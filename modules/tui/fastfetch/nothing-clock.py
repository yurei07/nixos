#!/usr/bin/env python3
"""NOTHING-SHELL: the current time as white dot-matrix, exactly like the Ndot
clock widget on the desktop. Renders HH:MM in Ndot 57 with PIL, then converts
the raster to braille dots for the terminal. Used by fastfetch's custom module."""
from datetime import datetime
import os

from PIL import Image, ImageDraw, ImageFont

FONT_CANDIDATES = [
    os.path.expanduser("~/.local/share/fonts/Nothing/Ndot57-Regular.otf"),
    os.path.expanduser("~/nix-profile/share/fonts/Nothing/Ndot57-Regular.otf"),
]


def pick_font() -> str:
    for p in FONT_CANDIDATES:
        if os.path.exists(p):
            return p
    raise SystemExit("Ndot 57 not found")


def braille(img: Image.Image, thresh: int = 96) -> list[str]:
    cell_w, cell_h = 2, 4
    w, h = img.size
    cols, rows = w // cell_w, h // cell_h
    dots = [(0, 0, 0x01), (0, 1, 0x02), (0, 2, 0x04), (1, 0, 0x08),
            (1, 1, 0x10), (1, 2, 0x20), (0, 3, 0x40), (1, 3, 0x80)]
    out = []
    for r in range(rows):
        line = ""
        for c in range(cols):
            bits = 0
            for dx, dy, mask in dots:
                if img.getpixel((c * cell_w + dx, r * cell_h + dy)) > thresh:
                    bits |= mask
            line += chr(0x2800 + bits) if bits else " "
        out.append(line.rstrip())
    return out


def main() -> None:
    text = datetime.now().strftime("%H:%M")
    img = Image.new("L", (900, 260), 0)
    ImageDraw.Draw(img).text((20, 30), text, fill=255,
                             font=ImageFont.truetype(pick_font(), 150))
    img = img.crop(img.getbbox())
    # empty canvas (rendering raced the font): draw nothing gracefully
    for line in braille(img):
        print(line)


if __name__ == "__main__":
    main()
