################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Mani Setayesh, 1008078367
# Student 2: Leon Cai, 1007966523
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
    
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

# The colours being used
MY_COLOURS:
    .word 0xff0000	# red
    .word 0x00ff00	# green
    .word 0xffa500	# orange
    .word 0xffff00	# yellow
    .word 0x008000	# dark green
    .word 0x0000ff	# blue    
    .word 0x4b0082	# purple
    .word 0xee82ee	# pink
    .word 0xffffff	# white
    .word 0x808080	# gray
    .word 0x000000	# black (eraser)

##############################################################################
# Mutable Data
##############################################################################
BALL: # BALL for x value, BALL + 4 for y value, BALL  + 8 for direction of ball
	# Ball direction: 1 = up-right, 2 = up-left, 3 = down-left, 4 = down-right (cntr clk from top-right)
	.space 12
PADDLE: # PADDLE for x value, PADDLE + 4 for y value
	.space 8
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    jal clear_screen
    li $s7, 0
    li $v0, 32
    li $a0, 100 
    syscall
    # Knowing where to write (top-left unit): ADR_DSPL
    la $t1, ADDR_DSPL
    lw $t2, 0($t1) 	# $t2 = ADR_DSPL
    
    # Initializing the game walls
    lw $t4, MY_COLOURS + 36  
 
     top_wall:
    	sw  $t4, 0($t2)		# Displaying the pixel
    	addi $t2, $t2, 4	# Moving the display pixel over by one unit
    	addi $t5, $t5, 1	# Incrementing the counter
    	blt $t5, 32, top_wall	# Loop if conditions not met
    
    lw $t2, 0($t1) 		# Resetting address display pixel
    
    left_wall:
    	sw  $t4, 0($t2)
    	addi $t2, $t2, 128	# Moving the display pixel to the next row
    	addi $t6, $t6, 1
    	blt $t6, 32, left_wall
    
    lw $t2, 0($t1) 
    
    right_wall:	
    	sw  $t4, 252($t2)
    	addi $t2, $t2, 128	# Moving the display pixel to the next row
    	addi $t7, $t7, 1
    	blt $t7, 32, right_wall
    	
    li $t2, 32
    li $t3, 0
    li $t8, 0
    
    lw $t1, 0($t1)
    la $t0, MY_COLOURS
    seven_line_loop:	# draws seven lines
	beq $t8, 7, setup_ball
	lw $t2,0($t0)
        addi $t0,$t0, 4
	add $t8, $t8, 1
	li $t9, 0
	
    # Each line is 32 units -> 32 times drawing a line
    draw_line_loop:	# draws one line
    	bge $t9, 30, new_line	# 32 total pixels per row - 2 edge walls
    	sw  $t2, 132($t1)	# 132 - starts drawing at second row second pixel
    	addi $t1, $t1, 4
    	addi $t9, $t9, 1
    	b draw_line_loop
    
    new_line: 		# goes to a new line
	addi $t1, $t1, 8 	# sets display pixel to be second pixel of next line
	b seven_line_loop
	
    setup_ball:
    	li $t0, 16	
    	sw $t0, BALL 		#loads starting ball's x-value
    	li $t0, 20
    	sw $t0, BALL + 4 	#loads starting ball's y-value
    	li $t0, 1
    	sw $t0, BALL + 8	#loads starting ball's direction (diagonal up + right)
    	
    setup_paddle: 		#draws the paddle
    	li $t0, 14	
    	sw $t0, PADDLE 		#loads starting paddle's x-value 
    	li $t0, 28
    	sw $t0, PADDLE + 4 	#loads starting paddle's y-value (constant)
    	
