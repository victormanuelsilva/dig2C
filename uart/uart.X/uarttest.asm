; CONFIG1
; __config 0xF8F1
 __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
    
    
    LIST p=16F887
    INCLUDE <P16F887.INC>

numpasajeros equ 0x20
Contador1	equ 0x23
Contador2	equ 0x24

Hundred	equ 0x25
Tens	equ 0x26
Units	equ 0x27	
bin	equ 0x28
count8	equ 0x29
temp	equ 0x2A
	
; NOTA:
; Oscilador utilizado 4MHz.-
; ************************************************

; ------------------------------Código modificado-------------------------------------
; inicio
          org     0x00
          goto    inicio
          org     0x04
          goto    INTER

; Se transmite via Serie el dato que esta en el registro W
TX_DATO   bcf     PIR1,TXIF      ; Restaura el flag del transmisor
          movf numpasajeros,w
	  movwf   TXREG          ; Mueve el byte a transmitir al registro de transmision
          bsf     STATUS,RP0     ; Bank01
          bcf     STATUS,RP1

TX_DAT_W  btfss   TXSTA,TRMT     ; ¿Byte transmitido?
          goto    TX_DAT_W       ; No, esperar
          bcf     STATUS,RP0     ; Si, vuelta a Bank00
          return

; Tratamiento de interrupción
INTER     btfss   PIR1,RCIF      ; ¿Interrupción por recepción?
          goto    VOLVER         ; No, falsa interrupción
          bcf     PIR1,RCIF      ; Si, reponer flag
          movf    RCREG,W        ; Lectura del dato recibido
          movwf   PORTB          ; Visualización del dato
          call    TX_DATO        ; Transmisión del dato como eco
VOLVER    retfie

; Comienzo del programa principal
inicio    clrf    PORTB          ; Limpiar salidas
          clrf    PORTC
          bsf     STATUS,RP0     ; Bank01
          bcf     STATUS,RP1
          clrf    TRISB          ; PORTB como salida
          movlw   b'10111111'    ; RC7/RX entrada,
          movwf   TRISC          ; RC6/TX salida
          movlw   b'00100100'    ; Configuración USART
          movwf   TXSTA          ; y activación de transmisión
          movlw   .25            ; 9600 baudios
          movwf   SPBRG
          bsf     PIE1,RCIE      ; Habilita interrupción en recepción
          bcf     STATUS,RP0     ; Bank00
          movlw   b'10010000'    ; Configuración del USART para recepción continua
          movwf   RCSTA          ; Puesta en ON
          movlw   b'11000000'    ; Habilitación de las
          movwf   INTCON         ; interrupciones en general

BUCLE     nop
	  ;nit = 2
	  ;nit + 0x30
	  movlw 0x32; numero 2 en ascii
	  CALL TX_DATO1
	  CALL DELAY_20MS
	  ;ens = 3
	  ;ens + 0x30
	  movlw 0x33; numero 3 en acii
	  CALL TX_DATO1
	  CALL DELAY_20MS
	  movlw 0x0A;numero \r
	  CALL TX_DATO1
	  CALL DELAY_20MS
	  movlw 0x0d;numero \n
	  CALL TX_DATO1
	  CALL DELAY_20MS
	  CALL DELAY_20MS
	  CALL DELAY_20MS
	  CALL DELAY_20MS
	  CALL DELAY_20MS
	  CALL DELAY_20MS
	  goto    BUCLE

TX_DATO1  bcf     PIR1,TXIF      ; Restaura el flag del transmisor
	  ;movwf numpasajeros
	  ;movf numpasajeros,w
	  movwf   TXREG          ; Mueve el byte a transmitir al registro de transmision
          bsf     STATUS,RP0     ; Bank01
          bcf     STATUS,RP1

TX_DAT_1  btfss   TXSTA,TRMT     ; ¿Byte transmitido?
          goto    TX_DAT_W       ; No, esperar
          bcf     STATUS,RP0     ; Si, vuelta a Bank00
          return
	  
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




