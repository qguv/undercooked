section "DMA trigger",ROM0

; Initiate a DMA transfer from OAM_BUF to the real OAM. The vblank period is
; the only time we can do this without bugs. Called each frame by the vblank
; interrupt.
VBlank::
	push	af
	push	bc
	push	de
	push	hl

	; start OAM DMA
	ld a, OAM_BUF / $100
	ld bc,$2946		; b: wait time, c: OAM trigger
	call DMA

	pop	hl
	pop	de
	pop	bc
	pop	af
	reti

;-----------------------------;
; OAM DMA (put this in HIRAM) ;
;_____________________________;

DMACode:
load "DMA",HRAM
DMA:				; 5 bytes total	9 clocks total
	ldh [c],a		; 1 byte	2 clocks
.loop
	dec b			; 1 byte	1 clock
	jr nz,.loop		; 2 bytes	2 clocks
	ret			; 1 byte	4 clocks
.end
endl

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
