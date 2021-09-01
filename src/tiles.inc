TWO_TILE_ALIGN equ 0		; whether to align tiles so each new one starts on even-numbered tiles (useful for 8x16 sprites)
LEVEL_WIDTH equ 40
LEVEL_HEIGHT equ 18		; TODO redefine in terms of ((TilemapEnd - Tilemap) / LEVEL_WIDTH)

TILE_NUM set 0

; label name, number of frames, tiles per frame
registertiles: macro
\1Frames equ (\2)
\1BeginIndex equ TILE_NUM
TILE_NUM set TILE_NUM + \1Frames
if TWO_TILE_ALIGN
TILE_NUM set TILE_NUM + (TILE_NUM % 2)
endc
	endm

	registertiles Tileset,$a1
	registertiles Blacktile,1
	registertiles Star,8
	registertiles Southward,10
	registertiles Westward,10
	registertiles Northward,10
	registertiles Eastward,10

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
