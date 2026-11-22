# glass.py by poligle (home/hyprlock.nix, nihil-lock-glass)

import argparse

import numpy as np
from PIL import Image, ImageFilter

TRANSMISSION = 0.38
RIM = 0.32
FROST = 6.0
SCATTER = 0.25
HALO = 0.9
WOBBLE = 1.5


def round_box(px, py, hx, hy, r):
    qx = np.abs(px) - hx + r
    qy = np.abs(py) - hy + r
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def sample(img, x, y):
    h, w = img.shape[:2]
    x = np.clip(x, 0, w - 1.001)
    y = np.clip(y, 0, h - 1.001)
    x0 = np.floor(x).astype(int)
    y0 = np.floor(y).astype(int)
    fx = (x - x0)[..., None]
    fy = (y - y0)[..., None]
    top = img[y0, x0] * (1 - fx) + img[y0, x0 + 1] * fx
    bottom = img[y0 + 1, x0] * (1 - fx) + img[y0 + 1, x0 + 1] * fx
    return top * (1 - fy) + bottom * fy


def blur(img, sigma):
    if sigma < 0.3:
        return img
    pic = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8))
    return np.asarray(pic.filter(ImageFilter.GaussianBlur(sigma)), dtype=np.float32) / 255


def hash2(x, y):
    p3 = np.stack([x, y, x], -1) * 0.1031
    p3 = p3 - np.floor(p3)
    p3 = p3 + (p3 * (p3[..., [1, 2, 0]] + 33.33)).sum(-1, keepdims=True)
    v = (p3[..., 0] + p3[..., 1]) * p3[..., 2]
    return v - np.floor(v)


def noise(x, y):
    ix, iy = np.floor(x), np.floor(y)
    fx, fy = x - ix, y - iy
    ux, uy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = hash2(ix, iy), hash2(ix + 1, iy)
    c, d = hash2(ix, iy + 1), hash2(ix + 1, iy + 1)
    top = a + (b - a) * ux
    return top + (c + (d - c) * ux - top) * uy


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def glass(img, out, cx, cy, hx, hy, r, scale):
    height, width = img.shape[:2]
    radius = r / scale
    refraction = min(6, 2 + radius / 3) * scale
    bevel = min(14, 4 + radius)
    clarity = smoothstep(10.0, 24.0, bevel)
    bevel *= scale

    x0, x1 = int(max(0, np.floor(cx - hx - 2))), int(min(width, np.ceil(cx + hx + 2)))
    y0, y1 = int(max(0, np.floor(cy - hy - 2))), int(min(height, np.ceil(cy + hy + 2)))
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32) + 0.5
    px, py = xx - cx, yy - cy

    margin = int(np.ceil((0.42 * 28 * 3 + 40) * scale))
    ox, oy = max(0, x0 - margin), max(0, y0 - margin)
    area = img[oy:min(height, y1 + margin), ox:min(width, x1 + margin)]
    xx, yy = xx - ox, yy - oy

    d = round_box(px, py, hx, hy, r)
    e = 0.5
    nx = round_box(px + e, py, hx, hy, r) - round_box(px - e, py, hx, hy, r)
    ny = round_box(px, py + e, hx, hy, r) - round_box(px, py - e, hx, hy, r)
    length = np.maximum(np.hypot(nx, ny), 1e-4)
    nx, ny = nx / length, ny / length
    depth = np.maximum(-d, 0)

    lx, ly = (px + hx) / scale, (py + hy) / scale
    k = np.clip(1 - depth / bevel, 0, 1) ** 2
    qx, qy = lx / 34.0, ly / 34.0
    wx = (noise(qx, qy) + 0.5 * noise(qx * 2.7 + 5.1, qy * 2.7 + 13.9)) / 1.5 * 2 - 1
    wy = (noise(qx + 19.7, qy + 7.3) + 0.5 * noise(qx * 2.7 + 23.4, qy * 2.7 + 2.2)) / 1.5 * 2 - 1
    bx, by = nx * refraction * k, ny * refraction * k
    ax = xx - 0.5 + bx + wx * WOBBLE * scale * (1 - k)
    ay = yy - 0.5 + by + wy * WOBBLE * scale * (1 - k)

    soft = blur(area, 0.5 * scale)
    clear = np.stack([sample(soft, ax - bx * 0.14, ay - by * 0.14)[..., 0],
                      sample(soft, ax, ay)[..., 1],
                      sample(soft, ax + bx * 0.14, ay + by * 0.14)[..., 2]], -1)
    thin, thick = blur(area, 0.42 * FROST * 0.75 * scale), blur(area, 0.42 * FROST * 1.25 * scale)
    uneven = noise(qx * 1.7 + 41, qy * 1.7 + 3)[..., None]
    frosted = sample(thin, ax, ay) * (1 - uneven) + sample(thick, ax, ay) * uneven
    frosted = frosted * (1 + (hash2(np.floor(lx * scale), np.floor(ly * scale)) - 0.5)[..., None] * 0.12)
    mixk = (smoothstep(0.08, 0.7, k) * clarity)[..., None]
    behind = frosted + (clear - frosted) * mixk

    wide = sample(blur(area, 0.42 * FROST * 2.2 * scale + 0.6 * FROST * scale), ax, ay)
    col = behind * TRANSMISSION + wide * SCATTER * (0.35 + TRANSMISSION)

    edge = np.exp(-depth / (2.5 * scale))[..., None]
    reach = 3 * scale + depth
    pastx, pasty = xx - 0.5 + nx * reach, yy - 0.5 + ny * reach
    near = sample(blur(area, 0.42 * 10 * scale), pastx, pasty)
    around = sample(blur(area, 0.42 * 28 * scale), pastx, pasty)
    col = col + np.maximum(near - around, 0) * HALO * edge

    band = np.clip(1 - depth / (2.5 * scale), 0, 1)
    lit = np.clip(-(nx + ny) * 0.7071, 0, None) ** 4
    away = np.clip((nx + ny) * 0.7071, 0, None) ** 2
    col = col + (RIM * lit * band)[..., None]
    col = col * (1 - 0.3 * away * band)[..., None]
    col = col + (0.03 * k)[..., None]

    cover = np.clip(0.5 - d / scale, 0, 1)[..., None]
    out[y0:y1, x0:x1] = out[y0:y1, x0:x1] * (1 - cover) + np.clip(col, 0, 1) * cover


def flat(out, cx, cy, hx, hy, r, scale, fill, line):
    height, width = out.shape[:2]
    x0, x1 = int(max(0, np.floor(cx - hx - 2))), int(min(width, np.ceil(cx + hx + 2)))
    y0, y1 = int(max(0, np.floor(cy - hy - 2))), int(min(height, np.ceil(cy + hy + 2)))
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32) + 0.5
    d = round_box(xx - cx, yy - cy, hx, hy, r)
    cover = np.clip(0.5 - d, 0, 1)[..., None]
    stroke = cover - np.clip(0.5 - (d + scale), 0, 1)[..., None]
    col = fill * (1 - stroke / np.maximum(cover, 1e-4)) + line * (stroke / np.maximum(cover, 1e-4))
    out[y0:y1, x0:x1] = out[y0:y1, x0:x1] * (1 - cover) + col * cover


def colour(hex):
    return np.array([int(hex[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("wallpaper")
    parser.add_argument("out")
    parser.add_argument("--logical", nargs=2, type=float, required=True)
    parser.add_argument("--field", nargs=3, type=float)
    parser.add_argument("--panel", nargs=5, type=float, metavar=("X", "Y", "W", "H", "R"))
    parser.add_argument("--flat", nargs=2, metavar=("FILL", "LINE"))
    args = parser.parse_args()

    img = np.asarray(Image.open(args.wallpaper).convert("RGB"), dtype=np.float32) / 255
    height, width = img.shape[:2]
    sx = width / args.logical[0]
    sy = height / args.logical[1]
    scale = (sx + sy) / 2
    out = img.copy()

    if args.field:
        fw, fh, up = args.field
        hx, hy = fw * sx / 2, fh * sy / 2
        glass(img, out, width / 2, height / 2 - up * sy, hx, hy, min(hx, hy), scale)
    if args.panel:
        x, y, w, h, r = args.panel
        cx, cy = (x + w / 2) * sx, height - (y + h / 2) * sy
        hx, hy = w * sx / 2, h * sy / 2
        r = min(r * scale, hx, hy)
        if args.flat:
            flat(out, cx, cy, hx, hy, r, scale, colour(args.flat[0]), colour(args.flat[1]))
        else:
            glass(img, out, cx, cy, hx, hy, r, scale)
    Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)).save(args.out)


if __name__ == "__main__":
    main()
