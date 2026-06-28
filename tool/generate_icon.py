"""Generates SafeBuy Nepal launcher icon assets with Pillow.
Emblem = Nepal flag's white crescent moon + 12-ray sun + verification check,
on the flag's crimson->blue gradient.
Outputs to assets/icon/.
"""
import os
import math
import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
os.makedirs(OUT, exist_ok=True)

CRIMSON = (228, 22, 60)
CRIMSON2 = (193, 18, 31)
BLUE = (1, 58, 143)
WHITE = (255, 255, 255, 255)


def gradient(size):
    """Diagonal crimson -> blue gradient as an RGB image."""
    n = 256
    ys, xs = np.mgrid[0:n, 0:n]
    t = (xs + ys) / (2 * (n - 1))  # 0..1 diagonal
    # two-stop: crimson -> crimson2 (0..0.5) -> blue (0.5..1)
    c0 = np.array(CRIMSON);  c1 = np.array(CRIMSON2);  c2 = np.array(BLUE)
    img = np.zeros((n, n, 3))
    a = np.clip(t / 0.55, 0, 1)[..., None]
    seg1 = c0 * (1 - a) + c1 * a
    b = np.clip((t - 0.55) / 0.45, 0, 1)[..., None]
    img = seg1 * (1 - b) + c2 * b
    im = Image.fromarray(img.astype("uint8"), "RGB").resize((size, size), Image.BILINEAR)
    return im


def draw_emblem(size):
    """Returns an RGBA emblem (white moon + sun + crimson check) sized SxS."""
    S = size
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx = S / 2

    # ── Crescent moon (upper) ──
    moon_cx, moon_cy = cx, S * 0.34
    R = S * 0.140
    d.ellipse([moon_cx - R, moon_cy - R, moon_cx + R, moon_cy + R], fill=WHITE)
    # carve a smaller circle offset right to form the crescent (opening right)
    r = S * 0.118
    ox, oy = moon_cx + S * 0.062, moon_cy - S * 0.018
    d.ellipse([ox - r, oy - r, ox + r, oy + r], fill=(0, 0, 0, 0))

    # ── Sun (lower): 12 rays + disc ──
    sun_cx, sun_cy = cx, S * 0.70
    outer = S * 0.185
    inner = S * 0.112
    disc = S * 0.097
    pts = []
    for i in range(24):
        rad = outer if i % 2 == 0 else inner
        ang = math.pi * i / 12 - math.pi / 2
        pts.append((sun_cx + rad * math.cos(ang), sun_cy + rad * math.sin(ang)))
    d.polygon(pts, fill=WHITE)
    d.ellipse([sun_cx - disc, sun_cy - disc, sun_cx + disc, sun_cy + disc], fill=WHITE)

    # ── Verification check inside the sun (crimson) ──
    lw = max(2, int(S * 0.022))
    p1 = (sun_cx - disc * 0.5, sun_cy + disc * 0.02)
    p2 = (sun_cx - disc * 0.08, sun_cy + disc * 0.45)
    p3 = (sun_cx + disc * 0.55, sun_cy - disc * 0.5)
    d.line([p1, p2, p3], fill=(193, 18, 31, 255), width=lw, joint="curve")
    # round the check endpoints
    for p in (p1, p3):
        d.ellipse([p[0]-lw/2, p[1]-lw/2, p[0]+lw/2, p[1]+lw/2], fill=(193,18,31,255))
    return im


def main():
    SZ = 1024

    # 1) Full icon: gradient background + emblem
    icon = gradient(SZ).convert("RGBA")
    emblem = draw_emblem(int(SZ * 0.74))
    off = (SZ - emblem.width) // 2
    icon.alpha_composite(emblem, (off, off))
    icon.convert("RGB").save(os.path.join(OUT, "app_icon.png"))

    # 2) Adaptive foreground: emblem only, transparent, safe-zone padded (~58%)
    fg = Image.new("RGBA", (SZ, SZ), (0, 0, 0, 0))
    emblem_fg = draw_emblem(int(SZ * 0.58))
    offf = (SZ - emblem_fg.width) // 2
    fg.alpha_composite(emblem_fg, (offf, offf))
    fg.save(os.path.join(OUT, "app_icon_foreground.png"))

    # 3) Adaptive background: gradient square
    gradient(SZ).save(os.path.join(OUT, "app_icon_bg.png"))

    # 4) Native splash logo: emblem on transparent (used over dark blue splash)
    splash = Image.new("RGBA", (SZ, SZ), (0, 0, 0, 0))
    emblem_sp = draw_emblem(int(SZ * 0.7))
    offs = (SZ - emblem_sp.width) // 2
    splash.alpha_composite(emblem_sp, (offs, offs))
    splash.save(os.path.join(OUT, "splash_logo.png"))

    print("Generated:", os.listdir(OUT))


if __name__ == "__main__":
    main()
