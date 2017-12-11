;- macros.asm ------------------------------------------------------------------
;
; Desription:  Collection of macros for clock program.
; Author:      Roan Martin-Hayden <roanmh@gmail.com>
;               [Except where otherwise noted]
; Date:        Dec 2017
;-------------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Name:     lcd_write_string_4d_mem
; Purpose:  Display a string of characters on the LCD, at a given location
; Entry:    XH and XL pointing to the start of the string
;           (temp_r16) contains the desired DDRAM address at which to start the display
; Exit:     No parameters
; Notes:    The string must end with a null (0)
;           uses time delays instead of checking the busy flag
lcd_write_string_4d_mem:
                push r16        ; Preserve Registers

; set up the initial DDRAM address
                  ori r16, lcd_SetCursor     ; convert the plain address to a set cursor instruction
                  call lcd_write_instruction_4d    ; set up the first DDRAM address
                  ldi r16, 80                ; 40 uS delay (min)
                  call delayTx1uS

                pop r16
                call lcd_append_string_4d_mem
                ret

;----------------------------------------------------------------------------
; Name:     lcd_append_string_4d_mem
; Purpose:  Display a string of characters on the LCD, at the current cursor
; Entry:    XH and XL pointing to the start of the string
; Exit:     No parameters
; Notes:    The string must end with a null (0)
;           uses time delays instead of checking the busy flag
lcd_append_string_4d_mem:
                push r16        ; Preserve Registers
                  push XH
                    push XL

; write the string of characters
lcd_write_string_4d_mem_01:
                      ld r16, X+                        ; get a character
                      cpi r16,  0                        ; check for end of string
                      breq lcd_write_string_4d_mem_02          ; done

; arrive here if this is a valid character
                      call lcd_write_character_4d          ; display the character
                      ldi r16, 80                        ; 40 uS delay (min)
                      call delayTx1uS
                      rjmp lcd_write_string_4d_mem_01          ; not done, send another character

; arrive here when all characters in the message have been sent to the LCD module
lcd_write_string_4d_mem_02:
                    pop XL                              ; restore pointer registers
                  pop XH
                pop r16
                ret
