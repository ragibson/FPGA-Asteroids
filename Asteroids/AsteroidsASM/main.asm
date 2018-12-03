.include "constants.asm"

.data DATA_START
x:             .word FP_HALF_XRES
y:             .word FP_HALF_YRES
degrees:       .word 0
vx:            .word 0
vy:            .word 0
w_press:       .word 0
s_held:        .word 0
sound_timeout: .word 0

# Eight {x, y, degrees, vx, vy, vd, size} structs
asteroids:
  .word FP_100, FP_100, 0, 0, 0, 0, 2,
        FP_400, FP_300, 0, 0, 0, 0, 2,
        FP_600, FP_200, 0, 0, 0, 0, 2,
        FP_300, FP_50,  0, 0, 0, 0, 2,
        0,      0,      0, 0, 0, 0, 0,
        0,      0,      0, 0, 0, 0, 0,
        0,      0,      0, 0, 0, 0, 0,
        0,      0,      0, 0, 0, 0, 0

# Five {x, y, vx, vy, timeout} structs
shots:
  .word 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0

.macro swap_args
    xor  $a0, $a0, $a2
    xor  $a2, $a0, $a2
    xor  $a0, $a0, $a2                 #   swap(x1, x2)
    xor  $a1, $a1, $a3
    xor  $a3, $a1, $a3
    xor  $a1, $a1, $a3                 #   swap(y1, y2)
.end_macro

.macro save_registers
    addi $sp, $sp, -36
    sw   $s0, 32($sp)
    sw   $s1, 28($sp)
    sw   $s2, 24($sp)
    sw   $s3, 20($sp)
    sw   $s4, 16($sp)
    sw   $s5, 12($sp)
    sw   $s6, 8($sp)
    sw   $s7, 4($sp)
    sw   $ra, 0($sp)
.end_macro

.macro restore_registers
    lw   $s0, 32($sp)
    lw   $s1, 28($sp)
    lw   $s2, 24($sp)
    lw   $s3, 20($sp)
    lw   $s4, 16($sp)
    lw   $s5, 12($sp)
    lw   $s6, 8($sp)
    lw   $s7, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 36
.end_macro

