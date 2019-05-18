SRCDIR = src
OBJDIR = obj
SPRITEDIR = sprites
MAPDIR = maps
LIBDIR = lib
WORKDIR := tmp_$(shell date +%s)
ROMPATH := ./undercooked_$(shell git describe --tags --dirty).gb
EMULATOR := bgb -nobatt

# disable suffix rule interpretation
.SUFFIXES:

# don't remove intermediate files
.SECONDARY:

VPATH = $(SRCDIR) $(LIBDIR)

.PHONY: build
build: $(ROMPATH)

$(ROMPATH): $(OBJDIR)/main.gb
	cp $< $@

$(OBJDIR)/%.o: %.asm $(OBJDIR)/star.2bpp $(OBJDIR)/table.2bpp $(OBJDIR)/ground.2bpp $(OBJDIR)/tileset.2bpp $(OBJDIR)/overcooked.2bpp $(OBJDIR)/sadcat.2bpp
	@printf "\nassembling $<...\n"
	@mkdir -p $(OBJDIR)
	rgbasm -v -E -o $@ $<

$(OBJDIR)/%.gb: $(OBJDIR)/%.o
	@printf "\nlinking $<...\n"
	rgblink -n $(OBJDIR)/$*.sym -o $@ $<
	rgbfix -v -p 0 $@

# format a sprite for the gameboy directly (no intermediates)
$(OBJDIR)/%.2bpp: $(SPRITEDIR)/%.png
	@printf "\nformatting $< for gameboy\n"
	@mkdir -p $(OBJDIR)
	rgbgfx -o $@ $<

# format an intermediate png for the gameboy
$(OBJDIR)/%.2bpp: $(OBJDIR)/%.png
	@printf "\nformatting $< for gameboy\n"
	rgbgfx -o $@ $<

# correct sprites that use white in the foreground to use a different palette
$(OBJDIR)/%.png: $(SPRITEDIR)/%_wfg.png
	@printf "\ncorrecting foreground-white $<\n"
	convert $< -fuzz 2% -fill "#eeeeee" -opaque white -background white -alpha remove $@

# correct intermediate pngs that use white in the foreground to use a different palette
$(OBJDIR)/%.png: $(OBJDIR)/%_wfg.png
	@printf "\ncorrecting foreground-white $<\n"
	convert $< -fuzz 2% -fill "#eeeeee" -opaque white -background white -alpha remove $@

# correct widths of sprites
$(OBJDIR)/%.png: $(SPRITEDIR)/%_to16.png
	@printf "\ncorrecting width of $<\n"
	convert $< -sample 16 $@

# correct widths of intermediate pngs
$(OBJDIR)/%.png: $(OBJDIR)/%_to16.png
	@printf "\ncorrecting width of $<\n"
	convert $< -sample 16 $@

# turn gif frames into a tall png of appended frames
$(OBJDIR)/%.png: $(SPRITEDIR)/%.gif
	@printf "\nstitching together frames of $<\n"
	@mkdir -p $(OBJDIR)
	@mkdir -p $(WORKDIR)/$(SPRITEDIR)
	convert -coalesce $< $(WORKDIR)/$*-%04d.png
	convert $(WORKDIR)/$*-*.png -append $@
	rm -rf $(WORKDIR)

# turn a map into a bunch of tiles and a tilemap of tile indexes
$(OBJDIR)/%.2bpp: $(MAPDIR)/%.png
	@printf "\ncreating tiles and tilemap from $<\n"
	@mkdir -p $(OBJDIR)
	rgbgfx -ut $(OBJDIR)/$*.tilemap -o $@ $<

.PHONY: play
play: $(OBJDIR)/main.gb
	$(EMULATOR) $<

.PHONY: debug
debug: build
	$(BGB) -setting StartDebug=1 -nobatt $(OBJDIR)/main.gb

.PHONY: clean
clean:
	rm -rf $(OBJDIR)

.PHONY: optimcheck
optimcheck:
	@ag '^\s*(ld\s+a,0|cp\s+0)' --ignore '*.txt' && exit 1 || exit 0
	@printf "No easily optimizable statements found! Nice work!\n"
