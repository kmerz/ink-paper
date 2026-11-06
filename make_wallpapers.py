#!/usr/bin/env python3
"""Procedural "ink on paper" wallpapers. Pillow only, nothing downloaded or traced.

Makes light ("paper") and dark ("ink") versions of three designs:
  brush       one sweeping stroke, thick to thin, dry-brush tail
  sketchbook  paper grain, faint pencil grid, tiny red seal bottom-right
  vignette    empty paper with a dense cluster of hatching and contours in one corner

Usage:
  python3 make_wallpapers.py                 # 1920x1080, all designs
  python3 make_wallpapers.py --size 2560x1440 --seed 3
"""
import argparse
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

PALETTES = {
    "light": dict(bg="#F2EEE6", surface="#E7E2D8", ink="#1A1A1A", muted="#8A8580", accent="#B23A2E"),
    "dark": dict(bg="#141414", surface="#1E1E1E", ink="#E9E4DA", muted="#5C5853", accent="#C8473A"),
}
SS = 2  # draw at 2x and scale down, for smooth edges
LANCZOS = Image.Resampling.LANCZOS
OUT = Path(__file__).resolve().parent


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def solid(size, color):
    return Image.new("RGB", size, rgb(color))


# ---------- paper ----------

def grain(img, mode, strength=1.0):
    """Fine paper tooth: tiny darker and lighter specks."""
    n = Image.effect_noise(img.size, 48).filter(ImageFilter.GaussianBlur(0.6))
    if mode == "light":
        dark_c, light_c, kd, kl = "#5C5853", "#FBF9F4", 0.16, 0.12
    else:
        dark_c, light_c, kd, kl = "#000000", "#3A3733", 0.20, 0.10
    kd *= strength
    kl *= strength
    dmask = n.point(lambda v: int(min(255, max(0, v - 128) * kd)))
    lmask = n.point(lambda v: int(min(255, max(0, 128 - v) * kl)))
    img = Image.composite(solid(img.size, dark_c), img, dmask)
    return Image.composite(solid(img.size, light_c), img, lmask)


