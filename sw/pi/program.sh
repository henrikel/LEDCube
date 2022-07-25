gpio -g mode 23 out
gpio -g write 23 0
make
gpio -g write 23 1
