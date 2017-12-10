;;; roanlib.asm ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
;  A Gathering of handy macros, not necessarily authored by me.
;
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ;; Standard Stack Pointer Initialization
  .macro init_sp
	  ldi r16,low(RAMEND)
	  out SPL,r16
	  ldi r16,high(RAMEND)
	  out SPH,r16
	.endmacro

  ;; Int Division: Returns floor(@0/@1) of two bytes in @0 register.
  ;; Input:  0 - [Output Only]
  ;;         1 - Dividend Register
  ;;         2 - Divisor Register
  ;; Output: 0 - Quotient Register
  ;;         1 - Remainder Register
  ;;         2 - [Input Only]
  .macro int_div
    clr @0
int_div_loop:
    cp @1, @2
    brlt int_div_done
    inc @0
    sub @1, @2
    jmp int_div_loop
int_div_done:
  .endmacro


  ;; Converts number in register to a hex digit 0-F or '#' if out of range
  ;; Params:  @0 register to convert. 16 <= r <= 31
  ;; Result:  Converted number -> @0
.macro hex_to_letter
  cpi @0, $0A
  brge hex_to_letter_geA
  subi @0, -0x30
  jmp hex_to_letter_done
hex_to_letter_geA:
  cpi @0, $10
  brge 	hex_to_letter_out_of_range
  subi @0, -0x37
  jmp hex_to_letter_done
hex_to_letter_out_of_range:
  ldi @0, '#'
hex_to_letter_done:
.endmacro

  ;; Converts number in register to two decimal digits, zero padded
  ;;   or '##' if out of range
  ;; Params:  0 - Register to convert. 16 <= r <= 31
  ;;          1 - Address to store at in SRAM (needs 3 bytes for storing.)
  ;;          2 - Stratch Regiter
  ;; Result:  Decimal String -> Address pointed to by @1
.macro hex_to_dec_str_two_dig
  push @0
  push @2
  push temp_r16
    cpi @0, $64
    brge hex_to_letter_out_of_range
    ldi temp_r16, 10
    int_div @2, @0, temp_r16
    subi @2, -0x30                ; Tens Place
    subi @0, -0x30                ; Ones Place
    jmp hex_to_letter_store
hex_to_letter_out_of_range:
    ldi @0, '#'
    ldi @2, '#'
hex_to_letter_store:
    push XL
      push XH
        ldi XH, high(@1)        ; Z = Code/Flash memory address of
        ldi XL, low(@1)         ; Message to be displayed
        st X+, @2
        st X+, @0
        clr temp_r16
        st X, temp_r16          ; Terminating Zero
      pop XH
    pop XL
  pop temp_r16
  pop @2
  pop @0
.endmacro

  ;; Increment a number of counters that represent readable time values
  ;; Input: Requires named registers: hun_sec_reg, sec_reg, min_reg, hour_reg
  .macro incr_time              ;TODO: Fix overflow (no 00 seem on secs)
    cpi hund_sec_reg, 99
    brge incr_time_carry_sec
    inc hund_sec_reg
    jmp incr_time_end
incr_time_carry_sec:
    cpi sec_reg, 59
    brge incr_time_carry_min
    clr hund_sec_reg
    inc sec_reg
    jmp incr_time_end
incr_time_carry_min:
    cpi min_reg, 59
    brge incr_time_carry_hour
    clr sec_reg
    inc min_reg
    jmp incr_time_end
incr_time_carry_hour:
    cpi min_reg, 23
    brge incr_time_overflow
    clr min_reg
    inc hour_reg
    jmp incr_time_end
incr_time_overflow:
    clr hour_reg
incr_time_end:
  .endmacro

  .macro store_time_val
  	load_addr @0, @1
	  st @0+, temp_r16
	  ldi temp_r16, $00
	  st @0, temp_r16
  .endmacro


; ---------------------------------------------------------------------------
; Name:     lcd_write_string_4d_mem
; Purpose:  display a string of characters on the LCD
; Entry:    XH and XL pointing to the start of the string
;           (temp_r16) contains the desired DDRAM address at which to start the display
; Exit:     no parameters
; Notes:    the string must end with a null (0)
;           uses time delays instead of checking the busy flag

.macro import_lcd_write_string_4d_mem
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
.endmacro

	;; Display a string from code memory
	;; Parameters are string_pointer, {lcd_lineone, lcd_linetwo}
	;; Source: Mick Walters
	  .macro disp_from_cm
	    ldi ZH, high(@0) ; Z = Code/Flash memory address of
	    ldi ZL, low(@0) ; message to be displayed
	    ldi r16, @1 ; r16 = line 1 LCD address
	    call lcd_write_string_4d
	  .endmacro

;; Display a string from SRAM
;; Parameters are string_pointer, {lcd_lineone, lcd_linetwo}
;; Source: Mick Walters
   .macro disp_from_sram
     ldi XH, high(@0) ; Z = Code/Flash memory address of
     ldi XL, low(@0) ; message to be displayed
     ldi r16, @1 ; r16 = line 1 LCD address
     call lcd_write_string_4d_mem
   .endmacro

  ;; Load an address into letter register without left shift
  .macro load_addr
    ldi @0L, low(@1)
    ldi @0H, high(@1)
  .endmacro
