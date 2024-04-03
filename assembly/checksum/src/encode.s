.intel_syntax noprefix

.set ARGV,           8
.set FILE_NAME,     16
.set FD_INFILE,     24
.set FD_OUTFILE,    32
.set BUFFER,        40

.section .text
     .global ENCODE
     
ENCODE:
OPEN_INPUT:
    mov rax, 2                                # open syscall
    mov rdi, [rbp - ARGV]                     # load ARGV ptr
    mov rdi, [rdi + 8]                        # load ARGV[1]
    mov [rbp - FILE_NAME], rdi                # save ARGV[1] on stack

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

    mov rdi, [rbp - FILE_NAME]                # load ARGV ptr
    
    lea rsi, OUT_FILE_SUFFIX[rip]             # load sufix for concat
    mov rdx, OFFSET OUT_FILE_NAME_LEN         # length of .out
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
    jg READ_WORD                              # continue, if valid

    mov rax, 3			                      # load close syscall
    mov rdi, [rbp - FD_INFILE]	              # input_fd
    syscall                                   # call close

    lea rsi, OUT_FILE_INVALID[rip]            # load invalid outfile message
    mov rdx, OFFSET OUT_FILE_INVALID_LEN      # load length of message
    mov QWORD PTR RETURN_VAL[rip], 2	      # error code
    jmp PRINT_ERROR                           # print error and EXIT


READ_WORD:
    mov WORD PTR [rbp - BUFFER], 0            # clear buffer
    xor rax, rax                              # load read

    mov rdi, [rbp - FD_INFILE]	              # input_fd
    lea rsi, [rbp - BUFFER]                   # load output buffer
    mov rdx, 2                                # read 2 bytes
    syscall                                   # call read

    cmp rax, 0                                # check return
    je ADD_CHECKSUM                           # exit on EOF

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

ADD_CHECKSUM:
    mov rax, 1			                      # load write syscall
    mov rdi, [rbp - FD_OUTFILE]               # fd outfile
    mov CHECKSUM[rip], r12w                   # load 2 bytes into buffer
    lea rsi, CHECKSUM[rip]                    # load output buffer
    mov rdx, 2                                # write two bytes
    syscall                                   # call write

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

   OUT_FILE_SUFFIX: .asciz ".out"
   .set OUT_FILE_NAME_LEN, . - OUT_FILE_SUFFIX
