# Full RV32I assembler supporting R/I/S/B/U/J-type instructions.
# Outputs Verilog-style memory assignments:
#     memory[0] = 32'hXXXXXXXX;
#     memory[1] = 32'hYYYYYYYY;
#     ...
# Supports labels, comments, and all RV32I base instructions:
#   R-type:   add, sub, sll, slt, sltu, xor, srl, sra, or, and
#   I-type:   addi, andi, ori, xori, slti, sltiu, slli, srli, srai, lw, jalr
#   S-type:   sw
#   B-type:   beq, bne, blt, bge, bltu, bgeu
#   U-type:   lui, auipc
#   J-type:   jal
# Usage:
#     python rv32i_assembler.py [--input prog.asm] [--output out_mem.v]
# HARDCODE_INPUT_PATH / HARDCODE_OUTPUT_PATH can be set at top; if set and valid, they are used.


import argparse
import sys
import os
import re

# === Configuration: hardcoded paths (optional) ===
# If these are non-empty strings and point to valid file/dir, they will be used.
# Otherwise fall back to CLI args or interactive prompt.
HARDCODE_INPUT_PATH = r"E:\Multi Cycle RISCV Processor\test.asm"
HARDCODE_OUTPUT_PATH = r"E:\Multi Cycle RISCV Processor\test.v"

# === Instruction definitions ===
R_TYPE = {
    'add':  {'funct7': 0b0000000, 'funct3': 0b000, 'opcode': 0b0110011},
    'sub':  {'funct7': 0b0100000, 'funct3': 0b000, 'opcode': 0b0110011},
    'sll':  {'funct7': 0b0000000, 'funct3': 0b001, 'opcode': 0b0110011},
    'slt':  {'funct7': 0b0000000, 'funct3': 0b010, 'opcode': 0b0110011},
    'sltu': {'funct7': 0b0000000, 'funct3': 0b011, 'opcode': 0b0110011},
    'xor':  {'funct7': 0b0000000, 'funct3': 0b100, 'opcode': 0b0110011},
    'srl':  {'funct7': 0b0000000, 'funct3': 0b101, 'opcode': 0b0110011},
    'sra':  {'funct7': 0b0100000, 'funct3': 0b101, 'opcode': 0b0110011},
    'or':   {'funct7': 0b0000000, 'funct3': 0b110, 'opcode': 0b0110011},
    'and':  {'funct7': 0b0000000, 'funct3': 0b111, 'opcode': 0b0110011},
}

I_TYPE = {
    'addi':  {'opcode': 0b0010011, 'funct3': 0b000},
    'andi':  {'opcode': 0b0010011, 'funct3': 0b111},
    'ori':   {'opcode': 0b0010011, 'funct3': 0b110},
    'xori':  {'opcode': 0b0010011, 'funct3': 0b100},
    'slti':  {'opcode': 0b0010011, 'funct3': 0b010},
    'sltiu': {'opcode': 0b0010011, 'funct3': 0b011},
    # shift-immediate: funct7 needed for slli/srli/srai
    'slli':  {'opcode': 0b0010011, 'funct3': 0b001, 'funct7': 0b0000000},
    'srli':  {'opcode': 0b0010011, 'funct3': 0b101, 'funct7': 0b0000000},
    'srai':  {'opcode': 0b0010011, 'funct3': 0b101, 'funct7': 0b0100000},
    # loads/jumps
    'lw':    {'opcode': 0b0000011, 'funct3': 0b010},
    'jalr':  {'opcode': 0b1100111, 'funct3': 0b000},
}

S_TYPE = {
    'sw': {'opcode': 0b0100011, 'funct3': 0b010},
}

B_TYPE = {
    'beq':  {'opcode': 0b1100011, 'funct3': 0b000},
    'bne':  {'opcode': 0b1100011, 'funct3': 0b001},
    'blt':  {'opcode': 0b1100011, 'funct3': 0b100},
    'bge':  {'opcode': 0b1100011, 'funct3': 0b101},
    'bltu': {'opcode': 0b1100011, 'funct3': 0b110},
    'bgeu': {'opcode': 0b1100011, 'funct3': 0b111},
}

