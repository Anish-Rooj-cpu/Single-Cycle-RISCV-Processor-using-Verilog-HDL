"""
Simple RISC-V RV32I assembler for a subset: R-type, I-type, B-type, J-type.
Outputs Verilog memory assignments: memory[i] = 32'hXXXXXXXX;

You can hardcode input/output paths by setting HARDCODE_INPUT_PATH and HARDCODE_OUTPUT_PATH.

Supported instructions:
R-type: add, sub, and, or, slt
I-type arithmetic: addi, andi, ori, slti
I-type load: lw
B-type: beq, bne
J-type: jal

Registers: x0..x31
Labels: defined as `label:` at start of line or before instruction.
Comments: start with '#' and go to end-of-line.
Instruction addresses: start at 0, increment by 4 per instruction.

Usage:
    python rv32i_assembler.py [--input prog.asm] [--output out.sv] [--symbol-name name]

If HARDCODE_INPUT_PATH is set (non-empty) and exists, it will be used directly.
If HARDCODE_OUTPUT_PATH is set (non-empty), it will be used directly (directory must exist).
Otherwise, falls back to command-line args or interactive prompt.
"""

import argparse
import sys
import os
import re

HARDCODE_INPUT_PATH = r"E:\RISC5 Single Cycle Processor\Test Programs\factorial.asm"
HARDCODE_OUTPUT_PATH = r"E:\RISC5 Single Cycle Processor\Instructions\factorial.v"

R_TYPE = {
    'add':  {'funct7': 0b0000000, 'funct3': 0b000, 'opcode': 0b0110011},
    'sub':  {'funct7': 0b0100000, 'funct3': 0b000, 'opcode': 0b0110011},
    'and':  {'funct7': 0b0000000, 'funct3': 0b111, 'opcode': 0b0110011},
    'or':   {'funct7': 0b0000000, 'funct3': 0b110, 'opcode': 0b0110011},
    'slt':  {'funct7': 0b0000000, 'funct3': 0b010, 'opcode': 0b0110011},
}

I_TYPE = {
    'addi': {'opcode': 0b0010011, 'funct3': 0b000},
    'andi': {'opcode': 0b0010011, 'funct3': 0b111},
    'ori':  {'opcode': 0b0010011, 'funct3': 0b110},
    'slti': {'opcode': 0b0010011, 'funct3': 0b010},
    'lw':   {'opcode': 0b0000011, 'funct3': 0b010},
    'jalr': {'opcode': 0b1100111, 'funct3': 0b000},
}

S_TYPE = {
    'sw':   {'opcode': 0b0100011, 'funct3': 0b010},
}

B_TYPE = {
    'beq': {'funct3': 0b000, 'opcode': 0b1100011},
    'bne': {'funct3': 0b001, 'opcode': 0b1100011},
}

J_TYPE = {
    'jal': {'opcode': 0b1101111},
}

REG_PATTERN = re.compile(r'^x([0-9]|[12][0-9]|3[01])$')

def parse_register(reg_str):
    m = REG_PATTERN.match(reg_str)
    if not m:
        raise ValueError(f"Invalid register name '{reg_str}'")
    return int(m.group(1))

def parse_immediate(imm_str):
    return int(imm_str, 0)

