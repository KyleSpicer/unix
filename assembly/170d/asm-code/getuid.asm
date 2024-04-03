; getuid.asm
; written by Kenton Groombridge
; assemble with: nasm -f elf64 getuid.asm
; link with:
;    ld -pie -z noexecstack -e main -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o getuid getuid.o -lc


extern printf

global main

section .text

main:
  mov rax, 102      ; getuid syscall (see https://filippo.io/linux-syscall-table/)
  syscall

  mov rsi, rax      ; move the returned uid in rax to rsi (the %d required by printf)

  lea rdi, [rel output]   ; load address of printf output string in rdi using rel for PIE executable
  mov al, 0               ; magic for varargs (0==no magic, to prevent a crash!)
  call printf wrt ..plt   ; wrt ..plt needed for PC-relative relocation generation required by PIE
;
  mov rax, 60       ; exit syscall
  mov rdi, 0        ; 0 in a Linux shell means all worked well
  syscall           ; perform exit syscall

section .rodata
  output: db "%d", 0x0a, 0
