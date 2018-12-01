.data TABLE_START
    # lookup table for cos(d), 0 <= d < 360 (values in fp16_t)
    fpcos_table:
      .word 64,  64,  64,  64,  64,  64,  64,  64,  63,  63,  63,  63,  63,  62,  62,
            62,  62,  61,  61,  61,  60,  60,  59,  59,  58,  58,  58,  57,  57,  56,
            55,  55,  54,  54,  53,  52,  52,  51,  50,  50,  49,  48,  48,  47,  46,
            45,  44,  44,  43,  42,  41,  40,  39,  39,  38,  37,  36,  35,  34,  33,
            32,  31,  30,  29,  28,  27,  26,  25,  24,  23,  22,  21,  20,  19,  18,
            17,  15,  14,  13,  12,  11,  10,  9,   8,   7,   6,   4,   3,   2,   1,
            0,   -1,  -2,  -3,  -4,  -6,  -7,  -8,  -9,  -10, -11, -12, -13, -14, -15,
            -17, -18, -19, -20, -21, -22, -23, -24, -25, -26, -27, -28, -29, -30, -31,
            -32, -33, -34, -35, -36, -37, -38, -39, -39, -40, -41, -42, -43, -44, -44,
            -45, -46, -47, -48, -48, -49, -50, -50, -51, -52, -52, -53, -54, -54, -55,
            -55, -56, -57, -57, -58, -58, -58, -59, -59, -60, -60, -61, -61, -61, -62,
            -62, -62, -62, -63, -63, -63, -63, -63, -64, -64, -64, -64, -64, -64, -64,
            -64, -64, -64, -64, -64, -64, -64, -64, -63, -63, -63, -63, -63, -62, -62,
            -62, -62, -61, -61, -61, -60, -60, -59, -59, -58, -58, -58, -57, -57, -56,
            -55, -55, -54, -54, -53, -52, -52, -51, -50, -50, -49, -48, -48, -47, -46,
            -45, -44, -44, -43, -42, -41, -40, -39, -39, -38, -37, -36, -35, -34, -33,
            -32, -31, -30, -29, -28, -27, -26, -25, -24, -23, -22, -21, -20, -19, -18,
            -17, -15, -14, -13, -12, -11, -10, -9,  -8,  -7,  -6,  -4,  -3,  -2,  -1,
            0,   1,   2,   3,   4,   6,   7,   8,   9,   10,  11,  12,  13,  14,  15,
            17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,
            32,  33,  34,  35,  36,  37,  38,  39,  39,  40,  41,  42,  43,  44,  44,
            45,  46,  47,  48,  48,  49,  50,  50,  51,  52,  52,  53,  54,  54,  55,
            55,  56,  57,  57,  58,  58,  58,  59,  59,  60,  60,  61,  61,  61,  62,
            62,  62,  62,  63,  63,  63,  63,  63,  64,  64,  64,  64,  64,  64,  64

.text

# Computes $v0 = ($a0 << FP_SHIFT_AMOUNT)
int_to_fp:
    sll $v0, $a0, FP_SHIFT_AMOUNT
    jr  $ra

# Computes $v0 = ($a0 >> FP_SHIFT_AMOUNT)
fp_ipart:
    srl $v0, $a0, FP_SHIFT_AMOUNT
    jr  $ra

# Computes $v0 = ($a0 & FP_FRAC_MASK)
fp_fpart:
    andi $v0, $a0, FP_FRAC_MASK
    jr   $ra

# Computes $v0 = ($a0 * $a1), saves no registers, uses $t0-$t5
imult:
    slt  $t0, $a0, $0
    slt  $t1, $a1, $0
    xor  $t2, $t0, $t1                 # neg_result = (a < 0) ^ (b < 0)
    
    beq  $t0, $0, skip_imult_negate_a  # if (a < 0)
    sub  $a0, $0, $a0                  #   a = -a
    skip_imult_negate_a:
    beq  $t1, $0, skip_imult_negate_b  # if (b < 0)
    sub  $a1, $0, $a1                  #   b = -b
    skip_imult_negate_b:
    
    li   $t3, 0                        # res = 0
    start_imult_while:              
    slt  $t4, $0, $a1
    beq  $t4, $0, end_imult_while      # while (b < 0)
    andi $t5, $a1, 0x1
    beq  $t5, $0, skip_imult_add       # if (b & 1)
    add  $t3, $t3, $a0                 #   res += a
    skip_imult_add:
    sll  $a0, $a0, 1
    sra  $a1, $a1, 1
    beq  $0, $0, start_imult_while
    end_imult_while:
    
    beq  $t2, $0, skip_neg_result      # if (neg_result)
    sub  $t3, $0, $t3                  #   res = -res
    skip_neg_result:
    
    move $v0, $t3
    jr   $ra                           # return res

