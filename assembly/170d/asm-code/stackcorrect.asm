; stack.asm
; assemble with: nasm -f elf64 stack.asm
; link with ld stack.o -o stack

global _start

_start:
main:
	mov rax, 5
	push rax
	mov rax, 1
	push rax
	pop r12
	pop r13
loop:
	add r12, 1
	cmp r12, r13
	jl loop
	mov rax, 0
	ret
