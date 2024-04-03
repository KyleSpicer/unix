/*
 * my_strtol.s
 *
 * assemble with: gcc my_strtol.s -o my_strtol
 *
 * description: two command line arguments (integers) 
 *  convert CL args to long integers and display results.
 *  Input validation will be incorporated.
 *
 *
 * Order of operations: rdi, rsi, rdx, rcx, r8
 *
*/

.intel_syntax noprefix

.section .text
     .global main

main:
     push rbp            # setup stack frame
     mov  rbp, rsp       # align base and stack pointers 

     # print formatted string showing two hard coded numbers
     lea rdi, NUMBER_PRINT[rip]          # adding OUTPUT to rdi
     mov rsi, QWORD PTR NUM1[rip]        # places NUM1 in rsi
     mov rdx, QWORD PTR NUM2[rip]        # places NUM 2 in rdx               
     mov eax, 0                          # lower 8 bits of register
     call printf

     # add NUM1 and NUM2 to rax
     xor r9, r9
     mov rax, QWORD PTR NUM1[rip]
     add rax, QWORD PTR NUM2[rip]
     
     jc HANDLE_CARRY          # jump if carry flag is set

     # carry flag not set, print result and exit
     lea rdi, SIMPLE_OUTPUT[rip]
     mov rsi, NUM1[rip]
     mov rdx, NUM2[rip]
     mov rcx, rax
     call printf

     jmp EXIT

HANDLE_CARRY:
     #rdi, rsi, rdx, rcx, r8
     lea rdi, COMPLEX_OUTPUT[rip]
     mov rsi, NUM1[rip]
     mov rdx, NUM2[rip]
     adc r9, 0
     mov r8, rax
     mov rcx, r9
     call printf

     jmp EXIT


DISPLAY_USAGE:
     mov rax, 1          # write syscall
     mov rdi, 1          # set stdout
     lea rsi, USAGE[rip]
     mov rdx, OFFSET USAGE_LEN
     syscall

EXIT:
     pop rbp             # close stack
     mov rax, 60         # system call for 'exit'
     mov rdi, 0          # return value of 0
     syscall             # call kernel


.data # initialized data section
     ERROR_CODE: .quad 0x0
     NUM1: .quad    0xdeadbeef12345678
     NUM2: .quad    0xfacefade87654321


.section .rodata
     USAGE: .asciz "Usage: ./my_strtol <num 1> <num 2>\n"
     .set USAGE_LEN, . - USAGE

     BAD_INPUT: .asciz "Must enter two positive integers.\n"
     .set BAD_INPUT_LEN, . - BAD_INPUT

     DISPLAY_STR: .asciz "You entered %s\n"
     .set DISPLAY_STR_LEN, . - DISPLAY_STR

     OUTPUT: .asciz "%lx + %lx = %lx\n"
     .set OUTPUT_LEN, . - OUTPUT

     SIMPLE_OUTPUT: .asciz "%lx + %lx = %lx\n"

     COMPLEX_OUTPUT: .asciz "%lx + %lx = %lx%lx\n"

     NUMBER_PRINT: .asciz "NUM1: %lx\nNUM2: %lx\n"  # display only the number
