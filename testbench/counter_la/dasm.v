// SPDX-License-Identifier: Apache-2.0
// Copyright 2019 Western Digital Corporation or its affiliates.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// Run time disassembler functions
// supports  RISCV extentions I, C, M, A
`ifndef RV_NUM_THREADS
`define RV_NUM_THREADS 1
`endif

// bit[31:0] [31:0] gpr[`RV_NUM_THREADS];
// 2^5 = 32
   reg [31:0] gpr[32];

// main DASM function
function string dasm(input[31:0] opcode,
                     input[31:0] pc,
                     input[ 4:0] regn, 
                     input[31:0] regv
                    );
  /*
  string sss0;
  string sss1;
  string ssss;

  sss0 = "000";
  sss1 = "111";
  */
//$display("%t 0x%04h 0x%04h 0x%02h 0x%04h", $time, pc, opcode, regn, regv);
//dasm = (opcode[1:0] == 2'b11) ? dasm32(opcode, pc, tid) : dasm16(opcode, pc, tid);
//ssss = (opcode[1:0] == 2'b11) ? dasm32(opcode, pc,   0) : dasm16(opcode, pc,   0);
//sss0 = dasm16(opcode, pc,   0);
//sss1 = dasm32(opcode, pc,   0);
//ssss = dasm16(opcode, pc,   0);
//if(regn) gpr[tid][regn] = regv;
  if( |regn ) 
   gpr[regn] = regv;

//$display("++ %s %s %s ++", sss1, sss0, ssss);
//ssss = (opcode[1:0] == 2'b11) ? sss1 : sss0;
//$display("-- %s %s %s --", sss1, sss0, ssss);
//return(ssss); 
  if( opcode[1:0] == 2'b11 )
// return(sss1);
   return(dasm32(opcode, pc, 0));
  else
// return(sss0);
   return(dasm16(opcode, pc, 0));
endfunction


///////////////// 16 bits instructions ///////////////////////

function string dasm16( input[31:0] opcode, input[31:0] pc, input tid=0);
//  $display("%s 0x%04h 0x%04h", "dasm16", pc, opcode);
    case(opcode[1:0])
    0: return dasm16_0(opcode, tid);
    1: return dasm16_1(opcode, pc);
    2: return dasm16_2(opcode);
    endcase
    return $sformatf(".short 0x%h", opcode[15:0]);
endfunction

function string dasm16_0 (input[31:0] opcode, tid);
//  $display("%s 0x%04h", "dasm16_0", opcode);
    case(opcode[15:13])
    3'b000: return dasm16_ciw(opcode);
    3'b001: return {"c.fld  ", dasm16_cl(opcode, tid)};
    3'b010: return {"c.lw   ", dasm16_cl(opcode, tid)};
    3'b011: return {"c.flw  ", dasm16_cl(opcode, tid)};
    3'b101: return {"c.fsd  ", dasm16_cl(opcode, tid)};
    3'b110: return {"c.sw   ", dasm16_cl(opcode, tid)};
    3'b111: return {"c.fsw  ", dasm16_cl(opcode, tid)};
    endcase
    return $sformatf(".short  0x%h", opcode[15:0]);
endfunction

function string dasm16_ciw (input[31:0] opcode);
    int imm;
    imm=0;
//  $display("%s 0x%04h", "dasm16_ciw", opcode);
    if(opcode[15:0] == 0)
      return (".short  0");
    else begin
     {imm[5:4],imm[9:6],imm[2],imm[3]} = opcode[12:5];
     return $sformatf("c.addi4spn %s,0x%0h", abi_reg[opcode[4:2]+8], imm);
    end

endfunction

function string dasm16_cl( input[31:0] opcode, input tid=0);
int imm;
    imm=0;
    imm[5:3] = opcode[12:10];
    imm[7:6] = opcode[6:5];

//  return $sformatf(" %s,%0d(%s) [%h]", abi_reg[opcode[4:2]+8], imm, abi_reg[opcode[9:7]+8], gpr[tid][opcode[9:7]+8]+imm);
    return $sformatf(" %s,%0d(%s) [%h]", abi_reg[opcode[4:2]+8], imm, abi_reg[opcode[9:7]+8], gpr[opcode[9:7]+8]+imm);
endfunction


function string dasm16_1( input[31:0] opcode, input[31:0] pc);
//  string tmp_str = {"c.addi  ", dasm16_ci(opcode)};
    case(opcode[15:13])
    /*
    3'b000: return (opcode[11:7]==5'h00)? "c.nop" : {"c.addi  ",dasm16_ci(opcode)};
    */
    3'b000: return (opcode[11:7]==5'h00)? "c.nop" :  "c.addi  ";  // TBD
    /*
    3'b000: return (opcode[11:7]==5'h00)? "c.nop" :  tmp_str;  // TBD
    */
    3'b001: return {"c.jal   ", dasm16_cj(opcode, pc)};
    3'b010: return {"c.li    ", dasm16_ci(opcode)};
    3'b011: return dasm16_1_3(opcode);
    3'b100: return dasm16_cr(opcode);
    3'b101: return {"c.j     ", dasm16_cj(opcode, pc)};
    3'b110: return {"c.beqz  ", dasm16_cb(opcode, pc)};
    3'b111: return {"c.bnez  ", dasm16_cb(opcode, pc)};
    endcase
