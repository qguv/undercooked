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
	ld	b,a
	ld	a,[hl]
	ld	c,a
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
	ld	c,a			; c <- sprite index
	ld	d,a			; hl <- SMT[sprite_index]
	ld	hl,SMT_RAM
.loop
	ld	a,SMT_RAM_BYTES
	addhla
	dec	d
	jp	nz,.loop
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
	ld	a,b			; if (SMT[sprite_index].animated) { return AdvanceAnimation(sprite_index); } (byte 0 bit 2)
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
	ld	a,[bc]		; _OAMRAM[sprite index].y -= dy
	sub	d
	ld	[bc],a
	inc	bc		; bc <- _OAMRAM[sprite_index].x
	ld	a,[dx]		; d <- dx
	ld	d,a
	ld	a,[bc]		; _OAMRAM[sprite index].x -= dx
	sub	d
	ld	[bc],a
	ret

; Update each sprite's animation counters in its (RAM) SMT state.
; FIXME don't update OAM, just call SpriteRecalculate__a after updating the SMT.
; arg a: sprite index in RAM SMT
SpriteAnimate__a:
	ld	c,a		; c <- i
	ld	d,a		; d <- i
	ld	hl,SMT_RAM	; hl <- &SMT[i]
.loop
	ld	a,SMT_RAM_BYTES
	addhla
	dec	d
	jp	nz,.loop
	ld	bc,_OAMRAM	; bc <- &OAM[i].tile
	ld	a,c
	sla	a
	sla	a
	inc	a
	inc	a
	addbca
	inc	hl		; d <- (byte 1 low nybble) animation stall amount
	ld	a,[hl]
	and	$0f
	ld	d,a
	ld	a,[hl]		; (byte 1 high nybble) animation stall counter -> a
	swap	a
	and	$0f
	jp	z,.stall_complete	; we animate only when the counter reaches zero
	dec	a		; decrease the animation stall counter
	swap	a		; combine the two nybbles
	or	d
	ld	[hl+],a		; write back to the RAM SMT
	ret
.stall_complete
	ld	a,d		; reset the stall counter to the stall amount
	swap	a		; combine the two nybbles
	or	d
	ld	[hl+],a		; stall counter and stall amount -> (byte 1)
	ld	a,[hl+]		; (byte 2) anim table length -> d
	ld	d,a
	ld	a,[hl]		; (byte 3) current anim table index -> a
	inc	a		; a++
	cp	d		; if current tile + 1 == length...
	jp	nz,.no_reset_animation
	ldz			; ...reset current tile to zero
.no_reset_animation
	ld	[hl+],a		; (byte 3) a -> current anim table index, -> tmp1
	ld	[tmp1],a
	ld	a,[hl+]		; de <- (byte 4-5) SMT[i].anim_table
	ld	e,a
	ld	a,[hl+]
	ld	d,a
	ld	a,[tmp1]	; de <- SMT[i].anim_table[f]
	adddea
	ld	a,[de]		; new tile index -> OAM current tile
	ld	[bc],a
	inc	bc
	ld	a,[hl+]		; de <- (byte 6-7) SMT[i].attr_table
	ld	e,a
	ld	a,[hl]
	ld	d,a
	ld	a,[tmp1]	; de <- SMT[i].attr_table[f]
	adddea
	ld	a,[de]
	ld	[bc],a		; new attrs -> OAM attrs
	ret
