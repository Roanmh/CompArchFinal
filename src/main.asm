;-------------------------------------------------------------------------------
;  main.asm
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


;;; Definitions
  ;; Register Definitions
  ;.def temp_r16=r16            ; Included in LCD-lib.asm
  .def temp_r17=r17
  .def hund_sec_reg=r18
  .def sec_reg=r19
  .def min_reg=r20
  .def hour_reg=r21

  ;; Contstant Definitions
  ;; TODO: Add Definitions


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
  .org 0x0000   jmp RESET       ; Reset Interupt Vecotor
  .org 0x001A   jmp TIMER1_OVR  ; Timer Overflow Interupt Vector.

  .org INT_VECTORS_SIZE         ; Start Rest of code after Interupt Vectors



;;; Interupt Service Routines

  ;; Timer Overflow Interupt
  .cseg                         ; This seems needed to avoid errors
TIMER1_OVR:



;;; Startup Routine
  .cseg
RESET:          init_sp         ; Initialize the Stack Pointer
