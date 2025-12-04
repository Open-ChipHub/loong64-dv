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


package riscv_instr_pkg;

  `include "dv_defines.svh"
  `include "riscv_defines.svh"
  `include "uvm_macros.svh"

  import uvm_pkg::*;
  import riscv_signature_pkg::*;

  `define include_file(f) `include `"f`"

  uvm_cmdline_processor  inst;

  // Data section setting
  typedef struct {
    string         name;
    int unsigned   size_in_bytes;
    bit [2:0]      xwr; // Excutable,Writable,Readale
  } mem_region_t;

  // Initialization of the vregs
  typedef enum {
    SAME_VALUES_ALL_ELEMS,
    RANDOM_VALUES_VMV,
    RANDOM_VALUES_LOAD
  } vreg_init_method_t;

  typedef enum bit [3:0] {
    BARE = 4'b0000,
    SV32 = 4'b0001,
    SV39 = 4'b1000,
    SV48 = 4'b1001,
    SV57 = 4'b1010,
    SV64 = 4'b1011
  } satp_mode_t;    // 地址翻译模式枚举

  typedef enum bit [2:0] {
    RNE = 3'b000,
    RTZ = 3'b001,
    RDN = 3'b010,
    RUP = 3'b011,
    RMM = 3'b100
  } f_rounding_mode_t;    // 浮点数舍入模式枚举

  typedef enum bit [1:0] {
    DIRECT   = 2'b00,    // 直接模式，所有异常使用同一入口点
    VECTORED = 2'b01    // 向量模式，不同异常使用不同入口点
  } mtvec_mode_t;    // 异常处理模式枚举

  typedef enum bit [2:0] {
    IMM,    // Signed immediate
    UIMM,   // Unsigned immediate
    NZUIMM, // Non-zero unsigned immediate
    NZIMM   // Non-zero signed immediate
  } imm_t;

  // Privileged mode
  typedef enum bit [1:0] {
    USER_MODE       = 2'b00,    // 映射到 PLV3
    SUPERVISOR_MODE = 2'b01,    // 映射到 PLV2
    RESERVED_MODE   = 2'b10,    // 映射到 PLV1
    MACHINE_MODE    = 2'b11     // 映射到 PLV0
  } privileged_mode_t;

  typedef enum bit [4:0] {
    LA64,
    RV32I,
    RV64I,
    RV32M,
    RV64M,
    RV32A,
    RV64A,
    RV32F,
    RV32FC,
    RV64F,
    RV32D,
    RV32DC,
    RV64D,
    RV32C,
    RV64C,
    RV128I,
    RV128C,
    RVV,
    RV32B,
    RV32ZBA,
    RV32ZBB,
    RV32ZBC,
    RV32ZBS,
    RV64B,
    RV64ZBA,
    RV64ZBB,
    RV64ZBC,
    RV64ZBS,
    RV32X,
    RV64X
  } riscv_instr_group_t;

  typedef enum {
    // LA64 instructions
    // 算数运算类指令
    ADD_W,
    ADD_D,
    SUB_W,
    SUB_D,
    ADDI_W,
    ADDI_D,
    ADDU16I_D,
    ALSL_W,
    ALSL_WU,
    ALSL_D,
    LU12I_W,
    LU32I_D,
    LU52I_D,
    SLT,
    SLTU,
    SLTI,
    SLTUI,
    PCADDI,
    PCADDU12I,
    PCADDU18I,
    PCALAU12I,
    AND,
    OR,
    NOR,
    XOR,
    ANDN,
    ORN,
    ANDI,
    ORI,
    XORI,
    NOP,
    MUL_W,
    MUL_D,
    MULH_W,
    MULH_WU,
    MULH_D,
    MULH_DU,
    MULW_D_W,
    MULW_D_WU,
    DIV_W,
    DIV_WU,
    DIV_D,
    DIV_DU,
    MOD_W,
    MOD_WU,
    MOD_D,
    MOD_DU,
    // 移位运算类指令
    SLL_W,
    SRL_W,
    SRA_W,
    ROTR_W,
    SLLI_W,
    SRLI_W,
    SRAI_W,
    ROTRI_W,
    SLL_D,
    SRL_D,
    SRA_D,
    ROTR_D,
    SLLI_D,
    SRLI_D,
    SRAI_D,
    ROTRI_D,
    // 位操作指令
    EXT_W_B,
    EXT_W_H,
    CLO_W,
    CLO_D,
    CLZ_W,
    CLZ_D,
    CTO_W,
    CTO_D,
    CTZ_W,
    CTZ_D,
    BYTEPICK_W,
    BYTEPICK_D,
    REVB_2H,
    REVB_4H,
    REVB_2W,
    REVB_D,
    REVH_2W,
    REVH_D,
    BITREV_4B,
    BITREV_8B,
    BITREV_W,
    BITREV_D,
    BSTRINS_W,
    BSTRINS_D,
    BSTRPICK_W,
    BSTRPICK_D,
    MASKEQZ,
    MASKNEZ,
    // 转移指令
    BEQ,
    BNE,
    BLT,
    BGE,
    BLTU,
    BGEU,
    BEQZ,
    BNEZ,
    B,
    BL,
    JIRL,
    // 普通访存指令
    LD_B,
    LD_BU,
    LD_H,
    LD_HU,
    LD_W,
    LD_WU,
    LD_D,
    ST_B,
    ST_H,
    ST_W,
    ST_D,
    LDX_B,
    LDX_BU,
    LDX_H,
    LDX_HU,
    LDX_W,
    LDX_WU,
    LDX_D,
    STX_B,
    STX_H,
    STX_W,
    STX_D,
    LDPTR_W,
    LDPTR_D,
    STPTR_W,
    STPTR_D,
    PRELD,
    PRELDX,
	// 边界检查访存指令
    LDGT_B,
    LDGT_H,
    LDGT_W,
    LDGT_D,
    LDLE_B,
    LDLE_H,
    LDLE_W,
    LDLE_D,
    STGT_B,
    STGT_H,
    STGT_W,
    STGT_D,
    STLE_B,
    STLE_H,
    STLE_W,
    STLE_D,
	// 原子访存指令
    AMSWAP_W,
    AMSWAP_D,
    AMADD_W,
    AMADD_D,
    AMAND_W,
    AMAND_D,
    AMOR_W,
    AMOR_D,
    AMXOR_W,
    AMXOR_D,
    AMMAX_W,
    AMMAX_D,
    AMMIN_W,
    AMMIN_D,
    AMMAX_WU,
    AMMAX_DU,
    AMMIN_WU,
    AMMIN_DU,
    AMSWAP_DB_W,
    AMSWAP_DB_D,
    AMADD_DB_W,
    AMADD_DB_D,
    AMAND_DB_W,
    AMAND_DB_D,
    AMOR_DB_W,
    AMOR_DB_D,
    AMXOR_DB_W,
    AMXOR_DB_D,
    AMMAX_DB_W,
    AMMAX_DB_D,
    AMMIN_DB_W,
    AMMIN_DB_D,
    AMMAX_DB_WU,
    AMMAX_DB_DU,
    AMMIN_DB_WU,
    AMMIN_DB_DU,
	AMSWAP_DB_B,
    AMSWAP_DB_H,
    AMADD_DB_B,
    AMADD_DB_H,
	AMSWAP_B,
    AMSWAP_H,
	AMADD_B,
    AMADD_H,
	AMCAS_B,
    AMCAS_H,
    AMCAS_W,
    AMCAS_D,
	AMCAS_DB_B,
    AMCAS_DB_H,
    AMCAS_DB_W,
    AMCAS_DB_D,
	SC_Q,
	LL_W,
    LL_D,
    SC_W,
    SC_D,
	LL_ACQ_W,
    LL_ACQ_D,
    SC_REL_W,
    SC_REL_D,
	// 栅障指令
	//DBAR,
	//IBAR,
	// CRC校验指令
    CRC_W_B_W,
    CRC_W_H_W,
    CRC_W_W_W,
    CRC_W_D_W,
    CRCC_W_B_W,
    CRCC_W_H_W,
    CRCC_W_W_W,
    CRCC_W_D_W,
	// 浮点指令
    FADD_S,
    // Custom instructions
    `include "isa/custom/riscv_custom_instr_enum.sv"
    // You can add other instructions here
    INVALID_INSTR
  } riscv_instr_name_t;

  // Maximum virtual address bits used by the program
  parameter int MAX_USED_VADDR_BITS = 48;    // LA64

  parameter int SINGLE_PRECISION_FRACTION_BITS = 23;
  parameter int DOUBLE_PRECISION_FRACTION_BITS = 52;

  typedef enum bit [4:0] {                  // LA64
    ZERO = 5'b00000,
    R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15,   // R1——RA，R2——SP，R3——GP，R4——TP
    R16, R17, R18, R19, R20, R21, R22, R23, R24, R25, R26, R27, R28, R29, R30, R31
  } riscv_reg_t;

  typedef enum bit [4:0] {                  // LA64
    F0, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15,
    F16, F17, F18, F19, F20, F21, F22, F23, F24, F25, F26, F27, F28, F29, F30, F31
  } riscv_fpr_t;

  typedef enum bit [4:0] {
    V0, V1, V2, V3, V4, V5, V6, V7, V8, V9, V10, V11, V12, V13, V14, V15,
    V16, V17, V18, V19, V20, V21, V22, V23, V24, V25, V26, V27, V28, V29, V30, V31
  } riscv_vreg_t;

  typedef enum bit [5:0] {    // LA64
    R2_TYPE = 0,
    R3_TYPE,
    R4_TYPE,
    R2I8_TYPE,
    R2I12_TYPE,
    R2I14_TYPE,
    R2I16_TYPE,
    R1I21_TYPE,
    I26_TYPE
  } riscv_instr_format_t;


  // Vector arithmetic instruction variant
  typedef enum bit [3:0] {
    VV,
    VI,
    VX,
    VF,
    WV,
    WI,
    WX,
    VVM,
    VIM,
    VXM,
    VFM,
    VS,
    VM
  } va_variant_t;

  typedef enum bit [5:0] {
    LOAD = 0,
    STORE,
    SHIFT,
    ARITHMETIC,
    LOGICAL,
    COMPARE,
    BRANCH,
    JUMP,
    BITOPERATION,   // LA64
    SYNCH,
    SYSTEM,
    COUNTER,
    CSR,
    CHANGELEVEL,
    TRAP,
    INTERRUPT,
    // `VECTOR_INCLUDE("riscv_instr_pkg_inc_riscv_instr_category_t.sv")
    AMO // (last one)
  } riscv_instr_category_t;

  typedef bit [13:0] riscv_csr_t;   // LA64的CSR是14位

  typedef enum bit [13:0] {   // LA64 TODO 暂未实现CSR
    // User mode register
    CRMD         = 'h0000,
    PRMD         = 'h0001,
    EUEN         = 'h0002,
    MISC         = 'h0003,
    ECFG         = 'h0004
  } privileged_reg_t;

  typedef enum bit [5:0] {
    RSVD,       // Reserved field
    MXL,        // mis.mxl
    EXTENSION,  // mis.extension
    MODE,       // satp.mode
    ASID,       // satp.asid
    PPN         // satp.ppn
  } privileged_reg_fld_t;   // TODO

  typedef enum bit [1:0] {    // LA64
    PLV_0 = 2'b11,
    PLV_1 = 2'b10,
    PLV_2 = 2'b01,
    PLV_3 = 2'b00
  } privileged_level_t;

  typedef enum bit [1:0] {
    WPRI, // Reserved Writes Preserve Values, Reads Ignore Value
    WLRL, // Write/Read Only Legal Values
    WARL  // Write Any Values, Reads Legal Values
  } reg_field_access_t;

  //Pseudo instructions
  typedef enum bit [7:0] {
    PSEUDO_NONE = 0 // 占位，暂时无伪指令；不允许空的enum
  } riscv_pseudo_instr_name_t;

  // Data pattern of the memory model
  typedef enum bit [1:0] {
    RAND_DATA = 0,
    ALL_ZERO,
    INCR_VAL
  } data_pattern_t;

  typedef enum bit [2:0] {
    NEXT_LEVEL_PAGE   = 3'b000, // Pointer to next level of page table.
    READ_ONLY_PAGE    = 3'b001, // Read-only page.
    READ_WRITE_PAGE   = 3'b011, // Read-write page.
    EXECUTE_ONLY_PAGE = 3'b100, // Execute-only page.
    READ_EXECUTE_PAGE = 3'b101, // Read-execute page.
    R_W_EXECUTE_PAGE  = 3'b111  // Read-write-execute page
  } pte_permission_t;

  typedef enum bit [3:0] {    // LA64
    SWI0             = 4'h0,
    SWI1             = 4'h1,
    HWI0             = 4'h2,
    HWI1             = 4'h3,
    HWI2             = 4'h4,
    HWI3             = 4'h5,
    HWI4             = 4'h6,
    HWI5             = 4'h7,
    HWI6             = 4'h8,
    HWI7             = 4'h9,
    PMI              = 4'hA,
    TI               = 4'hB,
    IPI              = 4'hC
  } interrupt_cause_t;

  typedef enum bit [3:0] {    // LA64
    SYS             = 4'h0,   // SYSCALL
    BRK             = 4'h1,   // BREAK
    INE             = 4'h2,   // 指令不存在
    IPE             = 4'h3,   // 指令特权等级错
    ADEF            = 4'h4,   // 地址对齐错
    ADEM            = 4'h5,   // 访存指令地址错
    FPE             = 4'h6    // 浮点错
  } exception_cause_t;

  typedef enum int {
    FPER     = 0,
    SXE     = 1,
    ASXE    = 2,
    BTE     = 3
  } misa_ext_t;   // 类似于LA64中的EUEN寄存器，但不一样

  typedef enum bit [1:0] {
    NO_HAZARD,
    RAW_HAZARD,
    WAR_HAZARD,
    WAW_HAZARD
  } hazard_e;   // 数据冒险

  // riscv_csr_t default_include_csr_write[$] = {MSCRATCH};

  `include "riscv_core_setting.sv"

  // ePMP machine security configuration
  typedef struct packed {     // PMP机制，忽略
    bit rlb;
    bit mmwp;
    bit mml;
  } mseccfg_reg_t;

  // PMP address matching mode
  typedef enum bit [1:0] {
    OFF   = 2'b00,
    TOR   = 2'b01,
    NA4   = 2'b10,
    NAPOT = 2'b11
  } pmp_addr_mode_t;

  // PMP configuration register layout
  // This configuration struct includes the pmp address for simplicity
  // TODO (udinator) allow a full 34 bit address for rv32?
`ifdef _VCP //GRK958
  typedef struct packed {
    bit                   l;
    bit [1:0]                  zero;
    pmp_addr_mode_t       a;
    bit                   x;
    bit                   w;
    bit                   r;
    // RV32: the pmpaddr is the top 32 bits of a 34 bit PMP address
    // RV64: the pmpaddr is the top 54 bits of a 56 bit PMP address
    bit [XLEN - 1 : 0]    addr;
    // The offset from the address of <main> - automatically populated by the
    // PMP generation routine.
    bit [XLEN - 1 : 0]    offset;
    // The size of the region in case of NAPOT and overlap in case of TOR.
    integer addr_mode;
`else
  typedef struct{
    rand bit                   l;
    bit [1:0]                  zero;
    rand pmp_addr_mode_t       a;
    rand bit                   x;
    rand bit                   w;
    rand bit                   r;
    // RV32: the pmpaddr is the top 32 bits of a 34 bit PMP address
    // RV64: the pmpaddr is the top 54 bits of a 56 bit PMP address
    rand bit [XLEN - 1 : 0]    addr;
    // The offset from the address of <main> - automatically populated by the
    // PMP generation routine.
    rand bit [XLEN - 1 : 0]    offset;
    // The size of the region in case of NAPOT and allows for top less than bottom in TOR when 0.
    rand integer addr_mode;
`endif
  } pmp_cfg_reg_t;

  function automatic string hart_prefix(int hart = 0);    //多核
    if (NUM_HARTS <= 1) begin
      return "";
    end else begin
      return $sformatf("h%0d_", hart);
    end
  endfunction : hart_prefix

  function automatic string get_label(string label, int hart = 0);
    return {hart_prefix(hart), label};
  endfunction : get_label

  //向量
  typedef struct packed {
    bit ill;
    bit fractional_lmul;
    bit [XLEN-2:7] reserved;
    int vediv;
    int vsew;
    int vlmul;
  } vtype_t;

  typedef enum bit [1:0] {
    RoundToNearestUp,
    RoundToNearestEven,
    RoundDown,
    RoundToOdd
  } vxrm_t;

  typedef enum int {      // 子扩展，忽略
    ZBA,
    ZBB,
    ZBS,
    ZBP,
    ZBE,
    ZBF,
    ZBC,
    ZBR,
    ZBM,
    ZBT,
    ZB_TMP // for uncategorized instructions
  } b_ext_group_t;

  `VECTOR_INCLUDE("riscv_instr_pkg_inc_variables.sv")

  typedef bit [15:0] program_id_t;

  // xSTATUS bit mask
  parameter bit [XLEN - 1 : 0] MPRV_BIT_MASK = 'h1 << 17;     // 控制内存权限和特权模式
  parameter bit [XLEN - 1 : 0] SUM_BIT_MASK  = 'h1 << 18;
  parameter bit [XLEN - 1 : 0] MPP_BIT_MASK  = 'h3 << 11;

  parameter int IMM8_WIDTH = 8;     // LA64
  parameter int IMM12_WIDTH = 12;
  parameter int IMM14_WIDTH = 14;
  parameter int IMM16_WIDTH = 16;
  parameter int IMM21_WIDTH = 21;
  parameter int IMM26_WIDTH = 26;
  parameter int INSTR_WIDTH = 32;
  parameter int DATA_WIDTH  = 64;

  // Parameters for output assembly program formatting
  parameter int MAX_INSTR_STR_LEN = 16;
  parameter int LABEL_STR_LEN     = 18;

  // Parameter for program generation
  parameter int MAX_CALLSTACK_DEPTH = 20;
  parameter int MAX_SUB_PROGRAM_CNT = 20;
  parameter int MAX_CALL_PER_FUNC   = 5;

  string indent = {LABEL_STR_LEN{" "}};

  // Format the string to a fixed length
  function automatic string format_string(string str, int len = 10);
    string formatted_str;
    formatted_str = {len{" "}};
    if(len < str.len()) return str;
    formatted_str = {str, formatted_str.substr(0, len - str.len() - 1)};
    return formatted_str;
  endfunction

  // Print the data in the following format
  // 0xabcd, 0x1234, 0x3334 ...
  function automatic string format_data(bit [7:0] data[], int unsigned byte_per_group = 4);
    string str;
    int cnt;
    str = "0x";
    foreach(data[i]) begin
      if((i % byte_per_group == 0) && (i != data.size() - 1) && (i != 0)) begin
        str = {str, ", 0x"};
      end
      str = {str, $sformatf("%2x", data[i])};
    end
    return str;
  endfunction

  // Get the instr name enum from a string
  function automatic riscv_instr_name_t get_instr_name(string str);
    riscv_instr_name_t instr = instr.first;
    forever begin
      if(str.toupper() == instr.name()) begin
        return instr;
      end
      if(instr == instr.last) begin
        return INVALID_INSTR;
      end
      instr = instr.next;
    end
  endfunction
  //暂时忽略异常处理
  // Push general purpose register to stack, this is needed before trap handling
  // function automatic void push_gpr_to_kernel_stack(privileged_reg_t status,
  //                                                  privileged_reg_t scratch,
  //                                                  bit mprv,
  //                                                  riscv_reg_t sp,
  //                                                  riscv_reg_t tp,
  //                                                  ref string instr[$]);
  //   string store_instr = (XLEN == 32) ? "sw" : "sd";
  //   if (scratch inside {implemented_csr}) begin
  //     // Push USP from gpr.SP onto the kernel stack
  //     instr.push_back($sformatf("addi x%0d, x%0d, -4", tp, tp));
  //     instr.push_back($sformatf("%0s  x%0d, (x%0d)", store_instr, sp, tp));
  //     // Move KSP to gpr.SP
  //     instr.push_back($sformatf("add x%0d, x%0d, zero", sp, tp));
  //   end
  //   // If MPRV is set and MPP is S/U mode, it means the address translation and memory protection
  //   // for load/store instruction is the same as the mode indicated by MPP. In this case, we
  //   // need to use the virtual address to access the kernel stack.
  //   if((status == MSTATUS) && (SATP_MODE != BARE)) begin
  //     // We temporarily use tp to check mstatus to avoid changing other GPR.
  //     // (The value of sp has been pushed to the kernel stack, so can be recovered later)
  //     if(mprv) begin
  //       instr.push_back($sformatf("csrr x%0d, 0x%0x // MSTATUS", tp, status));
  //       instr.push_back($sformatf("srli x%0d, x%0d, 11", tp, tp));  // Move MPP to bit 0
  //       instr.push_back($sformatf("andi x%0d, x%0d, 0x3", tp, tp)); // keep the MPP bits
  //       // Check if MPP equals to M-mode('b11)
  //       instr.push_back($sformatf("xori x%0d, x%0d, 0x3", tp, tp));
  //       instr.push_back($sformatf("bnez x%0d, 1f", tp));      // Use physical address for kernel SP
  //       // Use virtual address for stack pointer
  //       instr.push_back($sformatf("slli x%0d, x%0d, %0d", sp, sp, XLEN - MAX_USED_VADDR_BITS));
  //       instr.push_back($sformatf("srli x%0d, x%0d, %0d", sp, sp, XLEN - MAX_USED_VADDR_BITS));
  //       instr.push_back("1: nop");
  //     end
  //   end
  //   // Push all GPRs (except for x0) to kernel stack
  //   // (gpr.SP currently holds the KSP)
  //   instr.push_back($sformatf("addi x%0d, x%0d, -%0d", sp, sp, 32 * (XLEN/8)));
  //   for(int i = 1; i < 32; i++) begin
  //     instr.push_back($sformatf("%0s  x%0d, %0d(x%0d)", store_instr, i, i * (XLEN/8), sp));
  //   end
  //   // Move KSP back to gpr.TP
  //   // (this is needed if we again take a interrupt (nested) before restoring our USP)
  //   instr.push_back($sformatf("add x%0d, x%0d, zero", tp, sp));
  // endfunction

  // // Pop general purpose register from stack, this is needed before returning to user program
  // function automatic void pop_gpr_from_kernel_stack(privileged_reg_t status,
  //                                                   privileged_reg_t scratch,
  //                                                   bit mprv,
  //                                                   riscv_reg_t sp,
  //                                                   riscv_reg_t tp,
  //                                                   ref string instr[$]);
  //   string load_instr = (XLEN == 32) ? "lw" : "ld";
  //   // Move KSP to gpr.SP
  //   instr.push_back($sformatf("add x%0d, x%0d, zero", sp, tp));
  //   // Pop GPRs from kernel stack
  //   for(int i = 1; i < 32; i++) begin
  //     instr.push_back($sformatf("%0s  x%0d, %0d(x%0d)", load_instr, i, i * (XLEN/8), sp));
  //   end
  //   instr.push_back($sformatf("addi x%0d, x%0d, %0d", sp, sp, 32 * (XLEN/8)));
  //   if (scratch inside {implemented_csr}) begin
  //     // Move KSP back to gpr.TP
  //     instr.push_back($sformatf("add x%0d, x%0d, zero", tp, sp));
  //     // Pop USP from the kernel stack, move back to gpr.SP
  //     instr.push_back($sformatf("%0s  x%0d, (x%0d)", load_instr, sp, tp));
  //     instr.push_back($sformatf("addi x%0d, x%0d, 4", tp, tp));
  //   end
  // endfunction

  // Get an integer argument from comand line
  function automatic void get_int_arg_value(string cmdline_str, ref int val);
    string s;
    if(inst.get_arg_value(cmdline_str, s)) begin
      val = s.atoi();
    end
  endfunction

  // Get a bool argument from comand line
  function automatic void get_bool_arg_value(string cmdline_str, ref bit val);
    string s;
    if(inst.get_arg_value(cmdline_str, s)) begin
      val = s.atobin();
    end
  endfunction

  // Get a hex argument from command line
  function automatic void get_hex_arg_value(string cmdline_str,
                                            ref bit [XLEN - 1 : 0] val);
    string s;
    if(inst.get_arg_value(cmdline_str, s)) begin
      val = s.atohex();
    end
  endfunction

  class cmdline_enum_processor #(parameter type T = riscv_instr_group_t);
    static function void get_array_values(string cmdline_str, bit allow_raw_vals, ref T vals[]);
      string s;
      void'(inst.get_arg_value(cmdline_str, s));
      if(s != "") begin
        string cmdline_list[$];
        T value;
        uvm_split_string(s, ",", cmdline_list);
        vals = new[cmdline_list.size];
        foreach (cmdline_list[i]) begin
          if (allow_raw_vals && cmdline_list[i].substr(0, 1) == "0x") begin
            logic[$bits(T)-1:0] raw_val;

            string raw_val_hex_digits = cmdline_list[i].substr(2, cmdline_list[i].len()-1);
            raw_val = raw_val_hex_digits.atohex();
            vals[i] = T'(raw_val);
          end else if (uvm_enum_wrapper#(T)::from_name(
             cmdline_list[i].toupper(), value)) begin
            vals[i] = value;
          end else begin
            `uvm_fatal("riscv_instr_pkg", $sformatf(
                "Invalid value (%0s) specified in command line: %0s", cmdline_list[i], cmdline_str))
          end
        end
      end
    endfunction
  endclass

  riscv_reg_t all_gpr[] = {ZERO, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15,
    R16, R17, R18, R19, R20, R21, R22, R23, R24, R25, R26, R27, R28, R29, R30, R31};

  /* LA64没有压缩指令
  riscv_reg_t compressed_gpr[] = {S0, S1, A0, A1, A2, A3, A4, A5};  */

  riscv_instr_category_t all_categories[] = {
    LOAD, STORE, SHIFT, ARITHMETIC, LOGICAL, COMPARE, BRANCH, JUMP, BITOPERATION,
    SYNCH, SYSTEM, COUNTER, CSR, CHANGELEVEL, TRAP, INTERRUPT, AMO
  };

  function automatic void get_val(input string str, output bit [XLEN-1:0] val, input hex = 0);
    if (str.len() > 2) begin
      if (str.substr(0, 1) == "0x") begin
        str = str.substr(2, str.len() -1);
        val = str.atohex();
        return;
      end
    end
    if (hex) begin
      val = str.atohex();
    end else begin
      if (str.substr(0, 0) == "-") begin
        str = str.substr(1, str.len() - 1);
        val = -str.atoi();
      end else begin
        val = str.atoi();
      end
    end
    `uvm_info("riscv_instr_pkg", $sformatf("imm:%0s -> 0x%0x/%0d", str, val, $signed(val)),
              UVM_FULL)
  endfunction : get_val

  // `include "riscv_vector_cfg.sv"
  // `include "riscv_pmp_cfg.sv"
  typedef class riscv_instr;
  // typedef class riscv_zba_instr;
  // typedef class riscv_zbb_instr;
  // typedef class riscv_zbc_instr;
  // typedef class riscv_zbs_instr;
  // typedef class riscv_b_instr;
  `include "riscv_instr_gen_config.sv"
  `include "isa/riscv_instr.sv"
  // `include "isa/riscv_amo_instr.sv"    // 原子内存操作（AMO）指令
  // `include "isa/riscv_zba_instr.sv"
  // `include "isa/riscv_zbb_instr.sv"
  // `include "isa/riscv_zbc_instr.sv"
  // `include "isa/riscv_zbs_instr.sv"
  // `include "isa/riscv_b_instr.sv"
  // `include "isa/riscv_csr_instr.sv"
  `include "isa/riscv_floating_point_instr.sv"
  // `include "isa/riscv_vector_instr.sv"
  // `include "isa/riscv_compressed_instr.sv"
  // `include "isa/rv32a_instr.sv"
  // `include "isa/rv32c_instr.sv"
  // `include "isa/rv32dc_instr.sv"
  // `include "isa/rv32d_instr.sv"
  // `include "isa/rv32fc_instr.sv"
  // `include "isa/rv32f_instr.sv"
  // `include "isa/rv32i_instr.sv"
  // `include "isa/rv32b_instr.sv"
  // `include "isa/rv32zba_instr.sv"
  // `include "isa/rv32zbb_instr.sv"
  // `include "isa/rv32zbc_instr.sv"
  // `include "isa/rv32zbs_instr.sv"
  // `include "isa/rv32m_instr.sv"
  // `include "isa/rv64a_instr.sv"
  // `include "isa/rv64b_instr.sv"
  // `include "isa/rv64zba_instr.sv"
  // `include "isa/rv64zbb_instr.sv"
  // `include "isa/rv64c_instr.sv"
  // `include "isa/rv64d_instr.sv"
  // `include "isa/rv64f_instr.sv"
  // `include "isa/rv64i_instr.sv"   // 模仿这个 
  // `include "isa/rv64m_instr.sv"
  // `include "isa/rv128c_instr.sv"
  // `include "isa/rv32v_instr.sv"
  // `include "isa/custom/riscv_custom_instr.sv"
  // `include "isa/custom/rv32x_instr.sv"
  // `include "isa/custom/rv64x_instr.sv"
  `include "isa/la64i_instr.sv"
  `include "isa/la64f_instr.sv"

  // `include "riscv_pseudo_instr.sv"
  // `include "riscv_illegal_instr.sv"
  // `include "riscv_reg.sv"   // 疑似给CSR寄存器用的
  // `include "riscv_privil_reg.sv"
  // `include "riscv_page_table_entry.sv"
  // `include "riscv_page_table_exception_cfg.sv"
  // `include "riscv_page_table.sv"
  // `include "riscv_page_table_list.sv"
  // `include "riscv_privileged_common_seq.sv"
  // `include "riscv_callstack_gen.sv"   // 生成带“子程序/函数调用”的测试，如果只产生线性指令流不需要
  // `include "riscv_data_page_gen.sv"   // 生成可直接拼到汇编里的数据节(.section)字符串，为加载/存储/AMO/权限相关用例提供可控的内存初始内容与分段布局，覆盖对齐、边界与不同访问权限场景。

  `include "riscv_instr_stream.sv"    // 构造、操作和随机化一段基础指令序列，随机指令序列生成与拼装的核心基类
  // `include "riscv_loop_instr.sv"    // 用于在 riscv-dv 中构造带后向分支的单/双层嵌套循环并把它们混入随机指令流
  // `include "riscv_directed_instr_lib.sv"    // “定向指令流库”，提供一组可直接插入程序的场景化指令序列类，如跳转链、入栈/出栈、定向内存访问、数值角落值等
  // `include "riscv_load_store_instr_lib.sv"    // 用于在riscv-dv中系统性生成各类访存场景，覆盖对齐/未对齐、压缩指令、浮点/向量访存、地址局部性与数据相关/结构相关冒险等。
  // `include "riscv_amo_instr_lib.sv"   // “原子内存操作(AMO)指令流库”，用于在riscv-dv中生成面向AMO/LR-SC/向量AMO的定向场景指令序列。

  `include "riscv_instr_sequence.sv"
  `include "riscv_asm_program_gen.sv"
  // `include "riscv_debug_rom_gen.sv"
  // `include "riscv_instr_cover_group.sv"
  // `include "user_extension.svh"

endpackage
