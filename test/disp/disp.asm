;;; Includes
.nolist
.include "m328Pdef.inc"       ; Device
.list
.include "roanlib.asm"        ; Handy Fxns

;;; Definitions
  .def temp_r16=r16

;;; Macros

;;; Interupt Vectors
  .org 0x0000
               jmp RESET

;;; Good
;;; Startup Routine
  ;; .cseg
  .org INT_VECTORS_SIZE         ;TODO: Use this one instead and check different

		;;; Data!
	str_a:  .db "Hello World!", 0, 0

;;; Display Init
	  	.nolist
	  .include "LCD-lib.asm"
	  .list

  ;; Write from SRAM
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

RESET:
;;; Init SP
  init_sp

	  call lcd_init_4d              ; Initialize LCD display for 4-bit interface

  ldi temp_r16, lcd_Clear
  call lcd_write_instruction_4d

  disp_from_cm str_a, lcd_LineOne

  ldi XL, low(str_b)
  ldi XH, high(str_b)
  ldi temp_r16, $3A
  st X+, temp_r16
  ldi temp_r16, $29
  st X+, temp_r16
  ldi temp_r16, $00
  st X+, temp_r16
  ldi temp_r16, $00
  st X+, temp_r16
  disp_from_sram str_b, lcd_LineTwo

  ;; sleep
  ;; nop
wait_here:  jmp wait_here

  .dseg
str_b:   .byte 4
