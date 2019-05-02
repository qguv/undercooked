SRCDIR = src
OBJDIR = obj
SPRITEDIR = sprites
MAPDIR = maps
LIBDIR = lib
WORKDIR := tmp_$(shell date +%s)
ROMPATH := ./undercooked_$(shell git describe --tags --dirty).gb
EMULATOR := bgb -nobatt

.SUFFIXES:
.PRECIOUS: $(OBJDIR)/%.png $(OBJDIR)/%.o

VPATH = $(SRCDIR) $(LIBDIR)

.PHONY: build
build: $(ROMPATH)

.PHONY: all
all: build

$(ROMPATH): $(OBJDIR)/main.gb
	cp $< $@

%.asm: ;

$(OBJDIR)/%.o: %.asm $(OBJDIR)/star.2bpp $(OBJDIR)/table.2bpp $(OBJDIR)/ground.2bpp $(OBJDIR)/tileset.2bpp $(OBJDIR)/overcooked.2bpp fix $(OBJDIR)/sadcat.2bpp
	@mkdir -p $(OBJDIR)
	rgbasm -v -E -o $@ $<

$(OBJDIR)/%.gb: $(OBJDIR)/%.o
	rgblink -n $(OBJDIR)/$*.sym -o $@ $<
	rgbfix -v -p 0 $@

$(OBJDIR)/%.2bpp: $(SPRITEDIR)/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -o $@ $<

# turn gif frames into a tall png of appended frames
$(OBJDIR)/%.png: $(SPRITEDIR)/%.gif
	@mkdir -p $(OBJDIR)
	@mkdir -p $(WORKDIR)/$(SPRITEDIR)
	convert -coalesce $< $(WORKDIR)/$*-%04d.png
	convert $(WORKDIR)/$*-*.png -append $@
	rm -rf $(WORKDIR)

# turn a tall png representing an animation into 2bpp
$(OBJDIR)/%.2bpp: $(OBJDIR)/%.png
	rgbgfx -o $@ $<

# turn a map into a bunch of tiles and a tilemap of tile indexes
$(OBJDIR)/%.2bpp: $(MAPDIR)/%.png
	@mkdir -p $(OBJDIR)
	rgbgfx -ut $(OBJDIR)/$*.tilemap -o $@ $<

.PHONY: fix
fix: $(OBJDIR)/sadcat.png
	mogrify -sample 16 +negate -fuzz 2% -fill "#a8a8a8" -opaque white $<

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
