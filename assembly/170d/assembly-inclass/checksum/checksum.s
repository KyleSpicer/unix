/* 
 * checksum.s
 * Written by Kenton Groombridge 
 * assemble and link with: gcc -z noexecstack checksum.s -o checksum
 *
 * Creates a simple 16 bit checksum and appends to the file when using the -e option
 * Validates and removes the simple 16 bit checksum from the end of the file when using the -d option
 * If the checksum validaton fails, the file remains unchanged
*/

.intel_syntax noprefix

.set ARGV, 8
.set FILESIZE, 16
.set CHECKSUM, 24
.set FD_FILE, 32
.set BUFFER, 40
.set ERROR_CODE, 48

.section .text

.global main

main:
    enter 48, 0

    mov [rbp - ARGV], rsi                # save *argv[], rbp - 8
 
    mov rcx, rdi			# rdi contains argc when link with gcc with start file
    cmp rcx, 3 

    jnz NUM_ARGS_BAD        # if numbers of args is not 4, then display usage message and get out

    # Get argv[1]
    mov rdi, [rbp - ARGV]           # retrieve *argv[]

    mov rdi, [rdi + 8]              # argv[1]

# The following two instructions do the same thing as the previous instruction. The previous instruction is PIE
# compatible because the instruction it uses a register to access memory rather than an abosolute address.
# "lea" doesn't reference the memory location, it is just an address calculator. Intel used the [] on it, 
# and made it a bit confusing.
#   lea rdi, [rdi + 8]			    # ROT_VAL
#   mov rdi, QWORD PTR [rdi]        # argv[1]

    cmp BYTE PTR [rdi], '-'                  # Test first char for switch
    jne SWITCHINVALID

    cmp BYTE PTR [rdi + 2], 0                # Test what should be last char for NULL
    jne SWITCHINVALID

    cmp BYTE PTR [rdi + 1], 'd'              # Test switch value for d - decode
    je  DECODE

    cmp BYTE PTR [rdi + 1], 'e'              # Test switch value for e - encode
    je ENCODE
  
    jmp SWITCHINVALID               # If the above doesn't match "-d" or "-e", then arg was invalid

DECODE:
    mov ebx, 0                      # 0 in ebx means decode
    jmp OPENFILES

ENCODE:
    mov ebx, 1                      # 1 in ebx means encode
    
OPENFILES:
    # Attempt to open <infile>
    mov rdi, [rbp - ARGV]           # Retrieve *argv[]

    lea rdi, [rdi + 16]			    # <infile> name
    mov rdi, QWORD PTR [rdi]        # argv[2]

    mov rax, 0x2                # open syscall
    mov rsi, rax                # O_RDWR is 2 as well
    xor rdx, rdx                # mode in rdi is 0 since not creating a file
    syscall

    test rax, rax               # Set flags from open syscall
    js ERROR_FILE_OPEN          # Error opening <infile>

    mov [rbp - FD_FILE], rax    # save <infile> fd to stack

    # Prepare to do checksum stuff
    xor r12d, r12d              # Clear out r12 as it will be used to calculate our checksum later

    test ebx, ebx               # 0 is decode, 1 is encode
    jne DOCHECKSUM

    # If we got here then we need to decode. Lets read the checksum (last two bytes)
    # from the file, and resize it to make easier to read so we don't read in the
    # checkum and calculate with it.

    mov rax, 0x8                # lseek syscall
    mov rdi, [rbp - FD_FILE]    # need to get length of infile
    mov rsi, -2                 # 2 byte offset
    mov edx, 0x2                # SEEK_END
    syscall

    # rax contains the offset from SEEK_SET, since we specified -2 from SEEK_END, then this would
    # be the size of the file - 2
    mov [rbp - FILESIZE], rax   # Save the file size - 2 which we will truncate filesize to

    xor rax, rax                # 0 in rax means read syscall
    lea rsi, [rbp - CHECKSUM]   # Where we will save the 2 byte checksum
    mov rdx, 2                  # Read two bytes
    mov rdi, [rbp - FD_FILE]
    syscall

    # Put file ptr back to beginning of file
    mov rax, 0x8                # lseek syscall
    mov rdi, [rbp - FD_FILE]  # need to get length of infile
    xor rsi, rsi                # 0 offset
    mov edx, 0x0                # SEEK_SET
    syscall

    mov rax, 0x4d               # ftruncate syscall
    mov rsi, [rbp - FILESIZE]   # File size we want to make the file, remove two bytes
    syscall
    
DOCHECKSUM:
    xor rax, rax                # 0 in rax means read syscall
    lea rsi, [rbp - BUFFER]     # BUFFER contains our checksum
    mov rdx, 2                  # Read two bytes
    mov rdi, [rbp - FD_FILE]
    syscall

    test rax, rax
    jle DONECHECKSUM

    add r12w, [rbp - BUFFER]

    jmp DOCHECKSUM  

