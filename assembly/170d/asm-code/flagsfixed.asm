; flagsfixed.s
; written by Kenton Groombridge
; compile and link with
; nasm -f elf64 -o flagsfixed.o flagsfixed.s
; ld -o flagsfixed flagsfixed.o


global _start

section .text

_start:
  mov rax, 0               ; Move 0 to rax
  and rax,rax              ; Set flags *****
  jnz printnotzeromessage
  mov rax, 1               ; 64 bit write syscall
  mov rdi, 1               ; STDOUT file descriptor
  mov rsi, zerosetmsg      ; Address of zero flag set message  
  mov rdx, zerosetmsglen   ; Length of zero flag set message
  syscall
  jmp exit

printnotzeromessage:
  mov rax, 1                  ; 64 bit write syscall
  mov rdi, 1                  ; STDOUT file descriptor
  mov rsi, zeronotsetmsg      ; Address of zero flag not set message 
  mov rdx, zeronotsetmsglen   ; Length of zero flag not set message)
  syscall

exit:
  mov rax, 60       ; 64 bit exit syscall
  mov rdi, 0        ; 0 return code (success)
  syscall

section .rodata
  zerosetmsg: db "Zero flag set", 10
  zerosetmsglen: equ $ - zerosetmsg
  zeronotsetmsg: db "Zero flag not set", 10
  zeronotsetmsglen: equ $ - zeronotsetmsg
