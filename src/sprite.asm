; Update each sprite's animation, then update OAM buffer with its new position, animation frame, and flags.
SpriteUpdateAll:
	ld	bc,0		; b <- OAM (active) sprite counter
				; c <- SMT sprite counter
	ld	hl,SMT_RAM
.loop
	ld	a,[hl]		; if sprite isn't active
	and	SMTF_ACTIVE
	jp	z,.skip	; skip it
	push	bc		; SpriteUpdate(oam counter, SMT address)
	push	hl
	ld	a,b
	call	SpriteUpdate__ahl
	pop	hl
	pop	bc
	push	bc		; SpriteRecalculate(oam counter, SMT address)
	push	hl
	ld	a,b
	call	SpriteRecalculate__ahl
	pop	hl
	pop	bc
	inc	b
.skip
	inc	c
	ld	a,c
	cp	(SmtRomEnd - SmtRom) / SMT_ROM_BYTES
	ret	z
	ld	a,SMT_RAM_BYTES
	addhla
	jp	.loop
	;ret

; Update a sprite's animation, then update OAM buffer with its new position, animation frame, and flags.
; arg a: sprite index in OAM
; arg hl: beginning of SMT entry
SpriteUpdate__ahl:
	ld	c,a			; c <- i
	ld	a,[hl]			; b <- SMT[sprite_index].flags (byte 0)
	ld	b,a
	;ld	a,b
	and	SMTF_WORLD_FIXED	; if ((SMT[sprite_index] <- b).world_fixed) { SpriteFollowBackground(sprite_index <- c); } (byte 0 bit 1)
	jp	z,.no_follow_background
	push	bc
	push	hl
	ld	a,c
	call	SpriteFollowBackground__a
	pop	hl
	pop	bc
.no_follow_background
	ld	a,[dx]			; flags_trigger_animate <- (dx || dy) ? SMTF_PLAYER|SMTF_ANIMATED : SMTF_ANIMATED;
	cpz
	jp	nz,.player_animates
	ld	a,[dy]
	cpz
	jp	nz,.player_animates
	ldz
	jp	.player_doesnt_animate
.player_animates
	ld	a,SMTF_PLAYER
.player_doesnt_animate
	or	SMTF_ANIMATED
	and	b			; if (SMT[sprite_index].flags & flags_trigger_animate) { return SpriteAnimate(sprite_index); }
	ld	a,c
	jp	nz,SpriteAnimate__ahl
	ld	a,SMTF_PLAYER		; else if (!SMT[i].player) { return; }
	and	b
	ret	z
					; else /* SMT[i].player */ { SMT[i][3] = 0; return SpriteRecalculate(i); }
	inc	hl			; hl <- SMT[i][3]
	inc	hl
	inc	hl
	ld	a,[hl]			; SMT[i][3] %= 2
					; FIXME this is a hack!
	and	%11111110
	ld	[hl],a			; SMT[i][3] = 0
	ret

; Update a sprite's OAM buffer position so it remains fixed to its position in the background.
; arg a: sprite index in OAM
SpriteFollowBackground__a:
	ld	bc,OAM_BUF	; bc <- OAM_BUF[sprite index].y
	sla	a
	sla	a
	addbca
	ld	a,[dy]		; d <- dy
	ld	d,a
	; FIXME suspicious OOB VRAM access @ FE00-FE05 breaking sprites 0 and 1
	ld	a,[bc]		; OAM_BUF[sprite index].y -= dy
	sub	d
	ld	[bc],a
	inc	bc		; bc <- OAM_BUF[sprite_index].x
	ld	a,[dx]		; d <- dx
	ld	d,a
	ld	a,[bc]		; OAM_BUF[sprite index].x -= dx
	sub	d
	; FIXME suspicious OOB VRAM access @ FE00-FE05 breaking sprites 0 and 1
	ld	[bc],a
	ret