.text TEXT_START
main:
    jal  load_data
    li  $sp, DATA_END      # Initialize stack pointer to the 512th location above start of data
    addi $fp, $sp, -4      # Set $fp to the start of main's stack frame
    jal  clear_screen

    game_loop_while:
    li   $a0, GRAY
    jal  draw_asteroids                    # draw_asteroids(GRAY)

    lw   $a0, x($0)
    lw   $a1, y($0)
    lw   $a2, degrees($0)
    li   $a3, WHITE
    jal  draw_ship                         # draw_ship(x, y, degrees, WHITE)

    li   $a0, WHITE
    jal  draw_shots                        # draw_shots(WHITE)

    lw   $t0, w_press($0)                  # if (w_press)
    bne  $t0, 1, skip_draw_flame
    lw   $a0, x($0)
    lw   $a1, y($0)
    lw   $a2, degrees($0)
    li   $a3, ORANGE
    jal  draw_flame                        #   draw_flame(x, y, degrees, ORANGE)
    skip_draw_flame:

    wait_for_vsync:
    lw  $s1, vsync_addr($0)                # wait_for_vsync()
    beq $s1, $0, wait_for_vsync

    # redraw objects in black to "clear" the screen
    li   $a0, BLACK
    jal  draw_asteroids                    # draw_asteroids(BLACK)

    lw   $a0, x($0)
    lw   $a1, y($0)
    lw   $a2, degrees($0)
    li   $a3, BLACK
    jal  draw_ship                         # draw_ship(x, y, degrees, BLACK)

    li   $a0, BLACK
    jal  draw_shots                        # draw_shots(BLACK);

    lw   $t0, w_press($0)                  # if (w_press)
    bne  $t0, 1, skip_erase_flame
    lw   $a0, x($0)
    lw   $a1, y($0)
    lw   $a2, degrees($0)
    li   $a3, BLACK
    jal  draw_flame                        #   draw_flame(x, y, degrees, BLACK)
    li   $t0, 0
    sw   $t0, w_press($0)                  #   w_press = 0
    skip_erase_flame:

    lw   $t0, sound_timeout($0)
    beq  $t0, $0, skip_sound_decrement     # if (sound_timeout)
    subi $t0, $t0, 1
    sw   $t0, sound_timeout($0)            #   sound_timeout--
    beq  $0, $0, end_sound_update
    skip_sound_decrement:                  # else
    sw   $0, sound_addr($0)                #   sound_period = 0
    end_sound_update:

    jal  update_objects                    # update_objects()

    lw   $t0, keyboard_addr($0)            # c = read_keyboard()

    lw   $t1, s_held($0)
    bne  $t1, $0, skip_s_pressed
    beq  $t0, S_PRESSED, s_pressed
    skip_s_pressed:

    beq  $t0, S_PRESSED, skip_s_held_reset # if (c != 's')
    sw   $0, s_held($0)                    #   s_held = 0
    skip_s_held_reset:

    beq  $t0, W_PRESSED, w_pressed
    beq  $t0, A_PRESSED, a_pressed
    beq  $t0, D_PRESSED, d_pressed
    beq  $0, $0, end_keyboard_input

    w_pressed:                             # if (c == 'w')
    lw   $a0, degrees($0)
    jal  fpsin                             #   fpsin(degrees)
    move $a0, $v0
    li   $a1, W_SPEED
    jal  fpmult                            #   fpmult(W_SPEED, fpsin(degrees))
    lw   $t0, vx($0)
    add  $t0, $t0, $v0
    sw   $t0, vx($0)                       #   vx += fpmult(W_SPEED, fpsin(degrees))
    lw   $a0, degrees($0)
    jal  fpcos                             #   fpcos(degrees)
    move $a0, $v0
    li   $a1, W_SPEED
    jal  fpmult                            #   fpmult(W_SPEED, fpcos(degrees))
    lw   $t0, vy($0)
    sub  $t0, $t0, $v0
    sw   $t0, vy($0)                       #   vx -= fpmult(W_SPEED, fpcos(degrees))
    li   $t0, 1
    sw   $t0, w_press($0)                  #   w_press = 1

    # for one frame, play 125 Hz
    li   $t0, W_SOUND                 
    sw   $t0, sound_addr($0)               #   sound_period = W_SOUND
    li   $t0, W_SOUNDLEN
    sw   $t0, sound_timeout($0)            #   sound_timeout = W_SOUNDLEN

    beq  $0, $0, end_keyboard_input
    a_pressed:                             # else if (c == 'a')
    lw   $s0, degrees($0)
    addi $s0, $s0, FP_N5                   #   degrees -= FP_5
    sw   $s0, degrees($0)
    beq  $0, $0, end_keyboard_input
    d_pressed:                             # else if (c == 'd')
    lw   $s0, degrees($0)
    addi $s0, $s0, FP_5                    #   degrees += FP_5
    sw   $s0, degrees($0)
    beq  $0, $0, end_keyboard_input

    s_pressed:                             # else if (!s_held && c == 's')
    li   $t0, 1
    sw   $t0, s_held($0)
    li   $a0, FP_0
    li   $a1, FP_N10
    lw   $a2, degrees($0)
    jal  rotate                            #   rotate(FP_0, FP_N10, degrees, &front_x, &front_y)
    lw   $t0, x($0)
    add  $s0, $v0, $t0                     #   front_x += x
    lw   $t0, y($0)
    add  $s1, $v1, $t0                     #   front_y += y

    li   $s2, 0                            #   first_free = 0
    first_free_loop:                       #   for (first_free = 0; first_free < MAX_SHOTS; first_free++)
    addi $t0, $s2, POINT_TIMEOUT
    lw   $t0, shots($t0)
    beq  $t0, $0, end_first_free_loop      #     if (shots[first_free].timeout == 0)
    addi $s2, $s2, POINT_BYTES
    bne  $s2, SHOT_BYTES, first_free_loop  #       break
    end_first_free_loop:

    beq  $s2, SHOT_BYTES, skip_add_shot    #    if (first_free < MAX_SHOTS)
    addi $t0, $s2, POINT_X
    sw   $s0, shots($t0)                   #      shots[first_free].x = front_x
    addi $t0, $s2, POINT_Y
    sw   $s1, shots($t0)                   #      shots[first_free].y = front_y

    lw   $a0, degrees($0)
    jal  fpsin                             #      fpsin(degrees)
    move $a1, $v0
    li   $a0, SHOT_SPEED
    jal  fpmult                            #      fpmult(FP_3, fpsin(degrees))
    addi $t0, $s2, POINT_VX
    lw   $t1, vx($0)
    add  $t1, $t1, $v0
    sw   $t1, shots($t0)                   #      shots[i].vx = vx + fpmult(FP_3, fpsin(degrees))

    lw   $a0, degrees($0)
    jal  fpcos                             #      fpcos(degrees)
    move $a1, $v0
    li   $a0, SHOT_SPEED
    jal  fpmult                            #      fpmult(FP_3, fpcos(degrees))
    addi $t0, $s2, POINT_VY
    lw   $t1, vy($0)
    sub  $t1, $t1, $v0
    sw   $t1, shots($t0)                   #      shots[i].vy = vy - fpmult(FP_3, fpsin(degrees))

    addi $t0, $s2, POINT_TIMEOUT
    li   $t1, TWO_SECONDS
    sw   $t1, shots($t0)                   #      shots[i].timeout = TWO_SECONDS

    # for six frames, play 440 Hz
    li   $t0, S_SOUND                 
    sw   $t0, sound_addr($0)               #   sound_period = S_SOUND
    li   $t0, S_SOUNDLEN
    sw   $t0, sound_timeout($0)            #   sound_timeout = S_SOUNDLEN
    skip_add_shot:

    end_keyboard_input:

    lw   $a0, degrees($0)
    li   $a1, FP_360
    jal  mod
    move $s0, $v0
    sw   $s0, degrees($0)                  # degrees = mod(degrees, FP_360)

    lw   $t0, vx($0)
    lw   $t1, x($0)
    add  $a0, $t0, $t1
    li   $a1, FP_XRES
    jal  mod
    sw   $v0, x($0)                        # x = mod(x + vx, FP_XRES)

    lw   $t0, vy($0)
    lw   $t1, y($0)
    add  $a0, $t0, $t1
    li   $a1, FP_YRES
    jal  mod
    sw   $v0, y($0)                        # y = mod(y + vy, FP_XRES)

    # slow ship velocity slightly every frame
    # in fp16_t, SLOWDOWN is ~1.02
    lw   $a0, vx($0)
    li   $a1, SLOWDOWN
    jal  fpdiv
    sw   $v0, vx($0)                       # vx = fpdiv(vx, SLOWDOWN)

    lw   $a0, vy($0)
    li   $a1, SLOWDOWN
    jal  fpdiv
    sw   $v0, vy($0)                       # vy = fpdiv(vy, SLOWDOWN)

    j game_loop_while

