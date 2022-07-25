#include <avr/io.h>
#ifndef __ASSEMBLER__
#define __ASSEMBLER__
#endif
#include "data.h"

; Interrupt service routine for refreshing LED cube
; Timings:
; For a 100 Hz refresh rate, each layer should be refreshed every 1/100 s continuously.
; For a 4x4x4 cube with 4 layers, each layer has 1/4th the time to do its job. Thus,
; an ISR must be fired every 1/400 s in this case. In order to use PWM with 256 levels
; (0..255), the ISR should be fired every 9.8 us. For a 8 MHz ATMega328, that means
; the ISR has 78 clock cycles to do its job.
; 
; For an 8x8x8 cube, the ISR has 97 clock cycles at its disposal.
; 
; The multiplexing is done using bit angle modulation (BAM). This works by dividing
; the total period into 8 periods, where each period is 1/2 shorter than the previous
; one. LED is set or reset during each period according to the value of the corresponding
; bit. For example, if the brightness of the LED is 154 (0x9A hex, or 0b10011010 binary),
; then the LED is lit the first half of the period, unlit the next 1/4 period, unlit the
; next 1/8 period, lit the next 1/16 period, lit the next 1/32 period, unlit the next
; 1/64 period, lit the next 1/128 period and unlit the last 1/256 period.
; If a coarser scale is enough using only even numbers, the least significant bit could 
; be skipped, which also will relax the requirements on timing, since the shortest time 
; required for the ISR will be 1/128 of the layer time.
; 
; The brightness values of the LEDs in the layer are stored into memory with
; 48 (4x4x3) bytes for the 4x4x4 cube.
;
; The full cube buffer requires 4x4x4x3 = 192 bytes for 4x4x4 RGB. This can easily fit into 
; the 2048 byte memory of Atmega328. 

.section .bss

layer_data:
	.ds.b N_DATA * N_LAYERS * N_RGB
	
frame_buffer:
	.ds.b N_DATA * N_LAYERS * N_RGB

.section .data
	
layer_no:
	.byte 0
	
layer_bit:
	.byte 1
	
transfer_data:
	.byte 0
	
counter:
	.byte 0
	
counter_period:
	.byte 8
	
lut:
	.byte 1
	.byte 8
	.byte 0
	.byte 9
	.byte 3
	.byte 11
	.byte 2
	.byte 10
	.byte 4
	.byte 12
	.byte 5
	.byte 13
	.byte 7
	.byte 15
	.byte 6
	.byte 14

.section .text

.global cube_init
; **** Initializes timer and resets cube buffer
; ****
cube_init:
	
	in r25, _SFR_IO_ADDR(SREG)
	push r25
	push XL
	push XH
	push r18
	push r19
	
	; First, set all LEDs off
	cbi _SFR_IO_ADDR(PORTC), PC5	; Output enable
	clr r18
	out _SFR_IO_ADDR(PORTD), r18
	
	sbi _SFR_IO_ADDR(PORTB), PB0
	nop
	cbi _SFR_IO_ADDR(PORTB), PB0
	
	sbi _SFR_IO_ADDR(PORTB), PB1
	nop
	cbi _SFR_IO_ADDR(PORTB), PB1
	
	sbi _SFR_IO_ADDR(PORTB), PB2
	nop
	cbi _SFR_IO_ADDR(PORTB), PB2

	sbi _SFR_IO_ADDR(PORTB), PB6
	nop
	cbi _SFR_IO_ADDR(PORTB), PB6
	
	sbi _SFR_IO_ADDR(PORTB), PB7
	nop
	cbi _SFR_IO_ADDR(PORTB), PB7
	
	sbi _SFR_IO_ADDR(PORTC), PC4
	nop
	cbi _SFR_IO_ADDR(PORTC), PC4
	
	; Then, clear layer data
	clr r19
	
	ldi XL, lo8(layer_data)
	ldi XH, hi8(layer_data)
	ldi r18, N_DATA * N_LAYERS * N_RGB
