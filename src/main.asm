include "lib/gbhw.inc"		; hardware descriptions
include "lib/ibmpc1.inc"	; font
include "src/optim.inc"		; optimized instruction aliases

include "src/interrupts.asm"

section "Org $100",ROM0[$100]
	nop
	jp	begin

	ROM_HEADER ROM_MBC1_RAM_BAT, ROM_SIZE_32KBYTE, RAM_SIZE_8KBYTE

include "lib/memory.asm"
include "src/music.asm"		; music note frequencies

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SPR_CYCLE_SPEED	equ 2		; speed of star animation, higher is exponentially slower
NOTE_LENGTH	equ 11		; note length in vblank frames (~160ms)
NUM_SPRITES	equ 4		; number of sprites on the screen

		rsset _HIRAM
buttons		rb 1		; bitmask of which buttons are being held
song_repeated	rb 1		; when the song repeats for the first time, start scrolling
spr_cycle_stall	rb 1		; delay counter between sprite tile cycling animation frames
spr_index	rb 1		; used to loop through animating/moving sprites
note_dur	rb 1		; counter for frames within note
note_index	rb 1		; index of note in song
_HIRAM_END	rb 0

Font:
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

SongLength equ 32	; number of NOTES not BYTES
NotesPU1:
	db	a4,fs4,cs4,a3,gs4,e4,b3,gs3, \
		fs4,d4,a3,fs3,a3,d4,fs4,d4, \
		fs4,d4,a3,fs3,gs4,e4,b3,gs3, \
		a4,fs4,cs4,a3,cs4,fs4,a4,fs4
NotesPU2:
	db	fs3,REST,fs3,REST,e3,REST,REST,REST, \
		d3,REST,d3,REST,d3,REST,d3,d4, \
		d3,REST,d3,REST,e3,REST,REST,REST, \
		fs3,REST,fs3,REST,fs3,REST,e4,fs4

Star: incbin "obj/star.2bpp"
StarTile equ $80

HandleNotes:
	ld	a,[note_dur]		; if duration of previous note is expired, continue
	cpz
	jr	z,.next_note
	dec	a			; otherwise decrement and return
	ld	[note_dur],a
	ret

.next_note
	ld	a,NOTE_LENGTH		; set next note duration
	ld	[note_dur],a

	ld	a,[note_index]		; get note index
	cpz				; if hPU1NoteIndex isn't zero, fine...
	jr	nz,.sound_registers
	ld	a,1			; ...but if it is, the song has repeated and we need to mark that
	ld	[song_repeated],a

pulsenote: macro
	; index the notes-in-song table with the note song-index to get the actual note value
	ld	b,0
	ld	a,[note_index]
	ld	c,a
	ld	hl,\1
	add	hl,bc
	ld	c,[hl]

	ld	a,c			; if it's a rest, don't set any registers for this note
	cp	REST
	jr	z,.end\@

	; index the note frequency table with the actual note value to get the note frequency (16-bit)
	ld	b,0
	sla	c			; double the index (16-bit), sla+rl together represents a 16-bit left shift
	rl	b

	ld	hl,NoteFreqs		; now index the damn table
	add	hl,bc

	ldz				; disable sweep
	ld	[\4],a
	ld	a,\2			; duty cycle (top two) and length (the rest)
	ld	[\5],a
	ld	a,\3			; envelope, precisely like LSDj
	ld	[\6],a
	ld	a,[hl+]			; freq LSB
	ld	[\7],a
	ld	a,[hl]			; freq MSB
	and	%00000111		; truncate to bits of MSB that are actually used
	or	%10000000		; reset envelope (not legato)
	ld	[\8],a			; set frequency MSB and flags
.end\@
	endm

.sound_registers
	pulsenote	NotesPU1,%00111111,%11110001,rAUD1SWEEP,rAUD1LEN,rAUD1ENV,rAUD1LOW,rAUD1HIGH
	pulsenote	NotesPU2,%10111111,%11000011,rAUD2LOW,rAUD2LEN,rAUD2ENV,rAUD2LOW,rAUD2HIGH ; TODO: skip sweep appropriately

	ld	a,[note_index]	; increment index of note in song
	inc	a
	and	SongLength-1
	ld	[note_index],a

	ret

