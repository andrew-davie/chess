all: chess.bin

.PHONY: characters
.PHONY: gfx

characters:
#	cd charset && python icc.py

chess.bin: *.asm Makefile FORCE
		python clearTerminal.py
		(cd gfx && python ConvertChessPieces.py)
#		python tools/grid.py
		../dasm/bin/dasm ./chess.asm -l./chess.lst -f3 -s./chess.sym -o./chess.bin || (echo "mycommand failed $$?"; exit 1)
#    done
	chmod 777 ./chess.bin
	../stella/stella -rd A ./chess.bin
	exit 0

force:
#	echo "force"

sprites/spriteData.asm: sprites/*.png
	echo 'Building SPRITE data'
	python tools/sprite.py


#test.bin: test.asm FORCE Makefile
#	tools/dasm ./test.asm -l./test.txt -f3 -s./test.sym -o./test.bin
#	open -a Stella ./test.bin
#	exit 0


FORCE:
