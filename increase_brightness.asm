.data
inputFileName: .asciiz "input.ppm"
outputFileName: .asciiz "output.ppm"
textInputBuffer: .space 65000
outputImageBuffer: .space 65000
lineBuffer: .space 10
resultString: .space 20
newline: .asciiz "\n"
avgOriginalMessage: .asciiz "Average pixel value of the original image:\n"
avgModifiedMessage: .asciiz "Average pixel value of the new image:\n"

.text
.globl main

main:

# Read the input file
readInputFile:
    li $v0, 13              # Syscall code for open file (13)
    la $a0, inputFileName  # Load the input file name
    li $a1, 0               # File flag: read (0)
    syscall
    move $fileDescriptor, $v0  # Save the file descriptor

    li $v0, 14              # Syscall code for read file (14)
    move $a0, $fileDescriptor # File descriptor
    la $a1, textInputBuffer   # Buffer to store file content
    li $a2, 65000           # Number of bytes to read
    syscall

    li $v0, 16              # Syscall code for close file (16)
    move $a0, $fileDescriptor # File descriptor to close
    syscall

    move $inputBufferPointer, $a1 			 	# $inputBufferPointer is the pointer to the file content (textInputBuffer)
    la $outputBufferPointer, outputImageBuffer  		# $outputBufferPointer is the pointer to the output image buffer
    la $lineBufferPointer, lineBuffer   			# $lineBufferPointer is the pointer to the line buffer
    li $headerBytesCounter, 19 			 	# Counter for header bytes
    move $byteReadCounter, $zero  				# $byteReadCounter is the number of bytes read
    move $originalSum, $zero  				# $originalSum is used to accumulate the sum of original pixel values
    move $modifiedSum, $zero   				# $modifiedSum is used to accumulate the sum of modified pixel values

# Store the header bytes in the output image buffer
storeHeader:
    beq $byteReadCounter, 19, endStoreHeader
    lb $byteValue, 0($inputBufferPointer)            	# Load byte from file
    sb $byteValue, 0($outputBufferPointer)  			# Store byte in output image buffer (no editing needed)
    addi $inputBufferPointer, $inputBufferPointer, 1  	# Increment file pointer
    addi $outputBufferPointer, $outputBufferPointer, 1  	# Increment output image buffer pointer
    addi $byteReadCounter, $byteReadCounter, 1  		# Increment number of bytes read
    j storeHeader

endStoreHeader:

# Main loop to process pixel values
mainLoop:
    beq $lineCounter, 12288, endMainLoop              # Iterate over 12288 lines (first 4 lines = 12288 bytes)
    lb $byteValue, 0($inputBufferPointer)             # Load byte pointed at from file to $byteValue
    sb $byteValue, 0($lineBufferPointer)              # Store byte in $byteValue in line buffer (needs editing)
    addi $inputBufferPointer, $inputBufferPointer, 1  # Increment file pointer
    addi $byteReadCounter, $byteReadCounter, 1        # Increment number of bytes read
    addi $lineBufferPointer, $lineBufferPointer, 1    # Increment line buffer pointer
    beq $byteValue, 13, editPixel                     # When reached end of the line, edit the pixel (integer)
    j mainLoop

# Edit and process the pixel value
editPixel:
    addi $lineCounter, $lineCounter, 1 	 	# Increment number of lines
    la $lineBufferPointer, lineBuffer  		# Reset line buffer pointer

endStoreLineBuffer:
    li $carriageReturn, 13  # ASCII code for carriage return
    li $lineFeed, 10        # ASCII code for line feed
    li $zeroAscii, 48       # ASCII code for '0'
    la $lineBufferPointer, lineBuffer

# Convert ASCII to integer in line buffer
startStringToIntLoop:
    move $integerValue, $zero

stringToIntLoop:
    lb $currentChar, 0($lineBufferPointer)
    addi $lineBufferPointer, $lineBufferPointer, 1
    beq $currentChar, $carriageReturn, endStringToIntLoop
    sub $charValue, $currentChar, $zeroAscii
    mul $integerValue, $integerValue, 10
    add $integerValue, $integerValue, $charValue
    j stringToIntLoop

