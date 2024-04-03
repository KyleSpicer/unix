; stack.asm
; assemble with: nasm -f elf64 stack.asm
; link with ld stack.o -o stack

global _start

_start:
main:
    mov rax, 16
    push rax
    jmp mem2
    
mem1:
    mov rax, 0
    ret
    
mem2:
    pop r8
    cmp rax, r8
    je mem1
