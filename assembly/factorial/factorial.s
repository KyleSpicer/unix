 /*
 * factorial.s
 *
 * assemble with: as factorial.s -o factorial.o
 *
 * description:
 *
 * for pie with start files (args passed in registers) link with:
 * gcc -z  noexecstack factorial.o -o factorial
 *
 * for pie with nostartfiles (args passed on stack) link with: 
 * gcc -nostartfiles -z noexecstack factorial.o -o factorial
 * or using ld with: ld -pie -z noexecstack -dynamic-linker /lib64/ld-linux-  
 * x86.so.2 -o factorial factorial.o -lc
*/

.intel_syntax noprefix # Default for GNU as is ATT syntaxc

.set NOSTARTFILES, 1 # Comment when using gcc with startup files

.section .text

.ifdef NOSTARTFILES
     .global _start 

     _start:

     cmp QWORD PTR [rsp], 2           # argc on the stack with no start files


.else
     .global main

     main:

     mov rcx, rdi      # rdi contains argc when link with gcc with start file
     cmp rcx, 2 # two args?

.endif

     jz NUM_ARGS_GOOD
     
     # This starts the bad input area so print usage
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
     mov rdi, QWORD PTR [rsp + 16]      # pts to argv[1]
.else 
     lea rsi, [rsi + 8]
     mov rdi, QWORD PTR [rsi]      # argv[1] 

.endif
     call myatoi

    # see if myatoi returned -1, bad input
     cmp rax, -1
     jz INVALID

    # it did not, so load it into NUM1
     mov NUM1[rip], rax

### Check if input is 0 or 1 then check for negative nums
     cmp rax, 1
     jle DONE
     js DONE

MULT:
     mov rax , QWORD PTR NUM1[rip]  # places sum in rax
     mov rbx , QWORD PTR RES_1[rip]  # places rax in rbx
     xor rdx, rdx # this will be for using multiple registers for 13! and higher
     imul rbx # mul works too, but imul will use two registers (not implemented)

     mov QWORD PTR RES_1[rip], rax  # places rax in rbx
     dec QWORD PTR NUM1[rip] # decrement the number
    cmp QWORD PTR NUM1[rip], 1 # check if 1
     jne MULT # keep going if higher than 1

     lea rdi, OUTPUT[rip]     # "%d!= %d"
     mov rsi, NUM1[rip]       # places NUM1 in rsi
     mov rdx, RES_1[rip]       # RES in rdx

     mov eax, 0 # lower 8 bits of register
     call printf


     mov rax, 60     # exit syscall
     xor rdi, rdi # error msg in a linux shell
     // neg rdi   # two's compliment the negative number to obtain error 
     syscall   # execute syscall

DONE:
### conduct printf
     lea rdi, OUTPUT[rip]     # "%d!= %d"
     mov rsi, NUM1[rip]       # places NUM1 in rsi
     mov rdx, RES_1[rip]       # places NUM2 
    mov rcx, RES_1[rip+8]       # places NUM2 

     mov eax, 0 # lower 8 bits of register
     call printf

     jmp EXIT


INVALID:
     mov rax, 1
     mov rdi, 1
     lea rsi, NEW_OUTPUT[rip]
     mov rdx, OFFSET OUTPUT_LEN
     syscall

     mov QWORD PTR ERROR_CODE[rip], 2 

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
     
     NUM1: .quad 0x1
     RES_1: .quad 0x1
    RES_2: .quad 0x1


.section .rodata
     USAGE: .ascii "Usage: add <num 1>\n"
     .set USAGE_LEN, . - USAGE

     OUTPUT: .asciz "%d! = %d\n" # don't need len, using printf, null term
     NEW_OUTPUT: .ascii "This Sucks\n"
     .set OUTPUT_LEN, . - NEW_OUTPUT
