section "Org $00",ROM0[$00]
RST_00:
	jp	$100

section "Org $08",ROM0[$08]
RST_08:
	jp	$100

section "Org $10",ROM0[$10]
RST_10:
	jp	$100

section "Org $18",ROM0[$18]
RST_18:
	jp	$100

section "Org $20",ROM0[$20]
RST_20:
	jp	$100

section "Org $28",ROM0[$28]
RST_28:
	jp	$100

section "Org $30",ROM0[$30]
RST_30:
	jp	$100

section "Org $38",ROM0[$38]
RST_38:
	jp	$100

section "V-Blank IRQ Vector",ROM0[$40]
VBL_VECT:
	jp	VBlank

section "LCD IRQ Vector",ROM0[$48]
LCD_VECT:
	reti

section "Timer IRQ Vector",ROM0[$50]
TIMER_VECT:
	reti

section "Serial IRQ Vector",ROM0[$58]
SERIAL_VECT:
	reti

section "Joypad IRQ Vector",ROM0[$60]
JOYPAD_VECT:
	reti

