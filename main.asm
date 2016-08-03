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

  ROM_HEADER      ROM_MBC1_RAM_BAT, ROM_SIZE_32KBYTE, RAM_SIZE_8KBYTE

  INCLUDE "memory.asm"

TileData:
  chr_IBMPC1      2,3

begin::
  di
  ld      sp,$ffff
  call    StopLCD

	ld	a, %11100100 	; Window palette colors, from darkest to lightest
  ld      [rBGP],a        ; Setup the default background palette
  ldh     [rOBP0],a		; set sprite pallette 0
	ldh     [rOBP1],a   ; and 1

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

; Clear OAM
  ld      a,$00
  ld      hl,_OAMRAM
  ld      bc,40*4
  call    mem_Set

; Cursor sprite
  ld a, 64
  ldh [hCursorX], a
  ldh [hCursorY], a
  ld	a, %11100100
  ldh [hCursorColor], a
  ld	a, 3
  ldh [hCursorSize], a
  call DrawCursor

; Frame counters
  ld	a, 16
  ldh [hFrameSkip], a
  ld	a, 0
  ldh [hFrameCounter], a

; Now we turn on the LCD display to view the results!

  ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
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
  halt
  nop
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

; b - byte
; hl - address
DrawHexByte:
  ld c, 1
  ld a, b
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
  ld a, c
  cp 0
  ld a, b
  ld c, 0
  jr nz, .CharLoop
  ret
  

DrawCursor:
  ldh a, [hCursorY]
  add 16 ; true 0
  ld [_OAMRAM], a ; y
  ldh a, [hCursorX]
  add 8 ; true 0
  ld [_OAMRAM+1], a ; x
  ldh a, [hCursorSize]
  add $03
  ld [_OAMRAM+2], a ; sprite
  ld a, 0
  ld [_OAMRAM+3], a ; flags
  ldh a, [hCursorColor]
  ldh [rOBP0],a		; set sprite pallette 0
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
; draw using the second tileset
  ld      a,LCDCF_ON|LCDCF_BG8800|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
  ld      [rLCDC],a       ; Turn screen on

  ; Check frame counter
  ldh a, [hFrameCounter]
  cp a, 0
  jr z, .input
  dec a
  ldh [hFrameCounter], a
  reti ; don't do anything until we rech 0

.input
  call ReadJoypad
  ldh a, [hButtons]
  ld b, a

  cp 0 ; no buttons
  jr z, .nothing

.something
  ldh a, [hFrameSkip]
  srl a
  ldh [hFrameSkip], a
  ldh [hFrameCounter], a

  bit PADB_RIGHT, b
  jr z, .noRight
  ldh a, [hCursorX]
  inc a
  ldh [hCursorX], a
.noRight
  bit PADB_LEFT, b
  jr z, .noLeft
  ldh a, [hCursorX]
  dec a
  ldh [hCursorX], a
.noLeft
  bit PADB_UP, b
  jr z, .noUp
  ldh a, [hCursorY]
  dec a
  ldh [hCursorY], a
.noUp
  bit PADB_DOWN, b
  jr z, .noDown
  ldh a, [hCursorY]
  inc a
  ldh [hCursorY], a
.noDown
  call DrawCursor

  ldh a, [hCursorX]
  ld b, a
  coord hl, 18, 16
  call DrawHexByte

  ldh a, [hCursorY]
  ld b, a
  coord hl, 18, 17
  call DrawHexByte

  reti
.nothing
  ld a, 16
  ldh [hFrameSkip], a
  reti

Coincidence::
; draw the UI using the first tileset
  ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
  ld      [rLCDC],a       ; Turn screen on
reti

;* End of File *

