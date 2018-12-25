include "gbhw.inc"
include "ibmpc1.inc"
include "hram.inc"
include "macros.inc"

include "interrupts.asm"

section "Org $100",ROM0[$100]
	nop
	jp	begin

	ROM_HEADER ROM_MBC1_RAM_BAT, ROM_SIZE_32KBYTE, RAM_SIZE_8KBYTE

include "memory.asm"

TileData:
	chr_IBMPC1	1,8

Found1_len equ 12
Found1:
	db	"You found my"

Found2_len equ 9
Found2:
	db	"Game Boy!"

Found3_len equ 17
Found3:
	db	"Please return to:"

Address1_len equ 16
Address1:
	db	"Quint Guvernator"

Address2_len equ 19
Address2:
	db	"Gerard Doustraat 16"

Address3_len equ 19
Address3:
	db	"1072CA Amsterdam NL"

Phone1_len equ 15
Phone1:
	db	"+1 757 606 0005"

Phone2_len equ 15
Phone2:
	db	"WhatsApp or SMS"

Star: incbin "star.2bpp"
StarTile equ $80

PU1Note:
	ld	a,0			; no sweep
	ld	[rNR10],a
	ld	a,%01111111		; duty cycle (top two) and length (the rest)
	ld	[rNR11],a
	ld	a,%11110111		; envelope, precisely like LSDj
	ld	[rNR12],a
	ld	a,[hPU1Freq]
	ld	[rNR13],a
	ld	a,[hPU1Freq+1]
	add	%00000111		; truncate to MSB that's actually used
	or	%10000000		; initialize the registers
	ld	[rNR14],a
	ret

begin::
	di
	ld	sp,$ffff
	call	StopLCD

	ld	a,%00011011	; Window palette colors, from darkest to lightest
	ld	[rBGP],a	; Setup the default background palette
	ldh	[rOBP0],a	; set sprite pallette 0
	ld	a,%11100100
	ldh	[rOBP1],a	; and 1

; printable ascii
	ld	hl,TileData
	ld	de,_TILE0
	ld	bc,8*128	; length (8 bytes per tile) x (256 tiles)
	call	mem_CopyMono	; Copy tile data to memory

	ld	hl,Star
	ld	de,_TILE0 + ($10 * StarTile)
	ld	bc,16*8		; size of all eight star sprites
	call	mem_Copy

; Clear screen
	ld	a,$20
	ld	hl,_SCRN0
	ld	bc,32*32
	call	mem_Set

WriteCenter: macro		; write a line of text in the center of the screen
	ld	hl,\1
	ld	de,_SCRN0 + ($20 * \2) + ((20 - \1_len) / 2)
	ld	bc,\1_len
	call	mem_Copy
	endm

	; draw text on screen
	WriteCenter	Found1,$8
	WriteCenter	Found2,$9
	WriteCenter	Found3,$12
	WriteCenter	Address1,$14
	WriteCenter	Address2,$15
	WriteCenter	Address3,$16
	WriteCenter	Phone1,$18
	WriteCenter	Phone2,$19

	; blit happyface
	ld	de,_SCRN0+$389
	ld	a,1
	ld	[de],a

	; blit heart
	inc	de
	ld	a,3
	ld	[de],a

	; blit heart
	ld	de,_SCRN0+$3a9
	ld	[de],a

	; blit happyface
	inc	de
	ld	a,1
	ld	[de],a

	; clear oam
	ld	a,0
	ld	hl,_OAMRAM
	ld	bc,160
	call	mem_Set

LoadSprite: macro ; args: sprite number 0-39, tile, x, y, flags
	ld	a,16+(8*(\4))		; y, first sprite top-offset by 16
	ld	[_OAMRAM+((\1)*4)],a
	ld	a,8+(8*(\3))		; x, first sprite left-offset by 8
	ld	[_OAMRAM+((\1)*4)+1],a
	ld	a,\2
	ld	[_OAMRAM+((\1)*4)+2],a	; tile
	ld	a,\5
	ld	[_OAMRAM+((\1)*4)+3],a	; flags
	endm

	LoadSprite	0,StarTile+$0,$01,$6,0
	LoadSprite	1,StarTile+$2,$12,$6,OAMF_XFLIP
	LoadSprite	2,StarTile+$4,$01,$b,0
	LoadSprite	3,StarTile+$6,$12,$b,OAMF_XFLIP

	; enable sound registers
	ld	a,%10000000		; enable sound (keep pu1 off for now)
	ld	[rNR52],a
	ld	a,%01110111		; left and right channel volume
	ld	[rNR50],a
	ld	a,%00010001		; enable left and right PU1 output only
	ld	[rNR51],a

	; enable pu1
	ld	a,%10000001
	ld	[rNR52],a

	ld	hl,1750
	ld	a,l
	ld	[hPU1Freq],a
	ld	a,h
	ld	[hPU1Freq+1],a
	call	PU1Note

	; turn screen on
	ld	a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON;
	ld	[rLCDC],a

	ld	a,0
	ld	[hPageDelay],a		; count frames to wait before scrolling to reveal second screen of text
	ld	[hSpritesDisabled],a	; eventually will need to disable sprites

	ld	b,0			; slow down animations by skipping every b'th frame

	; set up interrupt
	ld	a,IEF_VBLANK
	ld	[rIE],a
	ei

.wait
	; wait for vblank
	halt
	nop
	jr	.wait

StopLCD:
	ld	a,[rLCDC]
	rlca			; Put the high bit of LCDC into the Carry flag
	ret	nc		; Screen is off already. Exit.

.wait
	; wait for vblank scan line 145
	ld	a,[rLY]
	cp	145
	jr	nz,.wait

	; turn off the LCD
	ld	a,[rLCDC]
	res	7,a
	ld	[rLCDC],a

	ret

; c - byte
; hl - address
DrawHexByte:
	ld	d,1
	ld	a,c
	swap	a
.CharLoop
	and	$0f
	cp	10
	jr	nc,.Alpha
	add	"0"
	jr	.Write
.Alpha
	add	"A" - 10
.Write
	ld	[hli],a
	ld	a,d
	cp	0
	ld	a,c
	ld	d,0
	jr	nz,.CharLoop
	ret

; directly from GB CPU manual
ReadJoypad:
	ld	a,P1F_5		; bit 5 = $20
	ld	[rP1],A		; select P14 by setting it low
	ld	A,[rP1]
	ld	A,[rP1]		; wait a few cycles
	cpl			; complement A
	and	$0F		; get only first 4 bits
	swap	A		; swap it
	ld	B,A		; store A in B
	ld	A,P1F_4
	ld	[rP1],A		; select P15 by setting it low
	ld	A,[rP1]
	ld	A,[rP1]
	ld	A,[rP1]
	ld	A,[rP1]
	ld	A,[rP1]
	ld	A,[rP1]		; Wait a few MORE cycles
	cpl			; complement (invert)
	and	$0F		; get first 4 bits
	or	B		; put A and B together

	;ld	B,A		; store A in D
	;ld	A,[hButtonsOld]	; read old joy data from ram
	;xor	B		; toggle w/current button bit
	;and	B		; get current button bit back
	ld	[hButtons],A	; save in new Joydata storage
	;ld	A,B		; put original value in A
	;ld	[hButtonsOld],A	; store it as old joy data
	ld	A,P1F_5|P1F_4	; deselect P14 and P15
	ld	[rP1],A		; RESET Joypad
	ret			; Return from Subroutine

; each frame, advance all sprites to their next tile and scroll down if needed
VBlank::
	ld	a,b
	cp	3
	jr	z,.animate	; ...animate...
	inc	b		; ...otherwise increment and bail
	reti

.animate
	; if the initial delay to start page down animation has expired, begin scrolling
	ld	a,[hPageDelay]
	cp	32
	jr	z,.scrollscreen	; ...if so, start scrolling...

	; otherwise, increment delay counter and skip scrolling
	inc	a
	ld	[hPageDelay],a
	jr	.cyclesprites

.scrollscreen
	; don't scroll if we're already at the bottom
	ld	a,[rSCY]
	cp	$74
	jr	z,.disablesprites

	; otherwise, scroll screen down
	inc	a
	ld	[rSCY],a
	jr	.cyclesprites

.disablesprites
	; if sprites are already disabled, we're done
	ld	a,[hSpritesDisabled]
	cp	0
	jr	nz,.end

	; otherwise, disable sprites and THEN we're done
	inc	a
	ld	[hSpritesDisabled],a
	ld	a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJOFF;
	ld	[rLCDC],a
	jr	nz,.end

.cyclesprites
	ld	b,0		; sprite counter
	ld	hl,_OAMRAM	; get the first sprite's tile
.loop
	ld	a,[hPageDelay]	; if it's NOT time to start paging down...
	cp	32
	jr	nz,.noscroll	; ...jump away and increment
	dec	[hl]

.noscroll
	inc	hl		; go to the tile selection byte of the sprite
	inc	hl
	ld	a,[hl]		; get some sprite's tile
	inc	a		; advance to the next tile...
	and	a,$7
	add	a,StarTile	; ...truncating to stay within the 8 star frames
	ld	[hl],a		; advance sprite to its next tile
	inc	b		; select the next sprite in OAMRAM by number...
	inc	hl		; ...and by address
	inc	hl
	ld	a,b		; do this for each of the four sprites on the screen
	cp	4
	jr	nz,.loop

.end
	ld	b,0		; reset animation frame wait counter
	reti

; vim: se ft=rgbds:
