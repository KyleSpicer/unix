section .data
    message db "Hello World!", 10, 0

section .text
    global _start

_start:
    ; write the message to stdout
    mov eax, 4      ; system call for 'write'
    mov ebx, 1      ; file descriptor for stdout
    mov ecx, message    ; address of message to write
    mov edx, 14     ; length of message
    int 0x80        ; call kernel

    ; exit program
    mov eax, 1      ; system call for 'exit'
    xor ebx, ebx    ; return value of 0
    int 0x80        ; call kernel