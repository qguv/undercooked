SMTF_ACTIVE equ 1	; sprite should be drawn (SMT flag)
SMTF_WORLD_FIXED equ 2	; sprite moves with background (SMT flag)
SMTF_SCREEN_FIXED equ 0	; sprite does not move with background (SMT flag)
SMTF_ANIMATED equ 4	; sprite animates constantly (SMT flag)
SMTF_PLAYER equ 8	; sprite animates only when the screen is moving (SMT flag)

SMT_ENTRIES equ 10	; number of SMT entries
SMT_RAM_BYTES equ 8	; size of an SMT entry in RAM (in bytes)
SMT_ROM_BYTES equ 10	; size of an SMT entry in ROM (in bytes)

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
