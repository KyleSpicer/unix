.intel_syntax noprefix

.globl main

main:
    enter   32, 0               # allocate some stack space
    mov rax, 1                  # set bad return code
    cmp rdi, 2                  # if argc != 2
    jne .SHUTDOWN               #   goto .SHUTDOWN
    mov rdi, QWORD PTR[rsi + 8] # put argv[1] into arg0
    mov QWORD PTR -32[rbp], 0   # clear stack area for incoming value
    lea rsi, -32[rbp]           # use -32 (to -24) for *endptr arg1
    mov rdx, 10                 # put base 10 into arg2
    call    strtol
    mov rsi, QWORD PTR -32[rbp] # get char * stored in -32->-24
    cmp BYTE PTR [rsi], 0       # if char != NULL
    jne .SHUTDOWN               #   goto .SHUTDOWN
    lea rdi, .OUTPUT[rip]       # load string into arg0
    mov rsi, rax                # load strtol result into arg1
    call    printf
    xor rax, rax                # set return value to 0
.SHUTDOWN:
    leave                       # restore stack
    ret                         # signal exit
.OUTPUT:
    .asciz "Result: %ld\n"