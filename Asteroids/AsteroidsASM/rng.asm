# Uses 3 bits from the global cycle count to return
# nonzero values from -96 to 96, saves $ra, uses $t0
# (in fp16_t, this corresponds to -1.5 to 1.5)
rng:
    lw   $v0, counter_addr($0)
    andi $t0, $v0, 0x1
    andi $v0, 0x6                       # (rand() & 0b110) << 4    
    bne  $v0, $0, skip_make_nonzero
    
    # We can't simply re-run rng on a zero-valued result here.
    # Since the rng is tied to the global timer, such a restart
    # could/would cause an infinite loop in some cases, so we just
    # use the smallest nonzero value for (rand() & 0b110) instead.
    li   $v0, 0x2
    
    skip_make_nonzero:
    sll  $v0, $v0, 4
    beq  $t0, $0, return_rng
    sub  $v0, $0, $v0                   # 50% chance for negative result
    return_rng:
    
    jr   $ra
