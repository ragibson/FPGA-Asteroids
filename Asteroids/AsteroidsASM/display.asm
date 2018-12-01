# Writes color $a2 to ($a0, $a1), saves $ra, uses $t0-$t1
write_pixel:
    addi  $sp, $sp, -4
    sw    $ra, 0($sp)
    
    sll   $t0, $a1, 9
    sll   $t1, $a1, 7
    add   $t0, $t0, $t1                 # t1 = (y << 9) + (y << 7) = 640*y
    add   $t0, $t0, $a0
    sll   $t0, $t0, 2                   # word-align array index
    sw    $a2, screen_base($t0)         # screen[640*y + x] = color
    
    lw    $ra, 0($sp)
    addi  $sp, $sp, 4
    jr    $ra

# Reads color from ($a0, $a1) into $v0, saves $ra, uses $t0-$t1
read_pixel:
    addi  $sp, $sp, -4
    sw    $ra, 0($sp)
    
    sll   $t0, $a1, 9
    sll   $t1, $a1, 7
    add   $t0, $t0, $t1                 # t1 = (y << 9) + (y << 7) = 640*y        
    add   $t0, $t0, $a0
    sll   $t0, $t0, 2                   # word-align array index
    lw    $v0, screen_base($t0)         # screen[640*y + x] = color
    
    lw    $ra, 0($sp)
    addi  $sp, $sp, 4
    jr    $ra

# Writes BLACK to every pixel on the screen, takes ~2 frames, could be optimized
clear_screen:
    li    $t0, 0
    li    $t1, BLACK
    continue_clear:
    sw    $t1, screen_base($t0)
    addi  $t0, $t0, 4
    bne   $t0, SCREEN_BYTES, continue_clear
    jr    $ra
