`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 12:40:20
// Design Name: 
// Module Name: RISCV_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RISC5_top(input clk, input rst);

  wire [31:0] PC, PC_plus4, PC_branch, PC_jalr_target, PC_jal_target, PC_next;
  wire [31:0] Instr;

  wire [6:0] opcode = Instr[6:0];
  wire [2:0] funct3 = Instr[14:12];
  wire [6:0] funct7 = Instr[31:25];
  wire [4:0] rs1 = Instr[19:15], rs2 = Instr[24:20], rd = Instr[11:7];

  wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
  wire Jal, Jalr, Lui, Auipc;
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
                      (funct3 == 3'b000 &&  Zero) ||     // BEQ
                      (funct3 == 3'b001 && !Zero) ||     // BNE
                      (funct3 == 3'b100 &&  slt_result) || // BLT
                      (funct3 == 3'b101 && !slt_result) || // BGE
                      (funct3 == 3'b110 &&  slt_result) || // BLTU (using ALU[0] for comparison result)
                      (funct3 == 3'b111 && !slt_result)    // BGEU
                    ));

  assign PC_next = Jalr        ? PC_jalr_target :
                   Jal         ? PC_jal_target  :
                   takeBranch  ? PC_branch      :
                                 PC_plus4;

  programCounter PC_reg(clk, rst, PC_next, PC);
  instructionMemory IM(PC, Instr);

  // Updated control unit with Lui and Auipc support
  controlUnit CU(opcode, Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite, Jal, Jalr, Lui, Auipc);
  
  registerFile RF(clk, RegWrite, rs1, rs2, rd, WriteData, RD1, RD2);
  signExtend SE(Instr, opcode, Imm); 

  mux2to1 MUX_ALU(RD2, Imm, ALUSrc, ALU_in2);
  aluControl ALUCTRL(ALUOp, funct3, funct7, ALUControl);
  alu ALU(RD1, ALU_in2, ALUControl, ALU_out, Zero);
  dataMemory DM(clk, MemWrite, MemRead, ALU_out, RD2, ReadData);

  // Data to write back to register (3-way mux)
  wire [31:0] WriteData_from_mem;
  wire [31:0] WriteData_from_jal = PC_plus4;
  wire [31:0] WriteData_from_lui = Imm;
  wire [31:0] WriteData_from_auipc = PC + Imm;

  wire write_jal = Jal | Jalr;
  wire write_lui = Lui;
  wire write_auipc = Auipc;

  // MUX1: ALU vs Mem
  mux2to1 MUX_MEM(ALU_out, ReadData, MemtoReg, WriteData_from_mem);

  // MUX2: result vs PC+4 for Jal
  assign WriteData = write_lui   ? WriteData_from_lui   :
                   write_auipc ? WriteData_from_auipc :
                   write_jal   ? WriteData_from_jal   :
                   MemtoReg    ? ReadData             :
                                  ALU_out;
//  initial begin
//    $monitor("T=%0t | PC=%h Instr=%h | Opcode = %b | funct3 = %b | funct7 = %b | Imm=%h | WriteData=%h", $time, PC, Instr, opcode, funct3, funct7, Imm, WriteData);
//  end
endmodule

