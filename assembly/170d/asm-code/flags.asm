; flags.asm
; written by Kenton Groombridge
; demo the zero flag
; x86_64 uses syscall instead of int 80 on x86
;     see https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/
; assemble with: nasm -f elf64 flags.asm
; link with ld flags.o -o flags

global _start

section .text

_start:
main:
    mov rax, 0
    jne notequaltozero
equaltozero:
    mov rax, 1 ; write
    mov rdi, 1 ; stdout file descriptor
    mov rsi, equaltozeromessage
    mov rdx, equaltozeromessagelen
    syscall
    jmp overothermessage
    
notequaltozero:
    mov rax, 1 ; write
    mov rdi, 1 ; stdout file descriptor
    mov rsi, notequaltozeromessage
    mov rdx, notequaltozeromessagelen
    syscall
    
overothermessage:
    mov rax, 60 ; sys_exit
    syscall
    

section .rodata
    equaltozeromessage: db "Equal to zero", 10
    equaltozeromessagelen: equ $ - equaltozeromessage
    notequaltozeromessage: db "Not equal to zero", 10
    notequaltozeromessagelen: equ $ - notequaltozeromessage
