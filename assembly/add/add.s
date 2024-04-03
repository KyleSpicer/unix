/*
 * add.s
 *
 * assemble with: as add.s -o add.o
 *
 * description:
 *
 * for pie with start files (args passed in registers) link with:
 * gcc -z  noexecstack add.o -o add
 *
 * for pie with nostartfiles (args passed on stack) link with: 
 * gcc -nostartfiles -z noexecstack add.o -o add
 * or using ld with: ld -pie -z noexecstack -dynamic-linker /lib64/ld-linux-  
 * x86.so.2 -o add add.o -lc
*/

.intel_syntax noprefix # Default for GNU as is ATT syntaxc

.set NOSTARTFILES, 1 # Comment when using gcc with startup files

.section .text

.ifdef NOSTARTFILES
     .global _start 

     _start:

     cmp QWORD PTR [rsp], 3           # argc on the stack with no start files


.else
     .global main

     main:

     mov rcx, rdi      # rdi contains argc when link with gcc with start file
     cmp rcx, 3

.endif

     jz NUM_ARGS_GOOD
     
     mov rax, 1     # write
     mov rdi, 1     # stdout
     lea rsi, USAGE[rip]           # utilizing PIE, Relative Addressing
     mov rdx, OFFSET USAGE_LEN     # using OFFSET accesses the value, not addy 
     syscall

     mov QWORD PTR ERROR_CODE[rip], 1   # error code
     jmp EXIT       # unconditial goto

NUM_ARGS_GOOD:

### Capture argv[1]
.ifdef NOSTARTFILES
     mov rdi, QWORD PTR [rsp + 16]      # pts to first item argv[1]
.else 
     lea rsi, [rsi + 8]
     mov rdi, QWORD PTR [rsi]      # argv[1] 

.endif
     call myatoi
     mov NUM1[rip], rax       # relative instruction ptr
     inc eax                  # add eax, 1
     cmp rax, 0
     jz INVALID

### Capture argv[2]
.ifdef NOSTARTFILES
     mov rdi, QWORD PTR [rsp + 24] # argv[2], skips argc, argv[0], argv[1]
.else
     lea rsi, [rsi + 16]
     mov rdi, QWORD PTR [rsi]
.endif
     call myatoi
     mov NUM2[rip], rax

     add rax, 1
     cmp rax, 0
     jz INVALID

### display NUM1 + NUM2 = SUM
     mov rax , 0
     add rax, QWORD PTR NUM1[rip]  # places sum in rax
     add rax, QWORD PTR NUM2[rip]  # places sum in rax

     mov rsi, rax

### conduct printf
     lea rdi, OUTPUT[rip]     # "5d + 5d = %d"
     mov rsi, NUM1[rip]       # places NUM1 in rsi
     mov rdx, NUM2[rip]       # places NUM2 
     mov rcx, rax

     mov eax, 0 # lower 8 bits of register
     call printf

     mov rax, 60     # exit syscall
     mov rdi, 0 # error msg in a linux shell
     // neg rdi   # two's compliment the negative number to obtain error 
     syscall   # execute syscall

INVALID:
     mov rax, 1
     mov rdi, 1
     lea rsi, NEW_OUTPUT[rip]
     mov rdx, OFFSET NEW_OUTPUT_LEN
     syscall

     jmp EXIT       # unconditial goto


EXIT:
     mov rax, 60     # exit syscall
     mov rdi, QWORD PTR ERROR_CODE[rip] # error msg in a linux shell
     // neg rdi   # two's compliment the negative number to obtain error 
     syscall   # execute syscall


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
     ERROR_CODE: .quad 0x0 # var named ERROR_CODE, quad (8 bytes), value is 0
     
     NUM1: .quad 0x0
     NUM2: .quad 0x0
     NUM3: .quad 0x0

.section .rodata
     USAGE: .ascii "Usage: add <num 1> <num 2>\n"
     .set USAGE_LEN, . - USAGE

     OUTPUT: .asciz "%d + %d = %d\n" # don't need len, using printf, null term
      
     NEW_OUTPUT: .ascii "Must enter two integers. Try Again...\n"
     .set NEW_OUTPUT_LEN, . - NEW_OUTPUT