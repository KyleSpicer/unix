/* 
 * converter.s 
 * assemble with: as converter.s -o converter.o
 *
 * for pie with start files (args passed in registers) link with: gcc -z noexecstack converter.o -o converter
 * for pie with no start files (args passed on stack) link with: gcc -nostartfiles -z noexecstack converter.o -o converter
 * or using ld with: ld -pie -z noexecstack -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o converter converter.o -lc
*/

.intel_syntax noprefix

.section .text
     .global CONVERT, my_strtol
     .set BUFFER_LEN, 256

CONVERT:
    enter 0, 0

     mov rax, 1          # write syscall
     mov rdi, 1          # set for stdout
     lea rsi, CONV_MESSAGE[rip]
     mov rdx, OFFSET CONV_MESSAGE_LEN
     syscall

     # receive input and save to INPUT_BUFFER
     mov rax, 0                    # read syscall
     mov rdi, 0                    # set stdin
     lea rsi, INPUT_BUFFER[rip]     # address of message to read
     mov rdx, BUFFER_LEN           # length of message
     syscall 

     lea rdi, INPUT_BUFFER[rip]
     mov QWORD PTR [rdi + rax - 1], 0

     push rsi                 # preserve rsi on stack
     call string_to_hex
     pop rsi                  # reinstate rsi to orginal

     cmp r10, -1              # compare return to -1
     je EXIT         # jump if equal (rax and -1)

     cmp rax, 0               # compare return to 0
     je EXIT         # jump if equal (rax and 0)

     mov r10, rax

    lea rdi, NEW_NUM[rip]

# hextodec subroutine 
# output string pointer passed in rdi
# input value in rax
hextodec:
    mov ecx, 64
    mov BYTE PTR [rdi + rcx], 0 # null terminate
    dec ecx
    mov rdx, rbx
    mov ebx, 0xa    # prepare for div

moretogo_hextodec:

    jz DONE_HEXTODEC

    div rbx
    mov r12, rax

    mov rax, rdx
    xor rdx, rdx
    div rbx
    mov r11, rax

    mov rax, r12
    shl rax, 64
    or  rax, r11

    add edx, 0x30   # rdx has remainder, add 0x30 to make ascii

    mov BYTE PTR [rdi + rcx], dl   # move converted value to string

    dec ecx

    jne moretogo_hextodec

DONE_HEXTODEC:
    lea rdx, [rdi + rcx + 1]

    lea rdi, OUTPUT[rip]
    lea rsi, INPUT_BUFFER[rip]
    xor eax, eax
    call printf@PLT

EXIT:
    leave
    ret

# procedure to convert a string to hexidecimal
string_to_hex:
     xor rax, rax        # zero out our counter register
     xor r11, r11

convert_stringtohex:
     inc r11

     cmp r11, 17
     je RESET

     movzx rsi, BYTE PTR [rdi]    # get current character
     test rsi, rsi                # check for \0
     je done_stringtohex          # returns if \0

     cmp rsi, 0x30       # anything less than 0 is invalid
     jl error_stringtohex

     cmp rsi, 0x39       # anything greater than 9 is invalid
     jle is_num

     # check for A - F characters (uppercase)
     cmp rsi, 0x41       # is it uppercase A
     jl error_stringtohex

     cmp rsi, 0x46       # is it uppercase F
     jle is_upper

     # check for a - f characters (lowercase)
     cmp rsi, 0x61       # is it lowercase A
     jl error_stringtohex

     cmp rsi, 0x66       # is it lowercase F
     jg error_stringtohex

     sub rsi, 0x20  # subtracts 32 from ascii code to make it lowercase

is_upper:
     sub rsi, 0x7  # converts ascii to its num val as hex digit between 10-15

is_num:
     sub rsi, 0x30       # subs 48 from num, converts num to hex value

is_valid:
     imul rax, 0x10       # multiply total by 16
     add rax, rsi        # add current digit to total
     inc rdi             # get address of next character
     jmp convert_stringtohex

error_stringtohex:
     mov r10, -1
     ret

done_stringtohex:
     mov r10, 0
     cmp r11, 17
     jl QUIT

     xchg rbx, rax

QUIT:
     ret

RESET:
    xor rbx, rbx
    xchg rbx, rax
    jmp convert_stringtohex 

.bss
     .lcomm INPUT_BUFFER, BUFFER_LEN 
     .lcomm NEW_NUM, 64 

.section .data

   ERROR_CODE: .quad  0x0	

   NUM1: .quad 0x0
   NUM2: .quad 0x0

.section .rodata

   USAGE: .ascii "Usage: converter <num1> <num2>\n"
   .set USAGE_LEN, . - USAGE

   CONV_MESSAGE: .ascii "Enter number: "
   .set CONV_MESSAGE_LEN, . - CONV_MESSAGE

   OUTPUT: .asciz "%s: %s\n"

   ARGINVALID: .ascii "Arguments must be unsigned integers.\n"
   .set ARGINVALID_LEN, . - ARGINVALID
