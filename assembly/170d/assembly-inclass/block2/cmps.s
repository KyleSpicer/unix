.intel_syntax noprefix

.global _start        # must be declared for linking

.extern printf

.section .text
	
_start:	                # tell linker the entry point
   mov  rbp, rsp	# Set rbp to valid memory location so function calls like printf work

# First cmp of same strings

   mov	ecx, OFFSET len_s1 	# repeat command this number of times, length of source string
   lea	rdi, s1[rip]	# source data
   lea	rsi, s2[rip]	# destination data

   cld			# clear direction flag to increment up rsi, rdi, std will increment them down
   
   repe	cmpsb		# move source to destination one byte at a time, decrement cx and stop when it is zero

   lea rsi, s1[rip]
   lea rdx, s2[rip]
   lea rcx, S_SAME[rip]

   jne DIFFERENT_1	# lea instructions don't affect flags

   lea rcx, S_SAME[rip]

   jmp PRINT_MESSAGE_1
   
DIFFERENT_1:
   lea rcx, S_DIFFERENT[rip]

PRINT_MESSAGE_1:
   lea rdi, FORMAT_STRING[rip]

   call printf@PLT

# Second cmp of different strings

   mov	ecx, OFFSET len_s1 	# repeat command this number of times, length of source string
   lea	rdi, s1[rip]	# source data
   lea	rsi, s3[rip]	# destination data

   cld			# clear direction flag to increment up rsi, rdi, std will increment them down
   
   repe	cmpsb		# move source to destination one byte at a time, decrement cx and stop when it is zero

   lea rsi, s1[rip]
   lea rdx, s3[rip]
   lea rcx, S_SAME[rip]

   jne DIFFERENT_2	# lea instructions don't affect flags

   lea rcx, S_SAME[rip]

   jmp PRINT_MESSAGE_2
   
DIFFERENT_2:
   lea rcx, S_DIFFERENT[rip]

PRINT_MESSAGE_2:
   lea rdi, FORMAT_STRING[rip]

   call printf@PLT

   mov rax, 60          # sys_exit
   xor edi, edi         # no error 0
   syscall

.section .rodata
   s1: .asciz  "HELLO, WORLD"   #source
   .set len_s1, . - s1

   s2: .asciz  "HELLO, WORLD"   #destination match
   .set len_s2, . - s2

   s3: .asciz  "HELLO, WORLd"   #destination not match
   .set len_s3, . - s3

   S_SAME: .asciz "same"

   S_DIFFERENT: .asciz "different"

   FORMAT_STRING: .asciz "String: '%s' and string '%s' are %s\n"
