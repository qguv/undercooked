section "begin main game loop",ROM0
Begin::
	call	Input

	; sleep CPU until next vblank
	halt

	jp	Begin
