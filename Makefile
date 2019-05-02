SRCDIR = src
OBJDIR = obj
SPRITEDIR = sprites
MAPDIR = maps
LIBDIR = lib
ROMPATH := ./undercooked_$(shell git describe --tags --dirty).gb
EMULATOR := bgb -nobatt

.SUFFIXES:
.SUFFIXES: .asm .inc .o .gb .png .2bpp .1bpp
.SECONDEXPANSION:
# Suppress annoying intermediate file deletion messages.
.PRECIOUS: %.2bpp

VPATH = $(SRCDIR) $(LIBDIR)

.PHONY: build
build: $(ROMPATH)

.PHONY: all
all: build

$(ROMPATH): $(OBJDIR)/main.gb
	cp $< $@

%.asm: ;

$(OBJDIR)/%.o: %.asm $(OBJDIR)/star.2bpp $(OBJDIR)/table.2bpp $(OBJDIR)/ground.2bpp $(OBJDIR)/tileset.2bpp
	@mkdir -p $(OBJDIR)
	rgbasm -v -E -o $@ $<

$(OBJDIR)/%.gb: $(OBJDIR)/%.o
	rgblink -n $(OBJDIR)/$*.sym -o $@ $<
	rgbfix -v -p 0 $@

$(OBJDIR)/%.2bpp: $(SPRITEDIR)/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -o $@ $<

$(OBJDIR)/%.2bpp: $(MAPDIR)/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -ut $(OBJDIR)/$*.tilemap -o $@ $<

$(OBJDIR)/%.1bpp: $(SPRITEDIR)/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -o $@ $<

$(OBJDIR)/%.1bpp: $(MAPDIR)/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -ut $(OBJDIR)/$*.tilemap -o $@ $<

.PHONY: play
play: all
	$(EMULATOR) $(OBJDIR)/main.gb

.PHONY: debug
debug: all
	$(BGB) -setting StartDebug=1 -nobatt $(OBJDIR)/main.gb

.PHONY: clean
clean:
	rm -rf $(OBJDIR)
	rm -f $(ROMPATH)

.PHONY: optimcheck
optimcheck:
	@ag '^\s*(ld\s+a,0|cp\s+0)' --ignore '*.txt' && exit 1 || exit 0
	@printf "No easily optimizable statements found! Nice work!\n"