# Draws ($a0, $a1) -- ($a2, $a3) with color $t0, checks for collision with color $t1
# Returns whether or not it drew over color $t1 (if not BLACK)
draw_line:
    save_registers

    addi $sp, $sp, -12
    sw   $0   8($sp)                   # store collision_occurred on stack
    sw   $t1, 4($sp)                   # save check_collision on stack
    sw   $t0, 0($sp)                   # save c on stack

    bne  $a2, $a0, skip_x2_increment   # naively avoid division by zero
    addi $a2, $a2, 1
    skip_x2_increment:

    bne  $a3, $a1, skip_y2_increment
    addi $a3, $a3, 1
    skip_y2_increment:

    addi $sp, $sp, -4
    sw   $a0, 0($sp)                   # save x1

    sub  $a0, $a2, $a0
    jal  abs
    move $s6, $v0                      # $s6 = abs(x2 - x1)
    sub  $a0, $a3, $a1
    jal  abs
    move $s7, $v0                      # $s7 = abs(y2 - y1)

    lw   $a0, 0($sp)
    addi $sp, $sp, 4                   # restore $a0 = x1

    # determine direction to iterate based on which dimension
    # requires more pixels to be drawn (avoids "skipped pixels")
    slt  $t0, $s6, $s7
    bne  $t0, $0, draw_line_if_false   # if (abs(x2 - x1) >= abs(y2 - y1))

    draw_line_if_true:
    slt  $t1, $a2, $a0
    beq  $t1, $0, skip_draw_swap1      # if (x1 >= x2)

    # ensure iteration proceeds as x1 -> x2
    swap_args

    skip_draw_swap1:

    move $s0, $a0                      # x = x1
    move $s1, $a1                      # y = y1
    move $s2, $a2                      # save x2
    move $s3, $a3                      # save y2

    sub  $a0, $s3, $s1
    sub  $a1, $s2, $s0
    jal  fpdiv                   
    move $s4, $v0                      # slope = (y2 - y1)/(x2 - x1)

    start_draw_loop1:
    slt  $t0, $s2, $s0
    bne  $t0, $0, end_draw_loop1       # for (x = x1; x <= x2; x += INT_TO_FP(1))
   
    move $a0, $s0
    jal  round_fp_to_int
    move $a0, $v0
    li   $a1, XRES
    jal  mod
    move $s5, $v0                      #   draw_x = round_fp_to_int(x) % XRES

    move $a0, $s1
    jal  round_fp_to_int
    move $a0, $v0
    li   $a1, YRES
    jal  mod
    move $s6, $v0                      #   draw_y = round_fp_to_int(y) % YRES

    lw   $t1, 4($sp)                   #   read check_collision from stack
    beq  $t1, $0, skip_collision1

    # collisions are calculated on the framebuffer itself
    move $a0, $s5
    move $a1, $s6                      #   if (check_collision &&
    jal  read_pixel                    #       read_pixel(draw_x, draw_y)
    lw   $t1, 4($sp)                   #       == check_collision)
    bne  $v0, $t1, skip_collision1
    li   $t0, 1
    sw   $t0, 8($sp)                   #     collision_occurred = 1
    skip_collision1:

    move $a0, $s5
    move $a1, $s6
    lw   $a2, 0($sp)                   #   read c from stack
    jal  write_pixel                   #   write_pixel(draw_x, draw_y, c)

    add  $s1, $s1, $s4                 #   y += slope
    addi $s0, $s0, FP_1                #   x += INT_TO_FP(1)
    beq  $0, $0, start_draw_loop1
    end_draw_loop1:
    beq  $0, $0, draw_line_return

    draw_line_if_false:
    slt  $t1, $a3, $a1
    beq  $t1, $0, skip_draw_swap2      # if (y1 >= y2)

    # ensure iteration proceeds as y1 -> y2
    swap_args
    skip_draw_swap2:

    move $s0, $a0                      # x = x1
    move $s1, $a1                      # y = y1
    move $s2, $a2                      # save x2
    move $s3, $a3                      # save y2

    sub  $a0, $s2, $s0
    sub  $a1, $s3, $s1
    jal  fpdiv
    move $s4, $v0                      # slope = (x2 - x1)/(y2 - y1)

    start_draw_loop2:
    slt  $t0, $s3, $s1
    bne  $t0, $0, end_draw_loop2       # for (y = y1; y <= y2; x += INT_TO_FP(1))
   
    move $a0, $s0
    jal  round_fp_to_int
    move $a0, $v0
    li   $a1, XRES
    jal  mod
    move $s5, $v0                      #   draw_x = round_fp_to_int(x) % XRES

    move $a0, $s1
    jal  round_fp_to_int
    move $a0, $v0
    li   $a1, YRES
    jal  mod
    move $s6, $v0                      #   draw_y = round_fp_to_int(y) % YRES

    lw   $t1, 4($sp)                   #   read check_collision from stack
    beq  $t1, $0, skip_collision2

    # collisions are calculated on the framebuffer itself
    move $a0, $s5
    move $a1, $s6                      #   if (check_collision &&
    jal  read_pixel                    #       read_pixel(draw_x, draw_y)
    lw   $t1, 4($sp)                   #       == check_collision)
    bne  $v0, $t1, skip_collision2
    li   $t0, 1
    sw   $t0, 8($sp)                   #     collision_occurred = 1
    skip_collision2:

    move $a0, $s5
    move $a1, $s6
    lw   $a2, 0($sp)                   #   read c from stack
    jal  write_pixel                   #   write_pixel(draw_x, draw_y, c)

    add  $s0, $s0, $s4                 #   x += slope
    addi $s1, $s1, FP_1                #   y += INT_TO_FP(1)
    beq  $0, $0, start_draw_loop2
    end_draw_loop2:

    draw_line_return:

    lw   $v0, 8($sp)                    # return collision_occurred
    addi $sp, $sp, 12                   # pop c and check_collision off stack
    restore_registers
              
    jr   $ra

# rotates ($a0, $a1) about (0, 0) by $a2 degrees (in fp16_t)
rotate:
    save_registers

    move $s0, $a0                      # x
    move $s1, $a1                      # y
    move $s2, $a2                      # degrees

    move $a0, $s2
    jal  fpcos
    move $s3, $v0                      # cos_d = fpcos(degrees)

    move $a0, $s2
    jal  fpsin
    move $s4, $v0                      # sin_d = fpsin(degrees)

    move $a0, $s3
    move $a1, $s0
    jal  fpmult
    move $s5, $v0                      # fpmult(cos_d, x)

    sub  $a0, $0, $s4
    move $a1, $s1
    jal  fpmult                        # fpmult(-sin_d, y)
    add  $s5, $s5, $v0                 # rx = fpmult(cos_d, x) + fpmult(-sin_d, y)

    move $a0, $s4
    move $a1, $s0
    jal  fpmult
    move $s6, $v0                      # fpmult(sin_d, x)

    move $a0, $s3
    move $a1, $s1
    jal  fpmult                        # fpmult(cos_d, y)
    add  $s6, $s6, $v0                 # ry = fpmult(sin_d, x) + fpmult(cos_d, y)

    move $v0, $s5
    move $v1, $s6                      # return rx, ry

    restore_registers
    jr   $ra

