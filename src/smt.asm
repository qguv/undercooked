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
	dw	StarAnimTab,AttrNormal8	; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$2e,$5d				; (bytes 8 and 9) y and x position (ROM only)

	; right stove eye
	db	SMTF_ACTIVE|SMTF_WORLD_FIXED|SMTF_ANIMATED	; (byte 0) SMT flags
	db	2 | (2 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	8,4				; (byte 2) frames, (byte 3) current/initial frame
	dw	StarAnimTab,AttrXFlip8		; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$2e,$6d				; (byte 8, ROM only) y (byte 9, ROM only) x

macro main_char_smt_entry

	; cat left ear
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	\1+(0*4),\2+(0*4)		; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$4e,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; cat right ear
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	\1+(1*4),\2+(1*4)		; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$4e,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; cat left head
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	\1+(2*4),\2+(2*4)		; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$56,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; cat right head
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	2,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	\1+(3*4),\2+(3*4)		; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$56,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; cat left arm
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	\1+(4*4),\2+(4*4)		; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$5e,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; cat right arm
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,2				; (byte 2) frames, (byte 3) current/initial frame
	dw	\1+(5*4),\2+(5*4)		; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$5e,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

	; cat left leg
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,0				; (byte 2) frames, (byte 3) current/initial frame
	dw	\1+(6*4),\2+(6*4)		; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$66,$50				; (byte 8, ROM only) y (byte 9, ROM only) x

	; cat right leg
	db	SMTF_ACTIVE|SMTF_SCREEN_FIXED|SMTF_PLAYER	; (byte 0) SMT flags
	db	7 | (8 << 4)			; (byte 1 low) vblanks between frames (byte 1 high) vblanks left
	db	4,2				; (byte 2) frames, (byte 3) current/initial frame
	dw	\1+(7*4),\2+(7*4)		; (bytes 4-5) tiles table (bytes 6-7) flags table
	db	$66,$58				; (byte 8, ROM only) y (byte 9, ROM only) x

endm

	main_char_smt_entry Cat_map+(0*8*4), Cat_attrs+(0*8*4)
	main_char_smt_entry Cat_map+(1*8*4), Cat_attrs+(1*8*4)
	main_char_smt_entry Cat_map+(2*8*4), Cat_attrs+(2*8*4)
	main_char_smt_entry Cat_map+(3*8*4), Cat_attrs+(3*8*4)

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

AttrNormal8:
	ds 8,0

AttrXFlip8:
	ds 8,OAMF_XFLIP

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
