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

.ifdef NOSTARTFILES
    .global _start

    _start:

    push rbp
    mov rbp, rsp

    cmp QWORD PTR [rsp + 8], 2  # argc on the stack with no start files
.else
    .global main

    main:

    push rbp
    mov rbp, rsp

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
    mov rdi, QWORD PTR [rsp + 24]       # argv[1]
.else
    lea rdi, [rsi + 8]
    mov rdi, QWORD PTR [rdi]            # argv[1]
.endif

    push rsi
    call stringtohex
    pop rsi

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


    mov rcx, rax        # put converted value in rcx in prep for FIBO

# rax low order 64 bits accumulator
# rbx high order 64 bits accumulator   128 value is rbx:zrax current number in sequence

# r8 low order 64 bits what I am adding
# r9 high order 64 bits what I am adding   128 value is r9:r8  previous number in sequence

# rcx is going to be how many iterations

FIBO:
    # prepare registers
    xor rbx, rbx    # clear out rbx
    mov rax, 1      # Beginning sequence in fibo

    mov r9, rbx     # make r8:r9 same as rbx:rax
    mov r8, rax

FIBO_LOOP:

    add rax, r8     # Add two low order 64 bits
    adc rbx, r9     # Add with carry two high order 64 bits

    # rax:rbx is current number in sequence
    # r8:r9 is previous number in sequence

    xchg rax, r8    # mave the previous value with current value in preparation to do next addition loop
    xchg rbx, r9


    push rax    # Need to save rax and rcx since they are usesd by hextostring and write syscall
    push rcx

    mov rdi, rbx            # Get ready to convert rbx to string
    lea rsi, buffer[rip]    # Address of output buffer to save to

    call hextostring        # convert to string

    mov rax, 0x1            # sys_write
    mov rdi, 0x1            # stdout
    mov rdx, 16             # 16 characters
    syscall

    mov rdi, [rsp + 8]      # rax saved on stack, need to get it to output low order 64 bits
    lea rsi, buffer[rip]    # Address of output buffer

    call hextostring        # convert to string

    mov rax, 0x1            # sys_write
    mov rdi, 0x1            # stdout
    mov rdx, 16             # 16 characters
    syscall

    lea rsi, NEWLINE[rip]   # newline character
    mov rax, 0x1            # sys_write
    mov rdi, 0x1            # stdout
    mov rdx, 0x1            # 1 character '\n'
    syscall


    pop rcx                 # put rax and rcx back to the way they were
    pop rax

    dec rcx                 # dec rcx
    jne FIBO_LOOP           # keep going until rcx is 0



EXIT:
    pop rbp

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


# stringtohex subroutine 
# input string pointer passed in rdi
# returns result in rax
stringtohex:  
   xor rax, rax              # Set initial total to 0

convert_stringtohex:
    movzx rsi, BYTE PTR [rdi]   # Get the current character
    test rsi, rsi           # Check for \0
    je done_stringtohex
    
    # check for 0 - 9
    cmp rsi, 0x30           # Anything less than 0 is invalid
    jl error_stringtohex

    cmp rsi, 0x39           # Anything greater than 9 is invalid
    jle is_num

    # check for A - F
    cmp rsi, 0x41           # Is it an uppercase A
    jl error_stringtohex

    cmp rsi, 0x46           # Is it an uppercase F
    jle is_upper

    # check for a - f
    cmp rsi, 0x61           # Is it an lowercase a
    jl error_stringtohex

    cmp rsi, 0x66           # Is it an lowercase f
    jg error_stringtohex

    sub rsi, 0x20

is_upper:
    sub rsi, 0x7    

is_num:
    sub rsi, 0x30           # Convert from ASCII number to hex number

    imul rax, 0x10          # Multiply total by 16
    add rax, rsi            # Add current digit to total

    inc rdi                 # Advance the pointer to the next character
    jmp convert_stringtohex # Do it again until we run into a NULL

error_stringtohex:
    mov rax, -1             # Return -1 on error, need to find another way as a string ffffffffffffffff is determined to be signed when it is a valid unsigned value

done_stringtohex:
    ret                     # Return total or error code 



# hextostring subroutine 
# output string pointer passed in rdi
# input value in rdi
hextostring:
    mov rax, rdi

    push rax	# push rax in prep to pop in our conversion

    xor ecx, ecx    # Clear rcx as we are going to use it as a counter to walk though the nibbles and buffer

moretogo_hextostring:

    pop rax	# Retrieve the last saved rotated rax to get nibble to convert
    rol rax, 4  # Rotate shift left by a nibble
    
    push rax    # Save the state of the last shift 

    and rax, 0xf	# Chop of everything but the last nibble

    cmp rax, 0xa 	# Check to see if a number 

    js isnum

    add rax, 0x7	# difference between ascii number and uppecase ascii letter

isnum:
    add rax, 0x30	# add to make ascii number

    mov [rsi + rcx], rax

    inc rcx

    cmp rcx, 16
    jne moretogo_hextostring

    add rsp, 8  # realign stack due to push rax at the beginning of the function

    ret




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
