; if we're moving left or right, load new tiles into VRAM before they're visible
ShowTiles:
	ld	a,[dx]		; if (dx == 1) { return ShowTilesR(); }
	cp	1
	jp	z,CheckShowTilesR
	cp	$ff		; else if (dx == -1) { return ShowTilesL(); }
	jp	z,CheckShowTilesL
	ret			; else { return; }

; do we need to load new tiles to the right?
CheckShowTilesR:
	ld	a,[rSCX]	; b <- about-to-be-seen rightmost column
rept 3
	srl	a
endr
	add	SCRN_X_B
	and	SCRN_VX_B - 1
	ld	b,a
	ld	a,[vram_ringr]	; if (rightmost loaded column != about-to-be-seen rightmost column) { return; }
	cp	b
	ret	nz
	call	ShowTilesR
	ld	a,[vram_ringr]	; b <- new rightmost loaded column
	ld	b,a
	ld	a,[vram_ringl]	; if (leftmost loaded column == new rightmost loaded column) { return UnloadTilesL(); }
	cp	b
	jp	z,UnloadTilesL
	ret

; do we need to load new tiles to the left?
CheckShowTilesL:
	ld	a,[rSCX]	; b <- about-to-be-seen leftmost column
rept 3
	srl	a
endr
	add	SCRN_VX_B - 1
	and	SCRN_VX_B - 1
	ld	b,a
	ld	a,[vram_ringl]	; if (leftmost loaded column != about-to-be-seen leftmost column) { return; }
	cp	b
	ret	nz
	call	ShowTilesL
	ld	a,[vram_ringl]	; b <- new leftmost loaded column
	ld	b,a
	ld	a,[vram_ringr]	; if (rightmost loaded column == new leftmost loaded column) { return UnloadTilesR(); }
	cp	b
	jp	z,UnloadTilesR
	ret

; load another column of tiles to the left of the last left-loaded column
ShowTilesR:
	ld	a,[vram_ringr]	; rightmost loaded column++ mod SCRN_VX_B
	inc	a
	and	SCRN_VX_B - 1
	ld	[vram_ringr],a
	ld	a,[maploadr]	; rightmost loaded map position++
	inc	a
	ld	[maploadr],a
	call	UpdateRightOob
	ld	a,[map_oob]	; if (out of bounds on the right) { return ShowBlankTilesR(); }
	and	MAP_OOB_RIGHT
	jp	nz,ShowBlankTilesR
	ld	a,[vram_ringr]		; b <- rightmost VRAM column
	ld	b,a
	ld	a,[maploadr]		; c <- rightmost map column
	ld	c,a
	jp	ShowRealTiles__ab
	;ret

; load another column of tiles to the left of the last left-loaded column
ShowTilesL:
	ld	a,[vram_ringl]	; leftmost loaded column-- mod SCRN_VX_B
	add	SCRN_VX_B - 1
	and	SCRN_VX_B - 1
	ld	[vram_ringl],a
	ld	a,[maploadl]	; leftmost loaded map position--
	dec	a
	ld	[maploadl],a
	call UpdateLeftOob
	ld	a,[map_oob]	; if (out of bounds on the left) { return ShowBlankTilesL(); }
	and	MAP_OOB_LEFT
	jp	nz,ShowBlankTilesL
	ld	a,[vram_ringl]		; b <- leftmost VRAM column
	ld	b,a
	ld	a,[maploadl]		; a <- leftmost map column
	jp	ShowRealTiles__ab
	;ret

UpdateRightOob:
	ld	a,[maploadr]	; if (maploadr != LEVEL_WIDTH) { return; }
	cp	LEVEL_WIDTH
	ret	nz
	ld	b,MAP_OOB_RIGHT	; map oob right = true
	ld	a,[map_oob]
	or	b
	ld	[map_oob],a
	ret

UpdateLeftOob:
	ld	a,[maploadl]	; if (maploadl != -1) { return; }
	inc	a
	ret	nz
	ld	b,MAP_OOB_LEFT	; map oob left = true
	ld	a,[map_oob]
	or	b
	ld	[map_oob],a
	ret

UnloadTilesL:
	ld	a,[vram_ringl]	; vram_ringl++ mod SCRN_VX_B
	inc	a
	and	SCRN_VX_B - 1
	ld	[vram_ringl],a
	ld	a,[maploadl]	; maploadl++
	inc	a
	ld	[maploadl],a
	cpz			; if (maploadl != 0) { return; }
	ret	z
	ld	a,[map_oob]	; map_oob_left = false;
	and	~MAP_OOB_LEFT
	ld	[map_oob],a
	ret

UnloadTilesR:
	ld	a,[vram_ringr]	; vram_ringr-- mod SCRN_VX_B
	add	SCRN_VX_B - 1
	and	SCRN_VX_B - 1
	ld	[vram_ringr],a
	ld	a,[maploadr]	; maploadr--
	dec	a
	ld	[maploadr],a
	cp	LEVEL_WIDTH - 1	; if (maploadr != LEVEL_WIDTH - 1) { return; }
	ret	z
	ld	a,[map_oob]	; map_oob_right = false;
	and	~MAP_OOB_RIGHT
	ld	[map_oob],a
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
	ld	a,BlacktileBeginIndex
	ld	[hl],a
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
