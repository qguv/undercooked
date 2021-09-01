include "lib/gbhw.inc"		; hardware descriptions

section "tiles",ROM0

Blacktile:
	ds SCRN_TILE_B, $ff

Tileset:	incbin "obj/house.2bpp"
Tilemap:	incbin "obj/house.tilemap"
Star:		incbin "obj/star.2bpp"
Southward:	incbin "obj/southward.2bpp"
Westward:	incbin "obj/westward.2bpp"
Northward:	incbin "obj/northward.2bpp"
Eastward:	incbin "obj/eastward.2bpp"

; the tile indices of all the bg tiles you should be able to walk on
nonlava:
	db	$89						; kitchen tile
	db	$4e, $4f, $5e, $5f				; wood
	db	$11, $9f, $9e, $9d, $85, $73, $60, $61, $62	; carpet
	db	$63, $74, $86, $a0				; carpet, right edge
.end:

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