endfunction


function string dasm16_ci( input[31:0] opcode);
int imm;
    imm=0;
    imm[4:0] = opcode[6:2];
    if(opcode[12]) imm [31:5] = '1;
    return $sformatf("%s,%0d", abi_reg[opcode[11:7]], imm);
endfunction

function string dasm16_cj( input[31:0] opcode, input[31:0] pc);
bit[31:0] imm;
    imm=0;
    {imm[11],imm[4],imm[9:8],imm[10],imm[6], imm[7],imm[3:1], imm[5]} = opcode[12:2];
    if(opcode[12]) imm [31:12] = '1;
    return $sformatf("0x%0h", imm+pc);
endfunction

function string dasm16_cb( input[31:0] opcode, input[31:0] pc);
bit[31:0] imm;
    imm=0;
    {imm[8],imm[4:3]} = opcode[12:10];
    {imm[7:6],imm[2:1], imm[5]} = opcode[6:2];
    if(opcode[12]) imm [31:9] = '1;
    return $sformatf("%s,0x%0h",abi_reg[opcode[9:7]+8], imm+pc);
endfunction

function string dasm16_cr( input[31:0] opcode);
bit[31:0] imm;

    imm = 0;
    imm[4:0] = opcode[6:2];
    if(opcode[5]) imm [31:5] = '1;
    case(opcode[11:10])
    0: return $sformatf("c.srli  %s,%0d",  abi_reg[opcode[9:7]+8], imm[5:0]);
    1: return $sformatf("c.srai  %s,%0d",  abi_reg[opcode[9:7]+8], imm[5:0]);
    2: return $sformatf("c.andi  %s,0x%0h", abi_reg[opcode[9:7]+8], imm);
    endcase

    case(opcode[6:5])
    0: return $sformatf("c.sub   %s,%s", abi_reg[opcode[9:7]+8], abi_reg[opcode[4:2]+8]);
    1: return $sformatf("c.xor   %s,%s", abi_reg[opcode[9:7]+8], abi_reg[opcode[4:2]+8]);
    2: return $sformatf("c.or    %s,%s", abi_reg[opcode[9:7]+8], abi_reg[opcode[4:2]+8]);
    3: return $sformatf("c.and   %s,%s", abi_reg[opcode[9:7]+8], abi_reg[opcode[4:2]+8]);
    endcase
endfunction

function string dasm16_1_3( input[31:0] opcode);
int imm;

    imm=0;
    if(opcode[11:7] == 2) begin
        {imm[4], imm[6],imm[8:7], imm[5]} = opcode[6:2];
        if(opcode[12]) imm [31:9] = '1;
        return $sformatf("c.addi16sp %0d", imm);
    end
    else begin
        imm[16:12] = opcode[6:2];
        if(opcode[12]) imm [31:17] = '1;
        return $sformatf("c.lui   %s,0x%0h", abi_reg[opcode[11:7]], imm);

    end
