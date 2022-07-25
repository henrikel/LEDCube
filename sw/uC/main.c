#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#ifdef __ASSEMBLER__
#undef __ASSEMBLER__
#endif
#include "data.h"
//#include "layer_control.h"
#include "effects.h"
//#include "serial_comm.h"

//volatile uint8_t	layer_data[N_DATA * N_LAYERS];

uint8_t	*led_ports[] = {&PORTD, &PORTD, &PORTD, &PORTD, &PORTD, &PORTD,
                                    &PORTD, &PORTD};
uint8_t	*layer_ports[] = {&PORTC, &PORTC, &PORTC, &PORTC};
uint8_t	*clock_ports[] = {&PORTB, &PORTB, &PORTB, &PORTB, &PORTB, &PORTC};
uint8_t led_pins[] = {0, 1, 2, 3, 4, 5, 6, 7};
uint8_t layer_pins[] = {0, 1, 2, 3};
uint8_t clock_pins[] = {0, 1, 2, 6, 7, 4};

extern void cube_init();
extern void update_cube();

// Pin configuration as follows:
// PC0: cathode 1
// PC1: cathode 2
// PC2: cathode 3
// PC3: cathode 4
//
// PD0: data 1
// PD1: data 2
// PD2: data 3
// PD3: data 4
// PD4: data 5
// PD5: data 6
// PD6: data 7
// PD7: data 8
//
// PB0: R clock 1
// PB1: G clock 1
// PB2: B clock 1
// PB6: R clock 2
// PB7: G clock 2
// PC4: B clock 2
//
// PC5: output enable (active low)

extern void set_led(int x, int y, int z, int r, int g, int b);

int main(int argc, char **argv) {
	
	// Initialize ports
	DDRB |= _BV(PB0);
	DDRB |= _BV(PB1);
	DDRB |= _BV(PB2);
	DDRB |= _BV(PB6);
	DDRB |= _BV(PB7);
	
	DDRC |= _BV(PC0);
	DDRC |= _BV(PC1);
	DDRC |= _BV(PC2);
	DDRC |= _BV(PC3);
	DDRC |= _BV(PC4);
	DDRC |= _BV(PC5);
	
	DDRD |= _BV(PD0);
	DDRD |= _BV(PD1);
	DDRD |= _BV(PD2);
	DDRD |= _BV(PD3);
	DDRD |= _BV(PD4);
	DDRD |= _BV(PD5);
	DDRD |= _BV(PD6);
	DDRD |= _BV(PD7);
	
	// Output disable
	PORTC |= _BV(PC5);
	
	// LED cathodes
	PORTC &= ~_BV(PC0);
	PORTC &= ~_BV(PC1);
	PORTC &= ~_BV(PC2);
	PORTC &= ~_BV(PC3);
	
	// Initialize cube
	cube_init();
	sei();
	
	while(1) {
		rain(100);
		spiral(10);
		rain(50);
		planes2(4);
	}
}