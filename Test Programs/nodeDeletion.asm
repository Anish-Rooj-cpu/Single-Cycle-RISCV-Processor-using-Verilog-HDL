# =======================================
# Recursive Delete Nodes > Threshold (x4)
# Modified list returned in x7
# =======================================

    # === Initial Setup ===
    addi x2, x0, 256       # Stack pointer
    addi x4, x0, 4         # Threshold
    addi x7, x0, 0         # Clear result
    addi x3, x0, 0x100     # x3 = Head pointer
    jal x1, delete_nodes
    addi x10, x7, 0     # Immediately store result
    addi x7, x7, 0      # Optional, to retain it explicitly

    addi x0, x0, 0         # Halt (infinite loop)

# ========== delete_nodes FUNCTION ==========
# Input: x3 = current node
# Output: x7 = new head (with deleted nodes skipped)

delete_nodes:
    beq x3, x0, return_null    # Base case: if null, return null

    # Push return address and current pointer
    addi x2, x2, -8
    sw x1, 4(x2)
    sw x3, 0(x2)

    # Get next pointer (x5)
    lw x5, 4(x3)
    addi x2, x2, -4
    sw x5, 0(x2)

    # Recursive call
    addi x3, x5, 0
    jal x1, delete_nodes

    # Pop next pointer (x5)
    lw x5, 0(x2)
    addi x2, x2, 4

    # Pop current node (x3), return address (x1)
    lw x3, 0(x2)
    lw x1, 4(x2)
    addi x2, x2, 8

    # Compare value with threshold
    lw x6, 0(x3)            # x6 = val
    slt x9, x4, x6          # x9 = (threshold < val)
    beq x9, x0, keep_node   # If val <= threshold, keep

    # Delete current node → return x7
    addi x7, x7, 0
    jalr x0, x1, 0

keep_node:
    sw x7, 4(x3)            # x3->next = x7
    addi x7, x3, 0          # x7 = x3
    jalr x0, x1, 0

return_null:
    addi x7, x0, 0
    jalr x0, x1, 0
