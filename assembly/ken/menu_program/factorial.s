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
     .global FACTOR, my_strtol
     .set BUFFER_LEN, 256

FACTOR:

     push rcx            # setup stack frame

     mov rax, 1          # write syscall
     mov rdi, 1          # set for stdout
     lea rsi, FACT_MESSAGE[rip]
     mov rdx, OFFSET FACT_MESSAGE_LEN
     syscall

     # receive input and save to INPUT_BUFFER
     mov rax, 0                    # read syscall
     mov rdi, 0                    # set stdin
     lea rsi, INPUT_BUFFER[rip]     # address of message to read
     mov rdx, BUFFER_LEN           # length of message
     syscall 


     lea rdi, INPUT_BUFFER[rip]
     mov QWORD PTR [rdi + rax - 1], 0

     push rsi                 # preserve rsi on stack
     call my_strtol
     pop rsi                  # reinstate rsi to orginal

     cmp rax, -1              # compare return to -1
     je INVALID         # jump if equal (rax and -1)

     cmp rax, 0               # compare return to 0
     je INVALID         # jump if equal (rax and 0)
     js EXIT                  

     cmp rax, -1
     jz INVALID

     mov NUM1[rip], rax
     mov r10, rax


MULT:
     mov rax, QWORD PTR NUM1[rip]
     mov rbx, QWORD PTR RES_1[rip]
     xor rdx, rdx
     imul rbx

     mov QWORD PTR RES_1[rip], rax
     cmp QWORD PTR NUM1[rip], 1
     dec QWORD PTR NUM1[rip]
     jne MULT

     lea rdi, OUTPUT[rip]
     mov rsi, r10
     mov rdx, RES_1[rip]

     mov eax, 0
     call printf

     jmp EXIT

INVALID:
     mov rax, 1
     mov rdi, 1
     lea rsi, USAGE[rip]
     mov rdx, OFFSET USAGE_LEN
     syscall

     mov QWORD PTR ERROR_CODE[rip], 2 

EXIT:
     mov rax, 0
     pop rbp
     ret

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


.section .bss
     .lcomm INPUT_BUFFER, BUFFER_LEN 

.section .data
     ERROR_CODE: .quad 0x0 # var named ERROR_CODE, quad (8 bytes), value is 0
     
     NUM1: .quad 0x1
     RES_1: .quad 0x1
    RES_2: .quad 0x1


.section .rodata
     USAGE: .asciz "Must enter a positive integer\n"
     .set USAGE_LEN, . - USAGE

     FACT_MESSAGE: .ascii "Enter number: "
     .set FACT_MESSAGE_LEN, . - FACT_MESSAGE

     OUTPUT: .asciz "%d! = %d\n"
     