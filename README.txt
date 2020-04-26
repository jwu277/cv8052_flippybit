

███████╗██╗     ██╗██████╗ ██████╗ ██╗   ██╗     █████╗  ██████╗ ███████╗██████╗ 
██╔════╝██║     ██║██╔══██╗██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔═████╗██╔════╝╚════██╗
█████╗  ██║     ██║██████╔╝██████╔╝ ╚████╔╝     ╚█████╔╝██║██╔██║███████╗ █████╔╝
██╔══╝  ██║     ██║██╔═══╝ ██╔═══╝   ╚██╔╝      ██╔══██╗████╔╝██║╚════██║██╔═══╝ 
██║     ███████╗██║██║     ██║        ██║       ╚█████╔╝╚██████╔╝███████║███████╗
╚═╝     ╚══════╝╚═╝╚═╝     ╚═╝        ╚═╝        ╚════╝  ╚═════╝ ╚══════╝╚══════╝
                                                                                 
================================================================================
Flippy 8052 is a hexadecimal game for the CV-8052, a virtual processor for
the DE0-CV board used in one of my courses (CPEN 312 @ UBC).
================================================================================
Credits:
This game is based on Flippy Bit by Q42 and Kateryna Afinogenova.
The idea for implementing the game on the CV-8052 was shared to me by Jesse Li,
a very talented individual who was also taking the course.
================================================================================
Game Instructions:

In brief, your goal is to enter what is displayed on HEX1/0 through the
switches SW7-0, hitting KEY3 to submit the input. This is done under time
pressure. HEX5/4 displays your current score.

On hardware reset, you are shown the title "screen." Press (and release) KEY0
to begin the game.

On the game over "screen" press KEY0 to restart the game.

In more detail:
The TARGET (two-digit hexadecimal number) is displayed on HEX1/0.
Your objective is to toggle switches SW7-0 to match the hexadecimal number.
To assist you, the current INPUT on SW7-0 is displayed in HEX3/2. When you have
the correct number enterred, press KEY3 to SUBMIT the entry and score a point.
Your score is displayed on HEX5/4. Scoring a point increments this count and
gives a new TARGET. Nothing will happen if you SUBMIT an incorrect INPUT.
The TIMER is displayed on the LED banks. When the LEDs all turn off, your time
is up and it is game over (where you are brought to the game over screen).
Scoring a point resets the TIMER.
