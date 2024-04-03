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


.intel_syntax noprefix

.set ARGV,           8
.set FILE_NAME,     16
.set FD_INFILE,     24
.set FD_OUTFILE,    32
.set BUFFER,        40


.section .text

    .global main
    counter=rcx

main:
    enter 40, 0                             # setup the stack for storing data

    mov [rbp - ARGV], rsi                   # save *argv[], rbp - 8 on stack
 
    mov rcx, rdi                            # save argc from rdi
    cmp rcx, 2                              

    jz ENCODE                          # skip usage statement if argc correct

    cmp rcx, 3
    jz DECODE

    lea rsi, USAGE[rip]                       # load usage
    mov rdx, OFFSET USAGE_LEN                 # OFFSET for message
    mov QWORD PTR RETURN_VAL[rip], 255	      # error code
    jmp PRINT_ERROR                           # print error and exit

DECODE:
OPEN_INPUT:
    mov rax, 2                                # open syscall
    mov rdi, [rbp - ARGV]                     # load ARGV ptr
    mov rdi, [rdi + 16]                       # load ARGV[2]
    mov [rbp - FILE_NAME], rdi                # save ARGV[2] on stack

    mov rsi, 2                              # read only
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
    xor r9, r9
    xor counter, counter

GET_NEXT_CHAR:
    mov r9b, BYTE PTR [rdi + counter]

CHECK_BYTE:
    cmp r9, '.'
    jz REPLACE_WITH_NULL

    cmp r9, 0
    jz FIND_DECIMAL

    inc counter
    jmp GET_NEXT_CHAR

REPLACE_WITH_NULL:
    mov BYTE PTR [rdi + counter], 0             # NULL on '.'
    mov BYTE PTR [rdi + counter + 1], 0         # NULL on '.' + 1

FIND_DECIMAL:
    mov rdi, [rbp - FILE_NAME]
    lea rsi, OUT_FILE_SUFFIX[rip]             # load sufix for concat
    mov rdx, 1                                # length of suffix "2"
    xor rcx, rcx
    xor r8, r8
    xor r9, r9

    call strncat                              # call strncat

OPEN_OUTPUT:
    mov rdi, rax                              # load new filename for write
    mov rax, 2                                # load write
    mov rsi, 0x41                             # O_CREATE | WR_ONLY
    mov rdx, 0x1a4                            # 0644 file permissions
    syscall                                   # call write

    mov [rbp - FD_OUTFILE], rax               # save output FD on stack

    xor r12, r12                              # zeroize accumulator
    test rax, rax                             # check open return
    jg GET_CHECKSUM                           # continue, if valid

    mov rax, 3			                      # load close syscall
    mov rdi, [rbp - FD_INFILE]	              # input_fd
    syscall                                   # call close

    lea rsi, OUT_FILE_INVALID[rip]            # load invalid outfile message
    mov rdx, OFFSET OUT_FILE_INVALID_LEN      # load length of message
    mov QWORD PTR RETURN_VAL[rip], 2	      # error code
    jmp PRINT_ERROR                           # print error and EXIT

GET_CHECKSUM:
    mov rax, 0x8
    mov rdi, [rbp - FD_INFILE]                 # file descriptor
    mov rsi, -2                                  # OFFSET
    mov rdx, 2                                  # SEEK_END 
    syscall

    # rax now conatins length of file
    push rax

READ_CHECKSUM:
    mov WORD PTR [rbp - BUFFER], 0            # clear buffer
    xor rax, rax                              # load read

    mov rdi, [rbp - FD_INFILE]	              # input_fd
    lea rsi, [rbp - BUFFER]                   # load output buffer
    mov rdx, 2                                # read 2 bytes
    syscall                                   # call read

LSEEK_TO_BEGGINING:
    xor r12, r12
    pop r12                                   # r12 now has file size 
    push [rbp - BUFFER]                       # pushing checksum

    mov rax, 0x8
    mov rdi, [rbp - FD_INFILE]                  # file descriptor
    mov rsi, 0                                  # OFFSET
    mov rdx, 0                                  # SEEK_SET (beginning) 
    syscall

TRUNCATE:
    mov rax, 0x4d                               # ftruncate syscall
    mov rdi, [rbp - FD_OUTFILE]
    mov rsi, r12
    syscall
   
    xor r12, r12

READ_WORD:
    mov WORD PTR [rbp - BUFFER], 0            # clear buffer
    xor rax, rax                              # load read

    mov rdi, [rbp - FD_INFILE]	              # input_fd
    lea rsi, [rbp - BUFFER]                   # load output buffer
    mov rdx, 2                                # read 2 bytes
    syscall                                   # call read

    cmp rax, 0
    jz CMP_CHECKSUM

ADD:
    mov r11w, WORD PTR[rbp - BUFFER]          # load buffer
    rol r11w, 8                               # swap endianness
    add r12w, r11w                            # add word to r12

    rol r11w, 8                               # swap endianness

WRITE_WORD:
    mov rdx, rax                              # write bytes read
    mov rax, 1			                      # load write syscall
    mov rdi, [rbp - FD_OUTFILE]               # fd outfile
    lea rsi, [rbp - BUFFER]                   # load output buffer
    syscall                                   # call write

    jmp READ_WORD                             # read next byte

PRINT_ERROR:
    mov rax, 1			                      # load write syscall
    mov rdi, 1			                      # stdout
    syscall                                   # call write
    jmp EXIT                                  # jump to exit

PRINT_SUCCESS:
    lea rsi, CHECKSUM_MATCH[rip]            # load invalid outfile message
    mov rdx, OFFSET CHECKSUM_MATCH_LEN      # load length of message
    mov rax, 1
    mov rdi, 1
    syscall

    jmp EXIT

CMP_CHECKSUM:
    pop rax
    cmp r12w, ax

    je PRINT_SUCCESS

    lea rsi, CHECKSUM_MISMATCH[rip]            # load invalid outfile message
    mov rdx, OFFSET CHECKSUM_MISMATCH_LEN      # load length of message
    jmp PRINT_ERROR

EXIT:
    leave                                     # reset the stack
    mov eax, 60                               # exit syscall
    mov rdi, QWORD PTR RETURN_VAL[rip]        # load return value
    syscall                                   # execute exit syscall


.section .data

   RETURN_VAL: .quad  0x0	            # initialize ret val to 0
   CHECKSUM:   .word  0x0               # initialize two-byte buffer to 0

.section .rodata

   USAGE: .ascii "Usage: ./checksum <input_file>\n"
   .set USAGE_LEN, . - USAGE

   IN_FILE_INVALID: .ascii "Input file failed to open.\n"
   .set IN_FILE_INVALID_LEN, . - IN_FILE_INVALID

   OUT_FILE_INVALID: .ascii "Output file failed to open.\n"
   .set OUT_FILE_INVALID_LEN, . - OUT_FILE_INVALID

    CHECKSUM_MISMATCH: .ascii "CHECKSUM Incorrect.\n"
   .set CHECKSUM_MISMATCH_LEN, . - CHECKSUM_MISMATCH

    CHECKSUM_MATCH: .ascii "CHECKSUM SUCCESS!.\n"
   .set CHECKSUM_MATCH_LEN, . - CHECKSUM_MATCH

   OUT_FILE_SUFFIX: .asciz "2"

