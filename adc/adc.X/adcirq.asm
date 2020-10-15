;El módulo convertidor ADC. Interrupción trás la conversión. Voltímetro digital
;
;Este ejemplo visualiza sobre la pantalla LCD el valor obtenido por el convertidor a partir
;de una tensión analógica de entrada de entre 0 y 5Vcc que se aplica por la entrada RA0/AN0.
;A lo que indique el LCD se le debe multiplicar 0.004887 (resolución/bit) para obtener la
;tensión de entrada en RA0/AN0.

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

	cblock    0x20            ;Inicio de variables de la aplicación
	    Byte_L                ;Parte baja del byte a convertir
            Byte_H                ;Parte alta del byte a convertir
            BCD_2                ;Byte 2 de conversión a BCD
            BCD_1                ;Byte 1 de conversión a BCD
            BCD_0                ;Byte 0 de conversión a BCD
            Contador            ;Variable de contaje
            Temporal
            Temporal_1
            Temporal_2            ;Variables temporales
        endc

        org    0x00
        goto   Inicio        ;Vector de reset
        org    0x04
        goto   Inter        ;Vector de interrupción
        org    0x05

;****************************************************************************************
;Inter: Programa de tratamiento de interrupción cuando finaliza una conversión. Lee el
;resultado, lo convierte a BCD y lo visualiza sobre la pantalla LCD
Inter   movf   ADRESH,W
        movwf   Byte_H
        bsf     STATUS,RP0        ;Banco 1
        movf    ADRESL,W
        bcf     STATUS,RP0        ;Banco 0
        movwf   Byte_L            ;Lee y salva el resultado de la conversión
        call    Bits16_BCD        ;Convierte a BCD
        movlw   0x84
        bsf     ADCON0,GO_DONE    ;Inicia una nueva conversión
        retfie

;16Bits_BCD: Esta rutina convierte un número binario de 16 bits situado en Cont_H y
;Cont_L y, lo convierte en 5 dígitos BCD que se depositan en las variables BCD_0, BCD_1
;y BCD_2, siendo esta última la de menos peso.
;Está presentada en la nota de aplicación AN544 de MICROCHIP y adaptada por MSE
Bits16_BCD      bcf     STATUS,C
                clrf    Contador
                bsf     Contador,4        ;Carga el contador con 16
                clrf    BCD_0
                clrf    BCD_1
                clrf    BCD_2            ;Puesta a 0 inicial

Loop_16         rlf     Byte_L,F
                rlf     Byte_H,F
                rlf     BCD_2,F
                rlf     BCD_1,F
                rlf     BCD_0,F            ;Desplaza a izda. (multiplica por 2)
                decfsz  Contador,F
                goto    Ajuste
                return

Ajuste          movlw   BCD_2
                movwf   FSR                ;Inicia el índice
                call    Ajuste_BCD        ;Ajusta el primer byte
                incf    FSR,F
                call    Ajuste_BCD        ;Ajusta el segundo byte
                incf    FSR,F
                call    Ajuste_BCD
                goto    Loop_16

Ajuste_BCD      movf    INDF,W
                addlw   0x03
                movwf   Temporal
                btfsc   Temporal,3        ;Mayor de 7 el nibble de menos peso ??
                movwf   INDF            ;Si, lo acumula
                movf    INDF,W
                addlw   0x30
                movwf   Temporal
                btfsc   Temporal,7        ;Mayor de 7 el nibble de menos peso ??
                movwf   INDF            ;Si, lo acumula
                return

;Programa principal
Inicio          clrf    PORTA
                clrf    PORTB            ;Borra salidas
                bsf     STATUS,RP0
                bsf     STATUS,RP1        ;Banco 3
                movlw   b'00000001'
                movwf   ANSEL            ;RA0/AN0/C12IN0- entrada analógica, resto digitales
                clrf    ANSELH            ;Puerta B digital
                bcf     STATUS,RP1        ;Banco 1
                clrf    TRISB            ;Puerta B se configura como salida
                movlw   b'11110001'
                movwf   TRISA            ;RA3:RA1 salidas
                bcf     STATUS,RP0        ;Selecciona banco 0

;Se activa el ADC y se selecciona el canal RA0/AN0.    Frec. de conversión = Fosc/32
                bsf     STATUS,RP0        ;Selecciona página 1
                movlw   b'10000000'
                movwf   ADCON1            ;Alineación dcha. Vref= VDD
                bcf     STATUS,RP0        ;Selecciona página 0
                movlw   b'10000001'
                movwf   ADCON0            ;ADC en On, seleciona canal RA0/AN0 y Fosc/32

;Habilita interrupción provocada al finalizar la conversión
                bcf     PIR1,ADIF        ;Restaura el flag del conversor AD
                bsf     STATUS,RP0        ;Banco 1
                bsf     PIE1,ADIE        ;Activa interrupción del ADC
                bcf     STATUS,RP0        ;Banco 0
                bsf     INTCON,PEIE        ;Habilita interrupciones de los periféricos
                bsf     INTCON,GIE        ;Habilita interrupciones
                bsf     ADCON0,GO_DONE    ;Inicia la conversión

;Bucle principal

Loop            nop
                goto    Loop            ;Repetir la lectura

                end                        ;Fin del programa fuente
