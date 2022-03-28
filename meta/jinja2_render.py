#!/usr/bin/env python3

import jinja2
import sys
import glob


def glob_partition(match, pattern):
    '''
    >>> glob_partition('', '')
    ('', '', '')

    >>> glob_partition('bird.png', 'bird.png')
    ('', 'bird.png', '')

    >>> glob_partition('bird.png', '*')
    ('', 'bird.png', '')

    >>> glob_partition('bird.png', '*.png')
    ('', 'bird', '.png')

    >>> glob_partition('art/bird.png', 'art/*')
    ('art/', 'bird.png', '')

    >>> glob_partition('art/bird.png', 'art/*.png')
    ('art/', 'bird', '.png')

    >>> glob_partition('art/animals/bird.png', 'art/**/*.png')
    ('art/', 'animals/bird', '.png')

    >>> glob_partition('art/sprites/animals/bird.png', 'art/**/animals/*.png')
    ('art/', 'sprites/animals/bird', '.png')
    '''

    # empty pattern
    if not pattern:
        return '', match, ''

    # star on both ends
    if pattern[0] == pattern[-1] == '*':
        return '', match, ''

    pieces = pattern.split('*')

    # no star
    if len(pieces) < 2:
        return '', match, ''

    # ends in star
    if not pieces[-1]:
        return pieces[0], match[len(pieces[0]):], pieces[-1]

    # general case (maybe starts with star)
    return pieces[0], match[len(pieces[0]):-len(pieces[-1])], pieces[-1]


def inner_glob(pattern):
    for result in glob.glob(pattern):
        _, inner, _ = glob_partition(result, pattern)
        yield inner


def jinja2_render(infile, outfile, chdir=None):
    env = jinja2.Environment(
        keep_trailing_newline=True,
        autoescape=False,
        line_statement_prefix="##",
    )
    src = infile.read()
    template = env.from_string(src)
    out = template.render(glob=glob.glob, inner_glob=inner_glob)
    outfile.write(out)


if __name__ == "__main__":
    jinja2_render(sys.stdin, sys.stdout)
