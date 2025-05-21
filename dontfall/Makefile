all: dontfall.phc dontfall_slowload.phc

test2.phc: test.bin
	python bin2phc.py

dontfall.phc: dontfall.bin
	../../tools/create_phc df dontfall.bin dontfall.phc

test.txt: test.bin bin2data.py
	python bin2data.py test.bin > test.txt

dontfall.bas: dontfall_slowload.bin
	python ../../tools/b2bc.py dontfall_slowload.bin dontfall.bas E800

dontfall_tilemap.asm: tilemap.tmx levels.tmx
	python generate_tilemap.py > dontfall_tilemap.asm

dontfall.bin: dontfall_fast.asm dontfall.asm dontfall_tilemap.asm
	z80asm dontfall_fast.asm -l -o dontfall.bin

dontfall_slowload.bin: dontfall_slowload.asm dontfall.asm dontfall_tilemap.asm
	z80asm dontfall_slowload.asm -l -o dontfall_slowload.bin

dsontfall_slowload.phc: dontfall.bas
	python ../tools/

run: dontfall.phc
	mame phc25 -autoboot_delay 0 -autoboot_script phc25_boot.lua -debug -cass dontfall.phc

runs: dontfall_slowload.phc
	mame phc25 -autoboot_delay 0 -autoboot_script phc25_boot.lua -debug -cass dontfall_slowload.phc
