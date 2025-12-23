/*
 * LA64 Privileged Instruction Class
 * 
 * Implements LA64 privileged instructions (Section 4.2) that need special handling
 * Note: CSR instructions (CSRRD/CSRWR/CSRXCHG) are handled by la64_csr_instr.sv
 * 
 * - All privileged instructions can ONLY be executed in PLV0
 * - Attempting to execute in PLV1-3 will cause IPE (Instruction Privilege Error) exception
 */

class la64_privileged_instr extends riscv_instr;
  
  // Instruction-specific fields
  rand bit [13:0] csr_addr;   // For CSR/IOCSR instructions (14-bit for LA64)
  rand bit [4:0]  op;         // For INVTLB, CACOP
  rand bit [4:0]  level;      // For IDLE, LDDIR
  rand bit [2:0]  seq;        // For LDPTE
  rand bit [14:0] hint;       // For DBCL
  
  // Constraint: TLB and ERTN instructions have all register fields = 0
  constraint zero_regs_c {
    if (instr_name inside {TLBSRCH, TLBRD, TLBWR, TLBFILL, TLBCLR, TLBFLUSH, ERTN}) {
      rs1 == ZERO;
      rd == ZERO;
    }
    if (instr_name inside {DBCL, IDLE}) {
      rs1 == ZERO;
      rd == ZERO;
    }
  }
  
  `uvm_object_utils(la64_privileged_instr)
  
  function new(string name = "");
    super.new(name);
  endfunction
  
  virtual function void set_rand_mode();
    super.set_rand_mode();
    
    case (instr_name)
      // Note: CSR instructions are handled by la64_csr_instr class
      
      // 4.2.2 IOCSR访问指令
      IOCSRRD_B, IOCSRRD_H, IOCSRRD_W, IOCSRRD_D: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b0;
        has_rd  = 1'b1;  
        has_imm = 1'b0;
      end
      
      IOCSRWR_B, IOCSRWR_H, IOCSRWR_W, IOCSRWR_D: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b0;
        has_rd  = 1'b1;  
        has_imm = 1'b0;
      end
      
      // 4.2.3 Cache维护指令
      CACOP: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b0;
        has_rd  = 1'b0;
        has_imm = 1'b1;  
      end
      
      // 4.2.4 TLB维护指令 (R2_TYPE with all regs = 0)
      TLBSRCH, TLBRD, TLBWR, TLBFILL, TLBCLR, TLBFLUSH: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b0;
        has_rd  = 1'b1;  
        has_imm = 1'b0;
      end
      
      INVTLB: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b1;  
        has_rd  = 1'b0;
        has_imm = 1'b1; 
      end
      
      // 4.2.5 软件页表遍历指令
      LDDIR: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b0;
        has_rd  = 1'b1;  
        has_imm = 1'b1;  
      end
      
      LDPTE: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b0;
        has_rd  = 1'b0;
        has_imm = 1'b1;  
      end
      
      // 4.2.6 其它杂项指令 (R2_TYPE format)
      ERTN: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b0;
        has_rd  = 1'b1;  
        has_imm = 1'b0;
      end
      
      DBCL: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b0;
        has_rd  = 1'b1;  
        has_imm = 1'b1;  
      end
      
      IDLE: begin
        has_rs1 = 1'b1;  
        has_rs2 = 1'b0;
        has_rd  = 1'b1;  
        has_imm = 1'b1;  
      end
      
      default: begin
        `uvm_fatal(`gfn, $sformatf("Unsupported LA64 privileged instruction: %0s", 
                                   instr_name.name()))
      end
    endcase
  endfunction
  
  // Convert instruction to assembly code
  virtual function string convert2asm(string prefix = "");
    string asm_str;
    asm_str = format_string(get_instr_name(), MAX_INSTR_STR_LEN);
    
    case (instr_name)
      // Note: CSR instructions are handled by la64_csr_instr class
      
      // 4.2.2 IOCSR访问指令
      IOCSRRD_B, IOCSRRD_H, IOCSRRD_W, IOCSRRD_D: begin
        asm_str = $sformatf("%0s%0s, %0s", asm_str, rd.name(), rs1.name());
      end
      
      IOCSRWR_B, IOCSRWR_H, IOCSRWR_W, IOCSRWR_D: begin
        asm_str = $sformatf("%0s%0s, %0s", asm_str, rd.name(), rs1.name());
      end
      
      // 4.2.3 Cache维护指令
      CACOP: begin
        asm_str = $sformatf("%0s0x%0x, %0s, %0d", 
                           asm_str, op, rs1.name(), $signed(imm[11:0]));
      end
      
      // 4.2.4 TLB维护指令
      TLBSRCH, TLBRD, TLBWR, TLBFILL, TLBCLR, TLBFLUSH: begin
        // No operands
      end
      
      INVTLB: begin
        asm_str = $sformatf("%0s0x%0x, %0s, %0s", 
                           asm_str, op, rs1.name(), rs2.name());
      end
      
      // 4.2.5 软件页表遍历指令
      LDDIR: begin
        asm_str = $sformatf("%0s%0s, %0s, 0x%0x", 
                           asm_str, rd.name(), rs1.name(), level);
      end
      
      LDPTE: begin
        asm_str = $sformatf("%0s%0s, 0x%0x", 
                           asm_str, rs1.name(), seq);
      end
      
      // 4.2.6 其它杂项指令
      ERTN: begin
        // No operands
      end
      
      DBCL: begin
        asm_str = $sformatf("%0s0x%0x", asm_str, hint);
      end
      
      IDLE: begin
        asm_str = $sformatf("%0s0x%0x", asm_str, level);
      end
      
      default: begin
        `uvm_fatal(`gfn, $sformatf("Unsupported LA64 privileged instruction: %0s", 
                                   instr_name.name()))
      end
    endcase
    
    if (comment != "") asm_str = {asm_str, " #", comment};
    return asm_str.tolower();
  endfunction
  
  // Get instruction name string
  virtual function string get_instr_name();
    case (instr_name)
      // Note: CSR instructions are handled by la64_csr_instr class
      IOCSRRD_B:   return "iocsrrd.b";
      IOCSRRD_H:   return "iocsrrd.h";
      IOCSRRD_W:   return "iocsrrd.w";
      IOCSRRD_D:   return "iocsrrd.d";
      IOCSRWR_B:   return "iocsrwr.b";
      IOCSRWR_H:   return "iocsrwr.h";
      IOCSRWR_W:   return "iocsrwr.w";
      IOCSRWR_D:   return "iocsrwr.d";
      CACOP:       return "cacop";
      TLBSRCH:     return "tlbsrch";
      TLBRD:       return "tlbrd";
      TLBWR:       return "tlbwr";
      TLBFILL:     return "tlbfill";
      TLBCLR:      return "tlbclr";
      TLBFLUSH:    return "tlbflush";
      INVTLB:      return "invtlb";
      LDDIR:       return "lddir";
      LDPTE:       return "ldpte";
      ERTN:        return "ertn";
      DBCL:        return "dbcl";
      IDLE:        return "idle";
      default:     return super.get_instr_name();
    endcase
  endfunction
  
  function void post_randomize();
    super.post_randomize();
    // Sync instruction-specific fields with imm
    case (instr_name)
      // Note: CSR instructions are handled by la64_csr_instr class
      INVTLB, CACOP: begin
        op = imm[4:0];
      end
      LDDIR, IDLE: begin
        level = imm[4:0];
      end
      LDPTE: begin
        seq = imm[2:0];
      end
      DBCL: begin
        hint = imm[14:0];
      end
    endcase
  endfunction
  
endclass