endfunction

function string dasm16_2( input[31:0] opcode, input tid=0);
    case(opcode[15:13])
    3'b000: return {"c.slli  ", dasm16_ci(opcode)};
    3'b001: return {"c.fldsp ", dasm16_cls(opcode,1,tid)};
    3'b010: return {"c.lwsp  ", dasm16_cls(opcode,0,tid)};
    3'b011: return {"c.flwsp ", dasm16_cls(opcode,0,tid)};
    3'b101: return {"c.fsdsp ", dasm16_css(opcode,1,tid)};
    3'b110: return {"c.swsp  ", dasm16_css(opcode,0,tid)};
    3'b111: return {"c.fswsp ", dasm16_css(opcode,0,tid)};
    endcase
    if(opcode[12]) begin
        if(opcode[12:2] == 0) return "c.ebreak";
        else if(opcode[6:2] == 0) return $sformatf("c.jalr  %s", abi_reg[opcode[11:7]]);
        else return $sformatf("c.add   %s,%s", abi_reg[opcode[11:7]], abi_reg[opcode[6:2]]);
    end
    else begin
        if(opcode[6:2] == 0) return $sformatf("c.jr    %s", abi_reg[opcode[11:7]]);
        else return $sformatf("c.mv    %s,%s", abi_reg[opcode[11:7]], abi_reg[opcode[6:2]]);
    end
endfunction


function string dasm16_cls( input[31:0] opcode, input sh1=0, tid=0);
bit[31:0] imm;
    imm=0;
    if(sh1) {imm[4:3],imm[8:6]} = opcode[6:2];
    else    {imm[4:2],imm[7:6]} = opcode[6:2];
    imm[5] = opcode[12];
//  return $sformatf("%s,0x%0h [%h]", abi_reg[opcode[11:7]], imm, gpr[tid][2]+imm);
    return $sformatf("%s,0x%0h [%h]", abi_reg[opcode[11:7]], imm, gpr[2]+imm);
endfunction

function string dasm16_css( input[31:0] opcode, input sh1=0, tid=0);
bit[31:0] imm;
    imm=0;
    if(sh1) {imm[5:3],imm[8:6]} = opcode[12:7];
    else {imm[5:2],imm[7:6]} = opcode[12:7];
//  return $sformatf("%s,0x%0h [%h]", abi_reg[opcode[6:2]], imm, gpr[tid][2]+imm);
    return $sformatf("%s,0x%0h [%h]", abi_reg[opcode[6:2]], imm, gpr[2]+imm);
endfunction

///////////////// 32 bit instructions ///////////////////////

function string dasm32( input[31:0] opcode, input[31:0] pc, input tid=0);
//  $display("%s 0x%04h 0x%04h 0x%02h", "dasm32 start", pc, opcode, tid);
    case(opcode[6:0])
    7'b0110111: return {"lui     ", dasm32_u(opcode)};
    7'b0010111: return {"auipc   ", dasm32_u(opcode)};
    7'b1101111: return {"jal     ", dasm32_j(opcode,pc)};
    7'b1100111: return {"jalr    ", dasm32_jr(opcode,pc)};
    7'b1100011: return dasm32_b(opcode,pc);
    7'b0000011: return dasm32_l(opcode,tid);
    7'b0100011: return dasm32_s(opcode,tid);
    7'b0010011: return dasm32_ai(opcode);
    7'b0110011: return dasm32_ar(opcode);
    7'b0001111: return {"fence", dasm32_fence(opcode)};
    7'b1110011: return dasm32_e(opcode);
    7'b0101111: return dasm32_a(opcode,tid);
    endcase
//  $display("%s 0x%04h 0x%04h 0x%02h", "dasm32   end", pc, opcode, tid);
    return $sformatf(".long   0x%h", opcode);
