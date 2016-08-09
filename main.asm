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

Pointers:
  db %00000000
  db %10000000
  db %11000000
  db %11110000
  db %11111111

Colors:
  db %00100100
  db %01100100
  db %10100100
  db %11100100

Corner:
  db %11111000, %11111000
  db %11111000, %10000000
  db %11000000, %10000000
  db %11000000, %10000000
  db %11000000, %10000000
  db %00000000, %00000000
  db %00000000, %00000000
  db %00000000, %00000000

GUI:
db $00, $00, $01, $01, $02, $02, $03, $03, "        X:              "
db $00, $00, $01, $01, $02, $02, $03, $03,  " ", $03, " ", $04, " ", $05, " ", $06,"Y:  "



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
  
; Croner sprite
  ;ld de, hl
  ld d, h
  ld e, l
  ld hl, Corner
  ld bc, 16
  call mem_Copy


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
; TODO DRY this shit up
; .... but how?
  ld      b,8 ; row
  ld      hl,_SCRN0
.RowLoop
  ld      c,0 ; col
.ColLoop
  ld a, b
  sla a ; row*16
  sla a
  sla a
  sla a
  add c ; row*16+col

  ld [hli],a
  inc c
  ld a, c
  cp 32
  jp nz, .ColLoop
  inc b
  ld a, b
  cp 16
  jp nz, .RowLoop

; negative tiles
  ld      b,0 ; row
.RowLoop2
  ld      c,0 ; col
.ColLoop2
  ld a, b
  sla a ; row*16
  sla a
  sla a
  sla a
  add c ; row*16+col

  ld [hli],a
  inc c
  ld a, c
  cp 32
  jp nz, .ColLoop2
  inc b
  ld a, b
  cp 8
  jp nz, .RowLoop2

; GUI
  coord de, 0, 16
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

; Selection sprite
  ld a, 10
  ldh [hSelectionIndex], a
  ld a, 1
  ldh [hMode], a
  call DrawSelection

; Frame counters
  ld	a, 32
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

SaveSRAM:
; turn of LCD to safely copy bulk data from vram
  ;call StopLCD
; already in vblank interrupt
; Turn off the LCD
  ld      a,[rLCDC]
  res     7,a             ; Reset bit 7 of LCDC
  ld      [rLCDC],a

  ld      a,SRAM_ENABLE
  ld      [rSRAM], a
  ld      de,_SRAM
  ld      hl,_TILE1
  ld      bc,16*$ff
  call    mem_Copy
  ld      a,SRAM_DISABLE
  ld      [rSRAM], a
  
  ld      a,[rLCDC]
  set     7,a             ; set bit 7 of LCDC
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

; update coordinates
  ldh a, [hCursorX]
  ld c, a
  coord hl, 18, 16
  call DrawHexByte

  ldh a, [hCursorY]
  ld c, a
  coord hl, 18, 17
  call DrawHexByte

  ret

DrawSelection:
  ldh a, [hSelectionIndex]
  sla a ; a*16
  sla a
  sla a
  sla a
  ld b, a ; x
  ld a, 8*16
  ld c, a ; y
  ld a, 0
  ld d, a ; flips
  ld hl, _OAMRAM+4
  call DrawCorner

  ld a, b
  add 8
  ld b, a ; x
  ld a, OAMF_XFLIP
  ld d, a ; flips
  call DrawCorner
  
  ld a, c
  add 8
  ld c, a ; y
  ld a, OAMF_XFLIP|OAMF_YFLIP
  ld d, a ; flips
  call DrawCorner
  
  ld a, b
  sub 8
  ld b, a ; y
  ld a, OAMF_YFLIP
  ld d, a ; flips
  call DrawCorner
  
  ret

; b - x
; c - y
; d - flips
; hl - address
DrawCorner:
  ld a, c
  add 16 ; true y
  ld [hli], a ; y
  ld a, b
  add 8 ; true x
  ld [hli], a ; x
  ld a, $07
  ld [hli], a ; sprite
  ld a, d
  or OAMF_PAL1 ; use first pallete
  ld [hli], a ; flags
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

MoveSelection:
  ldh a, [hSelectionIndex]

  bit PADB_RIGHT, b
  jr z, .noRight
  inc a
.noRight
  bit PADB_LEFT, b
  jr z, .noLeft
  dec a
.noLeft
  
  and %111
  ldh [hSelectionIndex], a

  ret

ChangeBrush:
  bit PADB_A, b
  ret z

  ldh a, [hSelectionIndex]
  cp 4
  jp c, .changeColor
  sub 4
  ldh [hCursorSize], a
  jr .setMode

.changeColor
  ld hl, Colors
  ld d, 0
  ld e, a
  add hl, de
  ld a, [hl]
  ldh [hCursorColor], a
