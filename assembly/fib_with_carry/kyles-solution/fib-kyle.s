.intel_syntax noprefix
.globl  main

main:
# input validatiton
	xor	r9, r9			# zero -o flag
	cmp	rdi, 3			# if 2 args given
	je	.CHECK_ARGS		#	goto check if valid -o option
.ARGS_CONT:				# probably a good sign my jump should go to function when I know how
	cmp	rdi, 2			# if less/more than 1 arg given after -o parsing
	jne	.BAD_ARGC		#	goto .BAD_ARGC and exit
	mov	rdi, QWORD PTR[rsi+8]	# put only CLI arg into arg1 for strtol
	mov	rdx, 10			# base 10 int arg3 for strtol
	push r9				# protect flag
	sub	rsp, 8			# move stack pointer up 8
	# pointer logic for strtol developed by Noel Bergman in TDQC #07_2020
	mov	rsi, rsp		# move stack pointer int arg2 for strtol
	call	strtol			# result in rax, remainder in rsi
	pop	rsi			# move stack pointer back
	pop	r9			# recover flag
	cmp	BYTE PTR[rsi], 0	# if remainder exists after strtol
	jne	.BAD_ARGV		# 	goto print error for bad argv[1]
	cmp	rax, 0			# if value < 0
	jb	.BAD_VAL		# 	goto bad input value error
	cmp	rax, 300		# if value > 300
	ja	.BAD_VAL		# 	goto bad input value error

# prep environment
	push	r12			# preserve callee-saved regs we use
	push	r13			# ...
	push	r14			# ...
	push	r15			# ...
	/* Register use and alignment
	Base	b256 : b192 : b128 : b64
	Pri	rsi  : rdx  : rcx  : r8
	Alt	r12  : r13  : r14  : r15

	r9	octal flag (1 if true)
	r10	start value
	rax	stop value
	*/
	mov	r15, 1			# set next value for r8
	xor	r8, r8			# zero(z) base64 pri reg
	xor	r14, r14		# z base128 alt rcx
	xor	rcx, rcx		# z base128 pri reg
	xor	r13, r13		# z base192 alt rdx
	xor	rdx, rdx		# z base192 pri reg
	xor	r12, r12		# z base256 alt rsi
	xor	rsi, rsi		# z base256 pri reg

	xor	r10, r10		# z incrementor
	#	rax 			  incrementor value from strtol
# calc value
.LOOP:
	cmp	r10, rax		# if incrementor equals stop val
	je	.PRINTER		#	goto .PRINTER
	xchg	rsi, r12		# swap base256 values
	xchg	rdx, r13		# swap base192 values
	xchg	rcx, r14		# swap base128 values
	xadd	r8, r15			# swap, then add base64 values
	adc	rcx, r14		# add base128 with cf from base64
	adc	rdx, r13		# add base192 with cf from base128
	adc	rsi, r12		# add base256 with cf from base192
	inc	r10
	jmp	.LOOP

.PRINTER:
	cmp	r9, 1			# if oct flag on
	je	.OCT_PRINTER		#	goto oct printer
	cmp	rax, 93			# if stop <= 93
	jbe	.LT93			# 	goto base64 formatter
	cmp	rax, 186		# elif stop <= 186
	jbe	.LT186			# 	goto base128 formatter
	cmp	rax, 278		# elif stop <= 278
	jbe	.LT278			# 	goto base192 formatter
	jmp	.LT370			# else goto base256 formatter

.OCT_PRINTER:
	mov	r15, r8			# copy base64 so they match
	mov	r14, rcx		# copy base128 so they match
	mov	r13, rdx		# copy base192 so they match
	mov	r12, rsi		# copy base256 so they match
	mov	r10, 0xFFFFFFFFFFFF	# used for later anding
	xor	r8, r8			# z for printing prep
	xor	r9, r9			# ...
	xor	rcx, rcx		# ...
	xor	rdx, rdx		# ...
	xor	rsi, rsi		# ...
	cmp	rax, 70			# determine which formatter is needed
	jbe	.OLT70			# ...
	cmp	rax, 139		# ...
	jbe	.OLT139			# ...
	cmp	rax, 209		# ...
	jbe	.OLT209			# ...
	cmp	rax, 278		# ...
	jbe	.OLT278			# ...
	jmp	.OLT347			# ...

.EXIT:
	xor	rax, rax		# clear eax/rax for printf
	call	printf
	pop	r15			# Put things back how I found them
	pop	r14			# ...
	pop	r13			# ...
	pop	r12			# ...
	xor	rax, rax		# return code 0 for success
	ret

.ERR_EXIT:
	xor	rax, rax		# purge rax for printf
	call	printf
	mov	rax, 1			# return code 1 for error
	ret

.LT93:
	lea	rdi, .fmt_base64[rip]	# base64 fmt string into arg1 for printf
	xchg	rsi, r8			# base64 to arg2 for printf
	jmp	.EXIT

.LT186:
	lea	rdi, .fmt_base128[rip]	# base128 fmt string into arg1 for printf
	xchg	rdx, r8			# base64 to arg3 for printf
	xchg	rsi, rcx		# base128 to arg2 for printf
	jmp	.EXIT

.LT278:
	lea	rdi, .fmt_base192[rip]	# base192 fmt string into arg1 for printf
	xchg	rcx, r8			# base64 to arg4 for printf
	xchg	rdx, r8			# base128 to arg3 for printf
	xchg	rsi, r8			# base128 to arg2 for printf
	jmp	.EXIT

.LT370:
	lea	rdi, .fmt_base256[rip]	# base256 fmt string into arg1 for printf
	jmp	.EXIT

.OLT70:
	mov	rsi, r15		# copy protected version into arg2
	lea	rdi, .fmt_obase48[rip]
	jmp	.EXIT

.OLT139:
	mov	rdx, r15		# copy protected version into arg3
	and	rdx, r10		# remove anything above the 48th bit for even octal printing
	shr	r15, 48			# shift r15 so all it has is the remainder of the "and"
	mov	rsi, r14		# copy r14 into arg2 of print
	shl	rsi, 16			# shift it left 16 to make space for lower 16
	or	rsi, r15		# or the remainder of r15 into rsi
	lea	rdi, .fmt_obase96[rip]
	jmp	.EXIT

.OLT209:
	mov	rcx, r15		# get full value into rcx
	and	rcx, r10		# wipe out top 16 bits of rcx
	mov	rsi, r13		# copy base192 value
	shl	rsi, 32			# get out of r14 way
	and	rsi, r10		# wipe out remainder
	mov	rdx, r14		# full copy into rdx
	shr	r14, 32			# shift to get out of base64 carry over
	or	rsi, r14		# rsi now complete
	shl	rdx, 16			# get out of way for carryover from base64
	and	rdx, r10		# clear out any remainder
	shr	r15, 48			# move to last 16 bits
	or	rdx, r15		# put last 16 bits in rdx
	lea	rdi, .fmt_obase144[rip]
	jmp	.EXIT

.OLT278:
	mov	r8, r15			# more of same stuff, comment for clarity with time
	and	r8, r10			# ...
	shr	r15, 48			# ...
	mov	rsi, r13		# ...
	shr	rsi, 16			# ...
	shl	r13, 48			# ...
	mov	rdx, r14		# ...
	shr	rdx, 32			# ...
	or	rdx, r13		# ...
	shl	r14, 16			# ...
	and	r14, r10		# ...
	or	rcx, r14		# ...
	or	rcx, r15		# ...
	lea	rdi, .fmt_obase192[rip]
	jmp	.EXIT

.OLT347:
	mov	r9, r15			# more of same stuff, comment later for clarity when time permits
	and	r9, r10			# ...
	shr	r15, 48			# ...
	mov	r8, r14			# ...
	shl	r8, 16			# ...
	and	r8, r10			# ...
	or	r8, r15			# ...
	shr	r14, 32			# ...
	mov	rcx, r13		# ...
	shl	rcx, 32			# ...
	and	rcx, r10		# ...
	or	rcx, r13		# ...
	mov	rdx, r13		# ...
	shr	rdx, 16			# ...
	mov	rsi, r12		# ...
	lea	rdi, .fmt_obase240[rip]
	jmp	.EXIT

.BAD_ARGC:
	mov	rsi, QWORD PTR[rsi]	# dereference argv[1] to arg2 of printf
	lea	rdi, .fmt_badargc[rip]	# put format string into arg1 of printf
	jmp	.ERR_EXIT

.BAD_ARGV:
	lea	rdi, .fmt_badargv[rip]	# put format string into arg1 of printf
	jmp	.ERR_EXIT

.BAD_VAL:
	lea	rdi, .fmt_badval[rip]	# put format string into arg1 of printf
	mov	rsi, rax		# user input val into arg2 of printf
	jmp	.ERR_EXIT

.BAD_OPT:
	lea	rdi, .fmt_badopt[rip]	# put format string into arg1 of printf
	jmp	.ERR_EXIT

# There has to be a better way to parse args
# strncmp solution derived from cc compiled code
.CHECK_ARGS:
	push	rdi			# preserve registers for call
	push	rsi			# ...
	mov	rdi, QWORD PTR 8[rsi]	# put argv[1] into rdi
	mov	ecx, 3			# put 3 into the length of bytes to check
	lea	rsi, .fmt_arg[rip]	# put the `-o` into rsi
	repz	cmpsb			# compares bytes for repz (i.e. 3)
	pop	rsi			# put things back how we found them
	pop	rdi			# ...
	seta	al			# sets al depending on flags from cmpsb
	sbb	al, 0			# adds src and cf and subs from al (i.e. 1 = true, 0 = false on our find)
	movsx	eax, al			# zeroes out rest of eax while preserving al
	mov	r9, rax			# copy our result into the r9 flag
	cmp	r9, 0			# Check for strncmp success
	jne	.BAD_OPT		# 	if not, try fail
	dec	rdi			# reduce argc to continue validation
	mov	r9, 1			# set flag to 1 for good -o found
	xchg	rax, QWORD PTR 8[rsi] 	# swap argv[1] and argv[2] NOTE: Find cleaner way!
	xchg	rax, QWORD PTR 16[rsi]	# ...
	xchg	rax, QWORD PTR 8[rsi]	# ...
	jmp	.ARGS_CONT		# return to where we were

.fmt_arg:
	.string "-o"

.fmt_badargc:
	.string "%s requires 1 argument(the number) and optional -o.\n"

.fmt_badargv:
	.string "%s still in buffer.\n./fibonacci only accepts whole numbers between 0 and 300\n"

.fmt_badopt:
	.string "Expected -o argument, but did not find -o argument before number.\n"

.fmt_badval:
	.string "%d does not fall between 0 and 300\n"

# while assignment states we should not lead with 0's, it is important to notice
# that all registers who are not the "most significant" NEED to print as %016lX
# Best test case is compare 298..300
.fmt_base64:
	.string "0x%lX\n"

.fmt_base128:
	.string "0x%lX%016lX\n"

.fmt_base192:
	.string "0x%lX%016lX%016lX\n"

.fmt_base256:
	.string "0x%lX%016lX%016lX%016lX\n"

.fmt_obase48:
	.string "0%lo\n"

.fmt_obase96:
	.string "0%lo%016lo\n"

.fmt_obase144:
	.string "0%lo%016lo%016lo\n"

.fmt_obase192:
	.string "0%lo%016lo%016lo%016lo\n"

.fmt_obase240:
	.string "0%lo%016lo%016lo%016lo%016lo\n"

