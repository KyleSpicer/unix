; catshadow.asm
; written by Kenton Groombridge
; assemble with: nasm -f elf64 catshadow.asm
; link with ld -e main catshadow.o -o catshadow for non-pie
; link with gcc catshadow.o -o catshadow to make pie executable

global main

section .text

main:
  mov rax, 2      	; open syscall (see https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)
  lea rdi, [rel shadow] ; load adddress for shadow file path
  mov rsi, 0  		; flag 0 for O_RDONLY
  mov rdx, 0  		; 0 for mode since we aren't opening for writing (perms and such)
  syscall		; execute open
;
  test rax, rax         ; set flags
  mov [rel error], rax 	; save error code for program exit
  jl exit		; if negative, something went wrong

  mov [rel shadow_fd], rax ; save fd 

readloop:
  lea rsi, [rel buffer]   ; place address of the buffer in rsi
  mov rdx, 100            ; read up to 100 chars at a time (size of the buffer)
  mov rdi, [rel shadow_fd]           ; mov file descripter into rdi
  mov rax, 0		  ; sys_read syscall
  syscall		; execute read
  
  test rax,rax                ; test to verity positive (got something) or 0 (got nothing) or negative (error)
  mov [rel error], rax 	; save error code for program exit
  jle   done		; if negative (error) or 0 (nothing else to read), we are done, get out
  
  mov rdx, rax ;  amount of chars read in rdx to write out
  
  mov rax, 1 			; sys_write
  mov rdi, 1			; STDOUT
;  lea rsi, [rel buffer]	; load address of buffer in rsi, not needed since it is done in readloop and not changed
  syscall			; write buffer to stdout
  jmp readloop		; keep going

done:
  mov rdi, [rel shadow_fd]		; move fd to rdi
  mov rax, 3		; close
  syscall		; execute close file

exit:
  mov rax, 60       ; exit syscall
  mov rdi, [rel error]        ; error message in a Linux shell means all worked well
  neg rdi		; two's compliment the negative number to obtain the error code
  syscall           ; execute exit syscall

section .rodata
  shadow: db "/etc/shadow", 0
 
section .data
  error: dq 0
  buffer: times 100 db 0
  shadow_fd: dw 0
