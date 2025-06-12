# Simple test program
start:
    addi x1, x0, 5       # x1 = 5
    addi x2, x0, 10      # x2 = 10
    add  x3, x1, x2      # x3 = x1 + x2 = 15
    lw   x4, 0(x0)       # assume memory[0] preloaded, or just demonstrate encoding
    beq  x3, x4, equal   # branch if equal
    addi x5, x0, 99      # skipped if branch taken
equal:
    jal  x6, after       # jump to after
    addi x7, x0, 77      # skipped
after:
    addi x8, x0, 88
