; Set a sprite's OAM tile index and attributes from its (RAM) SMT state.
; arg a: sprite index in RAM SMT
SpriteRecalculate__a:
	ld	b,a			; b <- sprite index
	ld	hl,_OAMRAM		; hl <- &OAMRAM[sprite_index].tile_id
	sla	a
	sla	a
	inc	a
	inc	a
	addhla
	push	hl			; save &OAMRAM[sprite_index]
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
	; push	hl
	; pop	hl
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
	pop	hl			; hl <- &OAMRAM[sprite_index].tile_id
	ld	a,e			; OAMRAM[sprite_index].tile_id <- anim_table[anim_counter]
	ld	[hl+],a
	;				; hl <- &OAMRAM[sprite_index].attrs
	ld	a,d			; OAMRAM[sprite_index].attrs <- flag_table[anim_counter]
	ld	[hl],a
	ret

; Set each sprite's OAM tile index and attributes from its (RAM) SMT state.
SpriteRecalculateAll:
	ld	a,SPRITE_NUM
.loop
	dec	a
	push	af
	call	SpriteRecalculate__a
	pop	af
	jp	nz,.loop
	ret

; Update each sprite's animation, then update OAM RAM with its new position, animation frame, and flags. Call this every VBLANK.
SpriteUpdateAll:
	ld	a,SPRITE_NUM
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
	cpz
	jp	z,.got_smt_entry
.next_smt_entry
	ld	d,a
	ld	a,SMT_RAM_BYTES
	addhla
	ld	a,d
	dec	a
	cpz
	jp	nz,.next_smt_entry
.got_smt_entry
	ld	a,[hl]			; b <- SMT[sprite_index].flags (byte 0)
	ld	b,a
	push	bc
	and	SMTF_ACTIVE		; if (!SMT[sprite_index].active) { return; } (byte 0 LSB)
	ret	z
	ld	a,b			; if ((SMT[sprite_index] <- b).world_fixed) { PositionUpdate(sprite_index <- c); } (byte 0 bit 1)
	and	SMTF_WORLD_FIXED
	ld	a,c
	call	nz,SpriteFollowBackground__a
	pop	bc
	ld	a,b			; if (SMT[sprite_index].animated) { return SpriteAnimate(sprite_index); } (byte 0 bit 2)
	and	SMTF_ANIMATED
	ld	a,c
	jp	nz,SpriteAnimate__a
	ret

; Update a sprite's OAM position so it remains fixed to its position in the background.
; arg a: sprite index in RAM SMT
SpriteFollowBackground__a:
	ld	bc,_OAMRAM	; bc <- _OAMRAM[sprite index].y
	sla	a
	sla	a
	addbca
	ld	a,[dy]		; d <- dy
	ld	d,a
	; FIXME suspicious OOB VRAM access @ FE00-FE05 breaking sprites 0 and 1
	ld	a,[bc]		; _OAMRAM[sprite index].y -= dy
	sub	d
	ld	[bc],a
	inc	bc		; bc <- _OAMRAM[sprite_index].x
	ld	a,[dx]		; d <- dx
	ld	d,a
	ld	a,[bc]		; _OAMRAM[sprite index].x -= dx
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
.loop
	ld	a,SMT_RAM_BYTES
	addhla
	dec	b
	jp	nz,.loop
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
