fs3_freq equ 1339
g3_freq equ 1379
gs3_freq equ 1417
a3_freq equ 1452
as3_freq equ 1486
b3_freq equ 1517
c4_freq equ 1546
cs4_freq equ 1575
d4_freq equ 1602
ds4_freq equ 1627
e4_freq equ 1650
f4_freq equ 1673
fs4_freq equ 1694
g4_freq equ 1714
gs4_freq equ 1732
a4_freq equ 1750

	rsreset	; this is space-sensitive for literally no reason
fs3	rb 1
g3	rb 1
gs3	rb 1
a3	rb 1
as3	rb 1
b3	rb 1
c4	rb 1
cs4	rb 1
d4	rb 1
ds4	rb 1
e4	rb 1
f4	rb 1
fs4	rb 1
g4	rb 1
gs4	rb 1
a4	rb 1

NoteFreqs:
	dw	fs3_freq, g3_freq, gs3_freq, a3_freq, \
		as3_freq, b3_freq, c4_freq, cs4_freq, \
		d4_freq, ds4_freq, e4_freq, f4_freq, \
		fs4_freq, g4_freq, gs4_freq, a4_freq

; vim: se ft=rgbds:
