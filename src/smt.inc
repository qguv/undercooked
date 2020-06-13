; The sprite meta-table (SMT) stores information about the behavior of sprites.
; It has a ROM and a RAM representation. The former is an authoritative list of
; all the sprites that can be encountered in the game. The latter only lists
; sprites that are currently SMTF_ACTIVE (that is, loaded in OAM). Note that an
; off-screen sprite still counts as "SMTF_ACTIVE".
;
; Each vblank, the vblank handler will read the RAM SMT and modify OAM RAM to
; advance animations and move sprites on the screen as necessary.

; constants
SMTF_ACTIVE equ 1
SMTF_WORLD_FIXED equ 2
SMTF_SCREEN_FIXED equ 0
SMTF_ANIMATED equ 4

; compiler variables
SPRITE_NUM set 0

; arguments:
; \1: name of sprite, an index of which will be defined for you
; \2: SMT flags: `SMTF_ACTIVE`, `SMTF_{WORLD,SCREEN}_FIXED`
; \3: x position
; \4: y position
; \5: flag table address
; \6: (animated) number of frames
; \7: (animated) speed (in number of vblank interrupts to stall)
; \8: (animated) table index to start on
; \9: (animated) table address
AnimSprite: macro
	; define sprite name
\1 equ SPRITE_NUM
SPRITE_NUM set SPRITE_NUM + 1

	; entries in SMT
	db	(\2)|SMTF_ANIMATED	; (byte 0 bit 0) `SMTF_ACTIVE` (when set)
					; (byte 0 bit 1) `SMTF_WORLD_FIXED` (when set) or `SMTF_SCREEN_FIXED` (when clear)
					; (byte 0 bit 2) `SMTF_ANIMATED` (when set)
if (\7) > $0f
    fail "Animation stall too high! Decrease stall or change the SMT format to fit the larger number!"
endc
	db	(\7) | ((\7) << 4)	; (byte 1 low nybble) animation speed in number of vblanks to skip
				; (byte 1 high nybble) number of vblanks left to stall
	db	(\6)		; (byte 2) animation table length
	db	(\8)		; (byte 3) current/initial animation table index
	dw	(\9)		; (byte 4-5) animation table address
	dw	(\5)		; (byte 6-7) flag table address
	db	(\4)		; (byte 8, ROM only) y
	db	(\3)		; (byte 9, ROM only) x
	endm

SMT_RAM_BYTES equ 8
SMT_ROM_BYTES equ 10

; vim: se ft=rgbds:
