section "begin main game loop",ROM0
Begin::
	call	Input
	jp	Begin

	; sleep CPU until next vblank
	halt