game_loop:
	jal too_late
	beq $v0, 1, terminate # terminates the loop - before the setting of the loop variables
	
	# setting up loop variables - useful to keep track of things within each loop between function calls
	addi $sp, $sp, -12
	sw $s0, 8($sp)
	sw $s1, 4($sp)
	sw $s2, 0($sp)

	# 1a. Check if key has been pressed 
	lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
  	lw $t8, 0($t0)                  # Load first word from keyboard
    	beq $t8, 1, keyboard_input      # If first word 1, key is pressed
	b collisions
	
	keyboard_input:
    	# 1b. Check which key has been pressed (supports caps-lock)
    	lw $a0, 4($t0)                  # Load second word from keyboard
    	beq $a0, 0x61, m_left
    	beq $a0, 0x41, m_left
    	beq $a0, 0x64, m_right
    	beq $a0, 0x44, m_right
    	beq $a0  0x70, pause		# User pressed p on keyboard
    	beq $a0  0x50, pause
    	beq $a0, 0x71, terminate
    	beq $a0, 0x51, terminate
    	b collisions
    	
    	pause:
    		lw $t0, ADDR_KBRD 
    		lw $t8, 0($t0)
    		beq $t8, 0, pause 	# Loading first word from keyboard and checking if there is no keyboard press
    		lw $t8, 4($t0)		# Loading the key from keyboard
    		bne $t8, 0x50, pause
    		bne $t8, 0x70, pause	# Keep looping if key is not p
    		b game_loop		# Resume game
    		
    	
    	m_left: 
    		jal pad_left
    		b collisions
    	m_right:
    		jal pad_right
    		b collisions

    	collisions: 
    	li $s0, 0
    	li $s1, 0
    	li $s2, 0
    	# 2a. Check for collisions 	
    	jal paddle_collision
    	addi $s0, $v0, 0
    	jal wall_collision
    	addi $s1, $v0, 0
    	jal brick_collision
    	addi $s2, $v0, 0
    	beq $v0, 1, add_score
    	b no_score
    	add_score: addi $s7, $s7, 1
    	no_score:
    	addi $a0, $s2, 0
    	jal brick_destroyer
    	
    	# update the direction of the ball accordingly. Then move the ball.
    	addi $a0, $s0, 0
    	addi $a1, $s1, 0
    	addi $a2, $s2, 0
    	jal new_dir
	sw $v0, BALL + 8
	jal ball_mover
	
	# 3. Draw the screen
	jal draw_paddle
	# 4. Sleep
	li $v0, 32
	li $a0, 100 
	syscall

    #5. Go back to 1
	lw $s2, 0($sp)
	lw $s1, 4($sp)
	lw $s0, 8($sp)
	addi $sp, $sp, 12
   	b game_loop

# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 31, inclusive
#       - y is between 0 and 31, inclusive   
get_location_address:
    # Each unit is 4 bytes. Each row has 32 units (128 bytes)
	sll 	$a0, $a0, 2		# x = x * 4
	sll 	$a1, $a1, 7             # y = y * 128

    # Calculate return value
	la 	$v0, ADDR_DSPL 		# res = address of ADDR_DSPL
    	lw      $v0, 0($v0)             # res = address of (0, 0)
	add 	$v0, $v0, $a0		# res = address of (x, 0)
	add 	$v0, $v0, $a1           # res = address of (x, y)

    	jr $ra

# draw_ball() -> void
#	draws the ball on the screen
draw_ball:
	#PROLOGUE - SAVE RA in STACK
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
    	lw $a0, BALL 		#function parameter - ball's x-value
    	lw $a1, BALL + 4 	#function parameter - ball's y-value
    	jal get_location_address
    	lw $t0, MY_COLOURS + 32
    	sw $t0, ($v0)		#store white in address returned by function (the ball)
	
	#EPILOGUE - LOAD RA from STACK
	lw $ra, 0($sp)
	addi $sp, $sp, 4

# draw_paddle() -> void
#	draws the paddle on the screen	
draw_paddle:
	#PROLOGUE - SAVE RA in STACK
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
    	lw $a0, PADDLE 		#function parameter - paddle's x-value
    	lw $a1, PADDLE + 4 	#function parameter - paddle's y-value
    	jal get_location_address
    	lw $t0, MY_COLOURS + 36
    	sw $t0, ($v0)		#store gray in address returned by function
    	li $t3, 0
    	draw_paddle_loop:
    		beq $t3, 4, draw_paddle_epi
    		addi $v0, $v0, 4	#given address is the leftest pixel of the paddle, add 4 to move right
    		sw $t0, ($v0)		#store gray
    		addi $t3, $t3, 1	#loop 4 times (for paddle of length 4)
    		b draw_paddle_loop
    		
    	#EPILOGUE - LOAD RA from STACK
    	draw_paddle_epi:
	lw $ra, 0($sp)
	addi $sp, $sp, 4	

