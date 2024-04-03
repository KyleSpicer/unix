/* 
 * add.s 
 * assemble with: as add.s -o add.o
 *
 * for pie with start files (args passed in registers) link with: gcc -z noexecstack add.o -o add
 * for pie with no start files (args passed on stack) link with: gcc -nostartfiles -z noexecstack add.o -o add
 * or using ld with: ld -pie -z noexecstack -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o add add.o -lc
*/

.intel_syntax noprefix

#.set NOSTARTFILES, 1 # Comment when using gcc with startup files

.section .text

.global main

main:

    #push rbp
    #mov rbp, rsp

    enter 40, 0

    mov [rbp - 8], rsi                # save *argv[], rbp - 8
 
    mov rcx, rdi			# rdi contains argc when link with gcc with start file
    cmp rcx, 4 

    jz NUM_ARGS_GOOD

    mov rax, 1			# write
    mov rdi, 1			# stdout
    lea rsi, USAGE[rip]
    mov rdx, OFFSET USAGE_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR ERROR_CODE[rip], 255	# error code
    jmp EXIT

NUM_ARGS_GOOD:

    lea rdi, [rsi + 8]			# ROT_VAL
    mov rdi, QWORD PTR [rdi]            # argv[1]

    test rax, rax               # if -1 then stringtohex failed

    jns ARG1GOOD

    mov rax, 1			# write
    mov rdi, 1			# stdout
    lea rsi, ARGINVALID[rip]
    mov rdx, OFFSET ARGINVALID_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR ERROR_CODE[rip], 2	# error code
    jmp EXIT

ARG1GOOD:

    mov ARGV1[rip], rax # save converted value to ARGV1





EXIT:
    leave

    mov eax, 60       # exit syscall
    mov rdi, QWORD PTR ERROR_CODE[rip]        # error message in a Linux shell means all worked well
    #neg rdi             # two's compliment the negative number to obtain the error code
    syscall           # execute exit syscall


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

.section .data

   ERROR_CODE: .quad  0x0	

   NUM1HIGH: .quad 0x0
   NUM1LOW: .quad 0x0

   ARGV1: .quad 0x0

   NEWLINE: .byte 0xa

.section .rodata

   USAGE: .ascii "Usage: fibo <num1>\n"
   .set USAGE_LEN, . - USAGE

   ARGINVALID: .ascii "Argument must be unsinged hexadecimal numbers.\n"
   .set ARGINVALID_LEN, . - ARGINVALID

.section .bss 
	.lcomm buffer, 16             # 16 byte buffer
	.lcomm saverax, 8             # 8 byte buffer