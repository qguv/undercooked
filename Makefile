PYTHON := python
MD5 := md5sum -c --quiet

2bpp     := $(PYTHON) extras/pokemontools/gfx.py 2bpp
1bpp     := $(PYTHON) extras/pokemontools/gfx.py 1bpp
pic      := $(PYTHON) extras/pokemontools/pic.py compress
includes := $(PYTHON) extras/pokemontools/scan_includes.py

.SUFFIXES:
.SUFFIXES: .asm .inc .o .gbc .png .2bpp .1bpp .pic
.SECONDEXPANSION:
# Suppress annoying intermediate file deletion messages.
.PRECIOUS: %.2bpp
.PHONY: all clean compare

all: main.gbc

%.asm: ;
Makefile: ;

%.o: %.asm $(shell $(includes) main.asm)
	rgbasm -v -h -o $@ $*.asm

%.gbc: %.o
	rgblink -n $*.sym -o $@ $^
	rgbfix -v -p 0 $@

%.png:  ;
%.2bpp: %.png  ; @$(2bpp) $<
%.1bpp: %.png  ; @$(1bpp) $<
%.pic:  %.2bpp ; @$(pic)  $<
