; The sprite meta-table (SMT) stores information about the behavior of sprites.
; It has a ROM and a RAM representation. The former is an authoritative list of
; all the sprites that can be encountered in the game. The latter only lists
; sprites that are currently SMTF_ACTIVE (that is, loaded in OAM). Note that an
; off-screen sprite still counts as "SMTF_ACTIVE".
;
; Each vblank, the vblank handler will read the RAM SMT and modify OAM RAM to
; advance animations and move sprites on the screen as necessary.

SMTF_ACTIVE equ 1	; sprite should be drawn (SMT flag)
SMTF_WORLD_FIXED equ 2	; sprite moves with background (SMT flag)
SMTF_SCREEN_FIXED equ 0	; sprite does not move with background (SMT flag)
SMTF_ANIMATED equ 4	; sprite animates constantly (SMT flag)
SMTF_PLAYER equ 8	; sprite animates only when the screen is moving (SMT flag)

SMT_RAM_BYTES equ 8	; size of an SMT entry in RAM (in bytes)
SMT_ROM_BYTES equ 10	; size of an SMT entry in ROM (in bytes)

; Sprite meta-table. Some of each entry is copied into SMT_RAM on boot.
; (byte 0) SMT flags
; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
; (byte 2) frames, (byte 3) current/initial frame
; (bytes 4-5) tiles table (bytes 6-7) flags table
; (bytes 8 and 9) y and x position (ROM only)
SmtRom

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
	db	SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardEarAnimTab,SouthwardLEarAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$4e,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat right ear
	db	SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardEarAnimTab,SouthwardREarAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$4e,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cart left head
	db	SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardHeadAnimTab,SouthwardLHeadAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$56,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat right head
	db	SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardHeadAnimTab,SouthwardRHeadAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$56,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat left arm
	db	SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardArmAnimTab,SouthwardLArmAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$5e,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat right arm
	db	SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,2				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardArmAnimTab,SouthwardRArmAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$5e,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat left leg
	db	SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardLegAnimTab,SouthwardLLegAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$66,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; southward cat right leg
	db	SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,2				; (byte 2) frames, (byte 3) current/initial frame
	dw	SouthwardLegAnimTab,SouthwardRLegAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$66,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; northward cat left ear
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	NorthwardLEarAnimTab,NorthwardLEarAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$4e,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; northward cat right ear
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	NorthwardREarAnimTab,NorthwardREarAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$4e,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; northward cart left head
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	NorthwardLHeadAnimTab,NorthwardLHeadAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$56,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; northward cat right head
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	NorthwardRHeadAnimTab,NorthwardRHeadAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$56,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; northward cat left arm
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	NorthwardLArmAnimTab,NorthwardLArmAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$5e,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; northward cat right arm
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,2				; (byte 2) frames, (byte 3) current/initial frame
	dw	NorthwardRArmAnimTab,NorthwardRArmAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$5e,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; northward cat left leg
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	NorthwardLLegAnimTab,NorthwardLLegAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$66,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; northward cat right leg
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,2				; (byte 2) frames, (byte 3) current/initial frame
	dw	NorthwardRLegAnimTab,NorthwardRLegAttrTab	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$66,$58				; (byte 8, ROM only) y (byte 9, ROM only) x
SmtRomEnd

StarAnimTab
	db StarBeginIndex+0
	db StarBeginIndex+1
	db StarBeginIndex+2
	db StarBeginIndex+3
	db StarBeginIndex+4
	db StarBeginIndex+5
	db StarBeginIndex+6
	db StarBeginIndex+7

LStarAttrTab
	ds 8,0

RStarAttrTab
	ds 8,OAMF_XFLIP

; TODO find some way to deal with tilemap files that assume the first tile in the sprite is tile 0. maybe even a preprocessing recipe to add a constant to each byte in the file? idk
SouthwardEarAnimTab
	db SouthwardBeginIndex+0
	db SouthwardBeginIndex+4

SouthwardHeadAnimTab
	db SouthwardBeginIndex+1
	db SouthwardBeginIndex+5

SouthwardArmAnimTab
	db SouthwardBeginIndex+2
	db SouthwardBeginIndex+6
	db SouthwardBeginIndex+2
	db SouthwardBeginIndex+7

SouthwardLegAnimTab
	db SouthwardBeginIndex+3
	db SouthwardBeginIndex+8
	db SouthwardBeginIndex+3
	db SouthwardBeginIndex+9

NorthwardLEarAnimTab
	db NorthwardBeginIndex+$00
	db NorthwardBeginIndex+$08
	db NorthwardBeginIndex+$10
	db NorthwardBeginIndex+$13

NorthwardREarAnimTab
	db NorthwardBeginIndex+$01
	db NorthwardBeginIndex+$09
	db NorthwardBeginIndex+$01
	db NorthwardBeginIndex+$08

NorthwardLHeadAnimTab
	db NorthwardBeginIndex+$02
	db NorthwardBeginIndex+$0a
	db NorthwardBeginIndex+$11
	db NorthwardBeginIndex+$14

NorthwardRHeadAnimTab
	db NorthwardBeginIndex+$03
	db NorthwardBeginIndex+$0b
	db NorthwardBeginIndex+$12
	db NorthwardBeginIndex+$15

NorthwardLArmAnimTab
NorthwardRArmAnimTab
	db NorthwardBeginIndex+$04
	db NorthwardBeginIndex+$0c
	db NorthwardBeginIndex+$05
	db NorthwardBeginIndex+$0d

NorthwardLLegAnimTab
NorthwardRLegAnimTab
	db NorthwardBeginIndex+$06
	db NorthwardBeginIndex+$0e
	db NorthwardBeginIndex+$07
	db NorthwardBeginIndex+$0f

SouthwardLEarAttrTab
SouthwardLHeadAttrTab
	ds 2,0

SouthwardREarAttrTab
SouthwardRHeadAttrTab
	ds 2,OAMF_XFLIP

SouthwardLArmAttrTab
SouthwardLLegAttrTab
NorthwardREarAttrTab
	db 0,0,0,OAMF_XFLIP

SouthwardRArmAttrTab
SouthwardRLegAttrTab
	db OAMF_XFLIP,OAMF_XFLIP,OAMF_XFLIP,0

NorthwardLEarAttrTab
NorthwardLHeadAttrTab
NorthwardRHeadAttrTab
	ds 4,0

NorthwardLArmAttrTab
NorthwardRArmAttrTab
NorthwardLLegAttrTab
NorthwardRLegAttrTab
	db 0,0,OAMF_XFLIP,OAMF_XFLIP

; vim: se ft=rgbds:
