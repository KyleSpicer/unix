/* 
 * coder.s 
 * Written by Kenton Groombridge
 * assemble and link with: gcc -z noexestack coder.s -o coder
 *
 */

.intel_syntax noprefix

.set ARGV,           8
.set XOR_VAL,       16
.set FD_INFILE,     24
.set FD_OUTFILE,    32
.set BUFFER,        40
.set ERROR_CODE,    48

.section .text
    COUNTER=rcx                 # symbolic link for rcx
    ACCUMULATOR=rax             # symbolic link for rax 
    STACK_BASE=rbp              # symbolic link for stack base pointer

.global main

main:
    enter 48, 0

    mov [STACK_BASE - ARGV], rsi                # save *argv[], STACK_BASE - 8
 
    mov COUNTER, rdi			                # rdi contains argc
    cmp COUNTER, 4 

    jnz NUM_ARGS_BAD        # if num args not 4, display usage msg & get out

    mov rdi, [STACK_BASE - ARGV]                # retrieve *argv[]

    mov rdi, [rdi + 8]                          # argv[1]

# The following two instructions do the same thing as the previous instruction. The previous instruction is PIE
# compatible because the instruction it uses a register to access memory rather than an abosolute address.
# "lea" doesn't reference the memory location, it is just an address calculator. Intel used the [] on it, 
# and made it a bit confusing.
#   lea rdi, [rdi + 8]			    # ROT_VAL
#   mov rdi, QWORD PTR [rdi]        # argv[1]

    call stringtohex

    test ACCUMULATOR, ACCUMULATOR        #  if ACCUMULATOR is -1, atoi failed

    js HEX_INVALID

    cmp ACCUMULATOR, 0x00                # Make sure out value is one byte
    jl HEX_INVALID

    cmp ACCUMULATOR, 0xff                # jump if greater than 255
    jg HEX_INVALID

    mov [STACK_BASE - XOR_VAL], al       # save XOR_val to the stack

# Attempt to open <infile>
    mov rdi, [STACK_BASE - ARGV]         # Retrieve *argv[]

    lea rdi, [rdi + 16]			         # <infile> name
    mov rdi, QWORD PTR [rdi]             # argv[2]

    mov ACCUMULATOR, 0x2                 # open syscall
    xor rsi, rsi                # flags in rsi are 0 rsi for O_RDONLY 
    xor rdx, rdx                # mode in rdi is 0 since not creating a file
    syscall

    test ACCUMULATOR, ACCUMULATOR        # Set flags from open syscall
    js ERROR_INFILE_OPEN                 # Error opening <infile>

    mov [STACK_BASE - FD_INFILE], ACCUMULATOR     # save <infile> fd to stack

# Attempt to open <outfile>
    mov rdi, [STACK_BASE - ARGV]        # retrieve *argv[]

    lea rdi, [rdi + 24]			        # <outfile> name
    mov rdi, QWORD PTR [rdi]            # argv[3]

    mov ACCUMULATOR, 0x2                # open syscall
    mov rsi, 0x41         # flags in rsi are 1 for O_WRONLY(0x1)|O_CREAT(0x40) 
    mov rdx, 0x1a4        # mode in rdi is 644 octal converted to hex
    syscall

    test ACCUMULATOR, ACCUMULATOR                # Set flags from open syscall
    js ERROR_OUTFILE_OPEN                        # Error opening <infile>

    mov [STACK_BASE - FD_OUTFILE], ACCUMULATOR    # save <outfile> fd to stack

    xor ecx, ecx                     # Use c register for our COUNTER for mod4

