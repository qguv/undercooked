include "lib/gbhw.inc"		; hardware descriptions
include "lib/debug.inc"		; debug instructions for bgb
include "src/optim.inc"		; optimized instruction aliases

include "src/interrupts.asm"

section "Org $100",ROM0[$100]
	nop
	jp	begin

	ROM_HEADER ROM_MBC1_RAM_BAT, ROM_SIZE_32KBYTE, RAM_SIZE_8KBYTE

include "lib/memory.asm"
include "src/music.asm"

; TODO use hw constants instead
VRAM_WIDTH equ $20
SCREEN_WIDTH equ 20

;------------------------,
; Configurable constants ;
;________________________'

TWO_TILE_ALIGN equ 0		; whether to align tiles so each new one starts on even-numbered tiles (useful for 8x16 sprites)
LEVEL_WIDTH equ 40
LEVEL_HEIGHT equ 18		; TODO redefine in terms of ((TilemapEnd - Tilemap) / LEVEL_WIDTH)
CHARACTER_HEIGHT equ 4
COLLISION_DETECTION equ 1	; whether to enable collision detection with the environment (bounds checking is always performed)

;-------,
; Tiles ;
;_______'

TILE_NUM set 0

; label name, number of frames, tiles per frame
registertiles: macro
\1Frames equ (\2)
\1BeginIndex equ TILE_NUM
TILE_NUM set TILE_NUM + \1Frames
if TWO_TILE_ALIGN
TILE_NUM set TILE_NUM + (TILE_NUM % 2)
endc
	endm

Tileset: incbin "obj/house.2bpp"
	registertiles	Tileset,$a1,1

; the tile indices of all the tiles you should be able to walk on
nonlava:
	db	$89						; kitchen tile
	db	$4e, $4f, $5e, $5f				; wood
	db	$11, $9f, $9e, $9d, $85, $73, $60, $61, $62	; carpet
	db	$63, $74, $86, $a0				; carpet, right edge
nonlava_end:

Tilemap: incbin "obj/house.tilemap"
TilemapEnd:

Blacktile:
rept SCRN_TILE_B
	db $ff
endr
	registertiles Blacktile,1

Star: incbin "obj/star.2bpp"
	registertiles Star,8

Southward: incbin "obj/southward.2bpp"
	registertiles Southward,10

;-------------------,
; Sprite Meta-Table ;
;___________________'

include "src/smt.inc"

StarAnimTab:
	db StarBeginIndex+0
	db StarBeginIndex+1
	db StarBeginIndex+2
	db StarBeginIndex+3
	db StarBeginIndex+4
	db StarBeginIndex+5
	db StarBeginIndex+6
	db StarBeginIndex+7

SouthwardEarAnimTab:
	db SouthwardBeginIndex+0
	db SouthwardBeginIndex+4

SouthwardHeadAnimTab:
	db SouthwardBeginIndex+1
	db SouthwardBeginIndex+5

SouthwardArmAnimTab:
	db SouthwardBeginIndex+2
	db SouthwardBeginIndex+6
	db SouthwardBeginIndex+2
	db SouthwardBeginIndex+7

SouthwardLegAnimTab:
	db SouthwardBeginIndex+3
	db SouthwardBeginIndex+8
	db SouthwardBeginIndex+3
	db SouthwardBeginIndex+9

