all: chess3E+.3E+

.PHONY: characters
.PHONY: gfx

characters:
#	cd charset && python icc.py

chess3E+.3E+: *.asm Makefile FORCE
	osascript -e 'quit app "Stella"'
	(cd ./gfx && python ConvertChessPieces.py)
#		python tools/grid.py
	../dasm/bin/dasm ./chess.asm -l./chess3E+.lst -f3 -s./chess3E+.sym -o./chess3E+.3E+ || (echo "mycommand failed $$?"; exit 1)
	open -a /Applications/Stella.app ./chess3E+.3E+

force:
#	echo "force"

../sprites/spriteData.asm: ../sprites/*.png
	echo 'Building SPRITE data'
	python ../tools/sprite.py


#test.bin: test.asm FORCE Makefile
#	tools/dasm ./test.asm -l./test.txt -f3 -s./test.sym -o./test.bin
#	open -a Stella ./test.bin
#	exit 0


FORCE:
