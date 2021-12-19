if !def(DEBUG_INC)
def DEBUG_INC = 1

; Prints a message to the no$gmb / bgb debugger
; Accepts a string as input, see emulator doc for support
macro debugmsg
	ld  d, d
	jr .end\@
	dw $6464
	dw $0000
	db \1
.end\@:
endm

; Access echo ram, which quits bgb when run with "-autoexit -set DebugEcho=1".
; Another option would be to quit using an illegal opcode (e.g. db $dd) but I
; don't know what this would do to real hardware.
macro quit
	ld a,[$e000]
	stop
endm

endc ; !def(DEBUG_INC)

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
