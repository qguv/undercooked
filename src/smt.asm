; The sprite meta-table (SMT) stores information about the behavior of sprites.
; It has a ROM and a RAM representation. The former is an authoritative list of
; all the sprites that can be encountered in the game. The latter only lists
; sprites that are currently SMTF_ACTIVE (that is, loaded in OAM). Note that an
; off-screen sprite still counts as "SMTF_ACTIVE".
;
; Each vblank, the vblank handler will read the RAM SMT and modify OAM RAM to
; advance animations and move sprites on the screen as necessary.
;
; Some of each entry is copied into SMT_RAM on boot.
;
; (byte 0) SMT flags
; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
; (byte 2) frames, (byte 3) current/initial frame
; (bytes 4-5) tiles table (bytes 6-7) flags table
; (bytes 8 and 9) y and x position (ROM only)

include "lib/gbhw.inc"		; hardware descriptions
include "src/smt.inc"		; constants
include "src/tiles.inc"		; tile constants

section "ROM SMT",ROM0

	; left stove eye
	db	SMTF_ACTIVE|SMTF_WORLD_FIXED|SMTF_ANIMATED	; (byte 0) SMT flags
	db	2 | (2 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	8,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	StarAnimTab,LStarAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$2e,$5d				; (bytes 8 and 9) y and x position (ROM only)

	; right stove eye
	db	SMTF_ACTIVE|SMTF_WORLD_FIXED|SMTF_ANIMATED	; (byte 0) SMT flags
	db	2 | (2 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	8,4				; (byte 2) frames, (byte 3) current/initial frame
	dw	StarAnimTab,RStarAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$2e,$6d				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat left ear
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardEarAnimTab,SouthwardLEarAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$4e,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat right ear
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardEarAnimTab,SouthwardREarAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$4e,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cart left head
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardHeadAnimTab,SouthwardLHeadAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$56,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat right head
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardHeadAnimTab,SouthwardRHeadAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$56,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat left arm
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardArmAnimTab,SouthwardLArmAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$5e,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat right arm
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,2				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardArmAnimTab,SouthwardRArmAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$5e,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat left leg
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardLegAnimTab,SouthwardLLegAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$66,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat right leg
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,2				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardLegAnimTab,SouthwardRLegAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$66,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

section "animation tables",ROM0

StarAnimTab:
	db StarBeginIndex+0
	db StarBeginIndex+1
	db StarBeginIndex+2
	db StarBeginIndex+3
	db StarBeginIndex+4
	db StarBeginIndex+5
	db StarBeginIndex+6
	db StarBeginIndex+7

LStarAttrTab:
	ds 8,0

RStarAttrTab:
	ds 8,OAMF_XFLIP

; TODO find some way to deal with tilemap files that assume the first tile in the sprite is tile 0. maybe even a preprocessing recipe to add a constant to each byte in the file? idk
SouthwardEarAnimTab:
	db SouthwardBeginIndex+0
	db SouthwardBeginIndex+4

SouthwardHeadAnimTab:
	db SouthwardBeginIndex+1
	db SouthwardBeginIndex+5

SouthwardREarAttrTab:
SouthwardRHeadAttrTab:
	ds 2,OAMF_XFLIP

SouthwardLEarAttrTab:
SouthwardLHeadAttrTab:
	ds 2,0

SouthwardArmAnimTab:
	db SouthwardBeginIndex+2
	db SouthwardBeginIndex+6
	db SouthwardBeginIndex+2
	db SouthwardBeginIndex+7

SouthwardLegAnimTab:
	db SouthwardBeginIndex+3
	db SouthwardBeginIndex+8
	db SouthwardBeginIndex+3
	db SouthwardBeginIndex+9

SouthwardLArmAttrTab:
SouthwardLLegAttrTab:
	db 0,0,0,OAMF_XFLIP

SouthwardRArmAttrTab:
SouthwardRLegAttrTab:
	db OAMF_XFLIP,OAMF_XFLIP,OAMF_XFLIP,0

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
