
;==========================================
; Archivo PostLab4.s
; Dispositivo: PIC16F887
;Autor: Christian Campos
;Compilador pic-as (v2.30), MPLABX V5.40
;
; Programa: Contador binario de 4 bits en el que cada incremento se realizará cada 100ms
; Hardware: 
; 
;Creado: 16 feb, 2023
; Última modficación: 19 feb, 2023
;==========================================

    PROCESSOR 16F887
    #include <xc.inc>

;============ CONFIGURACION ============

    CONFIG FOSC = INTRC_NOCLKOUT
    CONFIG WDTE = OFF
    CONFIG PWRTE = ON
    CONFIG MCLRE = OFF
    CONFIG CP = OFF
    CONFIG CPD = OFF

    CONFIG BOREN = OFF
    CONFIG IESO = OFF   
    CONFIG FCMEN = OFF
    CONFIG LVP = OFF

    CONFIG WRT = OFF
    CONFIG BOR4V = BOR40V
    
    UP	    EQU 0
    DOWN    EQU 1
    
    reset_tmr0 macro
	BANKSEL TMR0
	movlw	6		    
	movwf	TMR0	
	BANKSEL PORTA
	endm
    
;============ VARIABLES ============

    PSECT udata_bank0	
    cont_seg: DS 1	; variable contador segundos
    cont_min: DS 1	; variable contador decenas
    cont_TMR0: DS 2	; variable tmr0
    W_temp: DS 1
    STATUS_temp: DS 1
    
;============ RESET ============
    
    PSECT resVect, class=CODE, abs, delta=2
    ORG 00h
    
    resetVec: 
    PAGESEL main
    goto main
	
;============ INTERRUPCIONES ============
    ORG 04h
    
    push:			; guardando status y w
	movwf	W_temp
	swapf	STATUS, W
	movwf	STATUS_temp
	
    isr:			; rutinas de interrupcion
	btfsc	RBIF		; bandera de cambio en portb
	call	int_PORTB	
	btfsc	T0IF		; bandera de cambvio en tmr0
	call	int_TMR0
	
    pop:			; regresando los valores de status y w
	swapf	STATUS_temp, W
	movwf	STATUS
	swapf	W_temp, F
	swapf	W_temp, W
	retfie

;============ SUBRUTINAS INTERRUPCIONES ============	
	
    int_PORTB:			; subrutina de interrupcion portb
	btfss	PORTB, UP	; UP = 0 se incrementa el contador
	incf	PORTD	
	btfss	PORTB, DOWN	; UP = 0 se decrementa el contador
	decf	PORTD
	bcf	RBIF		; rst bandera
	return
	
    int_TMR0:			; subrutina de interrupcion tmr0
	reset_tmr0
	bcf	T0IF		; rst bandera
	incf	cont_TMR0	; incrementar contador tmr0
	movf	cont_TMR0, W	
	xorlw	125		; maximo tmr = 125
	btfss	ZERO
	goto	return_t0
	incf	cont_seg	; se incrementa el contador de segundos
	clrf	cont_TMR0	; se reinicion tmr0
    return_t0:
	return
	
	
;============ MAIN ============
	
    PSECT code, delta=2, abs
    ORG 100h
    
    main:
	call config_io
	call config_tmr0
	call config_clk
	call config_int
	BANKSEL	PORTA	
    
    tabla_a:
	clrf	PCLATH
	bsf	PCLATH, 0   ; PCLATH en 01
	addwf	PCL	    ; PC = PCLATH + PCL (offset)
	retlw 11000000B; 0
	retlw 11111001B; 1
	retlw 10100100B; 2
	retlw 10110000B; 3
	retlw 10011001B; 4
	retlw 10010010B; 5
	retlw 10000010B; 6
	;retlw 11111000B; 7
	;retlw 10000000B; 8
        ;retlw 10010000B; 9
        ;retlw 10001000B; A
	;retlw 10000011B; b
        ;retlw 10100111B; c
	;retlw 10100001B; d
	;retlw 10000110B; E
	;retlw 10001110B; F

    tabla_c:
	clrf	PCLATH
	bsf	PCLATH, 0   ; PCLATH en 01
	addwf	PCL	    ; PC = PCLATH + PCL (offset)
	retlw 11000000B; 0
	retlw 11111001B; 1
	retlw 10100100B; 2
	retlw 10110000B; 3
	retlw 10011001B; 4
	retlw 10010010B; 5
	retlw 10000010B; 6
	retlw 11111000B; 7
	retlw 10000000B; 8
	retlw 10010000B; 9
;============ CONFIGURACIÓN I/0 ============
    config_io:
    
	BANKSEL ANSEL
	clrf    ANSEL		; PINES DIGITALES
	clrf    ANSELH

	BANKSEL TRISA
	clrf	TRISA		; PORTA Salida
	clrf	TRISC		; PORTC Salida
	
	
	BANKSEL PORTA		; valores iniciales puertos y variables
	movlw	11000000B;	   ;configuración inicial PORTA Y PORTC en 0 (display)
	movwf	PORTA
	movlw	11000000B; 0
	movwf	PORTC
	clrf	PORTD
	
	clrf	cont_seg ;comenzar con los offsets de los segundos y los minutos en 0
	clrf	cont_min
	
	return
	
;============ CONFIG CLK ============
    
    config_clk:
	BANKSEL	OSCCON
	bsf	OSCCON, 6	; 1Mhz		
	bcf	OSCCON, 5
	bcf	OSCCON, 4
	bsf	OSCCON, 0	; oscilador interno
	return
	
    config_tmr0:
	BANKSEL	OPTION_REG ;Configuración Timer0 
	bcf	OPTION_REG, 5	
	bcf	OPTION_REG, 3	
	bcf	OPTION_REG, 2	
	bsf	OPTION_REG, 1
	bcf	OPTION_REG, 0
	reset_tmr0 
	return
	
;============ Inicial ============
	
    inicial:			; loop principal
	movlw	10			
	subwf	cont_seg, W	; comparacion contador de segundos = 10
	btfsc	ZERO	
	call	inc_dec		; se llama la funcion inc_dec
	movf	cont_seg, W	
	call	tabla_c		; mostrar el valor de cont_sec en display C
	movwf	PORTC		
	movf	cont_min, W
	call	tabla_a		; mostrar el valor de cont_dec en display A
	movwf	PORTA
	goto	inicial


;============ CONFIG INTERRUPCIONES ============	
	
    config_int:
	BANKSEL	INTCON
	bsf	INTCON, 7 ; GIE
	bsf	INTCON, 3 ;RBIE
	bcf	INTCON, 0 ;RBIF
	bsf	INTCON, 5 ;T0IE
	return
   

    
 ;============ SUBRUTINAS DISPLAY ============

    inc_dec:			; funcion para incrementar decenas de segundos
	clrf	cont_seg	; se limpia el contador de segundos
	incf	cont_min	; se incrementan las deces
	movlw	6		; 6*10=60 segundos= 1 minuto	
	subwf	cont_min, W	
	btfsc	ZERO
	clrf	cont_min	;Se limpia el contador del minuto (una herramienta que nos servirá mas adelante xD)
	return
	
END	