def paper(size, pal, mode):
    w, h = size
    img = solid(size, pal["bg"])
    # large, soft unevenness of the sheet
    mott = Image.effect_noise((max(8, w // 24), max(8, h // 24)), 40)
    mott = mott.resize(size, Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(6))
    k = 0.22 if mode == "light" else 0.26
    img = Image.composite(solid(size, pal["surface"]), img,
                          mott.point(lambda v: int(min(255, max(0, v - 128) * k))))
    return grain(img, mode, 1.0)


def compose(img, mask2x, color):
    mask = mask2x.resize(img.size, LANCZOS)
    return Image.composite(solid(img.size, color), img, mask)


# ---------- geometry helpers ----------

def bez(p, t):
    u = 1 - t
    return (u ** 3 * p[0][0] + 3 * u * u * t * p[1][0] + 3 * u * t * t * p[2][0] + t ** 3 * p[3][0],
            u ** 3 * p[0][1] + 3 * u * u * t * p[1][1] + 3 * u * t * t * p[2][1] + t ** 3 * p[3][1])


def bez_d(p, t):
    u = 1 - t
    return (3 * u * u * (p[1][0] - p[0][0]) + 6 * u * t * (p[2][0] - p[1][0]) + 3 * t * t * (p[3][0] - p[2][0]),
            3 * u * u * (p[1][1] - p[0][1]) + 6 * u * t * (p[2][1] - p[1][1]) + 3 * t * t * (p[3][1] - p[2][1]))


def quad(a, c, b, n):
    pts = []
    for i in range(n):
        t = i / (n - 1)
        u = 1 - t
        pts.append((u * u * a[0] + 2 * u * t * c[0] + t * t * b[0],
                    u * u * a[1] + 2 * u * t * c[1] + t * t * b[1]))
    return pts


def taper_poly(d, pts, wmax, profile, fill=255):
    """Filled stroke along pts whose width follows profile(t) in 0..1."""
    n = len(pts)
    left, right = [], []
    for i, (x, y) in enumerate(pts):
        a, b = pts[max(0, i - 1)], pts[min(n - 1, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / L, dx / L
        hw = wmax * profile(i / (n - 1)) / 2
        left.append((x + nx * hw, y + ny * hw))
        right.append((x - nx * hw, y - ny * hw))
    d.polygon(left + right[::-1], fill=fill)


# ---------- designs (masks drawn at 2x) ----------

def brush_mask(W, H, rng):
    w, h = W * SS, H * SS
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    P = [(0.07 * w, 0.68 * h), (0.33 * w, 0.16 * h), (0.58 * w, 1.02 * h), (0.94 * w, 0.30 * h)]
    n = 1800
    pts, nrm, rad = [], [], []
    rmax, rmin = 0.058 * h, 0.0015 * h
    for i in range(n + 1):
        t = i / n
        x, y = bez(P, t)
        dx, dy = bez_d(P, t)
        L = math.hypot(dx, dy) or 1.0
        pts.append((x, y))
        nrm.append((-dy / L, dx / L))
        attack = min(1.0, t / 0.035) ** 0.5          # brush pressed down quickly
        rad.append(rmin + (rmax - rmin) * attack * (1 - t) ** 0.85)

    # rounded head where the brush touches the paper
    r0 = rad[int(0.035 * n)] * 0.8
    x0, y0 = pts[int(0.012 * n)]
    d.ellipse([x0 - r0, y0 - r0, x0 + r0, y0 + r0], fill=250)

    N = 56  # bristles
    for u in sorted(rng.uniform(-1, 1) for _ in range(N)):
        # outer bristles run out of ink first: ragged, splitting tail
        t_end = 1 - 0.28 * abs(u) ** 1.4 - abs(rng.gauss(0, 0.03))
        val = rng.randint(215, 255)
        dry, prev = False, None
        for i in range(n + 1):
            t = i / n
            if t > t_end:
                break
            r = rad[i]
            cur = (pts[i][0] + nrm[i][0] * u * r * 0.98, pts[i][1] + nrm[i][1] * u * r * 0.98)
            if t > 0.55:  # dry brush: streaky gaps that get longer toward the end
                p = ((t - 0.55) / 0.45) ** 1.6
                if dry:
                    if rng.random() < 0.10 * (1 - p) + 0.01:
                        dry = False
                elif rng.random() < 0.05 * p:
                    dry = True
            if prev is not None and not dry:
                bw = max(SS * 1.0, 4.8 * r / N)
                d.line([prev, cur], fill=val, width=int(round(bw)))
            prev = cur
    return m


def grid_mask(W, H, rng, alpha):
    w, h = W * SS, H * SS
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    step = round(H / 18) * SS
    base = 255 * alpha

    def pencil_line(a, b, vertical):
        nseg = max(2, int(math.dist(a, b) / (24 * SS)))
        prev = a
        for i in range(1, nseg + 1):
            t = i / nseg
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t
            if vertical:
                x += rng.gauss(0, 0.35 * SS)
            else:
                y += rng.gauss(0, 0.35 * SS)
            d.line([prev, (x, y)], fill=int(base * rng.uniform(0.55, 1.0)), width=SS)
            prev = (x, y)

    for x in range((w % step) // 2, w, step):
        pencil_line((x, 0), (x, h), True)
    for y in range((h % step) // 2, h, step):
        pencil_line((0, y), (w, y), False)
    return m


def seal_mask(W, H, rng):
    w, h = W * SS, H * SS
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    s = round(H * 0.032) * SS
    margin = round(H * 0.055) * SS
    x1, y1 = w - margin, h - margin
    x0, y0 = x1 - s, y1 - s

    def j():
        return rng.uniform(-0.04, 0.04) * s

    d.polygon([(x0 + j(), y0 + j()), (x1 + j(), y0 + j()), (x1 + j(), y1 + j()), (x0 + j(), y1 + j())], fill=255)
    # abstract carved marks (not a real character), left as paper inside the seal
    lw = max(SS, int(s * 0.09))
    ins = s * 0.2
    d.line([(x0 + ins, y0 + ins), (x0 + ins, y1 - ins)], fill=0, width=lw)
    d.line([(x0 + ins, y1 - ins), (x1 - ins * 1.4, y1 - ins)], fill=0, width=lw)
    d.line([(x0 + s * 0.56, y0 + ins), (x0 + s * 0.56, y0 + s * 0.62)], fill=0, width=lw)
    d.line([(x0 + s * 0.56, y0 + s * 0.40), (x1 - ins, y0 + s * 0.40)], fill=0, width=lw)
    # uneven stamp ink: a few specks where the paper shows through
    pad = int(s * 0.1)
    box = (int(x0) - pad, int(y0) - pad, int(x1) + pad, int(y1) + pad)
    tex = Image.effect_noise((box[2] - box[0], box[3] - box[1]), 60).point(lambda v: 0 if v > 210 else 255)
    m.paste(ImageChops.multiply(m.crop(box), tex), box)
    return m


def vignette_mask(W, H, rng):
    w, h = W * SS, H * SS
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    ax, ay = 0.14 * w, 0.79 * h   # densest point, bottom-left
    rx, ry = 0.25 * w, 0.20 * h   # spread: the cluster covers about 15% of the screen

    def hatch(t):
        return max(0.12, math.sin(math.pi * t)) ** 0.6

    angles = [math.radians(a) for a in (38, 52, -35, -48, 78, 12)]
    for _ in range(46):
        while True:  # patch centre, denser near the anchor, kept inside the corner region
            px, py = ax + rng.gauss(0, rx * 0.45), ay + rng.gauss(0, ry * 0.45)
            if 0.02 * w < px < 0.40 * w and 0.60 * h < py < 0.97 * h:
                break
        dist = math.hypot((px - ax) / rx, (py - ay) / ry)
        dens = math.exp(-dist * dist * 1.5)
        ang = rng.choice(angles)
        layers = 2 if rng.random() < 0.45 * dens + 0.1 else 1   # cross-hatch the dense parts
        for layer in range(layers):
            a = ang + layer * math.radians(rng.uniform(55, 95))
            cnt = int(rng.uniform(6, 16) * (0.5 + dens))
            spacing = rng.uniform(4.5, 8.5) * SS * (1.3 - 0.5 * dens)
            length = rng.uniform(28, 95) * SS * (0.6 + 0.6 * dens)
            ux, uy = math.cos(a), math.sin(a)
            vx, vy = -uy, ux
            for k in range(cnt):
                o = (k - cnt / 2) * spacing
                cx = px + vx * o + rng.gauss(0, 1.2 * SS)
                cy = py + vy * o + rng.gauss(0, 1.2 * SS)
                L = length * rng.uniform(0.75, 1.15)
                p0 = (cx - ux * L / 2, cy - uy * L / 2)
                p1 = (cx + ux * L / 2, cy + uy * L / 2)
                bend = rng.gauss(0, 0.06) * L
                c = ((p0[0] + p1[0]) / 2 + vx * bend, (p0[1] + p1[1]) / 2 + vy * bend)
                taper_poly(d, quad(p0, c, p1, 14), rng.uniform(1.3, 2.6) * SS, hatch,
                           fill=rng.randint(200, 255))

    def press(t):
        return min(1.0, t / 0.07) ** 0.6 * (1 - t) ** 0.55 + 0.05

    for _ in range(7):  # a few confident contour strokes around the cluster
        r = rng.uniform(0.08, 0.24) * h
        start, span = rng.uniform(-1.9, -0.2), rng.uniform(0.9, 1.8)
        cx, cy = ax + rng.gauss(0, 0.04 * w), ay + rng.gauss(0, 0.04 * h)
        phase = rng.uniform(0, 6.28)
        pts = []
        for i in range(60):
            th = start + span * i / 59
            rr = r * (1 + 0.08 * math.sin(3 * th + phase))
            pts.append((cx + math.cos(th) * rr * 1.25, cy + math.sin(th) * rr))
        taper_poly(d, pts, rng.uniform(2.5, 4.2) * SS, press)
    return m


# ---------- render ----------

def render(style, mode, size, seed):
    rng = random.Random(f"{seed}-{style}")  # same drawing in light and dark
    pal = PALETTES[mode]
    W, H = size
    img = paper(size, pal, mode)
    if style == "brush":
        img = compose(img, brush_mask(W, H, rng), pal["ink"])
    elif style == "sketchbook":
        img = compose(img, grid_mask(W, H, rng, 0.16 if mode == "light" else 0.30), pal["muted"])
        img = compose(img, seal_mask(W, H, rng), pal["accent"])
    elif style == "vignette":
        img = compose(img, vignette_mask(W, H, rng), pal["ink"])
    return grain(img, mode, 0.5)  # paper tooth shows through the ink too


def contact_sheet(files, path):
    tw, th, pad = 640, 360, 24
    sheet = Image.new("RGB", (3 * tw + 4 * pad, 2 * th + 3 * pad + 40), rgb("#8A8580"))
    d = ImageDraw.Draw(sheet)
    for idx, (label, f) in enumerate(files):
        col, row = idx % 3, idx // 3
        x, y = pad + col * (tw + pad), pad + row * (th + pad + 20)
        sheet.paste(Image.open(f).resize((tw, th), LANCZOS), (x, y))
        d.text((x, y + th + 4), label, fill=rgb("#F2EEE6"))
    sheet.save(path)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--size", default="1920x1080")
    ap.add_argument("--seed", default="7")
    a = ap.parse_args()
    size = tuple(int(v) for v in a.size.lower().split("x"))
    made = []
    for mode in ("light", "dark"):
        for style in ("brush", "sketchbook", "vignette"):
            f = OUT / f"{style}-{mode}.png"
            render(style, mode, size, a.seed).save(f, optimize=True)
            made.append((f"{style} / {mode}", f))
            print("wrote", f)
    contact_sheet(made, OUT / "preview.png")
    print("wrote", OUT / "preview.png")


if __name__ == "__main__":
    main()