a:
	st X+, r19
	dec r18
	brne a

	; Initialize timer
	; An update frequency of 100 Hz for the cube means the following:
	; Each layer should be lit for 1/400 s, i.e. 2.5 ms
	; The PWM requires in total 8 calls to the interrupt routine, each time doubling the
	; time. Thus each call spends the following multiples of 78 us:
	; 1, 2, 4, 8, 16, 32, 64, 128
	ldi r18, 0x00
	sts TCCR1A, r18
	sts TCNT1L, r18
	sts TCNT1H, r18
	
	ldi r18, 0x09
	sts TCCR1B, r18	; CTC mode, 1x prescaler
	
	ldi r18, 0x02
	sts OCR1AH, r18
	ldi r18, 0x70
	sts OCR1AL, r18	; With 8 MHz clock, first interrupt after 78 us, corresponding to 0x0270 = 624 cycles. 

	lds r18, TIMSK1	; Enable timer interrupt
	ori r18, (1<<OCIE1A)				
	sts TIMSK1, r18

	pop r19
	pop r18
	pop XH
	pop XL
	pop r25
	out _SFR_IO_ADDR(SREG), r25
	ret
	
.global update_cube
update_cube:
	
	push r18
	ldi r18, 1
	sts transfer_data, r18
	pop r18
	ret
	
.global set_led
set_led:
	; Accepts values between 0 and 31 for R, G and B
	; r24 holds x, r22 holds y, r20 holds z, r18 holds R, r16 holds G, r14 holds B
	push r0
	push r1
	push r14
	push r16
	push r18
	push r19
	push r20
	push r21
	push r22
	push r23
	push r24
	push r25
	push YL
	push YH
	in r25, _SFR_IO_ADDR(SREG)
	
	ldi XL, lo8(frame_buffer)
	ldi XH, hi8(frame_buffer)

	ldi YL, lo8(lut)
	ldi YH, hi8(lut)
	
	; First, find offset into layer
	ldi r19, X_MAX
	mul r22, r19
	
	add r0, r24
	clr r1
	
	add YL, r0
	adc YH, r1
	
	ld r21, Y

	ldi r19, N_DATA
	mul r20, r19
	add r0, r21
	
	ldi r19, N_RGB
	mul r0, r19
	
	add XL, r0
	adc XH, r1
	
	; Multiply LED values by 8 since we are only using 5 bits for each color
	lsl r18
	lsl r18
	lsl r18
	lsl r16
	lsl r16
	lsl r16
	lsl r14
	lsl r14
	lsl r14
	
	st X+, r18
	st X+, r16
	st X, r14
	
	out _SFR_IO_ADDR(SREG), r25
	pop YH
	pop YL
	pop r25
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20
	pop r19
	pop r18
	pop r16
	pop r14
	pop r1
	pop r0
	ret
	
.global get_led
; Returns a 32-bit integer with r, g, b stored in three lowest bytes
get_led:
	; r24 holds x, r22 holds y, r20 holds z
	push r0
	push r1
	push r18
	push r19
	push r20
	push r21
	push XL
	push XH
	push YL
	push YH
	in r18, _SFR_IO_ADDR(SREG)
	
	; r24 holds x, r22 holds y, r20 holds z
	ldi XL, lo8(frame_buffer)
	ldi XH, hi8(frame_buffer)
	
	ldi YL, lo8(lut)
	ldi YH, hi8(lut)
	
	; First, find offset into layer
	ldi r19, X_MAX
	mul r22, r19
	
	add r0, r24
	clr r1
	
	add YL, r0
	adc YH, r1
	
	ld r21, Y

	ldi r19, N_DATA
	mul r20, r19
	add r0, r21
	
	ldi r19, N_RGB
	mul r0, r19
	
	add XL, r0
	adc XH, r1
	
	ld r22, X+
	ld r23, X+
	ld r24, X+
	
	lsr r22
	lsr r22
	lsr r22
	lsr r23
	lsr r23
	lsr r23
	lsr r24
	lsr r24
	lsr r24
	clr r25

	out _SFR_IO_ADDR(SREG), r18
	pop YH
	pop YL
	pop XH
	pop XL
	pop r20
	pop r21
	pop r19
	pop r18
	pop r1
	pop r0
	ret

set_layer_latch:
; **** Sets the output ports for byte no n to be latched out to the LEDs
; Input registers: X (holds memory address of layer data), r20 (holds counter_period)
; Modifies register(s): r23, r24
; Output: r18, r21, r22
; Number of cycles: 4 + 8 * (6 * 3 + 2) + 5 = 169 cycles
; ****
; Algorithm:
; There is 16x3=48 bytes for each layer
; Data is stored R, G, B for each LED in
; the layer. For each LED, extract the 
; current bit and AND it with 
; 
; ##########################################


	ldi r24, 1					; 1 cycle
	ldi r18, 0					; 1 cycle
	ldi r21, 0					; 1 cycle
	ldi r22, 0					; 1 cycle
