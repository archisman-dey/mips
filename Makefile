CC = iverilog
FLAGS = -Wall -Winfloop -g2005-sv

all: mips.v
	$(CC) $(FLAGS) -o test mips.v

	vvp test
	rm test
