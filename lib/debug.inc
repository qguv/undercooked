if !def(DEBUG_INC)
def DEBUG_INC = 1

; Prints a message to the no$gmb / bgb debugger
; Accepts a string as input, see emulator doc for support
macro debug
        ld  d, d
        jr .end\@
        dw $6464
        dw $0000
        db \1
.end\@:
endm

endc ; !def(DEBUG_INC)

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
