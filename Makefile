all: chess.bin

.PHONY: characters
.PHONY: gfx

characters:
#	cd charset && python icc.py

chess.bin: *.asm Makefile FORCE
	osascript -e 'quit app "Stella"'
	(cd ./gfx && python ConvertChessPieces.py)
	python tools/grid.py
	../dasmx/dasm/bin/dasm ./chess.asm -E0 -S -p20 -l./chess.lst -f3 -v1 -DTIA_BASE_ADDRESS=$40 -s./chess.sym -T1 -o./chess.bin || (echo "mycommand failed $$?"; exit 1)
	cp ./chess.bin ~/Nextcloud/My\ ROMs
	open -a /Applications/Stella.app ./chess.bin --args -ld B -rd B -rc atarivox -avoxport /dev/cu.usbserial-A50285BI

force:
#	echo "force"

../sprites/spriteData.asm: ../sprites/*.png
	echo 'Building SPRITE data'
	python ../tools/sprite.py


#test.bin: test.asm FORCE Makefile
#	tools/dasm ./test.asm -l./test.txt -f3 -s./test.sym -o./test.bin
#	open -a Stella ./test.bi
#	exit 0


FORCE:
