KEYIN		EQU		0616H      ;ND80 MONITOR
LEDREG		EQU		0FFECH     ;ND80 MONITOR
RGDSP		EQU		05A1H      ;ND80 MONITOR
SHIFT		EQU		05B5H      ;ND80 MONITOR
MONST_8		EQU		08A4H      ;ND8080
MONST_Z		EQU		088EH      ;ND80Z3
KEYIN_TK	EQU		0216H      ;TK80 MONITOR
LEDREG_TK	EQU		83ECH      ;TK80 MONITOR
RGDSP_TK	EQU		01A1H      ;TK80 MONITOR
SHIFT_TK	EQU		01B5H      ;TK80 MONITOR
MONST_TK	EQU		0051H      ;TK80 MONITOR
FNAME		EQU		0FFE6H
SADRS		EQU		0FFE8H
EADRS		EQU		0FFEAH
MIN_TK		EQU		7C39H      ;TK80 WORK -(83C7H)
MAX_TK		EQU		7C00H      ;TK80 WORK -(83FFH+1)
MIN_TK2		EQU		0048H      ;TK80 WORK -(FFB8H)
MIN_ND		EQU		0800H      ;ND80 WORK -(F800H)

;82H PORTC Bit
;7 IN  CHK
;6 IN
;5 IN  受信データ
;4 IN 
;3 OUT
;2 OUT FLG
;1 OUT
;0 OUT 送信データ

;ROM使用可能範囲
;ND8080 ROM1H
;ND80Z3 ROM4K
;0E80H～0FFBH、1785H～17FFH、1EABH～1EFFH

;		位置合わせ
		ORG		0000H
		DB		0FFH
		
;		TK80 MONITOR用JUMP TABLE
		ORG		0080H
		DW		SDSAVE         ;STORE
		DW		SDLOAD         ;LOAD
		
;		ND80Z3 ND MINOTOR用JUMP TABLE
		ORG		08F7H
		DW		SDSAVE3        ;PR(～OD)
		DW		SDSAVE         ;SO
		DW		SDLOAD         ;SI

;		ND8080 ND MONITOR用JUMP TABLE
		ORG		090DH
		DW		SDSAVE3        ;PR(～OD)
		DW		SDSAVE         ;SO
		DW		SDLOAD         ;SI

       ORG		0E80H

;		JP		SDLOAD
;		JP		SDSAVE
;		JP		SDSAVE3

;受信ヘッダ情報をセットし、SDカードからLOAD実行
;FNAME <- 0000H～FFFFHを入力。
;         ファイルネームは「xxxx.BTK」となる。
SDLOAD:	CALL	INIT
		LD		A,81H
		CALL	SNDBYTE    ;LOADコマンド81Hを送信
		CALL	RCVBYTE    ;状態取得(00H=OK)
		AND		A          ;00以外ならERROR
		JP		NZ,SVERR
		LD		HL,FNAME   ;FNAME <- LEDREG
		IN		A,(94H)
		AND		80H        ;TK80、ND80分岐
		JP		NZ,TKMODE5
		LD		DE,LEDREG
		JP		TKMD5
TKMODE5:LD		DE,LEDREG_TK
TKMD5:	LD		A,(DE)     ;FNAME取得
		LD		(HL),A
		INC		HL
		INC		DE
		LD		A,(DE)
		LD		(HL),A
		LD		HL,FNAME   ;FNAME送信
		LD		A,(HL)
		CALL	SNDBYTE
		INC		HL
		LD		A,(HL)
		CALL	SNDBYTE
		CALL	RCVBYTE    ;状態取得(00H=OK)
		AND		A          ;00以外ならERROR
		JP		NZ,SVERR
		CALL	HDRCV      ;ヘッダ情報受信
		CALL	DBRCV      ;データ受信
		JP		SDSV3      ;LOAD情報表示

;送信ヘッダ情報をセットし、SDカードへSAVE実行
;FNAME <- 0000H～FFFFHを入力。
;         ファイルネームは「xxxx.BTK」となる。
;SADRS <- 保存開始アドレス(8000H固定)
;EADRS <- 保存終了アドレス(83C6H固定)

SDSAVE:	LD		HL,SADRS
		LD		(HL),00H
		INC		HL
		LD		(HL),80H   ;SADRS <- 8000H
		INC		HL         ;HL <- EADRS
		LD		(HL),0C6H
		INC		HL
		LD		(HL),083H  ;EADRS <- 83C6H
		CALL	INIT
SDSAVE2:
		LD		A,80H
		CALL	SNDBYTE    ;SAVEコマンド80Hを送信
		CALL	RCVBYTE    ;状態取得(00H=OK)
		AND		A          ;00以外ならERROR
		JP		NZ,SVERR
		LD		HL,FNAME   ;FNAME <- LEDREG
		IN		A,(94H)
		AND		80H        ;TK80、ND80分岐
		JP		NZ,TKMODE4
		LD		DE,LEDREG
		JP		TKMD4
