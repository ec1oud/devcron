devcrond: main.c
	$(CPP) -I/usr/include main.c -o devcrond -lx10ephem-0.50 -L.
