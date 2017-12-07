.include "LCD-lib.asm"

; ---------------------------------------------------------------------------
; Name:     lcd_write_string_4d_mem
; Purpose:  display a string of characters on the LCD
; Entry:    XH and XL pointing to the start of the string
;           (temp_r16) contains the desired DDRAM address at which to start the display
; Exit:     no parameters
; Notes:    the string must end with a null (0)
;           uses time delays instead of checking the busy flag

lcd_write_string_4d_mem:
; preserve registers
    push    XH                              ; preserve pointer registers
    push    XL

; STEP NOT NEEDED ~fix up the pointers for use with the 'lpm' instruction~
    ;; lsl     XL                              ; shift the pointer one bit left for the lpm instruction
    ;; rol     XH

; set up the initial DDRAM address
    ori     temp_r16, lcd_SetCursor     ; convert the plain address to a set cursor instruction
    call   lcd_write_instruction_4d     ; set up the first DDRAM address
    ldi     temp_r16, 80                ; 40 uS delay (min)
    call    delayTx1uS

; write the string of characters
lcd_write_string_4d_mem_01:
    ld      temp_r16, X+                        ; get a character
    cpi     temp_r16,  0                        ; check for end of string
    breq    lcd_write_string_4d_mem_02          ; done

; arrive here if this is a valid character
    call    lcd_write_character_4d          ; display the character
    ldi     temp_r16, 80                        ; 40 uS delay (min)
    call    delayTx1uS
    rjmp    lcd_write_string_4d_mem_01          ; not done, send another character

; arrive here when all characters in the message have been sent to the LCD module
lcd_write_string_4d_mem_02:
    pop     XL                              ; restore pointer registers
    pop     XH
    ret
