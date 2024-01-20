#include <p16f84a.inc>
; oscilador externo de 8MHz, sem watch dog timer, com power up timer e sem protecao de codigo
    __config _FOSC_XT & _WDT_OFF & _PWRTE_ON & _CP_OFF

VAR_A EQU 0x0C ; endereco onde sera salvo a variavel A
VAR_B EQU 0x0D ; endereco onde sera salvo a variavel B
VAR_C EQU 0x0E ; endereco onde sera salvo a variavel C
VAR_D EQU 0x0F ; endereco onde sera salvo a variavel D
VAR_E EQU 0x10 ; endereco onde sera salvo a variavel E
VAR_F EQU 0x11 ; endereco onde sera salvo a variavel F
VAR_X EQU 0x12 ; endereco onde sera salvo a variavel X
MULTIPLICADOR EQU 0x13 ; endereco onde sera salvo o MULTIPLICADOR
PROCESSING EQU 0x14 ; endereco onde sera salvo o PROCESSING
RESULT EQU 0x15 ; endereco onde sera salvo o RESULT
              
    ORG 0x00 ; inicio do programa principal em 0x00
    GOTO PRIN_START ; pula para o inicio do programa

    ORG 0x04 ; inicio do programa de interrupcao em 0x04

; inicio do processo de configurar entradas e saidas
PRIN_START
    BCF STATUS, RP0 ; bank 0 (bit clear file)
    CLRF PORTA ; inicializa PORTA limpando-a (clear file)
    BSF STATUS, RP0 ; bank 1 (bit set file)
    BSF TRISA, RA1 ; RA1 como entrada (bit set file)
    
    BCF STATUS, RP0 ; bank 0 (bit clear file)
    CLRF PORTB ; inicializa PORTB limpando-a (clear file)
    BSF STATUS, RP0 ; bank 1 (bit set file)
    MOVLW 0x00 ; W = 0000 0000 (move literal to worker)
    MOVWF TRISB ; todas as portas B como saida (move worker to file)
    BCF STATUS, RP0 ; bank 0 (bit clear file)
; termino do processo de configurar entradas e saidas

; inicio do processo de carregar constantes
    MOVLW 0x02 ; W = 0000 0010 (move literal to worker)
    MOVWF VAR_A ; VAR_A = 0x02 = 0000 0010 = 2 (move worker to file)
    MOVLW 0x03 ; W = 0000 0011 (move literal to worker)
    MOVWF VAR_B ; VAR_B = 0x03 = 0000 0011 = 3 (move worker to file)
    MOVLW 0xFD ; W = 1111 1101 (move literal to worker)
    MOVWF VAR_C ; VAR_C = 0xFD = 1111 1101 = -3 (move worker to file)
    MOVLW 0x08 ; W = 0000 1000 (move literal to worker)
    ADDWF VAR_A, W ; W = W + VAR_A = 0000 1000 + 0000 0010 = 10 (add worker to VAR_A, put in worker)
    MOVWF VAR_E ; VAR_E = W = 0000 1010 = 10 (move worker to file)
    MOVLW 0x04 ; W = 0000 0100 (move literal to worker)
    MOVWF MULTIPLICADOR ; MULTIPLICADOR = W = 0000 0100 = 4 (move worker to file)
    MOVLW 0x00 ; W = 0000 0000 (move literal to worker)
    MOVWF PROCESSING ; PROCESSING = W = 0x00 = 0000 0000 = 0 (move worker to file)
    GOTO LOOP ; pula para o loop principal
; termino do processo de carregar constantes
           
; inicio do loop de ler continuamente RA1, ou seja, VAR_D
LOOP
    BTFSC PORTA, RA1 ; pula próxima linha caso RA1 == 0 (bit test, skip if clear)
    GOTO VAR_D_1 ; pula para VAR_D_1 pois VAR_D == 1
    GOTO VAR_D_0 ; pula para VAR_D_0 pois VAR_D == 0

VAR_D_1
    MOVF VAR_C, W ; W = VAR_C = 0xFD = 1111 1101 = -3 (move file to worker)
    CALL FUNCTION ; chama a funcao FUNCTION
    MOVF RESULT, W ; W = RESULT (move file to worker)
    MOVWF VAR_F ; VAR_F = W (move worker to file)
    GOTO WRITING ; pula para WRITING
    
VAR_D_0 
    MOVF VAR_E, W ; W = VAR_E = 0x0A = 0000 1010 = 10 (move file to worker)
    CALL FUNCTION ; chama a funcao FUNCTION
    MOVF RESULT, W ; W = RESULT (move file to worker)
    MOVWF VAR_F ; VAR_F = W (move worker to file)
    GOTO WRITING ; pula para WRITING

WRITING       
    MOVLW 0x00 ; W = 0000 0000 (move literal to worker)
    ADDWF VAR_F, 1 ; VAR_F = W + VAR_F (add worker to VAR_F, put in VAR_F)
; necessario pois o comando ADDWF atualiza o STATUS

; o bit Z do STATUS seta quando uma adicao da igual a zero
    BTFSC STATUS, Z ; pula próxima linha caso Z == 0 (bit test, skip if clear)
    GOTO NEGATIVE_OR_ZERO ; pula para NEGATIVE_OR_ZERO pois Z == 1, ou seja, VAR_F == 0
    GOTO LESS_OR_MORE_THEN ; pula para LESS_OR_MORE_THEN poia Z == 0, ou seja, VAR_F != 0

; logica para descobrir se VAR_F e um valor negativo ou positivo, considerando que ele esta em complemento de 2
LESS_OR_MORE_THEN
    BTFSC VAR_F, 7 ; pula próxima linha caso o bit 7 de VAR_F == 0 (bit test, skip if clear)
    GOTO NEGATIVE_OR_ZERO ; pula para NEGATIVE_OR_ZERO pois VAR_F < 0
    GOTO POSITIVE ; pula para POSITIVE pois VAR_F > 0

POSITIVE
    MOVLW 0x05 ; W = 0000 0101 (move literal to worker)
    MOVWF PORTB ; PORTB = W = 0000 0101 (move worker to file)
    GOTO LOOP ; volta para LOOP

NEGATIVE_OR_ZERO
    MOVLW 0x04 ; W = 0000 0100 (move literal to worker)
    MOVWF PORTB ; PORTB = W = 0000 0100 (move worker to file)
    GOTO LOOP ; volta para LOOP

FUNCTION 
    MOVWF VAR_X ; VAR_X = W = VAR_E || VAR_C (move worker to file)
    MOVF VAR_X, W ; W = VAR_X (move file to worker)

; inicio do loop de multiplicacao
M_LOOP
    ADDWF PROCESSING, 1 ; PROCESSING = PROCESSING + W (add worker to file, put in PROCESSING)
    DECFSZ MULTIPLICADOR, 1 ; MULTIPLICADOR = MULTIPLICADOR - 1 (decrement MULTIPLICADOR, skip if MULTIPLICADOR == 0)
    GOTO M_LOOP ; reinicia o loop de multiplicacao se MULTIPLICADOR != 0

    MOVWF PROCESSING ; PROCESSING = W (move worker to file)
    MOVLW 0x03 ; W = 0000 0011 (move literal to worker)
    SUBWF PROCESSING, W ; W = PROCESSING - W (subtrat worker from PROCESSING, put in worker)
    MOVWF RESULT ; RESULT = W (move worker to file)
    RETURN ; retorna para onde a funcao foi chamada
; termino do loop de multiplicacao

    END ; fim do programa
