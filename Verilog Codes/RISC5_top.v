`include "programCounter.v"
`include "instructionMemory.v"
`include "controlUnit.v"
`include "registerFile.v"
`include "alu.v"
`include "aluControl.v"
`include "signExtend.v"
`include "dataMemory.v"
`include "mux.v"
`include "pcAdder.v"

`timescale 1ns/1ps

module RISC5_top(input clk, input rst);

  wire [31:0] PC, PC_plus4, PC_branch, PC_jalr_target, PC_jal_target, PC_next;
  wire [31:0] Instr;

  wire [6:0] opcode = Instr[6:0];
  wire [2:0] funct3 = Instr[14:12];
  wire [6:0] funct7 = Instr[31:25];
  wire [4:0] rs1 = Instr[19:15], rs2 = Instr[24:20], rd = Instr[11:7];

  wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
  wire Jal, Jalr;
  wire [1:0] ALUOp;
  wire [3:0] ALUControl;
  wire Zero;

  wire [31:0] RD1, RD2, Imm;
  wire [31:0] ALU_in2, ALU_out, ReadData, WriteData;


  pcAdder PCA(PC, PC_plus4);

  assign PC_branch = PC + Imm;

  assign PC_jal_target = PC + Imm;
  assign PC_jalr_target = (RD1 + Imm) & 32'hfffffffe;

  
  wire slt_result = ALU_out[0]; 

  wire takeBranch = (Branch && (
                      (funct3 == 3'b000 &&  Zero) ||     
                      (funct3 == 3'b001 && !Zero) ||     
                      (funct3 == 3'b100 &&  slt_result) || 
                      (funct3 == 3'b101 && !slt_result)  
                    ));

  
  assign PC_next = Jalr ? PC_jalr_target :
                   Jal  ? PC_jal_target  :
                   takeBranch ? PC_branch :
                   PC_plus4;

  programCounter PC_reg(clk, rst, PC_next, PC);
  instructionMemory IM(PC, Instr);
  controlUnit CU(opcode, Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite, Jal, Jalr);
  registerFile RF(clk, RegWrite, rs1, rs2, rd, WriteData, RD1, RD2);
  signExtend SE(Instr, opcode, Imm);
  mux2to1 MUX_ALU(RD2, Imm, ALUSrc, ALU_in2);
  aluControl ALUCTRL(ALUOp, funct3, funct7, ALUControl);
  alu ALU(RD1, ALU_in2, ALUControl, ALU_out, Zero);
  dataMemory DM(clk, MemWrite, MemRead, ALU_out, RD2, ReadData);

  wire [31:0] WriteData_from_jal = PC_plus4;
  wire [31:0] WriteData_from_mem;
  wire write_jal = Jal | Jalr;
  
  mux2to1 MUX_MEM(ALU_out, ReadData, MemtoReg, WriteData_from_mem);
  mux2to1 MUX_JAL(WriteData_from_mem, WriteData_from_jal, write_jal, WriteData);

endmodule