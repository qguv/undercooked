#!/usr/env/python3

import argparse
import imageio as iio
import numpy as np


def flatten(xss):
    return [x for xs in xss for x in xs]


def separate(xss, splits, axis):
    return flatten(np.split(xs, splits, axis=axis) for xs in xss)


def gen_spritesheet(tiles_per_row, data):
    '''
    Produce an image with all of the frames of a single subsprite of the
    animation.
    '''

    HORIZONTAL = 1
    VERTICAL = 2

    nframes = len(data)
    pixels_per_column = len(data[0])
    pixels_per_row = len(data[0][0])
    channels = len(data[0][0][0])  # probably 4, rgba
    tile_width = int(pixels_per_row // tiles_per_row)
    tile_height = tile_width  # for square tiles
    tiles_per_column = int(pixels_per_column // tile_height)
    ntiles = tiles_per_row * tiles_per_column

    tile_rows = separate([data], tiles_per_column, HORIZONTAL)
    sprites = separate(tile_rows, tiles_per_row, VERTICAL)
    sprite_lines = separate(sprites, tile_height, HORIZONTAL)

    return np.array(sprite_lines).reshape((
        ntiles * tile_height,
        nframes * tile_width,
        channels,
    ))


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('GIF', help="animation to convert")
    parser.add_argument(
        '--width', type=int,
        required=True,
        help="width of sprite, in 8x8 tiles",
    )
    parser.add_argument(
        '--output',
        required=True,
        help="path the spritesheet will be generated",
    )
    return parser.parse_args()


args = parse_args()
data = np.array(list(iio.get_reader(args.GIF)))
sheet = gen_spritesheet(args.width, data)
with iio.get_writer(f'{args.output}') as w:
    w.append_data(sheet)
