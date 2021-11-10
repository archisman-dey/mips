CC = iverilog
FLAGS = -Wall -Winfloop -g2005-sv

all: init.py test.asm mips.v
	python3 init.py
	$(CC) $(FLAGS) -o test mips.v

	vvp test
	rm test

iverilog: mips.v
	$(CC) $(FLAGS) -o test mips.v

	vvp test
	rm test
