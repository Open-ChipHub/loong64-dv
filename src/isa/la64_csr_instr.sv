// LA64 CSR instruction class: CSRRD / CSRWR / CSRXCHG
class la64_csr_instr extends riscv_instr;
  // CSR address (14-bit)
  rand bit [13:0] csr;

  // Privileged CSR filters (use package enum)
  static riscv_instr_pkg::privileged_reg_t exclude_reg[$];
  static riscv_instr_pkg::privileged_reg_t include_reg[$];
  static riscv_instr_pkg::privileged_reg_t include_write_reg[$];

  // When set writes to read-only CSRs can be generated
  static bit allow_ro_write;

  rand bit write_csr;

  // Select CSR within include/exclude constraints
  constraint csr_addr_c {
    if (include_reg.size() > 0) csr inside {include_reg};
    if (exclude_reg.size() > 0) !(csr inside {exclude_reg});
  }

  // Decide whether write is allowed for chosen CSR
  // For LA64 we use top two CSR bits [13:12] to indicate read-only region (heuristic).
  constraint write_csr_c {
    if(!((csr[13:12] == 2'b11 && allow_ro_write) ||
         ((include_write_reg.size() > 0) && (csr inside {include_write_reg})) ||
         ((csr[13:12] != 2'b11) && (include_write_reg.size() == 0))))
      write_csr == 1'b0;
  }

  // Map instruction types to write/read behavior
  constraint csr_instr_rw {
    if (instr_name == CSRWR || instr_name == CSRXCHG) write_csr == 1'b1;
    if (instr_name == CSRRD) write_csr == 1'b0;
  }

  // Randomization ordering: pick CSR before deciding writes/operands
  constraint order {
    solve csr before write_csr, rs1, rs2, imm;
    solve write_csr before rs1, rs2, imm;
  }

  `uvm_object_utils(la64_csr_instr)

  function new(string name = "");
    super.new(name);
  endfunction

  // Create CSR filter based on generator config (similar to riscv variant)
  static function void create_csr_filter(riscv_instr_gen_config cfg);
    include_reg.delete();
    exclude_reg.delete();

    allow_ro_write = 1;

    if (cfg.enable_illegal_csr_instruction) begin
      exclude_reg = {implemented_csr};
    end else if (cfg.enable_access_invalid_csr_level) begin
      include_reg = {cfg.invalid_priv_mode_csrs};
    end else if (cfg.gen_all_csrs_by_default) begin
      allow_ro_write = cfg.gen_csr_ro_write;
      include_reg = {implemented_csr};
      // build include_write_reg from defaults + add/remove lists
      // Start with implemented_csr as the base, then apply add/remove filters
      create_include_write_reg(cfg.add_csr_write, cfg.remove_csr_write, {implemented_csr});
    end else begin
      // LA64 uses SAVE registers instead of SCRATCH registers
      // Use SAVE0 as the default safe CSR to avoid side effects
      include_reg = {SAVE0};
    end
  endfunction

  // Helper to create include_write_reg for LA64
  static function void create_include_write_reg(riscv_instr_pkg::privileged_reg_t add_csr[], riscv_instr_pkg::privileged_reg_t remove_csr[], riscv_instr_pkg::privileged_reg_t initial_csrs[$]);
    include_write_reg.delete();
    foreach (initial_csrs[r]) begin
      if (!(initial_csrs[r] inside {remove_csr})) begin
        include_write_reg.push_back(initial_csrs[r]);
      end
    end
    foreach (add_csr[r]) begin
      include_write_reg.push_back(add_csr[r]);
    end
  endfunction
  // Override random-mode for LA64 CSR instructions to set operand presence
  virtual function void set_rand_mode();
    super.set_rand_mode();
    // Default: no rs2 for R2I14_TYPE
    if (format == R2I14_TYPE) begin
      has_rs2 = 1'b0;
      if (instr_name == CSRRD) begin
        has_rs1 = 1'b0;
        has_rd  = 1'b1;
      end else if (instr_name == CSRWR) begin
        has_rs1 = 1'b1;
        has_rd  = 1'b0;
      end else if (instr_name == CSRXCHG) begin
        has_rs1 = 1'b1;
        has_rd  = 1'b1;
      end else begin
        has_rs1 = 1'b0;
      end
    end
  endfunction

  // Convert instruction to assembly
  virtual function string convert2asm(string prefix = "");
    string asm_str;
    asm_str = format_string(get_instr_name(), MAX_INSTR_STR_LEN);
    case (format)
      // R2I14_TYPE used for CSRRD/CSRWR/CSRXCHG: two-reg + 14-bit immediate variant
      R2I14_TYPE: begin
        if (instr_name == CSRRD) begin
          asm_str = $sformatf("%0s%0s, 0x%0x", asm_str, rd.name(), csr);
        end else if (instr_name == CSRWR) begin
          asm_str = $sformatf("%0s%0s, 0x%0x", asm_str, rs1.name(), csr);
        end else if (instr_name == CSRXCHG) begin
          // csrxchg rd, rj, csr_num
          asm_str = $sformatf("%0s%0s, %0s, 0x%0x", asm_str, rd.name(), rs1.name(), csr);
        end else begin
          asm_str = $sformatf("%0s%0s, 0x%0x", asm_str, rd.name(), csr);
        end
      end
      default: `uvm_fatal(`gfn, $sformatf("Unsupported format %0s [%0s]", format.name(), instr_name.name()))
    endcase
    if(comment != "") asm_str = {asm_str, " #", comment};
    return asm_str.tolower();
  endfunction

  function bit [6:0] get_opcode();
    // LA64 CSR opcode per docs
    get_opcode = 7'b0000100;
  endfunction

endclass

