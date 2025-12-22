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

// Psuedo instructions are used to simplify assembly program writing
class riscv_pseudo_instr extends riscv_instr;

  rand riscv_pseudo_instr_name_t  pseudo_instr_name;

  `add_pseudo_instr(LI, R2I12_TYPE, LOAD, LA64)
  `add_pseudo_instr(LA, R2I12_TYPE, LOAD, LA64)

  `uvm_object_utils(riscv_pseudo_instr)

  function new(string name = "");
    super.new(name);
    process_load_store = 0;
    this.format = R2I12_TYPE;
  endfunction

  // Convert the instruction to assembly code
  virtual function string convert2asm(string prefix = "");
    string asm_str;
    string symbol;
    bit is_la64;
    is_la64 = (LA64 inside {riscv_instr_pkg::supported_isa});
    
    // For LA64, expand la pseudo-instruction using pcaddu18i + addi.d with PC-relative addressing
    // Correct LA64 syntax: pcaddu18i $rd, %pc_hi20(symbol) + addi.d $rd, $rd, %pc_lo12(symbol)
    if (is_la64 && pseudo_instr_name == LA) begin
      string indent_str;
      symbol = get_imm();
      // Use pcaddu18i to load high 20 bits of PC-relative address
      // Then use addi.d to add low 12 bits
      // Note: prefix is added externally, so we need to add same-length indent for second line
      indent_str = format_string(" ", LABEL_STR_LEN);
      asm_str = "pcaddu18i $";
      asm_str = {asm_str, rd.name(), ", %pc_hi20(", symbol, ")"};
      if(comment != "")
        asm_str = {asm_str, " #", comment};
      asm_str = {asm_str, "\n", indent_str};
      asm_str = {asm_str, "addi.d $", rd.name(), ", $", rd.name(), ", %pc_lo12(", symbol, ")"};
      return asm_str.tolower();
    end else begin
      // For LI or non-LA64, use original format
      asm_str = format_string(get_instr_name(), MAX_INSTR_STR_LEN);
      // instr rd,imm
      asm_str = $sformatf("%0s%0s%0s, %0s", prefix, asm_str, rd.name(), get_imm());
      if(comment != "")
        asm_str = {asm_str, " #",comment};
      return asm_str.tolower();
    end
  endfunction

  virtual function string get_instr_name();
    return pseudo_instr_name.name();
  endfunction

endclass
