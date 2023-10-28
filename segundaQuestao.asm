#include <p16f84a.inc>
    
; oscilador externo de 8MHz, sem watch dog timer, com power up timer e sem protecao de codigo
    __config _FOSC_XT & _WDT_OFF & _PWRTE_ON & _CP_OFF
    
SAVE_W EQU 0x0C ; endereco onde sera salvo o W
SAVE_STATUS EQU 0x0D ; endereco onde sera salvo o STATUS de controle

    ORG 0x00 ; inicio do programa principal em 0x00
    GOTO PRIN_START ; pula para o inicio do programa
    
; label instruction parameter comment
    ORG 0x04 ; inicio do programa de interrupcao em 0x04
    
; inicio do processo de salvar o W e o STATUS
    MOVWF SAVE_W ; SAVE_W = W
    MOVF STATUS,W ; W = STATUS
    MOVWF SAVE_STATUS ; SAVE_STATUS = W
; termino do processo de salvar o W e o STATUS
    
; inicio do processo de saber o porque aconteceu a interrupcao
    BCF STATUS, RP0 ; bank 0 (bit clear file)
    BTFSS INTCON,T0IF ; bit que indica interrupcao por overflow por TMR0 (pula se 1)
    GOTO END_INT ; T0IF == 0 (ou seja, nao foi) entao fim
    BTFSS PORTA,RA0 ; T0IF == 1 (ou seja, foi) entao testa RA0
    GOTO RA0_0
    GOTO RA0_1
RA0_0
    BSF PORTA,RA0 ; T0IF == 1 &amp;&amp; RA0 == 0 entao RA0 = 1
    GOTO END_INT
RA0_1
    BCF PORTA,RA0 ; T0IF == 1 &amp;&amp; RA0 == 1 entao RA0 = 0
END_INT
; termino do processo de saber o porque aconteceu a interrupcao
    
; colocando 0xB em TRM0
    MOVLW 0xB ; W = 1111 1000
    MOVWF TMR0 ; TMR0 = W = 1111 1000
    
; inicio do processo de restauracao do W e STATUS
    MOVF SAVE_STATUS,W ; W = SAVE_STATUS
    MOVWF STATUS ; STATUS = W = SAVE_STATUS
    MOVF SAVE_W,W ; W = SAVE_W
; termino do processo de restauracao do W e STATUS
    
    BCF INTCON, T0IF ; zera a bandeira de overflow do TMR0
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
    MOVLW 0xFF ; W = 1111 1111
    MOVWF PORTB ; todas as saidas iniciam em alto
    MOVLW 0xFF ; W = 1111 1111
    MOVWF PORTA ; todas as entradas e saida (RA0) iniciam em alto
; termino do processo de configurar entradas e saidas
    
; inicio da configuracao do TMR0
    BSF STATUS, RP0 ; bank 1 (bit set file)
    BCF OPTION_REG,T0CS ; seleciona &quot;timer mode&quot; (ou seja, clock interno)
    BCF OPTION_REG, PSA ; pre-escalar definido pelo modulo do timer0
    BSF OPTION_REG, PS2 ; 1
    BSF OPTION_REG, PS1 ; 1
    BSF OPTION_REG, PS0 ; 111 = 1:256
    BCF STATUS, RP0 ; bank 0 (bit clear file) 0
    MOVLW 0xB ; W = 1111 1000
    MOVWF TMR0 ; TMR0 = W = 1111 1000
    BSF INTCON, GIE ; habilita interrupcoes sem mascara
    BSF INTCON, T0IE ; habilita interrupcao TRM0, TRM0 comeca a incrementar
; termino da configuracao do TMR0
    
; inicio do loop de ler continuamente RA1
LOOP
    BTFSC PORTA,RA1; pula próxima linha caso seja 0
    GOTO SENSOR_1
    GOTO SENSOR_0
SENSOR_1
    MOVLW 0x75 ; W = 0x75 = 0111 0101
    MOVWF PORTB ; PORTB = W = 0x75 = 1 = 0111 0101
    GOTO LOOP ; volta para loop
SENSOR_0
    MOVLW 0x31 ; W = 0x31 = 0011 0001
    MOVWF PORTB ; PORTB = W = 0x31 = 0 = 0011 0001
    GOTO LOOP ; volta para loop
    END