R:
	ld r23, X+					; 2 cycles
	and r23, r20				; 1 cycle
	brne one1					; 1/2 cycles
	rjmp G						; 2 cycles
one1:
	or r18, r24					; 1 cycle
G:
	ld r23, X+					; 2 cycles
	and r23, r20				; 1 cycle
	brne one2					; 1/2 cycles
	rjmp B						; 2 cycles
one2:
	or r21, r24					; 1 cycle
B:
	ld r23, X+					; 2 cycles
	and r23, r20				; 1 cycle
	brne one3					; 1/2 cycles
	rjmp next					; 2 cycles
one3:
	or r22, r24					; 1 cycle
next:
	lsl r24						; 1 cycle
	brne R						; 1/2 cycles
	
	ret 						; 4 cycles

set_layer:
; **** Sets the whole layer according to the data in the layer buffer
; Input registers: X and r20
; Modifies register(s): r18, r21, r22, r23, r24
; Output: None
; Number of cycles: 2 * (3 + 168) + 6 * 6 + 4 = 382
; ****
	
	call set_layer_latch			; 3 + 168 cycles
	; Latch out data for R, G and B
	out _SFR_IO_ADDR(PORTD), r18	; 1 cycle
	sbi _SFR_IO_ADDR(PORTB), PB0	; 2 cycles
	nop								; 1 cycle
	cbi _SFR_IO_ADDR(PORTB), PB0	; 2 cycles
	
	out _SFR_IO_ADDR(PORTD), r21	; 1 cycle
	sbi _SFR_IO_ADDR(PORTB), PB1	; 2 cycles
	nop								; 1 cycle
	cbi _SFR_IO_ADDR(PORTB), PB1	; 2 cycles
	
	out _SFR_IO_ADDR(PORTD), r22	; 1 cycle
	sbi _SFR_IO_ADDR(PORTB), PB2	; 2 cycles
	nop								; 1 cycle
	cbi _SFR_IO_ADDR(PORTB), PB2	; 2 cycles

	call set_layer_latch			; 3 + 168 cycles
	; Latch out data for R, G and B
	out _SFR_IO_ADDR(PORTD), r18	; 1 cycle
	sbi _SFR_IO_ADDR(PORTB), PB6	; 2 cycles
	nop								; 1 cycle
	cbi _SFR_IO_ADDR(PORTB), PB6	; 2 cycles
	
	out _SFR_IO_ADDR(PORTD), r21
	sbi _SFR_IO_ADDR(PORTB), PB7
	nop
	cbi _SFR_IO_ADDR(PORTB), PB7
	
	out _SFR_IO_ADDR(PORTD), r22
	sbi _SFR_IO_ADDR(PORTC), PC4
	nop
	cbi _SFR_IO_ADDR(PORTC), PC4
	
	ret								; 4 cycles

.global TIMER1_COMPA_vect
; 88 + 382 cycles for PWM update
; 102 + 382 cycles for layer update
TIMER1_COMPA_vect:
	push r0									; 2 cycles
	in r0, _SFR_IO_ADDR(SREG)				; Save status register, 1 cycle
	push r0									; 2 cycles
	push r1									; 2 cycles
	push r18								; 2 cycles
	push r19								; 2 cycles
	push r20								; 2 cycles
	push r21								; 2 cycles
	push r22								; 2 cycles
	push r23								; 2 cycles
	push r24								; 2 cycles
	push r25
	push r26								; 2 cycles
	push r27								; 2 cycles
	push r30								; 2 cycles
	push r31								; 2 cycles
	
	; Shifts the counter_period variable to the left 1 step. If shifted out,
	; we reset and start over with a new layer.
	lds r20, counter_period					; 2 cycles
	lsl r20									; 1 cycle
	brne update_counter						; 1/2 cycles
	
	; Start over with a new layer
	; First, reset counter_period to 1 and the TOP value of the counter to its
	; lowest value.
	; For a lower resolution than 256 levels, change according to the following:
	; 128 levels: 2 -> r20, 0x9c -> OCR1AL, 0 -> OCR1AH
	; 64 levels: 4 -> r20, 0x38 -> OCR1AL, 0x01 -> OCR1AH
	; 32 levels: 8 -> r20, 0x70 -> OCR1AL, 0x02 -> OCR1AH
	; 16 levels: 16 -> r20, 0xe0 -> OCR1AL, 0x04 -> OCR1AH
	; 8 levels: 32 -> r20, 0xc0 -> OCR1AL, 0x09 -> OCR1AH
	; 4 levels: 64 -> r20, 0x80 -> OCR1AL, 0x13 -> OCR1AH
	; 2 levels: 128 -> r20, 0x00 -> OCR1AL, 0x27 -> OCR1AH
	ldi r20, 8								; 1 cycle
	ldi r18, 0x02							; 1 cycle
	sts OCR1AH, r18							; 2 cycles
	ldi r18, 0x70							; 1 cycle
	sts OCR1AL, r18							; 2 cycles
	
	; Change to new layer
	lds r19, layer_bit						; 2 cycles
	lds r25, layer_no						; 2 cycles

	; Disable old layer
	in r18, _SFR_IO_ADDR(PORTC)				; 1 cycle
	com r19									; 1 cycle
	and r18, r19							; 1 cycle
	out _SFR_IO_ADDR(PORTC), r18			; 1 cycle
	com r19									; 1 cycle
	inc r25
	lsl r19									; 1 cycle
	cpi r19, 16								; 1 cycle
	brne store_layer						; 1/2 cycles
	ldi r19, 1								; 1 cycle
	ldi r25, 0								; 1 cycle

