include "lib/gbhw.inc"		; hardware descriptions
include "src/freqs.inc"		; note frequencies
include "src/notes.inc"		; note names
include "src/optim.inc"		; optimized instruction aliases

SONG_LENGTH equ 32		; number of NOTES not BYTES

section "music",ROM0

NoteFreqs:
	dw	c2_freq, cs2_freq, d2_freq, ds2_freq, \
		e2_freq, f2_freq, fs2_freq, g2_freq, \
		gs2_freq, a2_freq, as2_freq, b2_freq, \
		c3_freq, cs3_freq, d3_freq, ds3_freq, \
		e3_freq, f3_freq, fs3_freq, g3_freq, \
		gs3_freq, a3_freq, as3_freq, b3_freq, \
		c4_freq, cs4_freq, d4_freq, ds4_freq, \
		e4_freq, f4_freq, fs4_freq, g4_freq, \
		gs4_freq, a4_freq, as4_freq, b4_freq

NotesPU1:
	db	a4,fs4,cs4,a3,gs4,e4,b3,gs3, \
		fs4,d4,a3,fs3,a3,d4,fs4,d4, \
		fs4,d4,a3,fs3,gs4,e4,b3,gs3, \
		a4,fs4,cs4,a3,cs4,fs4,a4,fs4
NotesPU2:
	db	fs3,REST,fs3,REST,e3,REST,e3,d3, \
		KILL,REST,d3,d3,d3,d3,d3,REST, \
		d3,REST,d3,REST,e3,REST,e3,fs3, \
		KILL,REST,fs3,fs3,fs3,fs3,fs3,fs4
NotesWAV:
	db	fs3,fs3,fs3,REST,e3,e3,REST,d3, \
		REST,REST,d3,d3,d3,d3,d3,REST, \
		d3,d3,d3,REST,e3,e3,REST,fs3, \
		REST,REST,fs3,fs3,fs3,fs3,fs3,fs4

NoteDuration: ; in number of vblanks, this table will be cycled
	db	9, 7
NoteDurationEnd:

Wavetable:
	db $89,$ab,$cd,$ef,$fe,$dc,$ba,$98,$76,$54,$32,$10,$01,$23,$45,$67

HandleNotes:
	ld	a,[note_dur]		; if duration of previous note is expired, continue
	cpz
	jp	z,.next_note
	dec	a			; otherwise decrement and return
	ld	[note_dur],a
	ret
.next_note
	ld	a,[note_swindex]
	ld	hl,NoteDuration
	addhla				; add index into note duration table
	ld	a,[hl]			; set next note duration
	ld	[note_dur],a
	ld	a,[note_swindex]	; increase note swing index
	inc	a
	cp	NoteDurationEnd-NoteDuration	; wrap if necessary
	jp	c,.dont_wrap
	ldz
.dont_wrap
	ld	[note_swindex],a
	ld	a,[note_index]		; get note index
	cp	a,SONG_LENGTH-1		; if hPU1NoteIndex isn't zero, fine...
	jp	nz,.sound_registers
	ld	a,1			; ...but if it is, the song has repeated and we need to mark that
	ld	[song_repeated],a

macro pulsenote
	; index the notes-in-song table with the note song-index to get the actual note value
	ld	b,0
	ld	a,[note_index]
	ld	c,a
	ld	hl,\1
	add	hl,bc
	ld	c,[hl]

	ld	a,c			; if it's a rest (note 0), don't set any registers for this note
	cpz
	jp	z,.end\@

	cp	$ff			; if it's a kill command (note $ff), stop the note
	jp	nz,.nocut\@
	ldz
	ld	[\6],a
	ld	a,$80
	ld	[\8],a
	jp	.end\@
.nocut\@

	; index the note frequency table with the actual note value to get the note frequency (16-bit)
	ld	b,0
	sla	c			; double the index (16-bit), sla+rl together represents a 16-bit left shift
	rl	b

	ld	hl,NoteFreqs		; now index the damn table
	add	hl,bc

	ldz				; disable sweep
	ld	[\4],a
	ld	a,\2			; duty cycle (top two) and length (the rest)
	ld	[\5],a
	ld	a,\3			; envelope, precisely like LSDj
	ld	[\6],a
	ld	a,[hl+]			; freq LSB
	ld	[\7],a
	ld	a,[hl]			; freq MSB
	and	%00000111		; truncate to bits of MSB that are actually used
	or	%10000000		; reset envelope (not legato)
	ld	[\8],a			; set frequency MSB and flags
.end\@
endm ; pulsenote

.sound_registers
	pulsenote	NotesPU1,%00111111,$F1,rAUD1SWEEP,rAUD1LEN,rAUD1ENV,rAUD1LOW,rAUD1HIGH
	pulsenote	NotesPU2,%10111111,$C3,rAUD2LOW,rAUD2LEN,rAUD2ENV,rAUD2LOW,rAUD2HIGH ; TODO: skip sweep appropriately

	ld	a,[note_index]	; increment index of note in song
	inc	a
	and	SONG_LENGTH-1
	ld	[note_index],a

	ret

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
