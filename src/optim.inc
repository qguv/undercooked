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

; vim: se ft=rgbds:
