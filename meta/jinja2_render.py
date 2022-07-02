#!/usr/bin/env python3

import jinja2
import sys
import glob
import subprocess


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


def inner_globs(*patterns):
    for pattern in patterns:
        for result in glob.glob(pattern):
            yield glob_partition(result, pattern)


def rgbasm_version():
    return tuple(
        int(n)
        for n in (
            subprocess.check_output(('rgbasm', '--version'))
                .decode('utf-8')
                .split(' v', maxsplit=1)[1]
                .split('-', maxsplit=1)[0]
                .split('.')
        )
    )
    version, _, suffix = version.partition('-')
    version = tuple(int(n) for n in version)


def jinja2_render(infile, outfile, chdir=None):
    env = jinja2.Environment(
        keep_trailing_newline=True,
        autoescape=False,
        line_statement_prefix="##",
    )
    src = infile.read()
    template = env.from_string(src)
    out = template.render(glob=glob.glob, inner_globs=inner_globs, rgbasm_version=rgbasm_version())
    outfile.write(out)


if __name__ == "__main__":
    jinja2_render(sys.stdin, sys.stdout)