CODER_LOOP:
# If we are here then everything so far is copasetic, time to rotate.
# prepare for read syscall
    push COUNTER           # COUNTER is caller saved, read syscall mess it up
    xor ACCUMULATOR, ACCUMULATOR         # 0 in ACCUMULATOR means read syscall
    lea rsi, [STACK_BASE - BUFFER]
    mov rdx, 1
    mov rdi, [STACK_BASE - FD_INFILE]
    syscall
    pop COUNTER

    test ACCUMULATOR, ACCUMULATOR
    jle CLOSE_OUTFILE

    mov al, [STACK_BASE - BUFFER]     # put the read character into al
    rol al, cl                        # rotation shift left based on 0-3 in cl

    xor al, [STACK_BASE - XOR_VAL]    # xor encode with value on command line

    mov [STACK_BASE - BUFFER], al     # save to buffer to write to outfile
    
WRITE:    
# Write out to the outfile and keep going
    push COUNTER            # COUNTER is caller saved, read syscall mess it up
    mov ACCUMULATOR, 0x1    # write syscall
    mov rdx, ACCUMULATOR    # write one char, easy to copy from ACCUMULATOR
    lea rsi, [STACK_BASE - BUFFER]
    mov rdi, [STACK_BASE - FD_OUTFILE]
    syscall
    pop COUNTER
    
    inc ecx
    cmp ecx, 4      # check to see if ecx is up to 4 so we can 0 it again mod4
    jne CODER_LOOP

    xor ecx, ecx    # if ecx is 4, zero it out

    jmp CODER_LOOP


ERROR_OUTFILE_OPEN:
# Display error message that we couldn't open outfile.
    mov ACCUMULATOR, 1			# write
    mov rdi, ACCUMULATOR		# stdout is also 1, copied from ACCUMULATOR
    lea rsi, ARG3INVALID[rip]
    mov rdx, OFFSET ARG3INVALID_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR [STACK_BASE - ERROR_CODE], 2	# error code
    jmp CLOSE_INFILE

ERROR_INFILE_OPEN:
# Display error message that we couldn't open infile.
    mov ACCUMULATOR, 1			# write
    mov rdi, ACCUMULATOR		# stdout is also 1 copied from ACCUMULATOR
    lea rsi, ARG2INVALID[rip]
    mov rdx, OFFSET ARG2INVALID_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR [STACK_BASE - ERROR_CODE], 2	# error code
    jmp EXIT

HEX_INVALID:  
# Display message that our input XOR_val is not correct
    mov ACCUMULATOR, 1			        # write
    mov rdi, ACCUMULATOR		        # stdout is also 1
    lea rsi, ARG1INVALID[rip]
    mov rdx, OFFSET ARG1INVALID_LEN		# write
    syscall

    mov QWORD PTR [STACK_BASE - ERROR_CODE], 2	# error code
    jmp EXIT

NUM_ARGS_BAD:
# Number of arguments is not the expected 4
    mov ACCUMULATOR, 1           # write
    mov rdi, ACCUMULATOR		 # stdout is 1 copied from ACCUMULATOR
    lea rsi, USAGE[rip]
    mov rdx, OFFSET USAGE_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR [STACK_BASE - ERROR_CODE], 255	# error code
    jmp EXIT

CLOSE_OUTFILE:
# IF all worked, need to close outfile and then infile
    mov ACCUMULATOR, 0x3        # close
    mov rdi, [STACK_BASE - FD_INFILE]
    syscall

CLOSE_INFILE:
# Only need to close infile, if outfile failed to open
    mov ACCUMULATOR, 0x3        # close
    mov rdi, [STACK_BASE - FD_OUTFILE]
    syscall

EXIT:
    mov eax, 60       # exit syscall
    mov rdi, [STACK_BASE - ERROR_CODE]
    #neg rdi # two's compliment the negative number to obtain the error code

    leave           # put here so ERROR code above can be resolved on stack
                    # also some systems enter main without a valid STACK_BASE
    syscall         # execute exit syscall


# stringtohex subroutine 
# input string pointer passed in rdi
# returns result in ACCUMULATOR
stringtohex:  
    xor ACCUMULATOR, ACCUMULATOR              # Set initial total to 0

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

