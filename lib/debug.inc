if !def(DEBUG_INC)
def DEBUG_INC = 1

; Prints a message to the no$gmb / bgb debugger
; Accepts a string as input, see emulator doc for support
DBGMSG: MACRO
        ld  d, d
        jr .end\@
        DW $6464
        DW $0000
        DB \1
.end\@:
        ENDM

endc ; !def(DEBUG_INC)

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