# too_late() -> boolean
# 	return 1 if the ball is below the paddle - 0 if not.
too_late:
	lw $t0, BALL + 4
	lw $t1, PADDLE + 4
	ble $t0, $t1, not_late 		# The "if-statement", branch accordingly and update return register
	li $v0, 1
	b late_epilogue
	not_late:
	li $v0, 0
	late_epilogue:
	jr $ra

# paddle_collision() -> boolean
#	return 1 if ball will collide with the paddle. 0 if not.
paddle_collision:
	li $v0, 1 # Assume it collides
	lw $t0, BALL + 8
	lw $t1, BALL + 4
	lw $t2, PADDLE + 4 	# Load y-values of both paddle and ball and the ball's direction
	sub $t3, $t2, $t1 	# Get the vertical distance between ball/paddle
	blt $t0, 3, no_collision # If the ball is going up, no paddle collision
	bgt $t3, 1, no_collision # If the vertical distance is greater than 2, no collision
	lw $t1, BALL 
	lw $t2, PADDLE 
	sub $t3, $t2, $t1 # Load x-values, get horizontal distance
	blt $t3, -5, no_collision
	bgt $t3, 0, no_collision  # If horizontal distance is > 5 or  < -1, no collision occurs
	beq $t0, 3, l_coll
	beq $t0, 4, r_coll # Type of collision - from left/right side depending on ball's direction
	l_coll:
		bgt $t3, 0, no_collide # If direction is towards left, and distance is < 0, no collision. Else collision.
		b paddle_coll_epi
	r_coll:
		blt $t3, -4, no_collide # Same idea
		b paddle_coll_epi
	no_collide:
		li $v0, 0
	paddle_coll_epi:
	jr $ra
	
# wall_collision() -> int
#	return a value based on the collision with the type of wall
#	this value predicts if a collision will happen AFTER moving - in the next TURN
#	corner collision: return 4
# 	left-wall collision: return 3
#	right-wall collision: return 2
#	top-wall collision: return 1
#	no collision: return 0
wall_collision:
	
	lw $t0, BALL 				# Load the values of the ball - its position (x,y) and its direction
	lw $t1, BALL + 4
	lw $t2, BALL + 8
	
	top_collide:
		beq $t2, 3, left_collide 		# If the ball is going down, then it won't collide with the top wall
		beq $t2, 4, right_collide
		
		li $v0, 1 			# Add 1 to the ball's y-value, assume it hits the top wall.
		addi $t1, $t1, -1
		
		beq $t1, 0, corner_collide 	# If ball is hitting the top wall, then check for corner collisions. 
		beq $t2, 1, right_collide 		# Else, check for right/left walls (will update return value)
		beq $t2, 2, left_collide
	
	corner_collide:
		beq $t2, 1, r_corner		# Different corners depending on the direction of the ball
		beq $t2, 2, l_corner
		
		r_corner:			# Check if it collides with the right wall. If it does, update the return value to 4.
			addi $t0, $t0, 2	
			blt $t0, 32, collide_epilogue
			b collides
		
		l_corner:			# Check if it collides with the left wall. If it does, update the return value to 4.
			addi $t0, $t0, -2
			bgt $t0, 0, collide_epilogue
			b collides
		
		collides:			# Update return value to 4.
			li $v0, 4
			b collide_epilogue
			
	left_collide:			# Check if it collides with the left wall. If not, then no collision has occured.
		li $v0, 3		# If yes, then update return value. Same idea for right_wall.		
		addi $t0, $t0, -2
		bgt $t0, -1, no_collision
		b collide_epilogue
	
	right_collide:
		li $v0, 2
		addi $t0, $t0, 2
		blt $t0, 32, no_collision
		b collide_epilogue
	
	no_collision:
		li $v0, 0
		
	collide_epilogue:
	jr $ra

