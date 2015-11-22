;***********************************************************
;*
;*	Enter Lab4.asm
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: LUANSONGJIAN
;*	   Date: 2015-10-22
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; An operand
.def	B = r4					; Another operand

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter

.equ	addrA = $0100			; Beginning Address of Operand A data
.equ	addrB = $0102			; Beginning Address of Operand B data
.equ	LAddrP = $0104			; Beginning Address of Product Result
.equ	HAddrP = $0109			; Ending Address of Product Result
.equ	LAddrS = $0104
.equ	MultResult = $010C

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		; Initialize Stack Pointer
		; Init the 2 stack pointer registers
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr
		;
		ldi		ZL,	low(BEG_A << 1)
		ldi		ZH,	high(BEG_A << 1)
		ldi		XL,	low(addrA)
		ldi		XH,	high(addrA)

		clr		zero			; Set the zero register to zero, maintain
								; these semantics, meaning, don't load anything
								; to it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
		; Setup the add funtion
		; Add the two 16-bit numbers
		rcall	ADD16					; rcall	ADD16
										; Call the add function

		; Multiply two 24-bit numbers	
		rcall	MUL24					; rcall	MUL24
										; Call the multiply function

DONE:	rjmp	DONE			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
ADD16:
		; Save variable by pushing them to the stack
		push	A
		push	B
		push	zero
		push	XH
		push	XL
		push	YH
		push	YL
		push	ZH
		push	ZL

		clr		zero
		; Set X to beginning address of A
		ldi		XL,	low(addrA)
		ldi		XH,	high(addrA)
		; Set Y to beginning address of B 
		ldi		YL, low(addrB)
		ldi		YH, high(addrB)
		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrS)
		ldi		ZH, high(LAddrS)
		; Execute the function here
		ld		A,	X+
		ld		B,	Y+
		add		A,	B
		st		Z+,	A
		ld		A,	X
		ld		B,	Y
		adc		A,	B
		st		Z+,	A
		clr		A
		adc		A,	zero
		st		Z,	A
		; Restore variable by popping them from the stack in reverse order\
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;		result.
;-----------------------------------------------------------
MUL24:
		; Save variable by pushing them to the stack
		push 	A
		push	B
		push	rhi
		push	rlo
		push	zero
		push	XH
		push	XL
		push	YH
		push	YL				
		push	ZH
		push	ZL
		push	oloop
		push	iloop				

		clr		zero
		; Set Y to beginning address of B 
		ldi		YL, low(LAddrP)
		ldi		YH, high(LAddrP)
		; Set Z to begginning address of resulting Product
		ldi		ZL, low(MultResult)
		ldi		ZH, high(MultResult)
		; Begin outer for loop
		ldi		oloop, 3
MUL24_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(LAddrP)	; Load low byte
		ldi		XH, high(LAddrP)	; Load high byte
		; Begin inner for loop
		ldi		iloop, 3		; Load counter
MUL24_ILOOP:
		; Execute the function here
		ld		A,	X+
		ld		B,	Y
		mul		A,	B
		ld		A,	Z+
		ld		B,	Z+
		add		rlo, A
		adc		rhi, B
		ld		A,	Z
		adc		A,	zero
		st		Z,	A
		st		-Z, rhi
		st		-Z, rlo
		adiw	ZH:ZL, 1		
		dec		iloop
		brne	MUL24_ILOOP
		; End inner for loop
		sbiw	ZH:ZL, 2
		adiw	YH:YL, 1
		dec		oloop
		brne	MUL24_OLOOP

		; Restore variable by popping them from the stack in reverse order\
		pop		iloop
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;			A - Operand A is gathered from address $0101:$0100
;			B - Operand B is gathered from address $0103:$0102
;			Res - Result is stored in address 
;					$0107:$0106:$0105:$0104
;		You will need to make sure that Res is cleared before
;		calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A,	X+			; Get byte of A operand
		ld		B,	Y			; Get byte of B operand
		mul		A,	B			; Multiply A and B
		ld		A,	Z+			; Get a result byte from memory
		ld		B,	Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A,	Z			; Get a third byte from the result
		adc		A,	zero		; Add carry to A
		st		Z,	A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order\

		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here
BEG_A: 
	.DB	19, 82
END_A:
BEG_B: 
	.DB	37, 64
END_B:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program
