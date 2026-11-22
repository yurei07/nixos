#!/usr/bin/env python3
# cover.py by poligle


import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from dotmatrix import render

SIZE = 120
PITCH = 4


def save(img, out):
    tmp = out + ".tmp"
    img.save(tmp, "PNG")
    os.replace(tmp, out)


def cover(source, out):
    Image.MAX_IMAGE_PIXELS = 50_000_000
    with Image.open(source) as im:
        im.draft("RGB", (SIZE * 4, SIZE * 4))
        if "A" in im.getbands():
            rgba = im.convert("RGBA")
            img = Image.new("RGB", rgba.size, (0, 0, 0))
            img.paste(rgba, mask=rgba.getchannel("A"))
        else:
            img = im.convert("RGB")
    save(render(img, SIZE, SIZE, PITCH).convert("RGB"), out)


def placeholder(out):
    s = 4
    note = Image.new("L", (SIZE * s, SIZE * s), 0)
    draw = ImageDraw.Draw(note)
    u = SIZE * s / 120
    draw.ellipse((38 * u, 70 * u, 62 * u, 88 * u), fill=255)
    draw.rectangle((56 * u, 30 * u, 62 * u, 80 * u), fill=255)
    draw.polygon([(56 * u, 30 * u), (82 * u, 44 * u), (82 * u, 54 * u), (62 * u, 43 * u)], fill=255)
    note = note.filter(ImageFilter.GaussianBlur(2 * u)).resize((SIZE, SIZE), Image.LANCZOS)
    dots = np.asarray(render(note.convert("RGB"), SIZE, SIZE, PITCH), dtype=np.float32)
    off = 255 * 0.07
    dim = np.where(dots > off + 2, off + (dots - off) * 0.4, dots)
    save(Image.fromarray(np.clip(dim, 0, 255).astype(np.uint8)).convert("RGB"), out)


def blank(out):
    save(Image.new("RGBA", (1, 1), (0, 0, 0, 0)), out)


def main():
    args = sys.argv[1:]
    if len(args) == 2 and args[0] == "--placeholder":
        placeholder(args[1])
    elif len(args) == 2 and args[0] == "--blank":
        blank(args[1])
    elif len(args) == 2:
        cover(args[0], args[1])
    else:
        sys.exit("Usage: cover.py SOURCE OUT.png | --placeholder OUT.png | --blank OUT.png")


if __name__ == "__main__":
    main()