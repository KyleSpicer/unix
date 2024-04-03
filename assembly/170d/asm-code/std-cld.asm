; std-cld.asm
; written by Kenton Groombridge
; assemble with: nasm -f elf64 std-cld.asm
; link with ld std-cld.o -o std-cld



global _start

section .text

_start:
main:
  std              ; set direction flag, highest to lowest
  cld              ; clear direction flag, lowest to highest

  lea rsi, [s1_msg] ; load address of s1 in esi (source) 
  lea rdi, [buffer] ; load address of buffer in edi (destination)
  mov rcx, s1_len  ; number of bytes to copy

  rep movsb
;
  mov rax, 60       ; exit syscall
  mov rdi, 0        ; 0 in a Linux shell means all worked well
  syscall           ; perform exit syscall

section .rodata
  s1_msg: db "String one", 0x0a
  s1_len: equ $ - s1_msg
  s2_msg: db "String two", 0x0a
  s2_len: equ $ - s2_msg

section .data
  buffer: times 100 db 0

