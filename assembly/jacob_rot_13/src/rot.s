/*
 * rot.s
 *
 * assemble with: gcc rot.s -o rot.o
 *
 * description:
 * 
 * usage: ./rot <int> <file_name>
 * Rotate all letters <int> letters (upper or lower) to right.
 * Write output to <file_name>.out
 *
*/

.set ARGV, 8
.set ROT_VAL, 16
.set FD_INFILE, 24
.set FD_OUTFILE, 32
.set BUFFER, 40

.intel_syntax noprefix

.section .text

     .global main

main:
    enter 40, 0                               # setup the stack for storing data

    mov [rbp - ARGV], rsi                     # save *argv[], rbp - 8 on stack
 
    mov rcx, rdi			                  # rdi contains argc when link with gcc with start file
    cmp rcx, 3                                # program name, int for num_rotations, and input_file

    jz NUM_ARGS_GOOD                          # skip usage statement if argc correct

    lea rsi, USAGE[rip]                       # load usage
    mov rdx, OFFSET USAGE_LEN                 # mov rdx, length of USAGE message
    mov QWORD PTR RETURN_VAL[rip], 255	      # error code
    jmp PRINT_ERROR                           # print error and exit

NUM_ARGS_GOOD:
    mov rdi, [rbp - ARGV]                     # load ARGV ptr
    mov rdi, [rdi + 8]                        # load ARGV[1]

    call my_atoi                               # convert rot_val to int
    test rax, rax                             # if -1 then myatoi failed

    jns ROT_VAL_VALID                         # check if -1

    lea rsi, ARG_INVALID[rip]                 # load eror message if rot_val is not int
    mov rdx, OFFSET ARG_INVALID_LEN           # mov rdx, length of USAGE message
    mov QWORD PTR RETURN_VAL[rip], 2	      # error code
    jmp PRINT_ERROR                           # print error and exit

ROT_VAL_VALID:
    mov [rbp - ROT_VAL], rax                  # save converted value to ARGV1

OPEN_INPUT:
    mov rax, 2                                # open syscall
    mov rdi, [rbp - ARGV]                     # load ARGV ptr
    mov rdi, [rdi + 16]                       # load ARGV[2]

    xor rsi, rsi                              # read only
    xor rdx, rdx                              # no flags
    syscall                                   # call open

    test rax, rax                             # check open return
    jg BUILD_OUTPUT_NAME                      # continue, if valid

    lea rsi, IN_FILE_INVALID[rip]             # load invalid infile message
    mov rdx, OFFSET IN_FILE_INVALID_LEN       # load length of message
    mov QWORD PTR RETURN_VAL[rip], 2	      # error code
    jmp PRINT_ERROR                           # print error and exit

BUILD_OUTPUT_NAME:
    mov [rbp - FD_INFILE], rax                # store input file FD on stack

    mov rdi, [rbp - ARGV]                     # load ARGV ptr
    mov rdi, [rdi + 16]                       # load ARGV[2] for modification
    
    lea rsi, OUT_FILE_NAME[rip]               # load sufix for concat
    mov rdx, OFFSET OUT_FILE_NAME_LEN         # length of .out
    call strncat                              # call strncat

OPEN_OUTPUT:
    mov rdi, rax                              # load the new filename for write
    
    mov rax, 2                                # load write
    mov rsi, 0x41                             # O_CREATE | WR_ONLY
    mov rdx, 0x1a4                            # 0644 file permissions
    syscall                                   # call write

    mov [rbp - FD_OUTFILE], rax               # save output FD on stack

    test rax, rax                             # check open return
    jg READ_BYTE                              # continue, if valid

    mov rax, 3			                      # load close syscall
    mov rdi, [rbp - FD_INFILE]	              # input_fd
    syscall                                   # call close

    lea rsi, OUT_FILE_INVALID[rip]            # load invalid outfile message
    mov rdx, OFFSET OUT_FILE_INVALID_LEN      # load length of message
    mov QWORD PTR RETURN_VAL[rip], 2	      # error code
    jmp PRINT_ERROR                           # print error and exit

