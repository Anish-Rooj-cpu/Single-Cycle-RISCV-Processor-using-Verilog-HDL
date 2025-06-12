# Fibonacci Program - F(10) stored in x10
    addi x1, x0, 11     # x1 = 11 (loop counter: we compute F(10), so 10 iterations after 0,1)
    addi x2, x0, 0      # x2 = 0  (F(0))
    addi x3, x0, 1      # x3 = 1  (F(1))
    addi x5, x0, 2      # x5 = 2  (loop exit condition: when x1 == 2)

loop:
    add x4, x2, x3      # x4 = x2 + x3 (next Fibonacci number)
    add x2, x3, x0      # x2 = previous x3
    add x3, x4, x0      # x3 = previous x4 (new Fib)
    addi x1, x1, -1     # x1 = x1 - 1
    bne x1, x5, loop    # if x1 != 2, continue loop

# x3 now holds F(10) = 55
# store result and halt
    add x10, x3, x0     # x10 = F(10)
done:
    jal x0, done        # infinite loop to end program
