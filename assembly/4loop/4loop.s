/*
 * program.s
 *
 * assemble with: as program.s -o program.o
 *
 * description:
 *
 * for pie with start files (args passed in registers) link with:
 * gcc -z  noexecstack program.o -o program
 *
 * for pie with nostartfiles (args passed on stack) link with: 
 * gcc -nostartfiles -z noexecstack program.o -o program
 * or using ld with: ld -pie -z noexecstack -dynamic-linker /lib64/ld-linux-  
 * x86.so.2 -o prorgam program.o -lc
 *
 * Order of operations: rax, rdi, rsi, rdx
 *
*/

.intel_syntax noprefix # Default for GNU as is ATT syntaxc

.global _start

.text
     
_start:

     mov rax, 0          # load accumulator with value 0

loop_start:
     inc QWORD PTR COUNT[rip]             # increment accumulator by 1
     lea rdi, OUTPUT[rip]
     mov rsi, QWORD PTR COUNT[rip]
     call printf

     mov r12, QWORD PTR MAX[rip]

     cmp QWORD PTR COUNT[rip], r12
     jne loop_start
     
     # exit program
     mov rax, 60         # system call for 'exit'
     mov rdi, 0          # return value of 0
     syscall             # call kernel


.data # initialized data section
     MAX: .quad 10
     
     COUNT: .quad 0x0   # initialize a doubleword variable 'COUNT' to 0

     OUTPUT: .asciz "Counter: %lu\n"    # format string for printf

