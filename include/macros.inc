; macros.asm -------------------------------------------------------------------
;
; Desription:  Collection of macros for clock program.
; Author:      Roan Martin-Hayden <roanmh@gmail.com>
;               [Except where otherwise noted]
; Date:        Dec 2017
;-------------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Name:     init_sp
; Purpose:  Initialize Stack Pointer to end of device's RAM
; Args:     None
; Notes:    Does not conserve value of r16
; Author:   Mick Walters
  .macro init_sp
                ldi r16,low(RAMEND)
                out SPL,r16
                ldi r16,high(RAMEND)
                out SPH,r16
  .endmacro

;----------------------------------------------------------------------------
; Name:     int_div
; Purpose:  Perform integer division
; Args:     0 - Dividend Register
;           1 - Divisor Register -> Remainder Register
;           2 - -> Quotient Register
; Notes:    Does not conserve value of r16
; Author:   Mick Walters
  .macro int_div
                clr @2
int_div_loop:   cp @0, @1
                brlt int_div_done
                inc @2
                sub @0, @1
                jmp int_div_loop
int_div_done:
  .endmacro

;----------------------------------------------------------------------------
; Name:     hex_to_dec_str_two_dig
; Purpose:  Convert a number to a NULL terminated ASCII representation with two
;           digits.
; Args:     0 - Register to convert. (16 <= r <= 31) Register is resotored
;               after operation.
;           1 - Address to store at in SRAM (needs 3 bytes for string.)
; Notes:    Decimal String -> Address pointed to by Arg 1
  .macro hex_to_dec_str_two_dig
                push @0
                  push r16
                    push r17
                      cpi @0, $64
                      brge hex_to_letter_out_of_range
                      ldi r17, 10
                      int_div @0, r17, r16
                      subi r16, -0x30                   ; Tens Place
                      subi @0, -0x30                   ; Ones Place
                      jmp hex_to_letter_store
hex_to_letter_out_of_range:
                      ldi r17, '#'
                      ldi r16, '#'
hex_to_letter_store:
                      push XL
                        push XH
                          ldi XH, high(@1)                 ; Z = Code/Flash memory address of
                          ldi XL, low(@1)                  ; Message to be displayed
                          st X+, r16
                          st X+, @0
                          clr r17
                          st X, r17                  ; Terminating Zero
                        pop XH
                      pop XL
                    pop r17
                  pop r16
                pop @0
.endmacro

;----------------------------------------------------------------------------
; Name:     incr_time
; Purpose:  Increment a set of registers to represent a hundreth of a second
;           passing.
; Args:     0 - Hundreth Second Register
;           1 - Second Register
;           2 - Minute Register
;           3 - Hour Register
  .macro incr_time              ;TODO: Fix overflow (no 00 seem on secs)
                                ;TODO: Fix how it seems to top out
                cpi @0, 99
                brge incr_time_carry_sec
                inc @0
                jmp incr_time_end
incr_time_carry_sec:
                cpi @1, 59
                brge incr_time_carry_min
                clr @0
                inc @1
                jmp incr_time_end
incr_time_carry_min:
                cpi @2, 59
                brge incr_time_carry_hour
                clr @1
                inc @2
                jmp incr_time_end
incr_time_carry_hour:
                cpi @2, 23
                brge incr_time_overflow
                clr @2
                inc @3
                jmp incr_time_end
incr_time_overflow:
                clr @3
incr_time_end:
  .endmacro

;----------------------------------------------------------------------------
; Name:     disp_from_cm
; Purpose:  Display a NULL terminated string from program memory
; Args:     0 - (Flash) Memory Address of NULL terminated string
;           1 - LCD Address
; Note:     Uses r16 and Z, but restores them as well
  .macro disp_from_pm
  	            push r16
                  push ZL
                    push ZH
                      ldi ZH, high(@0) ; Z = Code/Flash memory address of
                      ldi ZL, low(@0)  ;     message to be displayed
                      ldi r16, @1      ; r16 = line 1 LCD address
                      call lcd_write_string_4d
                    pop r16
                  pop ZH
                pop ZL
  .endmacro

;----------------------------------------------------------------------------
; Name:     disp_from_sram
; Purpose:  Display a NULL terminated string from program memory.
; Args:     0 - (SRAM) Memory Address of NULL terminated string
;           1 - LCD Address
; Note:     Uses r16 and Z, but restores them as well
  .macro disp_from_sram
              	push r16
                  push XL
                    push XH
                      ldi XH, high(@0) ; Z = Code/Flash memory address of
                      ldi XL, low(@0)  ;     message to be displayed
                      ldi r16, @1      ; r16 = line 1 LCD address
                      call lcd_write_string_4d_mem
                    pop XH
                  pop XL
                pop r16
  .endmacro

;----------------------------------------------------------------------------
; Name:     disp_from_sram_app
; Purpose:  Display a NULL terminated string from program memory at the
;           current cursor location
; Args:     0 - (SRAM) Memory Address of NULL terminated string
; Note:     Uses r16 and Z, but restores them as well
 	.macro disp_from_sram_append
                push XL
                  push XH
                    ldi XH, high(@0) ; Z = Code/Flash memory address of
                    ldi XL, low(@0)  ;     message to be displayed
                    call lcd_append_string_4d_mem
                  pop XH
                pop XL
  .endmacro

;----------------------------------------------------------------------------
; Name:     load_addr
; Purpose:  Load an adress into a lettered register.
; Args:     0 - Register to load the address into
;           1 - Address to load
  .macro load_addr
	              ldi @0L, low(@1)
	              ldi @0H, high(@1)
  .endmacro
