$MODDE0CV

AUX_TIMER_RELOAD 	EQU 38	; countdown period = _ * 23ms (approx.)

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
cd:			DS 1 ; countdown
saved_in:	DS 1 ; last user input before game over
wait_time:	DS 1 ; wait period = _ * 6ms (approx.)

BSEG at 00H
game_over_flag:	DBIT 1

CSEG at 0200H
hex_to_7seg:
DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 90H
DB 88H, 83H, 0C6H, 0A1H, 086H, 08EH
intro_flippy:
DB 08EH, 0C7H, 0CFH, 8CH, 8CH, 91H, 0FFH
intro_8052:
DB 80H, 0C0H, 92H, 0A4H, 0FFH, 0FFH
intro_flippy2:
DB 08EH, 0C7H, 0CFH, 8CH, 8CH, 91H

CSEG at 1000H

timer1_isr:

	djnz aux_timer, timer1_isr_ret
	mov aux_timer, #AUX_TIMER_RELOAD ; ~1s
	
	lcall countdown
	
timer1_isr_ret:
	reti

countdown:

	djnz cd, countdown_continue
	setb game_over_flag
	mov saved_in, SWA
	
countdown_continue:

	clr C

	xch A, LEDRB
	rrc A
	xch A, LEDRB

	xch A, LEDRA
	rrc A
	xch A, LEDRA

	ret

main:

	mov SP, #7FH
	
	lcall init
	
loop:
	
	lcall update
	lcall display
	
	jb game_over_flag, game_over
	
	sjmp loop

game_over:

	lcall clear_7seg
	
	mov wait_time, #90
	lcall wait

	lcall game_over_display
	
	mov wait_time, #150
	lcall wait
	
	jnb KEY.0, game_over_key_pressed
	
	jb KEY.0, game_over ; if KEY.0 pressed, continue
game_over_key_pressed:
	lcall game_over_display
	jnb KEY.0, $
	lcall reset
	sjmp loop ; resets after KEY.0 is pressed and released

;; Initial configs here
init:

	; Turn off LEDs
	mov LEDRA, #0
	mov LEDRB, #0
	
	;; Ready to generate random number
	mov next_num, #0
	
	; Enable Timer 0 in Mode 2 + Timer 1 in Mode 1
	setb EA
	setb ET0
	setb ET1
	mov TMOD, #12H
	mov TH0, #0E0H ; Timer 0 to overflow every ~11.5 us
	setb TR0
	
	; Display intro
	lcall intro
	
	; Wait for KEY.0 press + release
	jb KEY.0, $
	jnb KEY.0, $
	
	lcall reset
	
	setb TR1 ; Run Timer 1 after we start

	ret

; Intro "title screen." Should be interruptable by KEY.0
intro:

	; 1. Display Flippy
	mov DPTR, #intro_flippy
	lcall display_intro
	
	mov wait_time, #60
	lcall wait
	
	jnb KEY.0, intro_ret

	; 2. Flippy 8052 loop
	mov R3, #intro_flippy2 - intro_flippy + 1
	mov wait_time, #80
intro_loop0:

	lcall display_intro
	lcall wait
	jnb KEY.0, intro_ret
	
	inc DPTR
	
	djnz R3, intro_loop0
	
	; 3. LED light show
	
	mov wait_time, #100
	
	mov LEDRA, #55H
	mov LEDRB, #55H
	
	lcall wait
	jnb KEY.0, intro_ret
	
	mov LEDRA, #0AAH
	mov LEDRB, #0AAH
	
	lcall wait
	jnb KEY.0, intro_ret
	
	mov LEDRA, #55H
	mov LEDRB, #55H
	
	lcall wait
	jnb KEY.0, intro_ret
	
	mov LEDRA, #0AAH
	mov LEDRB, #0AAH
	
	lcall wait
	jnb KEY.0, intro_ret
	
	mov LEDRA, #00H
	mov LEDRB, #00H
	
	lcall wait
	jnb KEY.0, intro_ret
	
	sjmp intro

intro_ret:
	ret

display_intro:
	
	mov B, #0
	
	mov A, B
	movc A, @DPTR+A
	mov HEX5, A
	
	inc B
	mov A, B
	movc A, @DPTR+A
	mov HEX4, A
	
	inc B
	mov A, B
	movc A, @DPTR+A
	mov HEX3, A
	
	inc B
	mov A, B
	movc A, @DPTR+A
	mov HEX2, A
	
	inc B
	mov A, B
	movc A, @DPTR+A
	mov HEX1, A
	
	inc B
	mov A, B
	movc A, @DPTR+A
	mov HEX0, A

	ret

reset:

	clr game_over_flag

	; Reset score
	mov score+0, #0
	mov score+1, #0
	
	lcall refresh

	ret

;; wait that is interruptable by KEY.0
wait:

	mov R0, #0
	mov R1, #0
	mov R2, wait_time
	
wait_loop:
	jnb KEY.0, wait_ret
	djnz R0, $
	djnz R1, wait_loop
	djnz R2, wait_loop

wait_ret:
	ret

;; Takes num and randomizes it. Should be a disorderly 1:1 map.
randomize:

	mov a, num
	swap a
	xrl a, #11001101b
	mov num, a

	ret

;; Updates the score based on whether user input is correct
update:

	jb KEY.3, update_ret ; continue if button not pressed
	jnb KEY.3, $ ; wait for release
	
	; See if user has correct input
	mov a, SWA
	cjne a, num, update_ret
	
	lcall refresh
	lcall inc_score

update_ret:
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
	mov cd, #11

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

game_over_display:

	lcall display_score
	lcall display_saved_input
	lcall display_num

	ret

clear_7seg:

	mov HEX5, #0FFH
	mov HEX4, #0FFH
	mov HEX3, #0FFH
	mov HEX2, #0FFH
	mov HEX1, #0FFH
	mov HEX0, #0FFH

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

display_saved_input:

	mov A, saved_in
	anl A, #0FH
	movc A, @A+DPTR
	mov HEX2, A
	
	mov A, saved_in
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
