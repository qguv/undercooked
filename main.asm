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

SprAttr:
db $60, $10, $8, $0
db $60, $18, $9, $0
db $68, $10, $A, $0
db $68, $18, $B, $0

Window:
db $CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD,$CD, "            "
db "Demo    Slide    1/5", "            "
db "                    ", "            "
db " Scrollable window- ", "            "
db " overlay            ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "
db "                    ", "            "

Slides:
; slide 1
db "                    ", "            "
db " Game Boy Emulator  ", "            "
db "                    ", "            "
db "          ",$8,$9,"   ",$C,$D,"   ", "            "
db "   FPGA + ",$A,$B," = ",$E,$F,"   ", "            "
db "                    ", "            "
db "     ",$18,"     ",$18,"        ", "            "
db "                    ", "            "
db "    GPU   CPU       ", "            "
db "                    ", "            "
db "                    ", "            "
db $10," 1000+ lines of C++", "            "
db $10," 500+ lines of VHDL", "            "
db $10," 300+ lines of ASM ", "            "
db "  (this demo)       ", "            "
db "                    ", "            "
; slide 2
db "                    ", "            "
db "      Overview      ", "            "
db "                    ", "            "
db " ", $C9, $CD, $CD, $BB, $1B,"VGA display   ", "            "
db " ", $BA, $20, $20, $BA, "               ", "            "
db " ", $C8, $D1, $CD, $BC, "  Raspberry Pi ", "            "
db "  ", $B3, "    ", $19, "            ", "            "
db "  ", $4, $5, "   ", $0, $1, "           ", "            "
db "  ", $6, $7, $CD, $CD, $CD, $2, $3, "           ", "            "
db "  ", $18, "                 ", "            "
db " DE1-SoC            ", "            "
db "                    ", "            "
db "  Data exchange:    ", "            "
db $10," 100Mhz SPI (VRAM) ", "            "
db $10," Screen sync pulses", "            "
db "                    ", "            "
; slide 3
db "                    ", "            "
db "    Raspberry Pi    ", "            "
db "                    ", "            "
db "  Runs modified em- ", "            "
db "  ulator (Gambatte) ", "            "
db "  Writes following  ", "            "
db "  VRAM data to SPI: ", "            "
db "                    ", "            "
db $10," Tile data         ", "            "
db "  $8000-$97FF       ", "            "
db $10," Tile maps         ", "            "
db "  $9800-$9FFF       ", "            "
db $10," Sprite Attributes ", "            "
db "  $FE00-$FE9F       ", "            "
db $10," Some CPU registers", "            "
db "                    ", "            "
; slide 4
db "                    ", "            "
db "      DE1-SoC       ", "            "
db "                    ", "            "
db " Drives VGA at 60Hz ", "            "
db "                    ", "            "
db " Async SPI slave    ", "            "
db " using 2-port RAM   ", "            "
db "                    ", "            "
db " Seperate RAM parts ", "            "
db " for parallel reads ", "            "
db "                    ", "            "
db " (Almost) perfect   ", "            "
db " rendering of all   ", "            "
db " Game Boy features  ", "            "
db "                    ", "            "
db "                    ", "            "
; slide 5
db "                    ", "            "
db "      Features      ", "            "
db "                    ", "            "
db $10," Scroling BG layer ", "            "
db "  ", $F8," wth palletes    ", "            "
db $10," Sprite layer with ", "            "
db "  ", $F8," palletes        ", "            "
db "  ", $F8," transparency    ", "            "
db "  ", $F8," flipping        ", "            "
db "                    ", "            "
db $DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF, "            "
db $DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF,$DC,$DF, "            "
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
  ld	a, %00011011
  ldh     [rOBP1],a   ; and 1

  ld      a,0
  ld      [rSCX],a
  ld      [rSCY],a
  ld [hScrolling], a
  ld      a,1
  ld [hSlideNumber], a
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
  ld      bc,32*5
  call    mem_Copy

; Clear OAM
  ld      a,$00
  ld      hl,_OAMRAM
  ld      bc,40*4
  call    mem_Set
; load sprites
  ld      hl,SprAttr
  ld      de,_OAMRAM
  ld      bc,4*4
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

  ld a, [hScrolling]
  bit 1, a
  jr z, .wait

  ld      de,_SCRN0
  ld a, [hSlideNumber]
  bit 0, a
  jr z, .evenSlide
  ld      de,_SCRN0+(16*32)
.evenSlide
  sla a
  ld b, a
  ld c, 0
  ld      hl,Slides
  add hl, bc
  ld      bc,32*16
  call    mem_Copy

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
  ld a, [_OAMRAM+1]
  inc a
  ld [_OAMRAM+1], a
  ld a, [_OAMRAM+5]
  inc a
  ld [_OAMRAM+5], a
  ld a, [_OAMRAM+9]
  inc a
  ld [_OAMRAM+9], a
  ld a, [_OAMRAM+13]
  inc a
  ld [_OAMRAM+13], a

  ld a, [hFrameCounter]
  inc a
  ld [hFrameCounter], a
  and %111111
  jr nz, .skipFlip
  ld a, [_OAMRAM+3]
  xor a, OAMF_PAL1|OAMF_YFLIP
  ld [_OAMRAM+3], a
  ld [_OAMRAM+7], a
  ld [_OAMRAM+11], a
  ld [_OAMRAM+15], a

  ld a, [_OAMRAM+2]
  xor a, 2
  ld [_OAMRAM+2], a
  ld a, [_OAMRAM+6]
  xor a, 2
  ld [_OAMRAM+6], a
  ld a, [_OAMRAM+10]
  xor a, 2
  ld [_OAMRAM+10], a
  ld a, [_OAMRAM+14]
  xor a, 2
  ld [_OAMRAM+14], a
.skipFlip

  ld a, [hScrolling]
  bit 0, a
  jr nz, .scrolling
  bit 2, a
  jr nz, .windowScrolling
  call ReadJoypad
  ldh a, [hButtons]
  bit PADB_A, a
  jr z, .noA
  ld a, 1
  ld [hScrolling], a
  ld a, [hSlideNumber]
  inc a
  ld [hSlideNumber], a
  add a, "0"
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
.windowScrolling
  ld a, [rWY]
  cp a, 104
  jr z, .stopScrolling
  dec a
  ld [rWY], a
.stopScrolling
  ld a, [hSlideNumber]
  cp a, 5
  jr nz, .not5
  ld a, 4
  ld [hScrolling], a
  ld a, [rLCDC]
  or a, LCDCF_OBJON
  ld [rLCDC],a
  reti
.not5
  ld a, 2
  ld [hScrolling], a
  reti

;* End of File *

