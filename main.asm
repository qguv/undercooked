  INCLUDE "gbhw.inc"
  INCLUDE "ibmpc1.inc"
  INCLUDE "hram.inc"
  INCLUDE "macros.inc"

  
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
	reti

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

  ROM_HEADER      ROM_MBC1_RAM_BAT, ROM_SIZE_32KBYTE, RAM_SIZE_8KBYTE

  INCLUDE "memory.asm"

TileData:
  chr_IBMPC1      1,8
Sprites:
  INCBIN "pi.2bpp"
  INCBIN "fpga.2bpp"
  INCBIN "pilogo.2bpp"
  INCBIN "gb.2bpp"

Window:
db $CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD, "            "
db "Demo    Slide    1/5"

Slides:
; slide 1
db "                    ", "            "
db " Game Boy Emulator  ", "            "
db "                    ", "            "
db "                    ", "            "
db "          ",$8,$9,"   ",$C,$D,"   ", "            "
db "   FPGA + ",$A,$B," = ",$E,$F,"   ", "            "
db "                    ", "            "
db "                    ", "            "
db "     ",$18,"     ",$18,"        ", "            "
db "                    ", "            "
db "    GPU   CPU      ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
; slide 2
db "                    ", "            "
db "      Overview      ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "

begin::
  di
  ld      sp,$ffff
  call    StopLCD

  ld	a, %11100100 	; Window palette colors, from darkest to lightest
  ld      [rBGP],a        ; Setup the default background palette
  ldh     [rOBP0],a		; set sprite pallette 0
  ld	a, %11100000
  ldh     [rOBP1],a   ; and 1

  ld      a,0
  ld      [rSCX],a
  ld      [rSCY],a
  ld [hSlideNumber], a
  ld [hScrolling], a
  ld      a,7
  ld      [rWX],a
  ld      a,128
  ld      [rWY],a

; printable ascii
  ld      hl,TileData
  ld      de,_TILE0
  ld      bc,8*256        ; length (8 bytes per tile) x (256 tiles)
  call    mem_CopyMono    ; Copy tile data to memory
; sprites
  ld      hl,Sprites
  ld      de,_TILE0
  ld      bc,16*4*4        ; length (16 bytes per tile) x (4 tiles) x (n metatiles)
  call    mem_Copy    ; Copy tile data to memory

  ; init screen
  ld      hl,Slides
  ld      de,_SCRN0
  ld      bc,32*32
  call    mem_Copy

  ; init window
  ld      hl,Window
  ld      de,_SCRN1
  ld      bc,32*2
  call    mem_Copy

  ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_WIN9C00|LCDCF_WINON
  ld      [rLCDC],a       ; Turn screen on

; set up interrupt
  ld a, IEF_VBLANK
  ld [rIE], a
  ei

.wait:
  halt
  nop
  jp      .wait

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
  ld a, [hScrolling]
  and a
  jr nz, .scrolling
  call ReadJoypad
  ldh a, [hButtons]
  bit PADB_A, a
  jr z, .noA
  ld a, 1
  ld [hScrolling], a
  ld a, [hSlideNumber]
  inc a
  ld [hSlideNumber], a
  add a, "1"
  ld [_SCRN1+49], a
.noA
  reti
.scrolling
  ld a, [rSCY]
  inc a
  ld [rSCY], a
  and %1111111
  jr z, .stopScrolling
  reti
.stopScrolling
  ld a, 0
  ld [hScrolling], a
  ld      hl,Slides
  ld      de,_SCRN0
  ld      bc,32*32
  call    mem_Copy
  reti

;* End of File *

