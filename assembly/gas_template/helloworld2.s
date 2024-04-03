# helloworld2.s written by Kyle Spicer

.intel_syntax noprefix # Default for GNU as is ATT syntaxc

.global _start

.set BUFFER_LEN, 1024

.text
     
_start:

     # write the message "Enter your name: " to stdout
     mov rax, 1                    # system call for "write"
     mov rdi, 1                    # file descriptor for stdoutls
     lea rsi, message[rip]         # address of message to write
     mov rdx, OFFSET message_len   # length of message
     syscall                       # call kernel

     # receive input from user and write to rsi
     mov rax, 0                    # system call for 'read'
     mov rdi, 0                    # file descriptor for stdin
     lea rsi, buffer[rip]          # address of message to read
     mov rdx, BUFFER_LEN           # length of message
     syscall

     # display "Hello "
     mov rax, 1                    # system call for 'write'
     mov rdi, 1                    # fd for stdout
     lea rsi, hello[rip]           # address of message to write
     mov rdx, OFFSET hello_len     # length of message
     syscall                       # call kernel

     # display user input to stdout
     mov rax, 1                    # system call for 'write'
     mov rdi, 1                    # file descriptor for stdout
     lea rsi, buffer[rip]          # address of message to write
     mov rdx, BUFFER_LEN                   # length of message
     syscall

     # exit program
     mov rax, 60         # system call for 'exit'
     mov rdi, 0          # return value of 0
     syscall             # call kernel


.data # initialized data section
     message: .ascii "Enter your name: "
     .set message_len, . - message

     hello: .ascii "Hello "
     .set hello_len, . - hello

.bss # uninitialized data section
     .lcomm buffer, BUFFER_LEN
     .lcomm buffer2, 64
     