.setMode
  ld a, 1
  ldh [hMode], a
  ld a, 10
  ldh [hSelectionIndex], a

; align pointer
  call BrushHeight
  ld a, c
  sub 1
  cpl
  ld c, a
  ldh a, [hCursorX]
  and c
  ldh [hCursorX], a
  ldh a, [hCursorY]
  and c
  ldh [hCursorY], a

  call DrawCursor
  ret

MoveCursor:
; get increment
  call BrushHeight
; move
  bit PADB_RIGHT, b
  jr z, .noRight
  ldh a, [hCursorX]
  add c
  and %1111111
  ldh [hCursorX], a
.noRight
  bit PADB_LEFT, b
  jr z, .noLeft
  ldh a, [hCursorX]
  sub c
  and %1111111
  ldh [hCursorX], a
.noLeft
  bit PADB_UP, b
  jr z, .noUp
  ldh a, [hCursorY]
  sub c
  and %1111111
  ldh [hCursorY], a
.noUp
  bit PADB_DOWN, b
  jr z, .noDown
  ldh a, [hCursorY]
  add c
  and %1111111
  ldh [hCursorY], a
.noDown
  call DrawCursor

  ret

; c -> height
BrushHeight:
; get brush height
; why did I define this so backwards?
  ldh a, [hCursorSize]
  ld c, a
  ld a, 3
  sub c
  ld c, 1
  cp 0
  ret z
.widthLoop
  sla c
  dec a
  jr nz, .widthLoop
  ret

ApplyPaint:
  bit PADB_A, b
  ret z

; Find tile
  ldh a, [hCursorY]
  and %11111000
  sla a ; a/8*16=a*2=a<<1
  ld b, a
  ldh a, [hCursorX]
  sra a ; a/8=a>>3
  sra a
  sra a
  add b
  ld h, 0 ; hl = a = y/8*16+x/8
  ld l, a
  add hl, hl ; hl*16=hl<<4
  add hl, hl
  add hl, hl
  add hl, hl
  ld bc, _TILE1
  add hl, bc ; hl = tile under cursor

; find row
  ldh a, [hCursorY]
  and %111
  sla a
  ld b, 0
  ld c, a
  add hl, bc ; hl = row under cursor

; get brush
; Pointers+4-hCursorSize
  ldh a, [hCursorSize]
  ld b, a
  ld de, Pointers+4
  ld a, e ; de - b
  sub b
  ld e, a
  ld a, d
  sbc 0
  ld d, a
  ld a, [de]

; shift brush to col
  ld b, a
  ldh a, [hCursorX]
  and %111
  jr .skip
.shiftLoop
  rr b
  dec a
.skip
  jr nz, .shiftLoop

  call BrushHeight

; actually apply paint
.paintLoop ; broken at tile edges
  ldh a, [hCursorColor]
  bit 6, a ; is msb set?
  jr z, .clearMSB
  ld a, [hl]
  or b
  ld [hli], a
  jr .LSB
.clearMSB
  ld a, [hl]
  cpl
  or b
  cpl
  ld [hli], a
.LSB
  ldh a, [hCursorColor]
  bit 7, a ; is msb set?
  jr z, .clearLSB
  ld a, [hl]
  or b
  ld [hli], a
  jr .next
.clearLSB
  ld a, [hl]
  cpl
  or b
  cpl
  ld [hli], a

.next
  ld a, c
  dec c
  jr nz, .paintLoop

  ret

VBlank::
; draw using the second tileset
  ld      a,LCDCF_ON|LCDCF_BG8800|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
  ld      [rLCDC],a       ; Turn screen on

.input
  call ReadJoypad
  ldh a, [hButtons]
  ld b, a ; b contain pressed buttons, don't mess it up

  cp 0 ; no buttons
  jr z, .nothing

  ; Check frame counter
  ldh a, [hFrameCounter]
  cp a, 0
  jr z, .something
  dec a
  ldh [hFrameCounter], a
  reti ; don't do anything until we rech 0

.something
  ldh a, [hFrameSkip]
  srl a
  ldh [hFrameSkip], a
  ldh [hFrameCounter], a

  bit PADB_START, b
  jr z, .noStart
  call SaveSRAM
.noStart
  bit PADB_SELECT, b
  jr z, .noSelect
  ld a, 0
  ldh [hSelectionIndex], a
  ldh [hMode], a
.noSelect
  ldh a, [hMode]
  cp 0
  jr nz, .drawMode
  call MoveSelection
  call ChangeBrush
  call DrawSelection
  reti
.drawMode
  call MoveCursor
  call ApplyPaint
  reti
.nothing
  ld a, 32
  ldh [hFrameSkip], a
  ld a, 0
  ldh [hFrameCounter], a
  reti

Coincidence::
; draw the UI using the first tileset
  ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
  ld      [rLCDC],a       ; Turn screen on
reti

;* End of File *