# Draws ship at ($a0, $a1) rotated by $a2 degrees (in fp16_t) with color $a3
draw_ship:
    addi $sp, $sp, -20
    sw   $a0, 16($sp)                  # x
    sw   $a1, 12($sp)                  # y
    sw   $a2, 8($sp)                   # degrees
    sw   $a3, 4($sp)                   # c
    sw   $ra, 0($sp)

    move $s0, $a2                      # degrees

    li   $a0, FP_0
    li   $a1, FP_N10
    move $a2, $s0
    jal  rotate                        # rotate(FP_0, FP_N10, degrees, ax, ay)
    move $s1, $v0                      # ax
    move $s2, $v1                      # ay

    li   $a0, FP_7
    li   $a1, FP_10
    move $a2, $s0
    jal  rotate                        # rotate(FP_7, FP_10, degrees, bx, by
    move $s3, $v0                      # bx
    move $s4, $v1                      # by

    li   $a0, FP_N7
    li   $a1, FP_10
    move $a2, $s0
    jal  rotate                        # rotate(FP_N7, FP_10, degrees, cx, cy)
    move $s5, $v0                      # cx
    move $s6, $v1                      # cy

    lw   $a0, 16($sp)
    lw   $a1, 12($sp)
    lw   $a2, 16($sp)
    lw   $a3, 12($sp)
    add  $a0, $a0, $s1                 # x + ax
    add  $a1, $a1, $s2                 # y + ay
    add  $a2, $a2, $s3                 # x + bx
    add  $a3, $a3, $s4                 # y + by
    lw   $t0, 4($sp)
    li   $t1, GRAY
    jal  draw_line                     # draw_line(x+ax, y+ay, x+bx, y+by, GRAY, c)
    beq  $v0, 1, main                  # reset if collision occurred

    lw   $a0, 16($sp)
    lw   $a1, 12($sp)
    lw   $a2, 16($sp)
    lw   $a3, 12($sp)
    add  $a0, $a0, $s1                 # x + ax
    add  $a1, $a1, $s2                 # y + ay
    add  $a2, $a2, $s5                 # x + cx
    add  $a3, $a3, $s6                 # y + cy
    lw   $t0, 4($sp)
    li   $t1, GRAY
    jal  draw_line                     # draw_line(x+ax, y+ay, x+cx, y+cy, GRAY, c)
    beq  $v0, 1, main                  # reset if collision occurred

    li   $a0, FP_N5
    li   $a1, FP_6
    move $a2, $s0
    jal  rotate                        # rotate(FP_N5, FP_6, degrees, dx, dy)
    move $s1, $v0                      # dx
    move $s2, $v1                      # dy

    li   $a0, FP_5
    li   $a1, FP_6
    move $a2, $s0
    jal  rotate                        # rotate(FP_N5, FP_6, degrees, ex, ey)
    move $s3, $v0                      # ex
    move $s4, $v1                      # ey

    lw   $a0, 16($sp)
    lw   $a1, 12($sp)
    lw   $a2, 16($sp)
    lw   $a3, 12($sp)
    add  $a0, $a0, $s1                 # x + dx
    add  $a1, $a1, $s2                 # y + dy
    add  $a2, $a2, $s3                 # x + ex
    add  $a3, $a3, $s4                 # y + ey
    lw   $t0, 4($sp)
    li   $t1, GRAY
    jal  draw_line                     # draw_line(x+dx, y+dy, x+ex, y+ey, GRAY, c)
    beq  $v0, 1, main                  # reset if collision occurred

    lw   $ra, 0($sp)
    addi $sp, $sp, 20
    jr   $ra

# Draws flame on ship (at ($a0, $a1) rotated by $a2 degrees) with color $a3
draw_flame:
    addi $sp, $sp, -20
    sw   $a0, 16($sp)                  # x
    sw   $a1, 12($sp)                  # y
    sw   $a2, 8($sp)                   # degrees
    sw   $a3, 4($sp)                   # c
    sw   $ra, 0($sp)

    move $s0, $a2                      # degrees

    li   $a0, FP_N4
    li   $a1, FP_6
    move $a2, $s0
    jal  rotate                        # rotate(FP_N4, FP_6, degrees, ax, ay)
    move $s1, $v0                      # ax
    move $s2, $v1                      # ay

    li   $a0, FP_0
    li   $a1, FP_12
    move $a2, $s0
    jal  rotate                        # rotate(FP_0, FP_12, degrees, bx, by)
    move $s3, $v0                      # bx
    move $s4, $v1                      # by

    li   $a0, FP_4
    li   $a1, FP_6
    move $a2, $s0
    jal  rotate                        # rotate(FP_4, FP_6, degrees, cx, cy)
    move $s5, $v0                      # cx
    move $s6, $v1                      # cy

    lw   $a0, 16($sp)
    lw   $a1, 12($sp)
    lw   $a2, 16($sp)
    lw   $a3, 12($sp)
    add  $a0, $a0, $s1                 # x + ax
    add  $a1, $a1, $s2                 # y + ay
    add  $a2, $a2, $s3                 # x + bx
    add  $a3, $a3, $s4                 # y + by
    lw   $t0, 4($sp)
    li   $t1, 0
    jal  draw_line                     # draw_line(x+ax, y+ay, x+bx, y+by, 0, c)

    lw   $a0, 16($sp)
    lw   $a1, 12($sp)
    lw   $a2, 16($sp)
    lw   $a3, 12($sp)
    add  $a0, $a0, $s3                 # x + bx
    add  $a1, $a1, $s4                 # y + by
    add  $a2, $a2, $s5                 # x + cx
    add  $a3, $a3, $s6                 # y + cy
    lw   $t0, 4($sp)
    li   $t1, 0
    jal  draw_line                     # draw_line(x+bx, y+by, x+cx, y+cy, 0, c)

    lw   $ra, 0($sp)
    addi $sp, $sp, 20
    jr   $ra

# Draws asteroids that have positive size with color $a0
draw_asteroids:
    save_registers

    addi $sp, $sp, -4
    sw   $a0, 0($sp)                   # save c on stack

    li   $s0, 0

    draw_asteroid_loop:                # for (i = 0; i < MAX_ASTEROIDS; i++)
    beq  $s0, ASTEROID_BYTES, end_draw_asteroid_loop

    li   $s3, 0                        #   collision = 0

    li   $s4, FP_AST_WIDTH             #   positive asteroid width
    li   $s5, FP_NAST_WIDTH            #   negative asteroid width
   
    addi $t0, $s0, OBJECT_SIZE         #   if (asteroids[i].size)
    lw   $t0, asteroids($t0)

    bne  $t0, 2, skip_size_doubling
    sll  $s4, $s4, 1                   #     width = FP_AST_WIDTH * asteroids[i].size
    sll  $s5, $s5, 1                   #     uses shifts since 0 <= size <= 2
    skip_size_doubling:

    beq  $t0, $0, skip_asteroid_iteration

    # Exploit symmetry of the square to only compute one rotation
    move $a0, $s4
    move $a1, $s5
    addi $t0, $s0, OBJECT_DEGREES
    lw   $a2, asteroids($t0)
    jal  rotate
    move $s4, $v0                      #     rx
    move $s5, $v1                      #     ry

    addi $t0, $s0, OBJECT_X
    lw   $s1, asteroids($t0)           #     x = asteroids[i].x
    addi $t0, $s0, OBJECT_Y
    lw   $s2, asteroids($t0)           #     y = asteroids[i].y

    add  $a0, $s1, $s4                 #     x + rx
    add  $a1, $s2, $s5                 #     y + ry
    sub  $a2, $s1, $s5                 #     x - ry
    add  $a3, $s2, $s4                 #     y + rx
    lw   $t0, 0($sp)                   #     c
    li   $t1, WHITE
    jal  draw_line                     #     draw_line(x+rx, y+ry, x-ry, y+rx, WHITE, c)
    or   $s3, $s3, $v0                 #     collision |= draw_line(...)

    add  $a0, $s1, $s4                 #     x + rx
    add  $a1, $s2, $s5                 #     y + ry
    add  $a2, $s1, $s5                 #     x + ry
    sub  $a3, $s2, $s4                 #     y - rx
    lw   $t0, 0($sp)                   #     c
    li   $t1, WHITE
    jal  draw_line                     #     draw_line(x+rx, y+ry, x+ry, y-rx, WHITE, c)
    or   $s3, $s3, $v0                 #     collision |= draw_line(...)

    sub  $a0, $s1, $s4                 #     x - rx
    sub  $a1, $s2, $s5                 #     y - ry
    sub  $a2, $s1, $s5                 #     x - ry
    add  $a3, $s2, $s4                 #     y + rx
    lw   $t0, 0($sp)                   #     c
    li   $t1, WHITE
    jal  draw_line                     #     draw_line(x-rx, y-ry, x-ry, y+rx, WHITE, c)
    or   $s3, $s3, $v0                 #     collision |= draw_line(...)

    sub  $a0, $s1, $s4                 #     x - rx
    sub  $a1, $s2, $s5                 #     y - ry
    add  $a2, $s1, $s5                 #     x + ry
    sub  $a3, $s2, $s4                 #     y - rx
    lw   $t0, 0($sp)                   #     c
    li   $t1, WHITE
    jal  draw_line                     #     draw_line(x-rx, y-ry, x+ry, y-rx, WHITE, c)
    or   $s3, $s3, $v0                 #     collision |= draw_line(...)

    bne  $s3, 1, skip_remove_ast       #     if (collision)
    addi $t0, $s0, OBJECT_SIZE
    lw   $t1, asteroids($t0)
    subi $t1, $t1, 1
    sw   $t1, asteroids($t0)           #       asteroids[i].size--

    beq  $t1, $0, skip_spawn_asteroids #       if (asteroids[i].size)

    # split asteroid into two with random velocities
    jal  rng
    addi $t0, $s0, OBJECT_VX
    sw   $v0, asteroids($t0)           #         asteroids[i].vx = rng()
    jal  rng
    addi $t0, $s0, OBJECT_VY
    sw   $v0, asteroids($t0)           #         asteroids[i].vy = rng()
    jal  rng
    addi $t0, $s0, OBJECT_VD
    sw   $v0, asteroids($t0)           #         asteroids[i].vd = rng()

    li   $t1, OBJECT_BYTES
    sll  $t1, $t1, 2
    add  $t1, $s0, $t1                 #         index for asteroids[i+4]

    addi $t0, $t1, OBJECT_X
    sw   $s1, asteroids($t0)           #         asteroids[i+4].x = asteroids[i].x
    addi $t0, $t1, OBJECT_Y
    sw   $s2, asteroids($t0)           #         asteroids[i+4].y = asteroids[i].y

    jal  rng
    addi $t0, $t1, OBJECT_VX
    sw   $v0, asteroids($t0)           #         asteroids[i+4].vx = rng()
    jal  rng
    addi $t0, $t1, OBJECT_VY
    sw   $v0, asteroids($t0)           #         asteroids[i+4].vy = rng()
    jal  rng
    addi $t0, $t1, OBJECT_VD
    sw   $v0, asteroids($t0)           #         asteroids[i+4].vd = rng()
    addi $t0, $t1, OBJECT_SIZE
    li   $t1, 1
    sw   $t1, asteroids($t0)           #         asteroids[i+4].size = 1
    skip_spawn_asteroids:

    # for six frames, play 220 Hz
    li   $t0, DEST_SOUND
    sw   $t0, sound_addr($0)
    li   $t0, DEST_SOUNDLEN
    sw   $t0, sound_timeout($0)
    skip_remove_ast:

    skip_asteroid_iteration:
    addi $s0, $s0, OBJECT_BYTES         # proceed to next struct
    beq  $0, $0, draw_asteroid_loop
    end_draw_asteroid_loop:

    addi $sp, $sp, 4                    # pop c off stack
    restore_registers
    jr   $ra

