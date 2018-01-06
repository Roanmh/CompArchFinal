;- main.asm --------------------------------------------------------------------
;
;  Desription:  Main source for a clock functioning on an ATMega328P and LCD
;               Keypad Sheild
;  Author:      Roan Martin-Hayden <roanmh@gmail.com>
;  Date:        Dec 2017
;  Note: Much of the ADC Setup Code is based off of work by Mick Walters
;-------------------------------------------------------------------------------


;;; Includes (Non-Function)
  .nolist
  .include "m328Pdef.inc"       ; Device
  .list
  .include "macros.inc"


;;; Definitions
  ;; Register Definitions
  .def temp_r16     = r16            ; Included in LCD-lib.asm
  .def temp_r17     = r17
  .def tnth_sec_reg = r18
  .def sec_reg      = r19
  .def min_reg      = r20
  .def hour_reg     = r21
  .def adc_res      = r22
  .def pgm_sts      = r23

 	;; Program Status Register
  .equ time_set = 0
  .equ btn_prs  = 1
  .equ dsp_upd  = 2

  ;; Contstant Definitions
  ; Output Compare Register
  .equ ocr_low  = $FF
  .equ ocr_high = $5F

  ; 16bit Timer Waveform Generation Mode
  .equ t16wgm_hi = (0b01 << WGM12)   ; CTC Mode
  .equ t16wgm_lo = (0b00 << WGM10)

  ; 16bit Timer Clock Select
  ;; .equ t16cs = (0b001 << CS10)  ; ClkIO x1 (no prescale)
  .equ t16cs = (0b011 << CS10)  ; ClkIO x8

  ; 16Bit Timer Interrupt Mask
  ;.equ t16im = (0b1 << TOIE1)   ; Overflow Interupt Enable
  .equ t16im = (0b1 << OCIE1A)   ; Output Compare Register A Int. En.

  ; Power Reduction Register
  .equ prr_startup = 0b11111110     ; Turn on ADC

  ;; ADC Multiplexer Selection Register
  .equ adc_mul_sel = (0b01 << REFS0) + (1 << ADLAR) + (0 << MUX0)

  ;; Digital Input Disable Register
  .equ di_dis_startup = (1 << ADC0D)

  ;; External Interrupt Control Register A
  .equ ext_int_ctrl_a = (0b11 << ISC00)

  ;; External Interrupt Mask Register
  .equ ext_int_msk = $00

  ;; ADC Control and Status Register A
  .equ adc_ctrl_a = (0b1 << ADEN) + (0b1 << ADSC) + (0b1 << ADATE) + (0b1 << ADIE) + (0b111 << ADPS0)

  ;; ADC Control and Status Register B
  .equ adc_ctrl_b = $00

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
ten_sec_str:   .byte 3
sec_str:       .byte 3
min_str:       .byte 3
hour_str:      .byte 3

;;; Interupt Vectors
  .cseg
  .org 0x0000
                jmp RESET        ; Reset Interupt Vecotor
  .org 0x0016
                jmp TIMER1_OVR   ; Timer Output Compare Vector
  .org 0x002A
                jmp ADC_INT      ; ADC Conversion Complete Vector



;;; Interupt Service Routines
  .org INT_VECTORS_SIZE         ; Start rest of code after Interupt Vectors

  ;; Timer Overflow Interupt
TIMER1_OVR:
                push temp_r16
                  lds temp_r16, 0x5F
                  push temp_r16
                    cpbit temp_r16, pgm_sts, time_set, 0
                    brne TIMER1_OVR_END
                    incr_time tnth_sec_reg, sec_reg, min_reg, hour_reg
                    ori pgm_sts, (1 << dsp_upd)
                  pop temp_r16
                  sts 0x5F, temp_r16
                pop temp_r16
TIMER1_OVR_END: reti

  ;; ADC Conversion Complete Interupt
ADC_INT:
                push temp_r16
                  push temp_r17
                    lds temp_r16, 0x5F
                    push temp_r16
                      lds adc_res, ADCH ; Load ADC Result High bit to register

                      cpi adc_res, 240 ; No button is pressed if adc_res is higher
                      brlo ADC_B1
                      andi pgm_sts, $FF - (1 << btn_prs) ; Clear button pressed state
                      jmp ADC_RET            ; Take no action

ADC_B1:               cpbit temp_r16, pgm_sts, btn_prs, 0 ; Check for button pressed state
                      brne ADC_RET
                      sei              ; Enable interupts because this is lower
                                       ; priority than time keeping
                      cpi adc_res, 140 ; Button 1 is pressed if  adc_res is higher
                      brlo ADC_B2

                      ldi temp_r16, (1 << time_set) ; time_set[0]=0->1 or time_set[0]=1->0
                      eor pgm_sts, temp_r16
                      ori pgm_sts, (1 << btn_prs) + (1 << dsp_upd) ; Set button pressed state
                      jmp ADC_RET

ADC_B2:               cpi adc_res, 90 ; Button 2 is pressed if adc_res is higher
                      brlo ADC_B3
                      inc hour_reg
                      cpi hour_reg, 24
                      brlt ADC_B2_1
                      clr hour_reg
ADC_B2_1:             ori pgm_sts, (1 << btn_prs)	+ (1 << dsp_upd) ; Set button pressed state
                      jmp ADC_RET

ADC_B3:               cpi adc_res, 55 ; Button 3 is pressed if adc_res is higher
                      brlo ADC_B4
                      inc min_reg
                      cpi min_reg, 60
                      brlt ADC_B3_1
                      clr min_reg
ADC_B3_1:             ori pgm_sts, (1 << btn_prs)	+ (1 << dsp_upd) ; Set button pressed state
                      jmp ADC_RET

ADC_B4:               cpi adc_res, 20 ; Button 3 is pressed if adc_res is higher
                      brlo ADC_B5
                      subi min_reg, -10
                      cpi min_reg, 60
                      brlt ADC_B4_1
                      subi min_reg, 60
ADC_B4_1:             ori pgm_sts, (1 << btn_prs)	+ (1 << dsp_upd) ; Set button pressed state
                      jmp ADC_RET

ADC_B5:               cpi sec_reg, 0

                      breq ADC_B5_2
                      clr sec_reg
                      jmp ADC_B5_3
ADC_B5_2:             ldi sec_reg, 30
ADC_B5_3:             ori pgm_sts, (1 << btn_prs) + (1 << dsp_upd) ; Set button pressed state

ADC_RET:
                    pop temp_r16
                    sts 0x5F, temp_r16
                  pop temp_r17
                pop temp_r16
                reti


;;; Startup Routine
  .cseg
  .include "LCD-lib.asm"
RESET:          init_sp         ; Initialize the Stack Pointer

  ;; Timer Setup
  ;;  -Control Registers
                ldi temp_r16, t16wgm_lo
                sts TCCR1A, temp_r16

                ldi temp_r16, t16cs         ; Clock Source (Curr: x1 Prescale)
                ori temp_r16, t16wgm_hi
                sts TCCR1B, temp_r16

                ldi temp_r16, $00 ; TODO: Add constant for this
                sts TCCR1C, temp_r16

  ;;  -Output Compare Registers
                ldi temp_r17, ocr_high
                ldi temp_r16, ocr_low
                sts OCR1AH, temp_r17
                sts OCR1AL, temp_r16

  ;;  -Interupt Mask
                ldi temp_r16, t16im
                sts TIMSK1, temp_r16

  ;; Power Reduction Register
                andi temp_r16, prr_startup
                sts PRR, temp_r16

  ;; ADC Multiplexer Selection Register
                ldi temp_r16, adc_mul_sel
                sts ADMUX, temp_r16

  ;; Digital Input Disable Register
                ldi temp_r16, di_dis_startup
                sts DIDR0, temp_r16

  ;; External Interrupt Control Register A
                ldi temp_r16, ext_int_ctrl_a
                sts EICRA,temp_r16

  ;; External Interrupt Mask Register
                ldi temp_r16, ext_int_msk
                sts EIMSK, temp_r16

  ;; ADC Control and Status Register A
                ldi temp_r16, adc_ctrl_a
                sts ADCSRA, temp_r16

  ;; ADC Control and Status Register B
                ldi temp_r16, adc_ctrl_b
                sts ADCSRB, temp_r16


                call lcd_init_4d              ; Initialize LCD display for 4-bit interface

  ;; Clear Display Instruction
                ldi temp_r16, lcd_Clear       ; r16 = clear display instruction
                call lcd_write_instruction_4d


  ;; Initialize Registers
                clr tnth_sec_reg
                clr sec_reg
                clr min_reg
                clr hour_reg
                clr adc_res
                ;clr pgm_sts
                ldi pgm_sts, (1 << dsp_upd)

  ;; Global Interupt Enable
                sei

  ;; Intialization of port for proper analog input
                ldi temp_r16, 0b11111110
                out DDRC,temp_r16 ; set PortC to output, ADC0 input
                clr temp_r16
                out PortC,temp_r16 ; set PortC to 0V

  ;; Waiting Loop
wait_loop:      cpbit temp_r16, pgm_sts, dsp_upd, 1
                brne wait_loop

                hex_to_dec_str_two_dig sec_reg, sec_str ; Convert and store time values
                hex_to_dec_str_two_dig min_reg, min_str
                hex_to_dec_str_two_dig hour_reg, hour_str

                ldi temp_r16, $00           ; Set cursor to Begining of first line
                ori temp_r16, lcd_SetCursor       ; convert the plain address to a set cursor instruction
                call lcd_write_instruction_4d

                disp_from_sram hour_str, clk_hr_loc ; Display each part of the clock
                disp_from_pm colon_str, clk_cln1_loc
                disp_from_sram min_str, clk_mn_loc
                disp_from_pm colon_str, clk_cln2_loc
                disp_from_sram sec_str, clk_sc_loc
                andi pgm_sts, $FF - (1 << dsp_upd) ; Clear display update needed
                ldi temp_r16, 80
                call delayTx1uS ; Must have an extra delay to avoid display glitches.
                jmp wait_loop

;;; Program Constants
  .cseg
colon_str:      .db ":", 0
;;; Function Libraries
  .cseg
  ;; .include "LCD-lib.asm"
  .include "timer_fxns.inc"
