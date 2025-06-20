`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 12:37:20
// Design Name: 
// Module Name: dataMemory
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


module dataMemory(
  input clk,
  input MemWrite, MemRead,
  input [31:0] addr, writeData,
  output [31:0] readData
);
  reg [31:0] memory [0:255]; 
  wire [7:0] mem_index = addr[9:2]; 
  integer i;
  always @(posedge clk) begin
    if (MemWrite) begin
      if (mem_index < 256) begin
        memory[mem_index] <= writeData;
      end else begin
        $display("Write out-of-bounds: addr=0x%0h", addr);
      end
    end
  end
  assign readData = (MemRead && mem_index < 256) ? memory[mem_index] : 32'b0;
  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      memory[i] = 32'd0;
    end
  end
endmodule

