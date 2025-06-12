`timescale 1ns/1ps
module pcAdder(
  input [31:0] pc,
  output [31:0] pc_next
);
  assign pc_next = pc + 4;
endmodule
