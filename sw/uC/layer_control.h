#ifndef LAYER_CONTROL_H
#define LAYER_CONTROL_H

#define N_LED	25
#define X_MAX	5
#define Y_MAX	5
#define Z_MAX	5

//void init_layers(void);
void shift_layers(int axis, int direction);
//void set_led(int x, int y, int z, int value);
//int get_led(int x, int y, int z);
//void set_layer(uint8_t *data, int layer);

#endif