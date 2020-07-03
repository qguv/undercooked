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

; 'addhla' adds a to hl (5 bytes, 5 cycles). Beats three or more repeated `inc hl`.
addhla: macro
	add	a,l
	ld	l,a
	adc	a,h
	sub	l
	ld	h,a
	endm

; 'addbca' adds a to bc, (5 bytes, 5 cycles). Beats three or more repeated `inc bc`.
addbca: macro
	add	a,c
	ld	c,a
	adc	a,b
	sub	c
	ld	b,a
	endm

; 'adddea' adds a to de, (5 bytes, 5 cycles). Beats three or more repeated `inc de`.
adddea: macro
	add	a,e
	ld	e,a
	adc	a,d
	sub	e
	ld	d,a
	endm

; vim: se ft=rgbds:
