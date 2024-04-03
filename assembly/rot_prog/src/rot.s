/*
 * rot_prog.s
 *
 * assemble with: gcc rot_prog.s -o rot_prog
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
     enter 32, 0
     mov rcx, rdi                  # rdi contains argc
     cmp rcx, 3                    # compare argc to 3

ARGV1:
     lea rbx, [rsi + 8]            # load rbx with argv[1]
     mov rdi, QWORD PTR [rbx]      # skips argc, argv[0]

     push rsi                      # preserve rsi on stack
     call my_strtol                # convert user input from string to integer
     pop rsi                       # reinstate original rsi
     
     cmp rax, -1                   # compare return to -1
     jz DISPLAY_USAGE

     mov USER_NUM[rip], rax        # save converted strtol to USER_NUM
     
ARGV2:
     lea r8, [rsi + 16]                   # load rbx with argv[2] (file name)
     lea rdi, QWORD PTR FILE_NAME[rip]       # load buffer to rdi
     mov rsi, r8                             # load str into src
     call strcat                             # copy argv[2] to filename buffer

OPEN_FILE:
     # create fp
     mov rax, 2                         # syscall for open
     mov rdi, QWORD PTR FILE_NAME[rip]  # file name
     mov rsi, 0                         
     syscall
     mov QWORD PTR FP[rip], rax

READ_DATA_LOOP:

CLOSE_FILE:
     mov rax, 3
     mov rdi, QWORD PTR FP[rip]
     syscall

DISPLAY_USER_ARGS:
     lea rdi, DISPLAY_ARGS[rip]
     mov rsi, QWORD PTR USER_NUM[rip] 
     mov rdx, QWORD PTR FILE_NAME[rip]
     call printf
     jmp EXIT

DISPLAY_USAGE:
     mov rax, 1          # write syscall
     mov rdi, 1          # set stdout
     lea rsi, USAGE[rip]
     mov rdx, OFFSET USAGE_LEN
     syscall

EXIT:
     leave
     mov rax, 60         # system call for 'exit'
     mov rdi, 0          # return value of 0
     syscall             # call kernel

.bss
     .lcomm BUFFER_LEN, 64         # buffer for user filename

.data # initialized data section
     USER_NUM:      .quad 0x0      # store user input number
     FILE_NAME:     .quad 0x0      # store filename argv[2]
     FP:            .quad 0x0

.section .rodata
     USAGE: .ascii "Usage: ./my_strtol <num 1> <file name>\n"
     .set USAGE_LEN, . - USAGE

     DISPLAY_ARGS: .asciz "USER_NUM: %ld\nFILE_NAME: %s\n"
     .set DISPLAY_ARGS_LEN, . - DISPLAY_ARGS

