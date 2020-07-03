AnimateSprites:
	ld	a,SPRITE_NUM
.loop
	dec	a
	push	af			; stack <- sprite_index
	call	UpdateSprite__a		; UpdateSprite(sprite_index)
	pop	af			; (sprite_index <- stack)--;
	jp	nz,.loop

; arg a: sprite index in RAM SMT
UpdateSprite__a:
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
	call	nz,PositionUpdate__a
	pop	bc
	ld	a,b			; if (SMT[sprite_index].animated) { return AdvanceAnimation(sprite_index); } (byte 0 bit 2)
	and	SMTF_ANIMATED
	ld	a,c
	jp	nz,AdvanceAnimation__a
	ret

; arg a: sprite index in RAM SMT
PositionUpdate__a:
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

; arg a: sprite index in RAM SMT
AdvanceAnimation__a:
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
