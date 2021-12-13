include "lib/gbhw.inc"		; hardware descriptions
include "src/optim.inc"		; optimized instruction aliases
include "src/tiles.inc"		; tile constants

CHARACTER_HEIGHT equ 4
COLLISION_DETECTION equ 1	; whether to enable collision detection with the environment (bounds checking is always performed)

section "input variables",HRAM
Direction:	db		; character look direction: SOUTHWARD, WESTWARD, NORTHWARD, EASTWARD
SOUTHWARD	equ 0
WESTWARD	equ 1
NORTHWARD	equ 2
EASTWARD	equ 3

section "input",ROM0

Input::
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
	ld	[Direction],a
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
	ld	[Direction],a
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
	ld	[Direction],a
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
	ld	[Direction],a
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
	ld	d,nonlava.end-nonlava	; number of entries in nonlava table
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

	call SpriteLoadPlayerCharacter
	call SpriteUpdateAll
	jp HandleNotes
	;ret

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
