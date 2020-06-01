SRCDIR := src
OBJDIR := obj
SPRITEDIR := art
RELEASESDIR := releases
LIBDIR := lib
WORKDIR := tmp_$(shell date +%s)
ROMPATH := undercooked_$(shell git describe --tags --dirty).gb
EMULATOR := bgb -nobatt -watch

.DEFAULT_GOAL := $(RELEASESDIR)/$(ROMPATH)

# ------------------------------------------------------------------------------
#  PHONY targets

.PHONY: play
play: $(OBJDIR)/main.gb
	$(EMULATOR) "$<"

.PHONY: debug
debug: $(OBJDIR)/main.gb
	$(EMULATOR) -setting StartDebug=1 "$<"

.PHONY: clean
clean:
	rm -rf "$(OBJDIR)"

.PHONY: optimcheck
optimcheck:
	@ag '^\s*(ld\s+a,0|cp\s+0)' --ignore '*.txt' && exit 1 || exit 0
	$(info $n# No easily optimizable statements found! Nice work!)

# ------------------------------------------------------------------------------
#  Single-file recipes

$(RELEASESDIR)/$(ROMPATH): $(OBJDIR)/main.gb | $(RELEASESDIR)
	$(info $n# copying release build $< to $(RELEASESDIR)/)
	cp $< $@

$(OBJDIR)/main.o: $(SRCDIR)/smt.inc $(OBJDIR)/star.2bpp $(OBJDIR)/tileset.2bpp $(OBJDIR)/southward.2bpp

# ------------------------------------------------------------------------------
#  Pattern rules

$(OBJDIR)/%.o: %.asm | $(OBJDIR)
	$(info $n# assembling $<...)
	rgbasm -v -E -o "$@" "$<"

$(OBJDIR)/%.gb: $(OBJDIR)/%.o
	$(info $n# linking $<...)
	rgblink -n "$(OBJDIR)/$*.sym" -o "$@" "$<"
	rgbfix -v -p 0 "$@"

$(OBJDIR)/%.2bpp: $(SPRITEDIR)/%.png | $(OBJDIR)
	$(info $n# formatting sprite $< for gameboy)
	rgbgfx -o "$@" "$<"

$(OBJDIR)/%.2bpp: $(OBJDIR)/%.png
	$(info $n# formatting intermediate $< for gameboy)
	rgbgfx -o "$@" "$<"

$(OBJDIR)/%.png: $(SPRITEDIR)/%_wfg.png | $(OBJDIR)
	$(info $n# correcting white foreground of sprite $<)
	convert "$<" -fuzz 2% -fill "#eeeeee" -opaque white -background white -alpha remove "$@"

$(OBJDIR)/%.png: $(OBJDIR)/%_wfg.png
	$(info $n# correcting white foreground of intermediate $<)
	convert "$<" -fuzz 2% -fill "#eeeeee" -opaque white -background white -alpha remove "$@"

$(OBJDIR)/%.png: $(SPRITEDIR)/%_to16.png | $(OBJDIR)
	$(info $n# correcting width of $<)
	convert "$<" -sample 16 "$@"

$(OBJDIR)/%.png: $(OBJDIR)/%_to16.png
	$(info $n# correcting width of intermediate $<)
	convert "$<" -sample 16 "$@"

$(OBJDIR)/%.png: $(SPRITEDIR)/%.gif | $(OBJDIR) $(WORKDIR)/$(SPRITEDIR)
	$(info $n# stitching together frames of $< into a tall png of frames)
	convert -coalesce "$<" "$(WORKDIR)/$*-%04d.png"
	convert "$(WORKDIR)/$*-*.png" -append $@
	rm -rf "$(WORKDIR)"

$(OBJDIR)/%.2bpp: $(SPRITEDIR)/%_tiles.png | $(OBJDIR)
	$(info $n# creating tiles and tilemap from $<)
	rgbgfx -ut "$(OBJDIR)/$*.tilemap" -o "$@" "$<"

$(OBJDIR)/%.2bpp: $(OBJDIR)/%_tiles.png
	$(info $n# creating tiles and tilemap from intermediate $<)
	rgbgfx -ut "$(OBJDIR)/$*.tilemap" -o "$@" "$<"

$(RELEASESDIR) $(OBJDIR) $(WORKDIR)/$(SPRITEDIR):
	mkdir -p $@

# ------------------------------------------------------------------------------
#  Make internals

VPATH := $(SRCDIR) $(LIBDIR)

# disable suffix rule interpretation
.SUFFIXES: ;

# define variable $n as a newline for $(info) invocation
define n


endef
