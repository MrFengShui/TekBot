;***********************************************************
;*
;*	Lab5.asm
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 5 of ECE 375
;*
;***********************************************************
;*
;*	 Author: LUAN SONGJIAN
;*	   Date: 2015-10-31
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
; Other register renames
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.equ	WTime = 100				; Time to wait in wait loop
; Constants for interactions such as
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

; Using the constants from above, create the movement 
; commands, Forwards, Backwards, Stop, Turn Left, and Turn Right
.equ	MovFwd = (1 << EngDirR | 1 << EngDirL)	; Move Forwards Command
.equ	MovBck = $00							; Move Backwards Command
.equ	TurnR = (1 << EngDirL)					; Turn Right Command
.equ	TurnL = (1 << EngDirR)					; Turn Left Command
.equ	Halt = (1 << EngEnR | 1 << EngEnL)		; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

; Set up the interrupt vectors for the interrupts, .i.e
;.org	$002E					; Analog Comparator IV
;		rcall	HandleAC		; Function to handle Interupt request
;		reti					; Return from interrupt
.org	$0002					; INT0
		rcall	HIT_RIGHT
		reti

.org	$0004					; INT1
		rcall	HIT_LEFT
		reti

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:	; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, high(RAMEND)
		out		SPH, mpr
		ldi		mpr, low(RAMEND)
		out		SPL, mpr
		; Initialize Port B for output
		ldi		mpr, $00
		out		PORTB, mpr
		ldi		mpr, $FF
		out		DDRB, mpr
		; Initialize Port D for input
		ldi		mpr, $FF
		out		PORTD, mpr
		ldi		mpr, $00
		out		DDRD, mpr
		; Initialize external interrupts
		; Set the Interrupt Sense Control to low level 
		; NOTE: must initialize both EICRA and EICRB
		ldi		mpr,	(0 << ISC00 | 0 << ISC01 | 0 << ISC10 | 0 << ISC11)
		sts		EICRA,	mpr
		ldi		mpr,	0
		out		EICRB,	mpr
		; Set the External Interrupt Mask
		ldi		mpr,	(1 << INT0 | 1 << INT1)
		out		EIMSK,	mpr
		; Turn on interrupts
		; NOTE: This must be the last thing to do in the INIT function
		sei

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:	; The Main program
		
		ldi		mpr,	MovFwd						; Send command to Move Robot Forward 
		out		PORTB,	mpr							; That is all you should have in MAIN	
		
		rjmp	MAIN								; Create an infinite while loop to signify the 
													; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; You will probably need several functions, one to handle the 
; left whisker interrupt, one to handle the right whisker 
; interrupt, and maybe a wait function
;------------------------------------------------------------
HIT_RIGHT:
		push	mpr
		push	waitcnt
		in		mpr,	SREG
		push	mpr
		; Move backwards for 1000ms
		ldi		mpr,	MovBck
		out		PORTB,	mpr
		ldi		waitcnt,	WTime
		rcall	FUNC
		; Turn left for 2000ms
		ldi		mpr,	TurnL
		out		PORTB,	mpr
		ldi		waitcnt,	WTime * 2
		rcall	FUNC
		; Restore program state
		pop		mpr
		out		SREG,	mpr
		pop		waitcnt
		pop		mpr
		ret

HIT_LEFT:
		push	mpr
		push	waitcnt
		in		mpr,	SREG
		push	mpr
		; Move backwards for 1000ms
		ldi		mpr,	MovBck
		out		PORTB,	mpr
		ldi		waitcnt,	WTime
		rcall	FUNC
		; Turn right for 2000ms
		ldi		mpr,	TurnR
		out		PORTB,	mpr
		ldi		waitcnt,	WTime * 2
		rcall	FUNC
		; Restore program state
		pop		mpr
		out		SREG,	mpr
		pop		waitcnt
		pop		mpr
		ret

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:	; Begin a function with a label
		; Save variable by pushing them to the stack
		push	waitcnt
		push	ilcnt
		push	olcnt
		; Execute the function here
WAIT_LOOP:
		ldi		olcnt,	224
OLOOP:
		ldi		ilcnt,	237
ILOOP:
		dec		ilcnt
		brne	ILOOP
		dec		olcnt
		brne	OLOOP
		dec		waitcnt
		brne	WAIT_LOOP
		; Restore variable by popping them from the stack in reverse order
		pop		olcnt
		pop		ilcnt
		pop		waitcnt
		ret		; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program

