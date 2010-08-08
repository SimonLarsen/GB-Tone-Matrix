EMU=gambatte -s 3

main: matrix.asm
	rgbasm -o matrix.o matrix.asm
	rgblink -o matrix.gb matrix.o
	rgbfix -v matrix.gb

run: matrix.asm
	rgbasm -o matrix.o matrix.asm
	rgblink -o matrix.gb matrix.o
	rgbfix -v matrix.gb
	$(EMU) matrix.gb
