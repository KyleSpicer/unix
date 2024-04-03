; hello.asm
; written by Kenton Groombridge
; assemble with: nasm -f elf64 hello.asm
; link with ld -e main hello.o -o hello for non-pie
; link with gcc hello.o -o hello to make pie executable

global main

section .text

main:
  mov rax, 1        ; write(
  mov rdi, 1        ;   STDOUT_FILENO,
  lea rsi, [rel msg]      ; or mov rsi, msg  ; "Hello, world!\n"
  mov rdx, msglen   ;   sizeof("Hello, world!\n")
  syscall           ; );

  mov rax, 60       ; exit(
  mov rdi, 0        ;   EXIT_SUCCESS
  syscall           ; );

section .rodata
  msg: db "Hello, world!", 10
  msglen: equ $ - msg