endfunction

function string dasm32_u( input[31:0] opcode);
bit[31:0] imm;
    imm=0;
    imm[31:12] = opcode[31:12];
    return $sformatf("%s,0x%0h", abi_reg[opcode[11:7]], imm);
endfunction

function string dasm32_j( input[31:0] opcode, input[31:0] pc);
int imm;
    imm=0;
    {imm[20], imm[10:1], imm[11], imm[19:12]} = opcode[31:12];
    if(opcode[31]) imm[31:20] = '1;
    return $sformatf("%s,0x%0h",abi_reg[opcode[11:7]], imm+pc);
endfunction

function string dasm32_jr( input[31:0] opcode, input[31:0] pc);
int imm;
    imm=0;
    imm[11:1] = opcode[31:19];
    if(opcode[31]) imm[31:12] = '1;
    return $sformatf("%s,%s,0x%0h",abi_reg[opcode[11:7]], abi_reg[opcode[19:15]], imm+pc);
endfunction

function string dasm32_b( input[31:0] opcode, input[31:0] pc);
int imm;
string mn;
    imm=0;
    {imm[12],imm[10:5]} = opcode[31:25];
    {imm[4:1],imm[11]} = opcode[11:7];
    if(opcode[31]) imm[31:12] = '1;
    case(opcode[14:12])
    0: mn = "beq     ";
    1: mn = "bne     ";
    2,3 : return $sformatf(".long    0x%h", opcode);
    4: mn = "blt     ";
    5: mn = "bge     ";
    6: mn = "bltu    ";
    7: mn = "bgeu    ";
    endcase
    return $sformatf("%s%s,%s,0x%0h", mn, abi_reg[opcode[19:15]], abi_reg[opcode[24:20]], imm+pc);
endfunction

function string dasm32_l( input[31:0] opcode, input tid=0);
int imm;
string mn;
    imm=0;
    imm[11:0] = opcode[31:20];
    if(opcode[31]) imm[31:12] = '1;
    case(opcode[14:12])
    0: mn = "lb      ";
    1: mn = "lh      ";
    2: mn = "lw      ";
    4: mn = "lbu     ";
    5: mn = "lhu     ";
    default : return $sformatf(".long   0x%h", opcode);
    endcase
//  return $sformatf("%s%s,%0d(%s) [%h]", mn, abi_reg[opcode[11:7]], imm, abi_reg[opcode[19:15]], imm+gpr[tid][opcode[19:15]]);
    return $sformatf("%s%s,%0d(%s) [%h]", mn, abi_reg[opcode[11:7]], imm, abi_reg[opcode[19:15]], imm+gpr[opcode[19:15]]);
endfunction

function string dasm32_s( input[31:0] opcode, input tid=0);
int imm;
string mn;
    imm=0;
    imm[11:5] = opcode[31:25];
    imm[4:0] = opcode[11:7];
    if(opcode[31]) imm[31:12] = '1;
    case(opcode[14:12])
    0: mn = "sb      ";
    1: mn = "sh      ";
    2: mn = "sw      ";
    default : return $sformatf(".long   0x%h", opcode);
    endcase
//  return $sformatf("%s%s,%0d(%s) [%h]", mn, abi_reg[opcode[24:20]], imm, abi_reg[opcode[19:15]], imm+gpr[tid][opcode[19:15]]);
    return $sformatf("%s%s,%0d(%s) [%h]", mn, abi_reg[opcode[24:20]], imm, abi_reg[opcode[19:15]], imm+gpr[opcode[19:15]]);
endfunction

function string dasm32_ai( input[31:0] opcode);
int imm;
string mn;
    imm=0;
    imm[11:0] = opcode[31:20];
    if(opcode[31]) imm[31:12] = '1;
    case(opcode[14:12])
    0: mn = "addi    ";
    2: mn = "slti    ";
    3: mn = "sltiu   ";
    4: mn = "xori    ";
    6: mn = "ori     ";
    7: mn = "andi    ";
    default: return dasm32_si(opcode);
