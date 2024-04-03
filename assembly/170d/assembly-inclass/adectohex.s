# adectohex subroutine 
# input string pointer passed in rdi
# returns result in rax
adectohex:
    xor eax, eax # zero out accumulator
NEXT_CHAR:
    movzx ecx, BYTE PTR [rdi] # get a character
    inc rdi # ready for next one
    cmp ecx, '0' # valid?
    jb DONE_adectohex
    cmp ecx, '9'
    ja DONE_adectohex
    sub ecx, '0' # "convert" character to number
    imul eax, 10 # multiply "result so far" by ten
    add eax, ecx # add in current digit
    jmp NEXT_CHAR # until done
DONE_adectohex:
    ret