endStringToIntLoop:
    add $originalSum, $originalSum, $integerValue  		# Add the integer in $integerValue to $originalSum
    addi $integerValue, $integerValue, 10  			# Increment the brightness by 10
    bge $integerValue, 255, clampValue  			# If the value is >= 255, clamp it to 255
    j dontClampValue

clampValue:
    li $integerValue, 255  	# Set the value to 255 (clamp)

dontClampValue:
    add $modifiedSum, $modifiedSum, $integerValue  		# Add the modified pixel value to $modifiedSum
    la $resultStringPointer, resultString  			# Load the address of the result string
    li $base10, 10          					# Load 10 (base 10)
    sb $nullTerminator, ($resultStringPointer)  		# Null-terminate the string
    addi $resultStringPointer, $resultStringPointer, 10  	# Move to the end of the string

# Convert integer to ASCII and store in result string
convertIntToStringLoop:
    div $integerValue, $base10  				# Divide $integerValue (completed integer) by 10
    mflo $quotient           					# Quotient goes to $quotient
    mfhi $digit              					# Remainder (digit) goes to $digit
    addi $digit, $digit, 48  					# Convert to ASCII
    sb $digit, -1($resultStringPointer)  			# Store the digit in the string
    addi $resultStringPointer, $resultStringPointer, -1  	# Move to the next position in the string
    beqz $quotient, endConvertIntToString  			# Check if the quotient is zero (end of conversion)
    move $integerValue, $quotient
    j convertIntToStringLoop

endConvertIntToString:
    move $resultStringPointerEnd, $resultStringPointer

# Add the modified pixel value to the output image buffer
addToOutputImageBuffer:
    lb $integerValue, 0($resultStringPointerEnd)
    beqz $integerValue, endAddToOutputImageBuffer
    sb $integerValue, 0($outputBufferPointer)
    addi $outputBufferPointer, $outputBufferPointer, 1
    addi $resultStringPointerEnd, $resultStringPointerEnd, 1
    j addToOutputImageBuffer

endAddToOutputImageBuffer:
    lb $carriageReturn, newline  		# Load ASCII code for newline character
    sb $carriageReturn, 0($outputBufferPointer)
    addi $outputBufferPointer, $outputBufferPointer, 1
    addi $lineCounter, $lineCounter, 1
    la $lineBufferPointer, lineBuffer
    j mainLoop

endMainLoop:

# Write the modified image to the output file
writeOutputFile:
    li $v0, 13              # Syscall code for open file (13)
    la $a0, outputFileName  # Load the output file name
    li $a1, 1               # File flag: write (1)
    syscall
    move $outputFileDescriptor, $v0  		# Save the file descriptor

    li $v0, 15              			# Syscall code for write file (15)
    move $a0, $outputFileDescriptor  		# File descriptor
    la $a1, outputImageBuffer 	 	# The string to write
    move $a2, $outputBufferSize 	 	# Length of the string
    syscall

    li $v0, 16              		# Syscall code for close file (16)
    move $a0, $outputFileDescriptor  	# File descriptor to close
    syscall

# Calculate and print average pixel values
calculateAndPrintAverage:
    mtc1 $originalSum, $fOriginalSum
    mtc1 $modifiedSum, $fModifiedSum
    mtc1 $lineCounter, $fLineCounter

    div.s $fAverageOriginal, $fOriginalSum, $fLineCounter
    div.s $fAverageModified, $fModifiedSum, $fLineCounter

    li $v0, 4
    la $a0, avgOriginalMessage
    syscall

    li $v0, 2
    mov.s $f12, $fAverageOriginal  # Load the result into $f12 for printing
    syscall

    la $a0, newline
    li $v0, 4
    syscall

    li $v0, 4
    la $a0, avgModifiedMessage
    syscall

    li $v0, 2
    mov.s $f12, $fAverageModified  # Load the result into $f12 for printing
    syscall

    li $v0, 10
    syscall

