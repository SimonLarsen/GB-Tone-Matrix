; +-------------------------+
; |   Gameboy Tone Matrix   |
; |  written in RGBDS ASM   |
; |  (c) 2010 Simon Larsen  |
; +-------------------------+
; ============
;   Includes
; ============
	INCLUDE	"Hardware.inc"
	INCLUDE "Header.inc"
; =================
;   Program Start
; =================
SECTION "Program Start",HOME[$0150]
Start::
	call WAIT_VBLANK

	ld	a,0			
	ld	[rLCDC],a ; Disable LCD
	ld	a,%11100100
	ld	[rBGP],a	; Standard palette
	ld	[rOBP0],a

	call LOAD_TILES	
	call CLEAR_SCRN0
	call CLEAR_MATRIX
	call DRAW_BOARD
	call CREATE_SPRITES

	ld	a,%10010011
	ld	[rLCDC],a
	jp	PLAY_MUSIC

Loop::
	REPT 24
		call WAIT_VBLANK
	ENDR
	call CHECK_ARROWS
	call MOVE_CURSOR
	call CHECK_BUTTONS
	jp	Loop

NonLoop::
	REPT 24
		call WAIT_VBLANK
	ENDR
	call CHECK_ARROWS
	call MOVE_CURSOR
	call CHECK_BUTTONS
	ret

; ===============
;   Subroutines
; ===============
; Wait for V-Blank period. Bad way. Rewrite!
WAIT_VBLANK::
	ldh	a,[rLY]
	cp	145
	jr	nz,WAIT_VBLANK
	ret

; Load tiles from TILES_DATA to VRAM
LOAD_TILES::
	ld	hl,TILES_DATA
	ld	de,_VRAM
	ld	b,5*16
LOAD_TILES_LOOP::
	ld	a,[hl+]
	ld	[de],a	
	inc	de
	dec	b
	jr	nz,LOAD_TILES_LOOP
	ret

; Draws 16x16 matrix of tile 1 in upper left corner
DRAW_BOARD::
	ld	hl,_SCRN0
	ld	b,16	; y counter
DRAW_BOARD_LOOP::
	ld	c,16	; x counter
	call DRAW_BOARD_XLOOP
	dec	b
	ld	de,16
	add	hl,de
	jr	nz,DRAW_BOARD_LOOP
	ret
DRAW_BOARD_XLOOP
	ld	a,1
	ld	[hl+],a
	dec	c
	jr	nz,DRAW_BOARD_XLOOP
	ret

CLEAR_SCRN0::
	ld	hl,_SCRN0
	ld	bc,32*32	
CLEAR_SCRN0_LOOP::
	ld	a,0
	ld	[hl+],a
	dec	bc
	ld	a,b
	or	c
	jr	nz,CLEAR_SCRN0_LOOP
	ret

CLEAR_MATRIX::
	ld	hl,MATRIX
	ld	bc,16*16 ; Counter
CLEAR_MATRIX_LOOP::
	ld	a,0
	ld	[hl+],a
	dec	bc
	ld	a,b
	or	c
	jr	nz,CLEAR_MATRIX_LOOP
	ret

; Creates cursor sprite
CREATE_SPRITES::
	; Setup MARKER/CURSOR
	ld	a,0
	ld	[MARKERX],a ; Set marker x and y coord
	ld	[MARKERY],a ; to zero (upper left corner)
	ld	hl,_OAMRAM
	ld	a,16 
	ld	[hl+],a ; Set Y-Coord
	ld	a,8
	ld	[hl+],a ; Set X-Coord
	ld	a,3
	ld	[hl+],a ; Set sprite = cursor
	ld	a,0
	ld	[hl+],a ; Set attribute stuff

	; Setup playback marker arrow
	ld	a,0 
	ld	[hl+],a ; Set Y-Coord = below matrix
	ld	a,8
	ld	[hl+],a ; Set X-Coord outside screen 
	ld	a,4
	ld	[hl+],a ; Set sprite = arrow
	ld	a,0
	ld	[hl+],a
	ret

; Moves cursor to correct position based on MARKERX and MARKERY
MOVE_CURSOR::
	WAIT_VBLANK
	ld	hl,_OAMRAM
	; Calculate y coord
	; MARKERY*8 + 16
	ld	a,[MARKERY]
	rlca
	rlca
	rlca	
	add	a,16
	ld	[hl+],a
	; Calculate x coord
	; MARKERY*8 + 8
	ld	a,[MARKERX]
	rlca
	rlca
	rlca
	add	a,8
	ld	[hl+],a
	ret

; Check arrow key status and move cursor accordingly
CHECK_ARROWS::
	ld	a,P1F_5
	ld	[rP1],a
	REPT 6
		nop
	ENDR
	REPT 4
		ld	a,[rP1]
	ENDR
	ld	b,a

	bit	0,b
	jr	z,RIGHT_PRESSED
AFTER_RIGHT_CHECK::
	bit	1,b
	jr	z,LEFT_PRESSED
AFTER_LEFT_CHECK::
	bit	2,b
	jr	z,UP_PRESSED
AFTER_UP_CHECK::
	bit	3,b
	jr	z,DOWN_PRESSED
AFTER_DOWN_CHECK::
	ret

RIGHT_PRESSED::
	ld	a,[MARKERX]
	cp	$0F
	ret	z
	inc	a
	ld	[MARKERX],a
	jp AFTER_RIGHT_CHECK

LEFT_PRESSED::
	ld	a,[MARKERX]
	or	0
	ret	z
	dec	a
	ld	[MARKERX],a
	jp AFTER_LEFT_CHECK

UP_PRESSED::
	ld	a,[MARKERY]
	or	0
	ret	z
	dec	a
	ld	[MARKERY],a
	jp AFTER_UP_CHECK

DOWN_PRESSED::
	ld	a,[MARKERY]
	cp	$0F
	ret z
	inc	a
	ld	[MARKERY],a
	jp AFTER_DOWN_CHECK

; Check A, B and Start buttons
; and set MATRIX to 1 or 0
; or start playing if Start is pressed
CHECK_BUTTONS::
	ld	a,P1F_4
	ld	[rP1],a	
	REPT 4
		ld	a,[rP1]
	ENDR

	bit	0,a
	jr	z,A_PRESSED
	bit	1,a
	jr	z,B_PRESSED
	bit	2,a
	jr	z,SELECT_PRESSED
	;bit	3,a
	;jr	z,START_PRESSED
	ret

A_PRESSED::
	call CURRENT_VRAM_FIELD_CALC
	ld	[hl],2
	call CURRENT_MATRIX_FIELD_CALC
	ld	[hl],1
	ret

B_PRESSED::
	call CURRENT_VRAM_FIELD_CALC
	ld	[hl],1
	call CURRENT_MATRIX_FIELD_CALC
	ld	[hl],0
	ret

SELECT_PRESSED::
	call WAIT_VBLANK
	ld	a,0
	ld	[rLCDC],a
	call CLEAR_SCRN0
	call DRAW_BOARD
	call CLEAR_MATRIX
	ld	a,%10010011
	ld	[rLCDC],a
	ret

; Loops music in matrix until Start is pressed again
PLAY_MUSIC::
	call ENABLE_SOUND
	ld	b,0 ; b = something :P
	ld	c,0 ; c = Horizontal counter
	ld	e,0 ; e = Vertical counter
	ld	d,0 ; d = Tone counter

	ld	a,0
	ld	[HPOS],a

	call WAIT_VBLANK
	ld	hl,_OAMRAM+4 ; Put arrow in left side
	ld	a,9*16
	ld	[hl],a
PLAY_MUSIC_HORIZONTAL_LOOP::
	call NonLoop
	call NonLoop
	ld	a,[HPOS]
	ld	c,a
PLAY_MUSIC_VERTICAL_LOOP::
	ld	hl,MATRIX
	ld	b,0
	add	hl,bc ; Add horizontal coord to hl address
	ld	a,d ; Temp. save D in A
	ld	d,0
	REPT 16
		add	hl,de ; Add vertical coord 16 times !!! VERY BAD WAY!
	ENDR
	ld	d,a ; Restore D

	ld	a,[hl]
	cp	1 			 ; Check wether current field is set
	call z,PLAY_TONE ; Play tone if so
	ld	a,d
	cp 2
	jp	z,VERTICAL_LOOP_END

	inc	e ; Increment vertical counter
	ld	a,e
	cp 16
	jr	nz,PLAY_MUSIC_VERTICAL_LOOP ; If end of vertical loop is not reached
VERTICAL_LOOP_END::
	ld	e,0 ; Reset vertical counter
	ld	d,0 ; Reset tone counter

	; Move arrow sprite
	call WAIT_VBLANK
	ld	hl,_OAMRAM+5
	ld	a,[hl]
	add	a,8
	ld	[hl],a

	inc	c  ;Increment Horizontal counter
	ld	a,c	
	cp	16 ; Reset of hor.count. if it has reached 16
	call z,RESET_HORIZONTAL_COUNTER

	ld	a,c
	ld	[HPOS],a
	jp	PLAY_MUSIC_HORIZONTAL_LOOP ; Restart loop

