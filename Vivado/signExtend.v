`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 12:38:51
// Design Name: 
// Module Name: signExtend
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


module signExtend(
  input [31:0] instr,
  input [6:0] opcode,
  output reg [31:0] imm
);

always @(*) begin
  case (opcode)
    7'b0000011, // I-type: lw
    7'b0010011, // I-type: addi, andi, ori, etc.
    7'b1100111: // I-type: jalr
      imm = {{20{instr[31]}}, instr[31:20]};

    7'b0100011: // S-type: sw
      imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

    7'b1100011: // B-type: beq, bne, blt, etc.
      imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

    7'b1101111: // J-type: jal
      imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    7'b0110111, // U-type: lui
    7'b0010111: // U-type: auipc
      imm = {instr[31:12], 12'b0};

    default:
      imm = 32'd0;
  endcase
end
endmodule

