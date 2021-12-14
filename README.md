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

1. run `./configure` to prepare build system (you only have to do this once)
2. run `ninja` to compile
3. run gameboy ROM at `obj/main.gb`

## playing

- you can run on real hardware with a flash cart like the GB USB 64M
- you can run on your regular emulator of choice, `zboy` is fine
- you can run on `bgb`, a very good emulator with a debugger, using wine (see [this AUR package][bgb-aur])

[bgb-aur]: https://aur.archlinux.org/packages/bgb

## developing

- if you run with `bgb -nobatt -watch obj/main.gb`, bgb will reload the newly built ROM whenever you run `ninja` to compile
- if you add (or remove) a source file and want to link it into the built ROM (or remove the link), edit the "for target" section in `meta/build.ninja.j2`
- run `./configure` again if you ever need to rebuild the build system

### naming conventions

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

### testing

After initial setup, the ROM jumps to a `Begin` label. There are two implementations of this label: one in `begin_main.asm` to start the game loop for normal gameplay; and one in `begin_test.asm` which runs a unit test suite and produces output in [TAP](https://testanything.org/) via `bgb` debug prints.

If you're on Arch Linux, and you've installed `bgb` from the [AUR][bgb-aur], then you can run `./test` to see the results of the tests as displayed by [tappy](https://github.com/python-tap/tappy). This process will exit successfully if the tests passed.

### releasing

1. create and push a new tag `vX.Y.Z`
2. edit and publish the [draft github release](https://github.com/qguv/undercooked/releases) that was just created for you
