include "lib/debug.inc"		; debugger support

section "begin test harness",ROM0
Begin::
	; wait for vblank
	halt
	debugmsg "# TAP version 12"
	debugmsg "ok 1 bgb debugmsg works"
	debugmsg "1..1"
	quit

