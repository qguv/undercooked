validateCoords: MACRO
	IF \1 >= SCRN_VX_B
		fail "x coord out of range"
	ENDC
	IF \2 >= SCRN_VY_B
		fail "y coord out of range"
	ENDC
ENDM

;\1 = r
;\2 = X
;\3 = Y
;\4 = which tilemap (optional)
coord: MACRO
	validateCoords \2, \3
	IF _NARG >= 4
		ld \1, \4 + (SCRN_VX_B * \3) + \2
	ELSE
		ld \1, _SCRN0 + (SCRN_VX_B * \3) + \2
	ENDC
ENDM
