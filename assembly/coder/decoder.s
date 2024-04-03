/* 
 * decoder.s 
 * Written by Kenton Groombridge
 * assemble and link with: gcc -z noexestack coder.s -o coder
 *
 */

.intel_syntax noprefix

.set ARGV, 8
.set XOR_VAL, 16
.set FD_INFILE, 24
.set FD_OUTFILE, 32
.set BUFFER, 40
.set ERROR_CODE, 48

#.set NOSTARTFILES, 1 # Comment when using gcc with startup files

.section .text

.global main

main:
    enter 48, 0

    mov [rbp - ARGV], rsi                # save *argv[], rbp - 8
 
    mov rcx, rdi			# rdi contains argc when link with gcc with start file
    cmp rcx, 4 

    jnz NUM_ARGS_BAD        # if numbers of args is not 4, then display usage message and get out

    # Get argv[1]
    mov rdi, [rbp - ARGV]           # retrieve *argv[]

    mov rdi, [rdi + 8]              # argv[1]

# The following two instructions do the same thing as the previous instruction. The previous instruction is PIE
# compatible because the instruction it uses a register to access memory rather than an abosolute address.
# "lea" doesn't reference the memory location, it is just an address calculator. Intel used the [] on it, 
# and made it a bit confusing.
#   lea rdi, [rdi + 8]			    # ROT_VAL
#   mov rdi, QWORD PTR [rdi]        # argv[1]

    call stringtohex

    test rax, rax               #  if rax is -1 then atoi failed

    js HEX_INVALID

    cmp eax, 0x00               # Make sure out value is one byte
    jb HEX_INVALID

    cmp eax, 0xff
    ja HEX_INVALID

    mov [rbp - XOR_VAL], al             # save XOR_val to the stack            


    # Attempt to open <infile>
    mov rdi, [rbp - ARGV]           # Retrieve *argv[]

    lea rdi, [rdi + 16]			    # <infile> name
    mov rdi, QWORD PTR [rdi]        # argv[2]

    mov rax, 0x2                # open syscall
    xor rsi, rsi                # flags in rsi are 0 rsi for O_RDONLY 
    xor rdx, rdx                # mode in rdi is 0 since not creating a file
    syscall

    test rax, rax               # Set flags from open syscall
    js ERROR_INFILE_OPEN        # Error opening <infile>

    mov [rbp - FD_INFILE], rax  # save <infile> fd to stack

    # Attempt to open <outfile>
    mov rdi, [rbp - ARGV]       # retrieve *argv[]

    lea rdi, [rdi + 24]			    # <outfile> name
    mov rdi, QWORD PTR [rdi]        # argv[3]

    mov rax, 0x2                # open syscall
    mov rsi, 0x41               # flags in rsi are 1 rsi for O_WRONLY(0x1)|O_CREAT(0x40) 
    mov rdx, 0x1a4              # mode in rdi is 644 octal converted to hex
    syscall

    test rax, rax               # Set flags from open syscall
    js ERROR_OUTFILE_OPEN        # Error opening <infile>

    mov [rbp - FD_OUTFILE], rax  # save <outfile> fd to stack

    xor ecx, ecx                # Use c reg for our counter for mod4

# If we are here then everything so far is copasetic, time to do some rot.
DECODER_LOOP:
    push rcx                    # rcx is caller saved and the read syscall will mess it up
    xor rax, rax                # 0 in rax means read syscall
    lea rsi, [rbp - BUFFER]
    mov rdx, 1
    mov rdi, [rbp - FD_INFILE]
    syscall
    pop rcx

    test rax, rax
    jle CLOSE_OUTFILE

    mov al, [rbp - BUFFER]      # put the read character into a

    xor al, [rbp - XOR_VAL]     # xor decode with byte provided on the command line

    ror al, cl                  # rotate right shift base on mod4 value in cl

    mov [rbp - BUFFER], al      # save to the buffer to get ready to write to outfile
    
# Write to outfile
WRITE:    
    push rcx                    # rcx is caller saved and the read syscall will mess it up
    mov rax, 0x1    # write syscall
    mov rdx, rax    # write one character, easy to copy from rax
    lea rsi, [rbp - BUFFER]
    mov rdi, [rbp - FD_OUTFILE]
    syscall
    pop rcx
    
    inc ecx         # ecx is our register used for mod4
    cmp ecx, 4      # check to see if ecx is up to 4 so we can 0 it again mod4
    jne DECODER_LOOP

    xor ecx, ecx    # if ecx is 4, zero it out

    jmp DECODER_LOOP


