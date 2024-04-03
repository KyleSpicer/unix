; stack_check.s
; written by Kenton Groombridge
; compile and link with
; nasm -f elf64 flags.asm 
; ld -o flags flags.o 

global _start

section .text

_start:

  mov eax,0x77
  mov ebx,0x99
  mov ecx,0x55

  push eax
  push ecx
  pop ebx
  push eax
  pop ecx
  pop eax

