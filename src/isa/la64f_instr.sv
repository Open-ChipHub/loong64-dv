/*
 * LoongArch 浮点指令定义
 */

// 浮点算术运算指令
// 单精度浮点指令：fd, fj, fk (3个浮点寄存器，使用R3_TYPE格式)
`DEFINE_FP_INSTR(FADD_S, R3_TYPE, ARITHMETIC, LA64)  // fadd.s fd, fj, fk
`DEFINE_FP_INSTR(FSUB_S, R3_TYPE, ARITHMETIC, LA64)  // fsub.s fd, fj, fk
`DEFINE_FP_INSTR(FMUL_S, R3_TYPE, ARITHMETIC, LA64)  // fmul.s fd, fj, fk
`DEFINE_FP_INSTR(FDIV_S, R3_TYPE, ARITHMETIC, LA64)  // fdiv.s fd, fj, fk
`DEFINE_FP_INSTR(FMAX_S, R3_TYPE, ARITHMETIC, LA64)  // fmax.s fd, fj, fk
`DEFINE_FP_INSTR(FMIN_S, R3_TYPE, ARITHMETIC, LA64)  // fmin.s fd, fj, fk
`DEFINE_FP_INSTR(FMAXA_S, R3_TYPE, ARITHMETIC, LA64) // fmaxa.s fd, fj, fk
`DEFINE_FP_INSTR(FMINA_S, R3_TYPE, ARITHMETIC, LA64) // fmina.s fd, fj, fk
`DEFINE_FP_INSTR(FSCALEB_S, R3_TYPE, ARITHMETIC, LA64) // fscaleb.s fd, fj, fk
`DEFINE_FP_INSTR(FCOPYSIGN_S, R3_TYPE, ARITHMETIC, LA64) // fcopysign.s fd, fj, fk

