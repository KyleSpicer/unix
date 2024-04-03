/*
 * assembly_funcs.s
 *
 *
 * description: used as a source file to hold functions for other projects 
 *
 * Order of operations: rax, rdi, rsi, rdx
 *
*/

.intel_syntax noprefix

.section .text
     .global my_strtol


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


