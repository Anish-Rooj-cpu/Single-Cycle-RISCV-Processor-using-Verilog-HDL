`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 12:37:39
// Design Name: 
// Module Name: aluControl
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


module aluControl(
    input  [1:0] ALUOp,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output reg [3:0] ALUControl
);
    always @(*) begin
        case (ALUOp)
            2'b00: // Load/Store
                ALUControl = 4'b0010; // ADD
            2'b01: begin
              case (funct3)
                3'b000: ALUControl = 4'b0110; // BEQ → SUB
                3'b001: ALUControl = 4'b0110; // BNE → SUB
                3'b100: ALUControl = 4'b0111; // BLT → SLT
                3'b101: ALUControl = 4'b0111; // BGE → SLT
                3'b110: ALUControl = 4'b1000; // BLTU → SLTU
                3'b111: ALUControl = 4'b1000; // BGEU → SLTU
                default: ALUControl = 4'b1111;
              endcase
            end

            2'b10: begin
      // Decode both R-type and I-type
              if (funct7 == 7'b0000000) begin
                case (funct3)
                  3'b000: ALUControl = 4'b0010; // ADD (or ADDI)
                  3'b001: ALUControl = 4'b0100; // SLL (or SLLI)
                  3'b010: ALUControl = 4'b0111; // SLT (or SLTI)
                  3'b011: ALUControl = 4'b1000; // SLTU (or SLTIU)
                  3'b100: ALUControl = 4'b0011; // XOR (or XORI)
                  3'b101: ALUControl = 4'b0101; // SRL (or SRLI)
                  3'b110: ALUControl = 4'b0001; // OR (or ORI)
                  3'b111: ALUControl = 4'b0000; // AND (or ANDI)
                  default: ALUControl = 4'b1111;
                endcase
              end else begin
                case ({funct7, funct3})
                  10'b0100000000: ALUControl = 4'b0110; // SUB
                  10'b0100000101: ALUControl = 4'b1101; // SRA
                  default: ALUControl = 4'b0010;        // Default to ADD
                endcase
              end
            end
          default: ALUControl = 4'b1111;
        endcase
    end
endmodule

