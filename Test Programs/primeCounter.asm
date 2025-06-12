# Sieve of Eratosthenes - Corrected Version
# Initialization
addi x10, x0, 100       # array_size = 100
addi x11, x0, 1         # prime_flag = 1
addi x12, x0, 0         # current index = 0
addi x13, x0, 0x10      # base address = 0x10
slli x13, x13, 8        # shift left to get 0x1000

# Initialize array (all numbers prime)
init_loop:
  bge x12, x10, init_done
  slli x14, x12, 2      # offset = index*4
  add x15, x13, x14     # address = base + offset
  sw x11, 0(x15)        # store prime flag
  addi x12, x12, 1      # increment index
  jal x0, init_loop

init_done:
  addi x5, x0, 2        # p = 2 (first prime)

# Sieve algorithm
sieve_outer:
  # Calculate p*p (x6 = p*p)
  add x6, x5, x0        # x6 = p
  add x28, x5, x0       # counter = p
  addi x28, x28, -1     # need p-1 additions
  add x29, x0, x0       # result = 0

mul_loop:
  beq x28, x0, mul_done
  add x29, x29, x6
  addi x28, x28, -1
  jal x0, mul_loop
mul_done:
  add x6, x29, x0       # x6 = p*p

  bge x6, x10, sieve_done  # if p*p >= size, done

  # Check if p is prime
  slli x7, x5, 2        # offset for p
  add x8, x13, x7       # address of p's flag
  lw x9, 0(x8)          # load flag
  beq x9, x0, next_prime # if composite, skip

  # Mark multiples of p as composite
  addi x16, x5, 0       # multiplier starts at p
  addi x17, x0, 0       # composite_flag = 0

mark_composites:
  # Calculate p * multiplier
  add x28, x16, x0      # counter = multiplier
  add x29, x0, x0       # result = 0
  add x30, x5, x0       # addend = p

inner_mul_loop:
  beq x28, x0, inner_mul_done
  add x29, x29, x30
  addi x28, x28, -1
  jal x0, inner_mul_loop
inner_mul_done:
  add x18, x29, x0      # x18 = p * multiplier

  bge x18, x10, next_prime # if >= size, done

  slli x19, x18, 2      # offset for multiple
  add x20, x13, x19     # address of multiple
  sw x17, 0(x20)        # mark as composite

  addi x16, x16, 1      # increment multiplier
  jal x0, mark_composites

next_prime:
  addi x5, x5, 1        # p = p + 1
  blt x5, x10, sieve_outer # if p < size, continue

# Count primes (starting from 2)
sieve_done:
  addi x21, x0, 0       # prime_count = 0
  addi x22, x0, 2       # start from 2 (first prime)

count_loop:
  bge x22, x10, count_done
  slli x26, x22, 2      # offset
  add x27, x13, x26     # address
  lw x28, 0(x27)        # load flag
  beq x28, x0, not_prime # if composite, skip
  
  addi x21, x21, 1      # increment prime count

not_prime:
  addi x22, x22, 1      # next number
  jal x0, count_loop

count_done:
  # Store final count in x10
  add x10, x21, x0

  # Infinite loop to terminate
  addi x1, x0, 0
  jalr x0, x1, 0