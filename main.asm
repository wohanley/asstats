# Assignment 3, part 1: Some statistics crap
#
# Registers used:
#	$t1: current item being processed in a loop
#	$t2: address of current item
#
# Created: November 29, 2011
# Last modified: December 4, 2011


	.data

newline: .asciiz "\n" # define newline character
space: .asciiz " " # define space character
fracbar: .asciiz "/" # define fraction bar
prog_title: .asciiz "Statistical Analysis:\n=====================\n" # program printed title
mean_txt: .asciiz "Mean: " # string introducing the mean
median_txt: .asciiz "Median: " # string introducing the median
mode_txt: .asciiz "Mode: " # string introducing the mode

sum: .word 0 # the sum of the dataset
count: .word 0 # the number of elements in the dataset
mean_whole: .word 0 # the arithmetic mean of the dataset, whole number portion
mean_frac: .word 0 # the arithmetic mean of the dataset, modulus portion
median: .word 0 # the median of the dataset
mode: .word 0 # the mode of the dataset
freq: .space 120 # space for a 120-byte (30-word) frequency array (word = 32 bits)
				 # freq[1]-freq[30]
dataset: .word 14,4,29,17,20,24,6,19,21,15,27,20,16,27,20,23 # begin data array
			.word 22,12,17,22,20,3,10,28,15,7,7,11,27,20,15,24
			.word 7,16,7,5,24,21,10,26,1,19,16,6,30,30,12,9
			.word 9,22,5,18,1,23,26,23,18,2,12,7,23,6,5,27
			.word 12,1,19,24,30,22,14,10,4,6,17,28,25,21,2,5
			.word 13,9,19,29,2,3,26,12,18,8,28,6,23,30,5,1
			.word 27,25,30,4,25,30,6,18,23,26,25,4,4,3,2,23
			.word 23,29,27,10,21,28,27,1,9,5,20,1,7,24,7,27
			.word 28,21,30,20,6,23,26,27,18,20,25,29,24,27,17,1
			.word 20,29,23,1,19,29,21,15,9,27,15,26,16,29,30,24
			.word 21,19,24,15,13,10,30,10,11,26,19,14,9,4,23,26
			.word 28,26,13,12,1,15,18,3,25,8,8,6,3,28,28,26
			.word 20,8,12,9,17,12,26,16,28,7,30,17,4,29,22,6
			.word 11,14,23,19,19,21,3,19,9,26,22,9,24,24,17,24
			.word 10,14,24,7,15,24,16,24,18,19,27,22,10,12,12 
			.word -1 # sentinel value


    .text

main:
	# Print the program title
    la      $a0, prog_title
	li		$v0, 4
	syscall

# First run through data: get count, cumulative sum, and frequency counts. Count
# can then be used for sorting, and with sum to get the mean.
# Registers used:
# 	$t3: count of items
#	$t4: cumulative sum
#	$t5: address of element to increment in frequency array
	la		$t2, dataset # first index is address of dataset
	li		$t3, 0 # set count to 0
	li		$t4, 0 # set sum to 0
prelim:
	lw		$t1, ($t2) # load next item
	beq		$t1, -1, end_prelim # exit loop if sentinel encountered
	add		$t2, $t2, 4 # increment index
	addi		$t3, 1 # increment count
	add		$t4, $t4, $t1 # keep running sum
	# Now increment the proper entry in the frequency array.
	mul		$t1, $t1, 4 # Multiply the value of the current element by four.
						# This register will be reused at the top of the loop.
	lw		$t5, freq($t1) # load the element of freq to be incremented
	addi		$t5, 1 # increment frequency counter
	sw		$t5, freq($t1) # store new frequency count
	j		prelim
end_prelim:
	sw		$t3, count # store count
	sw		$t4, sum # store sum	

# Get the mode, using the frequency counts from prelim
# Registers used:
#	$t3: address of current largest number found in freq
#	$t4: value of current largest frequency
#	$t5: mode, during calculations
#	$t6: base address of freq
#	$t7: current address - freq. When this reaches 120, we exit the loop.
#	$t0: 120
get_mode:
	la		$t2, freq # load address of the start of the frequency array
	la		$t3, freq # load address of the first word in freq, assumed to be the
				   # largest until proven otherwise
	lw		$t4, freq # load word at the start
	la		$t6, freq # load address of freq
	li		$t0, 120
