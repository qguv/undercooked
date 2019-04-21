SRCDIR = src
OBJDIR = obj
OUTDIR = .
SPRITEDIR = sprites
MAPDIR = maps
LIBDIR = lib

BGB := bgb

.SUFFIXES:
.SUFFIXES: .asm .inc .o .gb .png .2bpp .1bpp
.SECONDEXPANSION:
# Suppress annoying intermediate file deletion messages.
.PRECIOUS: %.2bpp

VPATH = $(SRCDIR) $(LIBDIR)

.PHONY: all
all: $(OUTDIR)/main.gb

$(OBJDIR):

%.asm: ;

$(OBJDIR)/%.o: %.asm $(OBJDIR)/star.2bpp $(OBJDIR)/table.2bpp $(OBJDIR)/ground.2bpp $(OBJDIR)/tileset.2bpp
	@mkdir -p $(OBJDIR)
	rgbasm -v -o $@ $<

$(OUTDIR)/%.gb: $(OBJDIR)/%.o
	rgblink -n $(OBJDIR)/$*.sym -o $@ $<
	rgbfix -v -p 0 $@

$(OBJDIR)/%.2bpp: sprites/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -o $@ $<

$(OBJDIR)/%.2bpp: maps/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -ut $(OBJDIR)/$*.tilemap -o $@ $<

$(OBJDIR)/%.1bpp: sprites/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -o $@ $<

$(OBJDIR)/%.1bpp: maps/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -ut $(OBJDIR)/$*.tilemap -o $@ $<

.PHONY: play
play: all
	$(BGB) -nobatt $(OUTDIR)/main.gb

.PHONY: debug
debug: all
	$(BGB) -setting StartDebug=1 -nobatt $(OUTDIR)/main.gb

.PHONY: clean
clean:
	rm -rf $(OBJDIR)
	rm -f $(OUTDIR)/main.gb

.PHONY: optimcheck
optimcheck:
	@ag '^\s*(ld\s+a,0|cp\s+0)' --ignore '*.txt' && exit 1 || exit 0
	@printf "No easily optimizable statements found! Nice work!\n"