SMT_ROM:
	AnimSprite lstar_sprite,SMTF_ACTIVE|SMTF_WORLD_FIXED,$5d,$2e,0,8,2,0,StarAnimTab
	AnimSprite rstar_sprite,SMTF_ACTIVE|SMTF_WORLD_FIXED,$6d,$2e,OAMF_XFLIP,8,2,4,StarAnimTab

	; cat facing southward
	AnimSprite earsl_sprite,SMTF_ACTIVE|SMTF_SCREEN_FIXED,$50,$4e,0,2,8,0,SouthwardEarAnimTab
	AnimSprite earsr_sprite,SMTF_ACTIVE|SMTF_SCREEN_FIXED,$58,$4e,OAMF_XFLIP,2,8,0,SouthwardEarAnimTab
	AnimSprite headl_sprite,SMTF_ACTIVE|SMTF_SCREEN_FIXED,$50,$56,0,2,8,0,SouthwardHeadAnimTab
	AnimSprite headr_sprite,SMTF_ACTIVE|SMTF_SCREEN_FIXED,$58,$56,OAMF_XFLIP,2,8,0,SouthwardHeadAnimTab
	AnimSprite armsl_sprite,SMTF_ACTIVE|SMTF_SCREEN_FIXED,$50,$5e,0,4,8,0,SouthwardArmAnimTab
	AnimSprite armsr_sprite,SMTF_ACTIVE|SMTF_SCREEN_FIXED,$58,$5e,OAMF_XFLIP,4,8,2,SouthwardArmAnimTab
	AnimSprite legsl_sprite,SMTF_ACTIVE|SMTF_SCREEN_FIXED,$50,$66,0,4,8,0,SouthwardLegAnimTab
	AnimSprite legsr_sprite,SMTF_ACTIVE|SMTF_SCREEN_FIXED,$58,$66,OAMF_XFLIP,4,8,2,SouthwardLegAnimTab

;---------------,
; Allocated RAM ;
;_______________'

		rsset _HIRAM
buttons		rb 1		; bitmask of which buttons are being held, $10 right, $20 left, $40 up, $80 down
song_repeated	rb 1		; when the song repeats for the first time, start scrolling
spr_index	rb 1		; used to loop through animating/moving sprites
note_dur	rb 1		; counter for frames within note
note_swindex	rb 1		; index into the swing table
note_index	rb 1		; index of note in song
duration	rb 1		; how many vblank frames of the current directive are left
vram_ringl	rb 1		; VRAM last loaded tile width index on the left (wraps around)
vram_ringr	rb 1		; VRAM last loaded tile width index on the right (wraps around)
maploadl	rb 1
maploadr	rb 1
map_oob		rb 1		; lsb = whether right side oob, 2nd lsb = whether left side oob
MAP_OOB_LEFT	set 2
MAP_OOB_RIGHT	set 1
dx		rb 1
dy		rb 1
lfootx		rb 1		; x position of left foot wrt the map, 0 is the furthest left you can go without hitting the wall
lfooty		rb 1		; y position of left foot wrt the map, 0 is the furthest up you can go without hitting your head

tmp1		rb 1
tmp2		rb 1

; character look direction: SOUTHWARD, WESTWARD, NORTHWARD, EASTWARD
direction	rb 1
SOUTHWARD	equ 0
WESTWARD	equ 1
NORTHWARD	equ 2
EASTWARD	equ 3

_HIRAM_END	rb 0
if _HIRAM_END > $fffe
	fail "Allocated HIRAM exceeds available HIRAM space!"
endc

		rsset _RAM
SMT_RAM		rb SPRITE_NUM * SMT_RAM_BYTES	; sprite meta-table, holding sprite animation and movement metadata
_RAM_END	rb 0
if _RAM_END > $dfff
	fail "Allocated RAM exceeds available RAM space!"
endc

;-------------,
; Entry point ;
;_____________'

begin::
	di
	ld	sp,$ffff
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

	; zero out allocated HRAM
	ldz
	ld	hl,_HIRAM
	ld	bc,_HIRAM_END-_HIRAM
	call	mem_Set

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

vram_addr set $8000

LoadTiles: macro
	ld	hl,\1
	ld	de,vram_addr
size	set	(\2) * SCRN_TILE_B
	ld	bc,size
	call	mem_Copy
vram_addr set vram_addr+size
	if TWO_TILE_ALIGN
vram_addr set vram_addr + vram_addr % (2 * SCRN_TILE_B)
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
	ld	a,VRAM_WIDTH - 1
	ld	[vram_ringr],a
	ld	a,$ff
	ld	[maploadr],a
rept SCREEN_WIDTH + 1
	call ShowTilesR
