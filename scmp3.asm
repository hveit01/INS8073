; This listing was reverse engineered and commented from a dump of the 8073N ROM
; It may look like valid SC/MP-III assembler, but probably isn't. This is purely for
; reference - not for feeding into an assembler program.
; Analysed and commented by Holger Veit (20140315)

				; locations in on-chip RAM
FFC0			MULOV	=	X'ffc0					; DW high 16 bit from MPY
FFC2			INPMOD	=	X'ffc2					; DB input mode: X'00 interactive, <>0 in INPUT, 01: running
FFC3			CURRNT	= 	X'ffc3					; DW current line number executed
FFC5			RUNMOD	=	X'ffc5					; DB runmode 'R', X'00
FFC6			EXTRAM	=	X'ffc6					; DW start of variables (26 words)
FFC8			AESTK	=	X'ffc8					; DW start of arithmetic stack (13 words)
FFCA			SBRSTK	=	X'ffca					; DW start of GOSUB stack (10 words)
FFCC			DOSTK	=	X'ffcc					; DW start of DO stack (10 words)
FFCE			FORSTK	=	X'ffce					; DW start of FOR stack (28 words)

FFD0			BUFAD	=	X'ffd0					; DW
FFD2			STACK	=	X'ffd2					; DW top of stack
FFD4			TXTBGN	=	X'ffd4					; DW start of program area
FFD6			TXTUNF	=	X'ffd6					; DW
FFD8			TXTEND	=	X'ffd8					; DW end of program area
FFDA			DOPTR	=	X'ffda					; DW ptr to DO level?
FFDC			FORPTR	=	X'ffdc					; DW ptr to FOR level?
FFDE			SBRPTR	= 	X'ffde					; DW ptr to GOSUB level?

FFE0			INTVEC	=	X'ffe0					; DW current interrupt vector
FFE2			INTAVC	=	X'ffe2					; DW Interrupt A vector
FFE4			INTBVC	=	X'ffe4					; DW Interrupt B vector
FFE6			BRKFLG	=	X'ffe6					; DB if 0 check for BREAK from serial
FFE7			NOINT	=	X'ffe7					; DB flag to suppress INT after having set STAT

FFE8			ONE		= 	X'ffe8					; DW constant 1
FFEA			ZERO	= 	X'ffea					; DW constant 0
FFEC			DLYTIM	=	X'ffec					; DW delay value for serial I/O
FFEE			CONTP	=	X'ffee					; DW buffer pointer for CONT

FFF0			TMPF0	=	X'fff0					; DW temporary for moving program code for insertion
FFF2			TMPF2	=	X'fff2					; DW temp store for current program pointer

FFF4			RNDNUM	=	X'fff4					; DW rnd number

FFF6			TMPF6	=	X'fff6					; DB,DW temporary
FFF8			UNUSE1	=	X'fff8					; DW unused
FFFB			TMPFB	=	X'fffb					; DB,DW temporary
FFFC			TMPFC	=	X'fffc					; DB,DW temporary (overlaps TMPFB)
FFFE			TMPFE	=	X'fffe					; DW temporary, alias

				; more constants
1000			RAMBASE	=	X'1000					; start of RAM
8000			ROMBASE	=	X'8000					; potential start of a ROM
FD00			BAUDFLG	=	X'FD00					; address of baudrate selection bits

08				BS		=	X'08					; back space
0D				CR		=	X'0d					; carriage return
0A				LF		=	X'0a					; line feed
15				NAK		=	X'15					; CTRL-U, NAK
20				SPACE	=	' '						; space character
3E				GTR		=	'>'						; prompt for interactive mode
3F				QUEST	=	'?'						; prompt for input mode
5E				CARET	=	'^'						; prefix for CTRL output


				; interpreter starts here
				; assumptions "should be" refer to 1K RAM at X'1000-X'13ff)
							ORG	0
0000: 00 					NOP    					; lost byte because of PC preincrement
0001: 24 09 00				JMP 	COLD			; Jump to cold start
0004: 24 b9 08				JMP		INTA			; Jump to interrupt a handler
0007: 24 be 08				JMP 	INTB			; Jump to interrupt b handler
000a: 84 00 80 	COLD:		LD		EA, =ROMBASE	; bottom address of ROM
000d: 8d d4	   	COLD1:		ST		EA, TXTBGN		; set begin of text to ROM
000f: 84 00 10				LD		EA, =RAMBASE	; set P2 to point to base of RAM
0012: 46 					LD 		P2, EA			;
0013: 20 72 00	COLD2:		JSR 	TSTRAM			; test for RAM at loc P2
0016: 7c fb					BNZ 	COLD2			; not zero: no RAM, loop
0018: 32 					LD 		EA, P2			; found RAM, get address
0019: bc 01 00				SUB 	EA, =1			; subtract 1 to get the current position
001c: 7c f5					BNZ 	COLD2			; is not at xx00, search next
001e: 74 20					BRA 	COLD3			; found a page skip over call tbl, continue below

				; short CALL table
0020: 3b 06					DW		RELEXP-1			; call 0 (RELEXP)
0022: ee 06					DW		FACTOR-1  		; call 1 (FACTOR)
0024: 46 08					DW		SAVOP-1    		; call 2 (SAVOP)
0026: 79 06					DW		COMPAR-1		; call 3 (COMPAR)
0028: 39 08 				DW		APUSH-1			; call 4 (APUSH)
002a: 49 08					DW		APULL-1			; call 5 (APULL)
002c: 02 02					DW		ENDCMD-1		; call 6 (ENDCMD)
002e: 82 09					DW		PUTC-1			; call 7 (PUTC)
0030: 7d 09					DW		CRLF-1			; call 8 (CRLF)
0032: 4c 05					DW		GETCHR-1		; call 9 (GETCHR)
0034: 01 08					DW		NEGATE-1		; call 10 (NEGATE)
0036: 13 06					DW		CMPTOK-1		; call 11 (CMPTOK)
0038: 5d 05					DW		EXPECT-1		; call 12 (EXPECT c, offset)
003a: 94 05					DW		NUMBER-1		; call 13 (NUMBER, offset)
003c: 3e 05					DW		PRTLN-1			; call 14 (PRTLN)
003e: cc 08					DW		ERROR-1			; call 15 (ERROR)

				; continues here from cold start
