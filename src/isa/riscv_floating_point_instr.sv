/*
 * LoongArch 浮点指令基类
 * 浮点指令格式与整数指令格式相同（R2_TYPE, R3_TYPE, R4_TYPE 等）
 */

class riscv_floating_point_instr extends riscv_instr;

  rand riscv_fpr_t fs1;  // 浮点源寄存器1（对应 LoongArch 的 fj）
  rand riscv_fpr_t fs2;  // 浮点源寄存器2（对应 LoongArch 的 fk）
  rand riscv_fpr_t fs3;  // 浮点源寄存器3（对应 LoongArch 的 fa）
  rand riscv_fpr_t fd;   // 浮点目标寄存器（对应 LoongArch 的 fd）
  rand riscv_fcsr_t fcsr;  // 浮点控制状态寄存器（FCSR0~FCSR3）
  rand riscv_cfr_t cfr;    // 条件标志寄存器（FCC0~FCC7）
  bit              has_fs1 = 1'b1;
  bit              has_fs2 = 1'b1;
  bit              has_fs3 = 1'b0;
  bit              has_fd  = 1'b1;
  bit              has_fcsr = 1'b0;  // 默认不使用FCSR
  bit              has_cfr = 1'b0;   // 默认不使用CFR

  `uvm_object_utils(riscv_floating_point_instr)
	
  function new (string name = "");
	super.new(name);
	is_floating_point = 1;
  endfunction
	
  // Convert the instruction to assembly code
  virtual function string convert2asm(string prefix = "");
    string asm_str;
    asm_str = format_string(get_instr_name(), MAX_INSTR_STR_LEN);
    case (format)
      // LoongArch 浮点指令格式（与整数指令格式相同）
      R2_TYPE:
        // GPR到FCSR移动指令：fcsr, rj (FCSR目标，GPR源)
        if (instr_name == MOVGR2FCSR) begin
          asm_str = $sformatf("%0s$fcsr%0d, $%0s", asm_str, fcsr, rs1.name());
        end
        // FCSR到GPR移动指令：rd, fcsr (GPR目标，FCSR源)
        else if (instr_name == MOVFCSR2GR) begin
          asm_str = $sformatf("%0s$%0s, $fcsr%0d", asm_str, rd.name(), fcsr);
        end
        // FPR到CF移动指令：cd, fj (CF目标，FPR源)
        else if (instr_name == MOVFR2CF) begin
          asm_str = $sformatf("%0s$fcc%0d, $%0s", asm_str, cfr, fs1.name());
        end
        // CF到FPR移动指令：fd, cj (FPR目标，CF源)
        else if (instr_name == MOVCF2FR) begin
          asm_str = $sformatf("%0s$%0s, $fcc%0d", asm_str, fd.name(), cfr);
        end
        // GPR到CF移动指令：cd, rj (CF目标，GPR源)
        else if (instr_name == MOVGR2CF) begin
          asm_str = $sformatf("%0s$fcc%0d, $%0s", asm_str, cfr, rs1.name());
        end
        // CF到GPR移动指令：rd, cj (GPR目标，CF源)
        else if (instr_name == MOVCF2GR) begin
          asm_str = $sformatf("%0s$%0s, $fcc%0d", asm_str, rd.name(), cfr);
        end
        // GPR到FPR移动指令：fd, rj (FPR目标，GPR源)
        else if (instr_name inside {MOVGR2FR_W, MOVGR2FRH_W, MOVGR2FR_D}) begin
          asm_str = $sformatf("%0s$%0s, $%0s", asm_str, fd.name(), rs1.name());
        end
        // FPR到GPR移动指令：rd, fj (GPR目标，FPR源)
        else if (instr_name inside {MOVFR2GR_S, MOVFR2GR_D, MOVFRH2GR_S}) begin
          asm_str = $sformatf("%0s$%0s, $%0s", asm_str, rd.name(), fs1.name());
        end
        // LoongArch 浮点指令：fd, fj (2个浮点寄存器)
        else begin
          asm_str = $sformatf("%0s$%0s, $%0s", asm_str, fd.name(), fs1.name());
        end
      R1I21_TYPE:
        // 基于条件标志的分支指令：cj, offs21 (CF寄存器 + 21位偏移)
        if (instr_name inside {BCEQZ, BCNEZ}) begin
          asm_str = $sformatf("%0s$fcc%0d, %0s", asm_str, cfr, get_imm());
        end
        else begin
          // 其他R1I21_TYPE格式指令，调用基类处理
          asm_str = super.convert2asm(prefix);
        end
      R2I12_TYPE:
        // 浮点加载/存储指令（立即数偏移）：fd, rj, si12 (FPR，GPR基址，12位立即数)
        if (instr_name inside {FLD_S, FLD_D, FST_S, FST_D}) begin
          asm_str = $sformatf("%0s$%0s, $%0s, %0s", asm_str, fd.name(), rs1.name(), get_imm());
        end
        else begin
          // 其他R2I12_TYPE格式指令，调用基类处理
          asm_str = super.convert2asm(prefix);
        end
      R3_TYPE:
        // 浮点比较指令：cd, fj, fk, cond (条件标志寄存器，2个浮点寄存器，条件码)
        if (instr_name inside {FCMP_S, FCMP_D}) begin
          bit [4:0] cond_val = imm[4:0];  // cond 是5位立即数（0x0-0x19）
          string cond_str = get_fcmp_cond_str(cond_val);
          string precision = (instr_name == FCMP_S) ? "s" : "d";
		  asm_str = $sformatf("fcmp.%0s.%0s $fcc%0d, $%0s, $%0s", cond_str, precision, cfr, fs1.name(), fs2.name());
        end
        // 浮点加载/存储指令（索引寻址）：fd, rj, rk (FPR，GPR基址，GPR索引)
        else if (instr_name inside {FLDX_S, FLDX_D, FSTX_S, FSTX_D}) begin
          asm_str = $sformatf("%0s$%0s, $%0s, $%0s", asm_str, fd.name(), rs1.name(), rs2.name());
        end
        // 浮点边界检查加载/存储指令：fd, rj, rk (FPR，GPR基址，GPR边界)
        else if (instr_name inside {FLDGT_S, FLDGT_D, FLDLE_S, FLDLE_D, FSTGT_S, FSTGT_D, FSTLE_S, FSTLE_D}) begin
          asm_str = $sformatf("%0s$%0s, $%0s, $%0s", asm_str, fd.name(), rs1.name(), rs2.name());
        end
        // LoongArch 浮点指令：fd, fj, fk (3个浮点寄存器)
        // 注意：LoongArch 使用 fj, fk 作为源寄存器，fd 作为目标寄存器
        // 在框架中，fs1 对应 fj，fs2 对应 fk，fd 对应 fd
        else begin
          asm_str = $sformatf("%0s$%0s, $%0s, $%0s", asm_str, fd.name(), fs1.name(), fs2.name());
        end
      R4_TYPE:
        // FSEL 指令：fd, fj, fk, ca (3个浮点寄存器 + 条件标志寄存器)
        if (instr_name == FSEL) begin
          // FSEL 指令格式：fsel fd, fj, fk, ca
          // 在框架中，fd 对应 fd，fs1 对应 fj，fs2 对应 fk，ca 是条件标志寄存器（CFR）
          asm_str = $sformatf("%0s$%0s, $%0s, $%0s, $fcc%0d", asm_str, fd.name(), fs1.name(), fs2.name(), cfr);
        end else begin
          // LoongArch 浮点指令：fd, fj, fk, fa (4个浮点寄存器)
          // 在框架中，fs1 对应 fj，fs2 对应 fk，fs3 对应 fa，fd 对应 fd
          asm_str = $sformatf("%0s$%0s, $%0s, $%0s, $%0s", asm_str, fd.name(), fs1.name(), fs2.name(), fs3.name());
        end
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
        // GPR到FCSR移动指令：fcsr, rj (FCSR目标，GPR源)
        if (instr_name == MOVGR2FCSR) begin
          has_rs1 = 1'b1;  // rj (GPR源)
          has_rs2 = 1'b0;
          has_rd  = 1'b0;
          has_fs1 = 1'b0;
          has_fs2 = 1'b0;
          has_fd  = 1'b0;  // FCSR是特殊寄存器，不使用fd
          has_fs3 = 1'b0;
          has_fcsr = 1'b1;  // 使用FCSR寄存器
          has_imm = 1'b0;
        end
        // FCSR到GPR移动指令：rd, fcsr (GPR目标，FCSR源)
        else if (instr_name == MOVFCSR2GR) begin
          has_rs1 = 1'b0;
          has_rs2 = 1'b0;
          has_rd  = 1'b1;  // rd (GPR目标)
          has_fs1 = 1'b0;  // FCSR是特殊寄存器，不使用fs1
          has_fs2 = 1'b0;
          has_fd  = 1'b0;
          has_fs3 = 1'b0;
          has_fcsr = 1'b1;  // 使用FCSR寄存器
          has_imm = 1'b0;
        end
        // FPR到CF移动指令：cd, fj (CF目标，FPR源)
        else if (instr_name == MOVFR2CF) begin
          has_rs1 = 1'b0;
          has_rs2 = 1'b0;
          has_rd  = 1'b0;  // 不使用rd，使用cfr字段
          has_fs1 = 1'b1;  // fj (FPR源)
          has_fs2 = 1'b0;
          has_fd  = 1'b0;
          has_fs3 = 1'b0;
          has_cfr = 1'b1;  // 使用CFR寄存器
          has_imm = 1'b0;
        end
        // CF到FPR移动指令：fd, cj (FPR目标，CF源)
        else if (instr_name == MOVCF2FR) begin
          has_rs1 = 1'b0;  // 不使用rs1，使用cfr字段
          has_rs2 = 1'b0;
          has_rd  = 1'b0;
          has_fs1 = 1'b0;
          has_fs2 = 1'b0;
          has_fd  = 1'b1;  // fd (FPR目标)
          has_fs3 = 1'b0;
          has_cfr = 1'b1;  // 使用CFR寄存器
          has_imm = 1'b0;
        end
        // GPR到CF移动指令：cd, rj (CF目标，GPR源)
        else if (instr_name == MOVGR2CF) begin
          has_rs1 = 1'b1;  // rj (GPR源)
          has_rs2 = 1'b0;
          has_rd  = 1'b0;  // 不使用rd，使用cfr字段
          has_fs1 = 1'b0;
          has_fs2 = 1'b0;
          has_fd  = 1'b0;
          has_fs3 = 1'b0;
          has_cfr = 1'b1;  // 使用CFR寄存器
          has_imm = 1'b0;
        end
        // CF到GPR移动指令：rd, cj (GPR目标，CF源)
        else if (instr_name == MOVCF2GR) begin
          has_rs1 = 1'b0;  // 不使用rs1，使用cfr字段
          has_rs2 = 1'b0;
          has_rd  = 1'b1;  // rd (GPR目标)
          has_fs1 = 1'b0;
          has_fs2 = 1'b0;
          has_fd  = 1'b0;
          has_fs3 = 1'b0;
          has_cfr = 1'b1;  // 使用CFR寄存器
          has_imm = 1'b0;
        end
        // GPR到FPR移动指令：fd, rj (FPR目标，GPR源)
        else if (instr_name inside {MOVGR2FR_W, MOVGR2FRH_W, MOVGR2FR_D}) begin
          has_rs1 = 1'b1;  // rj (GPR源)
          has_rs2 = 1'b0;
          has_rd  = 1'b0;
          has_fs1 = 1'b0;
          has_fs2 = 1'b0;
          has_fd  = 1'b1;  // fd (FPR目标)
          has_fs3 = 1'b0;
          has_imm = 1'b0;
        end
        // FPR到GPR移动指令：rd, fj (GPR目标，FPR源)
        else if (instr_name inside {MOVFR2GR_S, MOVFR2GR_D, MOVFRH2GR_S}) begin
          has_rs1 = 1'b0;
          has_rs2 = 1'b0;
          has_rd  = 1'b1;  // rd (GPR目标)
          has_fs1 = 1'b1;  // fj (FPR源)
          has_fs2 = 1'b0;
          has_fd  = 1'b0;
          has_fs3 = 1'b0;
          has_imm = 1'b0;
        end
        // LoongArch 浮点指令：fd, fj (2个浮点寄存器)
        else begin
          has_fs1 = 1'b1;  // fj
          has_fs2 = 1'b0;
          has_fd  = 1'b1;  // fd
          has_fs3 = 1'b0;
          has_imm = 1'b0;
        end
      end
      R2I12_TYPE: begin
        // 浮点加载/存储指令（立即数偏移）：fd, rj, si12 (FPR，GPR基址，12位立即数)
        if (instr_name inside {FLD_S, FLD_D, FST_S, FST_D}) begin
          has_rs1 = 1'b1;  // rj (GPR基址)
          has_rs2 = 1'b0;
          has_rd  = 1'b0;
          has_fs1 = 1'b0;
          has_fs2 = 1'b0;
          has_fd  = 1'b1;  // fd (FPR)
          has_fs3 = 1'b0;
          has_imm = 1'b1;  // 12位立即数偏移
        end
        else begin
          // 其他R2I12_TYPE格式指令，调用基类处理
          super.set_rand_mode();
        end
      end
      R3_TYPE: begin
        // 浮点比较指令：cd, fj, fk, cond (条件标志寄存器，2个浮点寄存器，条件码)
        if (instr_name inside {FCMP_S, FCMP_D}) begin
          has_fs1 = 1'b1;  // fj
          has_fs2 = 1'b1;  // fk
          has_fd  = 1'b0;  // 不使用fd，使用cfr
          has_fs3 = 1'b0;
          has_cfr = 1'b1;  // cd (条件标志寄存器)
          has_imm = 1'b1;  // cond (条件码，5位)
        end
        // 浮点加载/存储指令（索引寻址）：fd, rj, rk (FPR，GPR基址，GPR索引)
        else if (instr_name inside {FLDX_S, FLDX_D, FSTX_S, FSTX_D}) begin
          has_rs1 = 1'b1;  // rj (GPR基址)
          has_rs2 = 1'b1;  // rk (GPR索引)
          has_rd  = 1'b0;
          has_fs1 = 1'b0;
          has_fs2 = 1'b0;
          has_fd  = 1'b1;  // fd (FPR)
          has_fs3 = 1'b0;
          has_imm = 1'b0;
        end
        // 浮点边界检查加载/存储指令：fd, rj, rk (FPR，GPR基址，GPR边界)
        else if (instr_name inside {FLDGT_S, FLDGT_D, FLDLE_S, FLDLE_D, FSTGT_S, FSTGT_D, FSTLE_S, FSTLE_D}) begin
          has_rs1 = 1'b1;  // rj (GPR基址)
          has_rs2 = 1'b1;  // rk (GPR边界)
          has_rd  = 1'b0;
          has_fs1 = 1'b0;
          has_fs2 = 1'b0;
          has_fd  = 1'b1;  // fd (FPR)
          has_fs3 = 1'b0;
          has_imm = 1'b0;
        end
        // LoongArch 浮点指令：fd, fj, fk (3个浮点寄存器)
        else begin
          has_fs1 = 1'b1;  // fj
          has_fs2 = 1'b1;  // fk
          has_fd  = 1'b1;  // fd
          has_fs3 = 1'b0;
          has_imm = 1'b0;
        end
      end
      R4_TYPE: begin
        // FSEL 指令：fd, fj, fk, ca (3个浮点寄存器 + 条件标志寄存器)
        if (instr_name == FSEL) begin
          has_fs1 = 1'b1;  // fj
          has_fs2 = 1'b1;  // fk
          has_fd  = 1'b1;  // fd
          has_fs3 = 1'b0;  // 不使用 fs3
          has_imm = 1'b0;  // 不使用立即数
          has_cfr = 1'b1;  // ca 是条件标志寄存器（CFR）
        end else begin
          // LoongArch 浮点指令：fd, fj, fk, fa (4个浮点寄存器)
          has_fs1 = 1'b1;  // fj
          has_fs2 = 1'b1;  // fk
          has_fs3 = 1'b1;  // fa
          has_fd  = 1'b1;  // fd
          has_imm = 1'b0;
        end
      end
      R1I21_TYPE: begin
        // 基于条件标志的分支指令：cj, offs21 (CF寄存器 + 21位偏移)
        if (instr_name inside {BCEQZ, BCNEZ}) begin
          has_rs1 = 1'b0;  // 不使用rs1，使用cfr字段
          has_rs2 = 1'b0;
          has_rd  = 1'b0;
          has_fs1 = 1'b0;
          has_fs2 = 1'b0;
          has_fd  = 1'b0;
          has_fs3 = 1'b0;
          has_cfr = 1'b1;  // 使用CFR寄存器
          has_imm = 1'b1;  // 21位偏移量
        end
        else begin
          // 其他R1I21_TYPE格式指令，调用基类处理
          super.set_rand_mode();
        end
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
    this.fcsr    = rhs_.fcsr;
    this.cfr     = rhs_.cfr;
    this.has_fs3 = rhs_.has_fs3;
    this.has_fs2 = rhs_.has_fs2;
    this.has_fs1 = rhs_.has_fs1;
    this.has_fd  = rhs_.has_fd;
    this.has_fcsr = rhs_.has_fcsr;
    this.has_cfr = rhs_.has_cfr;
  endfunction : do_copy

  // 重写 extend_imm() 函数，确保 FCMP 指令的条件码不被修改
  virtual function void extend_imm();
    // 对于 FCMP 指令，条件码是 5 位无符号值，不应该被符号扩展
    if (instr_name inside {FCMP_S, FCMP_D}) begin
      // 只保留低 5 位，高位清零
      imm[XLEN-1:5] = 0;
      return;
    end
    super.extend_imm();
  endfunction : extend_imm
	
  virtual function void set_imm_len();
    if (instr_name inside {BCEQZ, BCNEZ}) begin
      // BCEQZ/BCNEZ指令：21位偏移量
      imm_len = 21;
    end else if (instr_name inside {FCMP_S, FCMP_D}) begin
      // FCMP指令：cond 是5位立即数（0x0-0x19）
      imm_len = 5;
    end else begin
      // LoongArch 浮点指令的立即数长度由格式决定，在基类 riscv_instr 中已处理
      // 这里可以添加浮点指令特定的立即数长度设置
    end
  endfunction: set_imm_len

  // 将FCMP指令的条件码转换为助记符字符串
  function string get_fcmp_cond_str(bit [4:0] cond_val);
    case (cond_val)
      5'h00: return "caf";
      5'h01: return "saf";
      5'h02: return "clt";
      5'h03: return "slt";
      5'h04: return "ceq";
      5'h05: return "seq";
      5'h06: return "cle";
      5'h07: return "sle";
      5'h08: return "cun";
      5'h09: return "sun";
      5'h0A: return "cult";
      5'h0B: return "sult";
      5'h0C: return "cueq";
      5'h0D: return "sueq";
      5'h0E: return "cule";
      5'h0F: return "sule";
      5'h10: return "cne";
      5'h11: return "sne";
      5'h14: return "cor";
      5'h15: return "sor";
      5'h18: return "cune";
      5'h19: return "sune";
      default: return $sformatf("cond%0d", cond_val);
    endcase
  endfunction: get_fcmp_cond_str

  // 基于条件标志的分支指令约束
  constraint bceqz_bcnez_c {
    if (instr_name inside {BCEQZ, BCNEZ})
      // 分支偏移量按字对齐，低2位必须为0
      imm[1:0] == 2'b00;
  }

  // FCMP指令约束：cond 值必须在有效范围内（0x0-0x19，但某些值无效）
  constraint fcmp_cond_c {
    if (instr_name inside {FCMP_S, FCMP_D}) {
      // 有效的 cond 值：0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x10, 0x11, 0x14, 0x15, 0x18, 0x19
      imm[4:0] inside {5'h00, 5'h01, 5'h02, 5'h03, 5'h04, 5'h05, 5'h06, 5'h07, 
                        5'h08, 5'h09, 5'h0A, 5'h0B, 5'h0C, 5'h0D, 5'h0E, 5'h0F,
                        5'h10, 5'h11, 5'h14, 5'h15, 5'h18, 5'h19};
      imm[XLEN-1:5] == 0;  // 高位必须为0
    }
  }

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
