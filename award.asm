.286
.MODEL	TINY
.STACK	100h

COD	SEGMENT
ASSUME	CS:COD,SS:STACK,DS:COD

AWARDP:
	XOR	AX,AX
	DEC	AX
	CALL	RANDOMIZE
	MOV	AX,COD
	MOV	DS,AX
	MOV	ES,AX
	LEA	SI,CREDITS
	CALL	WW
	CALL	DETECT_BIOS;(AX - BIOS ;AX=0 AWARD)
	CALL	PRINT_BIOS
	OR	AX,AX
	JNZ	EXIT
	CALL	AWARD_PASS
EXIT:
	MOV	AX,4C00H
	INT	21H
DETECT_BIOS	PROC
	XOR	AX,AX
	CALL	DETECT_AWARD;OUT C=0 WAS FOUND
	JNC	DETECT_BIOSE
	INC	AX
DETECT_BIOSE:
	RET
ENDP
DETECT_AWARD	PROC
	PUSHA
	PUSH	DS
	LEA	DI,AWARD_PGP
	MOV	AX,0F000H
	MOV	DS,AX
	XOR	SI,SI
	MOV	DX,14
	MOV	CX,65535
	XOR	BX,BX
	CALL	FIND_STRING
	POP	DS
	POPA
	RET
ENDP
PRINT_BIOS	PROC
	PUSH	SI
	LEA	SI,AWARD_BIOS
	OR	AX,AX
	JZ	PRINT_BIOS_1
	LEA	SI,UNKNOWN_BIOS
PRINT_BIOS_1:
	CALL	WW
	LEA	SI,BIO_DET
	CALL	WW
	POP	SI
	RET
ENDP
AWARD_PASS	PROC
	CALL	AWARD_DETECT_SECUR_OPT;(AL,AH = 0 - NONE,1 - SETUP,2 - SYSTEM)
	;AL FOR SUPERVISOR , AH FOR USER
	OR	AL,AL
	JZ	AWARD_NO_SUPERV
	CALL	AWARD_DETECT_SUPERV
AWARD_NO_SUPERV:
	OR	AH,AH
	JZ	AWARD_NO_USER
	CALL	AWARD_DETECT_USER
AWARD_NO_USER:
	CALL	PRINT_AWARD_SUPERV
	CALL	PRINT_AWARD_USER
	RET
ENDP
AWARD_DETECT_SECUR_OPT	PROC
	PUSH	DX
	MOV	AX,5EH
	CALL	READ_PORT
	AND	AL,3
	MOV	DL,AL
	MOV	AX,11H
	CALL	READ_PORT
	AND	AL,3
	OR	AL,AL
	JZ	AWARD_DETECT_S_O_1
	DEC	AL
AWARD_DETECT_S_O_1:
	MOV	AH,DL
	MOV	WORD PTR DS:[SECURITY],AX
	POP	DX
	RET
ENDP
AWARD_DETECT_SUPERV	PROC
	PUSH	AX
	CALL	GET_AWARD_SPASSWORD;(OUT AX-PASSW)
	LEA	DI,SUPERBUF
	CALL	DECODE_AWARD
	POP	AX
	RET
ENDP
GET_AWARD_SPASSWORD	PROC
	PUSH	DX
	XOR	AX,AX
	MOV	AL,1DH
	CALL	READ_PORT
	MOV	DL,AL
	MOV	AL,1CH
	CALL	READ_PORT
	MOV	AH,DL
	POP	DX
	RET
ENDP
AWARD_DETECT_USER	PROC
	PUSH	AX
	CALL	GET_AWARD_UPASSWORD;(OUT AX-PASSW)
	LEA	DI,USERBUF
	CALL	DECODE_AWARD
	POP	AX
	RET
ENDP
GET_AWARD_UPASSWORD	 PROC
	PUSH	DX
	XOR	AX,AX
	MOV	AL,5DH
	CALL	READ_PORT
	MOV	DL,AL
	MOV	AL,5CH
	CALL	READ_PORT
	MOV	AH,DL
	POP	DX
	RET
ENDP
READ_PORT	PROC
	OUT	70H,AL
	JMP	$+2
	IN	AL,71H
	RET
ENDP
DECODE_AWARD	PROC;(IN AX- PASSW)
	PUSHA
	PUSH	DS
	PUSH	ES
	POP	DS
	MOV	SI,DI
	MOV	DX,AX
	MOV	BP,AX
