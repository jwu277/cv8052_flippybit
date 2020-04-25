$MODDE0CV

CSEG at 0000H
ljmp main

CSEG at 0100H
DB	'Hexadecimal game for the CV-8052 by James Wu.'
DB	'Based on Flippy Bit by Q42 and Kateryna Afinogenova.'
DB	'Idea for implementing the game on the CV-8052 proposed by Jesse Li.'

DSEG at 30H
score: DS 2 ; low digit + high digit

CSEG at 0200H
hex_to_7seg:
DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 90H
DB 0A0H, 83H, 0C6H, 0A1H, 086H, 08EH

CSEG at 1000H

main:

	mov SP, #7FH

	lcall init
	
loop:
	
	lcall update_score
	lcall display
	
	sjmp loop

;; Initial configs here
init:

	; Turn off LEDs
	mov LEDRA, #0
	mov LEDRB, #0
	
	mov score+0, #0
	mov score+1, #0

	ret

;; Updates the score based on whether user input is correct
update_score:

	jb KEY.0, get_score_ret ; continue if button not pressed
	jnb KEY.0, $ ; wait for release
	
	lcall inc_score

get_score_ret:
	ret

inc_score:

	inc score+0
	mov R2, score+0
	cjne R2, #10, inc_score_ret
	
	mov score+0, #0
	inc score+1
	
	mov R2, score+1
	cjne R2, #10, inc_score_ret
	mov score+1, #0

inc_score_ret:
	ret

display:

	lcall display_score
	lcall display_input

	ret

;; Display decimal score on HEX5/4
display_score:

	mov DPTR, #hex_to_7seg
	mov A, score+0
	movc A, @A+DPTR
	mov HEX4, A
	
	mov DPTR, #hex_to_7seg
	mov A, score+1
	movc A, @A+DPTR
	mov HEX5, A

	ret

;; Display current input from SWA on HEX3/2
display_input:

	mov A, SWA
	anl A, #0FH
	movc A, @A+DPTR
	mov HEX2, A
	
	mov A, SWA
	swap A
	anl A, #0FH
	movc A, @A+DPTR
	mov HEX3, A

	ret

END
