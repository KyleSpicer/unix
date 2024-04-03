/*
 * progam.s
 *
 * assemble with: gcc progam.s -o progam
 *
 * description: 
 *
 *
 * Order of operations: rax, rdi, rsi, rdx
 *
*/

.intel_syntax noprefix

.section .text
     .global main

main:
     mov rcx, rdi        # rdi contains argc
     cmp rcx, 3          # compare argc to 3

     jnz DISPLAY_USAGE   # jump if not zero
     jz EXIT             # jump if zero


DISPLAY_USAGE:
     mov rax, 1          # write syscall
     mov rdi, 1          # set stdout
     lea rsi, USAGE[rip]
     mov rdx, OFFSET USAGE_LEN
     syscall

EXIT:
     mov rax, 60         # system call for 'exit'
     mov rdi, 0          # return value of 0
     syscall             # call kernel


.data # initialized data section
     .lcomm


.section .rodata
     USAGE: .ascii "Usage: ./my_strtol <num 1> <num 2>\n"
     .set USAGE_LEN, . - USAGE

     BAD_INPUT: .ascii "Must enter two positive integers.\n"
     .set BAD_INPUT_LEN, . - BAD_INPUT

