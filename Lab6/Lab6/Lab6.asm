;***********************************************************
;*
;*	Lab6.asm
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: LUAN SONGJIAN
;*	   Date: 2015-11-19
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	speed = r17
.def	step = r18
.def	count = r19

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit
.equ	span = 17

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rcall	INIT
		reti			; reset interrupt

.org	$0002					; place instructions in interrupt vectors here, if needed
		rcall	INCREMENT
		reti

.org	$0004
		rcall	DECREMENT
		reti

.org	$001E
		rjmp	TIM0_COMPA 

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi		mpr,	low(RAMEND)
		out		SPL,	mpr
		ldi		mpr,	high(RAMEND)
		out		SPH,	mpr
		; Configure I/O ports
		ldi		mpr,	$00
		out		PORTB,	mpr
		ldi		mpr,	$FF
		out		DDRB,	mpr
		ldi		mpr,	$FF
		out		PORTD,	mpr
		ldi		mpr,	$00
		out		DDRD,	mpr
		; Configure External Interrupts, if needed
		ldi		mpr,	(0 << ISC00 | 0 << ISC01 | 0 << ISC10 | 0 << ISC11)
		sts		EICRA,	mpr
		ldi		mpr,	0
		out		EICRB,	mpr
		ldi		mpr,	(1 << INT0 | 1 << INT1)
		out		EIMSK,	mpr
		; Configure 8-bit Timer/Counters, no prescaling
		; Set initial speed, display on Port B
		sbi		DDRB,	PB4
		ldi		mpr,	0b01110111
		out		TCCR0,	mpr
		ldi		mpr,	0b00000010
		out		TIMSK,	mpr

		ldi		count,	span
		clr		step
		clr		speed
		; Enable global interrupts (if any are used)
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN			; return to top of MAIN

INCREMENT:
		cpi		speed, 15
		breq	RETURN
		inc		speed
		add		step,	count
		rcall	WAIT_5MSEC
		out		PORTB,	speed
		ret		

DECREMENT:
		cpi		speed, 0
		breq	RETURN
		dec		speed
		sub		step,	count
		rcall	WAIT_5MSEC
		out		PORTB,	speed
		ret	

RETURN:
		ret

TIM0_COMPA:
		out		OCR0,	step
		reti 
;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
WAIT_5MSEC:
		ldi		mpr,	50
		out		TCNT0,	mpr