endr

	; we start at 7,9 in lfoot coordinates
	ld	a,9
	ld	[lfootx],a
	ld	a,7
	ld	[lfooty],a

	; copy ROM SMT to RAM SMT and set OAM where needed
	ld	a,SPRITE_NUM
	ld	[spr_index],a
	ld	hl,SMT_ROM
	ld	bc,SMT_RAM
	ld	de,_OAMRAM
.smt_row
rept 6				; bytes 0-5 go to SMT RAM
	ld	a,[hl+]
	ld	[bc],a
	inc	bc
endr
rept 4				; bytes 6-9 go to OAM RAM
	ld	a,[hl+]
	ld	[de],a
	inc	de
endr
	ld	a,[spr_index]
	dec	a
	ld	[spr_index],a
	jp	nz,.smt_row		; ...and loop if there's more sprites to process

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

.wait
	; wait for vblank
	halt
	nop
	jp	.wait

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
rept 6
	ld	A,[rP1]		; Wait a few MORE cycles
endr
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

include "src/tiles.asm"
include "src/sprites.asm"

VBlank::
	ld	a,[duration]
	cpz
	jp nz,.scroll_screen		; if the walk cycle isn't over, don't read buttons, just scroll

;walkcycleover
	call ReadJoypad
	ld	a,[buttons]
	and	$f0			; is a movement button held?
	jp	nz,.parsemovement	; if so, process it
.haltmovement
	ldz				; clear out current movement command
	ld	[dx],a
	ld	[dy],a
	jp	.end_movement

.parsemovement				; also does bounds checks
	ld	a,[buttons]
	and	PADF_UP | PADF_DOWN	; moving up or down?
	cpz
	jp	z,.xmovement
;ymovement
	and	PADF_UP			; moving up?
	cpz
	jp	nz,.up
;down
	ld	a,SOUTHWARD		; turn
	ld	[direction],a
	ld	a,[lfooty]		;if you're at the bottom edge, you can't move down
	cp	LEVEL_HEIGHT - CHARACTER_HEIGHT - 1
	jp	z,.haltmovement
	ld	a,1			; move down
	ld	[dy],a
	ldz
	ld	[dx],a
	jp	.collision
.up
	ld	a,NORTHWARD		; turn
	ld	[direction],a
	ld	a,[lfooty]		; if you're at the top edge, you can't move up
	cpz
	jp	z,.haltmovement
	ld	a,$ff			; move up
	ld	[dy],a
	ldz
	ld	[dx],a
	jp	.collision
.xmovement
	ld	a,[buttons]
	and	PADF_LEFT		; moving left?
	cpz
	jp	nz,.left
;right
	ld	a,EASTWARD		; turn
	ld	[direction],a
	ld	a,[lfootx]		; if you're at the rightmost edge, you can't move right
	cp	LEVEL_WIDTH - 2		; (subtract one to account for your RIGHT foot and one because you need to check it earlier)
	jp	z,.haltmovement
	ld	a,1			; move right
	ld	[dx],a
	ldz
	ld	[dy],a
	jp	.collision
.left
	ld	a,WESTWARD		; turn
	ld	[direction],a
	ld	a,[lfootx]		; if you're at the leftmost edge, you can't move left
	cpz
	jp	z,.haltmovement
	ld	a,$ff			; move left
	ld	[dx],a
	ldz
	ld	[dy],a
	;jp	.collision

.collision
if !COLLISION_DETECTION
	jp	.collision_end
endc
	; at (lfootx,lfooty) we test tilemap entry = firsttile + (40 * lfooty) + lfootx
	; where firsttile represents the tile (with respect to the "real" tile map)
	; that your left foot is standing on when you're at the lfoot origin
	ld	hl,Tilemap	; Tilemap[] -> hl
	ld	b,0		; firsttile -> bc
	ld	c,CHARACTER_HEIGHT * LEVEL_WIDTH
	add	hl,bc		; Tilemap[firsttile] -> hl
	ld	a,[dx]		; dx -> c
	ld	c,a
	ld	a,[lfootx]	; lfootx -> a
	add	c		; lfootx + dx -> a
	ld	b,0		; lfootx + dx -> bc
	ld	c,a
	add	hl,bc		; hl = Tilemap[firsttile + lfootx + dx]
	ld	a,[dy]		; dy -> c
	ld	c,a
	ld	a,[lfooty]	; lfooty -> a
	add	c		; lfooty + dy -> a
	ld	b,0		; 40 -> bc
	ld	c,40
	cpz
	jp	.mulcheck
