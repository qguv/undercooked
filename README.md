# undercooked

[![build status](https://github.com/qguv/undercooked/workflows/build/badge.svg?branch=master)](https://github.com/qguv/undercooked/actions?query=workflow%3Abuild+branch%3Amaster)

A cooking game for the 1989 Nintendo Game Boy (DMG-01). Should run on later models, too. Forever free and open source.

<img src="https://raw.githubusercontent.com/qguv/undercooked/master/art/title.png" /></a>

[Play undercooked now in your browser](https://qguv.github.io/undercooked), or [download the ROM](https://qguv.github.io/undercooked) to play in an emulator or burn onto a Gameboy cartridge!

## credits

<img width=80 src="https://retchdots.carrd.co/assets/images/image02.jpg?v81760597676551" /> [Rachel](https://retchdots.carrd.co/) did the amazing pixel art

[Quint](https://github.com/qguv) wrote the code and music

## building

prerequisite packages:

package       | purpose
------------- | -------
rgbds         | toolchain for cross-compiling for the gameboy architecture
imagemagick   | image correction tasks for sprites and tiles
ninja         | build system
python3       | build system
python-poetry | build system

1. run `./build`
2. run gameboy ROM at `obj/main.gb`

## playing

- you can run on real hardware with a flash cart like the GB USB 64M
- you can run on your regular emulator of choice, `zboy` is fine
- you can run on `bgb`, a very good emulator with a debugger, using wine (see [this AUR package](https://aur.archlinux.org/packages/bgb))

## developing

1. run `./build`
2. run `bgb -nobatt -watch obj/main.gb` to play it
3. now every time you run `./build`, bgb will reload the newly built ROM

## naming conventions

addresses:

```asm
.jump_label                 ; jump labels within subroutines
;convenience_label          ; label for a section of code that's currently entered by fallthrough
.label_in_macro\@           ; jump labels within macros
SomeFunction:               ; a non-exported subroutine
SomeFunction__abcdehl:      ; a non-exported subroutine reading registers a, b, c, d, e, h, and l as arguments
SomeData                    ; exported data, probably array/string
_GBHW_ADDR or _GBHWADDR     ; gameboy hardware address defined in gbhw.inc
some_value                  ; ram address or compiler variable
```

values:

```asm
as3_freq                    ; music frequency (16-bit)
as3                         ; music note (8-bit index into NoteFreqs)
SOME_CONSTANT               ; equ-defined constant
```

## releasing

1. create and push a new tag `vX.Y.Z`
2. edit and publish the [draft github release](https://github.com/qguv/undercooked/releases) that was just created for you
