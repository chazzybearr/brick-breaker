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

# The colours being used - red, green, blue, white in an array
MY_COLOURS:
    .word 0xff0000 # red
    .word 0x00ff00 # green
    .word 0x0000ff # blue
    .word 0xffffff # white
    
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
    lw $t4, 12($t0)  	# $t4 = white
    lw $t0, 0($t0) 	# $t0 = red
    
    # Knowing where to write (top-left unit): ADR_DSPL
    la $t1, ADDR_DSPL
    lw $t2, 0($t1) 	#t2 = ADR_DSPL
    
    
    
    # Initializing the game walls
    top_wall:
    	sw  $t4, 0($t2)		# Displaying the pixel
    	addi $t2, $t2, 4	# Moving the display pixel over by one unit
    	addi $t5, $t5, 1	# Incrementing the counter
    	blt $t5, 32, top_wall	# Loop if conditions not met
    
    lw $t2, 0($t1) 		# Resetting address display pixel
    
    left_wall:
    	sw  $t4, 0($t2)
    	addi $t2, $t2, 128
    	addi $t6, $t6, 1
    	blt $t6, 32, left_wall
    
    lw $t2, 0($t1) 
    
    right_wall:	
    	sw  $t4, 252($t2)
    	addi $t2, $t2, 128
    	addi $t7, $t7, 1
    	blt $t7, 32, right_wall


    li $t2, 32
    li $t3, 0
    
 #   li $t8, 0
    three_line_loop:	# draws three lines





game_loop:
	# 1a. Check if key has been pressed 
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    # b game_loop
