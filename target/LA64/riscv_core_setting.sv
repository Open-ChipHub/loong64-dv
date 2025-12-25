/*
 * Copyright 2019 Google LLC
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

//-----------------------------------------------------------------------------
// Processor feature configuration
//-----------------------------------------------------------------------------

// 注释了与向量、浮点有关的内容
// XLEN
parameter int XLEN = 64;

// Parameter for SATP mode, set to BARE if address translation is not supported
parameter satp_mode_t SATP_MODE = BARE;     // 暂时保留

// Supported Privileged mode
privileged_mode_t supported_privileged_mode[] = {MACHINE_MODE};

// Unsupported instructions
riscv_instr_name_t unsupported_instr[];

// ISA supported by the processor
riscv_instr_group_t supported_isa[$] = {LA64};

// Interrupt mode support
mtvec_mode_t supported_interrupt_mode[$] = {DIRECT, VECTORED};      // 暂时保留

// The number of interrupt vectors to be generated, only used if VECTORED interrupt mode is
// supported
// int max_interrupt_vector_num = 16;

// Physical memory protection support
bit support_pmp = 0;

// Enhanced physical memory protection support
bit support_epmp = 0;

// Debug mode support
bit support_debug_mode = 0;

// Support delegate trap to user mode
bit support_umode_trap = 0;

// Support sfence.vma instruction
bit support_sfence = 0;

// Support unaligned load/store
bit support_unaligned_load_store = 1'b1;

// GPR setting
parameter int NUM_FLOAT_GPR = 32;
parameter int NUM_GPR = 32;
// parameter int NUM_VEC_GPR = 32;

// ----------------------------------------------------------------------------
// Vector extension configuration
// ----------------------------------------------------------------------------

// Parameter for vector extension
// parameter int VECTOR_EXTENSION_ENABLE = 0;

// parameter int VLEN = 512;

// Maximum size of a single vector element
// parameter int ELEN = 32;

// Minimum size of a sub-element, which must be at most 8-bits.
// parameter int SELEN = 8;

// Maximum size of a single vector element (encoded in vsew format)
// parameter int VELEN = int'($ln(ELEN)/$ln(2)) - 3;

// Maxium LMUL supported by the core
// parameter int MAX_LMUL = 8;

// ----------------------------------------------------------------------------
// Multi-harts configuration
// ----------------------------------------------------------------------------

// Number of harts
parameter int NUM_HARTS = 1;

// ----------------------------------------------------------------------------
// Previleged CSR implementation
// ----------------------------------------------------------------------------

// Implemented previlieged CSR list
`ifdef DSIM
privileged_reg_t implemented_csr[] = {
`else
const privileged_reg_t implemented_csr[] = {
`endif
	// Exactly matches la64_privil_reg.sv - 64 CSR cases
  CRMD, PRMD, EUEN, MISC, ECFG, ESTAT, ERA, BADV, BADI, EENTRY,
  RVACFG, CPUID, PRCFG1, PRCFG2, PRCFG3,
  SAVE0,
  LLCTL,
  TLBIDX, TLBEHI, TLBELO0, TLBELO1,
  ASID, PGDL, PGDH, PGD, PWCL, PWCH, STLBPS,
  TLBRENTRY, TLBRBADV, TLBRERA, TLBRSAVE, TLBRELO0, TLBRELO1, TLBREHI, TLBRPRMD,
  DMW0, DMW1, DMW2, DMW3,
  TID, TCFG, TVAL, CNTC, TICLR,
  MERRCTL, MERRENTRY, MERRERA, MERRSAVE,
  PMCFG, PMCNT,
  MWPC, MWPS,
  DBG, DERA, DSAVE,
  MSGIS0, MSGIS1, MSGIS2, MSGIS3, MSGIR, MSGIE,
  FWPC, FWPS
};

// Implementation-specific custom CSRs
bit [11:0] custom_csr[] = {
};

// ----------------------------------------------------------------------------
// Supported interrupt/exception setting, used for functional coverage
// ----------------------------------------------------------------------------

`ifdef DSIM
interrupt_cause_t implemented_interrupt[] = {
`else
const interrupt_cause_t implemented_interrupt[] = {
`endif
};

`ifdef DSIM
exception_cause_t implemented_exception[] = {
`else
const exception_cause_t implemented_exception[] = {
`endif
    SYS,    // SYSCALL
    BRK,    // BREAK
    INE,    // 指令不存在
    IPE,    // 指令特权等级错
    ADEF,   // 地址对齐错
    ADEM,   // 访存指令地址错
    FPE     // 浮点错
};