#next_ball_loc() -> (int x, int y)
#	return the next location of the ball - (x,y) coordinates
next_ball_loc:
	lw $t0, BALL + 8
	beq $t0, 2, u_l
	beq $t0, 3, d_l
	beq $t0, 4, d_r
	u_r:
    		lw $v0, BALL		#load ball's current position
    		lw $v1, BALL + 4
    		addi $v0, $v0, 1	#update ball's current position (x,y) --> (x+1, y-1)
    		addi $v1, $v1, -1
    		b next_loc_epi
    	u_l: 
    		lw $v0, BALL		#load ball's current position
    		lw $v1, BALL + 4
    		addi $v0, $v0, -1	#update ball's current position (x,y) --> (x-1, y-1)
    		addi $v1, $v1, -1
      		b next_loc_epi
    	d_l:				
    		lw $v0, BALL		#load ball's current position
    		lw $v1, BALL + 4
    		addi $v0, $v0, -1	#update ball's current position (x,y) --> (x-1, y+1)
    		addi $v1, $v1, 1
    		b next_loc_epi
    	d_r: 
    		lw $v0, BALL		#load ball's current position
    		lw $v1, BALL + 4
    		addi $v0, $v0, 1	#update ball's current position (x,y) --> (x+1, y+1)
    		addi $v1, $v1, 1
    	
    	next_loc_epi:
    	jr $ra,

# brick_destroyer(boolean: brick_collision) -> void
#	 if the boolean is true, then destroy the brick that is in the next location of the ball
brick_destroyer:
	addi $sp,$sp, -12
	sw $s1, 8($sp)
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	beq $a0, 0, destroyer_epi #Check the input boolean for collision actually occuring
	jal next_ball_loc
	addi $s0, $v0, 0
	addi $s1, $v1, 0 
	addi $a0, $v0, 0
	addi $a1, $v1, 0
	jal get_location_address #get ball's next location
	lw $t0, MY_COLOURS + 40
	sw $t0, ($v0)
	and $t0, $s1, 1
	beq $t0, 1, odd_line # check if the next location is on an even/odd value of "y"
	b even_line
	odd_line: # if odd, store black in the ball's next location and the pixel right to it
		addi $v0, $v0, 4
		lw $t0, MY_COLOURS + 40
		sw $t0, ($v0)
		b destroyer_epi
	even_line: # if even, store black in the ball's next location and the pixel left to it
		addi $v0, $v0, -4
		lw $t0, MY_COLOURS + 40
		sw $t0, ($v0)
	destroyer_epi:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp,$sp,12
	jr $ra

# brick_collision() -> boolean:collides
#	return 1 if ball collides with "a colour". 0 otherwise
brick_collision:
	addi $sp,$sp, -4
	sw $ra, 0($sp)
	
	#get the ball's next location, assume collision occurs
	lw $t0, BALL + 8

	jal next_ball_loc
	addi $a0, $v0, 0
	addi $a1, $v1, 0
	jal get_location_address #get the address of the next location
	lw $t1, MY_COLOURS + 40 
	lw $t2, MY_COLOURS + 36
	lw $t3, ($v0)
	li $v0, 1
	#check if the next location has a colour other than black/gray
	beq $t3, $t1, no_brick_coll
	beq $t3, $t2, no_brick_coll
	b brick_coll_epi
	no_brick_coll: # if no collision, update value to 0
		li $v0, 0	
	brick_coll_epi:
	lw $ra, 0($sp)
	addi $sp,$sp,4
	jr $ra
	
# new_dir(hit_pad, hit_wall, hit_brick) -> new_dir
#	takes in whether the ball had any collisions, and provides a new direction based on the collision

