SRCDIR = src
OBJDIR = obj
OUTDIR = .
SPRITEDIR = sprites
LIBDIR = lib
EXTRASDIR = extras

BGB := wine $(EXTRASDIR)/bgb/bgb.exe
PYTHON2 := python2
MD5 := md5sum -c --quiet

png      := $(PYTHON2) $(EXTRASDIR)/pokemontools/gfx.py png
2bpp     := $(PYTHON2) $(EXTRASDIR)/pokemontools/gfx.py 2bpp
1bpp     := $(PYTHON2) $(EXTRASDIR)/pokemontools/gfx.py 1bpp
pic      := $(PYTHON2) $(EXTRASDIR)/pokemontools/pic.py compress
includes := $(PYTHON2) $(EXTRASDIR)/pokemontools/scan_includes.py

.SUFFIXES:
.SUFFIXES: .asm .inc .o .gb .png .2bpp .1bpp .pic
.SECONDEXPANSION:
# Suppress annoying intermediate file deletion messages.
.PRECIOUS: %.2bpp
.PHONY: all clean debug optimcheck play

VPATH = $(SRCDIR) $(LIBDIR) $(SPRITEDIR)

all: $(OBJDIR)/star.2bpp $(OUTDIR)/main.gb

%.asm: ;

$(OBJDIR)/%.o: %.asm $(shell $(includes) src/main.asm)
	mkdir -p $(OBJDIR)
	rgbasm -v -h -o $@ $<

$(OUTDIR)/%.gb: $(OBJDIR)/%.o
	rgblink -n $(OBJDIR)/$*.sym -o $@ $^
	rgbfix -v -p 0 $@

$(OBJDIR)/%.2bpp: %.png
	mkdir -p $(OBJDIR)
	rgbgfx -o $@ $^

$(OBJDIR)/%.1bpp: %.png
	mkdir -p $(OBJDIR)
	rgbgfx -o $@ $^

$(OBJDIR)/%.pic: %.2bpp
	mkdir -p $(OBJDIR)
	@$(pic) $<

play: all
	$(BGB) -nobatt $(OUTDIR)/main.gb

debug: all
	$(BGB) -setting StartDebug=1 -nobatt $(OUTDIR)/main.gb

clean:
	rm -rf $(OBJDIR)
	rm -f $(OUTDIR)/main.gb

optimcheck:
	@ag '^\s*(ld\s+a,0|cp\s+0)' --ignore '*.txt' && exit 1 || exit 0
	@printf "No easily optimizable statements found! Nice work!\n"
