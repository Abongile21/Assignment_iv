.data
input_filename: .asciiz "input.ppm"  # Input image file
output_filename: .asciiz "output.ppm"  # Output image file
Read_in: .space 100000  # Buffer for reading input data
Write_OUT: .space 100000  # Buffer for writing output data

.text
.globl main

main:
    # Open the input image file for reading
    li $v0, 13
    la $a0, input_filename
    li $a1, 0
    li $a2, 0
    syscall
    move $s0, $v0  # Store the file descriptor in $s0

    # Open the output image file for writing
    li $v0, 13
    la $a0, output_filename
    li $a1, 1
    li $a2, 0
    syscall
    move $s1, $v0  # Store the file descriptor in $s1

INPUT:
    # Read data from the input file into Read_in buffer
    li $v0, 14
    move $a0, $s0
    la $a1, Read_in
    li $a2, 100000
    syscall

    la $s2, Read_in  # Initialize a pointer to the input buffer
    la $s3, Write_OUT  # Initialize a pointer to the output buffer
    la $s4, Write_OUT  # Pointer to track the end of the output buffer
    li $t1, 1

    li $t2, 80
    sb $t2, ($s3)  # Store a value in the output buffer
    addi $s2, $s2, 1
    addi $s3, $s3, 1
    li $t2, 50
    sb $t2, ($s3)
    addi $s2, $s2, 1
    addi $s3, $s3, 1

    li $t2, 10
    sb $t2, ($s3)
    addi $s2, $s2, 1
    addi $s3, $s3, 1

HEADER:
    lb $t2, ($s2)
    sb $t2, ($s3)
    addi $s3, $s3, 1
    addi $s2, $s2, 1

    beq $t2, 10, newline
    j HEADER

newline:
    addi $t1, $t1, 1
    beq $t1, 4, Pixel_read
    j HEADER

Pixel_read:
    li $t4, 0
    li $t1, 0
    li $t3, 0
    li $t5, 0
    li $t6, 0

String_to_int:
    lb $t2, ($s2)
    beq $t2, 10, Line
    beq $t2, 0, WRITE

    sub $t2, $t2, 48
    mul $t4, $t4, 10
    add $t4, $t4, $t2
    addi $s2, $s2, 1
    j String_to_int

Line:
    addi $s2, $s2, 1
    addi $t3, $t3, 1
    add $t5, $t5, $t4
    li $t4, 0

    beq $t3, 3, AVG
    j String_to_int

AVG:
    addi $t6, $t6, 1
    beq $t6, 4097, WRITE

    divu $t5, $t5, 3
    mflo $t4

    blt $t4, 100, ADD1
    addi $s3, $s3, 3
    li $t8, 10
    sb $t8, ($s3)
    j INT_STRING

ADD1:
    blt $t4, 10, nADD
    addi $s3, $s3, 2
    li $t8, 10
    sb $t8, ($s3)
    j INT_STRING

nADD:
    addi $s3, $s3, 1
    li $t8, 10
    sb $t8, ($s3)
    j INT_STRING

INT_STRING:
    beqz $t4, end
    divu $t4, $t4, 10
    mfhi $t3
    addi $t3, $t3, 48
    sb $t3, -1($s3)
    addi $s3, $s3, -1
    addi $t1, $t1, 1
    j INT_STRING

end:
    add $s3, $s3, $t1
    addi $s3, $s3, 1
    li $t1, 0
    li $t3, 0
    li $t5, 0
    j String_to_int

WRITE:
    sb $t2, ($s3)  # Write data to the output buffer
    sub $s4, $s3, $s4  # Calculate the number of bytes to write

    # Write the output buffer to the output file
    li $v0, 15
    move $a0, $s1
    la $a1, Write_OUT
    move $a2, $s4
    syscall

close:
    # Close the input and output files
    li $v0, 16
    move $a0, $s0
    syscall

    li $v0, 16
    move $a0, $s1
    syscall

    li $v0, 10
    syscall

