#include <avr/io.h>
#include <util/delay.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include "effects.h"

#define X_MAX	4
#define Y_MAX	4
#define Z_MAX	4

#define N1		30
#define N2		7
#define N3		36
#define N4		36

// Going around triangle in xy space
int	r1[] = {0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 27, 24, 21, 18, 15, 12, 9, 6, 3, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0},
    g1[] = {30, 27, 24, 21, 18, 15, 12, 9, 6, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              3, 6, 9, 12, 15, 18, 21, 24, 27},
    b1[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30,
              27, 24, 21, 18, 15, 12, 9, 6, 3};

// Smaller subset of above
int	r2[] = {0, 15, 30, 15, 0,0, 0},
    g2[] = {30, 15, 0, 0, 0, 15, 30},
    b2[] = {0, 0, 0, 15, 30, 15, 0};
    
int r3[] = {31, 31, 31, 31, 29, 28, 26, 24, 22, 20, 18, 15, 14, 12, 10,  9,  7,
             7,  6,  6,  6,  7,  9, 10, 12, 15, 17, 20, 23, 25, 28, 30, 31, 31,
            31, 31},
	g3[] = {7,  7,  7,  8,  8,  8,  9,  9,  9, 10, 10, 10, 11, 11, 11, 11, 11,
           12, 11, 11, 11, 11, 11, 10, 10,  9,  9,  8,  8,  7,  7,  7,  7,  6,
            6,  7},
	b3[] = {12, 10,  8,  7,  6,  5,  4,  4,  4,  4,  4,  4,  5,  6,  7,  9, 10,
            12, 14, 16, 18, 19, 21, 22, 24, 24, 25, 25, 24, 23, 22, 21, 19, 17,
            15, 13};
            
int r4[] = {17, 16, 16, 15, 14, 13, 12, 11, 10,  8,  7,  6,  5,  4,  3,  2,  1,
             1,  0,  0,  0,  1,  1,  2,  4,  5,  7,  9, 10, 12, 14, 15, 16, 17,
            17, 17},
	g4[] = {2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
            5, 5, 4, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2},
	b4[] = {5,  4,  3,  2,  1,  1,  0,  0,  0,  0,  0,  1,  1,  2,  2,  3,  4,
            5,  6,  7,  9, 10, 11, 12, 12, 13, 13, 13, 13, 12, 12, 11, 10,  8,
            7,  6};

extern void set_led(int x, int y, int z, int r, int g, int b);
extern uint32_t get_led(int x, int y, int z);
extern void update_cube();

