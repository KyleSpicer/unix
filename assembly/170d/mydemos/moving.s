# cbw, cwd, cwde, cdq, cdqe, cqo demo
# assemble with as convert.s -o convert.o
# link with ld convert.o -o convert
# To make PIE
# assemble with: gcc -c -fPIE moving.s
# link with: gcc -nostdlib -Wl,-e_start moving.o -o moving


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
    mov ax, 0xff       # Set ax and bx to 0xff
    mov bx, ax      
    shl rax, 48        # move ax lower order bits into the upper 32 bits
    movzx rax, bl      # move bx (16 bits) into rax (64 bits) and zero out everything above the 16 bits (don't propagate signed bit)
    shl rax, 48	       # move ax lower order bits into the upper 32 bits
    movsx rax, bl      # move bx (16 bits) into rax (64 bits) and propagate signed bit from the source
    test ax, ax        # set flags
    cmove rbx, rax     # if ax were zero then it would move rax into rbx
    lea rbx, [rip + skipover] # load skipover memory address into rbx
    xchg rbx, rax     # swap rax and rbx registers
    mov QWORD PTR [rip + buffer], 0x1 # Move 64 bit value
    mov DWORD PTR [rip + buffer + 8], 0x2 # Move 32 bit value to area just past where previous instruction saved
skipover:
    mov rax, 60       # exit syscall
    syscall           # execute exit syscall

.data
buffer: .zero 20
