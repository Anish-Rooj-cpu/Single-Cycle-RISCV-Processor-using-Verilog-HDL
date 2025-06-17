`timescale 1ns/1ps
module controlUnit(
  input [6:0] opcode,
  output reg Branch, MemRead, MemtoReg,
  output reg [1:0] ALUOp,
  output reg MemWrite, ALUSrc, RegWrite,
  output reg Jal, Jalr,
  output reg Lui, Auipc
);

  always @(*) begin
    // Default values
    Branch = 0; MemRead = 0; MemtoReg = 0;
    MemWrite = 0; ALUSrc = 0; RegWrite = 0;
    ALUOp = 2'b00;
    Jal = 0; Jalr = 0;
    Lui = 0; Auipc = 0;

    case (opcode)
      7'b0110011: begin // R-type
        ALUSrc = 0;
        RegWrite = 1;
        ALUOp = 2'b10;
      end

      7'b0010011: begin // I-type ALU (ADDI, SLTI, ANDI, SLLI, etc.)
        ALUSrc = 1;
        RegWrite = 1;
        ALUOp = 2'b10;
      end

      7'b0000011: begin // Load (LB, LH, LW, LBU, LHU)
        ALUSrc = 1;
        RegWrite = 1;
        MemRead = 1;
        MemtoReg = 1;
        ALUOp = 2'b00;
      end

      7'b0100011: begin // Store (SB, SH, SW)
        ALUSrc = 1;
        MemWrite = 1;
        ALUOp = 2'b00;
      end

      7'b1100011: begin // Branch (BEQ, BNE, etc.)
        ALUSrc = 0;
        Branch = 1;
        ALUOp = 2'b01;
      end

      7'b1101111: begin // JAL
        RegWrite = 1;
        Jal = 1;
        ALUOp = 2'b00; // Not used
      end

      7'b1100111: begin // JALR
        RegWrite = 1;
        Jalr = 1;
        ALUSrc = 1;
        ALUOp = 2'b00; // Not used
      end

      7'b0110111: begin // LUI
        RegWrite = 1;
        Lui = 1;
        ALUOp = 2'b00; // Not used
      end

      7'b0010111: begin // AUIPC
        RegWrite = 1;
        Auipc = 1;
        ALUOp = 2'b00; // Uses PC + Imm in top-level
      end

      default: begin
        // Already covered by default values above
      end
    endcase
  end

endmodule