U_TYPE = {
    'lui':   {'opcode': 0b0110111},
    'auipc': {'opcode': 0b0010111},
}

J_TYPE = {
    'jal': {'opcode': 0b1101111},
}

# Regex for register parsing: x0..x31
REG_PATTERN = re.compile(r'^x([0-9]|[12][0-9]|3[01])$')

def parse_register(reg_str):
    """Parse register string 'x0'..'x31' and return integer 0..31."""
    m = REG_PATTERN.match(reg_str)
    if not m:
        raise ValueError(f"Invalid register '{reg_str}'")
    return int(m.group(1))

def parse_immediate(imm_str):
    """
    Parse immediate: decimal or hex (0x...). Returns Python int (signed or unsigned as per usage).
    Note: For branch/jump offsets, user writes label or immediate. Label-handling done separately.
    """
    try:
        # int(str, 0) handles 0x..., decimal, and also octal if prefixed.
        val = int(imm_str, 0)
    except ValueError:
        raise ValueError(f"Invalid immediate '{imm_str}'")
    return val

# === Encoding functions ===

def encode_r_type(mnemonic, rd, rs1, rs2):
    info = R_TYPE[mnemonic]
    funct7 = info['funct7'] & 0x7F
    funct3 = info['funct3'] & 0x7
    opcode = info['opcode'] & 0x7F
    return (funct7 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | (funct3 << 12) | ((rd & 0x1F) << 7) | opcode

def encode_i_type(mnemonic, rd, rs1, imm):
    info = I_TYPE[mnemonic]
    funct3 = info['funct3'] & 0x7
    opcode = info['opcode'] & 0x7F
    imm12 = imm & 0xFFF if imm >= 0 else (imm + (1 << 12)) & 0xFFF
    return (imm12 << 20) | ((rs1 & 0x1F) << 15) | (funct3 << 12) | ((rd & 0x1F) << 7) | opcode

def encode_i_shift_type(mnemonic, rd, rs1, shamt):
    info = I_TYPE[mnemonic]
    funct7 = info.get('funct7', 0) & 0x7F
    funct3 = info['funct3'] & 0x7
    opcode = info['opcode'] & 0x7F
    shamt5 = shamt & 0x1F
    return (funct7 << 25) | (shamt5 << 20) | ((rs1 & 0x1F) << 15) | (funct3 << 12) | ((rd & 0x1F) << 7) | opcode

def encode_s_type(mnemonic, rs2, rs1, imm):
    info = S_TYPE[mnemonic]
    funct3 = info['funct3'] & 0x7
    opcode = info['opcode'] & 0x7F
    imm12 = imm & 0xFFF
    imm11_5 = (imm12 >> 5) & 0x7F
    imm4_0  = imm12 & 0x1F
    return (imm11_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | (funct3 << 12) | (imm4_0 << 7) | opcode

def encode_b_type(mnemonic, rs1, rs2, imm):
    info = B_TYPE[mnemonic]
    funct3 = info['funct3'] & 0x7
    opcode = info['opcode'] & 0x7F
    # imm is byte offset (can be negative). Must be multiple of 2; lower bit always zero in encoding.
    imm12 = imm & 0x1000  # bit12
    # Actually imm is signed 13-bit (bit12 is sign), but in encoding:
    # imm[12] -> bit31, imm[10:5] -> bits30:25, imm[4:1] -> bits11:8, imm[11] -> bit7, LSB is zero.
    # We take imm & 0x1FFF to cover bits 12..0.
    imm13 = imm & 0x1FFF if imm >= 0 else (imm + (1 << 13)) & 0x1FFF
    bit12 = (imm13 >> 12) & 0x1
    bits10_5 = (imm13 >> 5) & 0x3F
    bits4_1 = (imm13 >> 1) & 0xF
    bit11 = (imm13 >> 11) & 0x1
    return (bit12 << 31) | (bits10_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | (funct3 << 12) | (bits4_1 << 8) | (bit11 << 7) | opcode

def encode_u_type(mnemonic, rd, imm):
    info = U_TYPE[mnemonic]
    opcode = info['opcode'] & 0x7F
    imm20 = (imm & 0xFFFFF) << 12
    return imm20 | ((rd & 0x1F) << 7) | opcode

def encode_j_type(mnemonic, rd, imm):
    info = J_TYPE[mnemonic]
    imm20 = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3FF
    imm11 = (imm >> 11) & 0x1
    imm19_12 = (imm >> 12) & 0xFF
    return (imm20 << 31) | (imm10_1 << 21) | (imm11 << 20) | (imm19_12 << 12) | \
        ((rd & 0x1F) << 7) | (info['opcode'] & 0x7F)

# === Utility functions ===

def prompt_for_path(prompt_msg, must_exist=False, default=None):
    """
    Prompt user for a file path. If must_exist=True, keep prompting until an existing file path is entered.
    If must_exist=False, check that directory exists.
    default: default path to show in prompt.
    """
    while True:
        if default:
            resp = input(f"{prompt_msg} [default: {default}]: ").strip()
            path = resp if resp else default
        else:
            path = input(f"{prompt_msg}: ").strip()
        # Strip quotes if any
        if (path.startswith('"') and path.endswith('"')) or (path.startswith("'") and path.endswith("'")):
            path = path[1:-1]
        path = os.path.expanduser(path)
        if must_exist:
            if os.path.isfile(path):
                return path
            else:
                print(f"Path '{path}' does not exist or is not a file. Please try again.")
        else:
            dirn = os.path.dirname(path) or '.'
            if os.path.isdir(dirn):
                return path
            else:
                print(f"Directory '{dirn}' does not exist. Please enter a valid path.")

def write_verilog_memory_file(output_path, machine_words):
    """
    Write lines like:
       memory[0] = 32'hXXXXXXXX;
       memory[1] = 32'hYYYYYYYY;
    """
    try:
        with open(output_path, 'w') as f:
            for i, word in enumerate(machine_words):
                hexstr = f"{word & 0xFFFFFFFF:08X}"
                f.write(f"    memory[{i}] = 32'h{hexstr};\n")
    except Exception as e:
        print(f"Failed to write Verilog memory file '{output_path}': {e}", file=sys.stderr)
        sys.exit(1)
    print(f"Wrote Verilog memory assignments to '{output_path}', {len(machine_words)} entries.")

# === Assembler logic ===

def updated_assemble(asm_lines):
    """
    First pass: collect labels and instruction lines.
    Second pass: encode each instruction to 32-bit word.
    """
    labels = {}
    instructions = []
    pc = 0
    # First pass: label collection
    for lineno, line in enumerate(asm_lines, start=1):
        # Remove comments
        if '#' in line:
            line = line.split('#', 1)[0]
        line = line.strip()
        if not line:
            continue
        # Check for label definition: label: possibly followed by instruction
        if ':' in line:
            parts = line.split(':', 1)
            label = parts[0].strip()
            if not re.match(r'^[A-Za-z_]\w*$', label):
                raise ValueError(f"Invalid label '{label}' on line {lineno}")
            if label in labels:
                raise ValueError(f"Duplicate label '{label}' on line {lineno}")
            labels[label] = pc
            rest = parts[1].strip()
            if rest:
                # There's instruction after label on same line
                instructions.append((lineno, rest))
                pc += 4
        else:
            instructions.append((lineno, line))
            pc += 4

    # Second pass: encode instructions
    machine_words = []
    for idx, (lineno, inst_line) in enumerate(instructions):
        curr_pc = idx * 4
        text = inst_line.strip()
        if not text:
            continue
        # Split tokens by whitespace, commas, parentheses.
        tokens = re.split(r'[,\s()]+', text)
        tokens = [tok for tok in tokens if tok]
        mnemonic = tokens[0].lower()
        try:
            if mnemonic in R_TYPE:
                # Expect: mnemonic rd, rs1, rs2
                if len(tokens) != 4:
                    raise ValueError(f"R-type '{mnemonic}' expects 3 operands (rd, rs1, rs2)")
                rd = parse_register(tokens[1])
                rs1 = parse_register(tokens[2])
                rs2 = parse_register(tokens[3])
                word = encode_r_type(mnemonic, rd, rs1, rs2)

            elif mnemonic in I_TYPE:
                if mnemonic == 'lw':
                    # Expect: lw rd, imm(rs1) or tokens: ['lw','rd','imm','rs1']
                    # After split: tokens[1]=rd, tokens[2]=imm, tokens[3]=rs1
                    if len(tokens) != 4:
                        raise ValueError(f"Invalid lw syntax on line {lineno}: '{inst_line}'")
                    rd = parse_register(tokens[1])
                    imm = parse_immediate(tokens[2])
                    rs1 = parse_register(tokens[3])
                    word = encode_i_type('lw', rd, rs1, imm)
                elif mnemonic in ('slli', 'srli', 'srai'):
                    # Expect: mnemonic rd, rs1, shamt
                    if len(tokens) != 4:
                        raise ValueError(f"Shift-immediate '{mnemonic}' expects 3 operands")
                    rd = parse_register(tokens[1])
                    rs1 = parse_register(tokens[2])
                    shamt = parse_immediate(tokens[3])
                    # Optionally: check shamt fits 5 bits (0..31)
                    if shamt < 0 or shamt > 31:
                        raise ValueError(f"Shift amount out of range 0..31: {shamt}")
                    word = encode_i_shift_type(mnemonic, rd, rs1, shamt)
                elif mnemonic == 'jalr':
                    if len(tokens) != 4:
                        raise ValueError(f"I-type '{mnemonic}' expects 3 operands")
                    rd = parse_register(tokens[1])
                    rs1 = parse_register(tokens[2])
                    imm = parse_immediate(tokens[3])
                    word = encode_i_type(mnemonic, rd, rs1, imm)
                else:
                    # Other I-type arithmetic: addi, andi, ori, xori, slti, sltiu
                    if len(tokens) != 4:
                        raise ValueError(f"I-type '{mnemonic}' expects 3 operands (rd, rs1, imm)")
                    rd = parse_register(tokens[1])
                    rs1 = parse_register(tokens[2])
                    imm = parse_immediate(tokens[3])
                    word = encode_i_type(mnemonic, rd, rs1, imm)

            elif mnemonic in S_TYPE:
                # sw rs2, imm(rs1)
                # After split: tokens = ['sw', 'rs2', 'imm', 'rs1']
                if len(tokens) != 4:
                    raise ValueError(f"S-type '{mnemonic}' expects syntax 'sw rs2, imm(rs1)'")
                rs2 = parse_register(tokens[1])
                imm = parse_immediate(tokens[2])
                rs1 = parse_register(tokens[3])
                word = encode_s_type('sw', rs2, rs1, imm)

            elif mnemonic in B_TYPE:
                # beq rs1, rs2, label_or_imm
                if len(tokens) != 4:
                    raise ValueError(f"B-type '{mnemonic}' expects 3 operands (rs1, rs2, target)")
                rs1 = parse_register(tokens[1])
                rs2 = parse_register(tokens[2])
                target = tokens[3]
                if re.match(r'^[A-Za-z_]\w*$', target):
                    if target not in labels:
                        raise ValueError(f"Undefined label '{target}' on line {lineno}")
                    target_addr = labels[target]
                    imm = target_addr - curr_pc
                else:
                    imm = parse_immediate(target)
                word = encode_b_type(mnemonic, rs1, rs2, imm)

            elif mnemonic in U_TYPE:
                # lui rd, imm  or auipc rd, imm
                if len(tokens) != 3:
                    raise ValueError(f"U-type '{mnemonic}' expects 2 operands (rd, imm20)")
                rd = parse_register(tokens[1])
                imm = parse_immediate(tokens[2])
                word = encode_u_type(mnemonic, rd, imm)

            elif mnemonic in J_TYPE:
                # jal rd, label_or_imm
                if len(tokens) != 3:
                    raise ValueError(f"J-type '{mnemonic}' expects 2 operands (rd, target)")
                rd = parse_register(tokens[1])
                target = tokens[2]
                if re.match(r'^[A-Za-z_]\w*$', target):
                    if target not in labels:
                        raise ValueError(f"Undefined label '{target}' on line {lineno}")
                    target_addr = labels[target]
                    imm = target_addr - curr_pc
                else:
                    imm = parse_immediate(target)
                word = encode_j_type('jal', rd, imm)

            else:
                raise ValueError(f"Unsupported instruction '{mnemonic}' on line {lineno}")

        except ValueError as ve:
            print(f"Error at line {lineno}: {ve}", file=sys.stderr)
            print(f"  >>> {inst_line}", file=sys.stderr)
            sys.exit(1)

        machine_words.append(word)

    return machine_words

def main():
    parser = argparse.ArgumentParser(description="Extended RISC-V RV32I assembler → Verilog memory[...] assignments")
    parser.add_argument("--input", "-i", help="Input assembly file (.asm)")
    parser.add_argument("--output", "-o", help="Output file for Verilog assignments")
    args = parser.parse_args()

    # Determine input path
    asm_path = None
    # 1. HARDCODE_INPUT_PATH if valid file
    if HARDCODE_INPUT_PATH:
        p = os.path.expanduser(HARDCODE_INPUT_PATH.strip('"').strip("'"))
        if os.path.isfile(p):
            asm_path = p
        else:
            # warn but continue
            print(f"Warning: HARDCODE_INPUT_PATH '{p}' not found. Ignoring hardcode.", file=sys.stderr)
    # 2. CLI arg
    if asm_path is None and args.input:
        p = os.path.expanduser(args.input.strip('"').strip("'"))
        if os.path.isfile(p):
            asm_path = p
        else:
            print(f"Warning: input file '{p}' not found. Will prompt.", file=sys.stderr)
    # 3. Prompt
    if asm_path is None:
        asm_path = prompt_for_path("Enter path to input .asm file", must_exist=True)

    # Determine output path
    out_path = None
    # HARDCODE_OUTPUT_PATH if its directory exists
    if HARDCODE_OUTPUT_PATH:
        p = os.path.expanduser(HARDCODE_OUTPUT_PATH.strip('"').strip("'"))
        dirn = os.path.dirname(p) or '.'
        if os.path.isdir(dirn):
            out_path = p
        else:
            print(f"Warning: HARDCODE_OUTPUT_PATH directory '{dirn}' not exist. Ignoring hardcode.", file=sys.stderr)
    # CLI arg
    if out_path is None and args.output:
        p = os.path.expanduser(args.output.strip('"').strip("'"))
        dirn = os.path.dirname(p) or '.'
        if os.path.isdir(dirn):
            out_path = p
        else:
            print(f"Warning: directory for output '{dirn}' does not exist. Will prompt.", file=sys.stderr)
    # Prompt if still None
    if out_path is None:
        default_out = os.path.splitext(asm_path)[0] + "_mem.v"
        out_path = prompt_for_path("Enter path to output Verilog memory file", must_exist=False, default=default_out)

    # Read lines
    try:
        with open(asm_path, 'r') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading '{asm_path}': {e}", file=sys.stderr)
        sys.exit(1)

    # Assemble
    try:
        machine_words = updated_assemble(lines)
    except Exception as e:
        print(f"Assembly failed: {e}", file=sys.stderr)
        sys.exit(1)

    # Write output
    write_verilog_memory_file(out_path, machine_words)

if __name__ == "__main__":
    main()
