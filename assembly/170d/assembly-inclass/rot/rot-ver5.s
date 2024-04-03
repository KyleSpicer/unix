/* 
 * add.s 
 * assemble with: as add.s -o add.o
 *
 * for pie with start files (args passed in registers) link with: gcc -z noexecstack add.o -o add
 * for pie with no start files (args passed on stack) link with: gcc -nostartfiles -z noexecstack add.o -o add
 * or using ld with: ld -pie -z noexecstack -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o add add.o -lc
*/

.intel_syntax noprefix

.set ARGV, 8
.set ROTVAL, 16
.set FD_INFILE, 24
.set FD_OUTFILE, 32
.set BUFFER, 40
.set ERROR_CODE, 48

#.set NOSTARTFILES, 1 # Comment when using gcc with startup files

.section .text

.global main

main:
    enter 40, 0

    mov [rbp - ARGV], rsi                # save *argv[], rbp - 8
 
    mov rcx, rdi			# rdi contains argc when link with gcc with start file
    cmp rcx, 4 

    jnz NUM_ARGS_BAD        # if numbers of args is not 4, then display usage message and get out

    # Get argv[1]
    mov rdi, [rbp - ARGV]           # retrieve *argv[]

    lea rdi, [rdi + 8]			    # ROT_VAL
    mov rdi, QWORD PTR [rdi]        # argv[1]

    call myatoi

    test rax, rax               #  if rax is -1 then atoi failed

    js ROTVALINVALID

    cmp rax, 1
    jl ROTVALINVALID

    cmp rax, 25
    jg ROTVALINVALID

    mov [rbp - ROTVAL], rax             # save integer rotval to the stack            


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




    jmp CLOSE_OUTFILE




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

# Display message that our input rotval is not correct
ROTVALINVALID:  
    mov rax, 1			# write
    mov rdi, rax		# stdout is also 1
    lea rsi, ARG1INVALID[rip]
    mov rdx, OFFSET ARG1INVALID_LEN		# write

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


# myatoi subroutine 
# input string pointer passed in rdi
# returns result in rax
myatoi:
    mov rax, 0              # Set initial total to 0

convert:
    movzx rsi, BYTE PTR [rdi]   # Get the current character
    test rsi, rsi           # Check for \0
    je done_atoi

    cmp rsi, 0x30           # Anything less than 0 is invalid
    jl error_atoi

    cmp rsi, 0x39           # Anything greater than 9 is invalid
    jg error_atoi

    sub rsi, 0x30           # Convert from ASCII to decimal 
    imul rax, 0xa           # Multiply total by 10
    add rax, rsi            # Add current digit to total

    inc rdi                 # Get the address of the next character
    jmp convert

error_atoi:
    mov rax, -1             # Return -1 on error

done_atoi:
    ret                     # Return total or error code 

.section .data

   NUM1HIGH: .quad 0x0

.section .rodata

   USAGE: .ascii "Usage: rot <rot-val> <infile> <outfile>\n"
   .set USAGE_LEN, . - USAGE

   ARG1INVALID: .ascii "Argument must be unsinged decimal numbers from 1 to 25.\n"
   .set ARG1INVALID_LEN, . - ARG1INVALID

   ARG2INVALID: .ascii "Unable to open <infile> for reading.\n"
   .set ARG2INVALID_LEN, . - ARG2INVALID

   ARG3INVALID: .ascii "Unable to open <outfile> for writing.\n"
   .set ARG3INVALID_LEN, . - ARG3INVALID

   ERROR_READING: .ascii "Error reading from <infile>.\n"
   .set ERROR_READING_LEN, . - ERROR_READING

   ERROR_WRITING: .ascii "Error writing to <outfile>.\n"
   .set ERROR_WRITING_LEN, . - ERROR_WRITING

.section .bss 
	.lcomm buffer, 16             # 16 byte buffer
	.lcomm saverax, 8             # 8 byte buffer
