/* 
 * add.s 
 * assemble with: as add.s -o add.o
 *
 * for pie with start files (args passed in registers) link with: gcc -z noexecstack add.o -o add
 * for pie with no start files (args passed on stack) link with: gcc -nostartfiles -z noexecstack add.o -o add
 * or using ld with: ld -pie -z noexecstack -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o add add.o -lc
*/

.intel_syntax noprefix

.extern printf

.set NOSTARTFILES, 1 # Comment when using gcc with startup files

.section .text

.ifdef NOSTARTFILES
    .global _start

    _start:

    cmp QWORD PTR [rsp], 2  # argc on the stack with no start files
.else
    .global main

    main:

    mov rcx, rdi			# rdi contains argc when link with gcc with start file
    cmp rcx, 2 
.endif

    jz NUM_ARGS_GOOD

    mov rax, 1			# write
    mov rdi, 1			# stdout
    lea rsi, USAGE[rip]
    mov rdx, OFFSET USAGE_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR ERROR_CODE[rip], 255	# error code
    jmp EXIT

NUM_ARGS_GOOD:

.ifdef NOSTARTFILES
    mov rdi, QWORD PTR [rsp + 16]       # argv[1]
.else
    lea rsi, [rsi + 8]
    mov rdi, QWORD PTR [rsi]            # argv[1]
.endif

    # call myatoi
    call adectohex

    test rax, rax               # if -1 then myatoi failed

    jns ARG1GOOD

    mov rax, 1			# write
    mov rdi, 1			# stdout
    lea rsi, ARGINVALID[rip]
    mov rdx, OFFSET ARGINVALID_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR ERROR_CODE[rip], 2	# error code
    jmp EXIT

ARG1GOOD:

    mov NUM1[rip], rax

    call adectohex

    lea rdi, buffer[rip]

    xor edx, edx    # clear out upper reg
    mov eax, 0x7b

    call hextodec

    lea rdi, OUT2[rip]
    xor eax, eax
    call printf@PLT

EXIT:
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

# adectohex subroutine 
# input string pointer passed in rdi
# returns result in rax
adectohex:
    xor eax, eax # zero out accumulator
NEXT_CHAR:
    movzx ecx, BYTE PTR [rdi] # get a character
    inc rdi # ready for next one
    cmp ecx, '0' # valid?
    jb DONE_adectohex
    cmp ecx, '9'
    ja DONE_adectohex
    sub ecx, '0' # "convert" character to number
    imul eax, 10 # multiply "result so far" by ten
    add eax, ecx # add in current digit
    jmp NEXT_CHAR # until done
DONE_adectohex:
    ret


/*
This works by dividing the number to convert by 10 (0xa), the remainder is the last digit and it converts that digit
to ascii by adding 0x30. It then saves it to rdi + rcx and rcx decrements so it starts with the last digit 
working towards the first digit. It is done when the division results in zero which means there is nothing left
to divide.

Somewhat issues, is that the since the length of the result is unknown, you have to start saving at the end of
the buffer, which means you don't know where the string starts at the end since address stored in rdi is
extremely likely not the beginning of the output string.

What could happen is once the conversion is done, move/copy the string to the location starting at rdi.
or
Return rdi + rcx + 1 which is the location where the first digit in the string is stored.

*/

# hextodec subroutine 
# output string pointer passed in rdi
# input value in rax
hextodec:
    mov ecx, 32
    mov BYTE PTR [rdi + rcx], 0 # null terminate
    dec ecx
    mov ebx, 0xa    # prepare for div

moretogo_hextodec:
    xor edx, edx    # clear out upper reg rdx:rax
    mov edx, 1      # Test

    test rax, rax   # if rax is 0 then we are done

    je DONE_HEXTODEC

    div ebx	    # divide rax by ebx, save result in rax and remainder in rdx

    add edx, 0x30   # rdx has remainder, add 0x30 to make ascii

    mov BYTE PTR [rdi + rcx], dl   # move converted value to string

    dec ecx

    jne moretogo_hextodec

DONE_HEXTODEC:

    lea rsi, [rdi + rcx + 1] 

    ret

.bss
    .lcomm buffer, 64             # 64 byte buffer

.section .data

   ERROR_CODE: .quad  0x0	

   NUM1: .quad 0x0
   NUM2: .quad 0x0

.section .rodata

   USAGE: .ascii "Usage: add <num1> <num2>\n"
   .set USAGE_LEN, . - USAGE

   OUTPUT: .asciz "%d + %d = %d\n"
   OUT2: .asciz "Your number is %s\n"

   ARGINVALID: .ascii "Arguments must be unsinged integers.\n"
   .set ARGINVALID_LEN, . - ARGINVALID