READ_BYTE:
    xor rax, rax			                  # load read
    mov rdi, [rbp - FD_INFILE]	              # input_fd
    lea rsi, [rbp - BUFFER]                   # load output buffer
    mov rdx, 1                                # read 1 byte
    syscall                                   # call read

    cmp rax, 0                                # check return
    je EXIT                                   # exit on EOF

    mov rax, [rbp - BUFFER]                   # load buffer
    mov rbx, [rbp - ROT_VAL]                  # load rot value

    and rax, 255                              # clear upper bits

    cmp rax, 'Z'                              # check if upper or lower
    jg INCREMENT_LOWER                        # 'a' is  higher than 'Z'

# 97-122 a-z
INCREMENT_UPPER:
    cmp rax, 'A'                              # anything less than a invalid
    jl WRITE_BYTE                             # write as is
     
    add rax, rbx                              # add rot_val to number
    
DEC_UPPER:
    cmp rax, 'Z' + 1                          # check if number out of bounds
    mov [rbp - BUFFER], rax                   # store value in buffer
    jl WRITE_BYTE                             # write valid byte

    sub rax, 26                               # subtract 26 to act as modulus
    jmp DEC_UPPER                             # check again

# 65-90 A-Z
INCREMENT_LOWER:
    cmp rax, 'a'                              # anything less is invalid
    jl WRITE_BYTE                             # write as is
    cmp rax, 'z'                              # anything above is invalid
    ja WRITE_BYTE                             # write as is

    add rax, rbx                              # add rot_val to number

DEC_LOWER:
    cmp rax, 'z' + 1                          # check if number out of bounds
    mov [rbp - BUFFER], rax                   # store value in buffer
    jl WRITE_BYTE                             # write valid byte

    sub rax, 26                               # subtract 26 to act as modulus
    jmp DEC_LOWER                             # check again

WRITE_BYTE:
    mov rax, 1			                      # load write syscall
    mov rdi, [rbp - FD_OUTFILE]               # fd outfile
    lea rsi, [rbp - BUFFER]                   # load output buffer
    mov rdx, 1                                # write one byte
    syscall                                   # call write

    jmp READ_BYTE                             # read next byte

PRINT_ERROR:
    mov rax, 1			                      # load write syscall
    mov rdi, 1			                      # stdout
    syscall                                   # call write

EXIT:
    leave                                     # reset the stack

    mov eax, 60                               # exit syscall
    mov rdi, QWORD PTR RETURN_VAL[rip]        # load return value
    syscall                                   # execute exit syscall

# returns result in rax
my_atoi:   
     mov rax, 0							# set rax to 0

convert_strtol:
     movzx rsi, BYTE PTR [rdi]     		# move first character to rsi
     test rsi, rsi                 		# set flags
     je done_strtol                		# jump to done if 0

     cmp rsi, 0x30       				# if value < 0
     jl error_strtol					# jump to error

     cmp rsi, 0x39       				# if value > 9
     jg error_strtol					# jump to error

     sub rsi, 0x30       				# convert from ascii to decimal
     imul rax, 0xa       				# multiply total by 10
     add rax, rsi        				# add current digit to total

     inc rdi             				# rdi++
     jmp convert_strtol					# restart loop

error_strtol:				
     mov rax, -1         				# return -1 on error

done_strtol:
     ret								# return

.section .data

   RETURN_VAL: .quad  0x0	            # initialize to 0

.section .rodata

   USAGE: .ascii "Usage: ./rot <int> <input_file>\n"
   .set USAGE_LEN, . - USAGE

   ARG_INVALID: .ascii "Argument must be unsigned integer numbers.\n"
   .set ARG_INVALID_LEN, . - ARG_INVALID

   IN_FILE_INVALID: .ascii "Input file failed to open.\n"
   .set IN_FILE_INVALID_LEN, . - IN_FILE_INVALID

   OUT_FILE_INVALID: .ascii "Output file failed to open.\n"
   .set OUT_FILE_INVALID_LEN, . - OUT_FILE_INVALID

   OUT_FILE_NAME: .asciz ".out"
   .set OUT_FILE_NAME_LEN, . - OUT_FILE_NAME
