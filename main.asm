  INCLUDE "gbhw.inc"
  INCLUDE "ibmpc1.inc"

  
	SECTION	"Org $00",HOME[$00]
RST_00:	
	jp	$100

	SECTION	"Org $08",HOME[$08]
RST_08:	
	jp	$100

	SECTION	"Org $10",HOME[$10]
RST_10:
	jp	$100

	SECTION	"Org $18",HOME[$18]
RST_18:
	jp	$100

	SECTION	"Org $20",HOME[$20]
RST_20:
	jp	$100

	SECTION	"Org $28",HOME[$28]
RST_28:
	jp	$100

	SECTION	"Org $30",HOME[$30]
RST_30:
	jp	$100

	SECTION	"Org $38",HOME[$38]
RST_38:
	jp	$100

	SECTION	"V-Blank IRQ Vector",HOME[$40]
VBL_VECT:
	jp VBlank
	
	SECTION	"LCD IRQ Vector",HOME[$48]
LCD_VECT:
	jp Coincidence

	SECTION	"Timer IRQ Vector",HOME[$50]
TIMER_VECT:
	reti

	SECTION	"Serial IRQ Vector",HOME[$58]
SERIAL_VECT:
	reti

	SECTION	"Joypad IRQ Vector",HOME[$60]
JOYPAD_VECT:
	reti

  SECTION "Org $100",HOME[$100]
  nop
  jp      begin

  ROM_HEADER      ROM_MBC1_RAM, ROM_SIZE_32KBYTE, RAM_SIZE_8KBYTE

  INCLUDE "memory.asm"

TileData:
  chr_IBMPC1      2,3

begin::
  di
  ld      sp,$ffff
  call    StopLCD

	ld	a, %11100100 	; Window palette colors, from darkest to lightest
  ld      [rBGP],a        ; Setup the default background palette

  ld      a,0
  ld      [rSCX],a
  ld      [rSCY],a

; GUI tiles
  ld      a,$00
  ld      hl,_TILE0
  ld      bc,16*$20
  call    mem_Set

  ld hl, _TILE0 ; destination

  ld c, 8 ; size
.WhiteLoop
  ld a, $00
  ld [hli], a
  ld a, $00
  ld [hli], a
  dec c
  jr nz, .WhiteLoop

  ld c, 8 ; size
.LightLoop
  ld a, $ff
  ld [hli], a
  ld a, $00
  ld [hli], a
  dec c
  jr nz, .LightLoop

  ld c, 8 ; size
.DarkLoop
  ld a, $00
  ld [hli], a
  ld a, $ff
  ld [hli], a
  dec c
  jr nz, .DarkLoop

  ld c, 4 ; size
.PointerLoop
  ld de, Pointers
  ;add de, c
  ld a, e
  add c
  ld e, a
  ld a, d
  adc 0

  ld b, c
  dec b
  ld a, $01
  jr z, .Shifted
.ShiftLoop
  rla
  dec b
  jr nz, .ShiftLoop
.Shifted
  ld b, a

  ld a, [de]
.InnerPLoop
  ld [hli], a
  ld [hli], a
  dec b
  jr nz, .InnerPLoop

  ld a, l
  dec a
  ld d, $f0
  and d
  add 16
  ld l, a

  dec c
  jr nz, .PointerLoop
  


; printable ascii
  ld      hl,TileData
  ld      de,_TILE0+(16*$20)
  ld      bc,8*64        ; length (8 bytes per tile) x (256 tiles)
  call    mem_CopyMono    ; Copy tile data to memory

; SRAM tiles
  ld      a,SRAM_ENABLE
  ld      [rSRAM], a
  ld      hl,_SRAM
  ld      de,_TILE1
  ld      bc,16*$ff
  call    mem_Copy
  ld      a,SRAM_DISABLE
  ld      [rSRAM], a

; initilise tiles
  ld      b,0 ; row
  ld      hl,_SCRN0
.RowLoop
  ld      c,0 ; col
.ColLoop
  ld a, b
  sla a
  sla a
  sla a
  sla a
  add c

  ld [hli], a
  inc c
  ld a, c
  cp 32
  jp nz, .ColLoop
  inc b
  ld a, b
  cp 16
  jp nz, .RowLoop

; GUI
  ld      d,h
  ld      e,l
  ld      hl,GUI
  ld      bc,32*2
  call    mem_Copy

; Now we turn on the LCD display to view the results!

  ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJOFF
  ld      [rLCDC],a       ; Turn screen on

; set up coincidence interrupt
ld a, STATF_LYC
ld [rSTAT], a ; coincindence flag
ld a, 8*16
ld [rLYC], a ; after 16 sprites
ld a, IEF_VBLANK|IEF_LCDC
ld [rIE], a
ei

.wait:
  jp      .wait

Pointers:
  db %00000000
  db %10000000
  db %11000000
  db %11110000
  db %11111111

GUI:
db $00, $00, $01, $01, $02, $02, $03, $03, "        X:              "
db $00, $00, $01, $01, $02, $02, $03, $03,  " ", $03, " ", $04, " ", $05, " ", $06,"Y:  "


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

VBlank::
	;ld	a, %11100100 ; Window palette colors, from darkest to lightest
  ;ld      [rBGP],a ; Setup the default background palette
  ld      a,LCDCF_ON|LCDCF_BG8800|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJOFF
  ld      [rLCDC],a       ; Turn screen on
  reti

Coincidence::
	;ld	a, %00011011 ; Inverse colors
  ;ld      [rBGP],a ; Setup the default background palette
  ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJOFF
  ld      [rLCDC],a       ; Turn screen on
reti

;* End of File *

