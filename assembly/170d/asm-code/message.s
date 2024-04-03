; message.s
; written by Kenton Groombridge
; compile and link with
; nasm -f elf64 -o message.o message.s
; ld -o message message.o

; %rax	System call	%rdi	%rsi	%rdx
; 1	sys_write	unsigned int fd	const char *buf	size_t count

.intel_syntax noprefix
.global _start

.section .text

_start:

  mov rax, 0x1      # sys_write syscall
  mov rdi, 0x1      # stdout
  lea rsi, [message]  # put address of message in rsi
  # mov rsi, message

  mov rdx, msg_len    # length of message
  syscall

  mov rax, 60       # 64 bit exit syscall intel
#  mov $60,rax       # 64 bit exit syscall att

  mov rdi, 5        # 0 return code (success)
  syscall

.section .rodata
message:
  .ascii  "Hey You!\n"

msg_len:
  .quad    . - message       # length of the message string

