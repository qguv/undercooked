; Set a sprite's OAM tile index and attributes from its (RAM) SMT state.
; arg a: sprite index in RAM SMT
SpriteRecalculate__a:
	ld	b,a			; b <- sprite index
	ld	hl,OAM_BUF		; hl <- &OAM_BUF[sprite_index].tile_id
	sla	a
	sla	a
	inc	a
	inc	a
	addhla
	push	hl			; save &OAM_BUF[sprite_index].tile_id
	ld	hl,SMT_RAM		; hl <- &SMT[sprite_index]
	ld	a,b
if SMT_RAM_BYTES == 8
rept 3
	sla	a
endr
else
fail "optimization for `a *= SMT_RAM_BYTES` via rotation in SpriteRecalculate__a in src/sprites.asm no longer applies!"
endc
rept 3					; hl <- &SMT[sprite_index].anim_counter
	inc	a
endr
	addhla
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
	pop	hl			; hl <- &OAM_BUF[sprite_index].tile_id
	ld	a,e			; OAM_BUF[sprite_index].tile_id <- anim_table[anim_counter]
	ld	[hl+],a
	;				; hl <- &OAM_BUF[sprite_index].attrs
	ld	[hl],d			; OAM_BUF[sprite_index].attrs <- flag_table[anim_counter]
	ret

; Set each sprite's OAM tile index and attributes from its (RAM) SMT state.
SpriteRecalculateAll:
	ld	a,((SmtRomEnd - SmtRom) / SMT_ROM_BYTES)
.loop
	dec	a
	push	af
	call	SpriteRecalculate__a
	pop	af
	jp	nz,.loop
	ret

; Update each sprite's animation, then update OAM RAM with its new position, animation frame, and flags. Call this every VBLANK.
SpriteUpdateAll:
	ld	a,(SmtRomEnd - SmtRom) / SMT_ROM_BYTES
.loop
	dec	a
	push	af
	call	SpriteUpdate__a
	pop	af
	jp	nz,.loop
	ret

; Update a sprite's animation, then update OAM RAM with its new position, animation frame, and flags.
; arg a: sprite index in RAM SMT
SpriteUpdate__a:
	ld	c,a			; c <- i
	ld	hl,SMT_RAM		; hl <- &SMT[i]
if SMT_RAM_BYTES == 8
rept 3
	sla	a
endr
else
fail "optimization for `a *= SMT_RAM_BYTES` via rotation in SpriteUpdate__a in src/sprites.asm no longer applies!"
endc
	addhla
	ld	a,[hl]			; b <- SMT[sprite_index].flags (byte 0)
	ld	b,a
	and	SMTF_ACTIVE		; if (!SMT[sprite_index].active) { return; } (byte 0 LSB)
	ret	z
	ld	a,b			; if ((SMT[sprite_index] <- b).world_fixed) { SpriteFollowBackground(sprite_index <- c); } (byte 0 bit 1)
	and	SMTF_WORLD_FIXED
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
	and	b			; if (SMT[sprite_index].flags && flags_trigger_animate) { return SpriteAnimate(sprite_index); }
	ld	a,c
	jp	nz,SpriteAnimate__a
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
	ld	a,c
	jp	SpriteRecalculate__a
	;ret

; Update a sprite's OAM position so it remains fixed to its position in the background.
; arg a: sprite index in RAM SMT
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

; Update a sprite's animation counters in its (RAM) SMT state and update tile index and attributes in OAM.
; arg a: sprite index in RAM SMT
SpriteAnimate__a:
	ld	b,a		; b <- i
	ld	c,a		; c <- i
	ld	hl,SMT_RAM	; hl <- &SMT[i]
if SMT_RAM_BYTES == 8
rept 3
	sla	a
endr
else
fail "optimization for `a *= SMT_RAM_BYTES` via rotation in SpriteAnimate__a in src/sprites.asm no longer applies!"
endc
	addhla
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
	ld	a,c
	jp	SpriteRecalculate__a
	;ret
