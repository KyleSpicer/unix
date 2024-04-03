.intel_syntax noprefix

.equ BUFFER_LEN, 20

 .global _start        #must be declared for using gcc

.section .text
	
_start:	                #tell linker entry point
   mov	ecx, BUFFER_LEN 	# repeat command this number of times
   lea	rdi, s1[rip]	# source data
#   lea	rdi, s2[rip]	# destination buffer
   xor eax, eax		# zero out A as we will use al to look for null byte in string
  # inc ecx		# experiment to watch flags in gdb

   cld			# clear direction flag to increment up rsi, rdi, std will increment them down
   
   repne	scasb		# move source to destination one byte at a time, decrement cx and stop when it is zero
	
   mov eax, 1           # sys_write
   mov edi, eax         # File descriptor
   lea rsi, s2[rip]     #message to write
   mov  edx, OFFSET len #message length
   syscall

   mov rax, 60          # sys_exit
   xor edi, edi         # no error 0
   syscall

.section .rodata
   s1: .asciz  "HELLO, WORLD"   #source
   .set len, . - s1

.section .bss
   .lcomm s2 BUFFER_LEN              #destination