store_layer:	
	sts layer_bit, r19   					; 2 cycles
	sts layer_no, r25						; 2 cycles
	
	; Set bits for new PWM cycle
	sts counter_period, r20					; 2 cycles

	ldi XL, lo8(layer_data)					; 1 cycle
	ldi XH, hi8(layer_data)					; 1 cycle
	
	ldi r22, N_DATA * N_RGB					; 1 cycles
	;lds r21, layer_no						; 2 cycles
	mul r22, r25							; 2 cycles
	add XL, r0								; 1 cycle
	adc XH, r1								; 1 cycle

	call set_layer							; 3 + 382 cycles

	; Enable new layer
	in r18, _SFR_IO_ADDR(PORTC)				; 1 cycle
	or r18, r19								; 1 cycle
	out _SFR_IO_ADDR(PORTC), r18			; 1 cycle

	rjmp finish								; 2 cycles

update_counter:
	; Multiply TOP value in counter by 2
	lds r18, OCR1AL							; 2 cycles
	lds r19, OCR1AH							; 2 cycles
	lsl r18									; 1 cycle
	rol r19									; 1 cycle
	sts OCR1AH, r19							; 2 cycles
	sts OCR1AL, r18							; 2 cycles

update_pwm:
	; Set bits for new PWM cycle
	sts counter_period, r20					; 2 cycles

	ldi XL, lo8(layer_data)					; 1 cycle
	ldi XH, hi8(layer_data)					; 1 cycle
	
	ldi r22, N_DATA * N_RGB					; 1 cycles
	lds r21, layer_no						; 2 cycles
	mul r22, r21							; 2 cycles
	add XL, r0								; 1 cycle
	adc XH, r1								; 1 cycle

	call set_layer							; 3 + 382 cycles
	
	; Check if last PWM cycle and last layer. If so, check if
	; new data should be transferred from the frame buffer
	lds r21, transfer_data
	tst r21
	breq finish
	lsl r20
	brcc finish
	lds r20, layer_no
	cpi r20, 3
	brne finish
	ldi XL, lo8(layer_data)					; 1 cycle
	ldi XH, hi8(layer_data)					; 1 cycle
	ldi ZL, lo8(frame_buffer)					; 1 cycle
	ldi ZH, hi8(frame_buffer)					; 1 cycle
	ldi r18, N_DATA * N_LAYERS * N_RGB
upd:
	ld r20, Z+
	st X+, r20
	dec r18
	brne upd
	clr r21
	sts transfer_data, r21

finish:
	pop r31									; 2 cycles
	pop r30									; 2 cycles
	pop r27									; 2 cycles
	pop r26									; 2 cycles
	pop r25
	pop r24									; 2 cycles
	pop r23									; 2 cycles
	pop r22									; 2 cycles
	pop r21									; 2 cycles
	pop r20									; 2 cycles
	pop r19									; 2 cycles
	pop r18									; 2 cycles
	pop r1									; 2 cycles
	pop r0									; 2 cycles
	out _SFR_IO_ADDR(SREG), r0	            ; Restore status register, 1 cycle
	pop r0									; 2 cycles
	reti									; 4 cycles
