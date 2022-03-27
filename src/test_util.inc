macro pass_if
	jp \1,.pass
	debugmsg "not ok {test_number}"
.pass\@:
;.fail\@:
.end\@:
endm

def test_number = 0
macro test
def test_number += 1
endm

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
