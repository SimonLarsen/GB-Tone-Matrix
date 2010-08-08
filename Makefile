main: matrix.asm
	rgbasm -o matrix.o matrix.asm
	rgblink -o matrix.gb matrix.o
	rgbfix -v matrix.gb

run: matrix.asm
	rgbasm -o matrix.o matrix.asm
	rgblink -o matrix.gb matrix.o
	rgbfix -v matrix.gb
	gambatte -s 3 matrix.gb
