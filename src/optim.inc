; 'cp 0' takes 2 bytes, 2 cycles
; 'or a' or 'and a' takes 1 byte, 1 cycle
cpz: macro
	or	a
	endm

; 'ld a,0' takes 2 bytes, 2 cycles, Doesn't affect flags
; 'xor a' takes 1 byte, 1 cycle, Flag results: C=0, Z=1
ldz: macro
	xor	a
	endm

; 'addhla' adds a to hl, 20 cycles. Not worth it for immediates; just use repeated `inc hl` for values under 10.
addhla: macro
	add	a,l
	ld	l,a
	adc	a,h
	sub	l
	ld	h,a
	endm

; 'addbca' adds a to bc, 20 cycles. Not worth it for immediates; just use repeated `inc bc` for values under 10.
addbca: macro
	add	a,c
	ld	c,a
	adc	a,b
	sub	c
	ld	b,a
	endm

; 'adddea' adds a to de, 20 cycles. Not worth it for immediates; just use repeated `inc de` for values under 10.
adddea: macro
	add	a,e
	ld	e,a
	adc	a,d
	sub	e
	ld	d,a
	endm

; vim: se ft=rgbds:
