include "lib/gbhw.inc"		; hardware descriptions
include "src/optim.inc"		; optimized instruction aliases
include "src/smt.inc"		; sprite meta-table constants
include "src/tiles.inc"		; tile constants

section "init",ROM0[$100]
	nop
	jp	setup

	ROM_HEADER ROM_MBC1_RAM_BAT, ROM_SIZE_32KBYTE, RAM_SIZE_8KBYTE

;----------------,
; Allocated HRAM ;
;________________'

section "hram vars",HRAM
song_repeated:	db		; when the song repeats for the first time, start scrolling
spr_index:	db		; used to loop through animating/moving sprites
note_dur:	db		; counter for frames within note
note_swindex:	db		; index into the swing table
note_index:	db		; index of note in song
duration:	db		; how many vblank frames of the current directive are left
vram_ringl:	db		; VRAM last loaded tile width index on the left (wraps around)
vram_ringr:	db		; VRAM last loaded tile width index on the right (wraps around)
maploadl:	db		; column index of vram_ringl (signed)
maploadr:	db		; column index of vram_ringr (signed)
dx:		db		; $ff moving left, $01 moving right
dy:		db		; $ff moving up, $01 moving down	; TODO: combine this with dx into a bitmap
lfootx:		db		; x position of left foot wrt the map, 0 is the furthest left you can go without hitting the wall
lfooty:		db		; y position of left foot wrt the map, 0 is the furthest up you can go without hitting your head

tmp1:		db
tmp2:		db

;-------------------,
; Allocated Low RAM ;
;___________________'

; OAM RAM buffer, copied to OAM RAM at each vblank
section "OAM buffer",WRAM0
OAM_BUF:	ds $a0

; sprite meta-table, holding sprite animation and movement metadata
section "RAM SMT",WRAM0
SMT_RAM:	ds SMT_RAM_ENTRIES * SMT_RAM_BYTES

;-------------,
; Entry point ;
;_____________'

section "main",ROM0

setup::
	di
	ld	sp,$e000	; use lowram for stack
	call	StopLCD

	ld	a,%11100100	; Window palette colors, from darkest to lightest
	ld	[rBGP],a	; Setup the default background palette
	ld	a,%11100000
	;                ^^ not used, always transparent
	ldh	[rOBP0],a	; set sprite pallette 0
	ld	a,%11010000
	;                ^^ not used, always transparent
	ldh	[rOBP1],a	; set sprite pallette 1

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

	; zero out OAM_BUF (sprite RAM buffer)
	ldz
	ld	hl,OAM_BUF
	ld	bc,160
	call	mem_Set

	; zero out HRAM and interrupt enable flag
	ldz
	ld	c,$80
.zero_hram_loop
	ldh	[$ff00+c], a
	inc	c
	jp	nz,.zero_hram_loop

	; copy DMA code to hram
	ld	hl,DMACode
	ld	de,DMA
	ld	bc,sizeof("DMA")
	call	mem_Copy

	; enable sound registers
	ld	a,%10000000		; enable sound
	ld	[rAUDENA],a
	ld	a,%01110111		; left and right channel volume
	ld	[rAUDVOL],a
	ld	a,%00010010		; hard-pan PU1 (left) and PU2 (right) outputs
	ld	[rAUDTERM],a

	; enable PU1 and PU2
	ld	a,%10000011
	ld	[rNR52],a

	; write a triangle pattern to wave ram
	ld	hl,Wavetable
	ld	de,_AUD3WAVERAM
	ld	bc,16
	call	mem_Copy

def vram_addr = _TILE0

macro LoadTiles
	ld	hl,\1
	ld	de,vram_addr
def size = (\2) * SCRN_TILE_B
	ld	bc,size
	call	mem_Copy
def vram_addr = vram_addr + size
	if TWO_TILE_ALIGN
def vram_addr = vram_addr + vram_addr % (2 * SCRN_TILE_B)
	endc
endm

	; write tiles from ROM into tile memory
	LoadTiles Tileset,TilesetFrames
	LoadTiles Blacktile,BlacktileFrames
	LoadTiles Star,StarFrames
	LoadTiles Southward,SouthwardFrames

if TilesetBeginIndex != 0
	fail "the first tiles in tile memory must be the tileset used by the tilemap!"
endc

; blank screen
	ld	hl,_SCRN0
.loop
	ld	a,BlacktileBeginIndex
	ld	[hl+],a
	ld	a,l
	cp	low(_SCRN0 + $400)
	jp	nz,.loop
	ld	a,h
	cp	high(_SCRN0 + $400)
	jp	nz,.loop

; load initial screen of tiles
	ld	a,SCRN_VX_B - 1
	ld	[vram_ringr],a
	ld	a,$ff
	ld	[maploadr],a
rept SCRN_X_B + 1
	call ShowTilesR
endr

	; we start at 7,9 in lfoot coordinates
	ld	a,9
	ld	[lfootx],a
	ld	a,7
	ld	[lfooty],a

	; copy ROM SMT to RAM SMT and set OAM where needed
	ld	a,SMT_RAM_ENTRIES
	ld	[spr_index],a
	ld	hl,startof("ROM SMT")
	ld	bc,SMT_RAM
	ld	de,OAM_BUF
.smt_row
rept SMT_RAM_BYTES		; bytes 0-7 go to SMT RAM
	ld	a,[hl+]
	ld	[bc],a
	inc	bc
endr
rept 2				; bytes 8-10 go to OAM RAM
	ld	a,[hl+]
	ld	[de],a
	inc	de
endr
	inc	de		; don't set OAM tile yet
	inc	de		; don't set OAM attribute yet

	ld	a,[spr_index]
	dec	a
	ld	[spr_index],a
	jp	nz,.smt_row	; ...and loop if there's more sprites to process

	call	SpriteRecalculateAll	; set OAM tile id and attributes from SMT

	ld	a,LCDCF_ON | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_BGON | LCDCF_OBJ8 | LCDCF_OBJON
	; turn LCD on
	; use 8000-8FFF for bg and window tile data
	; use 9800-9BFF for tiles
	; enable background
	; use 8x8 sprites
	; enable sprites

	ld	[rLCDC],a

	; set up interrupt
	ld	a,IEF_VBLANK
	ld	[rIE],a
	ei

	; sleep CPU until vblank
	halt

	; start game loop (begin_main.asm) or run tests (begin_test.asm)
	jp	Begin

StopLCD:
	ld	a,[rLCDC]
	rlca			; Put the high bit of LCDC into the Carry flag
	ret	nc		; Screen is off already. Exit.

.wait
	; wait for vblank scan line 145
	ld	a,[rLY]
	cp	145
	jp	nz,.wait

	; turn off the LCD
	ld	a,[rLCDC]
	res	7,a
	ld	[rLCDC],a

	ret

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
