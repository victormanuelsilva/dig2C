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
    
    
;**** Definicion de variables ****
Contador	equ	0x20	; Contador para detectar 4 desbordes de TMR0.-
W_Temp		equ	0x21	; Registro para guardar temporalmente W.-
STATUS_Temp	equ	0x22	; Registro para guardar temporalmente STATUS
Led		equ	0	; Definimos Led como el bit cero de un registro, en este caso PORTB.-
; ************************************************
;**** Inicio del Micro ****
	org	0x00		; Aquí comienza el micro.-
	goto	Inicio		; Salto a inicio de mi programa.-
;**** Vector de Interrupcion ****
	org	0x04		; Atiendo Interrupcion.-
	goto	Inicio_ISR

; **** Programa Principal ****
;**** Configuracion de puertos ***
	org	0x05		; Origen del código de programa.-
Inicio
	bsf	STATUS,RP0 	; Pasamos de Banco 0 a Banco 1.-
	movlw	b'11111110'	; RB0 como salida.-
	movwf	TRISB
	movlw	b'00000111'	; Se selecciona TMR0 modo temporizador y preescaler de 1/256.-
	movwf	OPTION_REG
	bcf	STATUS,RP0	; Paso del Banco 1 al Banco 0
	bcf	PORTB,Led	; El Led comienza apagado.-
	movlw	0x3D		; Cargamos 61 en TMR0 para lograr aprox. 50ms.-
	movwf	TMR0
	clrf	Contador	; Iniciamos contador.-
	movlw	b'10100000'	; Habilitamos GIE y T0IE (interrupción del TMR0)
	movwf	INTCON
;**** Bucle ****
Bucle
	nop			; Aqui el micro puede ejecutar cualquier otra tarea
	goto	Bucle		; sin necesidad de utilizar tiempo en un bucle de demora.-

;**** Rutina de servicio de Interrupcion ****

;---&gt; Aqui haremos copia de respaldo para mostrar como se hace aunque no es
; necesario ya que el micro no hace otra tarea mientras tanto &lt;---

;  Guardado de registro W y STATUS.-
Inicio_ISR
	movwf	W_Temp	; Copiamos W a un registro Temporario.-
	swapf	STATUS, W	;Invertimos los nibles del registro STATUS.-
	movwf	STATUS_Temp	; Guardamos STATUS en un registro temporal.-
;**** Interrupcion por TMR0 ****
ISR
	btfss	INTCON,T0IF	; Consultamos si es por TMR0.-
	goto	Fin_ISR		; No, entonces restauramos valores.-
	incf	Contador	; Si, Incrementamos contador
	movlw	0x04		; Consultamos si se han producido 4 desbordes
	subwf	Contador,0	; para obtener 200 ms.-
	btfss	STATUS,Z	;
	goto	Actualizo_TMR0	; No, cargo TMR0 si salgo.-
	clrf	Contador	; Si, reseteo Contador y controlo Led.-
	btfss	PORTB,Led	; Si esta apagado, prendo y viseversa.-
	goto	Prendo_led
	bcf	PORTB,Led	; Apago Led.-
Actualizo_TMR0			; Actualizo TMR0 para obtener una temporizacion de 50 ms.-
	movlw	0x3D		; d'61'
	movwf	TMR0
	bcf	INTCON,T0IF	; Borro bandera de control de Interrupcion.-
	goto	Fin_ISR		; Restauro valores.-
Prendo_led
	bsf	PORTB,Led	; prendo Led.-
	goto	Actualizo_TMR0
; Restauramos los valores de W y STATUS.-
Fin_ISR
	swapf	STATUS_Temp,W	; Invertimos lo nibles de STATUS_Temp.-
	movwf	STATUS
	swapf	W_Temp, f	; Invertimos los nibles y lo guardamos en el mismo registro.-
	swapf W_Temp,W	; Invertimos los nibles nuevamente y lo guardamos en W.-
	retfie			; Salimos de interrupción.-
;..........................................

	end