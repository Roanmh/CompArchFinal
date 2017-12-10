	;;; Includes
	.nolist
	.include "m328Pdef.inc"       ; Device
	.list
	  .include "roanlib.asm"        ; Handy Fxns


  ldi r16, 0
  ldi r17, 8
  ldi r18, 1
  floor_div r16, r17, r18 ; 4, 0, 1

  	ldi r16, 0
	  ldi r17, 8
	  ldi r18, 2
  	floor_div r16, r17, r18 ; 2, 0, 2

  	ldi r16, 0
	  ldi r17, 8
	  ldi r18, 3
  	floor_div r16, r17, r18 ; 1, 1, 3

  	ldi r16, 0
	  ldi r17, 4
	  ldi r18, 5
  	floor_div r16, r17, r18 ; 1, 0, 4
	nop
