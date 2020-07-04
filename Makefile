SRCDIR := src
OBJDIR := obj
SPRITEDIR := art
RELEASESDIR := releases
LIBDIR := lib
ROMPATH := undercooked_$(shell git describe --tags --dirty).gb
EMULATOR := bgb -nobatt -watch

.DEFAULT_GOAL := $(RELEASESDIR)/$(ROMPATH)

# ------------------------------------------------------------------------------
#  PHONY targets

.PHONY: play
play: $(OBJDIR)/main.gb
	nohup $(EMULATOR) "$<" >/dev/null &

.PHONY: debug
debug: $(OBJDIR)/main.gb
	nohup $(EMULATOR) -setting StartDebug=1 "$<" >/dev/null &

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
$(SRCDIR)/sprites.asm $(SRCDIR)/tiles.asm \
$(LIBDIR)/gbhw.inc $(LIBDIR)/debug.inc $(LIBDIR)/memory.asm \
$(SRCDIR)/optim.inc $(SRCDIR)/interrupts.asm $(SRCDIR)/music.asm $(SRCDIR)/smt.asm \
$(OBJDIR)/house.2bpp $(OBJDIR)/house.tilemap $(OBJDIR)/star.2bpp $(OBJDIR)/southward.2bpp

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

$(OBJDIR)/%.png: $(SPRITEDIR)/%.gif | $(OBJDIR)
	$(info $n stitching together frames of $< into a tall png of frames)
	convert -coalesce '$<' -append '$@'

$(OBJDIR)/%.nframes: $(SPRITEDIR)/%.gif | $(OBJDIR)
	$(info $n counting frames of $< into $@)
	printf '\x'"$$(printf '%02d\n' "$$(identify -format '%n\n' '$<' | head -n 1)")" > '$@'

$(OBJDIR)/%.2bpp $(OBJDIR)/%.tilemap: $(OBJDIR)/%_bg.png
	$(info $n extracting unique tiles from $<)
	rgbgfx \
		--unique-tiles \
		--tilemap "$(OBJDIR)/$*.tilemap" \
		--output "$@" \
		"$<"

$(OBJDIR)/%.2bpp $(OBJDIR)/%.tilemap $(OBJDIR)/%.attrmap: $(OBJDIR)/%_sprite.png
	$(info $n extracting unique tiles from $< and writing mirror flags)
	rgbgfx \
		--mirror-tiles \
		--tilemap "$(OBJDIR)/$*.tilemap" \
		--attr-map "$(OBJDIR)/$*.attrmap" \
		--output "$@" \
		"$<"

.INTERMEDIATE: $(OBJDIR)/%
$(OBJDIR)/%: $(SPRITEDIR)/% | $(OBJDIR)
	$(info $n retreiving sprite $<)
	cp "$<" "$@"

$(RELEASESDIR) $(OBJDIR):
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