search_largest:
	sub		$t7, $t2, $t6
	bge		$t7, $t0, finish_mode
	lw		$t1, ($t2) # load next item
	add		$t2, $t2, 4 # increment index
	ble		$t1, $t4, continue_search # if $t1 > $t4, $t1 is loaded into $t4
	move		$t4, $t1 # move the new largest frequency into $t4
	move		$t3, $t2 # Load the address of the largest frequency into $t3.
					 # Later, ($t3 - freq)/4 will give us the mode.
continue_search:
	j		search_largest
finish_mode: # at this point, $t3 contains the address of freq's largest element
	sub		$t3, $t3, $t6
	div		$t5, $t3, 4
	sub		$t5, $t5, 1 # the value here is actually an index, i.e. $t5 = 25
						# means mode = 24
	sw		$t5, mode
	# Print results
	li		$v0, 4
	la      $a0, mode_txt
	syscall
	li		$v0, 1
	lw		$a0, mode
	syscall
	li		$v0, 4
	la		$a0, newline
	syscall

# Calculate the mean using the sum and count values from prelim
# Registers used:
#	$t3: sum
#	$t4: count
#	$t5: integer portion of mean
#	$t6: numerator of fractional portion of mean
get_mean:
	lw		$t3, sum
	lw		$t4, count
	div		$t3, $t4
	mfhi		$t6
	mflo		$t5
	# Print results
	li		$v0, 4
	la      $a0, mean_txt
	syscall
	li		$v0, 1
	move		$a0, $t5
	syscall
	li		$v0, 4
	la      $a0, space
	syscall
	li		$v0, 1
	move		$a0, $t6
	syscall
	li		$v0, 4
	la      $a0, fracbar
	syscall
	li		$v0, 1
	lw		$a0, count
	syscall
	li		$v0, 4
	la		$a0, newline
	syscall

# Sort the data, so that the median can be found. (Algorithm: insertion sort)
# Registers used:
#	$t0 = address of end of list (in terms of offset from dataset)
#	$t1 = address of beginning of unsorted portion (in terms of offset from dataset)
#	$t2 = counter for inner loop
#	$t3 = value to insert once a place is found
#	$t4 = address of value being worked with
#	$t5 = value currently being checked
sort:	
	lw		$t0, count # load count so we know when to stop the loop
	addi		$t0, $t0, -1 # this and
	mul		$t0, $t0, 4 # this get count in terms of offset from dataset
	li		$t1, 4 # the "unsorted" portion starts at dataset[1]
outer_loop:
	bgt		$t1, $t0, get_median # done when beginning of unsorted portion is end of list
	addi		$t2, $t1, -4 # inner loop counter starts at end of sorted portion
	la		$t4, dataset($t1) # value to insert is the first in the unsorted portion
	lw		$t3, ($t4)
inner_loop:
	blt	$t2, 0, break_inner_loop # done when the beginning of the list is reached
	la	$t4, dataset($t2)
	lw	$t5, ($t4) # check next value
	ble	$t5, $t3, break_inner_loop # continue search if the current value <= value to insert
	sw	$t5, 4($t4)
	addi	$t2, $t2, -4
	j 	inner_loop
break_inner_loop:
	la	$t4, dataset($t2)
	sw	$t3, 4($t4)
	addi	$t1, $t1, 4
	j 	outer_loop

# Find the median, simply dataset[count/2] now that the list is sorted.
# Registers used:
#	$t0: count
#	$t1: index of median
#	$t2: median
get_median:
	lw		$t0, count
	addi		$t0, $t0, -1 # this and
	mul		$t0, $t0, 4 # this get count in terms of offset from dataset
	div		$t1, $t0, 2
	lw		$t2, dataset($t1)
	# Print results
	li		$v0, 4
	la      $a0, median_txt
	syscall
	li		$v0, 1
	move		$a0, $t2
	syscall
	
end:
    # end program
    li      $v0, 10
    syscall
