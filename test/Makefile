all: test.bin

test.bin: *.asm FORCE
	./dasm ./test.asm -l./test.lst -f3 -s./test.sym -o./test.bin
	chmod 777 ./test.bin
	exit 0

FORCE:
