# Recursive Factorial Calculator (5! = 120)
# Initialize stack pointer (starts at 256)
    addi x2, x0, 256    # x2 = 256 (stack pointer)
# Set input (n = 5)
    addi x5, x0, 5      # x5 = 5 (compute 5!)
# Call factorial function
    jal  x1, factorial  # Jump to factorial, store return addr in x1
# Halt after completion (infinite loop)
end:
    addi x0, x0, 0      # Infinite loop (halt)
    jal  x0, end        # Safety jump
# ===== Factorial Function =====
factorial:
    # Base case: if (n <= 1), return 1
    addi x8, x0, 1      # x8 = 1 (constant)
    slt  x7, x5, x8     # x7 = (n < 1) ? 1 : 0
    beq  x7, x0, recurse # If n >= 1, recurse
    addi x6, x0, 1      # Else, return 1 (x6 = 1)
    jalr x0, x1, 0      # Return to caller
recurse:
    # Push return address and n to stack (8 bytes total)
    addi x2, x2, -8     # Allocate 8 bytes on stack
    sw   x1, 4(x2)      # Store return address at sp+4
    sw   x5, 0(x2)      # Store n at sp+0

    # Compute factorial(n-1)
    addi x5, x5, -1     # n = n - 1
    jal  x1, factorial  # Recursive call

    # Restore n and return address
    lw   x5, 0(x2)      # Restore original n
    lw   x1, 4(x2)      # Restore return address
    addi x2, x2, 8      # Free stack space

    # Multiply result (x6) by n (x5) via addition
    addi x7, x0, 0      # x7 = product = 0
    addi x8, x0, 0      # x8 = counter = 0

multiply_loop:
    beq  x8, x5, end_multiply  # If counter == n, exit
    add  x7, x7, x6      # product += result
    addi x8, x8, 1       # counter++
    jal  x0, multiply_loop

end_multiply:
    add  x6, x7, x0      # x6 = product (update result)
    jalr x0, x1, 0       # Return