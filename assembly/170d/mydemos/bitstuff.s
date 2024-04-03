# Flag info:
#Carry Flag is a flag set when:
#
#a) two unsigned numbers were added and the result is larger than "capacity" of register where it is saved. Ex: we wanna add two 8 bit numbers and save result in 8 bit register. In your example: 255 + 9 = 264 which is more that 8 bit register can store. So the value "8" will be saved there (264 & 255 = 8) and CF flag will be set.
#
#b) two unsigned numbers were subtracted and we subtracted the bigger one from the smaller one. Ex: 1-2 will give you 255 in result and CF flag will be set.
#
#Auxiliary Flag is used as CF but when working with BCD. So AF will be set when we have overflow or underflow on in BCD calculations. For example: considering 8 bit ALU unit, Auxiliary flag is set when there is carry from 3rd bit to 4th bit i.e. carry from lower nibble to higher nibble. (Wiki link)
#
#Overflow Flag is used as CF but when we work on signed numbers. Ex we wanna add two 8 bit signed numbers: 127 + 2. the result is 129 but it is too much for 8bit signed number, so OF will be set. Similar when the result is too small like -128 - 1 = -129 which is out of scope for 8 bit signed numbers.
#
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
    mov rbx, 0x900     # Simple number with two bits set 

    bsf rax, rbx       # Find the least significant 1 bit in the source operand. Reports the index in destination. Destination content is undefined if source is zero. Sets the zero flag if source is zero.

    bsr rax, rbx       # Find the most significant 1 bit in the source operand. Reports the index in destination. Sets the zero flag if source is zero

    lzcnt rax, rbx     # count the number of leading zeros.

    mov rbx, -1        # Make rbx 0xffffffffffffffff
    mov rcx, 16        # Number of high bits to zero out
    bzhi rax, rbx, rcx # Zero High Bits Starting with Specified Bit Position rcx - num bits, rbx - number to zero high bits, rax - result

    mov rbx, 0x900
    tzcnt rax, rbx      # Count the Number of Trailing Zero Bits. Same as BSF except that destination is not undeefined if source is zero. Destination holds operand size if source is zero.

    mov ax, 0x1
    bt ax, 0x0          # test the low order bit of ax (binary 1), sets the carry flag
    bt ax, 0x1          # test the second low order bit of ax (binary 0), clears the carry flag

    btc ax, 0x0         # test the low order bit of ax (binary 1), sets the carry flag, then flip the tested bit (now binary 0)
    btc ax, 0x1         # test the second low order bit of ax (binary 0), clears the carry flag, then flip the tested bit (now binary 1)

    btr ax, 0x0         # test low order bit of ax (binary 0), clears the carry flag, clears the bit (remains binary 0)
    btr ax, 0x1         # test the second low order bit of ax (binary 1), sets the carry flag, clears the bit (now binary 0)

    mov ax, 0xffff
    mov bx, 0xabcd
    and ax, bx

    mov ax, 0xffff
    mov WORD PTR [bss_mem], 0xffff
    and WORD PTR [bss_mem], 0xabcd

    mov ax, 0xffff
    lea rbx, bss_mem
    mov WORD PTR [rbx], 0xabcd
    and ax, WORD PTR [rbx]

    mov ax, 0x0a0b
    mov bx, 0xc0d0
    or  ax, bx

    mov ax, 0xabcd
    mov bx, 0x0123
    xor ax, bx
    xor ax, ax       # nice way to clear a register
  
    mov eax, 0x3 
    not eax          # Just flip the bits

    mov eax, 0x3
    neg eax          # Two's compliment eax

    mov rax, 0x1
    shl rax
    shl rax, 0x1
    shl rax, 0x2

    shr rax
    shr rax, 0x1
    shr rax, 0x2

    mov eax, 0x80000000
    sar eax
    sar eax, 0x1
    sar eax, 0x2


#    and                # If source and destination have a 1 bit in the same position, then destination will have that same bit set. Overflow and carry flags are always cleared by this instruction.
#    andn               # Inverts the value of the second operand then performs a bitwise AND with the third operand. AF and PF flags are undefined. Overflow and carry flags are always cleared.
#    or                 # If either source or destination have a 1 bit in the any position, then destination will have that same bit set. Overflow and carry flags are always cleared by this instruction.
#    xor                # Destination will have a bit set if source and destination have different values for that position. Overflow and carry flags are always cleared by this instruction.
#    not                # Each 1 bit in destination becomes 0. Each 0 bit becomes 1.
#    neg                # Subtract the destination from zero. Store the result in destination

    mov rdi, 0         # exit with code 0 (all is good)
    mov rax, 60        # exit syscall
    syscall            # execute exit syscall

.section .bss
.lcomm bss_mem 2
