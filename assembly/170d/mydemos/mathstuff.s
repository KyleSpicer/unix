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
    xor bx, bx         # clear out bx
    mov ax, 0xffff     # start with largest unsigned 16 bit number
    add ax, 0x1        # cause a carry from the add
    adc bx, 0          # carry counts as one, so bx will have 1 from the carry
                       # Think of it this way, not enough room in ax, then continue in bx so the full number would be 0x00010000 (0xffff + 0x1)

    xor bx, bx         # clear out bx
    mov ax, 0x7fff     # start with largest 16 bit signed number
    add ax, 0x1        # add one which makes the result a negative number (high order bit set to 1) this sets overflow flag

    mov ax, 0x8000     # start with a smallest signed 16 bit number -0x7fff (one's compliment)
    sub ax, 0x1        # subtract one which will make the result a positive number (high order bit set to 0) this sets the overflow flag

    xor bx, bx         # clear out bx
    mov ax, 0x10       # Move 16 into ax
    sub ax, 0x16       # Subtract 22 from ax (sets carry flag)
    sbb bx, 0x0        # subtract with borrow (carry flag)
                       # bx is 0x0 and ax is 0x10 or combined 0x00000010, subtract 0x16 and get a signed 0xfffffffa or -6 (two's compliment)

    mov ax, 2          # put 2 in ax
    mov bx, 0x20       # put 32 in bx
    mul bx             # mul in this fashion multiplies ax and bx and saves the low order bits to ax and the high order bits to dx as multiplying large numbers can cause overflow

    mov ax, 0x7fff     # Put a large number in ax
    mov bx, 0x20       # put 32 in bx
    mul bx             # demonstrate that high order bits of the multiply are saved in dx

#    mov ax, 2          # put 2 in ax
#    mul ax, 0x20       # Multiply ax by 32 and store back in ax ; immediate values don't work with mul, but will with imul

    mov ax, -2         # -2 is 0xfffe (two's compliment)
    mov bx, 0x20       # put 32 in bx
    imul bx            # imul in this fashion multiplies ax and bx and saves the low order bits to ax and the high order bits to dx as multiplying large numbers can cause overflow

    mov ax, -0x7ffe    # put a large negative number in ax
    mov bx, 0x20       # put 32 in bx
    imul bx            # demonstrate that high order bits of the multiply are saved in dx

    mov ax, -2         # -2 is 0xfffe (two's compliment)
    imul ax, 0x20      # Multiply ax by 32 and store back in ax

    xor dx, dx         # clear out dx since div uses the dx for high order bits
    mov ax, 0x20       # put 32 in ax
    mov bx, 0x3        # put 3 in bx
    div bx             # div places div result in ax and remainder in dx

#    mov ax, 0x20       # put 2 in ax
#    div ax, 0x3        # Divide ax by 3 and store back in ax ; like mul, immediate values don't work with div, but will with idiv

    mov ax, -0x20      # put -32 in ax 
    cwde               # expand signed bit to eax
    cdqe               # expand signed bit to rax
    cqo                # expand signed bit to rdx
    mov bx, 0x3        # put 3 in bx
    idiv bx            # idiv places div result in ax and remainder in dx

    mov rdi, 0         # exit with code 0 (all is good)
    mov rax, 60        # exit syscall
    syscall            # execute exit syscall
