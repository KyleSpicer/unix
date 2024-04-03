/*
 * fib.s
 *
 * assemble with: gcc fib.s -o fib
 *
 * usage: ./fib_with_carry 100
 *
 * description: assembly program to calculate/display fibonacci sequence up
 *              to the number specified by user
 *
 *
 * Order of operations: rdi, rsi, rdx, rcx, r8, r9
 *
*/

.intel_syntax noprefix

.section .text
     .global main

main:
     push rcx            # setup stack frame
     mov rcx, rdi        # rdi contains argc
     cmp rcx, 2          # compare argc to 3

     jnz DISPLAY_USAGE   # jump if not zero
     
     # convert argv[1] from string to long
     lea rbx, [rsi + 8]                           # load rbx with argv[1]
     mov rdi, QWORD PTR [rbx]                     # skips argc, argv[0]

     push rsi                 # preserve rsi on stack
     call my_strtol
     pop rsi                  # reinstate rsi to orginal

     cmp rax, -1              # compare return to -1
     je DISPLAY_USAGE         # jump if equal (rax and -1)

     cmp rax, 0               # compare return to 0
     je DISPLAY_USAGE         # jump if equal (rax and 0)
     js EXIT                  

    # Save results of my_strtol from rax to USER_NUM variable
     mov USER_NUM[rip], rax        # save result to USER_NUM var
     xor rbx, rbx                  # zero out rbx
     xor r8, r8                    # zero out r8
     xor rax, rax                  # zero out rax
     xor r9, r9                    # zero out r9

FIB:
     mov rax, QWORD PTR NUM_1_L[rip]    # move value in NUM_1_L to rax

     mov rbx, QWORD PTR NUM_2_L[rip]    # move value in NUM_2_L to rbx

     inc QWORD PTR COUNT[rip]           # increment counter variable by 1
     mov rsi, QWORD PTR COUNT[rip]      # load count var to rsi

     add rax, rbx                       # add rbx and rax

     mov QWORD PTR BASE_RESULT[rip], rax     # move result to BASE_RESULT var
     mov rdx, QWORD PTR NUM_1_L[rip]         # move NUM_1_L to rdx
     mov rdi, rax                            # move result to rdi
     mov QWORD PTR NUM_1_L[rip], rdi         # move rdi to NUM_1_L var
     mov QWORD PTR NUM_2_L[rip], rdx         # move rdx to NUM_2_L var

DEBUG_PRINT:
     jc two_registers                        # jump if carry to two_registers
     mov rax, QWORD PTR CARRY_CURR[rip]      # move carry_curr to rax
     cmp rax, 0                              # compare rax to 0
     jnz two_registers                       # jump if non-zero to two_reg
     
one_register:
     # there were no values in CARRY_CUR variable
     lea rdi, OUTPUT_NO_CARRY[rip]           # load variable to rdi
     mov rdx, QWORD PTR BASE_RESULT[rip]     # load result var to rdx
     jmp DISPLAY_RESULT                      # goto print label

two_registers:
     # if CARRY_CUR was greater than zero
     mov r8, QWORD PTR CARRY_CURR[rip]       # move carry_cur to r8
     mov r9, QWORD PTR CARRY_PREV[rip]       # move carry_prev to r9

     adc r9, r8                              # add with carry r8 to r9

     mov QWORD PTR CARRY_CURR[rip], r9       # move r9 to CARRY_CURR var
     mov QWORD PTR CARRY_PREV[rip], r8       # move r8 to CARRY_PREV var

     xchg r9, r8                             # swap values between r8 and r9

     jc three_registers                  # jump if carry to three_reg label
     mov rax, QWORD PTR SECOND_CARRY_CURR[rip]    # move var to rax
     cmp rax, 0                                   # compare rax and 0
     jnz three_registers                # jump if non-zero to three_registers
     
     lea rdi, OUTPUT[rip]               # loading the output str to rdi
     mov rdx, r8                             # move r8 to rdx
     mov rcx, QWORD PTR BASE_RESULT[rip]     # move BASE_RESULT to rcx
     
     jmp DISPLAY_RESULT                      # jump to DISPLAY_RESULT label

three_registers:
     mov r8, QWORD PTR SECOND_CARRY_CURR[rip]  # 
     mov r9, QWORD PTR SECOND_CARRY_PREV[rip]  # 

     adc r9, r8                              # add with carry r8, r9

     jc TOO_LARGE_MSG                        # jump if carry to TOO_LARGE_MSG

     mov QWORD PTR SECOND_CARRY_CURR[rip], r9  
     mov QWORD PTR SECOND_CARRY_PREV[rip], r8  

     xchg r9, r8                             # exchange r8 to r9

     lea rdi, CARRY_OUTPUT[rip]              # loading the output str

     mov rdx, r8
     mov rcx, QWORD PTR CARRY_CURR[rip]
     mov r8, QWORD PTR BASE_RESULT[rip]


DISPLAY_RESULT:

     xor eax, eax                         # clear rax before calling
     call printf

     mov r12, QWORD PTR USER_NUM[rip]   # mov user input to r12
     cmp QWORD PTR COUNT[rip], r12      # cmp count to user input

     jne FIB        # if count and user input not equal, enter FIB LOOP

EXIT:
     mov rax, 60                             # exit syscall
     mov rdi, QWORD PTR ERROR_CODE[rip]      # error msg in a linux shell
     syscall                                 # execute syscall

DISPLAY_USAGE:
     mov rax, 1
     mov rdi, 1
     lea rsi, USAGE[rip]
     mov rdx, OFFSET USAGE_LEN
     syscall

     mov QWORD PTR ERROR_CODE[rip], 2 
     jmp EXIT

TOO_LARGE_MSG:
     # if third register overflows, display this message
     mov rax, 1
     mov rdi, 1
     lea rsi, TOO_LARGE[rip]
     mov rdx, OFFSET TOO_LARGE_LEN
     syscall

     mov QWORD PTR ERROR_CODE[rip], 2 
     jmp EXIT

# my_strtol subroutine
# input string ptr passed in rdi
# returns result in rax
my_strtol:
     push rbp
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
     ERROR_CODE:   .quad 0x0               # quad (8 bytes), value is 0
     USER_NUM:     .quad 0x1               # hold converted argv[1] as long
     COUNT:        .quad 0x0               # program counter variable
     NUM_1_L:      .quad 0x0               # fibonacci calc starts with 0
     NUM_2_L:      .quad 0x1               # fibonacci calc second num is 1
     BASE_RESULT:  .quad 0x0               # 
     CARRY_CURR:   .quad 0x0
     CARRY_PREV:   .quad 0x0
     SECOND_CARRY_CURR: .quad 0x0
     SECOND_CARRY_PREV: .quad 0x0


.section .rodata
     USAGE: .asciz "Usage: ./fibonacci <integer>\n"
     .set USAGE_LEN, . - USAGE

     TOO_LARGE: .asciz "Three Registers Overflow!!!\n"
     .set TOO_LARGE_LEN, . - TOO_LARGE

     CARRY_OUTPUT: .asciz "%3lu: %lx %lx %lx\n" 
     .set CARRY_OUTPUT_LEN, . - CARRY_OUTPUT

     OUTPUT: .asciz "%3lu: %lx %lx\n" 
     .set OUTPUT_LEN, . - OUTPUT

     OUTPUT_NO_CARRY: .asciz "%3lu: %lx\n" 
     .set OUTPUT_LEN, . - OUTPUT_NO_CARRY
