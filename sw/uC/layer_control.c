#include <avr/io.h>
#include <util/delay.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include "data.h"

#include "layer_control.h"

//extern uint8_t	layer_data[];

extern uint8_t get_led(int x, int y, int z);
extern void set_led(int x, int y, int z, int r, int g, int b);

#define SET_LED(n)		(*(led_ports[n]) |= (1 << led_pins[n]))
#define RESET_LED(n)	(*(led_ports[n]) &= ~(1 << led_pins[n]))
#define SET_LAYER(n)	(*(layer_ports[n]) |= (1 << layer_pins[n]))
#define RESET_LAYER(n)	(*(layer_ports[n]) &= ~(1 << layer_pins[n]))
#define SET_CLOCK(n)	(*(clock_ports[n]) |= (1 << clock_pins[n]))
#define RESET_CLOCK(n)	(*(clock_ports[n]) &= ~(1 << clock_pins[n]))

/**
void shift_layers(int axis, int direction) {
	
	int		i, j, k, tmp;
	
	switch(axis) {
		case 0:
			// Z axis
			for(k = 0; k < 5; ++k) {
				for(i = 0; i < 5; ++i)
					for(j = 0; j < 5; ++j) {
						tmp = get_led(i, j, k);
						set_led(i, j, k - 1, tmp);
						set_led(i, j, k, tmp >> 1);
					}
			}
			break;
		case 1:
			// Y axis
			break;
		case 2:
			// X axis
			break;
		default:
			break;
	}
}

void set_led(int x, int y, int z, int value) {
	
	int		bit = x + 5 * (y + 5 * z);
	
	layer_data[bit] = value << 2;
}

int get_led(int x, int y, int z) {

	int	bit = x + 5 * (y + 5 * z);
	
	return (layer_data[bit] >> 2) & 0x3f;
}

void set_layer(uint8_t *data, int layer) {
	
	int	i, j;
	
	for(i = 0; i < X_MAX; ++i)
		for(j = 0; j < Y_MAX; ++j)
			set_led(i, j, layer, data[i + X_MAX * j]);
}
*/