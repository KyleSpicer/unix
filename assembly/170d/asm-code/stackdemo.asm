; stackdemo.asm
; written by Kenton Groombridge
; demo accessing the stack outside of the bp and sp
; x86_64 uses syscall instead of int 80 on x86
;     see https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/
; assemble with: nasm -f elf64 stackdemo.asm
; link with ld stackdemo.o -o stackdemo

global _start

section .text

_start:
  mov rbx, 4
  push rbx
  pop rbx
  mov rcx, [rsp-8]
  add rcx, 0x30
  mov byte [value], cl
  mov rax, 1        ; write(
  mov rdi, 1        ;   STDOUT_FILENO,
  mov rsi, output     
  mov rdx, 15   ;   length of string
  syscall        

  mov rax, 60       ; exit(
  mov rdi, 0        ;   EXIT_SUCCESS
  syscall           ; );

section .data
  output: db "The value is "  
  value: db " "
  terminator: db 0x0a