# Draws shots that have positive timeout with color $a0
draw_shots:
    save_registers

    addi $sp, $sp, -4
    sw   $a0, 0($sp)                   # save c on stack

    li   $s0, 0

    draw_shot_loop:                    # for (i = 0; i < MAX_SHOTS; i++)
    beq  $s0, SHOT_BYTES, end_draw_shot_loop

    li   $s3, 0                        #   collision = 0

    addi $t0, $s0, POINT_TIMEOUT       #   if (shots[i].timeout > 0)
    lw   $t0, shots($t0)
    slt  $t0, $0, $t0
    beq  $t0, $0, skip_draw_shot_iteration

    addi $t0, $s0, POINT_X
    lw   $s1, shots($t0)               #     x = shots[i].x
    addi $t0, $s0, POINT_Y
    lw   $s2, shots($t0)               #     y = shots[i].y

    move $a0, $s1                      #     x
    subi $a1, $s2, FP_2                #     y - FP_2
    move $a2, $s1                      #     x
    addi $a3, $s2, FP_2                #     y + FP_2
    lw   $t0, 0($sp)                   #     c
    li   $t1, GRAY
    jal  draw_line                     #     draw_line(x, y-FP_2, x, y+FP_2, GRAY, c)
    or   $s3, $s3, $v0                 #     collision |= draw_line(...)

    subi $a0, $s1, FP_2                #     x - FP_2
    move $a1, $s2                      #     y
    addi $a2, $s1, FP_2                #     x + FP_2
    move $a3, $s2                      #     y
    lw   $t0, 0($sp)                   #     c
    li   $t1, GRAY
    jal  draw_line                     #     draw_line(x-FP_2, y, x+FP_2, y, GRAY, c)
    or   $s3, $s3, $v0                 #     collision |= draw_line(...)

    bne  $s3, 1, skip_remove_shot      #     if (collision)
    addi $t0, $s0, POINT_TIMEOUT

    # shot will disappear next frame
    li   $t1, 1
    sw   $t1, shots($t0)               #       shots[i].timeout = 1
    skip_remove_shot:

    skip_draw_shot_iteration:
    addi $s0, $s0, POINT_BYTES         # proceed to next struct
    beq  $0, $0, draw_shot_loop
    end_draw_shot_loop:

    addi $sp, $sp, 4                   # pop c off stack
    restore_registers
    jr  $ra

