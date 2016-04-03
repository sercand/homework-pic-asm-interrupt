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
L1      EQU	0X31
L2      EQU	0X32
L3      EQU	0X33
;Light variables
light6	EQU	0x34
light5	EQU	0x35
light4	EQU	0x36
light3	EQU	0x37
light2	EQU	0x38
light1	EQU	0x39
light0	EQU	0x3A

;Data variables
digit1	udata	0x41
digit1
digit2	udata	0x42
digit2
guess	udata	0x43
guess
tempcmp	udata	0x44
tempcmp
energy	udata	0x45
energy
lightN	udata	0x46
lightN
intmode EQU	0x47
dispctr	EQU	0x48
digit3	udata	0x49
digit3
digit4	udata	0x4A
digit4
cdig3	udata	0x4B
cdig3
cdig4	udata	0x4C
cdig4
;----------------------------------------;

org 0x00
    goto    init

org 0x08
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
; for 7-segment Displays

    MOVLW   0x00
    MOVWF   TRISH

    MOVLW   0x00
    MOVWF   TRISJ
    
    movlw 0x0
    movwf digit1
    movwf digit2
    movwf guess
    movwf cdig3
    movwf cdig4
    
    movlw 0xA
    movwf digit3    ; because A will show '-' on 7seg
    movwf digit4    ; because A will show '-' on 7seg
 
    movlw   b'00111111'
    movwf   light6

    movlw   b'00111110'
    movwf   light5
     
    movlw   b'00111100'
    movwf   light4
     
    movlw   b'00111000'
    movwf   light3
    
    movlw   b'00110000'
    movwf   light2
    
    movlw   b'00100000'
    movwf   light1
    
    movlw   b'00000000'
    movwf   light0
    
    movlw   0x0
    movwf   dispctr   
main:

    ;-----------------------------------------;
    ;              Your code                  ;
    ;-----------------------------------------;
    call    listenStartButton	    ;Waits for pressing RF5
    call    assignRandomNumber	    ;Assigns Random number between 00-99
    ;call    terminateTimerInterrupt ; Do not terminate Timer interupt because it necessary for showing 7SegmentDisplay
    call    SetEnergyFull
    call    CalculateCorrectDigits
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
    call    CalculateGuess	;Calculate guessed number from digit1 and digit2; w=digit1*10+digit2
    movf    guess,0		;move guessed number to WREG
    cpfseq  randNumber		;Compare guessed number and randNumber skip if equals
    goto    DecreaseEnergyOrDie	;Guessed number is not equal to random number, decrease energy  
    goto    ShowSuccess		;Guess is correct, Congratulations!!!
IncreaseFirstDigit 
    movlw   0x9			;W = 9
    cpfseq  digit1		;if number is 9 than skip increasing
    incf    digit1,1		;increase digit1
    goto    listenButton	;return to listen next button
DecreaseFirstDigit 
    tstfsz  digit1		;if digit1 is 0 than skip decreasing
    decf    digit1,1		;decrease digit1
    goto    listenButton
IncreaseSecondDigit 
    movlw   0x9			;W = 9
    cpfseq  digit2		;if digit2==9 than skip increasing
    incf    digit2,1
    goto    listenButton
DecreaseSecondDigit     
    tstfsz  digit2
    decf    digit2,1
    goto    listenButton
ShowSuccess
    movlw   0x9
    goto    listenButton    
ShowHint
    movf    guess,0
    cpfsgt  randNumber
    goto    ShowDownHint
    goto    ShowUpHint    
ShowDownHint
    movlw   b'01000000'
    movwf   LATB
    movwf   LATD
    movlw   b'11110000'
    movwf   LATC
    goto listenButton
ShowUpHint
    movlw   b'00000010'
    movwf   LATB
    movwf   LATD
    movlw   b'00001111'
    movwf   LATC
    goto listenButton
GameOver
    movlw   0xA
    movwf   digit1
    movwf   digit2
    movff   cdig3,digit3
    movff   cdig4,digit4
ENDLESS_LOOP
    call    Delay_500
    call    Delay_500
    goto    ENDLESS_LOOP
CalculateCorrectDigits
    movlw   0x9
    movwf   L1
    movlw   0x0
    movwf   tempcmp
    movf    randNumber,0
CCG_FIND_DIGIT3
    cpfslt  L1 
    goto    SET_DIGITS_3_4
    incf    tempcmp,1
    movwf   L2
    movlw   0xA
    subwf   L2,0
    goto    CCG_FIND_DIGIT3
SET_DIGITS_3_4
    movwf   cdig4
    movff   tempcmp,cdig3
    return

CalculateGuess
    movlw   0x0
    addwf   digit1,0	;w	= digit1
    mullw   0x9		;prodl	= w * 9
    addwf   PRODL,0	;w	= digit1 * 10;
    addwf   digit2,0	;w	= w + digit2 = digit1*10 + digit2;
    movwf   guess	;guess  = w
    return
SetEnergyFull
    movlw   0x6		    ;w = 6
    movwf   energy	    ;set energy level 6
    call    ShowEnergyLevel ;show energy level 
    movlw   0x0		    ;w = 0
    movwf   TMR0	    ;make tmr0=0
    bsf	    intmode,0	    ;change intmode to showing 7segment display
    return
DecreaseEnergyOrDie
    decf    energy,1
    call    ShowEnergyLevel
    tstfsz  energy
    goto    ShowHint
    goto    GameOver
ShowEnergyLevel
    movlw   0x6
    cpfseq  energy
    goto    check5
    movff   light6, lightN
    goto    lightUp
check5
    movlw   0x5
    cpfseq  energy
    goto    check4
    movff   light5, lightN
    goto    lightUp
check4
    movlw   0x4
    cpfseq  energy
    goto    check3
    movff   light4, lightN
    goto    lightUp   
check3
    movlw   0x3
    cpfseq  energy
    goto    check2
    movff   light3, lightN
    goto    lightUp  
check2
    movlw   0x2
    cpfseq  energy
    goto    check1
    movff   light2, lightN
    goto    lightUp 
check1
    movlw   0x1
    cpfseq  energy
    goto    check0
    movff   light1, lightN
    goto    lightUp     
check0
    movff   light0, lightN
lightUp
    movf    lightN,0
    movwf   LATE
    return
;500ms delay function
Delay_500
			;4999993 cycles
	movlw	0x2C
	movwf	L1
	movlw	0xE7
	movwf	L2
	movlw	0x0B
	movwf	L3
Delay_INNER
	decfsz	L1, f
WASTE0	goto	WASTE1
	decfsz	L2, f
WASTE1	goto	WASTE2
	decfsz	L3, f
WASTE2	goto	Delay_INNER

			;3 cycles
	nop
	nop
	nop
			;4 cycles (including call)
	return
;------------------------ The suedo random generator functions by using TIMER0-------------------------------------------------------------------; 
initTimer0

    movlw   B'01001111'	; Timer0 increment from internal clock with a prescaler of 1:256.
    movwf   T0CON
    movlw   0x0
    movwf   intmode
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
    
show_number_on_display
    movf    dispctr,0
    movff   PCL,STATUS      
    rlncf   WREG,w 
    addwf   PCL,f
    goto    show_digit_1
    goto    show_digit_2
    goto    show_digit_3
    goto    show_digit_4
show_digit_1
    movf    digit1,0
    call    segment
    movwf   LATJ
    bcf	    LATH,3
    bsf	    LATH,0
    incf    dispctr,1
    goto end_timer0_isr
show_digit_2
    movf    digit2,0
    call    segment
    movwf   LATJ
    bcf	    LATH,0
    bsf	    LATH,1
    incf    dispctr,1
    goto end_timer0_isr
show_digit_3
    movf    digit3,0
    call    segment
    movwf   LATJ
    bcf	    LATH,1
    bsf	    LATH,2
    incf    dispctr,1
    goto end_timer0_isr
show_digit_4
    movf    digit4,0
    call    segment
    movwf   LATJ
    bcf	    LATH,2
    bsf	    LATH,3    
    movlw   0x0
    movwf   dispctr
    goto end_timer0_isr
    
timer0_isr
    call    save_registers ; save current content of STATUS and PCLATH registers to be abel to restore later
    tstfsz  intmode
    goto    show_number_on_display
    movlw   d'157'		;256-157=99
    movwf   TMR0
end_timer0_isr
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
segment
    movff   PCL,STATUS      
    rlncf   WREG,w 
    addwf   PCL,f 
    retlw   0x3f    ; 0 code 
    retlw   0x06    ; 1 
    retlw   0x5b    ; 2 
    retlw   0x4f    ; 3 
    retlw   0x66    ; 4 
    retlw   0x6d    ; 5 
    retlw   0x7d    ; 6 
    retlw   0x07    ; 7 
    retlw   0x7f    ; 8 
    retlw   0x6f    ; 9 
    retlw   0x40    ; - 
    retlw   0x40    ; - 
    retlw   0x40    ; - 
    retlw   0x40    ; - 
    retlw   0x40    ; - 
    retlw   0x40    ; - 
    retlw   0x7f    ; 
end
