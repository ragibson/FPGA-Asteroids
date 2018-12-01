#############################################################################################
#
# Montek Singh
# COMP 541 Final Projects
# Apr 5, 2018
#
# This is a collection of helpful procedures for developing your final project demos.
#
# Use these in your actual MIPS code that is DEPLOYED ON THE BOARDS.
# (A separate version of a subset of these procedures is available for simulation in MARS.)
#
#############################################################################################

.text	
		
	#########################################
	# pause(N), N is hundredths of a second #
	# assuming 12.5 MHz clock.              #
	# N is placed in $a0.                   #
	#########################################


pause:
	addi	$sp, $sp, -8
	sw	$ra, 4($sp)
	sw	$a0, 0($sp)
	sll     $a0, $a0, 16
	beq	$a0, $0, pse_done
pse_loop:
	addi    $a0, $a0, -1
	bne	$a0, $0, pse_loop
pse_done:
	lw	$a0, 0($sp)
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra



	#####################################
	# proc putChar_atXY                 #
	# write one char to (x,y) on screen #
	#                                   #
	#   $a0:  char                      #
	#   $a1:  x (col)                   #
	#   $a2:  y (row)                   #
	#                                   #
	# restores all registers            #
	#   before returning                #
	#####################################

.eqv screen_base 0x10020000 		# Base address of screen memory
	
putChar_atXY:	
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t2, 0($sp)
	
	li	$t0, screen_base 	# initialize to start address of screen:  0x10020000
	
	sll	$t1, $a2, 5		# t1 = a2 << 5
	sll	$t2, $a2, 3		# t2 = a2 << 3
	add	$t1, $t1, $t2		# t1 = (a2 << 5) + (a2 << 3) = 40*row
	add	$t1, $t1, $a1		# t1 = 40*row + col
	sll	$t1, $t1, 2		# (40*row + col) * 4 for memory addressing
	add	$t0, $t0, $t1		# add offset to screen base address
	
	sw 	$a0, 0($t0) 		# store character here
	
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra


	#####################################
	# proc getChar_atXY                 #
	# read char from (x,y) on screen    #
	#                                   #
	#   $v0:  char read                 #
	#   $a1:  x (col)                   #
	#   $a2:  y (row)                   #
	#                                   #
	# restores all registers            #
	#   before returning                #
	#####################################
	
getChar_atXY:	
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t2, 0($sp)
	
	li	$t0, screen_base 	# initialize to start address of screen:  0x10020000
	
	sll	$t1, $a2, 5		# t1 = a2 << 5
	sll	$t2, $a2, 3		# t2 = a2 << 3
	add	$t1, $t1, $t2		# t1 = (a2 << 5) + (a2 << 3) = 40*row
	add	$t1, $t1, $a1		# t1 = 40*row + col
	sll	$t1, $t1, 2		# (40*row + col) * 4 for memory addressing
	add	$t0, $t0, $t1		# add offset to screen base address
	
	lw 	$v0, 0($t0) 		# read character from screen
	
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra


	#####################################
	# proc get_key                      #
	# gets a key from the kayboard      #
	#                                   #
	#   $v0: 0 if no valid key          #
	#      : index 1 to N if valid key  #
	#                                   #
	# restores all registers            #
	#   before returning                #
	#####################################
	
.data
key_array:	.word	0x1C, 0x1B, 0x1D, 0x1A   	# define as many keycodes here as you need
num_keys:	.word	4				# put the length of the key_array here

.eqv keyb_mmio 0x10030000 		# from our memory map

.text
get_key:
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t2, 0($sp)

	lw	$v0, keyb_mmio($0)
	beq	$v0, $0, get_key_exit	# return 0 if no key available
	move	$t1, $v0
	
	li	$v0, 0
	lw	$t2, num_keys($0)
	sll	$t2, $t2, 2		# multiply by 4 to get max offset
get_key_loop:				# iterate through key_array to find match
	lw	$t0, key_array($v0)
	addi	$v0, $v0, 4		# go to next array element
	beq	$t0, $t1, get_key_exit
	slt	$1, $v0, $t2
	bne	$1, $0, get_key_loop
	li	$v0, 0			# key not found in key_array
	
get_key_exit:
	srl	$v0, $v0, 2		# index of key found = offset by 4
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra


	#####################################
	# proc get_accel                    #
	# gets value from accelerometer     #
	#                                   #
	#   $v0: accel value                #
	#                                   #
	#####################################
	
.eqv accel_mmio 0x10030004 		# from our memory map

.text
get_accel:
	lw	$v0, accel_mmio($0)
	jr	$ra

get_accelX:
	lw	$v0, accel_mmio($0)
	srl	$v0, $v0, 16		# bits 16-24 is X accel (9 bits)
	andi	$v0, $v0, 0x01FF
	jr	$ra

get_accelY:
	lw	$v0, accel_mmio($0)
	andi	$v0, $v0, 0x01FF	# bits 0-8 is Y accel (9 bits)
	jr	$ra

	#####################################
	# proc put_sound                    #
	# generates a tone with a specified #
	#   period                          #
	#                                   #
	#   $a0: period (0 turns sound off) #
	#                                   #
	#####################################
	
.eqv sound_mmio 0x10030008 		# from our memory map

.text
put_sound:
	sw	$a0, sound_mmio($0)
	jr	$ra

sound_off:
	sw	$0, sound_mmio($0)
	jr	$ra


	#####################################
	# proc put_leds                     #
	# lights up a pattern on the        #
	#   16 LEDs                         #
	#                                   #
	#   $a0: pattern (lower 16 bits)    #
	#                                   #
	#####################################
	
.eqv leds_mmio 0x1003000C 		# from our memory map

.text
put_leds:
	sw	$a0, leds_mmio($0)
	jr	$ra