# Computes $v0 = ($a0 / $a1), saves no registers, uses $t0-$t5
idiv:
    slt  $t0, $a0, $0                  # neg_result = a < 0
    beq  $t0, $0, skip_idiv_negate_a   # if (neg_result)
    sub  $a0, $0, $a0                  #   a = -a
    skip_idiv_negate_a:

    li   $t1, 1                        # place = 1
    li   $t2, 0                        # res = 0
    start_idiv_while1:
    slt  $t3, $a0, $a1                 # while (a >= b)
    bne  $t3, $0, end_idiv_while1
    sll  $t1, $t1, 1                   #   place <<= 1
    sll  $a1, $a1, 1                   #   b <<= 1
    beq  $0, $0, start_idiv_while1
    end_idiv_while1:
    
    start_idiv_while2:
    slt  $t4, $0, $t1     
    beq  $t4, $0, end_idiv_while2      # while (place > 0)
    slt  $t5, $a0, $a1      
    bne  $t5, $0, skip_idiv_sub        # if (a >= b)
    sub  $a0, $a0, $a1                 #   a -= b
    add  $t2, $t2, $t1                 #   res += place
    skip_idiv_sub:
    sra  $t1, $t1, 1                   # place >>= 1
    sra  $a1, $a1, 1                   # b >>= 1
    beq  $0, $0, start_idiv_while2
    end_idiv_while2:
    
    beq  $t0, $0, skip_idiv_negate_res # if (neg_result)
    sub  $t2, $0, $t2                  #   res = -res
    skip_idiv_negate_res:
    
    move $v0, $t2
    jr   $ra                           # return res
    
# Computes "rounded" $v0 = (a >> FP_SHIFT_AMOUNT), saves no registers, uses $t0-$t1
round_fp_to_int:
    sra  $t0, $a0, FP_SHIFT_AMOUNT     # res = a >> FP_SHIFT_AMOUNT
    and  $t1, $a0, FP_ROUND_MASK
    beq  $t1, $0, skip_round_increment # if (a & FP_ROUND_MASK)
    addi $t0, $t0, 1                   #   res++
    skip_round_increment:
    
    move $v0, $t0
    jr   $ra                           # return res

# Computes $v0 = abs($a0), saves no registers, uses $t0
abs:
    slt  $t0, $a0, $0
    beq  $t0, $0, skip_abs_negate      # if (a < 0)
    sub  $a0, $0, $a0                  #   a = -a
    skip_abs_negate:
    
    move $v0, $a0
    jr   $ra                           # return a

# Computes $v0 = imult($a0, $a1) >> FP_SHIFT_AMOUNT, saves $ra, uses $t0-$t5
fpmult:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    jal  imult
    sra  $v0, $v0, FP_SHIFT_AMOUNT
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra                           # return imult(a, b) >> FP_SHIFT_AMOUNT
    
# Computes $v0 = idiv($a0 << FP_SHIFT_AMOUNT, $a1), saves $ra, uses $t0-$t5
fpdiv:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    sll  $a0, $a0, FP_SHIFT_AMOUNT     # a <<= FP_SHIFT_AMOUNT
    jal  idiv
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra                           # return idiv(a, b)

# Computes ($a0 % $a1), saves no registers, uses $t0-$t1
mod:
    slt  $t0, $a0, $a1
    bne  $t0, $0, skip_mod_sub         # if (x >= m)
    sub  $a0, $a0, $a1                 #   x -= m
    beq  $0, $0, skip_mod_add
    skip_mod_sub:
    slt  $t0, $a0, $0
    beq  $t0, $0, skip_mod_add         # else if (x < 0)
    add  $a0, $a0, $a1                 #   x += m
    skip_mod_add:
    
    move $v0, $a0
    jr   $ra                           # return x

# Computes $v0 = cos($a0) ($a0 in degrees, result in fp16_t), saves $ra, uses $t0-$t1
fpcos:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    jal  round_fp_to_int               # ideg = round_fp_to_int(degrees)
    
    move $a0, $v0
    li   $a1, 360
    jal  mod                           # ideg %= 360
    
    sll  $v0, $v0, 2                   # word-align array index
    lw   $v0, fpcos_table($v0)
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra                           # return fpcos_table[ideg]

# Computes $v0 = sin($a0) ($a0 in degrees, result in fp16_t), saves $ra, uses $t0-$t1
fpsin:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    subi $a0, $a0, FP_90_DEG            # degrees -= INT_TO_FP(90)
    jal  fpcos
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra                            # return fpcos(degrees)
