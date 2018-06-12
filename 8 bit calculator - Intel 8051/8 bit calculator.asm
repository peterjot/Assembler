; PIOTR JASINA
; 8 bit calculator with serial communication
; Intel 8051 mikrocontroller

NUM_FIRST DATA 031h
NUM_SEC DATA 032h
NUM_RES DATA 033h



ORG 0000h
_RESET:
	LJMP _INIT
	ORG 0100h
	
_INIT:

	; SM0 = 0 SM1 = 1  - set serial port to mode 1
	; serial port config
	MOV SCON, #01010000b

	ANL PCON, #01111111b ; set SMOD = 0 
	MOV TMOD, #00100000b ; set timer to mode 2
	CLR TR1
	CLR TF1

	MOV NUM_FIRST, #0d
	MOV NUM_SEC, #0d
	MOV NUM_RES, #0d
	MOV R0, #0d
	MOV R1, #0d
	MOV R2, #0d
	MOV R4, #0d
	MOV R5, #0d
	MOV R6, #0d

	; configure timer
	MOV TL1, #0FDh
	MOV TH1, #0FDh
	SETB TR1

_LOOP:
	; ascii code to digit
	; digit = ascii code - 48
	; digit to asci
	; ascii code = digit + 48
	; ----------------------------


	_IS_LOOP_0:
	CJNE R0,#0d, _IS_LOOP_1
	;  "$" symbol is address of the current instruction
	JNB RI,$ ; wait for something to read
	MOV A,SBUF ; read from buffer
	LCALL _100_NUMBER ; calculate hundreds
	INC R0
	CLR RI

	_IS_LOOP_1:
	CJNE R0,#1d, _IS_LOOP_2
	JNB RI,$
	MOV A,SBUF
	LCALL _10_NUMBER ; calc dozens
	INC R0
	CLR RI
	
	_IS_LOOP_2:
	CJNE R0,#2d, _IS_LOOP_3
	JNB RI,$
	MOV A,SBUF
	LCALL _1_NUMBER ; calculate unity
	MOV NUM_FIRST, R1 ; gets calculated number to var
	MOV R1, #0d;
	INC R0
	CLR RI
	
	_IS_LOOP_3: ; read operator (+, -, *, /)
	CJNE R0,#3d, _IS_LOOP_4
	JNB RI,$
	MOV A,SBUF
	MOV R2,A
	INC R0
	CLR RI
	
	_IS_LOOP_4:
	CJNE R0,#4d, _IS_LOOP_5
	JNB RI,$ 
	MOV A,SBUF
	LCALL _100_NUMBER
	INC R0
	CLR RI
	
	_IS_LOOP_5:
	CJNE R0,#5d, _IS_LOOP_6
	JNB RI,$
	MOV A,SBUF
	LCALL _10_NUMBER
	INC R0
	CLR RI
	
	_IS_LOOP_6:
	CJNE R0,#6d, _IS_LOOP_7
	JNB RI,$
	MOV A,SBUF
	LCALL _1_NUMBER
	MOV NUM_SEC, R1 ; save number converted from characters
	MOV R1, #0d
	INC R0
	CLR RI
	
	_IS_LOOP_7: ; read "=" operator
	CJNE R0,#7d, _IS_LOOP_8
	JNB RI,$
	MOV A,SBUF

	_ADD_CHAR:
	CJNE R2,#'+', _SUB_CHAR
	LCALL _ADDITION
	LJMP _DEFAULT

	_SUB_CHAR:
    CJNE R2,#'-', _MUL_CHAR
	LCALL _SUBTRACTION
	LJMP _DEFAULT

	_MUL_CHAR:
    CJNE R2,#'*', _DIV_CHAR
	LCALL _MULTIPLICATION
	LJMP _DEFAULT

	_DIV_CHAR:
	CJNE R2,#'/', _DEFAULT
	LCALL __DIVISION
	
	_DEFAULT:

	LCALL _INT_TO_STRING_TO_R4_R5_R6 ; converts number to ascii charaters and saves in R4, R5 i R6
	INC R0
	CLR RI
	
	; send the result via serial transmission
	_IS_LOOP_8:
	CJNE R0,#8d, _IS_LOOP_9
	CLR TI
	MOV SBUF,R4
	JNB TI, $
	INC R0

	_IS_LOOP_9:
	CJNE R0,#9d, _IS_LOOP_10
	CLR TI
	MOV SBUF,R5
	JNB TI, $
	INC R0

	_IS_LOOP_10:

	CLR TI
	MOV SBUF,R6
	JNB TI, $
	CLR TI
	MOV SBUF,#0Ah
	JNB TI, $


	; reset all
	MOV NUM_FIRST, #0d
	MOV NUM_SEC, #0d
	MOV NUM_RES, #0d
	MOV R0, #0d
	MOV R1, #0d
	MOV R2, #0d
	MOV R4, #0d
	MOV R5, #0d
	MOV R6, #0d
	CLR TR1
	CLR TF1
	MOV TMOD, #00100000b ;
	MOV TL1, #0FDh
	MOV TH1, #0FDh
	SETB TR1

	LJMP _LOOP

	_1_NUMBER:
		SUBB A,#48d
		ADD A,R1
		MOV R1, A
	RET

	_10_NUMBER:
		SUBB A,#48d
		MOV B,#10d
		MUL AB
		ADD A, R1
		MOV R1, A
	RET

	_100_NUMBER:
		SUBB A,#48d
		MOV B,#100d
		MUL AB
		MOV R1, A
	RET

	_INT_TO_STRING_TO_R4_R5_R6:
		;R4 = ( NUM_RES / 100) + 48  
		;R5 = ( NUM_RES % 100)/10 + 48
		;R6 = ( NUM_RES % 10) + 48

		PUSH ACC
		MOV A, NUM_RES
		MOV B, #100d
		DIV AB
		ADD A, #48d
		MOV R4, A

		; NUM_RES % 100
		MOV A,B
		MOV B,#10d
		DIV AB
		ADD A, #48d
		MOV R5, A
		MOV A,B
		ADD A,#48d
		MOV R6, A

		POP ACC
	RET

	_ADDITION:
		PUSH PSW
		PUSH ACC
		MOV A, NUM_FIRST
		ADD A, NUM_SEC
		MOV NUM_RES, A
		POP ACC
		POP PSW
	RET
	
	_SUBTRACTION:
		PUSH PSW
		PUSH ACC
		MOV A, NUM_FIRST
		SUBB A, NUM_SEC
		MOV NUM_RES, A
		POP ACC
		POP PSW
	RET
	
	_MULTIPLICATION:
		PUSH PSW
		PUSH ACC
		MOV A, NUM_FIRST
		MOV B, NUM_SEC
		MUL AB
		MOV NUM_RES, A
		POP ACC
		POP PSW
	RET
	
	__DIVISION:
		PUSH PSW
		PUSH ACC
		MOV A, NUM_FIRST
		MOV B, NUM_SEC
		DIV AB
		MOV NUM_RES, A
		POP ACC
		POP PSW
	RET


END