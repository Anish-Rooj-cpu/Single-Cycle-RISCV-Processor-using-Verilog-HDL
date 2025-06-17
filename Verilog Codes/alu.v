`timescale 1ns/1ps
module alu(
  input [31:0] A, B,
  input [3:0] ALUControl,
  output reg [31:0] Result,
  output reg Zero
);
  always @(*) begin
    case (ALUControl)
      4'b0000: Result = A & B;
      4'b0001: Result = A | B;
      4'b0010: Result = A + B;
      4'b0110: Result = A - B;
      4'b0111: Result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
      4'b1000: Result = (A < B) ? 32'd1 : 32'd0;
      4'b0011: Result = A ^ B;
      4'b0100: Result = A << B[4:0];
      4'b0101: Result = A >> B[4:0];
      4'b1101: Result = $signed(A) >>> A[4:0];
      default: Result = 32'h00000000;
    endcase

    Zero = (Result == 32'b0);  
    //$display("ALU: A=%0d, B=%0d, ctrl=%b, out=%0d", A, B, ALUControl, Result);
  end
endmodule
