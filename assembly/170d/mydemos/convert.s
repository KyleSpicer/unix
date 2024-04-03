# cbw, cwd, cwde, cdq, cdqe, cqo demo
# assemble with as convert.s -o convert.o
# link with ld convert.o -o convert

# Question:
# Why is it that the signed bit is propagated through the higher bits properly, but when a '0' bit
# is in position 31, it zeros out the upper 32 bits of a 64 bit register?

# The Intel documentation (3.4.1.1 General-Purpose Registers in 64-Bit Mode in manual Basic Architecture)

#        64-bit operands generate a 64-bit result in the destination general-purpose register.
#        32-bit operands generate a 32-bit result, zero-extended to a 64-bit result in the destination general-purpose register.
#        8-bit and 16-bit operands generate an 8-bit or 16-bit result. The upper 56 bits or 48 bits (respectively) of the destination general-purpose register are not be modified by the operation. If the result of an 8-bit or 16-bit operation is intended for 64-bit address calculation, explicitly sign-extend the register to the full 64-bits.

.intel_syntax noprefix
.section .text
.global _start

_start:
    mov al, 0xff      # start with signed number (high order bit is '1'
                      # these instructions shift the signed bit up to the requested size
    cbw               # convert byte to word al to ah
    cwde              # convert word to double word ax to eax
    cdqe              # convert double word to quad word eax to rax
                      # rax already has -1 in it
    mov eax, 0x0
    mov al, 0x7f      # start with unsigned number (high order bit is '0'
    cbw               # convert byte to word al to ah
    cwde              # convert word to double word ax to eax
    cdqe              # convert double word to quad word eax to rax
    
    mov rax, 0x8000   # start with 16 bit value with signed bit set
    
                      # these instructions take the signed bit from ax and propagate that bit in the d register to the requested size
    cwd               # take signed bit from ax and create word in dx of that signed bit
    shl rax, 16       # move signed bit from ax to eax
    cdq               # take signed bit from eax and create word in edx of that signed bit
    shl rax, 32       # move signed bit from eax to rax
    cqo               # take signed bit from rax and create quad word in rdx of that signed bit

    mov rax, 60       # exit syscall
    syscall           # execute exit syscall
