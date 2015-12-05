;***********************************************************
;* Lab 7 Receive.asm
;***********************************************************
;*
;*  Author: Rylee Glassman
;*    Date: 11/29/2015
;*
;***********************************************************

.include "m128def.inc"   ; Include definition file

;***********************************************************
;* Internal Register Definitions and Constants
;***********************************************************
.def mpr = r16    
.def transmitBuffer = r17
.def receiveBuffer = r18  ; Usart receive Buffer
.def waitCnt = r19   
.def ilcnt = r20    
.def olcnt = r21  
.def previousBotID = r22
.def previousFrzID = r23
.def currentComm = r24  
.def lpcnt = r25 

.equ whiskerRight = 0    
.equ whiskerLeft = 1    
.equ engineEnableRight = 4 
.equ engineEnableLeft = 7   
.equ engineDirectionRight = 5    
.equ engineDirectionLeft = 6        
;.equ irReceive = 2   
;.equ irTransmit = 3  

.equ BotID = $66
.equ FrzID = $67

.equ forwardCommand = 0b10110000 
.equ reverseCommand = 0b10000000 
.equ rightCommand = 0b10100000  
.equ leftCommand = 0b10010000  
.equ stopCommand = 0b11001000  
.equ freezeCommand = 0b11111000  
.equ freezeSignal = 0b01010101 

;/////////////////////////////////////////////////////////////
;Macros to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ Forward = (0<<engineEnableLeft)|(0<<engineEnableRight)|(1<<engineDirectionLeft)|(1<<engineDirectionRight) 
.equ Reverse = (0<<engineEnableLeft)|(0<<engineEnableRight)|(0<<engineDirectionLeft)|(0<<engineDirectionRight) 
.equ TurnR = (0<<engineEnableLeft)|(1<<engineEnableRight)|(1<<engineDirectionLeft)|(0<<engineDirectionRight) 
.equ TurnL = (1<<engineEnableLeft)|(0<<engineEnableRight)|(0<<engineDirectionLeft)|(1<<engineDirectionRight) 
.equ SpinL = (0<<engineEnableLeft)|(0<<engineEnableRight)|(0<<engineDirectionLeft)|(1<<engineDirectionRight) 
.equ SpinR = (0<<engineEnableLeft)|(0<<engineEnableRight)|(1<<engineDirectionLeft)|(0<<engineDirectionRight) 
.equ Stop = (1<<engineEnableLeft)|(1<<engineEnableRight)|(0<<engineDirectionLeft)|(0<<engineDirectionRight)

.equ waitTime = 100   ; Set wait time to 1 second

;***********************************************************
;* Start of Code Segment
;***********************************************************
.cseg       ; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org $0000     ; Beginning of IVs
		rjmp  INIT   ; Reset interrupt

; Set up the interrupt vectors for the interrupts

.org $0002     ;IRQ0 => pin0, PORTD
		rcall HitRight   
 reti     
       
.org $0004     ;IRQ1 => pin1, PORTD
		rcall HitLeft   
		reti    

.org $003C     ; USART1, Rx complete interrupt
		rcall USART_Receive  
		reti    

.org $0046     ; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT: 
		; Initialize Stack Pointer
		ldi mpr,	low(RAMEND) 
		out SPL,	mpr   
		ldi mpr,	high(RAMEND) 
		out SPH,	mpr  
		;ldi  currentComm, $00	
		clr currentComm												; Set current command to 0
		; Initialize USART1
		ldi mpr,	(1<<U2X1) ; Set double data rate
		sts UCSR1A,	mpr
		; Enable both receiver and transmitter, and receive interrupt
		ldi	mpr,	(1<<RXEN1 | 1<<RXCIE1)
		sts	UCSR1B,	mpr ;
		; Set frame format: 8 data, 2 stop bits, asynchronous
		ldi	mpr,	(0<<UMSEL1 | 1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)  
		sts	UCSR1C,	mpr												; UCSR0C in extended I/O space
		; Set baudrate at 2400
		ldi	mpr,	high(832)										; Load high byte of 0x0340
		sts	UBRR1H,	mpr												; UBRR0H in extended I/O space
		ldi	mpr,	low(832)										; Load low byte of 0x0340
		sts	UBRR1L,	mpr
		; Initialize Port B for output LEDS
		ldi	mpr,	$FF
		out	DDRB,	mpr												; for output  
		; Initialize Port D for input BUTTONS
		ldi	mpr,	(1<<whiskerRight)|(1<<whiskerLeft)				; Initialize Port D for input
		out	PORTD,	mpr												; with Tri-State
		ldi	mpr,	(0<<whiskerRight)|(0<<whiskerLeft)				; Set Port D Directional Register
		out	DDRD,	mpr												; for input
		; Initialize external interrupts
		ldi	mpr,	(0<<ISC00)|(0<<ISC01)|(0<<ISC10)|(0<<ISC11)		; Set the Interrupt Sense Control to low level 
		sts	EICRA,	mpr   ; for EICRA
		; Set the External Interrupt Mask
		ldi	mpr,	(1<<INT0)|(1<<INT1)								; Set EIMSK  to high
		out	EIMSK,	mpr     ;
		; Turn on interrupts
		sei															; Enable external interrupts

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
		mov  mpr,	currentComm
		lsl  mpr
		out  PORTB,	mpr
		rjmp MAIN

;***********************************************************
; Func: USART receive
;===========================================================
USART_Receive:
		lds		receiveBuffer,		UDR1				; Move data to receive buffer
		;Recognize BotID from Remote
		cpi		receiveBuffer,		BotID
		breq	receivedBotID							; branch if we recieved Bot ID
		cpi		previousBotID,		$FF
		breq	getCommand
		ret

getCommand:
		mov		currentComm,		receiveBuffer
		cpi		currentComm,		freezeCommand
		breq	sendSignal
		ldi		previousBotID,		$00
		ret

receivedBotID:
		ldi		previousBotID,		$FF 
		ret

sendSignal:
		ldi		transmitBuffer,		BotID
		rcall   transmitUSART
		ldi		transmitBuffer,		freezeSignal
		rcall   transmitUSART
		rcall	Freezed
		ldi		previousBotID,		$00

transmitUSART:
		lds		mpr,				UCSR1A
		sbrs	mpr,				UDRE1				; Loop until transmitter is available
		rjmp	transmitUSART
		sts		UDR1,				transmitBuffer		; Move data from transmit data buffer
		ret

;****************************************************************
;*
;*
;*
;*
;****************************************************************
Freezed:
		push	mpr
		in		mpr,	SREG
		push	mpr
		;
		ldi		mpr,	Stop
		out		PORTB,	mpr
		ldi		lpcnt,	5

FrzLoop:
		rcall	Wait
		dec		lpcnt
		brne	FrzLoop
		dec		waitCnt
		brne	unFreezed

unFreezed:
		ldi		currentComm, 0b11110000
		out		PORTB,	currentComm

		pop		mpr
		out		SREG,	mpr
		pop		mpr
		ret

;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:
		push	mpr			; Save mpr register
		push	waitcnt		; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, Reverse	; Load Move Backwards command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, waitTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, waitTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again	
		ldi		mpr, Forward	; Load Move Forwards command
		out		PORTB, mpr	; Send command to port

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, Reverse	; Load Move Backwards command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, waitTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, waitTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again	
		ldi		mpr, Forward	; Load Move Forwards command
		out		PORTB, mpr	; Send command to port

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine