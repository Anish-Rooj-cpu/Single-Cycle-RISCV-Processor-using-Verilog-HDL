`timescale 1ns/1ps
module controlUnit(
  input [6:0] opcode,
  output reg Branch, MemRead, MemtoReg,
  output reg [1:0] ALUOp,
  output reg MemWrite, ALUSrc, RegWrite,
  output reg Jal, Jalr
);
  always @(*) begin
    Jal = 0; Jalr = 0;
    case (opcode)
      7'b0110011: begin // R-type
        ALUSrc = 0; MemtoReg = 0; RegWrite = 1;
        MemRead = 0; MemWrite = 0; Branch = 0;
        ALUOp = 2'b10;
      end
      7'b0000011: begin // Load
        ALUSrc = 1; MemtoReg = 1; RegWrite = 1;
        MemRead = 1; MemWrite = 0; Branch = 0;
        ALUOp = 2'b00;
      end
      7'b0100011: begin // Store
        ALUSrc = 1; MemtoReg = 0; RegWrite = 0;
        MemRead = 0; MemWrite = 1; Branch = 0;
        ALUOp = 2'b00;
      end
      7'b1100011: begin // Branch
        ALUSrc = 0; MemtoReg = 0; RegWrite = 0;
        MemRead = 0; MemWrite = 0; Branch = 1;
        ALUOp = 2'b01;
      end
      7'b0010011: begin // I-type 
        ALUSrc = 1; MemtoReg = 0; RegWrite = 1;
        MemRead = 0; MemWrite = 0; Branch = 0;
        ALUOp = 2'b10;
      end
      7'b1101111: begin // JAL
        ALUSrc = 0; MemtoReg = 0; RegWrite = 1;
        MemRead = 0; MemWrite = 0; Branch = 0;
        ALUOp = 2'b00;
        Jal = 1; Jalr = 0;
      end
      7'b1100111: begin // JALR
        ALUSrc = 1; MemtoReg = 0; RegWrite = 1;
        MemRead = 0; MemWrite = 0; Branch = 0;
        ALUOp = 2'b00;
        Jal = 0; Jalr = 1;
      end
      default: begin
        ALUSrc = 0; MemtoReg = 0; RegWrite = 0;
        MemRead = 0; MemWrite = 0; Branch = 0;
        ALUOp = 2'b00;
        Jal = 0; Jalr = 0;
      end
    endcase
  end
endmodule
