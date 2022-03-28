#!/usr/bin/env python3

import argparse


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('FILE')
    parser.add_argument(
        '--add', type=int,
        required=True,
        help="amount to add to each byte",
    )
    parser.add_argument(
        '--output',
        required=True,
    )
    return parser.parse_args()


args = parse_args()
with open(args.FILE, 'rb') as f:
    xs = f.read()
with open(args.output, 'wb') as f:
    f.write(bytes(x + args.add for x in xs))
