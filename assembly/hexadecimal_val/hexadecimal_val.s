/*
 * hexadecimal_val.s
 *
 * assemble with: gcc hexadecimal_val.s -o hexadecimal_val
 *
 * description: receive two command line arguments (hexidecimal) 
 *  convert string to hexidecimal value. 
 *
 *  Input validation will be incorporated.
 *
 * Order of operations: rax, rdi, rsi, rdx
 *
*/

.intel_syntax noprefix

.section .text
     .global main

main:
     push rbp            # stack frame initialization
     mov  rbp, rsp       # align base and stack pointers 

     mov rcx, rdi        # rdi contains argc
     cmp rcx, 3          # compare argc to 3

     jnz DISPLAY_USAGE   # jump if not zero

     # convert argv[1]
     lea rdi, [rsi + 8]
     mov rdi, QWORD PTR [rdi] # skips argc, argv[0]

     push rsi                 
     call string_to_hex
     pop rsi

     test rax, rax            # if -1 then stringtohex failed
     jns ARG1GOOD             # jump if not signed 
     jmp INVALID_INPUT

ARG1GOOD:
     mov NUM1[rip], rax

     # convert argv[2]
     lea rdi, [rsi + 16]
     mov rdi, QWORD PTR [rdi]     # skips argc, argv[0], argv[1]
     
     push rsi
     call string_to_hex
     pop rsi

     test rax, rax 
     jns ARG2GOOD             # jump if not signed=
     jmp INVALID_INPUT

ARG2GOOD:
     mov NUM2[rip], rax

     # add two values together
     add rax, QWORD PTR NUM1[rip]
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


# procedure to convert a string to hexidecimal
string_to_hex:
     xor rax, rax        # zero out our counter register

convert_stringtohex:
     movzx rsi, BYTE PTR [rdi]    # get current character
     test rsi, rsi                # check for \0
     je done_stringtohex          # returns if \0

     cmp rsi, 0x30       # anything less than 0 is invalid
     jl error_stringtohex

     cmp rsi, 0x39       # anything greater than 9 is invalid
     jle is_num

     # check for A - F characters (uppercase)
     cmp rsi, 0x41       # is it uppercase A
     jl error_stringtohex

     cmp rsi, 0x46       # is it uppercase F
     jle is_upper

     # check for a - f characters (lowercase)
     cmp rsi, 0x61       # is it lowercase A
     jl error_stringtohex

     cmp rsi, 0x66       # is it lowercase F
     jg error_stringtohex

     sub rsi, 0x20  # subtracts 32 from ascii code to make it lowercase

is_upper:
     sub rsi, 0x7  # converts ascii to its num val as hex digit between 10-15

is_num:
     sub rsi, 0x30       # subs 48 from num, converts num to hex value

is_valid:
     imul rax, 0x10       # multiply total by 16
     add rax, rsi        # add current digit to total
     inc rdi             # get address of next character
     jmp convert_stringtohex

error_stringtohex:
     mov rax, -1         # return -1 on error

done_stringtohex:
     ret

# hextostring subroutine
# 
#
hex_to_string:
     mov ecx, 16         # count down counter
     




.section .data # initialized data section
     ERROR_CODE: .quad 0x0
     NUM1:       .quad 0x0
     NUM2:       .quad 0x0

.section .rodata
     USAGE: .ascii "Usage: ./hexadecimal_val <num 1> <num 2>\n"
     .set USAGE_LEN, . - USAGE

     BAD_INPUT: .ascii "Must enter two hexidecimals.\n"
     .set BAD_INPUT_LEN, . - BAD_INPUT

.section .bss
     .lcomm buffer, 16        # 16 byte buffer
