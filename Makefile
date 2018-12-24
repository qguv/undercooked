PYTHON := python2
MD5 := md5sum -c --quiet

png      := $(PYTHON) extras/pokemontools/gfx.py png
2bpp     := $(PYTHON) extras/pokemontools/gfx.py 2bpp
1bpp     := $(PYTHON) extras/pokemontools/gfx.py 1bpp
pic      := $(PYTHON) extras/pokemontools/pic.py compress
includes := $(PYTHON) extras/pokemontools/scan_includes.py

.SUFFIXES:
.SUFFIXES: .asm .inc .o .gb .png .2bpp .1bpp .pic
.SECONDEXPANSION:
# Suppress annoying intermediate file deletion messages.
.PRECIOUS: %.2bpp
.PHONY: all clean compare export play

all: star.2bpp main.gb

export: main.png

%.asm: ;
Makefile: ;

%.o: %.asm $(shell $(includes) main.asm)
	rgbasm -v -h -o $@ $*.asm

%.gb: %.o
	rgblink -n $*.sym -o $@ $^
	rgbfix -v -p 0 $@

%.2bpp: %.png ; rgbgfx -o $@ $^
%.1bpp: %.png  ; rgbgfx -o $@ $^
%.pic:  %.2bpp ; @$(pic)  $<
#%.png:  %.2bpp ; @$(png)  $<

play: main.gb
	bgb main.gb

clean:
	rm -f main.sym
	rm -f main.o
	rm -f main.gb
	rm -f star.2bpp
