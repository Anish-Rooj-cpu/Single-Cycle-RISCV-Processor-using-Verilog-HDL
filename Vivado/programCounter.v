`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 12:36:12
// Design Name: 
// Module Name: programCounter
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


module programCounter(
  input clk, rst,
  input [31:0] pc_in,
  output reg [31:0] pc_out
);
  always @(posedge clk or posedge rst) begin
    if (rst)
      pc_out <= 0;
    else
      pc_out <= pc_in;
//     $display("PC updated to 0x%08h at time %0t", rst ? 0 : pc_in, $time);
  end
endmodule

