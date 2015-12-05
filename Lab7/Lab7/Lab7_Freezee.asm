;***********************************************************
;* Lab 7 Transmit.asm
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
.def previousBotID = r22
.def previousFrzID = r23
.def currentComm = r24  
.equ irTransmit = 3   

.equ whiskerRight = 0    
.equ whiskerLeft = 1    
.equ engineEnableRight = 4 
.equ engineEnableLeft = 7   
.equ engineDirectionRight = 5    
.equ engineDirectionLeft = 6   

.equ Forward = (0<<engineEnableLeft)|(0<<engineEnableRight)|(1<<engineDirectionLeft)|(1<<engineDirectionRight) 
.equ Reverse = (0<<engineEnableLeft)|(0<<engineEnableRight)|(0<<engineDirectionLeft)|(0<<engineDirectionRight) 
.equ forwardCommand = 0b10110000 
.equ reverseCommand = 0b10000000 
.equ rightCommand = 0b10100000  
.equ leftCommand = 0b10010000  
.equ stopCommand = 0b11001000  
.equ freezeCommand = 0b11111000  
.equ freezeSignal = 0b01010101  

.equ BotID = $66  ; Bot ID
.equ FrzID = $67

;***********************************************************
;* Start of Code Segment
;***********************************************************
.cseg       ; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org $0000     ; Beginning of IVs
		rjmp  INIT   ; Reset interrupt

.org $0046     ; End of Interrupt Vectors


;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT: 
		ldi  mpr,	low(RAMEND) 
		out  SPL,	mpr   
		ldi  mpr,	high(RAMEND) 
		out  SPH,	mpr   
		; Initialize Port D for input BUTTONS
		ldi  mpr,	(1<<irTransmit)		; Set Port D Directional Register
		out  DDRD,	mpr					; 
		ldi  mpr,	$F7
		out  PORTD,	mpr					; with Tri-State
		; Initialize USART1
		ldi mpr,	(1<<U2X1) ; Set double data rate
		sts UCSR1A,	mpr
		; Enable transmitter and transmit interrupt
		; (1<<TXEN0)  ==>  Enables the USART1 Transmitter
		; (1<<TXCIE0) ==>  Enables interrupt on the TXC flag
		ldi mpr,	(1<<TXEN1)
		sts UCSR1B, mpr
		; Set frame format: 8 data, 2 stop bits, asynchronous
		; (0<<UMSEL1)  ==>  Use Asyncronous Operation
		; (1<<USBS1)   ==>  Use 2 stop bits
		; (1<<UCSZ11) | (1<<UCSZ10)  ==>  Sets the number of data bits in a frame to 8
		ldi mpr, (0<<UMSEL1 | 1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)  
		sts UCSR1C, mpr ; UCSR0C in extended I/O space
		; Set baudrate at 2400
		ldi mpr, high(832) ; Load high byte of 0x0340
		sts UBRR1H, mpr ; UBRR0H in extended I/O space
		ldi mpr, low(832) ; Load low byte of 0x0340
		sts UBRR1L, mpr

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
		; Button 0 is freezeCommand
		;in		mpr,	PIND
		;andi	mpr,	1<<0
		;cpi		mpr,	1<<0
		;brne	button0Pressed
		; Button 4 is forwardCommand
		in		mpr,	PIND
		andi	mpr,	1<<4
		cpi		mpr,	1<<4
		brne	button4Pressed
		; Button 5 is reverseCommand
		in		mpr,	PIND
		andi	mpr,	1<<5
		cpi		mpr,	1<<5
		brne	button5Pressed
		; Button 6 is rightCommand
		in		mpr,	PIND
		andi	mpr,	1<<6
		cpi		mpr,	1<<6
		brne	button6Pressed
		; Button 7 is leftCommand
		in		mpr,	PIND
		andi	mpr,	1<<7
		cpi		mpr,	1<<7
		brne	button7Pressed
		rjmp MAIN

button0Pressed:
		ldi		transmitBuffer,		BotID
		rcall   transmitUSART
		ldi		transmitBuffer,		freezeCommand
		rcall   transmitUSART
		rjmp MAIN

button4Pressed:
		;ldi		transmitBuffer,		BotID
		ldi		transmitBuffer,		FrzID
		rcall   transmitUSART
		ldi		transmitBuffer,		forwardCommand
		rcall   transmitUSART
		ldi		transmitBuffer,		0
		rjmp MAIN

button5Pressed:
		;ldi		transmitBuffer,		BotID
		ldi		transmitBuffer,		FrzID
		rcall   transmitUSART
		ldi		transmitBuffer,		reverseCommand
		rcall   transmitUSART
		rjmp	MAIN

button6Pressed:
		;ldi		transmitBuffer,		BotID
		ldi		transmitBuffer,		FrzID
		rcall   transmitUSART
		ldi		transmitBuffer,		rightCommand
		rcall   transmitUSART
		rjmp	MAIN

button7Pressed:
		;ldi		transmitBuffer,		BotID
		ldi		transmitBuffer,		FrzID
		rcall   transmitUSART
		ldi		transmitBuffer,		leftCommand
		rcall   transmitUSART
		rjmp	MAIN

;***********************************************************
;* Functions and Subroutines
;***********************************************************
USART_Receive:
		lds		receiveBuffer,		UDR1				; Move data to receive buffer
		;Recognize BotID from Remote
		cpi		receiveBuffer,		FrzID
		breq	receivedBotID							; branch if we recieved Bot ID
		cpi		previousBotID,		$FF
		breq	getCommand
		ret

getCommand:
		mov		currentComm,		receiveBuffer
		ldi		previousBotID,		$00
		ret

receivedBotID:
		ldi		previousBotID,		$FF 
		ret
;***********************************************************
; Func: USART Transmit Routine
;===========================================================
transmitUSART:
		lds		mpr,				UCSR1A
		sbrs	mpr,				UDRE1					; Loop until transmitter is available
		rjmp	transmitUSART
		sts		UDR1,				transmitBuffer			; Move data from transmit data buffer
		ret