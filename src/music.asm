c2_freq equ 44
cs2_freq equ 156
d2_freq equ 262
ds2_freq equ 363
e2_freq equ 457
f2_freq equ 547
fs2_freq equ 631
g2_freq equ 710
gs2_freq equ 786
a2_freq equ 854
as2_freq equ 923
b2_freq equ 986
c3_freq equ 1046
cs3_freq equ 1102
d3_freq equ 1155
ds3_freq equ 1205
e3_freq equ 1253
f3_freq equ 1297
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
as4_freq equ 1767
b4_freq equ 1783

	rsreset	; this is space-sensitive for literally no reason
c2	rb 1
cs2	rb 1
d2	rb 1
ds2	rb 1
e2	rb 1
f2	rb 1
fs2	rb 1
g2	rb 1
gs2	rb 1
a2	rb 1
as2	rb 1
b2	rb 1
c3	rb 1
cs3	rb 1
d3	rb 1
ds3	rb 1
e3	rb 1
f3	rb 1
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
as4	rb 1
b4	rb 1
REST	rb 1

NoteFreqs
	dw	c2_freq, cs2_freq, d2_freq, ds2_freq, \
		e2_freq, f2_freq, fs2_freq, g2_freq, \
		gs2_freq, a2_freq, as2_freq, b2_freq, \
		c3_freq, cs3_freq, d3_freq, ds3_freq, \
		e3_freq, f3_freq, fs3_freq, g3_freq, \
		gs3_freq, a3_freq, as3_freq, b3_freq, \
		c4_freq, cs4_freq, d4_freq, ds4_freq, \
		e4_freq, f4_freq, fs4_freq, g4_freq, \
		gs4_freq, a4_freq, as4_freq, b4_freq

; vim: se ft=rgbds:
