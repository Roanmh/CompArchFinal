;;; Includes
	.nolist
	.include "m328Pdef.inc"       ; Device
	.list
  .include "roanlib.asm"        ; Handy Fxns


;;; Definitions
  .def temp_r16=r16
  .def temp_r17=r17
  .def hund_sec_reg=r18
  .def sec_reg=r19
  .def min_reg=r20
  .def hour_reg=r21


	;;; Static Variable Planning
	.dseg
sec_str:  .byte 2          ; Counter string w/ null space


;;; Interupt Vectors
  .cseg
  .org 0x0000
               jmp RESET
  .org 0x001A                  ; This is the tiemer interupt vector.
               jmp TIMER1_OVR


;;; Beginning code above interupt vectors
  .org INT_VECTORS_SIZE
;;; Functions
  .cseg                         ; TODO: Why does this get rid of branch length errors?
  ;; Display Init
	.nolist
  .include "LCD-lib_roan.asm"
  .list

;;; Timer ISR
  .cseg
TIMER1_OVR:
  incr_time
  hex_to_dec_str_two_dig sec_reg, sec_str, temp_r17

  ldi temp_r16, $00
  ori temp_r16, lcd_SetCursor     ; convert the plain address to a set cursor instruction
  call lcd_write_instruction_4d

  ;; mov temp_r16, hund_sec_reg
  ;; hex_to_letter temp_r16
  ;; store_time_val X, sec_str
  disp_from_sram sec_str, lcd_LineOne
  reti



;;; Startup Routine
  .cseg
RESET:
;;; Init SP
  init_sp
  ;ldi r16,low(RAMEND)
  ;out SPL,r16
  ;ldi r16,high(RAMEND)
  ;out SPH,r16


;;; Set Timer Registers
  ;; Waveform Generation Mode
  .equ wgm_hi = (00 << WGM12)   ; Currently set to "Normal" Mode
  .equ wgo_lo = (00 << WGM10)
  ;; Control Registers
  ldi temp_r16, $00
  sts TCCR1A, temp_r16

  ldi temp_r16, (0b001 << CS10)   ; Clock Source (Curr: x1 Prescale)
  sts TCCR1B, temp_r16

  ldi temp_r16, $00
	sts TCCR1C, temp_r16

  ;; Interupt Mask
  ldi temp_r16, (1 << TOIE1)
  sts TIMSK1, temp_r16


  call lcd_init_4d              ; Initialize LCD display for 4-bit interface

	;; Clear Display Instruction
  ldi temp_r16, lcd_Clear       ; r16 = clear display instruction
  call lcd_write_instruction_4d


;;; Initialize Counter
  clr hund_sec_reg
  clr sec_reg
  clr min_reg
  clr hour_reg


;;; Enable Interupts
  sei                           ; Enable those interupts
sleep_loop:
  ;; Note: Trying out a more simple wait loop for now because sleep needs a more complex implementation
  ;; sleep                         ; Sleep becuase ISR handles everything now
  ;; Note: will enter sleep before any pending interrupt(s)
  jmp sleep_loop                ; Because return from the interrupt will advance the PC