// 单精度浮点一元运算指令：fd, fj (2个浮点寄存器，使用R2_TYPE格式)
`DEFINE_FP_INSTR(FABS_S, R2_TYPE, ARITHMETIC, LA64)  // fabs.s fd, fj
`DEFINE_FP_INSTR(FNEG_S, R2_TYPE, ARITHMETIC, LA64)  // fneg.s fd, fj
`DEFINE_FP_INSTR(FSQRT_S, R2_TYPE, ARITHMETIC, LA64) // fsqrt.s fd, fj
`DEFINE_FP_INSTR(FRECIP_S, R2_TYPE, ARITHMETIC, LA64) // frecip.s fd, fj
`DEFINE_FP_INSTR(FRSQRT_S, R2_TYPE, ARITHMETIC, LA64) // frsqrt.s fd, fj
`DEFINE_FP_INSTR(FLOGB_S, R2_TYPE, ARITHMETIC, LA64) // flogb.s fd, fj
`DEFINE_FP_INSTR(FCLASS_S, R2_TYPE, ARITHMETIC, LA64) // fclass.s fd, fj
`DEFINE_FP_INSTR(FRECIPE_S, R2_TYPE, ARITHMETIC, LA64) // frecipe.s fd, fj
`DEFINE_FP_INSTR(FRSQRTE_S, R2_TYPE, ARITHMETIC, LA64) // frsqrte.s fd, fj

// 单精度浮点乘加/乘减指令：fd, fj, fk, fa (4个浮点寄存器，使用R4_TYPE格式)
`DEFINE_FP_INSTR(FMADD_S, R4_TYPE, ARITHMETIC, LA64)  // fmadd.s fd, fj, fk, fa
`DEFINE_FP_INSTR(FMSUB_S, R4_TYPE, ARITHMETIC, LA64)  // fmsub.s fd, fj, fk, fa
`DEFINE_FP_INSTR(FNMADD_S, R4_TYPE, ARITHMETIC, LA64) // fnmadd.s fd, fj, fk, fa
`DEFINE_FP_INSTR(FNMSUB_S, R4_TYPE, ARITHMETIC, LA64) // fnmsub.s fd, fj, fk, fa

// 双精度浮点指令：fd, fj, fk (3个浮点寄存器，使用R3_TYPE格式)
`DEFINE_FP_INSTR(FADD_D, R3_TYPE, ARITHMETIC, LA64)  // fadd.d fd, fj, fk
`DEFINE_FP_INSTR(FSUB_D, R3_TYPE, ARITHMETIC, LA64)  // fsub.d fd, fj, fk
`DEFINE_FP_INSTR(FMUL_D, R3_TYPE, ARITHMETIC, LA64)  // fmul.d fd, fj, fk
`DEFINE_FP_INSTR(FDIV_D, R3_TYPE, ARITHMETIC, LA64)  // fdiv.d fd, fj, fk
`DEFINE_FP_INSTR(FMAX_D, R3_TYPE, ARITHMETIC, LA64)  // fmax.d fd, fj, fk
`DEFINE_FP_INSTR(FMIN_D, R3_TYPE, ARITHMETIC, LA64)  // fmin.d fd, fj, fk
`DEFINE_FP_INSTR(FMAXA_D, R3_TYPE, ARITHMETIC, LA64) // fmaxa.d fd, fj, fk
`DEFINE_FP_INSTR(FMINA_D, R3_TYPE, ARITHMETIC, LA64) // fmina.d fd, fj, fk
`DEFINE_FP_INSTR(FSCALEB_D, R3_TYPE, ARITHMETIC, LA64) // fscaleb.d fd, fj, fk
`DEFINE_FP_INSTR(FCOPYSIGN_D, R3_TYPE, ARITHMETIC, LA64) // fcopysign.d fd, fj, fk

// 双精度浮点一元运算指令：fd, fj (2个浮点寄存器，使用R2_TYPE格式)
`DEFINE_FP_INSTR(FABS_D, R2_TYPE, ARITHMETIC, LA64)  // fabs.d fd, fj
`DEFINE_FP_INSTR(FNEG_D, R2_TYPE, ARITHMETIC, LA64)  // fneg.d fd, fj
`DEFINE_FP_INSTR(FSQRT_D, R2_TYPE, ARITHMETIC, LA64) // fsqrt.d fd, fj
`DEFINE_FP_INSTR(FRECIP_D, R2_TYPE, ARITHMETIC, LA64) // frecip.d fd, fj
`DEFINE_FP_INSTR(FRSQRT_D, R2_TYPE, ARITHMETIC, LA64) // frsqrt.d fd, fj
`DEFINE_FP_INSTR(FLOGB_D, R2_TYPE, ARITHMETIC, LA64) // flogb.d fd, fj
`DEFINE_FP_INSTR(FCLASS_D, R2_TYPE, ARITHMETIC, LA64) // fclass.d fd, fj
`DEFINE_FP_INSTR(FRECIPE_D, R2_TYPE, ARITHMETIC, LA64) // frecipe.d fd, fj
`DEFINE_FP_INSTR(FRSQRTE_D, R2_TYPE, ARITHMETIC, LA64) // frsqrte.d fd, fj

// 双精度浮点乘加/乘减指令：fd, fj, fk, fa (4个浮点寄存器，使用R4_TYPE格式)
`DEFINE_FP_INSTR(FMADD_D, R4_TYPE, ARITHMETIC, LA64)  // fmadd.d fd, fj, fk, fa
`DEFINE_FP_INSTR(FMSUB_D, R4_TYPE, ARITHMETIC, LA64)  // fmsub.d fd, fj, fk, fa
`DEFINE_FP_INSTR(FNMADD_D, R4_TYPE, ARITHMETIC, LA64) // fnmadd.d fd, fj, fk, fa
`DEFINE_FP_INSTR(FNMSUB_D, R4_TYPE, ARITHMETIC, LA64) // fnmsub.d fd, fj, fk, fa
