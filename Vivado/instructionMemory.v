`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 12:36:58
// Design Name: 
// Module Name: instructionMemory
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


module instructionMemory(
  input [31:0] addr,
  output [31:0] instruction
);

  reg [31:0] memory [0:255];
  integer i;

  assign instruction = memory[addr[9:2]];

  initial begin
    for (i = 0; i < 256; i = i + 1)
      memory[i] = 32'h00000013; 
    memory[0]  = 32'h00B00093;   // addi x1, x0, 11
    memory[1]  = 32'h00000113;   // addi x2, x0, 0
    memory[2]  = 32'h00100193;   // addi x3, x0, 1
    memory[3]  = 32'h00200293;   // addi x5, x0, 2
    memory[4]  = 32'h00310233;   // add  x4, x2, x3
    memory[5]  = 32'h00018133;   // add  x2, x3, x0
    memory[6]  = 32'h000201B3;   // add  x3, x4, x0
    memory[7]  = 32'hFFF08093;   // addi x1, x1, -1
    memory[8]  = 32'hFE5098E3;   // bne  x1, x0, -20 (to addr 0x10)
    memory[9]  = 32'h00018533;   // add  x10, x3, x0
  end
endmodule
