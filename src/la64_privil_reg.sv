class la64_privil_reg extends riscv_reg#(privileged_reg_t);
  `uvm_object_utils(la64_privil_reg)
  function new(string name = ""); super.new(name); endfunction

  function void init_reg(REG_T reg_name);
    super.init_reg(reg_name);
    case(reg_name) inside
	  //MWPnCFG1~4 unimplemented
	  //FWPnCFG1~3 unimplemented
      CRMD: begin
        add_field("PLV", 2, RW);
        add_field("IE",  1, RW);
        add_field("DA",  1, RW);
        add_field("PG",  1, RW);
        add_field("DATF",2, RW);
        add_field("DATM",2, RW);
        add_field("WE",  1, RW);
        add_field("RESERVED", XLEN - (2+1+1+1+2+2+1), R0);
      end
      PRMD: begin
        add_field("PPLV", 2, RW);
        add_field("PIE",  1, RW);
        add_field("PWE",  1, RW);
        add_field("RESERVED", XLEN - (2+1+1), R0);
      end
      EUEN: begin
        add_field("FPE", 1, RW);
        add_field("SXE", 1, RW);
        add_field("ASXE",1, RW);
        add_field("BTE", 1, RW);
        add_field("RESERVED", XLEN - (1+1+1+1), R0);
      end
	  MISC: begin
        add_field("VA32L1", 1, RW);
        add_field("VA32L2", 1, RW);
        add_field("VA32L3", 1, RW);
        add_field("DRDTI1", 1, RW);
        add_field("DRDTI2", 1, RW);
        add_field("DRDTI3", 1, RW);
        add_field("RPCNT1", 1, RW);
        add_field("RPCNT2", 1, RW);
        add_field("RPCNT3", 1, RW);
        add_field("ALC0", 1, RW);
        add_field("ALC1", 1, RW);
        add_field("ALC2", 1, RW);
        add_field("ALC3", 1, RW);
        add_field("DWPL0", 1, RW);
        add_field("DWPL1", 1, RW);
        add_field("DWPL2", 1, RW);
        add_field("RESERVED", XLEN - (15), R0);
      end
      ECFG: begin
        add_field("LIE", 1, RW);
        add_field("VS", 3, RW);
        add_field("RESERVED", XLEN - (1+3), R0);
      end
      ESTAT: begin
        add_field("IS_LO", 2, RW);
        add_field("IS_HI", 11, R);
        add_field("RESERVED_13", 1, R0);
        add_field("MsgInt", 1, R);
        add_field("RESERVED_15", 1, R0);
        add_field("Ecode", 6, R);
        add_field("EsubCode", 9, R);
        add_field("RESERVED_31", 1, R0);
        add_field("RESERVED", XLEN - (2+11+1+1+1+6+9+1), R0);
      end
		ERA: begin
        add_field("PC", XLEN, RW);
      end
      BADV: begin
        add_field("VAddr", XLEN, RW);
      end
      BADI: begin
        add_field("Inst", 32, R);
        add_field("RESERVED", XLEN - 32, R0);
      end
      EENTRY: begin
        add_field("ZERO", 12, R0);
        add_field("VPN", XLEN - 12, RW);
      end
	  RVACFG: begin
		add_field("RBits", 4, RW);
		add_field("RESERVED", XLEN - 4, R0);
	  end
	  CPUID: begin
        add_field("CoreID", 9, R);
        add_field("RESERVED", XLEN - 9, R0);
      end
      PRCFG1: begin
        add_field("SAVENum", 4, R);
        add_field("TimerBits", 8, R);
        add_field("VSMAX", 3, R);
        add_field("RESERVED", XLEN - (4+8+3), R0);
      end
      PRCFG2: begin
        add_field("PSAVL", XLEN, R);
      end
      PRCFG3: begin
        add_field("TLBType", 4, R);
        add_field("MTLBEntries", 8, R);
        add_field("STLBWays", 8, R);
        add_field("STLBSets", 6, R);
        add_field("RESERVED", XLEN - (4+8+8+6), R0);
      end
      SAVE: begin
        add_field("Data", XLEN, RW);
      end
      LLCTL: begin
        add_field("ROLLB", 1, R);
        add_field("WCLLB", 1, W1);
        add_field("KLO", 1, RW);
        add_field("RESERVED", XLEN - (1+1+1), R0);
      end
	  TLBIDX: begin
        add_field("Index", 16, RW);
        add_field("RESERVED_23_16", 8, R0);
        add_field("PS", 6, RW);
        add_field("RESERVED_30", 1, R0);
        add_field("NE", 1, RW);
        add_field("RESERVED", XLEN - 32, R0);
      end
      TLBEHI: begin
        add_field("ZERO", 13, R0);
        add_field("VPPN", XLEN - 13, RW);
      end
	  TLBELO0: begin
        add_field("V", 1, RW);
        add_field("D", 1, RW);
        add_field("PLV", 2, RW);
        add_field("MAT", 2, RW);
        add_field("G", 1, RW);
        add_field("RESERVED_11_7", 5, R0);
        add_field("PPN", XLEN - 15, RW);
        add_field("NR", 1, RW);
        add_field("NX", 1, RW);
        add_field("RPLV", 1, RW);
      end
      TLBELO1: begin
        add_field("V", 1, RW);
        add_field("D", 1, RW);
        add_field("PLV", 2, RW);
        add_field("MAT", 2, RW);
        add_field("G", 1, RW);
        add_field("RESERVED_11_7", 5, R0);
        add_field("PPN", XLEN - 15, RW);
        add_field("NR", 1, RW);
        add_field("NX", 1, RW);
        add_field("RPLV", 1, RW);
      end
      ASID: begin
        add_field("ASID", 10, RW);
        add_field("RESERVED_15_10", 6, R0);
        add_field("ASIDBITS", 8, R);
        add_field("RESERVED", XLEN - (10+6+8), R0);
      end
      PGDL: begin
        add_field("ZERO", 12, R0);
        add_field("Base", XLEN - 12, RW);
      end
      PGDH: begin
        add_field("ZERO", 12, R0);
        add_field("Base", XLEN - 12, RW);
      end
      PGD: begin
        add_field("ZERO", 12, R0);
        add_field("Base", XLEN - 12, R);
      end
	  PWCL: begin
        add_field("PTbase", 5, RW);
        add_field("PTwidth", 5, RW);
        add_field("Dir1_base", 5, RW);
        add_field("Dir1_width", 5, RW);
        add_field("Dir2_base", 5, RW);
        add_field("Dir2_width", 5, RW);
        add_field("PTEWidth", 2, RW);
        add_field("RESERVED", XLEN - 32, R0);
      end
      PWCH: begin
        add_field("Dir3_base", 6, RW);
        add_field("Dir3_width", 6, RW);
        add_field("Dir4_base", 6, RW);
        add_field("Dir4_width", 6, RW);
        add_field("HPTW_En", 1, RW);
        add_field("RESERVED", XLEN - (6+6+6+6+1), R0);
      end
      STLBPS: begin
        add_field("PS", 6, RW);
        add_field("RESERVED", XLEN - 6, R0);
      end
      TLBRENTRY: begin
        add_field("ZERO", 12, R0);
        add_field("PPN", XLEN - 12, RW);
        add_field("RESERVED", XLEN - (12 + (XLEN - 12)), R0);
      end
      TLBRBADV: begin
        add_field("VAddr", XLEN, RW);
      end
      TLBRERA: begin
        add_field("IsTLBR", 1, RW);
        add_field("RESERVED_1", 1, R0);
        add_field("PC", XLEN - 2, RW);
      end
      TLBRSAVE: begin
        add_field("Data", XLEN, RW);
      end
      TLBRELO0: begin
        add_field("V", 1, RW);
        add_field("D", 1, RW);
        add_field("PLV", 2, RW);
        add_field("MAT", 2, RW);
        add_field("G", 1, RW);
        add_field("RESERVED_11_7", 5, R0);
        add_field("PPN", XLEN - 15, RW);
        add_field("NR", 1, RW);
        add_field("NX", 1, RW);
        add_field("RPLV", 1, RW);
      end
      TLBRELO1: begin
        add_field("V", 1, RW);
        add_field("D", 1, RW);
        add_field("PLV", 2, RW);
        add_field("MAT", 2, RW);
        add_field("G", 1, RW);
        add_field("RESERVED_11_7", 5, R0);
        add_field("PPN", XLEN - 15, RW);
        add_field("NR", 1, RW);
        add_field("NX", 1, RW);
        add_field("RPLV", 1, RW);
      end
	  TLBREHI: begin
        add_field("PS", 6, RW);
        add_field("RESERVED", XLEN - 6, R0);
      end
      TLBRPRMD: begin
        add_field("PPLV", 2, RW);
        add_field("PIE", 1, RW);
        add_field("RESERVED_3", 1, R0);
        add_field("PWE", 1, RW);
        add_field("RESERVED", XLEN - (2+1+1+1), R0);
      end
      DMW0: begin
        add_field("PLV0", 1, RW);
        add_field("PLV1", 1, RW);
        add_field("PLV2", 1, RW);
        add_field("PLV3", 1, RW);
        add_field("MAT", 2, RW);
        add_field("RESERVED_6_59", 54, R0);
        add_field("VSEG", 4, RW);
        add_field("RESERVED", XLEN - (1+1+1+1+2+54+4), R0);
      end
      DMW1: begin
        add_field("PLV0", 1, RW);
        add_field("PLV1", 1, RW);
        add_field("PLV2", 1, RW);
        add_field("PLV3", 1, RW);
        add_field("MAT", 2, RW);
        add_field("RESERVED_6_59", 54, R0);
        add_field("VSEG", 4, RW);
        add_field("RESERVED", XLEN - (1+1+1+1+2+54+4), R0);
      end
      DMW2: begin
        add_field("PLV0", 1, RW);
        add_field("PLV1", 1, RW);
        add_field("PLV2", 1, RW);
        add_field("PLV3", 1, RW);
        add_field("MAT", 2, RW);
        add_field("RESERVED_6_59", 54, R0);
        add_field("VSEG", 4, RW);
        add_field("RESERVED", XLEN - (1+1+1+1+2+54+4), R0);
      end
      DMW3: begin
        add_field("PLV0", 1, RW);
        add_field("PLV1", 1, RW);
        add_field("PLV2", 1, RW);
        add_field("PLV3", 1, RW);
        add_field("MAT", 2, RW);
        add_field("RESERVED_6_59", 54, R0);
        add_field("VSEG", 4, RW);
        add_field("RESERVED", XLEN - (1+1+1+1+2+54+4), R0);
      end
	  TID: begin
        add_field("TID", XLEN, RW);
      end
      TCFG: begin
        add_field("En", 1, RW);
        add_field("Periodic", 1, RW);
        add_field("InitVal", XLEN - 2, RW);
      end
      TVAL: begin
        add_field("TimeVal", XLEN, R);
      end
      CNTC: begin
        add_field("Compensation", XLEN, RW);
      end
      TICLR: begin
        add_field("CLR", 1, W1);
        add_field("RESERVED", XLEN - 1, R0);
      end
	  MERRCTL: begin
        add_field("IsMERR", 1, R);
        add_field("Repairable", 1, R);
        add_field("PPLV", 2, RW);
        add_field("PIE", 1, RW);
        add_field("RESERVED_5", 1, R0);
        add_field("PWE", 1, RW);
        add_field("PDA", 1, RW);
        add_field("PPG", 1, RW);
        add_field("PDATF", 2, RW);
        add_field("PDATM", 2, RW);
        add_field("RESERVED_15_13", 3, R0);
        add_field("Cause", 8, R);
        add_field("RESERVED_31_24", 8, R0);
      end
      MERRENTRY: begin
        add_field("ZERO", 12, R0);
        add_field("PPN", XLEN - 12, RW);
        add_field("RESERVED", XLEN - (12 + (XLEN - 12)), R0);
      end
      MERRERA: begin
        add_field("PC", XLEN, RW);
      end
      MERRSAVE: begin
        add_field("Data", XLEN, RW);
      end
	  PMCFG: begin
        add_field("EvCode", 10, RW);
        add_field("RESERVED_15_10", 6, R0);
        add_field("PLV0", 1, RW);
        add_field("PLV1", 1, RW);
        add_field("PLV2", 1, RW);
        add_field("PLV3", 1, RW);
        add_field("PMIEn", 1, RW);
        add_field("RESERVED_22_21", 2, R0);
        add_field("RESERVED_31_23", XLEN - (10+6+1+1+1+1+1+2), R0);
      end
      PMCNT: begin
        add_field("Count", XLEN, RW);
      end
      MWPC: begin
        add_field("Num", 6, R);
        add_field("RESERVED", XLEN - 6, R0);
      end
      MWPS: begin
        add_field("Status", 16, RW);
        add_field("RESERVED_15", 1, R0);
        add_field("Skip", 1, RW);
        add_field("RESERVED_31_17", XLEN - (16+1+1), R0);
      end
	  DBG: begin
        add_field("DS", 1, R);
        add_field("DRev", 7, R);
        add_field("DEI", 1, R);
        add_field("DCL", 1, R);
        add_field("DFW", 1, R);
        add_field("DMW", 1, R);
        add_field("RESERVED_15_12", 4, R0);
        add_field("Ecode", 6, R);
        add_field("RESERVED_31_22", 10, R0);
      end
      DERA: begin
        add_field("PC", XLEN, RW);
      end
      DSAVE: begin
        add_field("Data", XLEN, RW);
      end
      MSGIS0: begin
        add_field("IS", XLEN, R);
      end
      MSGIS1: begin
        add_field("IS", XLEN, R);
      end
      MSGIS2: begin
        add_field("IS", XLEN, R);
      end
      MSGIS3: begin
        add_field("IS", XLEN, R);
      end
      MSGIR: begin
        add_field("IntNum", 8, R);
        add_field("RESERVED_30_8", 23, R0);
        add_field("Null", 1, R);
      end
      MSGIE: begin
        add_field("PT", 8, RW);
        add_field("RESERVED", XLEN - 8, R0);
      end
	  FWPC: begin
        add_field("Num", 6, R);
        add_field("RESERVED", XLEN - 6, R0);
      end
      FWPS: begin
        add_field("Status", 16, RW);
        add_field("RESERVED_15", 1, R0);
        add_field("Skip", 1, RW);
        add_field("RESERVED_31_17", XLEN - (16+1+1), R0);
      end
      default: `uvm_fatal(get_full_name(), $sformatf("LA64 reg %0s is not supported yet", reg_name.name()))
    endcase
  endfunction

  function int unsigned meaningful_field_width();
    int unsigned total = 0;
    foreach(fld[i]) begin
      if (fld[i].get_name() != "RESERVED") total += fld[i].bit_width;
    end
    return total;
  endfunction

  // LA64 read semantics for 32-bit CSRs
  virtual function bit[XLEN-1:0] get_val();
    bit[XLEN-1:0] full = super.get_val();
    int unsigned mw = meaningful_field_width();
    if (mw == 32) begin
      bit[31:0] low32 = full[31:0];
      if (low32[31]) begin
        return {{(XLEN-32){1'b1}}, low32};
      end else begin
        return {{(XLEN-32){1'b0}}, low32};
      end
    end
    return full;
  endfunction

  // LA64 write semantics for 32-bit CSRs
  virtual function void set_val(bit [XLEN-1:0] val);
    int unsigned mw = meaningful_field_width();
    if (mw == 32) begin
      bit[XLEN-1:0] vfull = {{(XLEN-32){1'b0}}, val[31:0]};
      super.set_val(vfull);
      return;
    end
    super.set_val(val);
  endfunction
endclass
