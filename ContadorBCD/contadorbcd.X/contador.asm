; CONFIG1
; __config 0xF8F1
 __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
    
    
    LIST p=16F887
    INCLUDE <P16F887.INC>

Boton_asc	EQU     0       ; Definimos Led como RB0
Boton_dsc	EQU     1       ; Definimos Led como RB1
Switch_activar	EQU     2       ; Definimos Led como RB2
    

Contador1	EQU 0x20
Contador2	EQU 0x21
DISP_COUNTER	EQU 0x22
DISP_DEFAULT	EQU 0x23
DISP_FREQ	EQU 0x24

Hundred	EQU 0x25
Tens	EQU 0x26
Units	EQU 0x27	
bin	EQU 0x28
count8	EQU 0x29
temp	EQU 0x2A
 
    ORG 0x00 ; Inicio de programa
    goto INIT
 ;**** Configurar el puerto****
INIT
	bsf STATUS,RP0 ; Cambia al Banco 1
	movlw 00h ; Configura los pines del puerto D ...
	movwf TRISD ; ...como salidas.
	movwf TRISA ; ...como salidas.
	movlw	b'00000111'        ; Cargamos b'00000111' en W
	movwf	TRISB           ; Cargamos W en TRISA, RA0 como entrada
	
	BSF STATUS,RP1 ; Accede a banco 3
	CLRF ANSEL  ; 
	CLRF ANSELH ;
	BCF STATUS,RP0 ; Regresa a banco 0 RP0 = 0
	BCF STATUS,RP1 ; Regresa a banco 0 RP1 = 0
	
	movlw 00h ; Configura nuestro registro w con 00h
	movwf PORTD ; ...como salidas.
	movwf PORTA ; ...como salidas.
	movlw 20h ; Configura nuestro registro w con 02h
	movwf DISP_FREQ
	movlw 20h ; Configura nuestro registro w con 02h
	movwf DISP_DEFAULT
	movwf DISP_COUNTER
	MOVWF bin ; 0x20
	CALL Binary2BCD ; tens = 3 unit = 2 
MAIN
	btfss PORTB,Switch_activar	    ; Esta pulsado el Boton (RA0=1??)
	GOTO RUN
	GOTO SETTING
RUN
	CALL DISP_UPDATE_UNIT ; 2
	CALL DELAY_20MS
	CALL DISP_UPDATE_TENS; 3
	CALL DELAY_20MS
	DECFSZ DISP_FREQ
	GOTO MAIN
	DECFSZ DISP_COUNTER,F ;0x1f = 31 decimal
	GOTO INIT_FREQ
	CALL INIT_COUNTER
INIT_FREQ
	MOVF DISP_COUNTER,0
	MOVWF bin ; 0x20
	CALL Binary2BCD ; tens = 3 unit = 2 
	movlw 20h ; Configura nuestro registro w con 02h
	movwf DISP_FREQ
	GOTO MAIN

;--------------------------------------------------------------------------
; INITIALIZE COUNTER
;--------------------------------------------------------------------------	

INIT_COUNTER
	movf DISP_DEFAULT,0 ; Muevo el valor por defecto al registro W
	movwf DISP_COUNTER  ; cargo el valor del registro W al Contador
	RETURN

;********** R U T I N A * T E S T E O ******************************************
SETTING
	CALL UPDATE_BTN_ASC
	CALL UPDATE_BTN_DSC
	CALL INIT_COUNTER
	MOVF DISP_COUNTER,0
	MOVWF bin ; 0x20
	CALL Binary2BCD ; tens = 3 unit = 2
	CALL DISP_UPDATE_UNIT ; 2
	CALL DELAY_20MS
	CALL DISP_UPDATE_TENS; 3
	CALL DELAY_20MS
	
	GOTO INIT_FREQ
	
	
UPDATE_BTN_ASC
	btfss	PORTB,Boton_asc	    ; Esta pulsado el Boton (RA0=1??)
	goto	END_BTN_ASC	    ; No??, seguimos testeando
	call	DELAY_20MS        ; Si??, Eliminamos efecto rebote
	btfss	PORTB,Boton_asc	    ; Testeamos nuevamente
	goto	END_BTN_ASC	    ; Falsa Alarma, seguimos testeando
	incf	DISP_DEFAULT,1   ; Se ha pulsado, incrementamos Valor Default
RELEASE_BTN_ASC
	btfsc	PORTB,Boton_asc         ; Boton se dejo de pulsar??
	goto	RELEASE_BTN_ASC	    ; No??, PCL - 1, --> btfsc PORTA,Boton
	call    DELAY_20MS		; Si??, Eliminamos efecto rebote
	btfsc	PORTB,Boton_asc         ; Testeamos nuevamente si se dejo de pulsar
	goto	RELEASE_BTN_ASC                ; No??, Falsa alarma, volvemos a checar
	goto	END_BTN_ASC	    ; Falsa Alarma, seguimos testeando
	
END_BTN_ASC
	RETURN

UPDATE_BTN_DSC
	btfss	PORTB,Boton_dsc	    ; Esta pulsado el Boton (RA0=1??)
	goto	END_BTN_DSC	    ; No??, seguimos testeando
	call	DELAY_20MS        ; Si??, Eliminamos efecto rebote
	btfss	PORTB,Boton_dsc	    ; Testeamos nuevamente
	goto	END_BTN_DSC	    ; Falsa Alarma, seguimos testeando
	decf	DISP_DEFAULT,1   ; Se ha pulsado, incrementamos Valor Default
RELEASE_BTN_DSC
	btfsc	PORTB,Boton_dsc         ; Boton se dejo de pulsar??
	goto	RELEASE_BTN_DSC	    ; No??, PCL - 1, --> btfsc PORTA,Boton
	call    DELAY_20MS		; Si??, Eliminamos efecto rebote
	btfsc	PORTB,Boton_dsc         ; Testeamos nuevamente si se dejo de pulsar
	goto	RELEASE_BTN_DSC                ; No??, Falsa alarma, volvemos a checar
	goto	END_BTN_DSC	    ; Falsa Alarma, seguimos testeando

END_BTN_DSC
	RETURN
	
   
;--------------------------------------------------------------------------
; DISPLAY 7 SEGMENTS
;--------------------------------------------------------------------------	
DISP_UPDATE_UNIT
	BCF PORTA,0 ;TURN OFF DIGIT 2.
	MOVF Units,0
	CALL SEVENSEG_LOOKUP
	; para anodo comun complemento (1 -> 0, 0 -> 1)
	MOVWF PORTD ;PUT DATA ON PORTB.
	BSF PORTA,1 ;TURN ON DIGIT 1.
	RETURN
	
DISP_UPDATE_TENS
	BCF PORTA,1 ;TURN OFF DIGIT 1.
	MOVF Tens,0
	CALL SEVENSEG_LOOKUP
	;para anodo comun complemento (1 -> 0, 0 -> 1)
	MOVWF PORTD ;PUT DATA ON PORTB.
	BSF PORTA,0 ;TURN ON DIGIT 2.
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
;**** Final del programa ****