# Display error message that we couldn't open outfile.
ERROR_OUTFILE_OPEN:
    mov rax, 1			# write
    mov rdi, rax		# stdout is also 1 copied from rax
    lea rsi, ARG3INVALID[rip]
    mov rdx, OFFSET ARG3INVALID_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR [rbp - ERROR_CODE], 2	# error code
    jmp CLOSE_INFILE

# Display error message that we couldn't open infile.
ERROR_INFILE_OPEN:
    mov rax, 1			# write
    mov rdi, rax		# stdout is also 1 copied from rax
    lea rsi, ARG2INVALID[rip]
    mov rdx, OFFSET ARG2INVALID_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR [rbp - ERROR_CODE], 2	# error code
    jmp EXIT

# Display message that our input XOR_val is not correct
HEX_INVALID:  
    mov rax, 1			# write
    mov rdi, rax		# stdout is also 1
    lea rsi, ARG1INVALID[rip]
    mov rdx, OFFSET ARG1INVALID_LEN		# write
    syscall

    mov QWORD PTR [rbp - ERROR_CODE], 2	# error code
    jmp EXIT

# Number of arguments is not the expected 4
NUM_ARGS_BAD:
    mov rax, 1          # write
    mov rdi, rax		# stdout is 1 copied from rax
    lea rsi, USAGE[rip]
    mov rdx, OFFSET USAGE_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR [rbp - ERROR_CODE], 255	# error code
    jmp EXIT

# IF all worked, need to close outfile and then infile
CLOSE_OUTFILE:
    mov rax, 0x3        # close
    mov rdi, [rbp - FD_INFILE]
    syscall

# Only need to close infile, if outfile failed to open
CLOSE_INFILE:
    mov rax, 0x3        # close
    mov rdi, [rbp - FD_OUTFILE]
    syscall

EXIT:
    mov eax, 60       # exit syscall
    mov rdi, [rbp - ERROR_CODE]       # error message in a Linux shell means all worked well
    #neg rdi             # two's compliment the negative number to obtain the error code

    leave               # May seam out of place, but need to put here so ERROR code above can be resolved on the stack
                        # also some systems enter main without a valid rbp
    syscall             # execute exit syscall


# stringtohex subroutine 
# input string pointer passed in rdi
# returns result in rax
stringtohex:  
    xor rax, rax              # Set initial total to 0

convert_stringtohex:
    movzx rsi, BYTE PTR [rdi]   # Get the current character
    test rsi, rsi           # Check for \0
    je done_stringtohex
    
    # check for 0 - 9
    cmp rsi, 0x30           # Anything less than 0 is invalid
    jl error_stringtohex

    cmp rsi, 0x39           # Anything greater than 9 is invalid
    jle is_num

    # check for A - F
    cmp rsi, 0x41           # Is it an uppercase A
    jl error_stringtohex

    cmp rsi, 0x46           # Is it an uppercase F
    jle is_upper

    # check for a - f
    cmp rsi, 0x61           # Is it an lowercase a
    jl error_stringtohex

    cmp rsi, 0x66           # Is it an lowercase f
    jg error_stringtohex

    sub rsi, 0x20

is_upper:
    sub rsi, 0x7    

is_num:
    sub rsi, 0x30           # Convert from ASCII number to hex number

    imul rax, 0x10          # Multiply total by 16
    add rax, rsi            # Add current digit to total

    inc rdi                 # Advance the pointer to the next character
    jmp convert_stringtohex # Do it again until we run into a NULL

error_stringtohex:
    mov rax, -1             # Return -1 on error, need to find another way as a string ffffffffffffffff is determined to be signed when it is a valid unsigned value

done_stringtohex:
    ret                     # Return total or error code 

.section .rodata

   USAGE: .ascii "Usage: coder <xor byte> <infile> <outfile>\n"
   .set USAGE_LEN, . - USAGE

   ARG1INVALID: .ascii "Argument must be hexidecimal numbers in the format XX (example f4).\n"
   .set ARG1INVALID_LEN, . - ARG1INVALID

   ARG2INVALID: .ascii "Unable to open <infile> for reading.\n"
   .set ARG2INVALID_LEN, . - ARG2INVALID

   ARG3INVALID: .ascii "Unable to open <outfile> for writing.\n"
   .set ARG3INVALID_LEN, . - ARG3INVALID

