include "lib/gbhw.inc"		; hardware descriptions

section "tiles",ROM0

Blacktile:
	ds SCRN_TILE_B, $ff

Tileset:	incbin "obj/house.2bpp"
Tilemap:	incbin "obj/house.tilemap"
Star:		incbin "obj/star.2bpp"
Cat:		incbin "obj/cat.2bpp"
Cat_map:	incbin "obj/cat.tilemap"
Cat_attrs:	incbin "obj/cat.attrmap"

; the tile indices of all the bg tiles you should be able to walk on
nonlava:
	db	$89						; kitchen tile
	db	$4e, $4f, $5e, $5f				; wood
	db	$11, $9f, $9e, $9d, $85, $73, $60, $61, $62	; carpet
	db	$63, $74, $86, $a0				; carpet, right edge
.end:

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
