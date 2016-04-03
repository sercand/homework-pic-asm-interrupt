;----------------------------------------;
;Grup No: 45
;Student ID: 1941954
;Name and Surname: Sercan Degirmenci
;Student ID: 1942028
;Name and Surname: Hasan Zafer Elcik
;----------------------------------------;

list P=18F8722

#include <p18f8722.inc>
config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

;------------Variables-------------------
W_TEMP	    equ	    020h
STATUS_TEMP equ	    021h
PCLATH_TEMP equ	    022h
randNumber  udata   0x23      
randNumber

	;----------------------------------------;
    ;   Other variable declerations   ;
    ;----------------------------------------;
;----------------------------------------;

    org	0x00
	goto    init

	org	0x08
	goto    timer0_isr    ; Goto Interrupt service routine


init:

    call    initTimer0
    
    ;----------------------------------------;
    ;   Other required init configurations   ;
    ;----------------------------------------;
    MOVLW   b'11111000'
    MOVWF   TRISF
main:

    ;-----------------------------------------;
    ;              Your code                  ;
    ;-----------------------------------------;
    call    listenStartButton 
    call    assignRandomNumber
    call    terminateTimerInterrupt
    ;-----------------------------------------;
    ;              Your code                  ;
    ;-----------------------------------------;

    ;-----------------------------------------;
    ;         Your other subroutines          ;
    ;-----------------------------------------;

listenStartButton
    btfsc   PORTF,5    ;Listen button whether it is pressed or not. if yes then skip.
    goto    listenStartButton
ReleaseStartButton
    btfss   PORTF,5      ;Listen button whether it is released or not, if yes then skip.
    goto    ReleaseStartButton
    return	
	
;------------------------ The suedo random generator functions by using TIMER0-------------------------------------------------------------------; 
initTimer0

    movlw   B'01001111'	; Timer0 increment from internal clock with a prescaler of 1:256.
    movwf   T0CON
    bsf	    INTCON, TMR0IE 	; Enable TMR0 interrupt
    bsf	    INTCON, GIEH 	; Enable all interrupts
    bsf	    INTCON, GIE 	; Enable all interrupts
    bsf	    T0CON, TMR0ON
    return

assignRandomNumber

    movf   TMR0,0
    movwf  randNumber
    movlw  d'157'
    subwf  randNumber,1
    addwf  randNumber,0
    return

timer0_isr
    call    save_registers ; save current content of STATUS and PCLATH registers to be abel to restore later
    movlw   d'157'		;256-157=99
    movwf   TMR0
    bcf	    INTCON,TMR0IF
    call    restore_registers ; restore STATUS and PCLATH registers to their state before interrupt occurs
    retfie

terminateTimerInterrupt
    bcf	    T0CON,  TMR0ON 
    bcf	    INTCON, TMR0IE 	; Disable TMR0 interrupt
    bcf	    INTCON, GIEH 	; Disable all interrupts
    bcf	    INTCON, GIE 	; Disable all interrupts
return
;;;;;;;;;;;; Register handling for proper operation of main program ;;;;;;;;;;;;

save_registers:
    MOVWF 	W_TEMP		;Copy W to TEMP register
    SWAPF 	STATUS,W 	;Swap status to be saved into W
    CLRF 	STATUS 		;bank 0, regardless of current bank, Clears IRP,RP1,RP0
    MOVWF 	STATUS_TEMP 	;Save status to bank zero STATUS_TEMP register
    MOVF 	PCLATH, W 	;Only required if using pages 1, 2 and/or 3
    MOVWF 	PCLATH_TEMP 	;Save PCLATH into W
    CLRF 	PCLATH 		;Page zero, regardless of current page

    return

restore_registers:
    MOVF 	PCLATH_TEMP, W 	;Restore PCLATH
    MOVWF 	PCLATH 		;Move W into PCLATH
    SWAPF 	STATUS_TEMP,W 	;Swap STATUS_TEMP register into W
    ;(sets bank to original state)
    MOVWF 	STATUS 		;Move W into STATUS register
    SWAPF 	W_TEMP,F 	;Swap W_TEMP
    SWAPF 	W_TEMP,W 	;Swap W_TEMP into W

    return	
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------;

end