; Update a sprite's animation counters in its (RAM) SMT state and update tile index and attributes in OAM buffer
; arg a: sprite index in RAM SMT
SpriteAnimate__ahl:
	ld	b,a		; b <- i
	ld	c,a		; c <- i
	inc	hl		; hl <- &SMT[i][1]
	ld	a,[hl]		; b <- (byte 1 low nybble) animation stall amount
	and	$0f
	ld	b,a
	ld	a,[hl]		; a <- (byte 1 high nybble) animation stall counter
	swap	a
	and	$0f
	jp	z,.stall_complete	; we animate only when the counter reaches zero
	dec	a		; decrease the animation stall counter
	swap	a		; combine the two nybbles
	or	b
	ld	[hl],a		; write back to the RAM SMT
	ret
.stall_complete
	ld	a,b		; reset the stall counter to the stall amount
	swap	a		; combine the two nybbles
	or	b
	ld	[hl+],a		; (byte 1) <- stall counter and stall amount
	;			; hl <- &SMT[i][2]
	ld	a,[hl+]		; d <- (byte 2) anim table length
	ld	d,a
	;			; hl <- &SMT[i][3]
	ld	a,[hl]		; a <- (byte 3) current anim table index
	inc	a		; a++
	cp	d		; if current tile + 1 == length...
	jp	nz,.no_reset_animation
	ldz			; ...reset current tile to zero
.no_reset_animation
	ld	[hl],a		; (byte 3) <- current anim table index
	ret

; Set each sprite's OAM tile index and attributes from its (RAM) SMT state.
SpriteRecalculateAll:
	ld	bc,0		; b <- OAM (active) sprite counter
				; c <- SMT sprite counter
	ld	hl,SMT_RAM
.loop
	ld	a,[hl]		; if sprite isn't active
	and	SMTF_ACTIVE
	jp	z,.skip		; skip it
	push	bc		; SpriteRecalculate(oam counter, SMT address)
	push	hl
	ld	a,b
	call	SpriteRecalculate__ahl
	pop	hl
	pop	bc
	inc	b
.skip
	inc	c
	ld	a,c
	cp	(SmtRomEnd - SmtRom) / SMT_ROM_BYTES
	ret	z
	ld	a,SMT_RAM_BYTES
	addhla
	jp	.loop
	;ret

; Set a sprite's tile index and attributes in the OAM buffer from its (RAM) SMT state.
; arg a: sprite index in OAM
; arg hl: address of SMT row
SpriteRecalculate__ahl:
	push	af
	inc	hl
	inc	hl
	inc	hl
	ld	a,[hl+]			; d <- SMT[sprite_index].anim_counter
	ld	d,a
	;				; hl <- &SMT[sprite_index].anim_table_address
	ld	a,[hl+]			; bc <- &anim_table
	ld	c,a
	ld	a,[hl+]
	ld	b,a
	;				; hl <- &SMT[sprite_index].flag_table_address
	ld	a,d			; bc <- &anim_table[anim_counter]
	addbca
	ld	a,[bc]			; e <- anim_table[anim_counter]
	ld	e,a
	ld	a,[hl+]			; bc <- &flag_table
	ld	c,a
	ld	a,[hl]
	ld	b,a
	ld	a,d			; bc <- &flag_table[anim_counter]
	addbca
	ld	a,[bc]			; d <- flag_table[anim_counter]
	ld	d,a
	pop	af			; a <- OAM sprite index
	ld	hl,OAM_BUF		; hl <- &OAM_BUF[sprite_index]
	sla	a			; hl <- &OAM_BUF[sprite_index].tile_id
	sla	a
	inc	a
	inc	a
	addhla
	ld	a,e			; OAM_BUF[sprite_index].tile_id <- anim_table[anim_counter]
	ld	[hl+],a
	;				; hl <- &OAM_BUF[sprite_index].attrs
	ld	[hl],d			; OAM_BUF[sprite_index].attrs <- flag_table[anim_counter]
	ret
