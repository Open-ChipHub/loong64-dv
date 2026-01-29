/*
 * Copyright 2018 Google LLC
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
class la64_privileged_common_seq extends uvm_sequence;

  riscv_instr_gen_config  cfg;
  int                     hart;
  la64_privil_reg         crmd;        
  la64_privil_reg         prmd;        
  la64_privil_reg         ecfg;        
  rand bit                crmd_ie;     // Interrupt enable bit in CRMD

  `uvm_object_utils(la64_privileged_common_seq)

  function new(string name = "");
    super.new(name);
  endfunction

  virtual function void enter_privileged_mode(input privileged_mode_t mode,
                                              output string instrs[$]);
    string label = format_string({$sformatf("%0sinit_%0s:",
                                 hart_prefix(hart), mode.name())}, LABEL_STR_LEN);
    string ret_instr[] = {"ertn"};  
    la64_privil_reg regs[$];
    bit [1:0] plv;
    
    label = label.tolower();
    
    case(mode)
      MACHINE_MODE:    plv = 2'b00;  // PLV0
      RESERVED_MODE:   plv = 2'b01;  // PLV1
      SUPERVISOR_MODE: plv = 2'b10;  // PLV2
      USER_MODE:       plv = 2'b11;  // PLV3
      default:         plv = 2'b00;  // Default to PLV0
    endcase
    
    setup_crmd_reg(mode, plv, regs);
    setup_prmd_reg(mode, plv, regs);
    setup_ecfg_reg(mode, regs);
    
    if(cfg.virtual_addr_translation_on) begin
      setup_pgdl_pgdh(instrs);
    end
    
    gen_csr_instr(regs, instrs);
    // Use ERTN to switch to the target privileged mode
    instrs.push_back(ret_instr[0]);
    foreach(instrs[i]) begin
      instrs[i] = {indent, instrs[i]};
    end
    instrs.push_front(label);
  endfunction

  // Setup CRMD (Current Privilege Mode Register)
  virtual function void setup_crmd_reg(privileged_mode_t mode, bit [1:0] plv,
                                       ref la64_privil_reg regs[$]);
    crmd = la64_privil_reg::type_id::create("crmd");
    crmd.init_reg(CRMD);
    
    if (cfg.randomize_csr) begin
      // If cfg has crmd value, use it
    end
    
    crmd.set_field("PLV", plv);
    
    // Set IE (Interrupt Enable) field
    // Only enable interrupt in PLV0 (MACHINE_MODE) or based on config
    if (mode == MACHINE_MODE) begin
      crmd.set_field("IE", cfg.enable_interrupt);
    end else begin
      crmd.set_field("IE", cfg.enable_interrupt & crmd_ie);
    end
    
    crmd.set_field("DA", 1);
    
    crmd.set_field("PG", 0);
    
    crmd.set_field("DATF", 0);
    
    crmd.set_field("DATM", 0);
    
    crmd.set_field("WE", 0);
    
    `uvm_info(`gfn, $sformatf("crmd_val: 0x%0x", crmd.get_val()), UVM_LOW)
    regs.push_back(crmd);
  endfunction

  // Setup PRMD (Previous Privilege Mode Register)
  virtual function void setup_prmd_reg(privileged_mode_t mode, bit [1:0] plv,
                                       ref la64_privil_reg regs[$]);
    prmd = la64_privil_reg::type_id::create("prmd");
    prmd.init_reg(PRMD);
    `DV_CHECK_RANDOMIZE_FATAL(prmd, "cannot randomize prmd")
    
    if (cfg.randomize_csr) begin
      // If cfg has prmd value, use it
    end
    
    prmd.set_field("PPLV", plv);
    
    prmd.set_field("PIE", cfg.enable_interrupt);
    
    prmd.set_field("PWE", 0);
    
    regs.push_back(prmd);
  endfunction

  // Setup ECFG (Exception Configuration Register) for interrupt enable
  virtual function void setup_ecfg_reg(privileged_mode_t mode, ref la64_privil_reg regs[$]);
    // Enable external and timer interrupt
    if (ECFG inside {implemented_csr}) begin
      ecfg = la64_privil_reg::type_id::create("ecfg");
      ecfg.init_reg(ECFG);
      
      if (cfg.randomize_csr) begin
        // If cfg has ecfg value, use it
      end
      
      ecfg.set_field("LIE", cfg.enable_interrupt);
      
      ecfg.set_field("VS", 0);
      
      regs.push_back(ecfg);
    end
  endfunction

  virtual function void gen_csr_instr(la64_privil_reg regs[$], ref string instrs[$]);
    foreach(regs[i]) begin
      instrs.push_back($sformatf("li.d $r%0d, 0x%0x", cfg.gpr[0], regs[i].get_val()));
      instrs.push_back($sformatf("csrwr $r%0d, 0x%0x # %0s",
                       cfg.gpr[0], regs[i].reg_name, regs[i].reg_name.name()));
    end
  endfunction

  // Setup PGDL/PGDH (Page Global Directory Low/High) for address translation
  // LoongArch uses PGDL/PGDH instead of SATP for page table base address
  virtual function void setup_pgdl_pgdh(ref string instrs[$]);
    la64_privil_reg pgdl, pgdh;
    bit [XLEN-1:0] pgd_base_mask;
    
    pgdl = la64_privil_reg::type_id::create("pgdl");
    pgdl.init_reg(PGDL);
    
    pgdh = la64_privil_reg::type_id::create("pgdh");
    pgdh.init_reg(PGDH);
    
    // Load the root page table physical address
    instrs.push_back($sformatf("la $r%0d, page_table_0", cfg.gpr[0]));
    
    // For 64-bit, split the address into high and low parts
    // Low 12 bits are zero (page aligned), so we shift right by 12
    instrs.push_back($sformatf("srli.d $r%0d, $r%0d, 12", cfg.gpr[0], cfg.gpr[0]));
    
    // Extract lower 32 bits for PGDL (assuming 32-bit PGD base field)
    instrs.push_back($sformatf("li.d $r%0d, 0xffffffff", cfg.gpr[1]));
    instrs.push_back($sformatf("and $r%0d, $r%0d, $r%0d", cfg.gpr[1], cfg.gpr[0], cfg.gpr[1]));
    instrs.push_back($sformatf("csrwr $r%0d, 0x%0x # pgdl", cfg.gpr[1], PGDL));
    
    // Extract upper bits for PGDH (if needed for 64-bit systems)
    if (XLEN == 64) begin
      instrs.push_back($sformatf("srli.d $r%0d, $r%0d, 32", cfg.gpr[0], cfg.gpr[0]));
      instrs.push_back($sformatf("csrwr $r%0d, 0x%0x # pgdh", cfg.gpr[0], PGDH));
    end
  endfunction

endclass