endcase

return $sformatf("%s%s,%s,%0d", mn, abi_reg[opcode[11:7]], abi_reg[opcode[19:15]], imm);
endfunction

function string dasm32_si( input[31:0] opcode);
int imm;
string mn;
    imm = opcode[24:20];
    case(opcode[14:12])
    1: mn = "slli";
    5: mn = opcode[30] ? "srli": "srai";
    endcase

    return $sformatf("%s    %s,%s,%0d", mn, abi_reg[opcode[11:7]], abi_reg[opcode[19:15]], imm);
endfunction



function string dasm32_ar( input[31:0] opcode);
string mn;
    if(opcode[25])
        case(opcode[14:12])
        0: mn = "mul     ";
        1: mn = "mulh    ";
        2: mn = "mulhsu  ";
        3: mn = "mulhu   ";
        4: mn = "div     ";
        5: mn = "divu    ";
        6: mn = "rem     ";
        7: mn = "remu    ";
        endcase
    else
        case(opcode[14:12])
        0: mn = opcode[30]? "sub     ":"add     ";
        1: mn = "sll     ";
        2: mn = "slt     ";
        3: mn = "sltu    ";
        4: mn = "xor     ";
        5: mn = opcode[30]? "sra     ":"srl     ";
        6: mn = "or      ";
        7: mn = "and     ";
        endcase
    return $sformatf("%s%s,%s,%s", mn, abi_reg[opcode[11:7]], abi_reg[opcode[19:15]], abi_reg[opcode[24:20]]);
endfunction

function string dasm32_fence( input[31:0] opcode);
    return  opcode[12] ? ".i" : "";
endfunction

function string dasm32_e(input[31:0] opcode);
    if(opcode[31:7] == 0) return "ecall";
    else if({opcode[31:21],opcode [19:7]} == 0) return "ebreak";
    else
        case(opcode[14:12])
        1: return {"csrrw   ", dasm32_csr(opcode)};
        2: return {"csrrs   ", dasm32_csr(opcode)};
        3: return {"csrrc   ", dasm32_csr(opcode)};
        5: return {"csrrwi  ", dasm32_csr(opcode, 1)};
        6: return {"csrrsi  ", dasm32_csr(opcode, 1)};
        7: return {"csrrci  ", dasm32_csr(opcode, 1)};
        endcase

endfunction


// page 10~13 of "RISC-V Privileged Architectures"
function string get_csr_name(input[11:0] csr_index);
 string sss;
 case(csr_index)
  // User Trap Setup
  12'h000: sss = "ustatus";   //  User status register.
  12'h004: sss = "uie";       //  User interrupt-enable register.
  12'h005: sss = "utvec";     //  User trap handler base address.

  // User Trap Handling
  12'h040: sss = "uscratch";  // Scratch register for user trap handlers.
  12'h041: sss = "uepc";      // User exception program counter.
  12'h042: sss = "ucause";    // User trap cause.
  12'h043: sss = "ubadaddr";  // User bad address.
  12'h044: sss = "uip";       // User interrupt pending.

  // User Counter
  12'hC00: sss = "cycle";     // User interrupt pending.
  12'hC01: sss = "time";      // User interrupt pending.

  // Machine Information Register
  12'hF11: sss = "mvendorid"; //  Vendor ID.
  12'hF12: sss = "marchid";   //  Architecture ID.
  12'hF13: sss = "mimpid";    //  Implementation ID.
  12'hF14: sss = "mhartid";   //  Hardware thread ID.

  // Machine Trap Setup
  12'h300: sss = "mstatus";   //  Machine status register.
  12'h301: sss = "misa";      //  ISA and extensions
  12'h302: sss = "medeleg";   //  Machine exception delegation register.
  12'h303: sss = "mideleg";   //  Machine interrupt delegation register.
  12'h304: sss = "mie";       //  Machine interrupt-enable register.
  12'h305: sss = "mtvec";     //  Machine trap-handler base address.

  // Machine Trap Handling
  12'h340: sss = "mscratch";  //  Scratch register for machine trap handlers.
  12'h341: sss = "mepc";      //  Machine exception program counter.
  12'h342: sss = "mcause";    //  Machine trap cause.
  12'h343: sss = "mbadaddr";  //  Machine bad address.
  12'h344: sss = "mip";       //  Machine interrupt pending.

  // Machine Protection and Translation
  12'h380: sss = "mbase";     //  Base register.
  12'h381: sss = "mbound";    //  Bound register.
  12'h382: sss = "mibase";    //  Instruction base register.
  12'h383: sss = "mibound";   //  Instruction bound register.
  12'h384: sss = "mdbase";    //  Data base register.
  12'h385: sss = "mdbound";   //  Data bound register.
  default: sss = $sformatf("csr_%03h", csr_index);
 endcase
 return(sss);
