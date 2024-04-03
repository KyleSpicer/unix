/*
 * practice.s
 *
 * assemble with: gcc practice.s -o practice
 *
 * description: 
 *
 *
 * Order of operations: rax, rdi, rsi, rdx
 *
*/
.intel_syntax noprefix

.global main

.section .text
     .set BUFFER_LEN, 256    # buffer for user input

main:
     enter 32, 0         # setup stack frame
     
     mov rcx, rdi        # rdi contains argc
     cmp rcx, 1          # compare argc to value
     jnz DISPLAY_USAGE   # jump if not zero

     # print prompt: "Enter your name"
     mov rax, 1          # write syscall
     mov rdi, 1          # set for stdout
     lea rsi, MESSAGE[rip]
     mov rdx, OFFSET MESSAGE_LEN
     syscall

     # receive input and save to NAME_BUFFER
     mov rax, 0                    # read syscall
     mov rdi, 0                    # set stdin
     lea rsi, NAME_BUFFER[rip]     # address of message to read
     mov rdx, BUFFER_LEN           # length of message
     syscall 

     mov QWORD PTR [rsi + rax - 1], 0

     mov rcx, 55
     mov rax, 11
     xadd rax, rcx

     mov r15, rax
     mov rax, 1
     mov rdi, 1
     mov rsi, r15
     syscall

     # print GREETING_1 "Hello "
     mov rax, 1
     mov rdi, 1
     lea rsi, GREETING_1[rip]
     mov rdx, OFFSET GREETING_1_LEN
     syscall

     # print name provided
     mov rax, 1
     mov rdi, 1
     lea rsi, NAME_BUFFER[rip]
     mov rdx, BUFFER_LEN
     syscall

     # print GREETING_2 ", welcome ..."
     mov rax, 1
     mov rdi, 1
     lea rsi, GREETING_2[rip]
     mov rdx, OFFSET GREETING_2_LEN
     syscall

MAIN_MENU: 
     mov rax, 1
     mov rdi, 1
     lea rsi, MAIN_MENU_HEADER[rip]
     mov rdx, OFFSET MAIN_MENU_HEADER_LEN
     syscall

     # display menu options
     mov rax, 1
     mov rdi, 1
     lea rsi, MENU_PROMPT[rip]
     mov rdx, OFFSET MENU_PROMPT_LEN
     syscall

     # get user selection
     mov rax, 0                    # read syscall
     mov rdi, 0                    # set stdin
     lea rsi, NAME_BUFFER[rip]     # address of message to read
     mov rdx, BUFFER_LEN           # length of message
     syscall 

     # remove new line character
     mov QWORD PTR [rsi + rax - 1], 0
     mov rdi, rsi

     # convert input from string to long
     push rsi
     call my_strtol
     pop rsi

     # switch statement of sorts
     cmp rax, 1
     je FIB_FUNC

     cmp rax, 2
     je EXIT

     call DISPLAY_INVALID
     jmp MAIN_MENU

FIB_FUNC:
     call SCREEN_CLEAR_FUNC
     
     mov rax, 1
     mov rdi, 1
     lea rsi, FIB_OPTION[rip]
     mov rdx, OFFSET FIB_OPTION_LEN
     syscall

     call FIBBY

     jmp MAIN_MENU 

SLEEPER_FUNC:
     mov rdi, 1
     call sleep
     ret

SCREEN_CLEAR_FUNC:
     call SLEEPER_FUNC

     mov rax, 1
     mov rdi, 1
     lea rsi, SCREEN_CLEAR[rip]
     mov rdx, OFFSET SCREEN_CLEAR_LEN
     syscall
     ret

DISPLAY_INVALID:
     call SCREEN_CLEAR_FUNC
     mov rax, 1          # write syscall
     mov rdi, 1          # set stdout
     lea rsi, INVALID_OPTION[rip]
     mov rdx, OFFSET INVALID_OPTION_LEN
     syscall
     ret

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


.data # initialized data section
     
.bss
     .lcomm NAME_BUFFER, BUFFER_LEN

.section .rodata
     USAGE: .ascii "Usage: ./practice\n"
     .set USAGE_LEN, . - USAGE

     MESSAGE: .ascii "\nEnter your name: "
     .set MESSAGE_LEN, . - MESSAGE

     GREETING_1: .ascii "\n--- Hello "
     .set GREETING_1_LEN, . - GREETING_1

     GREETING_2: .ascii ", welcome to a Basic Assembly Program ---\n\n"
     .set GREETING_2_LEN, . - GREETING_2

     MAIN_MENU_HEADER: .ascii "----- MAIN MENU -----\n\n"
     .set MAIN_MENU_HEADER_LEN, . - MAIN_MENU_HEADER

     SCREEN_CLEAR: .asciz "\033[2J\033[;H"
     .set SCREEN_CLEAR_LEN, . - SCREEN_CLEAR 

     FIB_OPTION: .ascii "--- Calculate Fibonacci Option ---\n"
     .set FIB_OPTION_LEN, . - FIB_OPTION

     MENU_PROMPT: .ascii "1. Calculate Fibonacci\n2. Exit Program\n\nEnter selection: "
     .set MENU_PROMPT_LEN, . - MENU_PROMPT

     INVALID_OPTION: .ascii "Invalid selection. Enter a number from the menu to continue.\n\n"
     .set INVALID_OPTION_LEN, . - INVALID_OPTION
