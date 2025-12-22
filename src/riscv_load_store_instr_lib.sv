/*
 * Copyright 2018 Google LLC
 * Copyright 2020 Andes Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Base class for all load/store instruction stream

class riscv_load_store_base_instr_stream extends riscv_mem_access_stream;

  typedef enum bit [1:0] {
    NARROW,
    HIGH,
    MEDIUM,
    SPARSE
  } locality_e;

  rand int unsigned  num_load_store;
  rand int unsigned  num_mixed_instr;
  rand int           base;
  int                offset[];
  int                addr[];
  riscv_instr        load_store_instr[$];
  rand int unsigned  data_page_id;
  rand riscv_reg_t   rs1_reg;
  rand locality_e    locality;
  rand int           max_load_store_offset;
  rand bit           use_sp_as_rs1;

  `uvm_object_utils(riscv_load_store_base_instr_stream)

  constraint sp_rnd_order_c {
    solve use_sp_as_rs1 before rs1_reg;
  }

  constraint sp_c {
    // LA64: do not use stack pointer as base for directed load/store
    use_sp_as_rs1 == 1'b0;
  }

  constraint rs1_c {
    !(rs1_reg inside {cfg.reserved_regs, reserved_rd, ZERO});
    // Explicitly forbid tp (R2) and sp (R3) as base registers to avoid invalid ranges
    !(rs1_reg inside {R2, R3});
  }

  constraint addr_c {
    solve data_page_id before max_load_store_offset;
    solve max_load_store_offset before base;
    data_page_id < max_data_page_id;
    foreach (data_page[i]) {
      if (i == data_page_id) {
        max_load_store_offset == data_page[i].size_in_bytes;
      }
    }
    base inside {[0 : max_load_store_offset-1]};
    // LA64: Ensure base address leaves enough margin for maximum offset to avoid boundary issues
    // Leave at least 4KB margin at the end of region to accommodate maximum offset (2048)
    // This ensures final address (region_base + base + offset) stays within region bounds
    (max_load_store_offset > 4096) -> (base < (max_load_store_offset - 4096));
	if (data_page_id == 1) { 
	base < 150 * 1024;
    }
  }

  function new(string name = "");
    super.new(name);
  endfunction

  virtual function void randomize_offset();
    int offset_, addr_;
    offset = new[num_load_store];
    addr = new[num_load_store];
    for (int i=0; i<num_load_store; i++) begin
      if (!std::randomize(offset_, addr_) with {
        if (locality == NARROW) {
          soft offset_ inside {[-16:16]};
        } else if (locality == HIGH) {
          soft offset_ inside {[-64:64]};
        } else if (locality == MEDIUM) {
          soft offset_ inside {[-256:256]};
        } else if (locality == SPARSE) {
          soft offset_ inside {[-2048:2047]};
        }
        addr_ == base + offset_;
        addr_ inside {[0 : max_load_store_offset - 1]};
        // LA64: Additional constraint for LA_EMU address range
        // Valid RAM ranges: [0, 0x10000000), [0x90000000, ram_size+0x80000000), [0x1c000000, 0x1e000000)
        // Ensure final address (region_base + base + offset) stays within valid range
        // Since region symbols are in data section starting at 0x90000000+, we need to ensure
        // base + offset doesn't cause address to go beyond reasonable limits
        // Conservative approach: limit offset based on base to avoid boundary issues
        // Use if-else constraint expressions (without begin-end)
        if (base > (max_load_store_offset - 4096))
          soft offset_ inside {[-256:255]};
        else if (base > (max_load_store_offset - 65536))
          soft offset_ inside {[-512:511]};
      }) begin
        `uvm_fatal(`gfn, "Cannot randomize load/store offset")
      end
      offset[i] = offset_;
      addr[i] = addr_;
    end
  endfunction

  function void pre_randomize();
    super.pre_randomize();
    if (R2 inside {cfg.reserved_regs, reserved_rd}) begin
      use_sp_as_rs1 = 0;
      use_sp_as_rs1.rand_mode(0);
      sp_rnd_order_c.constraint_mode(0);
    end
  endfunction

  function void post_randomize();
    randomize_offset();
    // rs1 cannot be modified by other instructions
    if(!(rs1_reg inside {reserved_rd})) begin
      reserved_rd = {reserved_rd, rs1_reg};
    end
    gen_load_store_instr();
    add_mixed_instr(num_mixed_instr);
    add_rs1_init_la_instr(rs1_reg, data_page_id, base);
    super.post_randomize();
  endfunction

  // Generate each load/store instruction
  virtual function void gen_load_store_instr();
    riscv_instr instr;
    randomize_avail_regs();
    foreach (addr[i]) begin
      // Assign the allowed load/store instructions based on address alignment
      // This is done separately rather than a constraint to improve the randomization performance
      // LA64 load/store instructions
      allowed_instr = {LD_B, LD_BU, ST_B};
      if (!cfg.enable_unaligned_load_store) begin
        if (addr[i][0] == 1'b0) begin
          allowed_instr = {LD_H, LD_HU, ST_H, allowed_instr};
        end
        if (addr[i] % 4 == 0) begin
          allowed_instr = {LD_W, LD_WU, ST_W, allowed_instr};
          if (cfg.enable_floating_point) begin
            allowed_instr = {FLD_S, FST_S, allowed_instr};
          end
        end
        if ((XLEN >= 64) && (addr[i] % 8 == 0)) begin
          allowed_instr = {LD_D, ST_D, allowed_instr};
          if (cfg.enable_floating_point) begin
            allowed_instr = {FLD_D, FST_D, allowed_instr};
          end
        end
      end else begin // unaligned load/store
        allowed_instr = {LD_W, LD_WU, ST_W, LD_H, LD_HU, ST_H, allowed_instr};
        if (cfg.enable_floating_point) begin
          // For unaligned, we can still use aligned floating point loads/stores if address is aligned
          if (addr[i] % 4 == 0) begin
            allowed_instr = {FLD_S, FST_S, allowed_instr};
          end
          if ((XLEN >= 64) && (addr[i] % 8 == 0)) begin
            allowed_instr = {FLD_D, FST_D, allowed_instr};
          end
        end
        if (XLEN >= 64) begin
          allowed_instr = {LD_D, ST_D, allowed_instr};
        end
      end
      instr = riscv_instr::get_load_store_instr(allowed_instr);
      instr.has_rs1 = 0;
      instr.has_imm = 0;
      randomize_gpr(instr);
      instr.rs1 = rs1_reg;
      instr.imm_str = $sformatf("%0d", $signed(offset[i]));
      instr.process_load_store = 0;
      instr_list.push_back(instr);
      load_store_instr.push_back(instr);
    end
  endfunction

endclass

// A single load/store instruction
class riscv_single_load_store_instr_stream extends riscv_load_store_base_instr_stream;

  constraint legal_c {
    num_load_store == 1;
    num_mixed_instr < 5;
  }

  `uvm_object_utils(riscv_single_load_store_instr_stream)
  `uvm_object_new

endclass

// Back to back load/store instructions
class riscv_load_store_stress_instr_stream extends riscv_load_store_base_instr_stream;

  int unsigned max_instr_cnt = 30;
  int unsigned min_instr_cnt = 10;

  constraint legal_c {
    num_load_store inside {[min_instr_cnt:max_instr_cnt]};
    num_mixed_instr == 0;
  }

  `uvm_object_utils(riscv_load_store_stress_instr_stream)
  `uvm_object_new

endclass


// Back to back load/store instructions
class riscv_load_store_shared_mem_stream extends riscv_load_store_stress_instr_stream;

  `uvm_object_utils(riscv_load_store_shared_mem_stream)
  `uvm_object_new

  function void pre_randomize();
    load_store_shared_memory = 1;
    super.pre_randomize();
  endfunction

endclass

// Random load/store sequence
// A random mix of load/store instructions and other instructions
class riscv_load_store_rand_instr_stream extends riscv_load_store_base_instr_stream;

  constraint legal_c {
    num_load_store inside {[10:30]};
    num_mixed_instr inside {[10:30]};
  }

  `uvm_object_utils(riscv_load_store_rand_instr_stream)
  `uvm_object_new

endclass

// Use a small set of GPR to create various WAW, RAW, WAR hazard scenario
class riscv_hazard_instr_stream extends riscv_load_store_base_instr_stream;

  int unsigned num_of_avail_regs = 6;

  constraint legal_c {
    num_load_store inside {[10:30]};
    num_mixed_instr inside {[10:30]};
  }

  `uvm_object_utils(riscv_hazard_instr_stream)
  `uvm_object_new

  function void pre_randomize();
    avail_regs = new[num_of_avail_regs];
    super.pre_randomize();
  endfunction

endclass

// Use a small set of address to create various load/store hazard sequence
// This instruction stream focus more on hazard handling of load store unit.
class riscv_load_store_hazard_instr_stream extends riscv_load_store_base_instr_stream;

  rand int hazard_ratio;

  constraint hazard_ratio_c {
    hazard_ratio inside {[20:100]};
  }

  constraint legal_c {
    num_load_store inside {[10:20]};
    num_mixed_instr inside {[1:7]};
  }

  `uvm_object_utils(riscv_load_store_hazard_instr_stream)
  `uvm_object_new

  virtual function void randomize_offset();
    int offset_, addr_;
    offset = new[num_load_store];
    addr = new[num_load_store];
    for (int i = 0; i < num_load_store; i++) begin
      if ((i > 0) && ($urandom_range(0, 100) < hazard_ratio)) begin
        offset[i] = offset[i-1];
        addr[i] = addr[i-1];
      end else begin
        if (!std::randomize(offset_, addr_) with {
          if (locality == NARROW) {
            soft offset_ inside {[-16:16]};
          } else if (locality == HIGH) {
            soft offset_ inside {[-64:64]};
          } else if (locality == MEDIUM) {
            soft offset_ inside {[-256:256]};
          } else if (locality == SPARSE) {
            soft offset_ inside {[-2048:2047]};
          }
          addr_ == base + offset_;
          addr_ inside {[0 : max_load_store_offset - 1]};
        }) begin
          `uvm_fatal(`gfn, "Cannot randomize load/store offset")
        end
        offset[i] = offset_;
        addr[i] = addr_;
      end
    end
  endfunction : randomize_offset

endclass

// Back to back access to multiple data pages
// This is useful to test data TLB switch and replacement
class riscv_multi_page_load_store_instr_stream extends riscv_mem_access_stream;

  riscv_load_store_stress_instr_stream load_store_instr_stream[];
  rand int unsigned num_of_instr_stream;
  rand int unsigned data_page_id[];
  rand riscv_reg_t  rs1_reg[];

  constraint default_c {
    foreach(data_page_id[i]) {
      data_page_id[i] < max_data_page_id;
    }
    data_page_id.size() == num_of_instr_stream;
    rs1_reg.size() == num_of_instr_stream;
    unique {rs1_reg};
    foreach(rs1_reg[i]) {
      !(rs1_reg[i] inside {cfg.reserved_regs, ZERO});
    }
  }

  constraint page_c {
    solve num_of_instr_stream before data_page_id;
    num_of_instr_stream inside {[1 : max_data_page_id]};
    unique {data_page_id};
  }

  // Avoid accessing a large number of pages because we may run out of registers for rs1
  // Each page access needs a reserved register as the base address of load/store instruction
  constraint reasonable_c {
    num_of_instr_stream inside {[2:8]};
  }

  `uvm_object_utils(riscv_multi_page_load_store_instr_stream)
  `uvm_object_new

  // Generate each load/store seq, and mix them together
  function void post_randomize();
    load_store_instr_stream = new[num_of_instr_stream];
    foreach(load_store_instr_stream[i]) begin
      load_store_instr_stream[i] = riscv_load_store_stress_instr_stream::type_id::
                                   create($sformatf("load_store_instr_stream_%0d", i));
      load_store_instr_stream[i].min_instr_cnt = 5;
      load_store_instr_stream[i].max_instr_cnt = 10;
      load_store_instr_stream[i].cfg = cfg;
      load_store_instr_stream[i].hart = hart;
      load_store_instr_stream[i].sp_c.constraint_mode(0);
      // Make sure each load/store sequence doesn't override the rs1 of other sequences.
      foreach(rs1_reg[j]) begin
        if(i != j) begin
          load_store_instr_stream[i].reserved_rd =
            {load_store_instr_stream[i].reserved_rd, rs1_reg[j]};
        end
      end
      `DV_CHECK_RANDOMIZE_WITH_FATAL(load_store_instr_stream[i],
                                     rs1_reg == local::rs1_reg[i];
                                     data_page_id == local::data_page_id[i];,
                                     "Cannot randomize load/store instruction")
      // Mix the instruction stream of different page access, this could trigger the scenario of
      // frequent data TLB switch
      if(i == 0) begin
        instr_list = load_store_instr_stream[i].instr_list;
      end else begin
        mix_instr_stream(load_store_instr_stream[i].instr_list);
      end
    end
  endfunction

endclass

// Access the different locations of the same memory regions
class riscv_mem_region_stress_test extends riscv_multi_page_load_store_instr_stream;

  `uvm_object_utils(riscv_mem_region_stress_test)
  `uvm_object_new

  constraint page_c {
    num_of_instr_stream inside {[2:5]};
    foreach (data_page_id[i]) {
      if (i > 0) {
        data_page_id[i] == data_page_id[i-1];
      }
    }
  }

endclass

// Random load/store sequence to full address range
// The address range is not preloaded with data pages, use store instruction to initialize first
class riscv_load_store_rand_addr_instr_stream extends riscv_load_store_base_instr_stream;

  rand bit [XLEN-1:0] addr_offset;

  // Find an unused 4K page from address 1M onward
  constraint addr_offset_c {
    // LA64: keep addresses inside LA_EMU RAM window [0x90000000, 0x98000000)
    // Leave 4KB margin
    addr_offset inside {[32'h9000_0000 : 32'h97FF_F000]};
    addr_offset[11:0] == 0;
  }

  constraint legal_c {
    num_load_store inside {[5:10]};
    num_mixed_instr inside {[5:10]};
  }

  `uvm_object_utils(riscv_load_store_rand_addr_instr_stream)
  `uvm_object_new

  // Override: initialize rs1 with the explicit random address offset (not region label)
  virtual function void add_rs1_init_la_instr(riscv_reg_t gpr, int id, int base = 0);
    riscv_pseudo_instr li_instr;
    riscv_instr store_instr;

    // rs1 holds absolute address = addr_offset + base (base is 0 here)
    li_instr = riscv_pseudo_instr::type_id::create("li_instr");
    `DV_CHECK_RANDOMIZE_WITH_FATAL(li_instr,
       pseudo_instr_name == LI;
       rd == gpr;
    )
    li_instr.imm_str = $sformatf("0x%0x", addr_offset + base);
    instr_list.push_front(li_instr);
    // Reserve the base register so later instructions don't clobber it
    if(!(gpr inside {reserved_rd})) begin
      reserved_rd = {reserved_rd, gpr};
    end

    // Initialize memory that will be loaded later
    store_instr = riscv_instr::get_instr(ST_B);
    `DV_CHECK_RANDOMIZE_WITH_FATAL(store_instr,
       instr_name == ST_B;
       rs1 == gpr;
    )
    foreach (load_store_instr[i]) begin
      if (load_store_instr[i].category == LOAD) begin
        riscv_instr store;
        store = riscv_instr::type_id::create("store");
        store.copy(store_instr);
        store.rs2 = riscv_reg_t'(i % 32);
        store.imm_str = load_store_instr[i].imm_str;
        // LA64 instruction mapping
        case (load_store_instr[i].instr_name) inside
          LD_B, LD_BU : store.instr_name = ST_B;
          LD_H, LD_HU : store.instr_name = ST_H;
          LD_W, LD_WU : store.instr_name = ST_W;
          LD_D : store.instr_name = ST_D;
          FLD_S : begin
            if (cfg.enable_floating_point) begin
              store.instr_name = FST_S;
            end else begin
              `uvm_fatal(`gfn, $sformatf("Floating point load instruction generated when floating point is disabled: %0s",
                                         load_store_instr[i].convert2asm()))
            end
          end
          FLD_D : begin
            if (cfg.enable_floating_point) begin
              store.instr_name = FST_D;
            end else begin
              `uvm_fatal(`gfn, $sformatf("Floating point load instruction generated when floating point is disabled: %0s",
                                         load_store_instr[i].convert2asm()))
            end
          end
          default : `uvm_fatal(`gfn, $sformatf("Unexpected LA64 load op: %0s",
                                               load_store_instr[i].convert2asm()))
        endcase
        instr_list.push_front(store);
      end
    end
    // No super.add_rs1_init_la_instr; we already initialized rs1 here with absolute address
  endfunction

   virtual function void randomize_offset();
    int offset_, addr_;
    offset = new[num_load_store];
    addr = new[num_load_store];
    for (int i=0; i<num_load_store; i++) begin
      if (!std::randomize(offset_) with {
          offset_ inside {[-2048:2047]};
        }
      ) begin
        `uvm_fatal(`gfn, "Cannot randomize load/store offset")
      end
      offset[i] = offset_;
      addr[i] = addr_offset + offset_;
    end
  endfunction

endclass

//class riscv_vector_load_store_instr_stream extends riscv_mem_access_stream;
//
//  typedef enum {UNIT_STRIDED, STRIDED, INDEXED} address_mode_e;
//
//  rand bit [10:0] eew;
//  rand int unsigned data_page_id;
//  rand int unsigned num_mixed_instr;
//  rand int unsigned stride_byte_offset;
//  rand int unsigned index_addr;
//  rand address_mode_e address_mode;
//  rand riscv_reg_t rs1_reg;  // Base address
//  rand riscv_reg_t rs2_reg;  // Stride offset
//  riscv_vreg_t vs2_reg;      // Index address
//
//  constraint vec_mixed_instr_c {
//    num_mixed_instr inside {[0:10]};
//  }
//
//  constraint eew_c {
//    eew inside {cfg.vector_cfg.legal_eew};
//  }
//
//  constraint stride_byte_offset_c {
//    solve eew before stride_byte_offset;
//    // Keep a reasonable byte offset range to avoid vector memory address overflow
//    stride_byte_offset inside {[1 : 128]};
//    stride_byte_offset % (eew / 8) == 1;
//  }
//
//  constraint index_addr_c {
//    solve eew before index_addr;
//    // Keep a reasonable index address range to avoid vector memory address overflow
//    index_addr inside {[0 : 128]};
//    index_addr % (eew / 8) == 1;
//  }
//
//  constraint vec_rs_c {
//    !(rs1_reg inside {cfg.reserved_regs, reserved_rd, ZERO});
//    !(rs2_reg inside {cfg.reserved_regs, reserved_rd, ZERO});
//    rs1_reg != rs2_reg;
//  }
//
//  constraint vec_data_page_id_c {
//    data_page_id < max_data_page_id;
//  }
//
//  int base;
//  int max_load_store_addr;
//  riscv_vector_instr load_store_instr;
//
//  `uvm_object_utils(riscv_vector_load_store_instr_stream)
//  `uvm_object_new
//
//  function void post_randomize();
//    reserved_rd = {reserved_rd, rs1_reg, rs2_reg};
//    randomize_avail_regs();
//    gen_load_store_instr();
//    randomize_addr();
//    add_mixed_instr(num_mixed_instr);
//    add_rs1_init_la_instr(rs1_reg, data_page_id, base);
//    if (address_mode == STRIDED) begin
//      instr_list.push_front(get_init_gpr_instr(rs2_reg, stride_byte_offset));
//    end else if (address_mode == INDEXED) begin
//      // TODO: Support different index address for each element
//      add_init_vector_gpr_instr(vs2_reg, index_addr);
//    end
//    super.post_randomize();
//  endfunction
//
//  virtual function void randomize_addr();
//    int ss = address_span();
//    bit success;
//
//    repeat (10) begin
//      max_load_store_addr = data_page[data_page_id].size_in_bytes - ss;
//      if (max_load_store_addr >= 0) begin
//        success = 1'b1;
//        break;
//      end
//      `DV_CHECK_STD_RANDOMIZE_WITH_FATAL(data_page_id, data_page_id < max_data_page_id;)
//    end
//
//    assert (success) else begin
//      `uvm_fatal(`gfn, $sformatf({"Expected positive value for max_load_store_addr, got %0d.",
//        "  Perhaps more memory needs to be allocated in the data pages for vector loads and stores.",
//        "\ndata_page_id:%0d\ndata_page[data_page_id].size_in_bytes:%0d\naddress_span:%0d",
//        "\nstride_bytes:%0d\nVLEN:%0d\nLMUL:%0d\ncfg.vector_cfg.vtype.vsew:%0d\n\n"},
//        max_load_store_addr, data_page_id, data_page[data_page_id].size_in_bytes, ss,
//        stride_bytes(), VLEN, cfg.vector_cfg.vtype.vlmul, cfg.vector_cfg.vtype.vsew))
//    end
//
//    `DV_CHECK_STD_RANDOMIZE_WITH_FATAL(base, base inside {[0 : max_load_store_addr]};
//                                             base % eew == 0;)
//  endfunction
//
//  virtual function int address_span();
//    int num_elements = VLEN * cfg.vector_cfg.vtype.vlmul / cfg.vector_cfg.vtype.vsew;
//    case (address_mode)
//      UNIT_STRIDED : address_span = num_elements * stride_bytes();
//      STRIDED      : address_span = num_elements * stride_byte_offset;
//      INDEXED      : address_span = index_addr + num_elements * stride_bytes();
//    endcase
//  endfunction
//
//  virtual function int stride_bytes();
//    stride_bytes = eew / 8;
//  endfunction
//
//  // Generate each load/store instruction
//  virtual function void gen_load_store_instr();
//    build_allowed_instr();
//    randomize_vec_load_store_instr();
//    instr_list.push_back(load_store_instr);
//  endfunction
//
//  virtual function void build_allowed_instr();
//    case (address_mode)
//      UNIT_STRIDED : begin
//        allowed_instr = {VLE_V, VSE_V, allowed_instr};
//        if (cfg.vector_cfg.enable_fault_only_first_load) begin
//          allowed_instr = {VLEFF_V, allowed_instr};
//        end
//        if (cfg.vector_cfg.enable_zvlsseg) begin
//          allowed_instr = {VLSEGE_V, VSSEGE_V, allowed_instr};
//          if (cfg.vector_cfg.enable_fault_only_first_load) begin
//            allowed_instr = {VLSEGEFF_V, allowed_instr};
//          end
//        end
//      end
//      STRIDED : begin
//        allowed_instr = {VLSE_V, VSSE_V, allowed_instr};
//        if (cfg.vector_cfg.enable_zvlsseg) begin
//          allowed_instr = {VLSSEGE_V, VSSSEGE_V, allowed_instr};
//        end
//      end
//      INDEXED : begin
//        allowed_instr = {VLXEI_V, VSXEI_V, VSUXEI_V, allowed_instr};
//        if (cfg.vector_cfg.enable_zvlsseg) begin
//          allowed_instr = {VLXSEGEI_V, VSXSEGEI_V, VSUXSEGEI_V, allowed_instr};
//        end
//      end
//    endcase
//  endfunction
//
//  virtual function void randomize_vec_load_store_instr();
//    $cast(load_store_instr, riscv_instr::get_load_store_instr(allowed_instr));
//    load_store_instr.m_cfg = cfg;
//    load_store_instr.has_rs1 = 0;
//    load_store_instr.has_vs2 = 1;
//    load_store_instr.has_imm = 0;
//    randomize_gpr(load_store_instr);
//    load_store_instr.rs1 = rs1_reg;
//    load_store_instr.rs2 = rs2_reg;
//    load_store_instr.vs2 = vs2_reg;
//    if (address_mode == INDEXED) begin
//      cfg.vector_cfg.reserved_vregs = {load_store_instr.vs2};
//      vs2_reg = load_store_instr.vs2;
//      `uvm_info(`gfn, $sformatf("vs2_reg = v%0d", vs2_reg), UVM_LOW)
//    end
//    load_store_instr.process_load_store = 0;
//  endfunction
//
//endclass