begin::
	di
	ld	sp,$ffff
	call	StopLCD

	ld	a,%11100100	; Window palette colors, from darkest to lightest
	ld	[rBGP],a	; Setup the default background palette
	ldh	[rOBP0],a	; set sprite pallette 0
	ld	a,%00011011
	ldh	[rOBP1],a	; and 1

	; clear screen RAM
	ld	a,$20
	ld	hl,_SCRN0
	ld	bc,32*32
	call	mem_Set

	; zero out OAM (sprite RAM)
	ldz
	ld	hl,_OAMRAM
	ld	bc,160
	call	mem_Set

	; zero out allocated HRAM
	ldz
	ld	hl,_HIRAM
	ld	bc,_HIRAM_END-_HIRAM
	call	mem_Set

	; enable sound registers
	ld	a,%10000000		; enable sound
	ld	[rNR52],a
	ld	a,%01110111		; left and right channel volume
	ld	[rNR50],a
	ld	a,%00010010		; hard-pan PU1 (left) and PU2 (right) outputs
	ld	[rNR51],a

	; enable PU1 and PU2
	ld	a,%10000011
	ld	[rNR52],a

; printable ascii
	ld	hl,Font
	ld	de,_TILE0
	ld	bc,8*128	; length (8 bytes per tile) x (256 tiles)
	call	mem_CopyMono	; Copy tile data to memory

	ld	hl,Star
	ld	de,_TILE0 + ($10 * StarTile)
	ld	bc,16*8		; size of all eight star sprites
	call	mem_Copy

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

	; turn screen on
	ld	a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON;
	ld	[rLCDC],a

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
	cpz
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
	;ld	A,[buttons_old]	; read old joy data from ram
	;xor	B		; toggle w/current button bit
	;and	B		; get current button bit back
	ld	[buttons],A	; save in new Joydata storage
	;ld	A,B		; put original value in A
	;ld	[buttons_old],A	; store it as old joy data
	ld	A,P1F_5|P1F_4	; deselect P14 and P15
	ld	[rP1],A		; RESET Joypad
	ret			; Return from Subroutine

; each frame, advance all sprites to their next tile and scroll down if needed
VBlank::
	ld	a,[song_repeated]		; if the music hasn't repeated yet, don't scroll, skip directly to sprites
	cpz
	jr	z,.animate_sprites

	; don't scroll if we're already at the bottom
	ld	a,[rSCY]
	cp	$74
	jr	z,.end

	; otherwise, scroll screen down
	inc	a
	ld	[rSCY],a
	jr	.animate_sprites

.animate_sprites
	; advance animation delay
	ld	a,[spr_cycle_stall]
	inc	a
	and	(1<<SPR_CYCLE_SPEED)-1	; truncate to just a couple LSBs
	ld	[spr_cycle_stall],a

	ld	hl,_OAMRAM	; get the first sprite
	ldz		; reset sprite index
	ld	[spr_index],a
.loop
	ld	a,[song_repeated]	; if we're not scrolling yet, jump to sprite cycling
	cpz
	jr	z,.cycle_sprite

	; deal with going off the screen
	ld	a,[hl]
	cp	9
	jr	z,.zero_sprite	; if it's just about to go off the screen, zero it out
	jr	c,.skip		; if it's already off the screen, move onto the next one
	dec	[hl]		; otherwise, scroll it down
	jr	.cycle_sprite

.zero_sprite
	ldz
rept 4
	ld	[hl+],a
endr
	jr	.next_noadvance	; kinda ugly, but I think it's unfortunately optimal

.skip
	ld	bc,4
	add	hl,bc
	jr	.next_noadvance

.cycle_sprite
	inc	hl		; go to the tile selection byte of the sprite (2 cycles
	inc	hl		; (two increments is 4 cycles, vs 16-bit load (3) and add (2) (5 total))

	ld	a,[spr_cycle_stall]	; check if we're in a frame when we're supposed to cycle
	cpz
	jr	nz,.next
	ld	a,[hl]		; get some sprite's tile
	inc	a		; advance to the next tile...
	and	a,$7
	add	a,StarTile	; ...truncating to stay within the 8 star frames
	ld	[hl],a		; advance sprite to its next tile
.next
	inc	hl		; go to the next sprite in OAMRAM...
	inc	hl
.next_noadvance
	ld	a,[spr_index]	; increment the sprite counter
	inc	a
	ld	[spr_index],a	; increment the sprite counter
	cp	NUM_SPRITES		; repeat for each sprite
	jr	nz,.loop

.end
	call HandleNotes
	reti

; vim: se ft=rgbds:
