; 'cp 0' takes 2 bytes, 2 cycles
; 'or a' or 'and a' takes 1 byte, 1 cycle
macro cpz
.cpz\@
	or	a
endm

; 'ld a,0' takes 2 bytes, 2 cycles, Doesn't affect flags
; 'xor a' takes 1 byte, 1 cycle, Flag results: C=0, Z=1
macro ldz
.ldz\@
	xor	a
endm

; 'addhla' adds `a` to `hl`, clobbering `a` (5 bytes, 5 cycles). Beats three or more repeated `inc hl`.
macro addhla
.addhla\@
	add	a,l
	ld	l,a
	adc	a,h
	sub	l
	ld	h,a
.addhla_end\@
endm

; 'addbca' adds `a` to `bc`, clobbering `a` (5 bytes, 5 cycles). Beats three or more repeated `inc bc`.
macro addbca
.addbca\@
	add	a,c
	ld	c,a
	adc	a,b
	sub	c
	ld	b,a
.addbca_end\@
endm

; 'adddea' adds `a` to `de`, clobbering `a` (5 bytes, 5 cycles). Beats three or more repeated `inc de`.
macro adddea
.adddea\@
	add	a,e
	ld	e,a
	adc	a,d
	sub	e
	ld	d,a
.adddea_end\@
endm

; `inc_hl_safe` is a version of `inc hl` that's safe to use when hl is in $feXX. This area would otherwise trigger the infamous Sprite RAM Bug, see gbcpuman sec 2.8.3.
macro inc_hl_safe
.inc_hl_safe\@
	inc	l
	ldz
	adc	a,h
	ld	h,a
.inc_hl_safe_end\@
endm

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
