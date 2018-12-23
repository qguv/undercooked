  INCLUDE "gbhw.inc"
  INCLUDE "ibmpc1.inc"
  INCLUDE "hram.inc"
  INCLUDE "macros.inc"


	SECTION	"Org $00",ROM0[$00]
RST_00:
	jp	$100

	SECTION	"Org $08",ROM0[$08]
RST_08:
	jp	$100

	SECTION	"Org $10",ROM0[$10]
RST_10:
	jp	$100

	SECTION	"Org $18",ROM0[$18]
RST_18:
	jp	$100

	SECTION	"Org $20",ROM0[$20]
RST_20:
	jp	$100

	SECTION	"Org $28",ROM0[$28]
RST_28:
	jp	$100

	SECTION	"Org $30",ROM0[$30]
RST_30:
	jp	$100

	SECTION	"Org $38",ROM0[$38]
RST_38:
	jp	$100

	SECTION	"V-Blank IRQ Vector",ROM0[$40]
VBL_VECT:
	jp VBlank

	SECTION	"LCD IRQ Vector",ROM0[$48]
LCD_VECT:
	reti

	SECTION	"Timer IRQ Vector",ROM0[$50]
TIMER_VECT:
	reti

	SECTION	"Serial IRQ Vector",ROM0[$58]
SERIAL_VECT:
	reti

	SECTION	"Joypad IRQ Vector",ROM0[$60]
JOYPAD_VECT:
	reti

  SECTION "Org $100",ROM0[$100]
  nop
  jp      begin

  ROM_HEADER      ROM_MBC1_RAM_BAT, ROM_SIZE_32KBYTE, RAM_SIZE_8KBYTE

  INCLUDE "memory.asm"

TileData:
  chr_IBMPC1      1,8

Found1_16:
  db      "    You found my"

Found2_14:
  db      "     Game Boy!"

Found3_19:
  db      "  Please return to:"

Address1_18:
  db      "  Quint Guvernator"

Address2_19:
  db      "Gerard Doustraat 16"

Address3_19:
  db      "1072CA Amsterdam NL"

Phone1_17:
  db      "  +1 757 606 0005"

Phone2_17:
  db      "  WhatsApp or SMS"

begin::
  di
  ld      sp,$ffff
  call    StopLCD

  ld	  a, %11100100 	; Window palette colors, from darkest to lightest
  ld      [rBGP],a        ; Setup the default background palette
  ldh     [rOBP0],a		; set sprite pallette 0
  ld	  a, %00011011
  ldh     [rOBP1],a   ; and 1

; printable ascii
  ld      hl,TileData
  ld      de,_TILE0
  ld      bc,8*256        ; length (8 bytes per tile) x (256 tiles)
  call    mem_CopyMono    ; Copy tile data to memory

; Clear screen
  ld      a,$20
  ld      hl,_SCRN0
  ld      bc,32*32
  call    mem_Set

  ; draw text on screen
  ld      hl,Found1_16
  ld      de,_SCRN0+$40
  ld      bc,16
  call    mem_Copy
  ld      hl,Found2_14
  ld      de,_SCRN0+$60
  ld      bc,14
  call    mem_Copy
  ld      hl,Found3_19
  ld      de,_SCRN0+$a0
  ld      bc,19
  call    mem_Copy
  ld      hl,Address1_18
  ld      de,_SCRN0+$e0
  ld      bc,18
  call    mem_Copy
  ld      hl,Address2_19
  ld      de,_SCRN0+$100
  ld      bc,19
  call    mem_Copy
  ld      hl,Address3_19
  ld      de,_SCRN0+$120
  ld      bc,19
  call    mem_Copy
  ld      hl,Phone1_17
  ld      de,_SCRN0+$160
  ld      bc,17
  call    mem_Copy
  ld      hl,Phone2_17
  ld      de,_SCRN0+$180
  ld      bc,17
  call    mem_Copy

  ; blit happyface
  ld      de,_SCRN0+$1c9
  ld      a,2
  ld      [de],a

  ; blit heart
  inc     de
  ld      a,3
  ld      [de],a

  ; blit heart
  ld      de,_SCRN0+$1e9
  ld      [de],a

  ; blit happyface
  inc     de
  ld      a,2
  ld      [de],a

; Clear OAM
  ld      a,$00
  ld      hl,_OAMRAM
  ld      bc,40*4
  call    mem_Set

  ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON
  ld      [rLCDC],a       ; Turn screen on

; set up interrupt
  ld a, IEF_VBLANK
  ld [rIE], a
  ei

.wait:
  halt
  nop
  jr .wait

; *** Turn off the LCD display ***

StopLCD:
  ld      a,[rLCDC]
  rlca                    ; Put the high bit of LCDC into the Carry flag
  ret     nc              ; Screen is off already. Exit.

; Loop until we are in VBlank
.wait:
  ld      a,[rLY]
  cp      145             ; Is display on scan line 145 yet?
  jr      nz,.wait        ; no, keep waiting

; Turn off the LCD
  ld      a,[rLCDC]
  res     7,a             ; Reset bit 7 of LCDC
  ld      [rLCDC],a

  ret

; c - byte
; hl - address
DrawHexByte:
  ld d, 1
  ld a, c
  swap a
.CharLoop
  and $0f
  cp 10
  jr nc, .Alpha
  add "0"
  jr .Write
.Alpha
  add "A"-10
.Write
  ld [hli], a
  ld a, d
  cp 0
  ld a, c
  ld d, 0
  jr nz, .CharLoop
  ret

; Copied from CPU manual
ReadJoypad:
  LD A,P1F_5   ; <- bit 5 = $20
  LD [rP1],A   ; <- select P14 by setting it low
  LD A,[rP1]
  LD A,[rP1]    ; <- wait a few cycles
  CPL           ; <- complement A
  AND $0F       ; <- get only first 4 bits
  SWAP A        ; <- swap it
  LD B,A        ; <- store A in B
  LD A,P1F_4
  LD [rP1],A    ; <- select P15 by setting it low
  LD A,[rP1]
  LD A,[rP1]
  LD A,[rP1]
  LD A,[rP1]
  LD A,[rP1]
  LD A,[rP1]    ; <- Wait a few MORE cycles
  CPL           ; <- complement (invert)
  AND $0F       ; <- get first 4 bits
  OR B          ; <- put A and B together

  ;LD B,A        ; <- store A in D
  ;LD A,[hButtonsOld]  ; <- read old joy data from ram
  ;XOR B         ; <- toggle w/current button bit
  ;AND B         ; <- get current button bit back
  LD [hButtons],A  ; <- save in new Joydata storage
  ;LD A,B        ; <- put original value in A
  ;LD [hButtonsOld],A  ; <- store it as old joy data
  LD A,P1F_5|P1F_4    ; <- deselect P14 and P15
  LD [rP1],A    ; <- RESET Joypad
  RET           ; <- Return from Subroutine



VBlank::
  reti

;* End of File *

