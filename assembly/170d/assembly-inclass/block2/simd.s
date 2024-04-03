/*
 * simd.s
 * Written by Kenton Groombridge
 * Assemble with: as simd.s -o simd.o
 * Link with: ld -g -pie -z noexecstack -e _start -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o simd simd.o -lc
 */

.intel_syntax noprefix

.extern printf

.global _start  # must be declared for the linker to find program entry point

.section .text
	
_start:         # tell linker entry point

    # This will move 128 bits from FloatArray1, which are both float numbers
    lea rax, FloatArray1[rip]
    movapd xmm0, [rax]

    /*
     * This is valid for non-pie executables. Replace the previous two
     * instructions with:
     */
    # movapd xmm0, FloatArray1

     # This will move 128 bits from FloatArray2, which are both float numbers
    lea rax, FloatArray2[rip]
    movapd xmm1, [rax]

    /*
     * This is valid for non-pie executables. Replace the previous two
     * instructions with:
     */
    # movapd xmm1, FloatArray2

    /* This will add the lower portion of xmm1 to the lower portion of xmm0
     * and add the upper portion of xmm1 to the upper portion of xmm0
     */
    addpd xmm0, xmm1

    /* This is an iteresting command. Since doubles are 64 bit, and the xmm
     * registers are 128 bit, we are using the upper and lower 64 bits of the
     * xmm registers. The addition of 1.0 and 3.0 ends up in the lower portion
     * of xmm0, but we need to get the high order portion of xmm0 to the low
     * order portion of xmm1 for printf to display it. This command, as
     * presented, moves the high order portion of xmm0 to the low order
     * portion of xmm1.
     */
    movhlps xmm1, xmm0

    lea rdi, FORMAT[rip]

    /* We have floats/doubles to display, I have read that this value
     * represents the number of floats to be displayed by printf, but I
     * have found that it just needs to be 0 for no floats, and non-zero for
     * floats.
     */
    mov eax, 1

    call printf@PLT

    mov rax, 60          # sys_exit
    xor edi, edi         # no error 0
    syscall

.section .rodata
.align 4 # Must for using movapd above 2^4 or 16 byte alignment.
   FloatArray1:
       .double  1.0,2.0

   FloatArray2:
       .double  3.0,4.0

   FORMAT: .asciz "%f %f\n"