PLAY_TONE::
	ld	hl,TONES
	ld	a,d ; Temp. save d
	ld	d,0
	add	hl,de
	add	hl,de
	ld	d,a ; Restore d
	or	0
	jr z,PLAY_TONE_CN1
	jr   PLAY_TONE_CN2
	ret
PLAY_TONE_CN1::
	ld	a,[hl+]
	ld	[rNR13],a
	ld	a,[hl]
	add	a,%11000000
	ld	[rNR14],a
	inc	d
	ret
PLAY_TONE_CN2::
	ld	a,[hl+]
	ld	[rNR23],a
	ld	a,[hl]
	add	a,%11000000
	ld	[rNR24],a
	inc	d
	ret

RESET_HORIZONTAL_COUNTER::
	ld	c,0
	ld	hl,_OAMRAM+5
	ld	a,8
	ld	[hl],a
	ret

ENABLE_SOUND::
	; Reenable sounds
	;ld	a,%11111111
	;ld	[rNR52],a

	; Reset Channel 1 and 2
	ld	a,0
	ld	[rNR10],a
	ld	a,%10001111
	ld	[rNR11],a
	ld	[rNR21],a
	ld	a,%01001000
	ld	[rNR12],a
	ld	[rNR22],a
	ld	a,%11111111
	ld	[rNR13],a
	ld	[rNR23],a
	ld	a,%11111111
	ld	[rNR14],a
	ld	[rNR24],a
	ret

; Calculate address in VRAM to change 
; from MARKERX and -Y values
; place address in HL
CURRENT_VRAM_FIELD_CALC::
	ld	hl,_SCRN0
	ld	a,[MARKERX]
	ld	bc,0
	ld	c,a
	add	hl,bc
	ld	bc,32
	ld	a,[MARKERY]
	or	0
	ret z
	ld	d,a	; Counter
CURRENT_VRAM_FIELD_CALC_LOOP::
	add	hl,bc
	dec	d
	jr	nz,CURRENT_VRAM_FIELD_CALC_LOOP
	ret

; Calculate address in MATRIX
; place address in HL
CURRENT_MATRIX_FIELD_CALC::
	ld	hl,MATRIX
	ld	a,[MARKERX]
	ld	bc,0
	ld	c,a
	add	hl,bc
	ld	bc,16
	ld	a,[MARKERY]
	or	0
	ret	z
	ld	d,a
CURRENT_MATRIX_FIELD_CALC_LOOP::
	add	hl,bc
	dec	d
	jr	nz,CURRENT_MATRIX_FIELD_CALC_LOOP
	ret
; ==================
;    Constant data
; ==================
SECTION "Tones",HOME
TONES::	DB %01101011 ; A
		DB %00000111 ; 1899
		DB %01001111 ; F#
		DB %00000111 ; 1871
		DB %00111001 ; E
		DB %00000111 ; 1849
		DB %00100001 ; D
		DB %00000111 ; 1825
		DB %11110111 ; B
		DB %00000110 ; 1783
		DB %11010110 ; A
		DB %00000110 ; 1750
		DB %10011110 ; F#
		DB %00000110 ; 1694
		DB %01110010 ; E
		DB %00000110 ; 1650
		DB %01000010 ; D
		DB %00000110 ; 1602
		DB %11101101 ; H
		DB %00000101 ; 1517
		DB %10101100 ; A
		DB %00000101 ; 1452
		DB %00111011 ; F#
		DB %00000101 ; 1339
		DB %11100101 ; E
		DB %00000100 ; 1253
		DB %10000011 ; D
		DB %00000100 ; 1155
		DB %11011010 ; B
		DB %00000011 ; 986
		DB %01010110 ; A
		DB %00000011 ; 854
; ============
;     Tiles
; ============
SECTION "Tiles", HOME
TILES_DATA::
	DB $00,$00,$00,$00,$00,$00,$00,$00 ; $00	Blank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $01,$00,$7E,$01,$7E,$01,$7E,$01 ; $01	White box
	DB $7E,$01,$7E,$01,$7E,$01,$80,$7F
	DB $FE,$01,$81,$7F,$81,$7F,$81,$7F ; $02	Black box
	DB $81,$7F,$81,$7F,$81,$7F,$7F,$FF
	DB $66,$81,$E7,$66,$FF,$42,$3C,$18 ; $03	Cursor
	DB $3C,$18,$FF,$42,$E7,$66,$66,$81
	DB $00,$00,$08,$08,$1C,$1C,$3E,$3E ; $04	Indicator arrow
	DB $7F,$7F,$00,$00,$00,$00,$00,$00

; =============
;   Variables
; =============
SECTION "Variables",BSS
MARKERX:: DB
MARKERY:: DB 
HPOS:: DB
MATRIX::  DS 256
