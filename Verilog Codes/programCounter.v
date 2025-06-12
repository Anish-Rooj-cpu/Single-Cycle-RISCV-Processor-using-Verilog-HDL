`timescale 1ns/1ps
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
    //$display("PC updated to 0x%08h at time %0t", rst ? 0 : pc_in, $time);
  end
endmodule
