all: ordipourri.phc

test2.phc: test.bin
	python bin2phc.py

ordipourri.phc: ordipourri.bin
	../../tools/create_phc op ordipourri.bin ordipourri.phc

dontfall.bas: dontfall_slowload.bin
	python ../../tools/b2bc.py dontfall_slowload.bin dontfall.bas E800

ordipourri.bin: ordipourri.asm
	z80asm ordipourri.asm -l -o ordipourri.bin

dontfall_slowload.bin: dontfall_slowload.asm dontfall.asm dontfall_tilemap.asm
	z80asm dontfall_slowload.asm -l -o dontfall_slowload.bin

dsontfall_slowload.phc: dontfall.bas
	python ../tools/

run: ordipourri.phc
	mame phc25 -autoboot_delay 0 -autoboot_script phc25_boot.lua -debug -cass ordipourri.phc

runs: dontfall_slowload.phc
	mame phc25 -autoboot_delay 0 -autoboot_script phc25_boot.lua -debug -cass dontfall_slowload.phc
