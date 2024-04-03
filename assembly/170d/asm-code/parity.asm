; parity.asm
; written by Kenton Groombridge
; assemble with: nasm -f elf64 parity.asm
; link with ld parity.o -o parity



global _start

section .text

_start:
main:
; Rewrite this to take a number from stdin and determine parity  maybe a pushf and popx then mask then display the value of the parity flag
  mov rax, 3        ; Number to check parity on
  test rax, rax     ; Set flags based on the contents of rax
  jpo po            ; Load parity odd message and display
  lea rsi, pe_msg   ; Load address of "Parity even" in rsi (same as mov rsi, pe_msg)
  mov rdx, pe_len   ; Length of "Parity even" message in rdx)
  jmp pe            ; Jump over load "Parity odd" message
po:
  lea rsi, po_msg
  mov rdx, po_len
pe:
  mov rdi, 1        ; STDOUT_FILENO
  mov rax, 1
  syscall           ; Perform write syscall
;
  mov rax, 60       ; exit syscall
  mov rdi, 0        ; 0 in a Linux shell means all worked well
  syscall           ; perform exit syscall

section .rodata
  po_msg: db "Parity is odd", 0x0a
  po_len: equ $ - po_msg
  pe_msg: db "Parity is even", 0x0a
  pe_len: equ $ - pe_msg