# update shot and asteroid positions
update_objects:
    save_registers

    li   $s0, 0
    update_shot_loop:                  # for (i = 0; i < MAX_SHOTS; i++)
    beq  $s0, SHOT_BYTES, end_update_shot_loop

    addi $t0, $s0, POINT_TIMEOUT       #   if (shots[i].timeout > 0)
    lw   $t0, shots($t0)
    slt  $t0, $0, $t0
    beq  $t0, $0, skip_shot_iteration

    addi $t0, $s0, POINT_X
    lw   $s1, shots($t0)               #     shots[i].x
    addi $t0, $s0, POINT_VX
    lw   $s2, shots($t0)               #     shots[i].vx
    add  $a0, $s1, $s2
    li   $a1, FP_XRES
    jal  mod                           #     mod(shots[i].x+shots[i].vx, FP_XRES)
    addi $t0, $s0, POINT_X
    sw   $v0, shots($t0)               #     shots[i].x = mod(shots[i].x+shots[i].vx, FP_XRES)

    addi $t0, $s0, POINT_Y
    lw   $s1, shots($t0)               #     shots[i].y
    addi $t0, $s0, POINT_VY
    lw   $s2, shots($t0)               #     shots[i].vy
    add  $a0, $s1, $s2
    li   $a1, FP_YRES
    jal  mod                           #     mod(shots[i].y+shots[i].vy, FP_YRES)
    addi $t0, $s0, POINT_Y
    sw   $v0, shots($t0)               #     shots[i].y = mod(shots[i].y+shots[i].vy, FP_YRES)

    addi $t0, $s0, POINT_TIMEOUT
    lw   $t1, shots($t0)
    subi $t1, $t1, 1
    sw   $t1, shots($t0)               #     shots[i].timeout--

    skip_shot_iteration:
    addi $s0, $s0, POINT_BYTES         # proceed to next struct
    beq  $0, $0, update_shot_loop
    end_update_shot_loop:

    li   $s0, 0
    update_ast_loop:                   # for (i = 0; i < MAX_ASTEROID; i++)
    beq  $s0, ASTEROID_BYTES, end_update_ast_loop

    addi $t0, $s0, OBJECT_SIZE         #   if (asteroids[i].size)
    lw   $t0, asteroids($t0)
    slt  $t0, $0, $t0
    beq  $t0, $0, skip_ast_iteration

    addi $t0, $s0, OBJECT_X
    lw   $s1, asteroids($t0)           #     asteroids[i].x
    addi $t0, $s0, OBJECT_VX
    lw   $s2, asteroids($t0)           #     asteroids[i].vx
    add  $a0, $s1, $s2
    li   $a1, FP_XRES
    jal  mod                           #     mod(asteroids[i].x+asteroids[i].vx, FP_XRES)
    addi $t0, $s0, OBJECT_X
    sw   $v0, asteroids($t0)           #     asteroids[i].x = mod(...)

    addi $t0, $s0, OBJECT_Y
    lw   $s1, asteroids($t0)           #     asteroids[i].y
    addi $t0, $s0, OBJECT_VY
    lw   $s2, asteroids($t0)           #     asteroids[i].vy
    add  $a0, $s1, $s2
    li   $a1, FP_YRES
    jal  mod                           #     mod(asteroids[i].y+asteroids[i].vy, FP_YRES)
    addi $t0, $s0, OBJECT_Y
    sw   $v0, asteroids($t0)           #     asteroids[i].y = mod(...)

    addi $t0, $s0, OBJECT_DEGREES
    lw   $s1, asteroids($t0)           #     asteroids[i].degrees
    addi $t0, $s0, OBJECT_VD
    lw   $s2, asteroids($t0)           #     asteroids[i].vd
    add  $a0, $s1, $s2
    li   $a1, FP_360
    jal  mod                           #     mod(asteroids[i].degrees+asteroids[i].vd, FP_360)
    addi $t0, $s0, OBJECT_DEGREES
    sw   $v0, asteroids($t0)           #     asteroids[i].degrees = mod(...)

    skip_ast_iteration:
    addi $s0, $s0, OBJECT_BYTES        # proceed to next struct
    beq  $0, $0, update_ast_loop
    end_update_ast_loop:

    restore_registers
    jr  $ra

end:
    j   end

.include "display.asm"
.include "dataloader.asm"
.include "softmath.asm"
.include "rng.asm"
