/*
 * LoongArch 浮点指令基类
 * 浮点指令格式与整数指令格式相同（R2_TYPE, R3_TYPE, R4_TYPE 等）
 */

class riscv_floating_point_instr extends riscv_instr;

  rand riscv_fpr_t fs1;  // 浮点源寄存器1（对应 LoongArch 的 fj）
  rand riscv_fpr_t fs2;  // 浮点源寄存器2（对应 LoongArch 的 fk）
  rand riscv_fpr_t fs3;  // 浮点源寄存器3（对应 LoongArch 的 fa）
  rand riscv_fpr_t fd;   // 浮点目标寄存器（对应 LoongArch 的 fd）
  bit              has_fs1 = 1'b1;
  bit              has_fs2 = 1'b1;
  bit              has_fs3 = 1'b0;
  bit              has_fd  = 1'b1;
  bit              has_fcsr = 1'b0;  // 默认不使用FCSR
  bit              has_cfr = 1'b0;   // 默认不使用CFR

  `uvm_object_utils(riscv_floating_point_instr)
  `uvm_object_new

  // Convert the instruction to assembly code
  virtual function string convert2asm(string prefix = "");
    string asm_str;
    asm_str = format_string(get_instr_name(), MAX_INSTR_STR_LEN);
    case (format)
      // LoongArch 浮点指令格式（与整数指令格式相同）
      R2_TYPE:
        // LoongArch 浮点指令：fd, fj (2个浮点寄存器)
        asm_str = $sformatf("%0s$%0s, $%0s", asm_str, fd.name(), fs1.name());
      R3_TYPE:
        // LoongArch 浮点指令：fd, fj, fk (3个浮点寄存器)
        // 注意：LoongArch 使用 fj, fk 作为源寄存器，fd 作为目标寄存器
        // 在框架中，fs1 对应 fj，fs2 对应 fk，fd 对应 fd
        asm_str = $sformatf("%0s$%0s, $%0s, $%0s", asm_str, fd.name(), fs1.name(), fs2.name());
      R4_TYPE:
        // LoongArch 浮点指令：fd, fj, fk, fa (4个浮点寄存器)
        // 在框架中，fs1 对应 fj，fs2 对应 fk，fs3 对应 fa，fd 对应 fd
        asm_str = $sformatf("%0s$%0s, $%0s, $%0s, $%0s", asm_str, fd.name(), fs1.name(), fs2.name(), fs3.name());
      default:
        `uvm_fatal(`gfn, $sformatf("Unsupported LoongArch floating point format: %0s", format.name()))
    endcase
    if(comment != "")
      asm_str = {asm_str, " #",comment};
    return asm_str.tolower();
  endfunction

  virtual function void set_rand_mode();
    has_rs1 = 0;
    has_rs2 = 0;
    has_rd  = 0;
    has_imm = 0;
    case (format)
      // LoongArch 浮点指令格式（与整数指令格式相同）
      R2_TYPE: begin
        // LoongArch 浮点指令：fd, fj (2个浮点寄存器)
        has_fs1 = 1'b1;  // fj
        has_fs2 = 1'b0;
        has_fd  = 1'b1;  // fd
        has_fs3 = 1'b0;
        has_imm = 1'b0;
      end
      R3_TYPE: begin
        // LoongArch 浮点指令：fd, fj, fk (3个浮点寄存器)
        has_fs1 = 1'b1;  // fj
        has_fs2 = 1'b1;  // fk
        has_fd  = 1'b1;  // fd
        has_fs3 = 1'b0;
        has_imm = 1'b0;
      end
      R4_TYPE: begin
        // LoongArch 浮点指令：fd, fj, fk, fa (4个浮点寄存器)
        has_fs1 = 1'b1;  // fj
        has_fs2 = 1'b1;  // fk
        has_fs3 = 1'b1;  // fa
        has_fd  = 1'b1;  // fd
        has_imm = 1'b0;
      end
      default: `uvm_info(`gfn, $sformatf("Unsupported LoongArch floating point format %0s", format.name()), UVM_LOW)
    endcase
  endfunction

  function void pre_randomize();
    super.pre_randomize();
    // For GPR-to-FPR move instructions, rs1 (GPR) is used
    // For FPR-to-GPR move instructions, rd (GPR) is used
    // These are already handled in set_rand_mode() and super.pre_randomize()
    fs1.rand_mode(has_fs1);
    fs2.rand_mode(has_fs2);
    fs3.rand_mode(has_fs3);
    fd.rand_mode(has_fd);
    fcsr.rand_mode(has_fcsr);
    cfr.rand_mode(has_cfr);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    riscv_floating_point_instr rhs_;
    super.copy(rhs);
    assert($cast(rhs_, rhs));
    this.fs3     = rhs_.fs3;
    this.fs2     = rhs_.fs2;
    this.fs1     = rhs_.fs1;
    this.fd      = rhs_.fd;
    this.has_fs3 = rhs_.has_fs3;
    this.has_fs2 = rhs_.has_fs2;
    this.has_fs1 = rhs_.has_fs1;
    this.has_fd  = rhs_.has_fd;
  endfunction : do_copy

  virtual function void set_imm_len();
    // LoongArch 浮点指令的立即数长度由格式决定，在基类 riscv_instr 中已处理
    // 这里可以添加浮点指令特定的立即数长度设置
  endfunction: set_imm_len

  // coverage related functions - 暂时注释掉
  /*
  virtual function void update_src_regs(string operands[$]);
    if(category inside {LOAD, CSR}) begin
      super.update_src_regs(operands);
      return;
    end
    case(format)
      // LoongArch 浮点指令格式
      R2_TYPE: begin
        `DV_CHECK_FATAL(operands.size() == 2)
        fs1 = get_fpr(operands[1]);
        fs1_value = get_gpr_state(operands[1]);
      end
      R3_TYPE: begin
        `DV_CHECK_FATAL(operands.size() == 3)
        fs1 = get_fpr(operands[1]);
        fs1_value = get_gpr_state(operands[1]);
        fs2 = get_fpr(operands[2]);
        fs2_value = get_gpr_state(operands[2]);
      end
      R4_TYPE: begin
        `DV_CHECK_FATAL(operands.size() == 4)
        fs1 = get_fpr(operands[1]);
        fs1_value = get_gpr_state(operands[1]);
        fs2 = get_fpr(operands[2]);
        fs2_value = get_gpr_state(operands[2]);
        fs3 = get_fpr(operands[3]);
        fs3_value = get_gpr_state(operands[3]);
      end
      default: `uvm_fatal(`gfn, $sformatf("Unsupported LoongArch floating point format %0s", format))
    endcase
  endfunction : update_src_regs

  virtual function void update_dst_regs(string reg_name, string val_str);
    get_val(val_str, gpr_state[reg_name], .hex(1));
    if (has_fd) begin
      fd = get_fpr(reg_name);
      fd_value = get_gpr_state(reg_name);
    end else if (has_rd) begin
      rd = get_gpr(reg_name);
      rd_value = get_gpr_state(reg_name);
    end
  endfunction : update_dst_regs

  virtual function riscv_fpr_t get_fpr(input string str);
    str = str.toupper();
    if (!uvm_enum_wrapper#(riscv_fpr_t)::from_name(str, get_fpr)) begin
      `uvm_fatal(`gfn, $sformatf("Cannot convert %0s to FPR", str))
    end
  endfunction : get_fpr

  virtual function void check_hazard_condition(riscv_instr pre_instr);
    riscv_floating_point_instr pre_fp_instr;
    super.check_hazard_condition(pre_instr);
    if ($cast(pre_fp_instr, pre_instr) && pre_fp_instr.has_fd) begin
      if ((has_fs1 && (fs1 == pre_fp_instr.fd)) || (has_fs2 && (fs2 == pre_fp_instr.fd))
          || (has_fs3 && (fs3 == pre_fp_instr.fd))) begin
        gpr_hazard = RAW_HAZARD;
      end else if (has_fd && (fd == pre_fp_instr.fd)) begin
        gpr_hazard = WAW_HAZARD;
      end else if (has_fd && ((pre_fp_instr.has_fs1 && (pre_fp_instr.fs1 == fd)) ||
                              (pre_fp_instr.has_fs2 && (pre_fp_instr.fs2 == fd)) ||
                              (pre_fp_instr.has_fs3 && (pre_fp_instr.fs3 == fd)))) begin
        gpr_hazard = WAR_HAZARD;
      end else begin
        gpr_hazard = NO_HAZARD;
      end
    end
  endfunction
  */
endclass
