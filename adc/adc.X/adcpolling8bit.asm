; CONFIG1
; __config 0xF8F1
 __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
    
    
    LIST p=16F887
    INCLUDE <P16F887.INC>

; NOTA:
; Oscilador utilizado 4MHz.-
; ************************************************

EN_D0	EQU     0       ; Definimos Led como RE0
EN_D1	EQU     1       ; Definimos Led como RE1
    
RESULTHI	equ	0x20	; Registro para guardar Byte alto de la conversion.-
RESULTLO	equ	0x21	; Regsitro para guardar Byte bajo de la conversion.-
Contador	equ	0x22	; registro utilizado en demora.-
Contador1	equ 0x23
Contador2	equ 0x24
	
Hundred	equ 0x25
Tens	equ 0x26
Units	equ 0x27	
bin	equ 0x28
count8	equ 0x29
temp	equ 0x2A
	
	
; ************************************************
	org	0x00
	goto INIT
 ;**** Configurar el puerto****
INIT
	BSF 	STATUS,RP0	; Banco 1 -- BANKSEL ADCON1
	MOVLW	B'00000000'	; Justificado a la izquierda, VDD, VSS.-
	MOVWF	ADCON1		;Vdd and Vss as Vref
	BSF	TRISA,0		;Set RA0 to input
	CLRF	TRISE		;Set PORTE to output
	CLRF	TRISB		;Set PORTB to output
	CLRF	TRISD		;Set PORTD to output
	BCF	STATUS,RP0	; Banco 0  -- BANKSEL PORTE, ADCON0  ;
	MOVLW	B'01000001'	;Fosc/8, Canal 0, módulo habilitado.
	MOVWF	ADCON0		;AN0, On
	CLRF	PORTE
	CLRF	PORTB
	CLRF	PORTD
	BANKSEL ANSEL		;
	BSF	ANSEL,0		;Set RA0 to analog
	BCF	ANSEL,7		;Set RA7 to digital
	CLRF	ANSELH

	MOVLW d'25'
	MOVWF temp
	MOVLW d'25'
	SUBWF temp,0
	
	
	MOVLW B'10010111'
	MOVWF temp
	CALL CONVERT
	MOVWF RESULTHI
	GOTO RUN
	
RUN_ADC
	BANKSEL ADCON0
	CALL SampleTime		; Demora de adquision.-
	BSF ADCON0,GO		;Start conversion

WAIT_ACQ
	BTFSC	ADCON0,GO	; Espera a que termine conversion.-
	GOTO	WAIT_ACQ
	MOVF	ADRESH,W	; Movemos resultado de la conversion.-
	MOVWF	RESULTHI
	MOVWF	PORTB
	BSF	ADCON0,ADON	; Apago modulo de conversion.-
	;MOVF	RESULTHI,0
	MOVWF	temp
	CALL	CONVERT
	MOVWF	RESULTHI
	GOTO	RUN

SHOW
	BCF	STATUS,RP0
	BCF	STATUS,RP1
	BTFSC RESULTHI,0
	GOTO setl8
	BCF PORTE,2
	GOTO show_L9
setl8	
	BSF PORTE,2
show_L9	
	BTFSC RESULTHI,1
	GOTO setl9
	BCF PORTD,7
	GOTO fin_show
setl9	
	BSF PORTD,7
fin_show	
	RETURN
	
;**** Demora ****
SampleTime
	MOVLW 	0x05 ;
	MOVWF 	Contador ; Iniciamos contador1.-
Repeticion
	DECFSZ 	Contador,1 ; Decrementa Contador1.-
	GOTO 	Repeticion ; Si no es cero repetimos ciclo.-
	RETURN 
	
RUN
	MOVF RESULTHI,0
	MOVWF bin ; 0x20
	CALL Binary2BCD ; tens = 3 unit = 2
	CALL DISP_UPDATE_UNIT ; 2
	CALL DELAY_20MS
	CALL DISP_UPDATE_TENS; 3
	CALL DELAY_20MS
	GOTO RUN_ADC
	
CONVERT
	RRF temp,1
	BCF STATUS,0
	RRF temp,1
	BCF STATUS,0
	RRF temp,1
	BCF STATUS,0
	MOVF temp,0
	RRF temp,1
	BCF STATUS,0
	ADDWF temp,0
	RRF temp,1
	BCF STATUS,0
	RRF temp,1
	BCF STATUS,0
	RRF temp,1
	BCF STATUS,0
	ADDWF temp,0
	RETURN
	
