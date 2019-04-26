# undercooked

A cooking game for the 1989 Nintendo Game Boy (DMG-01). Should run on later models, too.

## credits

<img width=80 src="https://retchdots.carrd.co/assets/images/image02.jpg?v81760597676551" /> [Rachel](https://retchdots.carrd.co/) did the amazing pixel art

[Quint](https://github.com/qguv) wrote the code and music

## building

1. install rgbds
2. `make`, this will produce `undercooked_xyz.gb` where `xyz` is the version

## playing

- you can run on real hardware with a flash cart like the GB USB 64M
- you can run on your regular emulator of choice, zboy is fine
- you can run on bgb, a very good emulator with a debugger, using wine

## developing

1. make some changes
2. run `make optimcheck` to make sure you didn't miss any easily optimizable instructions
3. run `make play` to test it with bgb, assuming you have a binary called `bgb` on your $PATH that launches bgb with wine

## naming conventions

addresses:

```asm
.jump_label                 ; jump labels within subroutines
;convenience_label          ; label for a section of code that's currently entered by fallthrough
.label_in_macro\@           ; jump labels within macros
SomeFunction:               ; a non-exported function
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