.muladd
	add	hl,bc
	dec	a
.mulcheck
	jp	nz,.muladd
;mulend				; hl = Tilemap[firsttile + (lfootx + dx) + ((lfooty + dy) * 40)]
rept 2				; once for each foot
	ld	a,[hl+]		; left foot tile -> e
	ld	e,a
	ld	d,nonlava_end-nonlava	; number of entries in nonlava table
	ld	bc,nonlava	; nonlava[] -> bc
.nexttile\@
	ld	a,[bc]		; nonlava[i] -> a
	cp	e		; if this tile is a nonlava tile, move onto the next foot
	jp	z,.nextfoot\@
	inc	bc		; otherwise, i++
	dec	d
	cpz
	jp	nz,.nexttile\@
	jp	.haltmovement	; if we run out of tiles without jumping to the next foot, it's lava!
.nextfoot\@
endr
.collision_end

	call	ShowTiles	; load in a new line of tiles if necessary

	; update lfootx and lfooty to new coordinates
	ld	a,[dx]		; dx -> b
	ld	b,a
	ld	a,[lfootx]	; lfootx -> a
	add	b		; lfootx + dx -> a
	ld	[lfootx],a	; lfootx += dx
	ld	a,[dy]		; dy -> b
	ld	b,a
	ld	a,[lfooty]	; lfooty -> a
	add	b		; lfooty + dy -> a
	ld	[lfooty],a	; lfooty += dy

	; restart animation counter
	ld	a,8
	ld	[duration],a

.scroll_screen
	ld	a,[duration]
	dec	a
	ld	[duration],a

	; scroll bg viewport rightward by dx
	ld	a,[dx]		; dx -> b
	ld	b,a
	ld	a,[rSCX]	; rSCX -> a
	add	b		; rSCX + dx -> a
	ld	[rSCX],a	; rSCX += dx

.skip_movement
	; scroll bg viewport downward by dy
	ld	a,[dy]		; dy -> b
	ld	b,a
	ld	a,[rSCY]	; rSCY -> a
	add	b		; rSCY + dy -> a
	ld	[rSCY],a	; rSCY += dy
.end_movement

	call AnimateSprites

HandleNotes:
	ld	a,[note_dur]		; if duration of previous note is expired, continue
	cpz
	jp	z,.next_note
	dec	a			; otherwise decrement and return
	ld	[note_dur],a
	reti

.next_note
	ld	a,[note_swindex]
	ld	hl,NoteDuration
	addhla				; add index into note duration table
	ld	a,[hl]			; set next note duration
	ld	[note_dur],a
	ld	a,[note_swindex]	; increase note swing index
	inc	a
	cp	NoteDurationEnd-NoteDuration	; wrap if necessary
	jp	c,.dont_wrap
	ldz
.dont_wrap
	ld	[note_swindex],a
	ld	a,[note_index]		; get note index
	cp	a,SongLength-1		; if hPU1NoteIndex isn't zero, fine...
	jp	nz,.sound_registers
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
	jp	z,.end\@

	cp	KILL			; if it's a kill command, stop the note
	jp	nz,.nocut\@
	ldz
	ld	[\6],a
	ld	a,$80
	ld	[\8],a
	jp	.end\@
.nocut\@

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
	pulsenote	NotesPU1,%00111111,$F1,rAUD1SWEEP,rAUD1LEN,rAUD1ENV,rAUD1LOW,rAUD1HIGH
	pulsenote	NotesPU2,%10111111,$C3,rAUD2LOW,rAUD2LEN,rAUD2ENV,rAUD2LOW,rAUD2HIGH ; TODO: skip sweep appropriately

	ld	a,[note_index]	; increment index of note in song
	inc	a
	and	SongLength-1
	ld	[note_index],a

	reti

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
