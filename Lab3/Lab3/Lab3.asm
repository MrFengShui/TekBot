;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 3 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register required for LCD Driver
.def	ReadOneTxt = r23		; Line 1 used to read data from Program Memory
.def	lineone = r4			; Line 1 used for Name demo
.def	ReadTwoTxt = r24		; Line 2 used to read data from Program Memory
.def	linetwo = r5			; Line 2 used for Text demo

.equ	LineOneTxt = $0130		; Address of ASCII Line 1 text
.equ	LineTwoTxt = $0131		; Address of ASCII Line 2 text
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt
.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr 

		; Init the 2 stack pointer registers
		rcall	LCDInit			; Initialize LCD Display
								; An RCALL statement

		; Write initial "LUAN SONGJIAN" string to LCD line 1
		ldi		ZL, low(TXT1 << 1); Init variable registers
		ldi		ZH, high(TXT1 << 1)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		ldi		ReadOneTxt, LCDMaxCnt

INIT_LINE1:						; Initialize line 1
		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadTwoTxt		; Decrement Read Line 1 Text
		brne	INIT_LINE1		; Continue untill all data is read
		rcall	LCDWrLn1		; WRITE LINE 1 DATA

		sei
		; NOTE that there is no RET or RJMP from INIT, this is
		; because the next instruction executed is the first for
		; the main program

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:	com		lineone				; Complement input
		com		linetwo
		; Display the strings on the LCD Display
		mov		mpr, linetwo		; Copy value int mpr
		ldi		ZL, low(TXT2 << 1)	; Load Z pointer with address of text message 1
		ldi		ZH, high(TXT2 << 1) ;
		rcall	FUNC				; An RCALL statement
		rjmp	MAIN				; jump back to main and create an infinite
									; while loop.  Generally, every main program is an
									; infinite while loop, never let the main program
									; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:
		push	mpr				; Save the mpr register
		push	ReadOneTxt		; Save the ReadOneTxt
		rcall	LCDClrLn2		; CLEAR LINE 2 OF LCD
		
		ldi		ReadOneTxt, LCDMaxCnt	; LOAD THE LCD MAX LINE COUNT (16)
										; LOAD THE Y POINTER WITH THE DATA
								
		ldi		YL, low(LCDLn2Addr)		; ADDRESS FOR LINE 2 DATA
		ldi		YH, high(LCDLn2Addr)
WriteText_lp:							; Loop that reads the data
		lpm		mpr, Z+					; Read program data
		st		Y+, mpr					; Store data to memory
		dec		ReadOneTxt				; Decrement counter
		brne	WriteText_lp			; Loop untill all data is read
		rcall	LCDWrLn2				; WRITE DATA TO LINE 2
		pop		ReadOneTxt				; Restore the ReadCounter
		pop		mpr						; Restore the mpr register
		ret								; Return from function


;***********************************************************
;*	Stored Program Data
;***********************************************************
TXT1:
.DB " LUAN  SONGJIAN "
TXT2:
.DB "   Hello TA!    "

;----------------------------------------------------------
; An example of storing a string, note the preceeding and
; appending labels, these help to access the data
;----------------------------------------------------------
STRING_BEG:
.DB		"My Test String"		; Storing the string in Program Memory
STRING_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver


