# Found at: https://skanthak.homepage.t-online.de/integer.html
# Copyright © 2004-2023, Stefan Kanthak <‍stefan‍.‍kanthak‍@‍nexgo‍.‍de‍>

# NOTE: raises "division exception" when divisor is 0!

.arch	generic64
.code64
.intel_syntax noprefix
.text
				# rsi:rdi = dividend
				# rcx:rdx = divisor
__umodti3:
	sub	rsp, 24
	mov	r8, rsp		# r8 = address of remainder
	call	__udivmodti4
	pop	rax
	pop	rdx		# rdx:rax = remainder
	pop	rcx
	ret
				# rsi:rdi = dividend
				# rcx:rdx = divisor
__udivti3:
	xor	r8, r8
				# rsi:rdi = dividend
				# rcx:rdx = divisor
				# r8 = oword ptr remainder
__udivmodti4:
.if 0
	cmp	rsi, rcx
	jb	.trivial	# (high qword of) dividend < (high qword of) divisor?
.else
	cmp	rdi, rdx
	mov	rax, rsi
	sbb	rax, rcx
	jb	.trivial	# dividend < divisor?
.endif
	bsr	r9, rcx		# r9 = index of most significant '1' bit in high qword of divisor
	jz	.simple		# high qword of divisor = 0?

	# dividend >= divisor >= 2**64 (so quotient will be < 2**64)

	mov	r11, rcx	# r11 = high qword of divisor
	bsr	rcx, rdx	# rcx = index of most significant '1' bit in high qword of dividend
#	jz	.trivial	# high qword of dividend = 0?

	# perform "shift & subtract" alias "binary long" division
.large:
	sub	rcx, r9		# rcx = distance of leading '1' bits
#	jb	.trivial	# dividend < divisor?

	xor	r9, r9		# r9 = (low qword of) quotient' = 0
	mov	r10, rdx	# r10 = low qword of divisor
	shld	r11, r10, cl
	shl	r10, cl		# r11:r10 = divisor << distance of leading '1' bits
				#         = divisor'
.loop:
	mov	rax, rdi
	mov	rdx, rsi	# rdx:rax = dividend'
	sub	rdi, r10
	sbb	rsi, r11	# rsi:rdi = dividend' - divisor'
				#         = dividend",
				# CF = (dividend' < divisor')
	cmovb	rdi, rax
	cmovb	rsi, rdx	# rsi:rdi = (dividend' < divisor') ? dividend' : dividend"
	cmc			# CF = (dividend' >= divisor')
	adc	r9, r9		# r9 = quotient' << 1
				#    + dividend' >= divisor'
				#    = quotient"
.if 0
	shrd	r10, r11, 1
	shr	r11, 1		# r11:r10 = divisor' >> 1
				#         = divisor"
.else
	shr	r11, 1
	rcr	r10, 1		# r11:r10 = divisor' >> 1
				#         = divisor"
.endif
	dec	ecx
	jns	.loop

	test	r8, r8
	jz	0f		# address of remainder = 0?

	mov	[r8], rdi
	mov	[r8+8], rsi	# remainder = dividend"
0:
	mov	rax, r9		# rax = (low qword of) quotient
	xor	edx, edx	# rdx:rax = quotient
	ret

	# dividend < divisor
.trivial:
	test	r8, r8
	jz	1f		# address of remainder = 0?

	mov	[r8], rdi
	mov	[r8+8], rsi	# remainder = dividend
1:
	xor	eax, eax
	xor	edx, edx	# rdx:rax = quotient = 0
	ret

	# divisor < 2**64 (so remainder will be < 2**64 too)
.simple:
	mov	r9, rdx		# r9 = (low qword of) divisor
	cmp	rsi, rdx
	jae	.long		# high qword of dividend >= (low qword of) divisor?

	# dividend < divisor * 2**64 (so quotient will be < 2**64):
	# perform normal division
.normal:
	mov	rdx, rsi
	mov	rax, rdi	# rdx:rax = dividend
	div	r9		# rax = (low qword of) quotient,
				# rdx = (low qword of) remainder
	test	r8, r8
	jz	2f		# address of remainder = 0?

	mov	[r8], rdx
	mov	[r8+8], rcx	# high qword of remainder = 0
2:
	mov	rdx, rcx	# rdx:rax = quotient
	ret

	# dividend >= divisor * 2**64 (so quotient will be >= 2**64):
	# perform "long" alias "schoolbook" division
.long:
	mov	rdx, rcx	# rdx = 0
	mov	rax, rsi	# rdx:rax = high qword of dividend
	div	r9		# rax = high qword of quotient,
				# rdx = high qword of remainder'
	mov	r10, rax	# r10 = high qword of quotient
	mov	rax, rdi	# rax = low qword of dividend
	div	r9		# rax = low qword of quotient,
				# rdx = (low qword of) remainder
	test	r8, r8
	jz	3f		# address of remainder = 0?

	mov	[r8], rdx
	mov	[r8+8], rcx	# high qword of remainder = 0
3:
	mov	rdx, r10	# rdx:rax = quotient
	ret

.size	__udivmodti4, .-__udivmodti4
.type	__udivmodti4, @function
.global	__udivmodti4
.size	__udivti3, .-__udivti3
.type	__udivti3, @function
.global	__udivti3
.size	__umodti3, .-__umodti3
.type	__umodti3, @function
.global	__umodti3
.end
