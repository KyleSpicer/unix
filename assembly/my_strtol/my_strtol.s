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
 * Order of operations: rax, rdi, rsi, rdx
 *
*/

.intel_syntax noprefix

.section .text
     .global main

main:
     push rbp            # setup stack frame
     mov  rbp, rsp       # align base and stack pointers 

     mov rcx, rdi        # rdi contains argc
     cmp rcx, 3          # compare argc to 3

     jnz DISPLAY_USAGE   # jump if not zero
     
     # convert argv[1]
     lea rbx, [rsi + 8]
     mov rdi, QWORD PTR [rbx] # skips argc, argv[0]

     push rsi
     call my_strtol
     pop rsi

     mov NUM1[rip], rax

     cmp rax, 0
     jz INVALID_INPUT

     # convert argv[2]
     lea rsi, [rsi + 16]
     mov rdi, QWORD PTR [rsi]     # skips argc, argv[0], argv[1]
     call my_strtol

     mov NUM2[rip], rax

     cmp rax, 0     
     jz INVALID_INPUT

     # add two values together
     mov rax, 0
     add rax, QWORD PTR NUM1[rip]
     add rax, QWORD PTR NUM2[rip]
     mov rcx, rax

     # print formatted string
     lea rdi, OUTPUT[rip]          # adding OUTPUT to rdi
     mov rsi, NUM1[rip]            # places NUM1 in rsi
     mov rdx, NUM2[rip]            # places NUM 2 in rdx                  
     mov eax, 0                    # lower 8 bits of register
     call DumpRegs
     call printf

     jmp EXIT

INVALID_INPUT:
     mov rax, 1
     mov rdi, 1
     lea rsi, BAD_INPUT[rip]
     mov rdx, OFFSET BAD_INPUT_LEN
     syscall

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

# my_strtol subroutine
# input string ptr passed in rdi
# returns result in rax
my_strtol:
     push rbp       # save current base pointer
     mov rbp, rsp   # set up new base pointer
     sub rsp, 8     # reserve stack space for local variables
     
     mov rax, 0

convert_strtol:
     movzx rsi, BYTE PTR [rdi]     # get current character
     test rsi, rsi                 # check for \0
     je done_strtol                # returns if \0

     cmp rsi, 0x30       # anything less than 0 is invalid
     jl error_strtol

     cmp rsi, 0x39       # anything greater than 9 is invalid
     jg error_strtol

     sub rsi, 0x30       # convert from ascii to decimal
     imul rax, 0xa       # multiply total by 10
     add rax, rsi        # add current digit to total

     inc rdi             # get address of next character
     jmp convert_strtol

error_strtol:
     mov rax, -1         # return -1 on error

done_strtol:
     add rsp, 8          # clean up  stack frame
     pop rbp             # restore original base pointer
     ret


.data # initialized data section
     ERROR_CODE: .quad 0x0
     NUM1: .quad 0x0
     NUM2: .quad 0x0

.section .rodata
     USAGE: .asciz "Usage: ./my_strtol <num 1> <num 2>\n"
     .set USAGE_LEN, . - USAGE

     BAD_INPUT: .asciz "Must enter two positive integers.\n"
     .set BAD_INPUT_LEN, . - BAD_INPUT

     DISPLAY_STR: .asciz "You entered %s\n"
     .set DISPLAY_STR_LEN, . - DISPLAY_STR

     OUTPUT: .asciz "%lu + %lu = %lu\n"

     