;--------------------------------------------------------------------------
; DISPLAY 7 SEGMENTS
;--------------------------------------------------------------------------	
DISP_UPDATE_UNIT
	BCF PORTE,EN_D1 ;TURN OFF DIGIT 2.
	MOVF Units,0
	CALL SEVENSEG_LOOKUP
	; para anodo comun complemento (1 -> 0, 0 -> 1)
	MOVWF PORTD ;PUT DATA ON PORTB.
	BSF PORTE,EN_D0 ;TURN ON DIGIT 1.
	RETURN
	
DISP_UPDATE_TENS
	BCF PORTE,EN_D0 ;TURN OFF DIGIT 1.
	MOVF Tens,0
	CALL SEVENSEG_LOOKUP
	;para anodo comun complemento (1 -> 0, 0 -> 1)
	MOVWF PORTD ;PUT DATA ON PORTB.
	BSF PORTE,EN_D1 ;TURN ON DIGIT 2.
	RETURN
;--------------------------------------------------------------------------
; NUMBERIC LOOKUP TABLE FOR 7 SEG
;--------------------------------------------------------------------------
SEVENSEG_LOOKUP 
	ADDWF PCL,f
	RETLW 3Fh ; //Hex value to display the number 0. 0x40
	RETLW 06h ; //Hex value to display the number 1. 0x79
	RETLW 5Bh ; //Hex value to display the number 2.
	RETLW 4Fh ; //Hex value to display the number 3.
	RETLW 66h ; //Hex value to display the number 4.
	RETLW 6Dh ; //Hex value to display the number 5.
	RETLW 7Ch ; //Hex value to display the number 6.
	RETLW 07h ; //Hex value to display the number 7.
	RETLW 7Fh ; //Hex value to display the number 8.
	RETLW 6Fh ; //Hex value to display the number 9.
	RETURN
;--------------------------------------------------------------------------
; DELAY 20 MILLISECONDS
;--------------------------------------------------------------------------
DELAY_20MS
	movlw	0xFF			;
	movwf	Contador1		; Iniciamos contador1.-
Repeticion1
	movlw	0x19			;
	movwf	Contador2		; Iniciamos contador2
Repeticion2
	decfsz	Contador2,1		; Decrementa Contador2 y si es 0 sale.-
	goto	Repeticion2		; Si no es 0 repetimos ciclo.-
	decfsz	Contador1,1		; Decrementa Contador1.-
	goto	Repeticion1		; Si no es cero repetimos ciclo.-
	return				; Regresa de la subrutina.-

;--------------------------------------------------------------------------
; CONVERTER BINARY TO BCD
;--------------------------------------------------------------------------
Binary2BCD
	clrf		Hundred
	clrf		Tens
	clrf		Units
	movlw		0x08
	movwf		count8
	; check if bin is zero	
	movlw		0x00
	addwf		bin, f
	btfsc		STATUS, Z
	goto		endBinary2BCD
startconversion	
	; rotate MSB from bin into Units
	bcf		STATUS, C
	rlf		bin, f
	rlf		Units, f
	; check if a carry happened to 5th bit of Units 
	; helps to move the carry from nibble to a different byte
	btfss		Units, 0x04
	goto		RotateZeroIntoTen
	bsf		STATUS, C
	rlf		Tens, f
	goto		completeUnitCarry	
RotateZeroIntoTen
	bcf		STATUS, C
	rlf		Tens, f
completeUnitCarry	
	bcf		Units, 0x04
	; check if a carry happend to the 5th bit of Tens
	; helps to move the carry from nibble to a different byte
	btfss		Tens, 0x04
	goto		RotateZeroIntoHun
	bsf		STATUS, C
	rlf		Hundred, f
	goto		completeTenCarry	
RotateZeroIntoHun
	bcf		STATUS, C
	rlf		Hundred, f
completeTenCarry	
	bcf		Tens, 0x04
	decfsz		count8,f
	goto		continue
	goto		endBinary2BCD
continue
	; check if you need to add 3 to Units if it is greater or equal to 5
	movf		Units, w
	movwf		temp
	movlw		0x05
	subwf		temp, f
	btfss		STATUS, C
	goto		AfterAdding3
	movf		Units, w
	addlw		0x03
	movwf		Units
AfterAdding3	
	; check if you need to add 3 to Tens if it is greater or equal to 5
	movf		Tens, w
	movwf		temp
	movlw		0x05
	subwf		temp, f
	btfss		STATUS, C
	goto		AfterAdding_3
	movf		Tens, w
	addlw		0x03
	movwf		Tens
AfterAdding_3	
	goto		startconversion
endBinary2BCD	
	return

	
	end



