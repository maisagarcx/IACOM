#include <p16f84a.inc>
; oscilador externo de 8MHz, sem watch dog timer, com power up timer e sem protecao de codigo
    __config _FOSC_XT & _WDT_OFF & _PWRTE_ON & _CP_OFF
    
SAVE_W EQU 0x0C ; endereco onde sera salvo o W (worker)
SAVE_STATUS EQU 0x0D ; endereco onde sera salvo o STATUS de controle

    ORG 0x00 ; inicio do programa principal em 0x00
    GOTO PRIN_START ; pula para o inicio do programa
    
    ORG 0x04 ; inicio do programa de interrupcao em 0x04
    
; inicio do processo de salvar o W e o STATUS
    MOVWF SAVE_W ; SAVE_W = W (move worker to file)
    MOVF STATUS, W ; W = STATUS (move file to worker)
    MOVWF SAVE_STATUS ; SAVE_STATUS = W (move worker to file)
; termino do processo de salvar o W e o STATUS
    
; inicio do processo de saber o porque aconteceu a interrupcao
    BCF STATUS, RP0 ; bank 0 (bit clear file)
    BTFSS INTCON, T0IF ; bit que indica interrupcao por overflow por TMR0 (bit test, skip if set)
    GOTO END_INT ; pula para END_INT pois T0IF == 0 (nao foi interrupcao por overflow)
    BTFSS PORTA, RA0 ; testa RA0 pois T0IF == 1 (interrupcao por overflow) (bit test, skip if set)
    GOTO RA0_0 ; pula para RA0_0 pois RA0 == 0
    GOTO RA0_1 ; pula para RA0_1 pois RA0 == 1

; inicio da logica de inverter o valor de RA0
RA0_0
    BSF PORTA, RA0 ; RA0 = 1 (bit set file)
    GOTO END_INT ; pula para END_INT

RA0_1
    BCF PORTA, RA0 ; RA0 = 0 (bit clear file)
    GOTO END_INT ; pula para END_INT
; termino da logica de inverter o valor de RA0

END_INT 
; termino do processo de saber o porque aconteceu a interrupcao
    
; colocando 0x0B em TRM0
    MOVLW 0x0B ; W = 0000 1011 (move literal to worker)
    MOVWF TMR0 ; TMR0 = W = 0000 1011 (move worker to file)
    
; inicio do processo de restauracao do W e STATUS
    MOVF SAVE_STATUS, W ; W = SAVE_STATUS (move file to worker)
    MOVWF STATUS ; STATUS = W = SAVE_STATUS (move worker to file)
    MOVF SAVE_W, W ; W = SAVE_W (move file to worker)
; termino do processo de restauracao do W e STATUS
    
    BCF INTCON, T0IF ; T0IF = 0 (bit clear file) 
    RETFIE ; sai do programa de interrupcao
; termino do programa de interrupcao
    
; inicio do processo de configurar entradas e saidas
PRIN_START
    BCF STATUS, RP0 ; bank 0 (bit clear file)
    CLRF PORTA ; inicializa PORTA limpando-a (clear file)
    CLRF PORTB ; inicializa PORTB limpando-a (clear file)
    BSF STATUS, RP0 ; bank 1 (bit set file)
    MOVLW 0xFE ; W = 1111 1110 (move literal to worker)
    MOVWF TRISA ; todas as portas A como entrada, RA0 saida do clock (move worker to file)
    MOVLW 0x00 ; W = 0000 0000 (move literal to worker)
    MOVWF TRISB ; todas as portas B como saida (move worker to file)
    BCF STATUS, RP0 ; bank 0 (bit clear file)
; termino do processo de configurar entradas e saidas
    
; inicio da configuracao do TMR0
    BSF STATUS, RP0 ; bank 1 (bit set file)
    BCF OPTION_REG, T0CS ; T0CS = 0, ou seja, seleciona o uso do clock interno (bit clear file)
    BCF OPTION_REG, PSA ; PSA = 0, ou seja, pre-escalar definido pelo modulo TMR0 (bit clear file)
    BSF OPTION_REG, PS2 ; PS2 = 1 (bit set file)
    BSF OPTION_REG, PS1 ; PS1 = 1 (bit set file)
    BSF OPTION_REG, PS0 ; PS0 = 1, ou seja, TMR0 rate = 1:256 (bit set file)
    BCF STATUS, RP0 ; bank 0 (bit clear file)
    MOVLW 0xB ; W = 1111 1000 (move literal to worker)
    MOVWF TMR0 ; TMR0 = W = 1111 1000 (move worker to file)
    BSF INTCON, GIE ; GIE = 1, ou seja, habilita interrupcoes sem mascara (bit set file)
    BSF INTCON, T0IE ; T0IE = 1, ou seja, habilita interrupcao por TRM0, TRM0 comeca a incrementar (bit set file)
; termino da configuracao do TMR0
    
; inicio do loop de ler continuamente RA1
LOOP
    BTFSC PORTA, RA1; pula próxima linha caso RA1 == 0 (bit test, skip if clear)
    GOTO SENSOR_1 ; pula para SENSOR_1 pois RA1 == 1
    GOTO SENSOR_0 ; pula para SENSOR_0 pois RA1 == 0

SENSOR_1
    MOVLW 0x75 ; W = 0x75 = 0111 0101 (move literal to worker)
    MOVWF PORTB ; PORTB = W = 0x75 = 0111 0101 (move worker to file)
    GOTO LOOP ; volta para loop

SENSOR_0
    MOVLW 0x31 ; W = 0x31 = 0011 0001 (move literal to worker)
    MOVWF PORTB ; PORTB = W = 0x31 = 0011 0001 (move worker to file)
    GOTO LOOP ; volta para loop
    
    END ; fim do programa
