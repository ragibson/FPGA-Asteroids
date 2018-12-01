# Zero out stack and load in
#
#   x:       .word FP_HALF_XRES
#   y:       .word FP_HALF_YRES
#   degrees: .word 0
#   vx:      .word 0
#   vy:      .word 0
#   w_press: .word 0
#   
#   asteroids:
#     .word FP_100, FP_100, rng(), rng(), rng(), rng(), 1,
#           FP_400, FP_300, rng(), rng(), rng(), rng(), 1,
#           FP_600, FP_200, rng(), rng(), rng(), rng(), 1,
#           FP_300, FP_50,  rng(), rng(), rng(), rng(), 1
#

load_data:
    # Reset data memory so that CPU reset signals work correctly
    
    # this routine clears the stack, so we'll save the
    # return address in a register
    move $s2, $ra
    
    li   $s0, DATA_START
    clear_data:
    sw   $0, 0($s0)
    addi $s0, $s0, 4
    bne  $s0, DATA_END, clear_data
    
    li   $s0, FP_HALF_XRES
    sw   $s0, x($0)
    li   $s0, FP_HALF_YRES
    sw   $s0, y($0)
    
    li   $s0, 0
    li   $s1, FP_100
    sw   $s1, asteroids($s0)            # asteroids[0].x
    addi $s0, $s0, 4
    li   $s1, FP_100
    sw   $s1, asteroids($s0)            # asteroids[0].y
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[0].degrees
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[0].vx
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[0].vy
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[0].vd
    addi $s0, $s0, 4
    li   $s1, 2
    sw   $s1, asteroids($s0)            # asteroids[0].size
    
    addi $s0, $s0, 4
    li   $s1, FP_400
    sw   $s1, asteroids($s0)            # asteroids[1].x
    addi $s0, $s0, 4
    li   $s1, FP_300
    sw   $s1, asteroids($s0)            # asteroids[1].y
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[1].degrees
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[1].vx
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[1].vy
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[1].vd
    addi $s0, $s0, 4
    li   $s1, 2
    sw   $s1, asteroids($s0)            # asteroids[1].size
    addi $s0, $s0, 4
    
    li   $s1, FP_600
    sw   $s1, asteroids($s0)            # asteroids[2].x
    addi $s0, $s0, 4
    li   $s1, FP_200
    sw   $s1, asteroids($s0)            # asteroids[2].y
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[2].degrees
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[2].vx
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[2].vy
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[2].vd
    addi $s0, $s0, 4
    li   $s1, 2
    sw   $s1, asteroids($s0)            # asteroids[2].size
    addi $s0, $s0, 4

    li   $s1, FP_300
    sw   $s1, asteroids($s0)            # asteroids[3].x
    addi $s0, $s0, 4
    li   $s1, FP_50
    sw   $s1, asteroids($s0)            # asteroids[3].y
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[3].degrees
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[3].vx
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[3].vy
    addi $s0, $s0, 4
    jal  rng
    sw   $v0, asteroids($s0)            # asteroids[3].vd
    addi $s0, $s0, 4
    li   $s1, 2
    sw   $s1, asteroids($s0)            # asteroids[3].size
    
    sw   $0, sound_addr($0)             # turn off any current sound
    
    move $ra, $s2
    jr   $ra
