$MODDE0CV

AUX_TIMER_RELOAD EQU 42

CSEG at 0000H
ljmp main

CSEG at 000BH
inc next_num
reti

CSEG at 001BH
ljmp timer1_isr

CSEG at 0100H
DB	'Hexadecimal game for the CV-8052 by James Wu.'
DB	'Based on Flippy Bit by Q42 and Kateryna Afinogenova.'
DB	'Idea for implementing the game on the CV-8052 proposed by Jesse Li.'

DSEG at 30H
score:		DS 2 ; low digit + high digit
num:		DS 1 ; random number for user to match
next_num:	DS 1 ; next random number, randomized with time
aux_timer:	DS 1 ; auxiliary timer for timer 1 countdown to add more bits

CSEG at 0200H
hex_to_7seg:
DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 90H
DB 88H, 83H, 0C6H, 0A1H, 086H, 08EH

CSEG at 1000H

timer1_isr:

	djnz aux_timer, timer1_isr_ret
	mov aux_timer, #AUX_TIMER_RELOAD ; ~1s
	
	lcall countdown
	
timer1_isr_ret:
	reti

countdown:

	clr C

	xch A, SWB
	rrc A
	xch A, SWB

	xch A, SWA
	rrc A
	xch A, SWA

	ret

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
	
	; Reset score
	mov score+0, #0
	mov score+1, #0
	
	;; Generate random number
	mov next_num, #0
	
	; Display '--' on HEX1/0 while waiting for user to start (KEY.0)
	mov HEX0, #0BFH
	mov HEX1, #0BFH
	
	; Enable Timer 0 in Mode 2 + Timer 1 in Mode 1
	setb EA
	setb ET0
	setb ET1
	mov TMOD, #12H
	mov TH0, #0E0H ; Timer 0 to overflow every ~11.5 us
	setb TR0
	setb TR1
	
	; Wait for KEY.0 press + release
	jb KEY.0, $
	jnb KEY.0, $
	
	lcall refresh

	ret

;; Takes num and randomizes it. Should be a disorderly 1:1 map.
randomize:

	mov a, num
	swap a
	xrl a, #11001101b
	mov num, a

	ret

;; Updates the score based on whether user input is correct
update_score:

	jb KEY.3, get_score_ret ; continue if button not pressed
	jnb KEY.3, $ ; wait for release
	
	; See if user has correct input
	mov a, SWA
	cjne a, num, get_score_ret
	
	lcall inc_score
	lcall refresh

get_score_ret:
	ret

; Increments the decimal score
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

; Refreshes appropriate registers for next round
refresh:

	mov aux_timer, #AUX_TIMER_RELOAD

	mov SWB, #03H
	mov SWA, #0FFH

	mov num, next_num
	
	lcall randomize
	
	ret

display:

	lcall display_score
	lcall display_input
	lcall display_num

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

display_num:

	mov A, num
	anl A, #0FH
	movc A, @A+DPTR
	mov HEX0, A
	
	mov A, num
	swap A
	anl A, #0FH
	movc A, @A+DPTR
	mov HEX1, A

	ret

END
