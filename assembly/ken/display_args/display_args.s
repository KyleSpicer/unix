/*
 * display_args.s
 *
 * assemble with: as display_args.s -o display_args.o
 *
 * description:
 *
 * for pie with start files (args passed in registers) link with:
 * gcc -z  noexecstack display_args.o -o display_args
 *
 * for pie with nostartfiles (args passed on stack) link with: 
 * gcc -nostartfiles -z noexecstack display_args.o -o display_args
 * or using ld with: ld -pie -z noexecstack -dynamic-linker /lib64/ld-linux-  
 * x86.so.2 -o display_args display_args.o -lc
*/

.intel_syntax noprefix

.section .text
     .global main

main:
        push    rbx                             # stash used callee
        enter   24, 0                           # make 24 byte stack space
                                                # 24 + push == 32 byte alignment
        mov     QWORD PTR -8[rbp], rdi          # stash argc on stack
        mov     QWORD PTR -16[rbp], rsi         # stash argv on stack
        mov     rsi, rdi                        # mov argc to arg1
        lea     rdi, QWORD PTR .argc_print[rip] # load string for printf
        call    printf

        xor     rbx, rbx                        # zero callee to avoid printf
.ARGVS:
        lea     rdi, QWORD PTR .argv_print[rip] # put string address in arg0
        mov     rsi, rbx                        # move counter into arg1
        mov     rdx, QWORD PTR -16[rbp]         # get dbl ptr
        mov     rdx, QWORD PTR[rdx + (8 * rbx)] # deref dbl ptr + (8 * counter)
        call    printf
        inc     rbx                             # increment counter
        cmp     QWORD PTR -8[rbp], rbx          # compare argc to counter
        jg      .ARGVS                          # jump if argc > counter

        leave                                   # clean up stack and rsp/rbp
        pop     rbx                             # put calle back how we found
        xor     rax, rax                        # set return code to 0
        ret


.section .data
        .argc_print: .asciz "argc = %lu\n"

        .argv_print: .asciz "argv[%lu] = %s\n"


