include "lib/debug.inc"		; debugger support
include "src/test_util.inc"	; test macros

section "begin test harness",ROM0

Begin::
	debugmsg "# TAP version 12"
	call subtraction
	jp end_tests

test
subtraction:
	ld	a,42
	sub	a,40
	sub	a,2
	jp	z,.ok
	pass_if	z,"subtraction"
.pass:
	debugmsg "ok {test_number} subtraction"
.fail:
	debugmsg "not ok {test_number} subtraction"
.end:

end_tests:
	debugmsg "1..{test_number}"
	quit

; vim: se ft=rgbds ts=8 sw=8 sts=8 noet:
