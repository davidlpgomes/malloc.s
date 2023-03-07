CC = gcc
CFLAGS = -g -Wall -no-pie
PROG = malloc

all: $(PROG)

$(PROG): test.o malloc.o
	$(CC) $(CFLAGS) -o $(PROG) test.o malloc.o

test.o: test.c
	$(CC) $(CFLAGS) -c test.c -o test.o

malloc.o: malloc.h malloc.s
	as malloc.s -o malloc.o

clean:
	rm -rf *.o $(PROG)
