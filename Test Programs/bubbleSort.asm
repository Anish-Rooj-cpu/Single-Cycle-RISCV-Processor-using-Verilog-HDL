# Initialize registers with unsorted values
addi x10, x0, 5    # x10 = 5
addi x11, x0, 2    # x11 = 2
addi x12, x0, 8    # x12 = 8
addi x13, x0, 1    # x13 = 1
addi x14, x0, 4    # x14 = 4
addi x15, x0, 7    # x15 = 7

# Sort x10..x15 (6 values)
addi x7, x0, 6      # n = 6
addi x5, x0, 0      # i = 0

outer_loop:
    addi x6, x0, 0    # j = 0
    addi x16, x0, 0   # swap flag = 0

inner_loop:
    # Compare x[j] and x[j+1] (unrolled)
    beq x6, x0, compare_x10_x11
    addi x8, x0, 1
    beq x6, x8, compare_x11_x12
    addi x8, x0, 2
    beq x6, x8, compare_x12_x13
    addi x8, x0, 3
    beq x6, x8, compare_x13_x14
    addi x8, x0, 4
    beq x6, x8, compare_x14_x15
    
    # Equivalent to 'j end_inner_loop' using beq
    beq x0, x0, end_inner_loop

compare_x10_x11:
    slt x8, x11, x10
    beq x8, x0, next_iteration
    add x9, x0, x10
    add x10, x0, x11
    add x11, x0, x9
    addi x16, x0, 1
    beq x0, x0, next_iteration

compare_x11_x12:
    slt x8, x12, x11
    beq x8, x0, next_iteration
    add x9, x0, x11
    add x11, x0, x12
    add x12, x0, x9
    addi x16, x0, 1
    beq x0, x0, next_iteration

compare_x12_x13:
    slt x8, x13, x12
    beq x8, x0, next_iteration
    add x9, x0, x12
    add x12, x0, x13
    add x13, x0, x9
    addi x16, x0, 1
    beq x0, x0, next_iteration

compare_x13_x14:
    slt x8, x14, x13
    beq x8, x0, next_iteration
    add x9, x0, x13
    add x13, x0, x14
    add x14, x0, x9
    addi x16, x0, 1
    beq x0, x0, next_iteration

compare_x14_x15:
    slt x8, x15, x14
    beq x8, x0, next_iteration
    add x9, x0, x14
    add x14, x0, x15
    add x15, x0, x9
    addi x16, x0, 1
    beq x0, x0, next_iteration

next_iteration:
    addi x6, x6, 1       # j++
    addi x8, x7, -1
    sub x8, x8, x5       # x8 = (n-1) - i
    slt x9, x6, x8       # x9 = (j < (n-i-1)) ? 1 : 0
    bne x9, x0, inner_loop  # Continue if j < (n-i-1)

end_inner_loop:
    beq x16, x0, done    # Exit if no swaps
    addi x5, x5, 1       # i++
    slt x8, x5, x7       # x8 = (i < n) ? 1 : 0
    bne x8, x0, outer_loop  # Continue if i < n

done:
    # Infinite loop to halt
    beq x0, x0, done