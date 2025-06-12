`timescale 1ns/1ps
module signExtend(
  input [31:0] instr,
  input [6:0] opcode,
  output reg [31:0] imm
);

always @(*) begin
  case (opcode)
    7'b0000011, 7'b0010011, 7'b1100111: begin // I-type: lw, addi, jalr
      imm = {{20{instr[31]}}, instr[31:20]};
    end
    7'b0100011: begin // S-type: sw
      imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    end
    7'b1100011: begin // B-type: beq, bne
      imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    end
    7'b1101111: begin // J-type: jal
      imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
    end
    default: begin
      imm = 32'd0;
    end
  endcase
end

endmodule
