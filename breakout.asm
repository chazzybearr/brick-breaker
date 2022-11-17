################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000

# The colours being used - red, green, blue in an array
MY_COLOURS:
    .word 0xff0000
    .word 0x00ff00
    .word 0x0000ff
    
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000


##############################################################################
# Mutable Data
##############################################################################
BALL: # Needs x,y values for now (x,y values should be more than bottom wall, between two right/left walls)
	.space 8
PADDLE: # Needs x,y values for now -> "4" pixels wide, indicate the left most pixel 
	#(x,y values should be more than bottom wall, between two right/left walls)
	.space 8
LEFT_WALL: # Needs x value, draw from bottom to top (all y-values)
	.space 4
BOTTOM_WALL: # Needs y value, draw from left to right (all x-values)
	.space 4
RIGHT_WALL: # Needs x value, draw from bottom to top (all y-values)
	.space 4
BRICK:  # Needs x,y values for now -> "2" pixels wide, indicate the left most pixel 
	#(x,y values should be more than bottom wall, between two right/left walls)
	.space 8
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game
    la $t0, MY_COLOURS
    lw $t0, 0($t0)
    
    # Knowing where to write (top-left unit): ADR_DSPL
    la $t1, ADDR_DSPL
    lw $t1, 0($t1)
    
    li $t2, 32
    li $t3, 0
    
    three_line_loop:
        add $t8, $zero, $zero
        beq $t8, 3, end_draw_line
    	add $t9, $zero, $zero

    # Each line is 32 units -> 32 times drawing a line
    draw_line_loop:
    	bge $t9, 32, three_line_loop
    	sw  $t0, 0($t1)
    	addi $t1, $t1, 4
    	addi $t9, $t9, 1
    	b draw_line_loop
    
    end_draw_line:


game_loop:
	# 1a. Check if key has been pressed 
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    # b game_loop