void shift_layers(int axis, int direction) {
	
	int			i, j, k;
	uint8_t		r, g, b;
	uint32_t	tmp;
	
	switch(axis) {
		case 0:
			// Z axis
			for(k = 0; k < Z_MAX; ++k) {
				for(i = 0; i < Y_MAX; ++i)
					for(j = 0; j < X_MAX; ++j) {
						tmp = get_led(i, j, k);
						r = tmp & 0x000000ff;
						g = (tmp >> 8) & 0x000000ff;
						b = (tmp >> 16) & 0x000000ff;
						set_led(i, j, k - 1, r, g, b);
						set_led(i, j, k, r >> 2, g >> 2, b >> 2);
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

void rain(int iterations) {
	
	int	i, ii, rnd_x, rnd_y, rnd_num, rnd_col, rnd_int, r, g, b;
	
	for(ii = 0; ii < iterations; ++ii) {
		rnd_num = rand() % 4;
		for(i = 0; i < rnd_num; i++) {
			rnd_col = rand() % N2;
			rnd_int = rand() & 4;
			r = r2[rnd_col] >> rnd_int;
			g = g2[rnd_col] >> rnd_int;
			b = b2[rnd_col] >> rnd_int;
			rnd_x = rand() % 4;
			rnd_y = rand() % 4;
			set_led(rnd_x, rnd_y, Z_MAX - 1, r, g, b);
			
		}
		update_cube();
		_delay_ms(200);
		for(i = 0; i < Z_MAX + 3; ++i) {
			shift_layers(0, -1);
			update_cube();
			_delay_ms(100);
		}
	}
}

void planes2(int niters) {
	
	int		i, j, k, l, r, g, b, m;
	
	for(m = 0; m < niters; ++m) {
		for(l = 0; l < N4 / 6; ++l) {
			r = r4[l*6];
			g = g4[l*6];
			b = b4[l*6];
			for(k = 0; k < Z_MAX; ++k) {
				for(i = 0; i < X_MAX; ++i)
					for(j = 0; j < Y_MAX; ++j)
						set_led(i, j, k, r, g, b);
				update_cube();
				_delay_ms(100);
			}
			_delay_ms(400);
			r = r4[l*6+1];
			g = g4[l*6+1];
			b = b4[l*6+1];
			for(j = 0; j < Y_MAX; ++j) {
				for(k = 0; k < Z_MAX; ++k)
					for(i = 0; i < X_MAX; ++i)
						set_led(i, j, k, r, g, b);
				update_cube();
				_delay_ms(100);
			}
			_delay_ms(400);
			r = r4[l*6+2];
			g = g4[l*6+2];
			b = b4[l*6+2];
			for(j = Y_MAX - 1; j >= 0; --j) {
				for(k = 0; k < Z_MAX; ++k)
					for(i = 0; i < X_MAX; ++i)
						set_led(i, j, k, r, g, b);
				update_cube();
				_delay_ms(100);
			}
			_delay_ms(400);
			r = r4[l*6+3];
			g = g4[l*6+3];
			b = b4[l*6+3];
			for(i = 0; i < X_MAX; ++i) {
				for(k = 0; k < Z_MAX; ++k)
					for(j = 0; j < Y_MAX; ++j)
						set_led(i, j, k, r, g, b);
				update_cube();
				_delay_ms(100);
			}
			_delay_ms(400);
			r = r4[l*6+4];
			g = g4[l*6+4];
			b = b4[l*6+4];
			for(i = X_MAX - 1; i >= 0; --i) {
				for(k = 0; k < Z_MAX; ++k)
					for(j = 0; j < Y_MAX; ++j)
						set_led(i, j, k, r, g, b);
				update_cube();
				_delay_ms(100);
			}
			_delay_ms(400);
			r = r4[l*6+5];
			g = g4[l*6+5];
			b = b4[l*6+5];
			for(k = Z_MAX - 1; k >= 0; --k) {
				for(i = 0; i < X_MAX; ++i)
					for(j = 0; j < Y_MAX; ++j)
						set_led(i, j, k, r, g, b);
				update_cube();
				_delay_ms(100);
			}
			_delay_ms(400);
		}
	}
}

#define RADIUS	1.4

void spiral(int niters) {
	
	double		t1, z1;
	double		x, y;
	int			rnd_col = 0, r, g, b, i;
	
	for(i = 0; i < niters; ++i) {
		t1 = z1 = 0.0;
		while(z1 < Z_MAX) {
	
			r = r4[rnd_col % N4];
			g = g4[rnd_col % N4];
			b = b4[rnd_col % N4];
	
			x = RADIUS * cos(t1) + 1.5;
			y = RADIUS * sin(t1) + 1.5;
			set_led((int)round(x), (int)round(y), (int)round(z1), r, g, b);
	
			t1 += 0.05;
			if(t1 >= 2.0 * M_PI)
				t1 = 0.0;
			z1 += 0.005;
			update_cube();
			_delay_ms(5);
		
			rnd_col += 1;
		}
	
		t1 = z1 = 0.0;
	
		while(z1 < Z_MAX) {
	
			x = RADIUS * cos(t1) + 1.5;
			y = RADIUS * sin(t1) + 1.5;
			set_led((int)round(x), (int)round(y), (int)round(z1), 0, 0, 0);
	
			t1 += 0.05;
			if(t1 >= 2.0 * M_PI)
				t1 = 0.0;
			z1 += 0.005;
			update_cube();
			_delay_ms(5);
		
		}
	}
}