DONECHECKSUM:
    mov [rbp - BUFFER], r12w    # save checksum to BUFFER to use in write coming up

    test ebx, ebx               # 0 is decode, 1 is encode
    je VERIFYCHECKSUM           # If it decode, verify the checksum

    # We are already at the end of the file, so just need to append the
    # calculated checksum to the end of the file
    mov rax, 1                  # 1 in rax means write syscall
    lea rsi, [rbp - BUFFER]     # BUFFER contains our checksum
    mov rdx, 2                  # Write two bytes
    mov rdi, [rbp - FD_FILE]
    syscall

    # Let user know that checksum was added to the file 
    mov rax, 1			# write
    mov rdi, rax		# stdout is also 1 copied from rax
    lea rsi, CHECKSUMADDEDMSG[rip]
    mov rdx, OFFSET CHECKSUMADDEDMSG_LEN    #  mov rdx, lenght of USAGE message
    syscall    

    jmp CLOSE_FILE           # Done clean up

# This part is only for checking a file that has the two byte checksum appended
VERIFYCHECKSUM:
    cmp r12w, [rbp - CHECKSUM]
    je CHECKSUMGOOD

    # If checksum is bad, then display bad checksum message
    mov rax, 1			# write
    mov rdi, rax		# stdout is also 1 copied from rax
    lea rsi, CHECKSUMBADMSG[rip]
    mov rdx, OFFSET CHECKSUMBADMSG_LEN    #  mov rdx, lenght of USAGE message
    syscall

    # Checksum calculated bad, so write back the checksum we 
    # read from the file to put it back the way it was
    mov rax, 1                  # 1 in rax means write syscall
    lea rsi, [rbp - CHECKSUM]     # Checksum read from file
    mov rdx, 2                  # Write two bytes
    mov rdi, [rbp - FD_FILE]
    syscall

    jmp CLOSE_FILE           # Done clean up

# Checksum is good, display appropriate message
CHECKSUMGOOD:
    mov rax, 1			# write
    mov rdi, rax		# stdout is also 1 copied from rax
    lea rsi, CHECKSUMGOODMSG[rip]
    mov rdx, OFFSET CHECKSUMGOODMSG_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR [rbp - ERROR_CODE], 0	# error code
    jmp CLOSE_FILE

# Display error message that we couldn't open infile.
ERROR_FILE_OPEN:
    mov rax, 1			# write
    mov rdi, rax		# stdout is also 1 copied from rax
    lea rsi, FILEINVALID[rip]
    mov rdx, OFFSET FILEINVALID_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR [rbp - ERROR_CODE], 2	# error code
    jmp EXIT

# Display message that our input rotval is not correct
SWITCHINVALID:  
    mov rax, 1			# write
    mov rdi, rax		# stdout is also 1
    lea rsi, ARGINVALID[rip]
    mov rdx, OFFSET ARGINVALID_LEN		# write
    syscall

    mov QWORD PTR [rbp - ERROR_CODE], 2	# error code
    jmp EXIT

# Number of arguments is not the expected 4
NUM_ARGS_BAD:
    mov rax, 1          # write
    mov rdi, rax		# stdout is 1 copied from rax
    lea rsi, USAGE[rip]
    mov rdx, OFFSET USAGE_LEN    #  mov rdx, lenght of USAGE message
    syscall

    mov QWORD PTR [rbp - ERROR_CODE], 255	# error code
    jmp EXIT

# Only need to close infile, if outfile failed to open
CLOSE_FILE:
    mov rax, 0x3        # close
    mov rdi, [rbp - FD_FILE]
    syscall

EXIT:
    mov eax, 60       # exit syscall
    mov rdi, [rbp - ERROR_CODE]       # error message in a Linux shell means all worked well
    #neg rdi             # two's compliment the negative number to obtain the error code

    leave               # May seam out of place, but need to put here so ERROR code above can be resolved on the stack
                        # also some systems enter main without a valid rbp
    syscall             # execute exit syscall


.section .rodata

    USAGE: .ascii "Usage: checksum <-d|-e> <file>\n"
    .set USAGE_LEN, . - USAGE

    ARGINVALID: .ascii "Argument is invalid, use either -d for decode or -e for encode.\n"
    .set ARGINVALID_LEN, . - ARGINVALID

    CHECKSUMADDEDMSG: .ascii "Checksum has been added to your file, rerun program with '-d' option to check remove it.\n"
    .set CHECKSUMADDEDMSG_LEN, . - CHECKSUMADDEDMSG

    CHECKSUMGOODMSG: .ascii "Checksum is good, your file is now ready to use.\n"
    .set CHECKSUMGOODMSG_LEN, . - CHECKSUMGOODMSG

    CHECKSUMBADMSG: .ascii "Checksum is bad, your file has not been changed.\n"
    .set CHECKSUMBADMSG_LEN, . - CHECKSUMBADMSG

    FILEINVALID: .ascii "Unable to open <file>.\n"
    .set FILEINVALID_LEN, . - FILEINVALID
