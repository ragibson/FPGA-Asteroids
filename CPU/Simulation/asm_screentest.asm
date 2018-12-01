#############################################################################################
#
# Montek Singh
# COMP 541 Final Projects
# Apr 5, 2018
#
# This is a MIPS program that tests the MIPS processor and the VGA display,
# using a very simple animation.
#
# This program assumes the memory-IO map introduced in class specifically for the final
# projects.  In MARS, please select:  Settings ==> Memory Configuration ==> Default.
#
# NOTE:  MEMORY SIZES.
#
# Instruction memory:  This program has 103 instructions.  So, make instruction memory
# have a size of at least 128 locations.
#
# Data memory:  Make data memory 64 locations.  This program only uses two locations for data,
# and a handful more for the stack.  Top of the stack is set at the word address
# [0x100100fc - 0x100100ff], giving a total of 64 locations for data and stack together.
# If you need larger data memory than 64 words, you will have to move the top of the stack
# to a higher address.
#
#############################################################################################
#
# THIS VERSION HAS LONG PAUSES:  Suitable for board deployment, NOT for Vivado simulation
#
#############################################################################################


.data 0x10010000 			# Start of data memory
a_sqr:	.space 4
a:	.word 3

.text 0x00400000			# Start of instruction memory
main:
	lui	$sp, 0x1001		# Initialize stack pointer to the 64th location above start of data
	ori 	$sp, $sp, 0x0100	# top of the stack is the word at address [0x100100fc - 0x100100ff]
	
	
	#############################
	# TEST ALL 25 INSTRUCTIONS #
	#############################

	lui	$t0, 0xffff
	ori	$t0, $t0, 0xffff 	# $t0 = -1
	addi	$t1, $0, -1		# $t1 = -1
	bne	$t0, $t1, end
	sll	$t0, $t0, 24		# $t0 = 0xff00_0000
	ori 	$t0, $t0, 0xf000	# $t0 = 0xff00_f000
	sra	$t0, $t0, 8		# $t0 = 0xffff_00f0
	srl	$t0, $t0, 4		# $t0 = 0x0fff_f00f
	ori	$t2, $0, 3		# $t2 = 3
	sub	$t2, $t2, $t1 		# $t2 = 3 - (-1) = 4
	sllv	$t0, $t0, $t2 		# $t0 = 0xffff_00f0
	
	slt 	$t3, $t0, $t2 		# 0xffff_00f0 < 4 ?  (signed)  YES
	sltu 	$t3, $t0, $t2 		# 0xffff_00f0 < 4 ?  (unsigned)  NO
	addi 	$t0, $0, 5		# $t0 = 5
	sltiu	$t3, $t0, 10		# $t0 < 10?
	sltiu	$t3, $t0, 4		# $t0 < 4?
	addi 	$t0, $0, -5		# $t0 = -5
	sltiu	$t3, $t0, 5		# $t0 < 5?  NO -- see writeup
		
	lui 	$t3, 0x1010
	ori	$t3, $t3, 0x1010	# $t3 = 0x1010_1010
	lui 	$t4, 0x0101
	addi	$t4, $t4, 0x1010	# $t4 = 0x0101_1010
	and	$t5, $t3, $t4
	or	$t5, $t3, $t4
	xor	$t5, $t3, $t4
	nor	$t5, $t3, $t4
     	
	##############################################
	# TEST procedure calls, stack and recursion #
	##############################################

	lw	$a0, a($0) 		# bring a into register $a0
	addi	$a0, $a0, 2
	addiu	$a0, $a0, 0xfffffffe 	# -2
	jal   	sqr			# compute sqr(a)
	sw	$v0, a_sqr($0)		# store result into a_sqr     



	###############################################
	# ANIMATE character on screen                 #
	#                                             #
	# To eliminate pauses (for Vivado simulation) #
	# replace the two "jal pause" instructions    #
	# by nops.                                    #
	###############################################

	addi	$a0, $0, 1000    	# let's pause for 10 seconds
	jal	pause
	# nop
	
	li	$a1, 0			# initialize to first screen col (X=0)
	li	$a2, 0			# initialize to first screen row (Y=0)

animate_loop:	
	li	$a0, 2			# draw character 2 here
	jal	putChar_atXY 		# $a0 is char, $a1 is X, $a2 is Y
	
	li	$a0, 50			# pause for 1/2 second
	jal	pause
	# nop
	
	li	$a0, 3			# overwrite with character 3 here
	jal	putChar_atXY
	
	addi 	$a1, $a1, 1 		# increment col
	addi	$a2, $a2, 1		# increment row
	
	slti 	$t0, $a2, 30 		# still on screen?  row < 30?
	bne	$t0, $0, animate_loop

	addi 	$a1, $a1, -1 		# backtrack one step
	addi	$a2, $a2, -1		# backtrack one step

	li	$a0, 0			# overwrite with character 0 here
	jal	putChar_atXY	

			
					
	###############################
	# END using infinite loop     #
	###############################
end:
	j	end          	# infinite loop "trap" because we don't have syscalls to exit


######## END OF MAIN #################################################################################


######## CALLED PROCEDURES BELOW #####################################################################



	###############################
	# sqr() recursive procedure   #
	###############################

sqr:
	addi	$sp,$sp,-8
	sw	$ra,4($sp)
	sw	$a0,0($sp)
	slti	$t0,$a0,2
	beq	$t0,$0,then
	add	$v0,$0,$a0
	j	rtn	
then:
	addi	$a0,$a0,-1
	jal	sqr
	lw	$a0,0($sp)
	add	$v0,$v0,$a0
	add	$v0,$v0,$a0
	addi	$v0,$v0,-1
rtn:
	lw	$ra,4($sp)
	addi	$sp,$sp,8
	jr	$ra
	
	
######## END OF CODE #################################################################################

.include "procs_board.asm"