def encode_r_type(mnemonic, rd, rs1, rs2):
    info = R_TYPE[mnemonic]
    return ((info['funct7'] & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | \
        ((info['funct3'] & 0x7) << 12) | ((rd & 0x1F) << 7) | (info['opcode'] & 0x7F)

def encode_i_type(mnemonic, rd, rs1, imm):
    info = I_TYPE[mnemonic]
    imm12 = imm & 0xFFF
    return (imm12 << 20) | ((rs1 & 0x1F) << 15) | ((info['funct3'] & 0x7) << 12) | \
        ((rd & 0x1F) << 7) | (info['opcode'] & 0x7F)

def encode_s_type(mnemonic, rs2, rs1, imm):
    info = S_TYPE[mnemonic]
    imm11_5 = (imm >> 5) & 0x7F
    imm4_0 = imm & 0x1F
    return (imm11_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | \
        ((info['funct3'] & 0x7) << 12) | (imm4_0 << 7) | (info['opcode'] & 0x7F)

def encode_b_type(mnemonic, rs1, rs2, imm):
    info = B_TYPE[mnemonic]
    imm12 = (imm >> 12) & 0x1
    imm10_5 = (imm >> 5) & 0x3F
    imm4_1 = (imm >> 1) & 0xF
    imm11 = (imm >> 11) & 0x1
    return (imm12 << 31) | (imm10_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | \
        ((info['funct3'] & 0x7) << 12) | (imm4_1 << 8) | (imm11 << 7) | (info['opcode'] & 0x7F)

def encode_j_type(mnemonic, rd, imm):
    info = J_TYPE[mnemonic]
    imm20 = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3FF
    imm11 = (imm >> 11) & 0x1
    imm19_12 = (imm >> 12) & 0xFF
    return (imm20 << 31) | (imm10_1 << 21) | (imm11 << 20) | (imm19_12 << 12) | \
        ((rd & 0x1F) << 7) | (info['opcode'] & 0x7F)
# Assembler logic

def assemble(asm_lines):
    labels = {}
    instructions = []
    pc = 0
    # First pass: collect labels
    for lineno, line in enumerate(asm_lines, start=1):
        if '#' in line:
            line = line.split('#',1)[0]
        line = line.strip()
        if not line:
            continue
        if ':' in line:
            parts = line.split(':')
            label = parts[0].strip()
            if not re.match(r'^[A-Za-z_]\w*$', label):
                raise ValueError(f"Invalid label '{label}' on line {lineno}")
            if label in labels:
                raise ValueError(f"Duplicate label '{label}' on line {lineno}")
            labels[label] = pc
            rest = ':'.join(parts[1:]).strip()
            if rest:
                instructions.append((lineno, rest))
                pc += 4
        else:
            instructions.append((lineno, line))
            pc += 4

    # Second pass: encode instructions
    machine_words = []
    for idx, (lineno, inst_line) in enumerate(instructions):
        curr_pc = idx * 4
        line = inst_line.strip()
        tokens = re.split(r'[,\s()]+', line)
        tokens = [tok for tok in tokens if tok]
        if not tokens:
            continue
        mnemonic = tokens[0].lower()
        try:
            if mnemonic in R_TYPE:
                if len(tokens) != 4:
                    raise ValueError(f"R-type '{mnemonic}' expects 3 operands")
                rd = parse_register(tokens[1]); rs1 = parse_register(tokens[2]); rs2 = parse_register(tokens[3])
                word = encode_r_type(mnemonic, rd, rs1, rs2)

            elif mnemonic in I_TYPE:
                if mnemonic == 'lw':
                    m = re.match(r'\s*lw\s+(x\d+)\s*,\s*([-]?\w+)\((x\d+)\)\s*$', inst_line, re.IGNORECASE)
                    if not m:
                        raise ValueError(f"Invalid 'lw' syntax on line {lineno}: '{inst_line}'")
                    rd_str, imm_str, rs1_str = m.group(1), m.group(2), m.group(3)
                    rd = parse_register(rd_str); rs1 = parse_register(rs1_str); imm = parse_immediate(imm_str)
                    word = encode_i_type('lw', rd, rs1, imm)
                elif mnemonic == 'jalr':
                    if len(tokens) != 4:
                        raise ValueError(f"I-type '{mnemonic}' expects 3 operands")
                    rd = parse_register(tokens[1])
                    rs1 = parse_register(tokens[2])
                    imm = parse_immediate(tokens[3])
                    word = encode_i_type(mnemonic, rd, rs1, imm)
                else:
                    if len(tokens) != 4:
                        raise ValueError(f"I-type '{mnemonic}' expects 3 operands")
                    rd = parse_register(tokens[1]); rs1 = parse_register(tokens[2]); imm = parse_immediate(tokens[3])
                    word = encode_i_type(mnemonic, rd, rs1, imm)

            elif mnemonic in S_TYPE:
                m = re.match(r'\s*(\w+)\s+(x\d+),\s*([-\w]+)\((x\d+)\)', inst_line)
                if not m:
                    raise ValueError(f"Invalid S-type syntax on line {lineno}: '{inst_line}'")
                mnemonic = m.group(1)
                rs2 = parse_register(m.group(2))
                imm = parse_immediate(m.group(3))
                rs1 = parse_register(m.group(4))
                word = encode_s_type(mnemonic, rs2, rs1, imm)

            elif mnemonic in B_TYPE:
                if len(tokens) != 4:
                    raise ValueError(f"B-type '{mnemonic}' expects 3 operands")
                rs1 = parse_register(tokens[1]); rs2 = parse_register(tokens[2]); target = tokens[3]
                if re.match(r'^[A-Za-z_]\w*$', target):
                    if target not in labels:
                        raise ValueError(f"Undefined label '{target}' on line {lineno}")
                    target_addr = labels[target]
                    imm = target_addr - curr_pc
                else:
                    imm = parse_immediate(target)
                word = encode_b_type(mnemonic, rs1, rs2, imm)

            elif mnemonic in J_TYPE:
                if len(tokens) != 3:
                    raise ValueError(f"J-type '{mnemonic}' expects 2 operands")
                rd = parse_register(tokens[1]); target = tokens[2]
                if re.match(r'^[A-Za-z_]\w*$', target):
                    if target not in labels:
                        raise ValueError(f"Undefined label '{target}' on line {lineno}")
                    target_addr = labels[target]
                    imm = target_addr - curr_pc
                else:
                    imm = parse_immediate(target)
                word = encode_j_type(mnemonic, rd, imm)

            else:
                raise ValueError(f"Unsupported instruction '{mnemonic}' on line {lineno}")
        except ValueError as ve:
            print(f"Error at line {lineno}: {ve}", file=sys.stderr)
            print(f"  >>> {inst_line}", file=sys.stderr)
            sys.exit(1)

        machine_words.append(word)

    return machine_words

def prompt_for_path(prompt_msg, must_exist=False, default=None):
    while True:
        if default:
            resp = input(f"{prompt_msg} [default: {default}]: ").strip()
            if resp == "":
                path = default
            else:
                path = resp
        else:
            path = input(f"{prompt_msg}: ").strip()
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
                print(f"Directory '{dirn}' does not exist. Please enter a valid output path.")

def write_verilog_memory_file(output_path, machine_words):
    """
    Write Verilog memory assignments:
    memory[0] = 32'hXXXXXXXX;
    memory[1] = 32'hXXXXXXXX;
    """
    try:
        with open(output_path, 'w') as f:
            for i, word in enumerate(machine_words):
                # Format hex uppercase with leading zeros, e.g. 32'h00500093
                hexstr = f"{word:08X}"
                f.write(f"    memory[{i}] = 32'h{hexstr};\n")
    except Exception as e:
        print(f"Failed to write Verilog memory file '{output_path}': {e}", file=sys.stderr)
        sys.exit(1)
    print(f"Wrote Verilog memory assignments to '{output_path}', {len(machine_words)} entries.")

def main():
    parser = argparse.ArgumentParser(description="Simple RISC-V RV32I assembler → Verilog memory[...] assignments")
    parser.add_argument("--input", "-i", help="Input assembly file (.asm)")
    parser.add_argument("--output", "-o", help="Output file for Verilog assignments")
    parser.add_argument("--symbol-name", "-s", default=None,
                        help="(unused) symbol name; kept for compatibility")
    args = parser.parse_args()

    # 1. Determine input path:
    asm_path = None
    # First: check hardcoded
    if HARDCODE_INPUT_PATH:
        p = HARDCODE_INPUT_PATH.strip('"').strip("'")
        p = os.path.expanduser(p)
        if os.path.isfile(p):
            asm_path = p
        else:
            print(f"Warning: HARDCODE_INPUT_PATH '{p}' does not exist or is not a file. Ignoring hardcode.", file=sys.stderr)
    # Second: check command-line arg
    if asm_path is None and args.input:
        p = args.input.strip('"').strip("'")
        p = os.path.expanduser(p)
        if os.path.isfile(p):
            asm_path = p
        else:
            print(f"Warning: input file '{p}' not found. Will prompt.", file=sys.stderr)
    # Third: prompt if still None
    if asm_path is None:
        asm_path = prompt_for_path("Enter path to input .asm file", must_exist=True)

    # 2. Determine output path:
    out_path = None
    if HARDCODE_OUTPUT_PATH:
        p = HARDCODE_OUTPUT_PATH.strip('"').strip("'")
        p = os.path.expanduser(p)
        dirn = os.path.dirname(p) or '.'
        if os.path.isdir(dirn):
            out_path = p
        else:
            print(f"Warning: HARDCODE_OUTPUT_PATH directory '{dirn}' does not exist. Ignoring hardcode.", file=sys.stderr)
    if out_path is None and args.output:
        p = args.output.strip('"').strip("'")
        p = os.path.expanduser(p)
        dirn = os.path.dirname(p) or '.'
        if os.path.isdir(dirn):
            out_path = p
        else:
            print(f"Warning: directory for output '{dirn}' does not exist. Will prompt.", file=sys.stderr)
    if out_path is None:
        default_out = os.path.splitext(asm_path)[0] + "_mem.v"
        out_path = prompt_for_path("Enter path to output Verilog memory file", must_exist=False, default=default_out)

    # Read assembly lines
    try:
        with open(asm_path, 'r') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading '{asm_path}': {e}", file=sys.stderr)
        sys.exit(1)

    # Assemble
    try:
        machine_words = assemble(lines)
    except Exception as e:
        print(f"Assembly failed: {e}", file=sys.stderr)
        sys.exit(1)

    # Write Verilog memory assignments
    write_verilog_memory_file(out_path, machine_words)

if __name__ == "__main__":
    main()