TKMODE4:LD		DE,LEDREG_TK
TKMD4:	LD		A,(DE)     ;FNAME取得
		LD		(HL),A
		INC		HL
		INC		DE
		LD		A,(DE)
		LD		(HL),A
		CALL	HDSEND     ;ヘッダ情報送信
		CALL	RCVBYTE    ;状態取得(00H=OK)
		AND		A          ;00以外ならERROR
		JP		NZ,SVERR
		CALL	DBSEND     ;データ送信
SDSV3:	CALL	OKDSP      ;SAVE情報表示
MONRET:	IN		A,(94H)
		AND		80H        ;TK80、ND80分岐
		JP		NZ,MONST_TK;MONITOR復帰(TK80)
		LD		HL,MONST_Z
		LD		A,(HL)
		CP		3EH        ;ND80 MODEの時にはND8080を識別
		JP		NZ,MONST_8 ;MONITOR復帰(ND8080)
		JP		MONST_Z    ;MONITOR復帰(ND80Z3)

;送信ヘッダ情報をセットし、SDカードへSAVE実行。SAVE範囲指定
;SADRS <- 保存開始アドレス(LED ADRS 表示)
;EADRS <- 保存終了アドレス(LED DATA 表示)
;FNAME <- 0000H～FFFFHを入力。
;         ファイルネームは「xxxx.BTK」となる。

SDSAVE3:CALL	INIT
		LD		HL,EADRS   ;EADRS <- LEDREG
		LD		DE,LEDREG
		LD		A,(DE)
		LD		(HL),A
		INC		HL
		INC		DE
		LD		A,(DE)
		LD		(HL),A
		LD		HL,SADRS   ;SADRS <- LEDREG
		INC		DE
		LD		A,(DE)
		LD		(HL),A
		INC		HL
		INC		DE
		LD		A,(DE)
		LD		(HL),A
		CALL	KEYIN4     ;LEDREG <- KEYIN4
		JP		SDSAVE2

SVERR:	CALL	ERRDSP     ;FFH:FILE OPEN ERROR F0H:SDカード初期化ERROR
		JP		MONRET     ;F1H;FILE存在ERROR

;ヘッダ送信
HDSEND:	LD		B,06H
		LD		HL,FNAME   ;FNAME送信、SADRS送信、EADRS送信
HDSD1:	LD		A,(HL)
		CALL	SNDBYTE
		INC		HL
		DEC		B
		JP		NZ,HDSD1
		RET

;データ送信
;SADRSからEADRSまでを送信
DBSEND:	LD		HL,(EADRS)
		EX		DE,HL
		LD		HL,(SADRS)
DBSLOP:	LD		A,(HL)
		CALL	SNDBYTE
		LD		A,H
		CP		D
		JP		NZ,DBSLP1
		LD		A,L
		CP		E
		JP		Z,DBSLP2   ;HL = DE までLOOP
DBSLP1:	INC		HL
		JP		DBSLOP
DBSLP2:	RET

;SAVE、LOAD正常終了ならSADRS、EADRSをLEDに表示
OKDSP:
		IN		A,(94H)
		AND		80H        ;TK80、ND80分岐
		JP		NZ,TKMODE6
		LD		HL,LEDREG
		JP		TKMD6
TKMODE6:LD		HL,LEDREG_TK
TKMD6:	LD		DE,EADRS  ;LEDREG <- EADRS
		LD		A,(DE)
		LD		(HL),A
		INC		DE
		INC		HL
		LD		A,(DE)
		LD		(HL),A
		INC		HL
		LD		DE,SADRS  ;LEDREG+2 <- SADRS
		LD		A,(DE)
		LD		(HL),A
		INC		DE
		INC		HL
		LD		A,(DE)
		LD		(HL),A
OKDSP2:	IN		A,(94H)
		AND		80H        ;TK80、ND80分岐
		JP		NZ,TKMODE2
		CALL	RGDSP      ;LED表示更新
		RET
TKMODE2:CALL	RGDSP_TK
		RET

;ヘッダ受信
HDRCV:	LD		HL,SADRS+1 ;SADRS取得
		CALL	RCVBYTE
		LD		(HL),A
		DEC		HL
		CALL	RCVBYTE
		LD		(HL),A
		LD		HL,EADRS+1 ;EADRS取得
		CALL	RCVBYTE
		LD		(HL),A
		DEC		HL
		CALL	RCVBYTE
		LD		(HL),A
		RET

;データ受信
DBRCV:	LD		HL,(EADRS)
		EX		DE,HL
		LD		HL,(SADRS)
DBRLOP:	CALL	RCVBYTE
		LD		B,A
		CALL	JOGAI     ;WORKエリアを識別してSKIP
		AND		A
		JP		NZ,SKIP
		LD		A,B
		LD		(HL),A
SKIP:	LD		A,H
		CP		D
		JP		NZ,DBRLP1
		LD		A,L
		CP		E
		JP		Z,DBRLP2   ;HL = DE までLOOP
DBRLP1:	INC		HL
		JP		DBRLOP
DBRLP2:	RET
		
;SAVE、LOADエラー終了処理(F0H又はFFHをLEDに表示)
ERRDSP: PUSH	AF
		IN		A,(94H)
		AND		80H        ;TK80、ND80分岐
		JP		NZ,TKMODE7
		LD		HL,LEDREG
		JP		TKMD7
TKMODE7:LD		HL,LEDREG_TK
TKMD7:	POP		AF
		LD		(HL),A
		INC		HL
		LD		(HL),A
		INC		HL
		LD		(HL),A
		INC		HL
		LD		(HL),A
		JP		OKDSP2

		ORG		1790H

;1BYTE受信
;受信DATAをAレジスタにセットしてリターン
RCVBYTE:PUSH 	BC
		LD		C,00H
		LD		B,08H
RBLOP1:	CALL	RCV1BIT    ;1BIT受信
		AND		A          ;A=0?
		LD		A,C
		JP		Z,RBRES    ;0
RBSET:	INC		A          ;1
RBRES:	RRCA               ;Aレジスタ右SHIFT
		LD		C,A
		DEC		B
		JP		NZ,RBLOP1  ;8BIT分LOOP
		LD		A,C        ;受信DATAをAレジスタへ
		POP		BC
		RET
		
;1BYTE送信
;Aレジスタの内容を下位BITから送信
SNDBYTE:PUSH 	BC
		LD		B,08H
SBLOP1:	RRCA               ;最下位BITをCフラグへ
		PUSH	AF
		JP		NC,SBRES   ;Cフラグ = 0
SBSET:	LD		A,01H      ;Cフラグ = 1
		JP		SBSND
SBRES:	LD		A,00H
SBSND:	CALL	SND1BIT    ;1BIT送信
		POP		AF
		DEC		B
		JP		NZ,SBLOP1  ;8BIT分LOOP
		POP		BC
		RET
		
;1BIT送信
;Aレジスタ(00Hor01H)を送信する
SND1BIT:
		OUT		(83H),A    ;PORTC BIT0 <- A(00H or 01H)
		LD		A,05H
		OUT		(83H),A    ;PORTC BIT2 <- 1
		CALL	F1CHK      ;PORTC BIT7が1になるまでLOOP
		LD		A,04H
		OUT		(83H),A    ;PORTC BIT2 <- 0
		CALL	F2CHK
		RET
		
;WORKエリアを識別
;TK80 MODE (83C7H～83FFH、FFB8H～FFFFHはSKIP)
;ND MODE   (F800H～FFFFHはSKIP)
JOGAI:		PUSH	HL
			PUSH	DE
			EX		DE,HL
			IN		A,(94H)
			AND		80H        ;TK80、ND80分岐
			JP		Z,JOGAI_ND
JOGAI_TK:	LD		HL,MIN_TK
			ADD		HL,DE
			JP		NC,JGOK    ;MIN未満ならOK
			LD		HL,MAX_TK
			ADD		HL,DE
			JP		NC,JGERR   ;MAX未満ならSKIP
			LD		HL,MIN_TK2
			JP		JG01
JOGAI_ND:	LD		HL,MIN_ND
JG01:		ADD		HL,DE
			JP		NC,JGOK    ;MIN未満ならOK
JGERR:		LD		A,01H      ;SKIP範囲ならAレジスタ=1
			JP		JGRTN
JGOK:		XOR		A          ;OKならAレジスタ=0
JGRTN:		POP		DE
			POP		HL
			RET

		ORG		1EB0H

;1BIT受信
;受信BITをAレジスタに保存してリターン
RCV1BIT:CALL	F1CHK      ;PORTC BIT7が1になるまでLOOP
		LD		A,05H
		OUT		(83H),A    ;PORTC BIT2 <- 1
		IN		A,(82H)    ;PORTC BIT5
		AND		20H
		RRCA
		RRCA
		RRCA
		RRCA
		RRCA               ;右5回SHIFT
		PUSH	AF
		CALL	F2CHK      ;PORTC BIT7が0になるまでLOOP
		LD		A,04H
		OUT		(83H),A    ;PORTC BIT2 <- 0
		POP		AF         ;受信DATAセット
		RET
		
;BUSYをCHECK(1)
; 82H BIT7が1になるまでLOP
F1CHK:	IN		A,(82H)
		AND		80H        ;PORTC BIT7 = 1?
		JP		Z,F1CHK
		RET

;BUSYをCHECK(0)
; 82H BIT7が0になるまでLOOP
F2CHK:	IN		A,(82H)
		AND		80H        ;PORTC BIT7 = 0?
		JP		NZ,F2CHK
		RET

;4桁をキー入力
;任意範囲セーブ時FNAME取得用
;ND MODE時のみ使用
KEYIN4:		LD		B,04H
KI4LP1:		PUSH	BC
MODE1:		CALL	KEYIN
			LD		B,A
MODE13:		CALL	SHIFT
MODE8:		LD		A,(LEDREG)
			OR		B
MODE9:		LD		(LEDREG),A
MODE12:		CALL	RGDSP
			POP		BC
			DEC		B
			JP		NZ,KI4LP1
			RET

;8255初期化
;PORTC下位BITをOUTPUT、上位BITをINPUT
INIT:	LD		A,88H
		OUT		(83H),A
;出力BITをリセット
INIT2:	LD		A,00H      ;PORTC <- 0
		OUT		(82H),A
		RET
		
		END
