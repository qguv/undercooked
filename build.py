#!/usr/bin/env python3
'''
abstract.ninja compiler

abstract.ninja files are a minimal syntax extension of build.ninja files to
allow build statements with wildcard paths. By executing this compiler, a
build.ninja file is built, after which ninja is run.

An abstract.ninja file is separated into sections by `match <pattern>` and
`verbatim` statements. These statements must appear on their own line.

The `match <pattern>` statement begins a match section. When the abstract.ninja
file is compiled, the filesystem is searched for files whose names match the
provided Python glob.glob pattern. The section is repeated once for each
matching file, with instances of `$*` replaced by the part of the path matching
the wildcard part of the glob. See "Pattern examples" below.

The `verbatim` statement begins a verbatim section. When the abstract.ninja
file is compiled, the contents of this section are simply copied into the
output. You can use this to include fixed content at the end of the file, after
a match statement. Also, all lines before the first section statement are
implicitly in a verbatim section.

Pattern examples:

| pattern              | matching file                | value of `$*`
| -------------------- | ---------------------------- | --------------------
| art/*.png            | art/bird.png                 | bird
| art/**/*.png         | art/animals/bird.png         | animals/bird
| art/**/animals/*.png | art/sprites/animals/bird.png | sprites/animals/bird

Copyright 2020 qguv, under the terms of the GNU General Public License ver. 3.
'''


from glob import glob
from os import execlp, mkdir
from sys import argv

section_keywords = ['match', 'verbatim']


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


def get_sections(abstract_file):
    name = 'verbatim'
    lines = []
    with open(abstract_file, 'r') as f:
        for line in f:

            # check for section keyword to flush the existing section and start a new one
            if any((line.startswith(x) for x in section_keywords)):
                yield (name, ''.join(lines))
                name = line.strip()
                lines = []
                continue

            # ignore blank lines after lines with keywords
            if not line.strip() and not lines:
                continue

            lines.append(line)

        yield (name, ''.join(lines))


def generate_build(abstract_file, build_file):
    sections = get_sections(abstract_file)
    with open(build_file, 'w') as f:
        for name, body in sections:

            # add section headers for debugging
            if name:
                f.write(f'# {name}\n\n')

            # 'match' section
            if name.startswith('match '):
                pattern = name.split(maxsplit=1)[1]
                for match in glob(pattern):
                    prefix, core, suffix = glob_partition(match, pattern)
                    f.write(f'# {prefix}{{{core}}}{suffix}\n\n')
                    f.write(body.replace('$*', core))
                continue

            # 'verbatim' section
            if name == 'verbatim':
                f.write(body)
                continue


if __name__ == '__main__':
    try:
        mkdir('obj')
    except FileExistsError:
        pass

    generate_build('meta/abstract.ninja', 'obj/build.ninja')
    execlp('ninja', 'ninja', '-f', 'obj/build.ninja', *argv[1:])
