# gbsplash

A simple splash screen for the 1989 Nintendo Game Boy (DMG-01). Should run on later models, too.

## building

prerequisites:

1. install rgbds
2. git submodule init && git submodule update (to get run scripts)

building binary:

3. `make`

playing game

4. install wine
5. download bgb (for windows, 32- or 64-bit depending on your wine installation) and extract into `extras/bgb`
6. `make clean play`

## development

1. make some changes
2. run `make optimcheck` to make sure you didn't miss any easily optimizable instructions
