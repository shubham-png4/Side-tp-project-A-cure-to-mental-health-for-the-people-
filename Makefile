# Build with `make`, run with `make run`, clean up with `make clean`.
CC ?= gcc
FLAGS ?= -std=c11 -Wall -Wextra -g

main: main.c
	$(CC) $(FLAGS) main.c -o main -lm

run: main
	./main

clean:
	rm -f main main.exe

.PHONY: run clean
