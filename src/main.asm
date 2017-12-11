;- main.asm --------------------------------------------------------------------
;
;  Desription:  Main source for a clock functioning on an ATMega328P and LCD
;               Keypad Sheild
;  Author:      Roan Martin-Hayden <roanmh@gmail.com>
;  Date:        Dec 2017
;-------------------------------------------------------------------------------



;;; Includes (Non-Function)
  .nolist
  .include "m328Pdef.inc"       ; Device
  .list
  .include "macros.inc"


;;; Definitions
  ;; Register Definitions
  ;.def temp_r16=r16            ; Included in LCD-lib.asm
  .def temp_r16     = r16
  .def temp_r17     = r17
  .def hund_sec_reg = r18
  .def sec_reg      = r19
  .def min_reg      = r20
  .def hour_reg     = r21


  ;; Contstant Definitions

  ; 16bit Timer Waveform Generation Mode
  .equ t16wgm_hi = (0b00 << WGM12)   ; Normal Mode
  .equ t16wgm_lo = (0b00 << WGM10)
  ;.equ t16wgm_hi = (0b01 << WGM12)   ; CTC Mode (For Future Reference)
  ;.equ t16wgo_lo = (0b00 << WGM10)

  ; 16bit Timer Clock Select
  .equ t16cs = (0b001 << CS10)  ; ClkIO x1 (no prescale)

  ; 16Bit Timer Interrupt Mask
  .equ t16im = (0b1 << TOIE1)   ; Overflow Interupt Enable
  ;.equ t16im = (0b1 << OCIEA)   ; Output Compare Register A Int. En.

  ;Display Location Constants
  .equ clk_hr_loc   = 0x00
  .equ clk_cln1_loc = 0x02
  .equ clk_mn_loc   = 0x03
  .equ clk_cln2_loc = 0x05
  .equ clk_sc_loc   = 0x06

;;; Static Variables
  .dseg

  ;; Time Value Strings: Null terminated ASCII strings of each time value
  ;; Note: See "" for programed string values
hund_sec_str:  .byte 3
ten_sec_str:   .byte 3
sec_str:       .byte 3
min_str:       .byte 3
hour_str:      .byte 3

;;; Interupt Vectors
  .cseg
  .org 0x0000
                jmp RESET       ; Reset Interupt Vecotor
  .org 0x001A
                jmp TIMER1_OVR  ; Timer Overflow Interupt Vector.

  .org INT_VECTORS_SIZE         ; Start Rest of code after Interupt Vectors



;;; Interupt Service Routines

  ;; Timer Overflow Interupt
  .cseg                         ; This seems needed to avoid errors
  	.include "LCD-lib.asm"
TIMER1_OVR:     incr_time hund_sec_reg, sec_reg, min_reg, hour_reg
                hex_to_dec_str_two_dig sec_reg, sec_str ; Convert and store time values
                hex_to_dec_str_two_dig min_reg, min_str
                hex_to_dec_str_two_dig hour_reg, hour_str

                ldi temp_r16, $00           ; Set cursor to Begining of first line
                ori temp_r16, lcd_SetCursor	     ; convert the plain address to a set cursor instruction
                call lcd_write_instruction_4d    ; 80us delay

                	disp_from_sram hour_str, clk_hr_loc  ; 320us delay
	                disp_from_pm colon_str, clk_cln1_loc ; 240us delay
	                disp_from_sram min_str, clk_mn_loc   ; 320us delay
	                disp_from_pm colon_str, clk_cln2_loc ; 240us delay
	                disp_from_sram sec_str, clk_sc_loc   ; 320us delay
                ;; disp_from_sram_append hour_str
                ;; disp_from_pm colon_str, clk_cln1_loc
                ;; disp_from_sram_append min_str
                ;; disp_from_pm colon_str, clk_cln2_loc
                ;; disp_from_sram_append sec_str
                reti


;;; Startup Routine
  .cseg
RESET:          init_sp         ; Initialize the Stack Pointer

  ;; Timer Setup
  ;;  -Control Registers
                ldi temp_r16, t16wgm_lo
                sts TCCR1A, temp_r16

                ldi temp_r16, t16cs         ; Clock Source (Curr: x1 Prescale)
                ori temp_r16, t16wgm_hi
                sts TCCR1B, temp_r16

                ldi temp_r16, $00 ;TODO: Add constant for this
                sts TCCR1C, temp_r16

  ;;  -Interupt Mask
                ldi temp_r16, t16im
                sts TIMSK1, temp_r16


                call lcd_init_4d              ; Initialize LCD display for 4-bit interface

  ;; Clear Display Instruction
                ldi temp_r16, lcd_Clear       ; r16 = clear display instruction
                call lcd_write_instruction_4d


  ;; Initialize Counters
                clr hund_sec_reg
                clr sec_reg
                clr min_reg
                clr hour_reg

  ;; Global Interupt Enable
                sei

  ;; Waiting Loop
wait_loop:      jmp wait_loop

;;; Program Constants
  .cseg
colon_str:      .db ":", 0
;;; Function Libraries
  .cseg
  ;; .include "LCD-lib.asm"
  .include "timer_fxns.inc"
