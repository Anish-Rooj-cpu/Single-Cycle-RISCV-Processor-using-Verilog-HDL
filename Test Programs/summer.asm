# Sum generator program (1+2+3+...+10)
# Registers:
#   x1 = return address (used by jal)
#   x2 = stack pointer (sp)
#   x5 = counter (i)
#   x6 = sum
#   x7 = constant 10 (limit)
#   x8 = temporary

    addi x5, x0, 1      # Initialize counter (i) to 1
    addi x6, x0, 0      # Initialize sum to 0
    addi x7, x0, 10     # Set limit to 10

loop:
    add  x6, x6, x5     # sum = sum + i
    addi x5, x5, 1      # i = i + 1
    slt  x8, x7, x5     # x8 = (10 < i) ? 1 : 0
    beq  x8, x0, loop   # if (10 >= i), branch to loop

# At this point, x6 contains the sum (55)