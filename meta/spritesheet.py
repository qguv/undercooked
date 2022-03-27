#!/usr/env/python3

import argparse
import imageio as iio
import numpy as np

SEP_COLUMNS = 2
SEP_ROWS = 1
SEP_FRAMES = 0


def fsplit(xss, splits, axis):
    xss = [np.split(xs, splits, axis=axis) for xs in xss]
    ret = [x for xs in xss for x in xs]

def spritesheet(tiles_per_row, animation_path):
    '''Produce an image where each row is all the frames of one subsprite of the animation.'''
    animated_sprites = get_subsprites(tiles_per_row, animation_path)
    for sprite_frames in animated_sprites:
        yield np.concatenate(zip(sprite_frames))


def get_subsprites(tiles_per_row, animation_path):
    '''Separate a large animated sprite into animated subsprite tiles.'''
    reader = iio.get_reader(f'{animation_path}')
    return zip(framesheet(tiles_per_row, frame) for frame in reader)


def framesheet(tiles_per_row, frame):
    h, w, _ = frame.shape
    tile_width = w / tiles_per_row
    tile_height = tile_width  # for square tiles

    for tile_row in np.array_split(frame, tile_height):
        yield from hsplit(tile_row)


def hsplit(lines):
    '''Separate the tiles in a row of square 2d tiles.'''

    tile_height = len(lines)
    tile_width = tile_height  # for square tiles
    return zip(np.array_split(line, tile_width) for line in lines)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('GIF')
    parser.add_argument(
        '-w',
        '--width',
        required=True,
        help="width of sprite, in 8x8 tiles",
    )
    return parser.parse_args()


args = parse_args()
spritesheet(args.width, args.GIF)