endfunction


function string dasm32_csr(input[31:0] opcode, input im=0);
  bit[11:0] csr;
  csr = opcode[31:20];
  if(im) begin
  //return $sformatf("%s,csr_%0h,0x%h", abi_reg[opcode[11:7]],               csr, opcode[19:15]);
    return $sformatf("%s, %s,0x%h",     abi_reg[opcode[11:7]], get_csr_name(csr), opcode[19:15]);
    end
  else begin
  //return $sformatf("%s,csr_%0h,%s",  abi_reg[opcode[11:7]],               csr, abi_reg[opcode[19:15]]);
    return $sformatf("%s, %s,%s",      abi_reg[opcode[11:7]], get_csr_name(csr), abi_reg[opcode[19:15]]);
  end

endfunction

//atomics
function string dasm32_a(input[31:0] opcode, input tid=0);
    case(opcode[31:27])
//  'b00010: return $sformatf("lr.w    %s,(%s) [%h]",    abi_reg[opcode[11:7]],                         abi_reg[opcode[19:15]], gpr[tid][opcode[19:15]]);
//  'b00011: return $sformatf("sc.w    %s,%s,(%s) [%h]", abi_reg[opcode[11:7]], abi_reg[opcode[24:20]], abi_reg[opcode[19:15]], gpr[tid][opcode[19:15]]);
    'b00010: return $sformatf("lr.w    %s,(%s) [%h]",    abi_reg[opcode[11:7]],                         abi_reg[opcode[19:15]], gpr[opcode[19:15]]);
    'b00011: return $sformatf("sc.w    %s,%s,(%s) [%h]", abi_reg[opcode[11:7]], abi_reg[opcode[24:20]], abi_reg[opcode[19:15]], gpr[opcode[19:15]]);
    'b00001: return {"amoswap.w", dasm32_amo(opcode, tid)};
    'b00000: return {"amoadd.w",  dasm32_amo(opcode, tid)};
    'b00100: return {"amoxor.w",  dasm32_amo(opcode, tid)};
    'b01100: return {"amoand.w",  dasm32_amo(opcode, tid)};
    'b01000: return {"amoor.w",   dasm32_amo(opcode, tid)};
    'b10000: return {"amomin.w",  dasm32_amo(opcode, tid)};
    'b10100: return {"amomax.w",  dasm32_amo(opcode, tid)};
    'b11000: return {"amominu.w", dasm32_amo(opcode, tid)};
    'b11100: return {"amomaxu.w", dasm32_amo(opcode, tid)};
    endcase
    return $sformatf(".long 0x%h", opcode);
endfunction

function string dasm32_amo( input[31:0] opcode, input tid=0);
//  return $sformatf(" %s,%s,(%s) [%h]", abi_reg[opcode[11:7]], abi_reg[opcode[24:20]], abi_reg[opcode[19:15]], gpr[tid][opcode[19:15]]);
    return $sformatf(" %s,%s,(%s) [%h]", abi_reg[opcode[11:7]], abi_reg[opcode[24:20]], abi_reg[opcode[19:15]], gpr[opcode[19:15]]);
endfunction
