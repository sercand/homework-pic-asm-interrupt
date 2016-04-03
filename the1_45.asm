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
;Delay variables
L1        EQU 0X31
L2        EQU 0X32
L3        EQU 0X33
;
digit1	  EQU 0x41
digit2	  EQU 0x42
guess	  EQU 0x43
tempcmp	  EQU 0x44	  
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
    CLRF    LATF	;CLEAR LATF
    CLRF    LATB	;CLEAR LATB
    CLRF    LATC	;CLEAR LATC
    CLRF    LATD	;CLEAR LATD
    CLRF    LATE	;CLEAR LATE
    
    MOVLW   b'00111111'
    MOVWF   TRISF	;portF will use as Input
    MOVLW   0x00
    MOVWF   TRISB	;portB shows Hint
    MOVWF   TRISC	;portC shows Hint
    MOVWF   TRISD	;portD shows Hint
    MOVWF   TRISE	;portE shows enery
    
    CLRF    PORTF	;clear PortF
    CLRF    PORTB	;clear PortB
    CLRF    PORTC	;clear PortC
    CLRF    PORTD	;clear PortD
    CLRF    PORTE	;clear PortE

    MOVLW   0x0F
    MOVWF   ADCON1
    
    movlw 0x0
    movwf digit1
    movwf digit2
    movwf guess
    
main:

    ;-----------------------------------------;
    ;              Your code                  ;
    ;-----------------------------------------;
    call    listenStartButton	    ;Waits for pressing RF5
    call    assignRandomNumber	    ;Assigns Random number between 00-99
    call    terminateTimerInterrupt ;
    call    listenButton
    ;-----------------------------------------;
    ;              Your code                  ;
    ;-----------------------------------------;
listenButton
    btfsc   PORTF,0		;Listen button whether it is pressed or not. if no then skip.
    goto    ReleaseButton0
    btfsc   PORTF,1		;Listen button whether it is pressed or not. if no then skip.
    goto    ReleaseButton1
    btfsc   PORTF,2		;Listen button whether it is pressed or not. if no then skip.
    goto    ReleaseButton2
    btfsc   PORTF,3		;Listen button whether it is pressed or not. if no then skip.
    goto    ReleaseButton3
    btfsc   PORTF,4		;Listen button whether it is pressed or not. if no then skip.
    goto    ReleaseButton4
    goto    listenButton
ReleaseButton0
    btfss   PORTF,0		;Listen button whether it is released or not, if yes then skip.
    goto    CheckInput
    goto    ReleaseButton0
ReleaseButton1
    btfss   PORTF,1		;Listen button whether it is released or not, if yes then skip.
    goto    DecreaseSecondDigit
    goto    ReleaseButton1
ReleaseButton2
    btfss   PORTF,2		;Listen button whether it is released or not, if yes then skip.
    goto    IncreaseSecondDigit
    goto    ReleaseButton2
ReleaseButton3
    btfss   PORTF,3		;Listen button whether it is released or not, if yes then skip.
    goto    DecreaseFirstDigit
    goto    ReleaseButton3
ReleaseButton4
    btfss   PORTF,4		;Listen button whether it is released or not, if yes then skip.
    goto    IncreaseFirstDigit
    goto    ReleaseButton4

    ;-----------------------------------------;
    ;         Your other subroutines          ;
    ;-----------------------------------------;

listenStartButton
    btfss   PORTF,5		;Listen button whether it is pressed or not. if yes then skip.
    goto    listenStartButton
ReleaseStartButton
    btfsc   PORTF,5		;Listen button whether it is released or not, if yes then skip.
    goto    ReleaseStartButton
    return
    
CheckInput
    
IncreaseFirstDigit 

DecreaseFirstDigit 

IncreaseSecondDigit 

DecreaseSecondDigit     

ShowCorrectAnswer

ShowHint

ShowDownHint
goto listenStartButton
ShowUpHint
goto listenStartButton
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
