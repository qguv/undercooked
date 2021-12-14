section "begin main game loop",ROM0
Begin::
	; wait for vblank
	halt
	call	Input
	jp	Begin
