#!/usr/bin/env python3
"""NOTHING-SHELL fastfetch logo: the braille NixOS snowflake with the current
time rendered underneath in white Ndot 57 dots, like the desktop clock widget."""
from datetime import datetime
import os

from PIL import Image, ImageDraw, ImageFont

DOTS_FILE = "/etc/nixos/modules/tui/fastfetch/logo/nixos-dots.txt"
FONT = os.path.expanduser("~/.local/share/fonts/Nothing/Ndot57-Regular.otf")


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


def clock_lines() -> list[str]:
    try:
        text = datetime.now().strftime("%H:%M")
        img = Image.new("L", (300, 100), 0)
        ImageDraw.Draw(img).text((6, 8), text, fill=255,
                                 font=ImageFont.truetype(FONT, 46))
        img = img.crop(img.getbbox())
        return braille(img)
    except Exception:
        return []


def main() -> None:
    nix = [row.rstrip() for row in open(DOTS_FILE).read().splitlines()]
    nix = [row for row in nix if row.strip() != ""][:40]
    clock = clock_lines()
    width = max((len(line) for line in nix + clock), default=0)

    for line in nix:
        print(line)
    # blank gap, then the clock centred under the snowflake
    print()
    for line in clock:
        pad = max(0, (width - len(line)) // 2)
        print(" " * pad + line)


if __name__ == "__main__":
    main()