new_dir:
	# Load the ball's direction, check for which collision that occured based on the inputs (paddle first)
	lw $t0, BALL + 8
    	beq $a0, 1, hit_paddle
    	bgtz $a1, hit_wall
    	bgtz, $a2, hit_brick
    	
    	# No collision - jump to end
    	b new_dir_epi
    	
	hit_paddle:
		#compare the direction of the ball, change accordingly
		beq $t0, 4, l_to_r
		li $t0, 2
		b hit_pad_epi
		l_to_r:
			li $t0, 1
		# store new direction, check for other collisions (brick/wall)
		hit_pad_epi:
			sw $t0, BALL + 8
			bgtz $a1, hit_wall
			bgtz $a2, hit_brick
			b new_dir_epi
	hit_wall:
		#compare the direction of the ball, change accordingly
		beq $a1, 2, right_side
		beq $a1, 3, left_side
		beq $a1, 4, t_corner
		beq $t0, 1, top_l2r
		
		li $t0, 3
		b hit_wall_epi
		top_l2r:
			li $t0, 4
			b hit_wall_epi
		right_side:
			beq $t0, 4, right_td
			li $t0, 2
			b hit_wall_epi
			right_td: li $t0, 3
			b hit_wall_epi
		left_side:
			beq $t0, 3, left_td
			li $t0, 1
			b hit_wall_epi
			left_td: li $t0, 4
			b hit_wall_epi
		t_corner:
			beq $t0, 2, l_corn 
			li $t0, 3
			b hit_wall_epi
			l_corn: li $t0, 4
			b hit_wall_epi
		# store new direction, check for other collisions (brick/wall)
		hit_wall_epi:
			sw $t0, BALL + 8
			bgtz $a2, hit_brick
			b new_dir_epi
	
	hit_brick:
		#compare the direction of the ball, change accordingly
		li $a2, 0
		beq $t0, 1, brick_ur
		beq $t0, 2, brick_ul
		beq $t0, 3, brick_dl
		li $t0, 1
		b new_dir_epi
		brick_ur:
			li $t0, 4
			b new_dir_epi
		brick_ul:
			li $t0, 3
			b new_dir_epi
		brick_dl:
			li $t0, 2
	new_dir_epi:
		addi $v0, $t0, 0
		jr $ra
# ball_mover() -> void
#	moves the ball in the direction stored in the ball

ball_mover:
	#PROLOGUE - SAVE RA in STACK
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#BODY
    	lw $a0, BALL 		#function parameter - ball's x-value
    	lw $a1, BALL + 4 	#function parameter - ball's y-value
    	jal get_location_address
    	lw $t0, MY_COLOURS + 40
    	sw $t0, ($v0)		#store black in the ball's former location	
       	jal next_ball_loc
    	addi $a0, $v0, 0
    	addi $a1, $v1, 0
    	sw $a0, BALL		#store ball's updated position
    	sw $a1, BALL + 4
    	
    	jal get_location_address
    	lw $t1, MY_COLOURS + 32	
    	sw $t1, ($v0)		#store white in the ball's new location
    	
    	#EPILOGUE - LOAD RA from STACK
    	lw $ra, 0($sp)
    	addi $sp,$sp, 4
    	jr $ra

# pad_left() -> void
# 	moves the paddle left by one unit
pad_left:	

	#PROLOGUE - SAVE RA in STACK
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#BODY
	lw $t0, MY_COLOURS + 40
	lw $t1, MY_COLOURS + 36
    	lw $a0, PADDLE 		#function parameter - paddle's x-value
    	lw $a1, PADDLE + 4 	#function parameter - paddle's y-value
    	addi $t2, $a0, -1
    	ble $t2, 0, pad_left_epi
    	sw $t2, PADDLE		#store x - 1 in paddle's x-value
    	jal get_location_address
    	sw $t1, -4($v0)		#store gray in the new left-est pixel
    	sw $t0, 16($v0)		#store black in the former right-est pixel
    	
    	#EPILOGUE - LOAD RA from STACK
    	pad_left_epi:
    	lw $ra, 0($sp)
    	addi $sp,$sp, 4
    	jr $ra

# pad_right() -> void
# 	moves the paddle right by one unit