DECODE_AWARD_REST:
	MOV	CX,2
	MOV	BP,DX
	MOV	DI,SI
DECODE_AWARD_1:
	MOV	BX,BP
	CMP	BX,7FH
	JA	DECODE_AWARD_2
	CMP	BX,1FH
	JA	DECODE_AWARD_3
	JMP	SHORT	DECODE_AWARD_REST
DECODE_AWARD_2:
	CALL	DECODE_AWARD_F
	ADD	AL,1001B
	SHL	AX,2
	AND	BX,11B
	OR	AX,BX
	STOSB
	SUB	BP,AX
	SHR	BP,CL
	JMP	SHORT	DECODE_AWARD_1
DECODE_AWARD_3:
	MOV	AX,BP
	STOSB
	MOV	AX,0A0DH
	STOSW
	SUB	DI,2
	PUSH	DI
	SUB	DI,SI
	SHR	DI,1
	MOV	CX,DI
	POP	DI
	DEC	DI
DECODE_AWARD_4:
	LODSB
	XCHG	DS:[DI],AL
	MOV	DS:[SI-1],AL
	DEC	DI
	LOOP	DECODE_AWARD_4
	POP	DS
	POPA
	RET
ENDP
DECODE_AWARD_F	PROC
	PUSH	BX
	MOV	BX,10110B
	CALL	RND
	POP	BX
	RET
ENDP
PRINT_AWARD_SUPERV	PROC
	MOV	AL,BYTE PTR DS:[SECURITY]
	LEA	DI,SUPER_
	CALL	PRINT_SECURITY_OPTION
	JNC	PRINT_AWARD_NO_PASS
	MOV	SI,DI
	CALL	WW
	LEA	SI,PASS_IS+1
	ADD	BYTE PTR DS:[SI],20H
	CALL	WW
	LEA	SI,SUPERBUF
	CALL	WW
PRINT_AWARD_NO_PASS:
	RET
ENDP
PRINT_AWARD_USER	PROC
	MOV	AL,BYTE PTR DS:[SECURITY+1]
	LEA	DI,USER_
	CALL	PRINT_SECURITY_OPTION
	JNC	PRINT_AWARD_NO_PASS
	MOV	SI,DI
	CALL	WW
	LEA	SI,PASS_IS+1
	ADD	BYTE PTR DS:[SI],20H
	CALL	WW
	LEA	SI,USERBUF
	CALL	WW
	RET
ENDP
PRINT_SECURITY_OPTION	PROC
	;IN DI - SUPER OR USER
	OR	AL,AL
	JZ	PRINT_SECUR_1
	MOV	SI,DI
	CALL	WW
	LEA	SI,SECUR_OPTION+1
	ADD	BYTE PTR DS:[SI],20H
	CALL	WW
	LEA	SI,ON_SETUP
	DEC	AL
	JZ	PRINT_SECUR_2
	LEA	SI,ON_SYSTEM
PRINT_SECUR_2:
	CALL	WW
	STC
	RET
PRINT_SECUR_1:
	LEA	SI,NO_
	CALL	WW
	MOV	SI,DI
	INC	SI
	ADD	BYTE PTR DS:[SI],20H
	CALL	WW
	LEA	SI,PASS_
	JMP	WW
ENDP


INCLUDE WW.LIB
INCLUDE RND.LIB
INCLUDE FINDSTR.LIB
INCLUDE COMPSTR.LIB

SECURITY	DW	0
SUPERBUF	DB	11	DUP	(0)
USERBUF 	DB	11	DUP	(0)
CREDITS 	DB	'Password detector for Award BIOS Version 1.0 (C)1996 Pavel A. Skrylev',0dh,0ah,0
AWARD_BIOS	DB	0FEH,'Award',0
UNKNOWN_BIOS	DB	0FEH,'Unknown',0
BIO_DET 	DB	' BIOS detected',0dh,0ah,0
SUPER_		DB	0FEh,'Supervisor ',0
USER_		DB	0FEh,'User ',0
NO_		DB	0FEH,'No ',0
PASS_		DB	'password installed',0dh,0ah,0
PASS_IS 	DB	0FEH,'Password is ',0
SECUR_OPTION	DB	0FEH,'Security option:',0
ON_SYSTEM	DB	'System',0dh,0ah,0
ON_SETUP	DB	'Setup',0dh,0ah,0
ENTR		DB	0DH,0AH,0
AWARD_PGP	DB	'AWARD SOFTWARE'
ENDS
END     AWARDP