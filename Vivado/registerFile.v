`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 12:39:19
// Design Name: 
// Module Name: registerFile
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


module registerFile(
  input clk,
  input RegWrite,
  input [4:0] rs1, rs2, rd,
  input [31:0] writeData,
  output [31:0] readData1, readData2
);

  reg [31:0] registers[0:31];
  integer i;
  assign readData1 = (rs1 != 5'd0) ? registers[rs1] : 32'b0;
  assign readData2 = (rs2 != 5'd0) ? registers[rs2] : 32'b0;
  always @(posedge clk) begin
    if (RegWrite && rd != 5'd0) begin
      registers[rd] <= writeData;
      //$display("RegWrite: x%0d <= %0d at time %0t", rd, writeData, $time);
    end
  end
  initial begin
    for (i = 0; i < 32; i = i + 1) begin
      registers[i] = 32'b0;
    end
  end
endmodule