pad_right:	

	#PROLOGUE - SAVE RA in STACK
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#BODY

    	lw $a0, PADDLE 		#function parameter - paddle's x-value
    	lw $a1, PADDLE + 4	#function parameter - paddle's y-value
    	addi $t2, $a0, 6
    	bge $t2, 32, pad_right_epi
    	addi $t2, $a0, 1
    	sw $t2, PADDLE		#store x + 1 in paddle's x-value
    	jal get_location_address	
    	lw $t0, MY_COLOURS + 40
	lw $t1, MY_COLOURS + 36
    	sw $t0, ($v0)		#store black in the former left-est pixel
    	sw $t1, 20($v0)		#store gray in the new right-est pixel
    	
    	#EPILOGUE - LOAD RA from STACK
    	pad_right_epi:
    	lw $ra, 0($sp)
    	addi $sp,$sp, 4
    	jr $ra

# clear_screen()-> void
#	store black in all pixels (clean the screen)
clear_screen:
	#load top-left pixel, the colour black, and set loop variable to 0
	la $t0, ADDR_DSPL
	lw $t0, 0($t0)
	li $t1, 0
	lw $t2, MY_COLOURS + 40
	
	#store black in address, add to address by 4, increment loop variable until all pixels are black
	clean_loop: 
	beq $t1, 1024, clear_screen_epi
	sw $t2, ($t0)
	addi $t0, $t0, 4
	addi $t1, $t1, 1
	b clean_loop
	
	clear_screen_epi:
	jr $ra

