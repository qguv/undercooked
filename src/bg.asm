include "lib/gbhw.inc"		; hardware descriptions
include "src/optim.inc"		; optimized instruction aliases
include "src/tiles.inc"		; tile constants

section "background gfx",ROM0

; if we're moving left or right, load new tiles into VRAM before they're visible
ShowTiles:
	ld	a,[dx]		; if (dx == 1) { return ShowTilesR(); }
	cp	1
	jp	z,CheckShowTilesR
	cp	$ff		; else if (dx == -1) { return ShowTilesL(); }
	jp	z,CheckShowTilesL
	ret

; do we need to load new tiles to the right?
CheckShowTilesR:
	ld	a,[rSCX]	; a <- about-to-be-seen rightmost pixel
if SCRN_VX != $100
	fail	strfmt("[%s:%d] relying on overflow", __FILE__, __LINE__)
endc
	add	SCRN_X
rept 3				; b <- about-to-be-seen rightmost vram column
	srl	a
endr
	ld	b,a
	ld	a,[vram_ringr]	; if (rightmost loaded column != about-to-be-seen rightmost column) { return; }
	cp	b
	ret	nz
	call	ShowTilesR	; ShowTilesR();
	ld	a,[vram_ringr]	; b <- new rightmost loaded column
	ld	b,a
	ld	a,[vram_ringl]	; if (leftmost loaded column == new rightmost loaded column) { return UnloadTilesL(); }
	cp	b
	jp	z,UnloadTilesL
	ret

; do we need to load new tiles to the left?
CheckShowTilesL:
	ld	a,[rSCX]	; a <- about-to-be-seen leftmost pixel
if SCRN_VX != $100
	fail	strfmt("[%s:%d] relying on overflow", __FILE__, __LINE__)
endc
	sub	8
rept 3				; b <- about-to-be-seen leftmost column
	srl	a
endr
	ld	b,a
	ld	a,[vram_ringl]	; if (leftmost loaded column != about-to-be-seen leftmost column) { return; }
	cp	b
	ret	nz
	call	ShowTilesL	; ShowTilesL();
	ld	a,[vram_ringl]	; b <- new leftmost loaded column
	ld	b,a
	ld	a,[vram_ringr]	; if (rightmost loaded column == new leftmost loaded column) { return UnloadTilesR(); }
	cp	b
	jp	z,UnloadTilesR
	ret

; load another column of tiles to the right of the last right-loaded column
ShowTilesR:
	ld	a,[vram_ringr]	; b <- rightmost loaded vram column++ mod SCRN_VX_B
	inc	a
	and	SCRN_VX_B - 1
	ld	b,a
	ld	[vram_ringr],a
	ld	a,[maploadr]	; c <- rightmost loaded map column
	inc	a
	ld	[maploadr],a
	ld	c,a
	cp	LEVEL_WIDTH	; if (rightmost loaded map column >= LEVEL_WIDTH)
	jp	nc,ShowBlankTilesR	; return ShowBlankTilesR();
	ld	a,c		; return ShowRealTiles(leftmost loaded map column, leftmost loaded vram column);
	jp	ShowRealTiles__ab
	; ret

; load another column of tiles to the left of the last left-loaded column
ShowTilesL:
	ld	a,[vram_ringl]	; b <- --leftmost loaded vram column mod SCRN_VX_B
	add	SCRN_VX_B - 1
	and	SCRN_VX_B - 1
	ld	b,a
	ld	[vram_ringl],a
	ld	a,[maploadl]	; c <- --leftmost loaded map column
	dec	a
	ld	c,a
	ld	[maploadl],a
	and	$80		; if ((signed) leftmost loaded map column < 0)
	jp	nz,ShowBlankTilesL	; return ShowBlankTilesL();
	ld	a,c		; return ShowRealTiles(leftmost loaded map column, leftmost loaded vram column);
	jp	ShowRealTiles__ab
	;ret

UnloadTilesL:
	ld	a,[vram_ringl]	; vram_ringl++ mod SCRN_VX_B
	inc	a
	and	SCRN_VX_B - 1
	ld	[vram_ringl],a
	ld	a,[maploadl]	; maploadl++
	inc	a
	ld	[maploadl],a
	ret

UnloadTilesR:
	ld	a,[vram_ringr]	; vram_ringr-- mod SCRN_VX_B
	add	SCRN_VX_B - 1
	and	SCRN_VX_B - 1
	ld	[vram_ringr],a
	ld	a,[maploadr]	; maploadr--
	dec	a
	ld	[maploadr],a
	ret

ShowBlankTilesR:
	ld	a,[vram_ringr]
	jp	ShowBlankTiles__a
	;ret

ShowBlankTilesL:
	ld	a,[vram_ringl]
	jp	ShowBlankTiles__a
	;ret

; arg a: vram index to start
ShowBlankTiles__a:
	ld	hl,_SCRN0
	addhla
rept LEVEL_HEIGHT
	ld	[hl],BlacktileBeginIndex
	ld	a,$20
	addhla
endr
	ret

; arg a: max map column
; arg b: max VRAM column
ShowRealTiles__ab:
	ld	hl,Tilemap		; hl <- Tilemap + new max map column
	addhla
	ld	a,b			; de <- _SCRN0 + new max VRAM column
	ld	de,_SCRN0
	adddea
rept LEVEL_HEIGHT
	ld	a,[hl]			; *de = *hl
	ld	[de],a
	ld	a,LEVEL_WIDTH		; hl += world_width
	addhla
	ld	a,SCRN_VX_B		; de += SCRN_VX_B
	adddea
endr
	ret

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
