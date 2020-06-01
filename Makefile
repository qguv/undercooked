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
	$(info $n No easily optimizable statements found! Nice work!)

# ------------------------------------------------------------------------------
# File dependencies

$(OBJDIR)/main.o: \
$(LIBDIR)/gbhw.inc $(LIBDIR)/debug.inc $(LIBDIR)/memory.asm \
$(SRCDIR)/optim.inc $(SRCDIR)/interrupts.asm $(SRCDIR)/music.asm $(SRCDIR)/smt.inc \
$(OBJDIR)/tileset.2bpp $(OBJDIR)/tileset.tilemap $(OBJDIR)/star.2bpp $(OBJDIR)/southward.2bpp

# ------------------------------------------------------------------------------
#  Release targets

$(RELEASESDIR)/$(ROMPATH): $(OBJDIR)/main.gb | $(RELEASESDIR)
	$(info $n copying release build $< to $(RELEASESDIR)/)
	cp $< $@

# ------------------------------------------------------------------------------
#  Pattern rules

$(OBJDIR)/%.o: %.asm | $(OBJDIR)
	$(info $n assembling $<...)
	rgbasm -v -E -o "$@" "$<"

$(OBJDIR)/%.gb: $(OBJDIR)/%.o
	$(info $n linking $<...)
	rgblink -n "$(OBJDIR)/$*.sym" -o "$@" "$<"
	rgbfix -v -p 0 "$@"

$(OBJDIR)/%.2bpp: $(OBJDIR)/%.png
	$(info $n formatting $< for gameboy)
	rgbgfx -o "$@" "$<"

$(OBJDIR)/%.png: $(OBJDIR)/%_wfg.png
	$(info $n correcting white foreground of $<)
	convert "$<" -fuzz 2% -fill "#eeeeee" -opaque white -background white -alpha remove "$@"

$(OBJDIR)/%.png: $(OBJDIR)/%_to16.png
	$(info $n correcting width of $<)
	convert "$<" -sample 16 "$@"

$(OBJDIR)/%.png: $(SPRITEDIR)/%.gif | $(OBJDIR) $(WORKDIR)/$(SPRITEDIR)
	$(info $n stitching together frames of $< into a tall png of frames)
	convert -coalesce "$<" "$(WORKDIR)/$*-%04d.png"
	convert "$(WORKDIR)/$*-*.png" -append $@

$(OBJDIR)/%.2bpp $(OBJDIR)/%.tilemap: $(OBJDIR)/%_tiles.png
	$(info $n creating tiles and tilemap from $<)
	rgbgfx -ut "$(OBJDIR)/$*.tilemap" -o "$@" "$<"

.INTERMEDIATE: $(OBJDIR)/%
$(OBJDIR)/%: $(SPRITEDIR)/% | $(OBJDIR)
	$(info $n retreiving sprite $<)
	cp "$<" "$@"

.INTERMEDIATE: $(WORKDIR)/$(SPRITEDIR)
$(RELEASESDIR) $(OBJDIR) $(WORKDIR)/$(SPRITEDIR):
	mkdir -p $@

# ------------------------------------------------------------------------------
#  Make internals

# echo commands prefixed with +
SHELL = /bin/env PS4='$$ ' /bin/bash -x
.SILENT: ;

VPATH := $(SRCDIR) $(LIBDIR)

# disable suffix rule interpretation
.SUFFIXES: ;

# define variable $n as a newline for $(info) invocation
define n

#
endef