0040: 8d c6		COLD3:		ST		EA, EXTRAM		; arrive here with xx00, store it (should be X'1000)
0042: b4 00 01				ADD		EA, =X'0100		; add 256
0045: 8d d2					ST		EA, STACK		; store as STACK address (should be X'1100)
0047: 45					LD		SP, EA    		; initialize stack pointer
0048: 20 72 00	COLD4:		JSR 	TSTRAM			; check RAM at current pos P2 (should be X'1000)
004b: 6c fb					BZ		COLD4			; advance until no longer RAM
													; P2 points to last RAM+2
004d: c6 fe   				LD		A, @fe, P2		; subtract 2 from P2
004f: 32 					LD		EA, P2    		; get last RAM address
0050: 8d d8    				ST		EA, TXTEND		; store at end of text (should be X'13ff)
0052: 85 d4					LD		EA, TXTBGN		; load begin of ROM text (X'8000)
0054: 46 					LD		P2, EA    		; put into P2
0055: 20 72 00				JSR 	TSTRAM			; is there RAM?
0058: 6c 03					BZ		COLD5			; yes, skip
005a: 24 d9 01 				JMP		RUN				; no, this could be a ROM program, run it
005d: 85 d2		COLD5:		LD		EA, STACK		; get stack top
005f: bd d4    				SUB		EA, TXTBGN		; subtract begin of program
0061: 06 					LD		A, S   			; get carry bit
0062: 64 04					BP		COLD6			; not set, skip
0064: 85 d2					LD		EA, STACK		; get stack top
0066: 8d d4					ST 		EA, TXTBGN		; make it new TXTBGN
0068: c5 c5		COLD6:		LD 		A, RUNMOD  		; get mode
006a: e4 52					XOR 	A, ='R'			; is it 'R'?
006c: 6c 2c					BZ		MAINLP			; yes, skip
006e: 20 c0 05 				JSR		INITAL			; intialize all interpreter variables
0071: 74 1e					BRA		MAIN			; continue

					; check RAM at loc P2; return 0 if found, nonzero if no RAM
0073: c6 01    	TSTRAM:		LD		A, @1, P2		; get value from RAM, autoincrement
0075: 48 					LD		E, A    		; save old value into E (e.g. X'55)
0076: e4 ff    				XOR		A, =ff			; complement value (e.g. X'AA)
0078: ca ff					ST		A, ff, P2    	; store it back (X'AA)
007a: e2 ff					XOR		A, ff, P2		; read back and compare (should be X'00)
007c: 01 					XCH		A, E    		; A=old value, E=X'00 (if RAM)
007d: ca ff					ST		A, ff, P2    	; store back old value
007f: e2 ff					XOR		A, ff, P2		; read back and compare (should be X'00)
0081: 58 					OR		A, E   			; or both tests, should be X'00 if RAM)
0082: 5c					RET						; return zero, if RAM, nonzero if none

				; NEW command
0083: 20 c0 05 	NEW:		JSR		INITAL			; initialize interpreter variables
0086: c2 00    				LD		A, 0, P2		; get a char from current program position (initially ROMBASE)
0088: e4 0d    				XOR		A, =CR			; is char a CR?
008a: 6c 05					BZ		MAIN			; yes, skip to program
008c: 10     				CALL	0
008d: 15 					CALL	5    			; APULL
008e: 24 0c 00				JMP		COLD1    		; back to cold start

0091: 85 d4   	MAIN: 		LD		EA, TXTBGN		; get start of program area
0093: 8d d6					ST		EA, TXTUNF		; store as end of program
0095: 46 					LD		P2, EA			; point P2 to it
0096: c4 7f					LD		A, =7f    		; set end of program flag
0098: ca 00					ST		A, 0, P2    	; at that position

				; main interpreter loop
009a: 85 d2		MAINLP:		LD		EA, STACK		; reinitialize stack
009c: 45 					LD		SP, EA    
009d: 85 c6    				LD		EA, EXTRAM		; start of RAM		
009f: b4 34	00				ADD		EA, =52			; offset to AESTK    
00a2: 8d c8					ST		EA, AESTK		; set position of arithmetic stack
00a4: 47					LD		P3, EA			; P3 is arith stack pointer
00a5: 20 e4 09 				JSR		INITBD			; initialize baud rate
00a8: 18					CALL 	8				; CRLF
00a9: c5 c2					LD		A, INPMOD		; mode flag?
00ab: 6c 0c					BZ 		MAINL1			; zero, skip
													; no, this is a break CTRL-C
00ad: 32 2    				LD		EA, P2			; current pointion of buffer
00ae: 8d ee    				ST		EA, CONTP		; save position (for CONT)
00b0: 22 11 09				PLI		P2, =STOPMSG	; STOP message
00b3: 1e     				CALL	14				; PRTLN
00b4: 5e 					POP		P2				; restore P2
00b5: 20 01 09 				JSR		PRTAT			; print AT line#
00b8: 18		MAINL1:		CALL	8				; CRLF
00b9: 85 c8		MAINL2:		LD 		EA, AESTK		; initialize P3 with AESTK
00bb: 47 					LD		P3, EA    
00bc: 84 00 00 				LD		EA, =0			; initialize constant ZERO
00bf: 8d ea					ST		EA, ZERO		
00c1: cd c2					ST		A, INPMOD   	; set cmd mode=0
00c3: c4 01					LD		A, =1			; initialize constant ONE
00c5: 8d e8					ST		EA, ONE			
00c7: 20 4c 08				JSR		GETLN			; read a line into buffer
00ca: 19 					CALL	9				; GETCHR
00cb: 1d					CALL 	13				; NUMBER
00cc: 85					DB		=X'85  			; not a number, skip to DIRECT
00cd: 85 d4					LD		EA, TXTBGN		; start of program
00cf: bd e8					SUB		EA, ONE    		; minus 1
00d1: bd d6					SUB		EA, TXTUNF		; subtract end of program
00d3: 06					LD		A, S    		; get status
00d4: 64 02					BP		MAINL3   			; overflow? no, skip
00d6: 1f					CALL	15				; ERROR
00d7: 01					DB 		=1				; 1 (out of mem)
00d8: 32		MAINL3:		LD		EA, P2    		; get buffer pointer
00d9: 8d f0					ST		EA, TMPF0		; save it
00db: 20 6d 01				JSR		FINDLN			; find line in program
00de: 7c 1b					BNZ		MAINL4			; no match, skip
00e0: 56					PUSH	P2				; save p2 (line begin)
00e1: 20 91 01				JSR		TOEOLN			; advance to end of line
00e4: 81 00					LD		EA, 0, SP		; get line begin (P2)
00e6: 47					LD		P3, EA			; into P3
00e7: 32					LD		EA, P2			; get end of line from TOEOLN
00e8: 1a 					CALL	10    			; NEGATE
00e9: 08					PUSH	EA				; save -endline
00ea: b5 e8					ADD		EA, ONE			; add one (for CR)
00ec: b5 d6					ADD		EA, TXTUNF		; add end of program area
00ee: 8d fe					ST		EA, TMPFE		; store number of bytes to move
00f0: 3a					POP		EA				; restore -endline
00f1: b1 00					ADD		EA, 0, SP		; subtract from start to get number of bytes to move
00f3: b5 d6					ADD		EA, TXTUNF		; add end of program area
00f5: 8d d6					ST		EA, TXTUNF		; set a new end of program
00f7: 20 5c 01				JSR		BMOVE			; move area
00fa: 5e					POP		P2				; restore start of line
				; replace or add line
00fb: 32		MAINL4:		LD		EA, P2			; copy into P3
00fc: 47 					LD		P3, EA    
00fd: 85 f0					LD		EA, TMPF0		; buffer pointer
00ff: 46					LD		P2, EA			; into P2
0100: 19					CALL	9				; GETCHR
0101: e4 0d					XOR		A, =CR			; is it a single line number?
0103: 6c b4					BZ		MAINL2			; yes, ignore that
0105: 85 d0					LD		EA, BUFAD		; address of buffer
0107: 46					LD		P2, EA			; into P2
0108: 19					CALL	9				; GETCHR
0109: 32					LD		EA, P2			; save buffer pointer
010a: 8d f6					ST		EA, TMPF6
010c: 20 91 01				JSR		TOEOLN			; advance to end of line
010f: 32					LD		EA, P2			; get end of line
0110: bd f6					SUB		EA, TMPF6		; subtract to get length of buffer
0112: 8d fe					ST		EA, TMPFE		; store number of bytes to move
0114: b5 d6					ADD		EA, TXTUNF		; add temporary end of buffer
0116: bd d8					SUB		EA, TXTEND		; store as new end of program
0118: bd e8					SUB		EA, ONE			; subtract one
011a: 01					XCH		A, E			; is result negative?
011b: 64 3e					BP		OMERR			; out of memory error
011d: 57					PUSH	P3				; save P3
011e: 85 d6					LD		EA, TXTUNF		; get tmp area
0120: 46 					LD		P2, EA			; into P2
0121: 33					LD		EA, P3			; line to insert
0122: bd d6					SUB		EA, TXTUNF		; subtract tmp buf
0124: 1a					CALL	10				; NEGATE
0125: 8d fb					ST		EA, TMPFB		; number of bytes to expand
0127: 58					OR		A, E			; is result zero?
0128: 0a					PUSH	A    			; save it for later check
0129: 85 d6					LD		EA, TXTUNF		; tmp buf
012b: b5 fe					ADD		EA, TMPFE		; add length of line
012d: 8d d6					ST		EA, TXTUNF		; store
012f: 47					LD		P3, EA			; into P3
0130: c2 00					LD		A, 0, P2		; copy a byte
0132: cb 00					ST		A, 0, P3
0134: 38					POP		A				; restore result from above (sets Z flag)
0135: 6c 10					BZ		MAINL6			; was zero, skip
0137: c6 ff		MAINL5:		LD		A, @X'ff, P2	; otherwise copy backwards TMPFB bytes
0139: cf ff					ST		A, @X'ff, P3
013b: 9d fb					DLD		A, TMPFB		; decrement byte counter
013d: 7c f8					BNZ		MAINL5
013f: c5 fc					LD		A, TMPFB+1
0141: 6c 04					BZ		MAINL6			; exit loop if zero
0143: 9d fc					DLD		A, TMPFB+1
0145: 74 f0					BRA		MAINL5			; loop
0147: 5f		MAINL6:		POP		P3				; restore target location
0148: 85 f6					LD		EA, TMPF6		
014a: 46					LD		P2, EA			; restore source location
014b: 20 5c 01				JSR		BMOVE			; move new line into program
014e: 24 b8 00	MAINL7:		JMP		MAINL2			; done, continue in main loop

				; parse a direct command
0151: c2 00		DIRECT:		LD		A, 0, P2		; get char from buffer
0153: e4 0d					XOR		A, =CR			; is it a CR?
0155: 6c f7					BZ		MAINL7			; yes, continue in main loop
0157: 23 98 01				PLI		P3, CMDTB1		; load first CMD table
015a: 1b					CALL	11				; CMPTOK

				; out of memory error
015b: 1f		OMERR:		CALL	15				; ERROR
015c: 01    				DB		1				; 1 (out of memory)
;--------------------------------------------------------------------------------------------------

				; move TMPFE bytes ascending from @P2 to @P3
015d: c6 01		BMOVE:		LD		A, @1, P2		; get char from first pos
015f: cf 01					ST		A, @1, P3		; store into second
0161: 9d fe					DLD		A, TMPFE    	; decrement byte counter 16 bit
0163: 7c f8					BNZ		BMOVE
0165: c5 ff					LD		A, TMPFE+1
0167: 6c 04					BZ		BMOVE1   		; exit if zero
0169: 9d ff					DLD		A, TMPFE+1
016b: 74 f0					BRA		BMOVE			; loop
016d: 5c		BMOVE1:		RET
;--------------------------------------------------------------------------------------------------
				; find line in program, 0 = found, 1 = insert before, -1 = not found, line in P2
				; line number to find is on AESTK
016e: 85 d4    	FINDLN:		LD 		EA, TXTBGN		; get start of program
0170: 46					LD 		P2, EA    		; into P2
0171: 32		FINDL1:		LD		EA, P2			; get P2
0172: 8d fb					ST		EA, TMPFB		; save temporary
0174: 19					CALL	9				; GETCHR
0175: 1d					CALL	13				; NUMBER
0176: 18					DB 		18				; skip if not number to FINDL4
0177: 15					CALL 	5				; APULL
0178: bb fe					SUB 	EA, X'fe, P3	; subtract number from the one on stack (the line number found)
017a: 01					XCH		A, E			; is larger?
017b: 64 05					BP		FINDL2			; yes skip
017d: 20 91 01 				JSR		TOEOLN			; advance to end of line
0180: 74 ef					BRA		FINDL1			; loop
0182: 58    	FINDL2:		OR		A, E
0183: 6c 02					BZ		FINDL3			; is exactly the same?
0185: c4 01					LD		A, =01			; no, return 1
0187: 0a     	FINDL3:		PUSH	A
0188: 15     				CALL	5				; APULL
0189: 85 fb					LD		EA, TMPFB		; get start of this line
018b: 46					LD		P2, EA    		; into P2
018c: 38					POP		A				; restore result
018d: 5c					RET						; return with 0, if exact match, 1 if insert
018e: c4 ff		FINDL4:		LD		A, =X'ff		; return with -1: end of program
0190: 74 f5					BRA		FINDL3		

;--------------------------------------------------------------------------------------------------
				; advance to end of line
0192: c4 0d		TOEOLN:		LD		A, =CR			; search for end of line
0194: 2e					SSM 	P2				; should be within next 256 bytes
0195: 74 17					BRA		UCERR			; didn't find one, error 3
0197: 5c					RET						; found one, return with P2 pointing to char after CR

;--------------------------------------------------------------------------------------------------
				; set of DIRECT commands
0198: 4c..		CMDTB1:		DB 		'LIST'
019c: 93					DB 		X'93			; to LIST
019d: 4e..    				DB 		'NEW'
01a0: 8a					DB 		X'8a			; to NEW2
01a1: 52..					DB 		'RUN'
01a4: b5					DB 		X'b5			; to RUN
01a5: 43..					DB 		'CONT'
01a9: a7					DB 		X'a7			; to CONT
01aa: d2					DB		X'd2			; default case to EXEC1

;--------------------------------------------------------------------------------------------------
				; NEW command
01ab: 24 82 00	NEW2:		JMP		NEW				; do new command

;--------------------------------------------------------------------------------------------------
01ae: 1f    	UCERR:		CALL 	15				; ERROR
01af: 03					DB 		3				; 3 (unexpected char)

;--------------------------------------------------------------------------------------------------
				; LIST command
01b0: 1d		LIST:		CALL	13				; NUMBER
01b1: 03					DB		3				; if no number, skip to LIST0
01b2: 74 03					BRA		LIST1
01b4: 85 ea		LIST0:		LD		EA, ZERO		; no number given, start with line 0
01b6: 14					CALL	4				; APUSH put on stack
01b7: 20 6d 01  LIST1:		JSR		FINDLN			; find line in program, or next one
01ba: 19		LIST2:		CALL	9 		  		; GETCHR from location found
01bb: 56					PUSH	P2    
01bc: 1d					CALL	13				; NUMBER 
01bd: 0a					DB		X'0a			; if error, goto LIST3
01be: 15					CALL	5				; APULL
01bf: 5e					POP		P2    
01c0: 1e					CALL	14				; PRTLN
01c1: 18					CALL	8				; CRLF
01c2: 20 1d 09				JSR		CHKBRK			; test break
01c5: 74 f3					BRA		LIST2
01c7: 5e     	LIST3:		POP		P2
01c8: 24 99 00	MAIN1:		JMP		MAINLP

;--------------------------------------------------------------------------------------------------
01cb: 54..     	CMDTB6:		DB		'THEN'			; then table
01cf: ad					DB		X'ad			; to EXEC1
01d0: ac					DB		X'ac			; default case to EXEC1

;--------------------------------------------------------------------------------------------------
				; CONT command
01d1: 85 ee		CONT:		LD		EA, CONTP		; restore program pointer from CONT
01d3: 46					LD		P2, EA
01d4: c4 01					LD		A, =01			; set program mode
01d6: cd c2					ST		A, INPMOD
01d8: 74 37					BRA		ENDCM1

;--------------------------------------------------------------------------------------------------
				; RUN command
01da: 20 c0 05	RUN:		JSR		INITAL			; initialize interpreter variables
01dd: c4 01					LD		A, =01			; set "running mode"
01df: cd c2					ST		A, INPMOD
01e1: 85 d4					LD		EA, TXTBGN		; start at first line
01e3: 46 					LD		P2, EA			; in buffer
01e4: 74 04					BRA		RUN2			; skip
01e6: c5 c2		RUN1:		LD		A, INPMOD
01e8: 6c de					BZ		MAIN1
01ea: 85 ea		RUN2:		LD		EA, ZERO		; load 0
01ec: 14					CALL	4				; APUSH

01ed: 20 70 01	RUN3:		JSR		FINDL1			; find line from current position
01f0: 64 06					BP		RUN4			; found one
01f2: c4 00					LD		A, =00			; set 'not running'
01f4: cd c2					ST		A, INPMOD
01f6: 74 d0					BRA		MAIN1			; back to mainloop
01f8: 1d 		RUN4:		CALL	13				; parse line NUMBER
01f9: 08					DB		 8				; not found: syntax error, goto SNERR1
01fa: 15					CALL	 5				; APULL line number
01fb: 8d c3					ST		EA, CURRNT		; set as current line


01fd: 23 2e 02	EXEC1:		PLI		P3, =CMDTB2		; run loop
0200: 1b					CALL	11				; process commands

0201: 1f		SNERR1:		CALL	15				; ERROR
0202: 04					DB 		4				; 4 (syntax error)

;--------------------------------------------------------------------------------------------------
				; handle end of CMD, check for break or interrupts... (call 6)
0203: 3a		ENDCMD:		POP		EA				; drop return address
0204: c5 e7					LD		A, ffe7			; flag set?
0206: 7c 09					BNZ		ENDCM1			; yes, skip
0208: c5 c2					LD		A, INPMOD		; interactive mode?
020a: 6c 05					BZ		ENDCM1			; yes skip
020c: 85 e0					LD		EA, INTVEC		; interrupt pending?
020e: 58					OR		A, E
020f: 7c 14					BNZ		ENDCM3			; yes, skip

0211: c4 00		ENDCM1:		LD		A, =0			
0213: cd e7					ST		A, NOINT
0215: 20 1d 09				JSR		CHKBRK			; check for break
0218: 1c					CALL	12				; EXPECT
0219: 3a					DB		':'				; colon?
021a: 03					DB		X'03			; no, to ENDCM2
021b: 74 e0					BRA		EXEC1			; continue run loop
021d: c6 01		ENDCM2:		LD		A, @1, P2		; advance to next char
021f: e4 0d					XOR		A, =CR			; is it end of line?
0221: 7c 8b					BNZ		UCERR			; error unexpected char
0223: 74 c1					BRA		RUN1			; continue

0225: 85 e0		ENDCM3:		LD		EA, INTVEC		; get pending int vector
0227: 14					CALL	4				; APUSH
0228: 85 ea					LD		EA, ZERO		; 
022a: 8d e0					ST		EA, INTVEC		; clear pending int
022c: 74 49					BRA		GOSUB1			; jump into GOSUB (process interrupt)

022e: 4c..		CMDTB2:		DB		'LET'
0231: a6					DB 		X'a6			; to LET
0232: 49..	   				DB		'IF'
0234: f3					DB		X'f3			; to IFCMD
0235: 4c..					DB		'LINK'
0239: f7					DB		X'f7			; to LINK
023a: 4e..					DB		'NEXT'
023e: 9c					DB		X'9c			; to NEXT
023f: 55..					DB		'UNTIL'
0244: db					DB		X'db			; to UNTIL
0245: 47..					DB		'GO'
0247: 96					DB		X'96			; to GOCMD
0248: 52..					DB		'RETURN'
024e: bd					DB		X'bd			; to RETURN
024f: 52..					DB		'REM'
0252: cf					DB		X'cf			; to REMCMD
0253: 80					DB		X'80			; default case to EXEC2

0254: 23 bf 02	EXEC2:		PLI		P3, =CMDTB7		; load table 7
0257: 1b					CALL	11    			; CMPTOK

;------------------------------------------------------------------------------
				; forward to assignment
0258: 24 5a 04	LET:		JMP		ASSIGN			; ignore LET and continue with general assigment

;------------------------------------------------------------------------------
				; forward to NEXT cmd
025b: 24 68 03	NEXT:		JMP		NEXT0			; handle NEXT

;------------------------------------------------------------------------------
				; handle GOTO or GOSUB
025e: 23 62 02	GOCMD:  	PLI		P3, =CMDTB5  	; check for TO or SUB
0261: 1b					CALL	11

0262: 54..		CMDTB5:		DB		'TO'
0264: 85					DB		X'85			; to GOTO
0265: 53..					DB		'SUB'
0268: 8d					DB		X'8d
0269: 80					DB		X'80			; default case to GOTO

;------------------------------------------------------------------------------
				; GOTO command
026a: 10		GOTO:		CALL	0				; RELEXP
026b: c4 01					LD		A, =1			;
026d: cd c2					ST		A, INPMOD		; set 'running mode'
026f: 20 6d 01				JSR		FINDLN			; find line in buffer
0272: 6c 84					BZ		RUN4			; skip to line number check
0274: 1f					CALL	15				; error    
0275: 07					DB		7				; 7 (goto target does not exist)    

;------------------------------------------------------------------------------
				; GOSUB command
0276: 10		GOSUB:		CALL	0				; RELEXP 
0277: 85 de		GOSUB1:		LD		EA, SBRPTR		; get SBR stack pointer
0279: 57					PUSH	P3				; save P3
027a: 47					LD		P3, EA			; SBR stack in P3
027b: 85 cc					LD		EA, DOSTK		; mark do stack pointer
027d: cd f6					ST		A, TMPF6		; in temporary
027f: 33					LD		EA, P3			; get SBR stack ptr
0280: 20 c0 03				JSR		CHKSBR			; check for overflow			
0283: 32					LD		EA, P2			; get buffer pointer
0284: 8f 02					ST		EA, @2, P3		; 
0286: 33					LD		EA, P3			; save new SBR pointer
0287: 8d de					ST		EA, SBRPTR
0289: 5f					POP		P3				; restore P3
028a: 74 df					BRA		GOTO			; do GOTO

;------------------------------------------------------------------------------
				; RETURN command
028c: 85 de		RETURN:		LD		EA, SBRPTR		; get SBR ptr
028e: bd ca					SUB		EA, SBRSTK		; is stack empty?
0290: 6c 0c					BZ		RETERR			; yes error 8
0292: 85 de					LD		EA, SBRPTR		; decrement SBR ptr
0294: bc 02 00				SUB		EA, =2
0297: 8d de					ST		EA, SBRPTR		; store it back
0299: 46					LD		P2, EA			; into P2
029a: 82 00					LD		EA, 0, P2		; restore buffer pointer
029c: 46					LD		P2, EA
029d: 16					CALL	6				; ENDCMD

;------------------------------------------------------------------------------
029e: 1f		RETERR:		CALL	15				; ERROR
029f: 08					DB		8				; 8 (return without gosub)

;------------------------------------------------------------------------------
				; forward to UNTIL
02a0: 74 5f		UNTIL:		BRA		UNTIL0			; redirect to real code

;------------------------------------------------------------------------------
				; REM
02a2: 20 91 01	REMCMD:		CALL	TOEOLN			; advance to end of line
02a5: c6 ff					LD		A, @X'ff, P2	; back one char
02a7: 16					CALL	6				; ENDCMD

;------------------------------------------------------------------------------
				; IF
02a8: 10		IFCMD:		CALL	0				; RELEXP get condition
02a9: 15					CALL	5				; APULL pop it into EA
02aa: 58					OR		A, E			; check for zero
02ab: 6c f5					BZ		REMCMD			; false: advance to end of line
02ad: 23 cb 01				PLI		P3, =CMDTB6		; process THEN (may be missing)
02b0: 1b					CALL	11				; CMPTOK

;------------------------------------------------------------------------------
				; LINK
02b1: 10		LINK:		CALL	0				; RELEXP get link address
02b2: 22 c2 04				PLI		P2, DOLAL6-1	; save P2, put return vector into P2
02b5: 15					CALL	5				; APULL pop link address
02b6: 57					PUSH	P3				; push P3 on stack
02b7: 56					PUSH	P2				; put return vector on stack
02b8: bd e8					SUB		EA, ONE			; adjust link address
02ba: 08					PUSH	EA				; push on stack
02bb: 85 c6					LD		EA, EXTRAM		; load P2 with base of variables
02bd: 46					LD		P2, EA
02be: 5c					RET						; return to link address
				; note: the stack frame is (before RET):
				;		P2 = variables
				;		Top:	linkaddress-1	(pulled by RET here)
				;				returnvector-1	(pulled by RET in called program)
				;				saved P3		(restored in returnvector stub)
				;				saved P2		(restored in returnvector stub)

;------------------------------------------------------------------------------
02bf: 46..		CMDTB7:		DB		'FOR'
02c2: e4					DB		X'e4			; to FOR
02c3: 44..					DB		'DO'
02c5: a7					DB		X'a7			; to DO
02c6: 4f..					DB		'ON'
02c8: 8f					DB		X'8f			; to ON
02c9: 43..					DB		'CLEAR'
02ce: 85					DB		X'85			; to CLEAR
02cf: 80					DB		X'80			; to EXEC3

;------------------------------------------------------------------------------
				; handle several commands for direct/program mode
02d0: 23 23 04	EXEC3:		PLI		P3, CMDTB8
02d3: 1b					CALL	11				; CMPTOK

;------------------------------------------------------------------------------
				; CLEAR cmd
02d4: 20 c5 05 	CLEAR:		JSR		INITA1			; do warm initialization
02d7: 16					CALL	6				; ENDCMD

;------------------------------------------------------------------------------
				; ON cmd
02d8: 10		ON:			CALL	0				; RELEXP get expression
02d9: 1c					CALL	12				; EXPECT check if comma follows
02da: 2c					DB		','    
02db: 01					DB		1				; if not, continue next instruction
02dc: 15		ON1:		CALL	5				; APULL get expression
02dd: d4 01					AND		A, =1			; has it bit 0 set?
02df: 6c 07					BZ		ON2				; no, skip
02e1: cd e6					ST		A, BRKFLG		; store nonzero in BRKFLG
02e3: 10					CALL	0				; RELEXP get INTA vector expression
02e4: 15					CALL	5				; APULL into EA
02e5: 8d e2					ST		EA, INTAVC		; set as INTA call vector
02e7: 16					CALL	6				; ENDCMD done

				; assume here another bit set
02e8: 10		ON2:		CALL	0				; RELEXP get INTB vector expression
02e9: 15					CALL	5				; APULL into EA
02ea: 8d e4					ST		EA, INTBVC		; set as INTB call vector
02ec: 16					CALL	6				; ENDCMD done

;------------------------------------------------------------------------------
				; DO cmd
02ed: 85 da		DO:			LD		EA, DOPTR		; get DO stack ptr
02ef: 57					PUSH	P3				; 	save P3
02f0: 47					LD		P3, EA			; into P3
02f1: 85 ce					LD		EA, FORSTK		; put end of stack (FORSTK is adjacent)
02f3: cd f6					ST		A, TMPF6		; into temporary
02f5: 33					LD		EA, P3			; DO stack pointer
02f6: 20 c0 03 				JSR		CHKSBR			; check stack overflow
02f9: 32					LD		EA, P2			; get current program pointer
02fa: 8f 02					ST		EA, @02, P3		; push on DO stack
02fc: 33					LD		EA, P3    		; and save new DO stack ptr
02fd: 5f					POP		P3				;   restore P3
02fe: 8d da		DO1:		ST		EA, DOPTR
0300: 16					RET						; done

;------------------------------------------------------------------------------
					;UNTIL command
0301: 10		UNTIL0:		CALL	0				; RELEXP get condition
0302: 85 da					LD		EA, DOPTR		; get DO stack ptr
0304: bd cc					SUB		EA, DOSTK		; subtrack stack base
0306: 58					OR		A,E				; is empty?
0307: 7c 02					BNZ		UNTIL1			; no, continue
													; otherwise throw error 11
0309: 1f					CALL	15				; ERROR
030a: 0b					DB		X'0b			; 11 (UNTIL without DO)
030b: 15		UNTIL1:		CALL	5				; APULL condition into EA
030c: 58					OR		A,E				; is false?
030d: 6c 07					BZ		UNTIL2			; yes, skip
030f: 85 da					LD		EA, DOPTR		; no, discard DO loop from stack
0311: bc 02 00				SUB		EA, =0002		; 1 level
0314: 74 e8					BRA		DO1				; store back DO stack ptr and exit
0316: 85 da		UNTIL2:		LD		EA, DOPTR		; do loop again
0318: 46					LD		P2, EA			; get DO stack ptr
0319: 82 fe					LD		EA, X'fe, P2	; get last level stored
031b: 46					LD		P2, EA			; as new program pointer -> redo loop
031c: 16					RET						; done	

;------------------------------------------------------------------------------
				; for comparison of FOR keyword STEP
031d: 53  		CMDTB9:		DB		'STEP'
0321: 96					DB		X'96			; to FOR2
0322: 98 					DB		X'98			; to FOR3

				; for comparison of FOR keyword TO
0323: 54		CMDT10:		DB		'TO'
0325: 8d					DB		X'8d			; to FOR1
0326: fd					DB		X'fd			; to SNERR2 (syntax error)

0327: 20 6c 05	FOR:		JSR		GETVAR			; get a variable address on stack
032a: 7a					DB		X'7a			; none found: goto SNERR2 (syntax error)
032b: 1c					CALL	12				; EXPECT a '='
032c: 3d    				DB		'='
032d: 77					DB		X'77			; none found: goto SNERR2 (syntax error)
032e: 10					CALL	0				; RELEXP get initial expression
032f: 23 23 03				PLI		P3, =CMDT10		; expect TO keyword (SNERR if not)
0332: 1b					CALL	11				; CMPTOK

0333: 10		FOR1:		CALL	0				; RELEXP get end expression
0334: 23 1d 03				PLI		P3, =CMDTB9		; check for STEP keyword, to FOR2 if found, to FOR3 if not
0337: 1b					CALL	11				; CMPTOK

0338: 10		FOR2:		CALL	0				; RELEXP get step expression
0339: 74 04					BRA		FOR4			; skip
033b: 85 e8		FOR3:   	LD		EA, ONE			; push 1 as STEP on stack
033d: 8f 02					ST		EA, @2, P3
033f: 85 dc		FOR4:		LD		EA, FORPTR		; get the FOR stack ptr
0341: 56					PUSH	P2				;   save current program ptr
0342: 46					LD		P2, EA			; into P2
0343: 85 d0					LD		EA, BUFAD		; put end of stack (BUFAD is adjacent)
0345: cd f6					ST		A, TMPF6		; into temporary
0347: 32					LD		EA, P2			; FOR stack ptr
0348: 20 c0 03				JSR		CHKSBR			; check stack overflow
034b: 15					CALL	5				; APULL restore step value
034c: 8e 02					ST		EA, @2, P2		; save at forstack+0
034e: 15					CALL	5				; APULL restore end value
034f: 8e 02					ST		EA, @2, P2		; save at forstack+2
0351: 15					CALL	5				; APULL restore initial value
0352: 09					LD		T, EA			; save in T
0353: 15					CALL	5				; APULL restore variable address
0354: 8d f6					ST		EA, TMPF6		; store address in temporary
0356: ce 01					ST		A, @1, P2		; save low offset of var at forstack+4
0358: 81 00					LD		EA, 0, SP		; get current program ptr
035a: 8e 02					ST		EA, @2, P2		; save at forstack+5
035c: 32					LD		EA, P2			; save new FOR stack ptr
035d: 8d dc					ST		EA, FORPTR
035f: 85 f6					LD		EA, TMPF6		; get variable address
0361: 46					LD		P2, EA			; into P2
0362: 0b					LD		EA, T			; initial value
0363: 8a 00					ST		EA, 0, P2		; save in variable
0365: 5e		FOR5:		POP		P2				; restore program pointer
0366: 16					CALL	6				; ENDCMD
				; note the FOR stack frame looks like the following:
				;		offset 0: DW step value
				;		offset 2: DW end value
				;		offset 4: DB variable low offset
				;		offset 5: DW program pointer of first statement of loop

0367: 1f		NXERR:		CALL	15				; ERROR
0368: 0a					DB		10				; 10 (NEXT without FOR)

				; NEXT command
0369: 20 6c 05	NEXT0:		JSR		GETVAR			; get variable address on stack
036c: 38					DB		X'38			; no var found, goto SNERR2 (syntax error)
036d: 15					CALL	5				; APULL restore address
036e: 09					LD		T, EA			; put into T
036f: 85 dc		NEXT1:		LD		EA, FORPTR		; get FOR stack ptr
0371: bd ce					SUB		EA, FORSTK		; subtract base
0373: 6c f2					BZ		NXERR			; is empty? yes, NEXT without FOR error
0375: 85 dc					LD		EA, FORPTR		; get FOR stack ptr again
0377: bc 07	00				SUB		EA, =0007		; discard current frame
037a: 8d dc					ST		EA, FORPTR		; save it for the case loop ends
037c: 56					PUSH	P2				; save program pointer
037d: 46					LD		P2, EA			; point to base of current FOR frame
037e: 0b					LD		EA, T			; get var address
037f: fa 04					SUB		A, 4, P2		; subtract var addr of this frame
0381: 6c 03					BZ		NEXT2			; is the same?, yes skip (found)
0383: 5e					POP		P2				; restore P2
0384: 74 e9					BRA		NEXT1			; try another loop - assume jump out of loop
0386: c2 01		NEXT2:		LD		A, 1, P2		; step value (high byte)
0388: 64 09					BP		NEXT3			; is step positive? yes, skip
038a: 20 a5 03				JSR		NXADD			; add step and compare with end value
038d: e4 ff					XOR		A, =X'ff		; compare with -1
038f: 6c 					BZ		NEXT5			; zero? yes, end of loop not yet reached
0391: 74 03					BRA		NEXT4			; skip
0393: 20 a5 03	NEXT3:		JSR		NXADD			; add step and compare with end value
0396: 64 cd		NEXT4:		BP		FOR5			; end of loop done, continue after NEXT
0398: 82 05		NEXT5: 		LD		EA, 5, P2		; get start of loop program pointer
039a: 5e					POP		P2				; drop P2
039b: 46					LD		P2, EA			; set start of loop again
039c: 85 dc					LD		FORPTR			; get FOR stack ptr
039e: b4 07 00				ADD		EA, =0007		; push loop frame again
03a1: 8d dc					ST		EA, FORPTR		; save new FOR ptr
03a3: 16					RET						; done

03a4: 1f		SNERR2:		CALL	15				; ERROR
03a5: 04					DB		4				; 4 (syntax error)

;------------------------------------------------------------------------------
				; add step and compare with end value
03a6: 85 c6		NXADD:		LD		EA, EXTRAM		; variable base
03a8: c2 04					LD		A, 4, P2    	; get variable offset
03aa: 57					PUSH	P3				;   save P3
03ab: 47					LD		P3, EA			; into EA
03ac: 83 00					LD		EA, 0, P3		; get variable value
03ae: b2 00					ADD		EA, 0, P2		; add step value
03b0: 8b 00					ST		EA, 0, P3		; store new variable
03b2: 5f					POP		P3				;  restore P3
03b3: ba 02					SUB		EA, 2, P2		; compare with end value
03b5: 6c 04					BZ		NXADD2			; same?
03b7: 01					XCH		A, E			; no, swap: A = high byte
03b8: d4 80		NXADD1:		AND		A, =X'80		; mask out sign bit
03ba: 5c					RET						; return
03bb: 01		NXADD2:		XCH		A, E			; swap: A = high byte
03bc: 7c fa					BNZ		NXADD1			; not same? get high byte
03be: c4 ff					LD		A, =X'ff		; set A = -1
03c0: 5c					RET						; return

;------------------------------------------------------------------------------	
				; check for SBR stack overflow
				; EA contains current stack pointer, TMPF6 contains limit
03c1: fd f6		CHKSBR:		SUB		A, TMPF6		; subrack limit
03c3: 64 01					BP		NSERR			; beyond limit?
03c5: 5c					RET						; no, exit
													; otherwise nesting too deep error
03c6: 1f		NSERR:		CALL	15				; ERROR
03c7: 09					DB		9				; 9 (nesting too deep)

;------------------------------------------------------------------------------
03c8: 1f		SUERR:		CALL	15				; ERROR
03c9: 02					DB		2				; 2 (stmt used improperly)

;------------------------------------------------------------------------------
				; INPUT handler
03ca: c5 c2		INPUT0:		LD		A, INPMOD		; is in direct mode?
03cc: 6c fa					BZ		SUERR			; yes, this is an error!
03ce: 32					LD		EA, P2			; save current program ptr temporarily
03cf: 8d f2					ST		EA, TMPF2
03d1: 20 6c 05	INPUT1:		JSR		GETVAR			; get variable address on stack
03d4: 29					DB		X'29			; no variable, goto INPUT3 (could be $)
03d5: c4 03					LD		A, =03			; set mode 3, swap buffers (P2 is input buffer)
03d7: 20 1a 04				JSR		SWPBUF
03da: 20 4c 08				JSR		GETLN			; get line into input buffer
03dd: 10		INPUT2:		CALL	0				; RELEXP get expression from input buffer
03de: 15					CALL	5				; APULL into EA
03df: 09					LD		T, EA			; save into T
03e0: 15					CALL	5				; APULL get variable address
03e1: 57					PUSH	P3				;   save P3
03e2: 47					LD		P3, EA			; into P3
03e3: 0b					LD		EA, T			; obtain expression
03e4: 8b 00					ST		EA, 0, P3		; save into variable
03e6: 5f					POP		P3				;   restore P3
03e7: c4 01					LD		A, =01			; set mode 1, swap buffers (P2 is program ptr)
03e9: 20 1a 04				JSR		SWPBUF
03ec: 1c					CALL	12				; EXPECT a comma
03ed: 2c					DB		','
03ee: 2c					DB		X'2c			; if not found, exit via INPUT5
03ef: 20 6c 05				JSR		GETVAR			; get another variable
03f2: d6					DB		X'd6			; if none found, goto SUERR (error 2)
													; does not accept $ any more here
03f3: c4 03					LD		A, =03			; set mode 3, swap buffers (P2 is input buffer)
03f5: 20 1a 04				JSR		SWPBUF
03f8: 1c					CALL	12				; EXPECT an optional comma in input buffer
03f9: 2c					DB		','
03fa: 01					DB		1				; none found, ignore
03fb: 74 e0					BRA		INPUT2			; process the next variable

				; process $expr for string input
03fd: 1c		INPUT3:		CALL	12				; EXPECT a $ here
03fe: 24					DB		'$'
03ff: c9					DB		X'c9			; none found, goto SUERR
0400: 11					CALL	1				; FACTOR get string buffer address
0401: c4 03					LD		A, =03			; set mode 3, swap buffers (P2 is input buffer)
0403: 20 1a 04				JSR		SWPBUF
0406: 20 4c 08				JSR		GETLN			; get line of input
0409: 15					CALL	5				; APULL get buffer address
040a: 57					PUSH	P3				;   save P3
040b: 47					LD		P3, EA			; into P3
040c: c6 01		INPUT4:		LD		A, @1, P2		; copy input from buffer into string
040e: cf 01					ST		A, @1, P3
0410: e4 0d					XOR		A, =CR			; until CR seen
0412: 7c f8					BNZ		INPUT4
0414: 5f					POP		P3				;   restore P3
0415: c4 01					LD		A, =01			; set mode 1 again, swap buffers (P2 is program ptr)
0417: 20 1a 04				JSR		SWPBUF			
041a: 16		INPUT5:		CALL	6				; ENDCMD done

;------------------------------------------------------------------------------
				; save input mode and swap buffers
041b: cd c2		SWPBUF:		ST		A, INPMOD		; store new input mode
041d: 85 f0					LD		EA, TMPF0		; swap buffer addresses
041f: 4e					XCH		P2, EA			; TMPF0 normally contains input buffer address
0420: 8d f0					ST		EA, TMPF0
0422: 5c					RET

;------------------------------------------------------------------------------
				; several more commands
0423: 44..		CMDTB8:		DB		'DELAY'
0428: 9a					DB		X'9a			; to DELAY
0429: 49..					DB		'INPUT'
042e: 8f					DB		X'8f			; to INPUT
042f: 50..					DB		'PRINT'
0434: 8b					DB		X'8b			; to PRINT
0435: 50..					DB		'PR'
0437: 88					DB		X'88			; to PRINT
0438: 53..					DB		'STOP'
043c: 91					DB		X'91			; to STOP
043d: 9d					DB		X'9d			; default to ASSIGN

;------------------------------------------------------------------------------
				; INPUT cmd
043e: 74 8a		INPUT:		BRA		INPUT0			; INPUT handler

;------------------------------------------------------------------------------
				; PRINT cmd
0440: 24 c9 04	PRINT:		JMP		PRINT0			; PRINT handler

;------------------------------------------------------------------------------
				; DELAY cmd
0443: 10		DELAY:		CALL	0				; RELEXP get delay expression
0444: 15					CALL	5				; APULL into EA
0445: a4 3f	00				LD		T, =X'003f		; multiply with 63
0448: 2c					MPY		EA, T
0449: 0b					LD		EA, T			; into EA
044a: 20 ca 09				JSR		DELAYC			; do delay
044d: 16					RET						; done

;------------------------------------------------------------------------------
				; STOP cmd
044e: 24 99 00	STOP:		JMP		MAINLP			; directly enter main loop

;------------------------------------------------------------------------------
				; left hand side (LHS) operators for assigment
0451: 53..		CMDTB4:		DB		'STAT'
0455: 89					DB		X'89			; to STATLH
0456: 40					DB		'@'
0457: 92					DB		X'92			; to ATLH
0458: 24					DB		'$'
0459: b1					DB		X'b1			; to DOLALH
045a: 9e					DB		X'9e			; default case to ASSIG1   

;------------------------------------------------------------------------------
				; handle assignments
045b: 23 51 04	ASSIGN:		PLI		P3, CMDTB4
045e: 1b					CALL	11				; CMPTOK

;------------------------------------------------------------------------------
				; STAT on left hand side
045f: 1c		STATLH:		CALL	12 				; EXPECT an equal symbol
0460: 3d					DB		'='				;  
0461: 67					DB		X'67			; not found, goto SNERR    
0462: 10					CALL	0				; RELEXP get the right hand side
0463: 15					CALL	5				; APULL into EA
0464: 07					LD		S, A			; put into SR (only low byte)  
0465: c4 01					LD		A, =1			; suppress potential INT that could
0467: cd e7    				ST		A, NOINT		; result from changing SA/SB
0469: 16					CALL	6				; ENDCMD

;------------------------------------------------------------------------------
				; @ on left hand side (POKE)
046a: 11 		ATLH:		CALL	1				; FACTOR get non-boolean expression
046b: 1c					CALL	12				; EXPECT an equal symbol
046c: 3d					DB		'='
046d: 5b					DB		X'5b			; not found, goto SNERR (syntax error)
046e: 10					CALL	0				; RELEXP get right hand side
046f: 15					CALL	5				; APULL into EA
0470: 09					LD		T, EA			; into T
0471: 15					CALL	5				; APULL get target address
0472: 57					PUSH	P3				;   save P3
0473: 47					LD		P3, EA			; into P3
0474: 0b					LD		EA, T			; RHS into EA
0475: cb 00					ST		A, 0, P3		; store low byte at address
0477: 5f					POP		P3
0478: 16					RET

;------------------------------------------------------------------------------
				; default case for assign (VAR = expr)
0479: 20 6c 05	ASSIG1:		JSR		GETVAR			; get a variable
047c: 4c					DB		X'4c			; if not var, goto DOLAL4 (assume $xxxx)
047d: 1c					CALL	12				; EXPECT an equal symbol
047e: 3d					DB		'='
047f: 49					DB		X'49			; not found, go to SNERR
0480: 10					CALL	0				; RELEXP get right hand side
0481: 15					CALL	5				; APULL into EA
0482: 09					LD		T, EA			; into T
0483: 15					CALL	5				; APULL get variable address
0484: 57					PUSH	P3				;   save P3
0485: 47					LD		P3, EA			; into P3
0486: 0b					LD		EA, T			; get RHS
0487: 8b 00					ST		EA, 0, P3		; store result into variable
0489: 5f					POP		P3				;   restore P3
048a: 16					CALL	6				; ENDCMD done

;------------------------------------------------------------------------------
				; $ on left hand side
048b: 11		DOLALH:		CALL	1				; FACTOR get target address
048c: 1c					CALL	12				; EXPECT an equal symbol
048d: 3d					DB		'='
048e: 3a					DB		X'3a			; if not found, goto SNERR
048f: c2 00					LD		A, 0, P2		; get next char from program
0491: e4 22					XOR		A, X'22			; is double quote?
0493: 7c 1c					BNZ		DOLAL3			; not a constant string, may be string assign
0495: c6 01					LD		A, @1, P2		; skip over quote
0497: 15					CALL	5				; APULL get target address
0498: 57					PUSH	P3				;   save P3
0499: 47					LD		P3, EA			; into P3
049a: c6 01		DOLAL1:		LD		A, @1, P2		; get string char from program buffer
049c: e4 22					XOR		A, =X'22		; is double quote?
049e: 6c 0a					BZ		DOLAL2			; yes, end of string, skip
04a0: e4 2f					XOR		A, =X'2f		; is CR?
04a2: 6c 22					BZ		EQERR			; yes, ending quote missing error 
04a4: e4 0d					XOR		A, =X'0d		; convert back to original char
04a6: cf 01					ST		A, @1, P3		; store into target buffer
04a8: 74 f0					BRA		DOLAL1			; loop

04aa: c4 0d		DOLAL2:		LD		A, =CR			; terminate target string
04ac: cb 00					ST		A, 0, P3
04ae: 5f					POP		P3				;   restore P3
04af: 19					CALL	9				; GETCHR get next char from program
04b0: 16					CALL	6				; ENDCMD done

				; assume string assign
04b1: 1c		DOLAL3:		CALL	12				; EXPECT a $
04b2: 24					DB		'$'
04b3: 15					DB		X'15			; not found, goto SNERR
04b4: 11					CALL	1				; FACTOR get source address
04b5: 15					CALL	5				; APULL into EA
04b6: 56					PUSH	P2				;   save P2
04b7: 46					LD		P2, EA			; into P2

04b8: 15		DOLAL4:		CALL	5				; APULL get target address
04b9: 57					PUSH	P3				;   save P3
04ba: 47					LD		P3, EA			; into P3
04bb: c6 01		DOLAL5:		LD		A, @1, P2		; move byte from source to targer
04bd: cf 01					ST		A, @1, P3
04bf: e4 0d					XOR		A, =CR			; compare with CR
04c1: 7c f8					BNZ		DOLAL5			; not yet, continue copying

;------------------------------------------------------------------------------
				; This location is also the return point form LINK
04c3: 5f		DOLAL6:		POP		P3				;   restore P3
04c4: 5e					POP		P2				;   restore P2
04c5: 16					CALL	6				; ENDCMD

;------------------------------------------------------------------------------
04c6: 1f		EQERR:		CALL	15				; ERROR
04c7: 06					DB		6				; 6 (ending quote missing)

;------------------------------------------------------------------------------
04c8: 1f		SNERR:		CALL	15				; ERROR    
04c9: 04					DB		4				; 4 (syntax error)

;------------------------------------------------------------------------------
				; PRINT handler
04ca: c2 00		PRINT0:		LD		A, 0, P2		; get char from program
04cc: e4 22					XOR		A, X'22			; is double quote?
04ce: 7c 11					BNZ		PRINT2			; no, not a string print

				; print a string constant
04d0: c6 01					LD		A, @1, P2		; skip over quote
04d2: c6 01		PRINT1:		LD		A, @1, P2		; get next char
04d4: e4 22					XOR		A, =X'22		; is double quote?
04d6: 6c 18					BZ		PRINT4			; yes, done with print
04d8: e4 2f					XOR		A, =X'2f		; is CR?
04da: 6c ea					BZ		EQERR			; yes, error missing end quote
04dc: e4 0d					XOR		A, =X'0d		; convert back to original char
04de: 17					CALL	7				; PUTC emit 
04df: 74 f1					BRA		PRINT1			; loop

				; print a string variable
04e1: 1c		PRINT2:		CALL	12				; EXPECT a $
04e2: 24					DB		'$'
04e3: 09					DB		X'09			; if not found, goto PRINT3 (could be expression)
04e4: 11					CALL	1				; FACTOR get source address
04e5: 15					CALL	5				; APULL into EA
04e6: 56					PUSH	P2				;   save P2
04e7: 46					LD		P2, EA			; into P2
04e8: 1e					CALL	14				; PRTLN print the string
04e9: 5e					POP		P2				;   restore P2
04ea: 74 04					BRA		PRINT4			; continue in PRINT

				; print an expression
04ec: 10		PRINT3:		CALL	0				; RELEXP get expression
04ed: 20 fb 04				JSR		PRNUM			; print numeric

				; print next field
04f0: 19		PRINT4:		CALL	9				; GETCHR get next character
04f1: 1c					CALL	12				; EXPECT a comma
04f2: 2c					DB		','
04f3: 03					DB		3				; if not found, goto PRINT5 (check for semicolon)
04f4: 74 d4					BRA		PRINT0			; process next field

04f6: 1c		PRINT5:		CALL	12				; EXPECT a semicolon
04f7: 3b					DB		';'
04f8: 02					DB		2				; if not found, goto PRINT6 do a CRLF
04f9: 16					CALL	6				; ENDCMD semicolon: terminate without CRLF
04fa: 18		PRINT6:		CALL	8				; CRLF do a new line
04fb: 16					CALL	6				; ENDCMD done

;------------------------------------------------------------------------------
				; pop number off stack and print it
04fc: 83 fe    PRNUM:		LD 		EA, fe, P3		; get last number on stack
04fe: 01 					XCH		A, E    		; check high byte
04ff: 64 09    				BP		PRNUM1			; is positive? yes, skip
0501: 01 					XCH		A, E    		; restore original number
0502: 1a 					CALL	10    			; NEGATE number
0503: 8b fe    				ST		EA, fe, P3		; store as positive number on stack
0505: c4 2d					LD		A, ='-'			; load minus symbol
0507: 17     				CALL	7				; PUTC emit it
0508: 74 03    				BRA		PRNUM2			; skip
050a: c4 20		PRNUM1:		LD		A, =SPACE		; emit a blank
050c: 17 					CALL	7    			; PUTC
050d: c4 00		PRNUM2:		LD		A, =0			; clear counter for characters
050f: cd fe					ST		A, TMPFE		; 
0511: 15 					CALL	5				; APULL get number  (is positive)
0512: 23 f6 ff    			PLI		P3, =TMPF6		; save P3 and load TMPF6
0515: a4 0a 00	PRNUM3:		LD		T, =10			; load divisor 10    
0518: 8d fc					ST		EA, TMPFC		; store dividend temporary
051a: 0d 					DIV		EA, T			; divide by 10
051b: 08					PUSH	EA				; save remainder
051c: a4 0a 00				LD		T, =10			; multiplier 10
051f: 2c					MPY		EA, T			; multiply, is now (VAL DIV 10) * 10, i.e. last digit stripped
0520: 0b 					LD		EA, T			; get this
0521: 1a 					CALL	10    			; NEGATE
0522: b5 fc  				ADD		EA, TMPFC		; extract least digit
0524: cf 01					ST		A, @1, P3		; push onto stack
0526: 95 fe					ILD		A, TMPFE		; increment char counter
0528: 3a 					POP		EA    			; restore remainder
0529: 7c ea					BNZ		PRNUM3			; unless zero, loop for another digit
052b: 01 					XCH		A, E			; also high byte
052c: 6c 03					BZ		PRNUM4			; if zero, go emitting
052e: 01 					XCH		A, E    		; restore remainder
052f: 74 e4					BRA		PRNUM3			; loop for another digit
0531: c7 ff		PRNUM4:  	LD		A, @ff, P3		; get last pushed digit first
0533: f4 30					ADD		A, ='0'			; make it ASCII digit    
0535: 17 					CALL	7				; PUTC
0536: 9d fe					DLD		A, TMPFE		; decrement count	
0538: 7c f7					BNZ		PRNUM4    		; loop until all digits done
053a: c4 20					LD		A, =SPACE		; emit space
053c: 17					CALL	7				; PUTC
053d: 5f					POP		P3				; restore arithmetic stack pointer
053e: 5c					RET
;------------------------------------------------------------------------------
				; print string pointed to by P2, until char has bit 7 is set or is CR
053f: c6 01		PRTLN:		LD		A, @1, P2		; get next char from buffer
0541: e4 0d					XOR		A, =CR			; is CR?
0543: 6c 05					BZ		PRTLN1			; yes exit
0545: e4 0d					XOR 	A, =CR			; make original char again
0547: 17					CALL 	7				; PUTC emit it
0548: 64					BP		PRTLN			; if positive, loop
054a: 5c     	PRTLN1		RET						; exit
;------------------------------------------------------------------------------
				; get next char from buffer
054b: c6 01		GETNXC:		LD		A, @1, P2		; advance P2
;------------------------------------------------------------------------------
				; get character from buffer pointed to by P2, into A (call 9)
054d: c2 00    	GETCHR:		LD		A, 0, P2		; char from buffer
054f: d4 7f					AND		A, =X'7f		; mask 7 bits
0551: 48					LD		E, A			; into E
0552: e4 20					XOR		A, =SPACE		; is space?    
0554: 6c f5					BZ		GETNXC			; skip over it, loop to next    
0556: e4 2a					XOR		A, =X'2a		; is LF (SPACE xor X'0a)?
0558: 6c f1					BZ		GETNXC			; yes, skip over it, loop to next    
055a: 40					LD		A, E			; back into A
055b: 6c ee					BZ		GETNXC			; if zero, loop over it
055d: 5c					RET
;------------------------------------------------------------------------------
				; EXPECT char following in text, if not found (call 12)
				; call it as:
				;			CALL 12
				;			DB	'chartomatch'
				;			DB	offset to jump to if no match
055e: 3a		EXPECT:		POP		EA				; get return addr
055f: b5 e8					ADD		EA, ONE    		; advance to following byte
0561: 08					PUSH	EA				; put return on stack again (continue here if matched)
0562: 57					PUSH	P3				; save P3
0563: 47 					LD		P3, EA			; point to char to match
0564: c3 00					LD		A, 0, P3		; load char to match
0566: e2 00					XOR		A, 0, P2		; compare with buffer
0568: 5f					POP		P3				; restore P3
0569: 6c 23					BZ		GETVA3			; char matched, advance to next and exit
056b: 74 0c    				BRA		GETVA1			; otherweise error

;------------------------------------------------------------------------------
				; expect variable, and push it
				; call as:
				;			JSR GETVAR
				;			DB	offset to jump to if not variable
056d: c2 00		GETVAR:		LD		A, 0, P2		; get character from buffer
056f: 48					LD		E, A			; save in E
0570: fc 5b					SUB		A, ='Z'+1		; subtract 'Z'+1
0572: 64 05					BP		GETVA1			; is >=, skip
0574: 40					LD		A, E			; restore char
0575: fc 41					SUB		A, ='A'			; subtract 'A'
0577: 64 0d					BP		GETVA2			; is an alpha char, skip

				; go to the offset that return address points to
0579: 3a    	GETVA1:		POP		EA				; pop return address (pointing to error code)
057a: 8d f6					ST		EA, TMPF6		; save in temporary
057c: 57					PUSH	P3				; save P3
057d: 47					LD		P3, EA			; get return addr in P3
057e: 85 ea					LD		EA, ZERO		; clear EA
0580: c3 01					LD		A, 1, P3		; get next location offset
0582: b5 f6					ADD		EA, TMPF6		; add return addr
0584: 5f					POP		P3				; restore P3
0585: 44					LD		PC, EA			; go to that offset (no variable found)

0586: 0e		GETVA2:		SL		A				; is variable, make offset into var table
0587: 01					XCH		A, E			; put into E
0588: c4 00					LD		A, =0			; clear A
058a: 01					XCH		A, E			; make 16 bit unsigned
058b: b5 c6					ADD		EA, EXTRAM		; add ext ram base
058d: 14					CALL	4				; APUSH

058e: c6 01    	GETVA3:		LD		A, @1, P2		; advance to next buffer pos
0590: 19		GETVA4:		CALL	9				; GETCHR
0591: 3a					POP		EA				; return addr
0592: b5 e8					ADD		EA, ONE			; skip over error jump
0594: 44    				LD		PC, EA			; continue in interpreter
;------------------------------------------------------------------------------
				; NUMBER	expect a number and push it (call 13)
				; call as:
				;			CALL 13
				;			DB offset to jump to if no number
0595: c2 00		NUMBER:		LD		A, 0, P2		; get char from buffer
0597: 2d e0					BND		GETVA1, PC		; if not digit, skip to next loc
0599: 85 ea					LD		EA, ZERO		; load 0
059b: 8d f6					ST		EA, TMPF6		; store temporary
059d: 09		NUMBE1:		LD		T, EA			; store into T
059e: c6 01					LD		A, @1, P2		; get digit and advance
05a0: 2d 19					BND		NUMBE4, PC		; skip if no more digits
05a2: cd f6					ST		A, TMPF6		; store digit    
05a4: 84 0a 00				LD		EA, =10			; factor 10
05a7: 2c					MPY		EA, T			; multiply
05a8: 58 					OR		A, E			; check overflow?
05a9: 7c 0e					BNZ		NUMBE3			; yes, skip
05ab: 0b					LD		EA, T			; move result to EA
05ac: b5 f6					ADD		EA, TMPF6		; add digit
05ae: 09					LD		T, EA			; store intermediate result
05af: 40					LD		A, E			; high byte
05b0: 64 02					BP		NUMBE2			; skip if no overflow (became negative)
05b2: 74 05					BRA		NUMBE3			; not okay
05b4: 06		NUMBE2:		LD		A, S			; get status    
05b5: d4 c0					AND		A, =X'c0		; mask out OV, CY
05b7: 6c e5					BZ		NUMBE1			; loop unless error
05b9: 1f     	NUMBE3:		CALL	15				; ERROR
05ba: 05     				DB		5				; 5 (value format)
05bb: c6 ff    	NUMBE4:		LD		A, @X'ff, P2	; point back to non digit
05bd: 0b					LD		EA, T			; get accumulated value    
05be: 14					CALL	4				; APUSH
05bf: 74 cf					BRA		GETVA4			; advance to next position and skip over error offset
;------------------------------------------------------------------------------
					; intialize interpreter variables
05c1: 84 00 00 	INITAL:		LD		EA, =X'0000		; constant 0
05c4: 8d c3					ST		EA, CURRNT		; reset current line number
05c6: 85 c6		INITA1:		LD		EA, EXTRAM		; get start addr of external RAM
05c8: b4 34 00				ADD		EA, =52			; add offset to next field (26 variables)
05cb: 8d c8					ST		EA, AESTK 		; store start of arithmetic stack
05cd: b4 1a 00				ADD		EA, =26			; add offset to next field
05d0: 8d ca					ST		EA, SBRSTK		; store start of GOSUB stack
05d2: 8d de					ST		EA, SBRPTR		; store pointer to GOSUB level
05d4: b4 10 00				ADD		EA, =16			; add offset to next field
05d7: 8d cc					ST		EA, DOSTK		; store start of DO stack
05d9: 8d da					ST		EA, DOPTR		; store pointer to DO level
05db: b4 10 00				ADD		EA, =16			; add offset to next field
05de: 8d ce					ST		EA, FORSTK		; store start of FOR stack
05e0: 8d dc					ST		EA, FORPTR		; store pointer to FOR level
05e2: b4 1c 00				ADD		EA, =28			; add offset to next field
05e5: 8d d0					ST		EA, BUFAD		; store pointer to line buffer
05e7: 20 e4 09				JSR		INITBD			; initialize baud rate
													; BUG! ZERO is not yet initialized on first call!
05ea: c4 34					LD		A, =52			; size of variable table in bytes
05ec: cd f6					ST		A, TMPF6		; store it
05ee: 85 c6					LD		EA, EXTRAM		; load RAM BASE into P3
05f0: 47 					LD		P3, EA
05f1: 84 00 00				LD		EA, =0000		; initialize constant zero
05f4: 8d ea					ST		EA, ZERO
05f6: 8d e0					ST		EA, INTVEC		; clear vector for current interrupt
05f8: 8d e2					ST		EA, INTAVC		; clear vector for Interrupt A
05fa: 8d e4					ST		EA, INTBVC		; clear vector for Interrupt B
05fc: 8d c0					ST		EA, MULOV
05fe: cd e6					ST		A, BRKFLG		; enable breaks
0600: c4 00		INITA2:		LD		A, =00			; clear A
0602: cf 01					ST		A, @1, P3		; clear variable area
0604: 9d f6					DLD		A, TMPF6		; decrement counter
0606: 7c f8					BNZ		INITA2			; until done
0608: c4 01					LD		A, =01			; low byte = 01, EA now 0001
060a: 8d e8					ST		EA, ONE			; store constant 1
060c: 85 c8					LD		EA, AESTK		; load AESTK into P3
060e: 47					LD		P3, EA 
060f: c4 52					LD		A, ='R'			; store 'R'
0611: cd c5					ST		A, RUNMOD
0613: 5c					RET						; exit

;------------------------------------------------------------------------------
				; CMPTOK (CALL 11) compare current position with token from list in P3
				; table is built this way:
				;			DB		'token1'
				;			DB		jmp displacement OR X'80
				;			DB		'token2'
				;			DB		jmp displacement OR X'80
				;			DB		jmp target if not found OR X'80
0614: 3a		CMPTOK:		POP		EA				; drop return address
0615: 56		CMPTO1:		PUSH	P2				; save buffer pointer position
0616: c7 01					LD		A, @1, P3		; get byte from table
0618: 64 15					BP		CMPTO4			; if positive, belongs to token to match
													; negative: matched a complete token
061a: 74 05					BRA		CMPTO3			; value is location offset to jump to
													; note that the last char in table is negative:
													; the default location always reached if no token matches
061c: c7 01		CMPTO2:		LD		A, @1, P3		; next char of token from table
061e: 64 0f					BP		CMPTO4			; is end of token? yes, found one
0620: 19					CALL	9				; GETCHR, read char from buffer
													; P2 now points to char after recognized token
0621: 3a		CMPTO3:		POP		EA				; drop old P2 (start of token)
0622: 85 ea					LD		EA, ZERO		; preload a zero
0624: c7 ff					LD		A, @X'ff, P3	; get the location offset
0626: d4 7f					AND		A, X'7f			; discard high bit
0628: 8d f6					ST		EA, TMPF6    	; store temporary
062a: 33					LD		EA, P3			; get pointer postion
062b: b5 f6					ADD		EA, TMPF6    	; add offset
062d: 5f					POP		P3				; restore P3
062e: 44					LD		PC, EA			; go to location
062f: e6 01		CMPTO4:		XOR		A, @1, P2		; compare token char with buffer
0631: d4 7f					AND		A, X'7f			; only select 7 bits
0633: 6c e7					BZ		CMPTO2			; matches, loop
0635: 5e					POP		P2				; does not match, reload buffer pointer
0636: c7 01		CMPTO5:		LD		A, @1, P3		; get char from table, advance until end of token
0638: 64 fc					BP		CMPTO5    		; loop as long token char
063a: 74 d9					BRA		CMPTO1			; retry next token from table

;------------------------------------------------------------------------------
				; get relational expression (call 0)
				; term {<|<=|=|<>|>|>=} term
				;
				; note the precedence seems to be warped:
				; I'd expect something like 
				;	X>5 AND X<10 to match an X between 5 and 10,
				; but TERM binds the AND operator stronger
				; thus it is interpreted as
				;   X > (5 AND X) < 10
				; which results in an error 3
063c: 20 8e 06	RELEXP:		JSR 	TERM			; get first operand
063f: 23 43 06				PLI		P3, =OPTBL1		; list of comparison operators
0642: 1b					CALL	11				; CMPTOK
0643: 3d		OPTBL1:		DB		'='
0644: 8e    				DB		X'8e			; to RELEQ
0645: 3c..    				DB		'<='
0647: 90					DB		X'90			; to RELLE
0648: 3c..					DB		'<>'
064a: 92					DB		X'92			; to RELNE
064b: 3c					DB		'<'
064c: 95					DB		X'95			; to RELLT
064d: 3e..					DB		'>='
064f: 97					DB		X'97    		; to RELGE
0650: 3e					DB		'>'
0651: 9a					DB		X'9a			; to RELGT
0652: a6					DB		X'a6			; default case to RELEX3

0653: 13		RELEQ:		CALL	3				; COMPAR
0654: d4 02					AND		A, =X'02		; is equal?
0656: 74 17					BRA		RELEX1
0658: 13		RELLE:		CALL	3				; COMPAR
0659: d4 82					AND		A, =X'82		; is less or equal?
065b: 74 12					BRA		RELEX1
065d: 13		RELNE:		CALL	3				; COMPAR
065e: d4 81					AND		A, =X'81		; is less or greater?
0660: 74 0d					BRA		RELEX1
0662: 13		RELLT:		CALL	3				; COMPAR
0663: d4 80					AND		A, =X'80		; is less?
0665: 74 08					BRA		RELEX1
0667: 13		RELGE:		CALL	3				; COMPAR
0668: d4 03					AND		A, =X'03		; is greater or equal?
066a: 74 03					BRA		RELEX1
066c: 13		RELGT:		CALL	3				; COMPAR
066d: d4 01					AND		A, =X'01		; is greater?
066f: 6c 05		RELEX1:		BZ		RELEX2			; condition not matched
0671: 84 ff ff				LD		EA, =X'ffff		; return -1 (condition matched)
0674: 14					CALL	4				; APUSH
0675: 5c					RET
0676: 85 ea		RELEX2:		LD		EA, ZERO		; return 0 (condition not matched)
0678: 14					CALL	4				; APUSH
0679: 5c		RELEX3:		RET

;------------------------------------------------------------------------------
				; COMPAR	(call 3)
				; get a second operand and compare it to the first one on STACK
067a: 20 8e 06	COMPAR:		CALL	TERM			; get second operand
067d: 12					CALL	2				; SAVOP
067e: bd f6					SUB		EA, TMPF6		; compute 1stOP - 2ndOP
0680: 01					XCH		A, E			; highbyte
0681: 64 03					BP		COMPA1			; positive, i.e. 1st >= 2nd ?
0683: c4 80					LD		A, =X'80		; no, set bit 7 (less)
0685: 5c					RET
0686: 58		COMPA1:		OR		A, E			; even zero, i.e. 1st = 2nd ?
0687: 6c 03					BZ		COMPA2			; yes
0689: c4 01					LD		A, =X'01		; no, set bit 0 (greater)
068b: 5c					RET
068c: c4 02		COMPA2: 	LD		A, =X'02		; set bit 1 (equal)
068e: 5c					RET

;------------------------------------------------------------------------------
				; evaluate a TERM:   {+|-} factor {+|-} factor
068f: 1c		TERM:		CALL	12				; EXPECT an optional minus symbol
0690: 2d					DB		'-'				; 
0691: 09     				DB		9				; if not found, skip to TERM2
0692: 20 c7 06 				JSR		MDTERM			; get first mul/div term
0695: 15					CALL	5				; APULL into EA
0696: 1a					CALL	10				; NEGATE negate
0697: 14		TERM1:		CALL	4				; APUSH again on stack
0698: 74 06					BRA		TERM4			; continue
069a: 1c		TERM2:		CALL	12				; EXPECT an optional plus symbol
069b: 2b					DB		'+'				;
069c: 01					DB		1				; if not found, continue at TERM3
069d: 20 c7 06	TERM3:		JSR		MDTERM			; get a mul/div term
06a0: 23 a4 06	TERM4:		PLI		P3, =CMDT11		; load add/sub/or operator table
06a3: 1b					CALL	11				; CMPTOK

06a4: 2b					DB		'+'
06a5: 86					DB		X'86			; to TERM5
06a6: 2d					DB		'-'
06a7: 8c					DB		X'8c			; to TERM6
06a8: 4f..					DB		'OR'
06aa: 91					DB		X'91			; to TERM7
06ab: c5					DB		X'c5			; default to FACTOR1 (RET)
				; process MDTERM + MDTERM
06ac: 20 c7 06	TERM5:		CALL	MDTERM			; get second mul/div term
06af: 12					CALL	2				; SAVOP
06b0: b5 f6					ADD		EA, TMPF6		; compute sum
06b2: 74 e3					BRA		TERM1			; loop for further term of this precedence
				; process MDTERM - MDTERM
06b4: 20 c7 06	TERM6:		JSR		MDTERM			; get second mul/div term
06b7: 12					CALL	2				; SAVOP
06b8: bd f6					SUB		EA, TMPF6		; compute difference
06ba: 74 db					BRA		TERM1			; loop for further term of this precedence
				; process MDTERM OR MDTERM
06bc: 20 c7 06	TERM7:		JSR		MDTERM			; get second operand
06bf: 12					CALL	2				; SAVOP
06c0: dd f6					OR		A, TMPF6		; do byte by byte OR
06c2: 01					XCH		A, E
06c3: dd f7					OR		A, TMPF6+1
06c5: 01					XCH		A, E
06c6: 74 cf					BRA		TERM1			; loop for further term of this precedence

;------------------------------------------------------------------------------
				; evaluate multiplicative term		factor {*|/} factor
06c8: 11		MDTERM:		CALL	1				; FACTOR get first factor
06c9: 23 cd 06	MDTER0:		PLI		P2, =CMDT13		; load table of mul/div/and operators
06cc: 1b					CALL	11				; CMPTOK
06cd: 2a    	CMDT13:		DB		'*'
06ce: 87					DB		X'87			; to MDTER1
06cf: 2f					DB		'/'
06d0: 8d					DB		X'8d			; to MDTER3
06d1: 41..					DB		'AND'
06d4: 90					DB		X'90			; to MDTER4
06d5: 9b					DB		X'9b			; default to FACTO1 (return)

				; process	FACTOR * FACTOR
06d6: 11		MDTER1:		CALL	1				; FACTOR get 2nd operand
06d7: 12					CALL	2				; SAVOP
06d8: 20 f4 07				JSR		MULTOP			; multiply EA * TMPF6
06db: 14		MDTER2:		CALL	4				; APUSH push result on stack
06dc: 74 eb					BRA		MDTER0			; loop for further multiplicative term
				; process FACTOR / FACTOR (handle division by zero in subroutine)
06de: 11		MDTER3:		CALL	1				; FACTOR get 2nd operand
06df: 12					CALL	2				; SAVOP
06e0: 20 0c 08				JSR		DIVOP			; divide EA / TMPF6
06e3: 74 f6					BRA		MDTER2			; loop for further multiplicative term
				; process FACTOR AND FACTOR
06e5: 11		MDTER4:		CALL	1				; FACTOR get 2nd operand
06e6: 12					CALL	2				; SAVOP
06e7: d5 f6					AND		A, TMPF6		; do byte by byte AND
06e9: 01					XCH		A, E
06ea: d5 f7					AND		A, TMPF6+1
06ec: 01					XCH		A, E
06ed: 74 ec					BRA		MDTER2			; loop for further multiplicative term

;------------------------------------------------------------------------------
				; FACTOR	(call 1) get a factor: number, var, function, (RELEXP)
06ef: 1d		FACTOR:		CALL	13				; NUMBER get number in sequence
06f0: 02					DB		2				; if not found continue at FACTO2
06f1: 5c		FACTO1:		RET						; has numeric operand on stack, done

06f2: 23 f6 06	FACTO2:		PLI		P3, =CMDT12		; load table of standard functions
06f5: 1b					CALL	11				; CMPTOK

06f6: 28					DB		'('				; left parenthesis (subexpression)
06f7: b2					DB		X'b2			; to LPAREN
06f8: 40					DB		'@'				; right hand side @
06f9: b7					DB		X'b7			; to ATRH
06fa: 23					DB		'#'				; hex operator
06fb: e5					DB		X'e5			; to HASHFN
06fc: 4e..					DB		'NOT'			; NOT operator
06ff: b7					DB		X'b7			; to NOTFN
0700: 53..					DB		'STAT'			; right hand side STAT
0704: bc					DB		X'bc			; to STATRH
0705: 54..					DB		'TOP'			; right hand side TOP
0708: bb					DB		X'bb			; to TOPFN
0709: 49..					DB		'INC'			; INC(X) function
070c: bd					DB		X'bd			; to INCFN
070d: 44..					DB		'DEC'			; DEC(X) function
0710: c2					DB		X'c2			; to DECFN
0711: 4d..					DB		'MOD'			; MOD(X,Y) function
0714: ce					DB		X'ce			; to MODFN
0715: 52..					DB		'RND'			; RND(X,Y) function
0718: e5					DB		X'e5			; to RNDFN
0719: 80					DB		X'80			; default to FACTO3 (variable)
071a: 20 6c 05	FACTO3:		JSR		GETVAR
071d: 12					DB		X'12			; if not var, goto SNERR3
071e: 20 22 07				JSR		PEEK
0721: 14					CALL	4				; APUSH
0722: 5c					RET

;------------------------------------------------------------------------------
				; peek word at address on stack
0723: 15		PEEK:		CALL	5				; APULL
0724: 57					PUSH	P3
0725: 47					LD		P3, EA
0726: 83 00					LD		EA, 0, P3
0728: 5f					POP		P3
0729: 5c					RET

;------------------------------------------------------------------------------
				; handle parenthesized expression '(' expr ')'
072a: 10		LPAREN:		CALL	0				; RELEXP get expression
072b: 1c					CALL	12				; EXPECT a closing parenthesis
072c: 29					DB		')'
072d: 02					DB		X'02			; if not found, goto SNERR3
072e: 5c					RET

;------------------------------------------------------------------------------
072f: 1f		SNERR3:		CALL	15				; ERROR
0730: 04					DB		4				; 4 (syntax error)

;------------------------------------------------------------------------------
				; @ operator
0731: 11		ATRH:		CALL	1				; FACTOR get the address to peek
0732: 20 22 07				JSR		PEEK			; read memory
0735: 74 24					BRA		DECFN2			; make 16 bit result on stack

;------------------------------------------------------------------------------
				; NOT operator
0737: 11		NOTFN:		CALL	1				; FACTOR get argument
0738: 15					CALL	5				; APULL into EA
0739: e4 ff					XOR		A, =X'ff		; do byte by byte complement
073b: 01					XCH		A, E
073c: e4 ff					XOR		A, X'ff
073e: 01					XCH		A, E
073f: 14					CALL	4				; APUSH result on stack
0740: 5c					RET

;------------------------------------------------------------------------------
				; STAT function
0741: 06		STATRH:		LD		A, S			; get the current status reg
0742: 74 17					BRA		DECFN2			; make 16 bit result on stack

;------------------------------------------------------------------------------
				; TOP function
0744: 85 d6		TOPFN:		LD		EA, TXTUNF		; get current top of program area
0746: b5 e8					ADD		EA, ONE			; add 1 to return next free location
0748: 14					CALL	4				; APUSH	push on stack
0749: 5c					RET

;------------------------------------------------------------------------------
				; INC function
074a: 20 a2 07	INCFN:		JSR		ARGONE			; get a single function arg into EA
074d: 56					PUSH	P2				;   save P2
074e: 46					LD		P2, EA			; put as address into P2
074f: 92 00					ILD		A, 0, P2		; increment this cell
0751: 74 07					BRA		DECFN1			; return the new result as 16 bit
				
;------------------------------------------------------------------------------
				; DEC function
0753: 20 a2 07	DECFN:		JSR		ARGONE			; get a single function arg into EA
0756: 56					PUSH	P2				;   save P2
0757: 46					LD		P2, EA			; put as address into P2
0758: 9a 00					DLD		A, 0, P2		; decrement this cell
075a: 5e		DECFN1:		POP		P2				;   restore old P2
075b: 01		DECFN2:		XCH		A, E			; save result
075c: c4 00					LD		A, =X'00		; make zero high byte
075e: 01					XCH		A, E			; restore result as low byte
075f: 14					CALL	4				; APUSH 16 bit result on stack
0760: 5c					RET

;------------------------------------------------------------------------------
				; jump to # operator
0761: 74 57		HASHFN:		BRA		HASHF0			; forward to HEX number interpreter

;------------------------------------------------------------------------------
				; MOD function
0763: 20 ab 07	MODFN:		JSR		ARGTWO			; get two arguments
0766: 12					CALL	2				; SAVOP: 1st arg=EA, 2nd=TMPF6
0767: 09		MODFN1:		LD		T, EA			; T = 1st arg
0768: 85 f6					LD		EA, TMPF6		; EA = 2nd arg
076a: 8d fe					ST		EA, TMPFE		; save in temp
076c: 0b 					LD		EA, T			; save 1nd arg in TMPFC
076d: 8d fc					ST		EA, TMPFC
076f: 20 0c 08				JSR		DIVOP			; divide EA / TMPF6
0772: 8d f6					ST		EA, TMPF6		; quotient into TMPF6
0774: 85 fe					LD		EA, TMPFE		; multiply with 2nd arg
0776: 20 f4 07				JSR		MULTOP			; i.e. EA div F6 * F6
0779: 1a					CALL	10				; NEGATE, i.e. -(EA div F6 * F6)
077a: b5 fc					ADD		EA, TMPFC		; subtract from 1st: EA - (EA div F6 * F6)
077c: 14					CALL	4				; APUSH on stack
077d: 5c					RET

;------------------------------------------------------------------------------
				; RND function
077e: 20 ab 07	RNDFN:		JSR		ARGTWO			; get two arguments on stack
0781: a5 f4					LD		T, RNDNUM		; get random number
0783: 84 85 04				LD		EA, =X'0485		; multiply with 1157
0786: 2c 					MPY		EA, T
0787: 0b					LD		EA, T			; use only low 16 bits
0788: b4 19 36				ADD		EA, =X'3619		; add 13849
078b: 8d f4					ST		EA, RNDNUM		; discard overflow and save as new random value
078d: 15					CALL	5				; APULL second arg
078e: b5 e8					ADD		EA, ONE			; add one
0790: bb fe					SUB		EA, X'fe, P3	; subtract 1st arg
0792: 8d f6					ST		EA, TMPF6		; save as TMPF6
0794: 85 f4					LD		EA, RNDNUM		; get random value
0796: 01					XCH		A, E			; make random number positive
0797: d4 7f					AND		A, =X'7f
0799: 01					XCH		A, E
079a: 20 66 07				JSR		MODFN1			; MOD(random, (2nd-1st+1))
079d: 15					CALL	5				; APULL get result
079e: b3 fe					ADD		EA, X'fe, P3	; add 1st arg
07a0: 8b fe					ST		EA, X'fe, P3	; store inplace on stack
07a2: 5c					RET

;------------------------------------------------------------------------------
				; get a single function argument
07a3: 1c		ARGONE:		CALL	12				; EXPECT opening paren
07a4: 28					DB		'('
07a5: 13					DB		X'13			; if not found, goto SNERR4
07a6: 10					CALL	0				; RELEXP expression
07a7: 1c					CALL	12				; EXPECT closing paren
07a8: 29					DB		')'
07a9: 0f					DB		X'0f			; if not found, goto SNERR4
07aa: 15					CALL	5				; APULL argument into EA
07ab: 5c					RET

;------------------------------------------------------------------------------
				; get a double function arg
07ac: 1c		ARGTWO:		CALL	12				; EXPECT opening paren
07ad: 28					DB		'('
07ae: 0a					DB		X'0a			; if not found goto SNERR4
07af: 10					CALL	0				; RELEXP get first arg on stack
07b0: 1c					CALL	12				; EXPECT a comma
07b1: 2c					DB		','
07b2: 06					DB		X'06			; if not found, goto SNERR4
07b3: 10					CALL	0				; RELEXP get 2nd arg on stack
07b4: 1c					CALL	12				; EXPECT closing paren
07b5: 29					DB		')'
07b6: 02					DB		X'02			; if not found, goto SNERR4
07b7: 5c					RET						; leaves 2 args on stack

07b8: 1f		SNERR4:		CALL	15				; ERROR
07b9: 04					DB		4				; 4 (syntax error)

;------------------------------------------------------------------------------
				; # operator
				; handle hexadecimal constants
07ba: 85 ea		HASHF0:		LD		EA, ZERO		; initialize temporary
07bc: 8d f6					ST		EA, TMPF6
07be: 09					LD		T, EA			; also clear T (collects value)
07bf: c6 01					LD		A, @1, P2		; get first digit
07c1: 2d 02					BND		HASHF1, PC		; if not digit, skip
07c3: 74 1a					BRA		HASHF5			; handle decimal digit (0..9)
07c5: 20 ea 07	HASHF1:		JSR		CVTHEX			; may be 'A'..'F', convert to 0..5
07c8: 64 13					BP		HASHF4			; if negative, was no hex letter
07ca: 1f					CALL	15				; ERROR
07cb: 05    				DB		5				; 5 (value error)

07cc: c6 01		HASHF2:		LD		A, @1, P2		; get next char from number
07ce: 2d 02					BND		HASHF3, PC		; if not digit, skip
07d0: 74 0d   				BRA		HASHF5			; insert next digit
07d2: 20 ea 07	HASHF3:		JSR		CVTHEX			; may by 'A'..'F', convert to 0..5
07d5: 64 06					BP		HASHF4			; if a letter, insert it
07d7: 0b    				LD		EA, T			; done with hex number, put value into EA
07d8: 14    				CALL	4				; APUSH on stack
07d9: c6 ff					LD		EA, @X'ff, P2	; re-get the last non-hex char
07db: 19    				CALL	9				; GETCHR
07dc: 5c    				RET						; done
07dd: f4 0a		HASHF4:		ADD		A, =X'0a		; cvt hex 'letter' into range 10..15
07df: cd f6		HASHF5:		ST		A, TMPF6		; store digit temporary (0..15)
07e1: 0b    				LD		EA, T			; shift 4 bit left
07e2: 0f    				SL		EA
07e3: 0f    				SL		EA
07e4: 0f    				SL		EA
07e5: 0f   					SL		EA
07e6: b5 f6					ADD		EA, TMPF6		; add digit
07e8: 09    				LD		T, EA			; put back into T
07e9: 74 e1					BRA		HASHF2			; loop

;------------------------------------------------------------------------------
				; convert an ASCII hex digit to X'00...X'05
07eb: fc 47		CVTHEX:		SUB		A, =X'47		; subtract 'G'
07ed: 64 03					BP		CVTHE1			; is >= 'G', yes, return -1
07ef: f4 06					ADD		A, =X'06		; adjust into range 0..5 if 'A'..'F'
07f1: 5c   					RET						; still negative, if < 'A'
07f2: c4 ff		CVTHE1:		LD		A, =X'ff		; return negative result
07f4: 5c   					RET

;------------------------------------------------------------------------------
				; Multiply EA * TMPF6 -> EA
07f5: 20 1e 08	MULTOP:		JSR		GETSGN			; make operands positive, and save result sign in FB
07f8: a5 f6					LD		T, TMPF6		; compute EA * F6
07fa: 2c					MPY		EA, T
07fb: 8d c0					ST		EA, MULOV		; save higher result as overflow
07fd: c5 fb		MULTO1:		LD		A, TMPFB		; get resulting sign
07ff: 64 0a					BP		NEGAT1			; if positive, return result unchanged
0801: 0b					LD		EA, T    		; otherwise put result in EA
													; and fall through into NEGATE

;--------------------------------------------------------------------------------------------------
				; negate number in EA (call 10)
0802: e0 ff		NEGATE:		XOR		A, =X'ff		; 1's complement low byte
0804: 01					XCH		A, E			; swap
0805: e4 ff					XOR		A, =X'ff		; 1's complement high byte
0807: 01 					XCH		A, E    		; swap back
0808: b5 e8					ADD		EA, ONE			; add ONE (2's complement)
080a: 5c					RET

080b: 0b		NEGAT1:		LD		EA, T			; return positive result
080c: 5c					RET

;------------------------------------------------------------------------------
				; divide EA / TMPF6 -> EA
080d: 20 1e 08	DIVOP:		JSR		GETSGN			; make operands positive, save result sign in FB
0810: 09					LD		T, EA			; 1st arg in T
0811: 85 f6					LD		EA, TMPF6		; check 2nd arg
0813: 58					OR		A, E			; is it zero?
0814: 6c 07					BZ		DV0ERR			; yes, division by zero error
0816: 0b					LD		EA, T			; EA = 1st arg
0817: a5 f6					LD		T, TMPF6		; T = 2nd arg
0819: 0d					DIV		EA, T			; divide
081a: 09					LD		T, EA			; store quotient into T
081b: 74 e0					BRA		MULTO1			; adjust result sign

081d: 1f		DV0ERR:		CALL	15				; ERROR    
081e: 0c					DB		X'0c			; 12 (div by zero)

;------------------------------------------------------------------------------
				; make operands of Mul/Div positive, and store result sign in TMPFB
081f: 09		GETSGN:		LD		T, EA			; 1st arg into T
0820: c5 f7					LD		A, TMPF6+1		; get sign of 2nd arg
0822: cd fb					ST		A, TMPFB		; store in FB
0824: 64 05					BP		GETSG1			; was positive, skip
0826: 85 f6					LD		EA, TMPF6		; negate 2nd arg
0828: 1a 					CALL	10				; NEGATE
0829: 8d f6					ST		EA, TMPF6		; store it back
082b: 0b		GETSG1:		LD		EA, T			; get 1st arg
082c: 40 					LD		A, E			; get sign
082d: e5 fb					XOR		A, TMPFB		; exor with sign of 2nd
082f: cd fb					ST		A, TMPFB		; save as resulting sign
0831: 0b					LD		EA, T			; get 1st arg
0832: 01					XCH		A, E			; get sign
0833: 64 03					BP		GETSG2			; was positive, restore and exit
0835: 01					XCH		A, E			; otherwise negate 1nd arg 
0836: 1a					CALL	10				; NEGATE
0837: 5c					RET			
0838: 01		GETSG2:		XCH		A, E			; return 1st arg in EA
0839: 5c					RET

;----------------------------------------------------------------------------------------------
				; push a value in EA onto AESTK, pointed to by P3
083a: 08 		APUSH:		PUSH	EA				; save value
083b: 33					LD		EA, P3			; get P3 value
083c: bd ca					SUB		EA, SBRSTK		; subtract end of AESTK (= start of SBRSTK)
083e: 01					XCH		A, E			; get high byte
083f: 64 04					BP		APUSH1			; negative?, yes error
0841: 3a					POP		EA				; restore value
0842: 8f 02					ST		EA, @2, P3		; store in stack, pointed to by P3, autoincrement
0844: 5c					RET
0845: 1f    	APUSH1:		CALL 	15				; error 9 (stack overflow)
0846: 09					DB		9				; error code

;----------------------------------------------------------------------------------------------
				; SAVOP		(call 2) pull last op and save into TMPF6, then pull 2nd last into EA
0847: 15		SAVOP:		CALL	5				; APULL
0848: 8d f6					ST 		EA, TMPF6		; save last value

;--------------------------------------------------------------------------------------------------
				; pull a value off AESTK pointed to by P3, return in EA (call 5)
084a: 87 fe		APULL:		LD		EA, @fe, P3		; get value from stack, autodecrement
084c: 5c 					RET						; return

;--------------------------------------------------------------------------------------------------
				; get a line into BUFAD, return P2 = BUFAD
084d: 85 d0		GETLN:		LD		EA, BUFAD		; set P2 = BUFAD
084f: 46					LD		P2, EA			; 
0850: c4 00					LD		A, =0			; clear BUFCNT
0852: cd fe					ST		A, TMPFE
0854: c5 c2					LD		A, INPMOD    	; input mode
0856: 6c 07					BZ		GETLN1			; if zero, do '>' prompt
0858: c4 3f					LD		A, =QUEST		; load '?'
085a: 17					CALL 	7				; PUTC
085b: c4 20					LD		A, =SPACE		; load space
085d: 74 02					BRA		GETLN2			; continue
085f: c4 3e    	GETLN1:		LD		A, =GTR			; load '>'
0861: 17    	GETLN2:		CALL 	7				; PUTC
0862: 20 2a 09	GETCH:		JSR		GECO			; get char with echo in A
0865: 6c fb    				BZ		GETCH			; if zero, ignore
0867: 48					LD		E, A			; save char into E
0868: e4 0a					XOR		A, =LF			; is it LF?
086a: 6c f6					BZ		GETCH			; yes, ignore
086c: e4 07					XOR		A, =X'07		: is it CR?		A xor (0a xor 07)
086e: 6c 3f					BZ		EOLN			; yes, skip
0870: e4 52					XOR		A, =X'52		; is it '_'?	A xor (0d xor 52)
0872: 6c 25					BZ		DELCH			; yes skip
0874: e4 57					XOR		A, =X'57		; is it X'08?	A xor (5f xor 57)
0876: 6c 1b					BZ		CTRLH			; yes skip
0878: e4 1d					XOR		A, =X'1d		; is it X'15?	A xor (08 xor 1d)
087a: 6c 0e					BZ		CTRLU			; yes skip
087c: e4 16					XOR		A, =X'16		; is it X'03?	A xor (15 xor 16)
087e: 7c 23    				BNZ		CHAR			; no, skip: no control char
0880: c4 5e    				LD		A, =CARET		; load '^'
0882: 17					CALL	7				; PUTC
0883: c4 43					LD		A, ='C'			; load 'C'
0885: 17					CALL 	7				; PUTC
0886: 18					CALL	8				; CRLF
0887: 24 99 00				JMP		MAINLP			; back to interpreter
088a: c4 5e		CTRLU:		LD		A, =CARET		; load '^'
088c: 17					CALL 	7				; PUTC
088d: c4 55					LD		A, ='U'			; load 'U'
088f: 17					CALL	7				; PUTC
0890: 18					CALL	8				; CRLF
0891: 74 ba					BRA		GETLN			; restart input line
0893: c4 20		CTRLH:		LD		A, =SPACE		; load ' '
0895: 17					CALL	7				; PUTC
0896: c4 08					LD		A, =BS			; load backspace
0898: 17					CALL 	7				; PUTC
0899: c5 fe		DELCH:		LD		A, TMPFE		; load buffer count
089b: 6c c5					BZ		GETCH			; if at beginning of line, loop
089d: 9d fe					DLD		A, TMPFE		; decrement buffer count
089f: c6 ff					LD		A, @ff, P2    	; point one buffer pos back
08a1: 74 bf					BRA		GETCH			; loop 
08a3: 40		CHAR:		LD		A, E			; get char back
08a4: ce 01					ST		A, @1, P2   	; put into buffer
08a6: 95 fe					ILD		A, TMPFE		; increment buffer counter
08a8: e4 49					XOR		A, =73			; limit of 72 chars reached?
08aa: 7c b6					BNZ		GETCH			; no get another
08ac: c4 0d   				LD		A, =CR			; load CR
08ae: 17					CALL	7				; emit

08af: c4 0d		EOLN:		LD		A, =CR			; load CR
08b1: ce 01					ST		A, @1, P2		; put into buffer
08b3: c4 0a					LD		A, =LF			; load LF
08b5: 17					CALL	7				; PUTC
08b6: 85 d0					LD		EA, BUFAD		; get BUFAD into P2
08b8: 46					LD		P2, EA
08b9: 5c					RET						; done

;--------------------------------------------------------------------------------------------------
				; handle Interrupt A (will only happen with external I/O, otherwise SA is in use)
08ba: 08 	    INTA:		PUSH	EA				; save EA
08bb: 85 e2    				LD		EA, INTAVC		; load vector
08bd: 74 03					BRA		INT1			; skip

08bf: 08 	    INTB:		PUSH	EA				; save EA
08c0: 85 e4    				LD		EA, INTBVC		; load vector
08c2: 8d e0    	INT1:		ST		EA, INTVEC		; save vector
08c4: 58					OR		A, E			; check if EA=0
08c5: 6c 02					BZ		INT2			; yes ignore
08c7: 3a 					POP		EA				; restore EA
08c8: 5c					RET						; exit
08c9: 3a		INT2:		POP		EA				; restore EA
08ca: 3b 01					OR		S, =X'01		; enable interrupts
08cc: 5c					RET						; exit

;--------------------------------------------------------------------------------------------------
				; emit error, code is in byte following CALL 15
08cd: 3a 		ERROR:		POP		EA				; get address of caller
08ce: 47					LD		P3, EA			; into P3
08cf: 56					PUSH	P2    			; save P2
08d0: 26 0c 09				LD		P2, =ERRMSG		; address of error message
08d3: 1e					CALL 	14				; PRTLN
08d4: 85 ea					LD		EA, ZERO		; clear EA
08d6: c3 01					LD		A, 1, P3    	; get error number from code
08d8: 47     				LD		P3, EA			; into P3
08d9: 85 c8					LD 		EA, AESTK		; get AESTK    
08db: 4f O    				XCH		EA, P3			; put into P3, EA is error code
08dc: 14					CALL	4				; APUSH
08dd: 20 fb 04 				JSR		PRNUM			; print number
08e0: c5 c2					LD		A, INPMOD		; get input mode
08e2: 6c 07					BZ		ERRO1			; was in interactive mode, skip
08e4: e4 03					XOR		A, =03    		; was X'03?
08e6: 6c 0c					BZ 		ERRO2			; yes, skip
08e8: 20 01 09				JSR		PRTAT			; otherwise: print AT line#
08eb: 18 		ERRO1:		CALL 	8				; CRLF
08ec: 5e					POP		P2				; restore P2
08ed: c4 00					LD		A, =0			; set interactive mode
08ef: cd c2					ST		A, INPMOD
08f1: 24 99 00				JMP		MAINLP    		; back to main loop
08f4: 18 		ERRO2:		CALL	8				; CRLF
08f5: 22 18 09				PLI		P2, =RETMSG		; load retype msg
08f8: 1e 					CALL 	14				; PRTLN
08f9: 5e 					POP		P2				; restore P2
08fa: 18 					CALL	8				; CRLF
08fb: 5e					POP		P2    			; restore P2 from call
08fc: 85 f2					LD		EA, TMPF2		; restore buffer ptr from input save location
08fe: 46					LD		P2, EA			;
08ff: 24 d0 03				JMP		INPUT1			; back into INPUT

;--------------------------------------------------------------------------------------------------
				; print "AT line#"
0902: 26 16 09	PRTAT:		LD		P2, =ATMSG		; at msg
0905: 1e					CALL 	14				; PRTLN
0906: 85 c3					LD		EA, CURRNT		; current line
0908: 14     				CALL	4				; APUSH
0909: 24 fb 04				JMP		PRNUM    		; print line number

090c: 45..     	ERRMSG:		DB		'ERRO', 'R'+$80
0911: 53.. 		STOPMSG:	DB		'STO', 'P'+$80
0916: 41.. 		ATMSG:		DB		'A', 'T'+$80
0918: 52.. 		RETMSG:		DB		'RETYP', 'E'+$80

;--------------------------------------------------------------------------------------------------
				; check BREAK from serial, return to mainloop if pressed
				; requires BRKFLG=0
091e: c5 e6    	CHKBRK:		LD		A, BRKFLG		; get break flag
0920: 7c 05					BNZ		CHKBR1			; if 1 then not enabled
0922: 06					LD		A, S			; get status
0923: d4 10					AND		A, =X'10		; check SA
0925: 6c 01					BZ		CHKBR2			; if low, return to main loop
0927: 5c    	CHKBR1:		RET						; otherwise exit
0928: 24 99 00	CHKBR2:		JMP		MAINLP

;--------------------------------------------------------------------------------------------------
				; wait for and read a character from input line, return it in A
092b: 22 00 fd	GECO:		PLI 	P2, =BAUDFLG	; get baudrate flags
092e: c2 00					LD 		A, 0, P2		; read bits, here: bit 7
0930: 64 43					BP		EXGET			; bit 7=0: call external routine
0932: 5e					POP		P2				; restore P2
0933: 06					LD		A, S			; get status
0934: 0a					PUSH	A				; save it
0935: 39 fe					AND		S, =X'fe		; disable IE
0937: c4 09					LD		A, =9
0939: cd ff					ST		A, TMPFE+1		; store counter for bits
093b: 3b 04					OR		S, =X'04		; set F2
093d: 06		GECO1:		LD		A, S			; read status
093e: d4 10					AND		A, =X'10		; select bit SA
0940: 7c fb					BNZ		GECO1			; if 1 loop (no start bit)
0942: 20 cd 09 				JSR		DELAYI			; delay a half bit
0945: 06					LD		A, S			; sample status
0946: d4 10					AND		A, =X'10		; select bit SA
0948: 7c f3					BNZ		GECO1			; still 1, no start bit yet, loop
094a: 39 fb					AND		S, =X'fb		; clear F2
094c: 3b 02					OR		S, =X'02   		; set F1 (echo bit inverted)
094e: 20 d5 09 	GECO2:		JSR		DELAYI2			; do a full bit delay
0951: 00					NOP						; wast some time
0952: 00					NOP
0953: 9d ff					DLD		A, TMPFE+1		; decrement bit count
0955: 6c 15					BZ		GECO3			; if done, exit
0957: 06					LD		A, S			; get status
0958: d4 10					AND		A, =X'10    	; select bit SA
095a: 3c					SR		A				; put bit into position 02 (for F1)
095b: 3c					SR		A
095c: 3c					SR		A
095d: cd f6					ST		A, TMPF6		; store into temporary 
095f: 3c					SR		A				; put bit into position 01
0960: 3f					RRL		A				; rotate into LINK
0961: 01					XCH		A, E  			; collect bit into E
0962: 3d					SRL		A				; by rotating LINK into E
0963: 01					XCH		A, E
0964: 06					LD		A, S			; get status
0965: dc 02					OR		A, =X'02		; preload bit 2 with 1
0967: e5 f6					XOR		A, TMPF6		; map in bit for F1 echo
0969: 07					LD		S, A			; put out bit
096a: 74 e2					BRA		GECO2			; loop
096c: 38 8    	GECO3:		POP		A				; restore old status
096d: d4 f9					AND		A, =X'f9		; clear F1, F2 (stop bits, reader relay)
096f: 07					LD		S, A			; emit bits
0970: 40					LD		A, E			; get byte received
0971: d4 7f					AND		A, =X'7f		; 7 bits only
0973: 48					LD		E, A			; save into E
0974: 5c					RET						; exit

;--------------------------------------------------------------------------------------------------
				; use external GET routine
0975: 84 f5 09	EXGET:		LD		EA, =(EXGET1-1)	; push return to caller on stack
0978: 08					PUSH	EA
0979: 82 01					LD		EA, 1, P2		; get address of routine X'FD01
097b: bd e8					SUB		EA, ONE   		; subtract 1
097d: 44 					LD		PC, EA			; jump indirect into routine

;--------------------------------------------------------------------------------------------------
				; emit a CRLF (call 8)
097e: c4 0d		CRLF:		LD		A, =CR			; load CR
0980: 17					CALL	7				; PUTC
0981: c4 0a					LD		A, =LF			; load LF
													; fall thru into PUTC
;--------------------------------------------------------------------------------------------------
				; emit the character in A (call 7)						
0983: 0a		PUTC:		PUSH 	A				; save A
0984: 22 00 fd				PLI 	P2, =BAUDFLG	; push P2 and load baud rate bits
0987: c2 00					LD		A, 0, P2		; get baud rate flag, here: bit 7
0989: 64 32					BP		EXPUTC   		; bit 7=0: goto external routines
098b: 5e					POP		P2				; restore P2
098c: 38					POP		A  		  		; restore char
098d: 0a					PUSH	A				; save it again
098e: 0e					SL 		A  		  		; shift left (7 bit), so low bit is in pos 2
													; note: 8th bit is ignored, and first bit to emit is now
													; in the correct position for flag F1
098f: 01					XCH		A, E    		; save current bits in E
0990: 06					LD		A, S			; get status
0991: 0a					PUSH	A				; save old state
0992: 39 fa					AND		S, =X'fa		; clear F2, IE
0994: 20 d3 09 				JSR		DELAYO			; do some delay (ensure two stop bits)
0997: 20 d3 09				JSR 	DELAYO			;
099a: 3b 02					OR		S, =X'02		; set F1 (start bit)
													; note inverse logic: start bit is 1
099c: c4 09					LD		A, =9			; set counter for 9 bits
099e: cd fb					ST		A, TMPFB		
09a0: 20 d3 09	PUTC1:		JSR		DELAYO			; wait a bit time
09a3: 9d fb    				DLD		A, TMPFB		; decrement bit count
09a5: 6c 10    				BZ		PUTC2			; is it zero?, yes skip
09a7: 40 					LD		A, E    		; get byte to emit
09a8: d4 02    				AND		A, =X'02		; extract bit to transfer
09aa: cd ff					ST		A, TMPFE+1		; save bit temporary
09ac: 40					LD		A, E			; get byte to emit
09ad: 3c 					SR		A    			; advance to next bit
09ae: 48					LD		E, A			; store back
09af: 06 					LD		A, S			; get status
09b0: dc 02					OR		A, =X'02    	; preload bit 2
09b2: e5 ff					XOR		A, TMPFE+1		; map in inverted data bit
09b4: 07					LD		S, A    		; put out bit at F1
09b5: 74 e9					BRA		PUTC1			; loop bits
09b7: 38    	PUTC2:		POP		A				; restore saved status
09b8: d4 f9					AND		A, =X'f9		; clear F2, F1 (stop bit)
09ba: 07					LD		S, A			; put out stop bit
09bb: 38					POP		A				; restore char to emit
09bc: 5c    				RET						; exit
;--------------------------------------------------------------------------------------------------
				; call external routine for PUTC
09bd: 82 03    	EXPUTC:		LD		EA, 3, P2		; get address at X'FD03
09bf: 46 					LD		P2, EA    		; into P2
09c0: 84 c7 09 				LD		EA, =(EXPUT1-1)	; address of return 
09c3: 08					PUSH	EA 				; save on stack (will be called on return)
09c4: c1 04					LD		A, 4, SP		; get char to emit from stack
09c6: 76 ff					BRA		ff, P2			; jump to external routine on stack
09c8: 5e		EXPUT1:		POP		P2    			; restore original P2
09c9: 38					POP A					; restore char to emit
09ca: 5c					RET						; return to caller

;--------------------------------------------------------------------------------------------------
				; some delay
09cb: 08     	DELAYC:		PUSH	EA				; save EA
09cc: 74 0b    				BRA		DELAY1			; skip into delay routine

;--------------------------------------------------------------------------------------------------
				; (half) delay for input
09ce: 08     	DELAYI:		PUSH	EA				; save EA
09cf: 85 ec    				LD		EA, DLYTIM		; get delay time
09d1: 0c     				SR		EA				; div /2
09d2: 74 05    				BRA		DELAY1			; skip into delay rountine
;--------------------------------------------------------------------------------------------------
				; delay for output
09d4: 01     	DELAYO:		XCH		A, E			; waste some time
09d5: 01 					XCH		A, E    		; waste some time
09d6: 08     	DELAYI2:	PUSH	EA				; save EA
09d7: 85 ec					LD		EA, DLYTIM		; get delay constant
09d9: bd e8		DELAY1:		SUB		EA, ONE			; subtract 1
09db: 7c fc					BNZ		DELAY1			; loop until xx00
09dd: 01					XCH		A, E			; is also 00xx?
09de: 6c 03					BZ		DELAY2			; yes exit
09e0: 01 					XCH		A, E			; put back high byte
09e1: 74 f6					BRA		DELAY1 			; loop
09e3: 3a		DELAY2:		POP		EA				; restore EA
09e4: 5c     				RET						; exit

;--------------------------------------------------------------------------------------------------
					; initialize the variable for baud rate
09e5: 22 00 fd	INITBD:		PLI 	P2, =BAUDFLG	; push P2 and load it with baudrate address
09e8: 85 ea    				LD		EA, ZERO		; clear EA
09ea: c2 00					LD		A, 0, P2		; get baud flags
09ec: d4 06					AND		A, =X'06    	; mask out bits 1/2
09ee: b4 f8 09				ADD		EA, =DLYTAB		; add base of DLY constants
09f1: 46 					LD		P2, EA   		; into P2
09f2: 82 00					LD		EA, 0, P2		; get constant
09f4: 8d ec					ST		EA, DLYTIM    	; store it in DLY constant word
09f6: 5e 		EXGET1:		POP		P2				; restore P2
09f7: 5c					RET						; exit
09f8: 04 00		DLYTAB:		DW		=X'0004			; delay for 4800bd
09fa: 2e 00					DW		=X'002e			; for 1200 bd
09fc: d5 00					DW		=X'00d5 		; for 300 bd
09fe: 52 02					DW		=X'0252			; for 110 bd

							END
