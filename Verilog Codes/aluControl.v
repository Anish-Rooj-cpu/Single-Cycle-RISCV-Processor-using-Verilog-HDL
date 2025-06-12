`timescale 1ns/1ps
module aluControl(
  input [1:0] ALUOp,
  input [2:0] funct3,
  input [6:0] funct7,
  output reg [3:0] ALUControl
);
  always @(*) begin
  case (ALUOp)
    2'b00: ALUControl = 4'b0010; // lw/sw -> add
    2'b01: begin
      case (funct3)
        3'b000: ALUControl = 4'b0110; // beq: sub
        3'b001: ALUControl = 4'b0110; // bne: sub
        3'b100: ALUControl = 4'b0111; // blt
        3'b101: ALUControl = 4'b0111; // bge
        default: ALUControl = 4'b1111;
      endcase
    end
    2'b10: begin
      // Decode both R-type and I-type
      if (funct7 == 7'b0000000) begin
        case (funct3)
          3'b000: ALUControl = 4'b0010; // ADD (or ADDI)
          3'b111: ALUControl = 4'b0000; // AND (or ANDI)
          3'b110: ALUControl = 4'b0001; // OR (or ORI)
          3'b010: ALUControl = 4'b0111; // SLT (or SLTI)
          default: ALUControl = 4'b1111;
        endcase
      end else begin
        case ({funct7, funct3})
          10'b0000000000: ALUControl = 4'b0010;// ADD
          10'b0100000000: ALUControl = 4'b0110; // SUB
          default: ALUControl = 4'b0010;        // Default to ADD
        endcase
      end
    end
    default: ALUControl = 4'b1111;
  endcase
end

endmodule