game_over_screen:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal draw_score
	li $a0, 6
	li $a1, 2
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 4($v0)
	sw $t0, 8($v0)		
	sw $t0, 12($v0)	
	sw $t0, 20($v0)
	sw $t0, 24($v0)
	sw $t0, 28($v0)
	sw $t0, 32($v0)
	sw $t0, 40($v0)
	sw $t0, 56($v0)
	sw $t0, 64($v0)
	sw $t0, 68($v0)
	sw $t0, 72($v0)
	sw $t0, 76($v0)
	sw $t0, 128($v0)
	sw $t0, 148($v0)
	sw $t0, 160($v0)
	sw $t0, 168($v0)
	sw $t0, 172($v0)
	sw $t0, 180($v0)
	sw $t0, 184($v0)		
	sw $t0, 192($v0)
	sw $t0, 256($v0)
	sw $t0, 264($v0)
	sw $t0, 268($v0)
	sw $t0, 276($v0)
	sw $t0, 280($v0)
	sw $t0, 284($v0)
	sw $t0, 288($v0)
	sw $t0, 296($v0)
	sw $t0, 304($v0)
	sw $t0, 312($v0)
	sw $t0, 320($v0)
	sw $t0, 324($v0)
	sw $t0, 328($v0)
	sw $t0, 384($v0)
	sw $t0, 396($v0)
	sw $t0, 404($v0)
	sw $t0, 416($v0)
	sw $t0, 424($v0)	
	sw $t0, 440($v0)
	sw $t0, 448($v0)
	sw $t0, 512($v0)
	sw $t0, 516($v0)
	sw $t0, 520($v0)
	sw $t0, 524($v0)
	sw $t0, 532($v0)
	sw $t0, 544($v0)
	sw $t0, 552($v0)
	sw $t0, 568($v0)
	sw $t0, 576($v0)	
	sw $t0, 580($v0)
	sw $t0, 584($v0)
	sw $t0, 588($v0)
	sw $t0, 768($v0)
	sw $t0, 772($v0)
	sw $t0, 776($v0)
	sw $t0, 780($v0)
	sw $t0, 788($v0)
	sw $t0, 804($v0)
	sw $t0, 812($v0)
	sw $t0, 816($v0)	
	sw $t0, 820($v0)
	sw $t0, 824($v0)
	sw $t0, 832($v0)
	sw $t0, 836($v0)
	sw $t0, 840($v0)
	sw $t0, 844($v0)
	sw $t0, 896($v0)
	sw $t0, 908($v0)
	sw $t0, 916($v0)
	sw $t0, 932($v0)
	sw $t0, 940($v0)	
	sw $t0, 960($v0)
	sw $t0, 972($v0)
	sw $t0, 1024($v0)
	sw $t0, 1036($v0)
	sw $t0, 1044($v0)
	sw $t0, 1048($v0)
	sw $t0, 1056($v0)
	sw $t0, 1060($v0)
	sw $t0, 1068($v0)
	sw $t0, 1072($v0)	
	sw $t0, 1076($v0)
	sw $t0, 1088($v0)
	sw $t0, 1092($v0)
	sw $t0, 1096($v0)
	sw $t0, 1100($v0)
	sw $t0, 1152($v0)
	sw $t0, 1164($v0)
	sw $t0, 1176($v0)
	sw $t0, 1180($v0)
	sw $t0, 1184($v0)
	sw $t0, 1196($v0)	
	sw $t0, 1216($v0)
	sw $t0, 1224($v0)
	sw $t0, 1280($v0)
	sw $t0, 1284($v0)
	sw $t0, 1288($v0)
	sw $t0, 1292($v0)
	sw $t0, 1308($v0)
	sw $t0, 1324($v0)
	sw $t0, 1328($v0)
	sw $t0, 1332($v0)
	sw $t0, 1336($v0)	
	sw $t0, 1344($v0)
	sw $t0, 1356($v0)
	
	li $a0, 6
	li $a1, 18
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, 0($v0)
	sw $t0, 8($v0)
	sw $t0, 16($v0)
	sw $t0, 128($v0)
	sw $t0, 136($v0)
	sw $t0, 144($v0)
	sw $t0, 152($v0)
	sw $t0, 256($v0)
	sw $t0, 260($v0)
	sw $t0, 264($v0)
	sw $t0, 272($v0)
	sw $t0, 384($v0)
	sw $t0, 392($v0)
	sw $t0, 400($v0)
	sw $t0, 408($v0)
	sw $t0, 512($v0)
	sw $t0, 520($v0)
	sw $t0, 528($v0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

terminate:
	jal clear_screen
	jal game_over_screen
	
	retry_loop:
		lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
  		lw $t1, 0($t0)                  # Load first word from keyboard
    		beq $t1, 1, post_game_input     
		b retry_loop
	post_game_input:
		lw $t1, 4($t0)
		beq $t1, 0x52, main
		beq $t1, 0x72, main
		beq $t1, 0x51, quit
		beq $t1, 0x71, quit 
	quit:
	li $v0, 10 # terminate the program gracefully 
	syscall


draw_score:
	addi $sp, $sp, -12
	sw $s1, 8($sp)
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	
	bge $s7, $s6, new_high
	b high_else
	new_high:
	addi $s6, $s7, 0
	high_else:
	
	draw_hundreds:
		li $t0, 100
		div $s7, $t0
		mflo $a2
		mfhi $s1
		li $a0, 12
		li $a1, 24
		jal number_assigner
		li $t0, 100
		div $s6, $t0
		mflo $a2
		mfhi $s0
		li $a0, 14
		li $a1, 18
		jal number_assigner
	draw_tens:
		li $t0, 10
		div $s1, $t0
		mflo $a2
		mfhi $s1
		li $a0, 16
		li $a1, 24
		jal number_assigner
		li $t0, 10
		div $s0, $t0
		mflo $a2
		mfhi $s0
		li $a0, 18
		li $a1, 18
		jal number_assigner
	draw_ones:
		li $t0, 1
		div $s1, $t0
		mflo $a2
		li $a0, 20
		li $a1, 24
		jal number_assigner
		li $t0, 1
		div $s0, $t0
		mflo $a2
		li $a0, 22
		li $a1, 18
		jal number_assigner
	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

number_assigner:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	beq $a2, 1, one
	beq $a2, 2, two
	beq $a2, 3, three
	beq $a2, 4, four
	beq $a2, 5, five
	beq $a2, 6, six
	beq $a2, 7, seven
	beq $a2, 8, eight
	beq $a2, 9, nine
	zero: jal draw_0
		b na_epi
	one: jal draw_1
		b na_epi
	two: jal draw_2
		b na_epi
	three: jal draw_3
		b na_epi
	four: jal draw_4
		b na_epi
	five: jal draw_5
		b na_epi
	six: jal draw_6
		b na_epi
	seven: jal draw_7
		b na_epi
	eight: jal draw_8
		b na_epi
	nine: jal draw_9
		b na_epi
	
	na_epi:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#draw_0(x,y) -> void
# draws a 0, starting from the top right position
draw_0:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 4($v0)
	sw $t0, 8($v0)
	sw $t0, 128($v0)
	sw $t0, 136($v0)
	sw $t0, 256($v0)	
	sw $t0, 264($v0)
	sw $t0, 384($v0)
	sw $t0, 392($v0)	
	sw $t0, 512($v0)
	sw $t0, 516($v0)
	sw $t0, 520($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#draw_1(x,y) -> void
# draws a 1, starting from the top right position
draw_1:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, 4($v0)
	sw $t0, 132($v0)
	sw $t0, 260($v0)	
	sw $t0, 388($v0)
	sw $t0, 516($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#draw_2(x,y) -> void
# draws a 2, starting from the top right position
draw_2:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 4($v0)
	sw $t0, 8($v0)
	sw $t0, 136($v0)
	sw $t0, 256($v0)
	sw $t0, 260($v0)	
	sw $t0, 264($v0)
	sw $t0, 384($v0)
	sw $t0, 512($v0)
	sw $t0, 516($v0)
	sw $t0, 520($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#draw_3(x,y) -> void
# draws a 3, starting from the top right position
draw_3:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 4($v0)
	sw $t0, 8($v0)
	sw $t0, 136($v0)
	sw $t0, 260($v0)	
	sw $t0, 264($v0)
	sw $t0, 392($v0)	
	sw $t0, 512($v0)
	sw $t0, 516($v0)
	sw $t0, 520($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#draw_4(x,y) -> void
# draws a 4, starting from the top right position
draw_4:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 8($v0)
	sw $t0, 128($v0)
	sw $t0, 136($v0)
	sw $t0, 256($v0)
	sw $t0, 260($v0)		
	sw $t0, 264($v0)
	sw $t0, 392($v0)	
	sw $t0, 520($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#draw_5(x,y) -> void
# draws a 5, starting from the top right position
draw_5:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 4($v0)
	sw $t0, 8($v0)
	sw $t0, 128($v0)
	sw $t0, 256($v0)	
	sw $t0, 260($v0)	
	sw $t0, 264($v0)
	sw $t0, 392($v0)	
	sw $t0, 512($v0)
	sw $t0, 516($v0)
	sw $t0, 520($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	#draw_6(x,y) -> void
# draws a 6, starting from the top right position
draw_6:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 4($v0)
	sw $t0, 8($v0)
	sw $t0, 128($v0)
	sw $t0, 256($v0)
	sw $t0, 260($v0)	
	sw $t0, 264($v0)
	sw $t0, 384($v0)
	sw $t0, 392($v0)	
	sw $t0, 512($v0)
	sw $t0, 516($v0)
	sw $t0, 520($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#draw_7(x,y) -> void
# draws a 7, starting from the top right position
draw_7:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 4($v0)
	sw $t0, 8($v0)
	sw $t0, 136($v0)
	sw $t0, 260($v0)	
	sw $t0, 384($v0)	
	sw $t0, 512($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#draw_8(x,y) -> void
# draws a 8, starting from the top right position
draw_8:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 4($v0)
	sw $t0, 8($v0)
	sw $t0, 128($v0)
	sw $t0, 136($v0)
	sw $t0, 256($v0)
	sw $t0, 260($v0)		
	sw $t0, 264($v0)
	sw $t0, 384($v0)
	sw $t0, 392($v0)	
	sw $t0, 512($v0)
	sw $t0, 516($v0)
	sw $t0, 520($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#draw_9(x,y) -> void
# draws a 9, starting from the top right position
draw_9:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_location_address
	lw $t0, MY_COLOURS + 32
	sw $t0, ($v0)
	sw $t0, 4($v0)
	sw $t0, 8($v0)
	sw $t0, 128($v0)
	sw $t0, 136($v0)
	sw $t0, 256($v0)
	sw $t0, 260($v0)		
	sw $t0, 264($v0)
	sw $t0, 392($v0)	
	sw $t0, 512($v0)
	sw $t0, 516($v0)
	sw $t0, 520($v0)		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
