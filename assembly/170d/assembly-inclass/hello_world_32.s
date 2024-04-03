.intel_syntax noprefix 		# Default for GNU as is ATT syntax

                                #we must export the entry point to the ELF linker or
.global  main                 	#loader. They conventionally recognize _start as their
			        #entry point. Use ld -e foo to override the default.

.section .text                  #section declaration

main:
    mov     edx, OFFSET len     #third argument: message length
    lea     ecx, msg[eip]	#second argument: pointer to message to write
    mov     ebx,1               #first argument: file handle (stdout)
    mov     eax,4               #system call number (sys_write)
    int     0x80                #call kernel

                                #and exit
    mov     ebx,0               #first syscall argument: exit code
    mov     eax,1               #system call number (sys_exit)
    int     0x80                #call kernel

.section .data			#section declaration

msg: .ascii "Hello, world!\n"   #our dear string
.set len, . - msg               #length of our dear string

# taken from: http://www.iitk.ac.in/LDP/HOWTO/html_single/Assembly-HOWTO/#AEN856

# assemble with: as hello_world.s -o hello_world.o
# link with: ld -e main hello_world.o -o hello_world
