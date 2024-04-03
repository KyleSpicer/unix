.intel_syntax noprefix

.equ BUFFER_LEN, 32

.global _start        # must be declared for linking

.extern printf

.section .text
	
_start:	                # tell linker the entry point
   mov  rbp, rsp	# Set rbp to valid memory location so function calls like printf work

# First cmp of same strings
   mov ecx, OFFSET len_source	# Use cx as a counter

   lea	rsi, source[rip]	# source data
   lea	rdi, destination[rip]	# destination data

   cld			# clear direction flag to increment up rsi, rdi, std will increment them down

OVER:
   lodsb
   stosb

   dec ecx
   jne OVER

   lea rdi, FORMAT_STRING[rip]
   lea rsi, source[rip]
   lea rdx, destination[rip]

   call printf@PLT

   mov rax, 60          # sys_exit
   xor edi, edi         # no error 0
   syscall

.section .rodata
   source: .asciz  "HELLO, WORLD"   #source
   .set len_source, . - source

   FORMAT_STRING: .asciz "Source string: '%s', destination string '%s'\n"

.section .bss
   .lcomm destination BUFFER_LEN              #destination

