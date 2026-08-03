#!/usr/bin/env python3
"""
Generate app icons for Neno SmartLife.
Design: neon yellow-green (#B5D317) background, bold dark 'N' (#0A0A0A).
"""

import os
import math
from PIL import Image, ImageDraw

BG_COLOR = (181, 211, 23)
FG_COLOR = (10,  10,  10)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def draw_N(draw: ImageDraw.ImageDraw, px: int):
    """
    Draw a bold capital N using three overlapping filled shapes.
    Since all three are the same colour, overlap is invisible but ensures
    there are zero gaps at the joints.

      Left stem:  full-height rectangle on the left
      Right stem: full-height rectangle on the right
      Diagonal:   parallelogram extending sw into each stem at both ends
                  so the joints are always seamless regardless of rounding.

    The parallelogram corners sit on y=oy and y=b (never above/below),
    and are widened left into the left stem and right into the right stem.
    """
    glyph_h = px * 0.60
    sw      = glyph_h * 0.20   # stem width
    glyph_w = glyph_h * 0.72

    ox = (px - glyph_w) / 2
    oy = (px - glyph_h) / 2
    r  = ox + glyph_w
    b  = oy + glyph_h

    Li = ox + sw   # left stem inner x
    Ri = r  - sw   # right stem inner x

    # ── Left stem ─────────────────────────────────────────────────────────────
    draw.polygon([(ox, oy), (Li, oy), (Li, b), (ox, b)], fill=FG_COLOR)

    # ── Right stem ────────────────────────────────────────────────────────────
    draw.polygon([(Ri, oy), (r, oy), (r, b), (Ri, b)], fill=FG_COLOR)

    # ── Diagonal parallelogram ────────────────────────────────────────────────
    # The diagonal runs from the top-left area to the bottom-right area.
    # Width `dw` is set so the perpendicular stroke thickness equals sw:
    #   dw = sw * diagonal_length / glyph_h
    run    = Ri - Li
    length = math.hypot(run, glyph_h)
    dw     = sw * length / glyph_h

    # Extend sw into each stem at both ends to guarantee seamless joints.
    # tl/tr are the two top corners (at y=oy), bl/br are the bottom corners (at y=b).
    tl = (ox,        oy)   # extends sw left into left stem
    tr = (ox + dw,   oy)
    br = (r,         b)    # extends sw right into right stem
    bl = (r   - dw,  b)

    draw.polygon([tl, tr, br, bl], fill=FG_COLOR)


def make_icon(px: int, android_icon: bool = False) -> Image.Image:
    img  = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    if android_icon:
        draw.rectangle([0, 0, px - 1, px - 1], fill=BG_COLOR)
    else:
        radius = int(px * 0.22)
        draw.rounded_rectangle([0, 0, px - 1, px - 1], radius=radius, fill=BG_COLOR)

    draw_N(draw, px)
    return img


def save(img: Image.Image, path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.convert("RGBA").save(path, "PNG", optimize=True)
    print(f"  ✓ {os.path.relpath(path, BASE_DIR)}")


def generate():
    android_specs = {
        "mipmap-mdpi":    48,
        "mipmap-hdpi":    72,
        "mipmap-xhdpi":   96,
        "mipmap-xxhdpi":  144,
        "mipmap-xxxhdpi": 192,
    }
    android_res = os.path.join(BASE_DIR, "android", "app", "src", "main", "res")
    print("\nAndroid icons:")
    for folder, size in android_specs.items():
        save(make_icon(size, android_icon=True),
             os.path.join(android_res, folder, "ic_launcher.png"))

    ios_specs = [
        ("Icon-App-20x20@1x.png",     20),
        ("Icon-App-20x20@2x.png",     40),
        ("Icon-App-20x20@3x.png",     60),
        ("Icon-App-29x29@1x.png",     29),
        ("Icon-App-29x29@2x.png",     58),
        ("Icon-App-29x29@3x.png",     87),
        ("Icon-App-40x40@1x.png",     40),
        ("Icon-App-40x40@2x.png",     80),
        ("Icon-App-40x40@3x.png",     120),
        ("Icon-App-60x60@2x.png",     120),
        ("Icon-App-60x60@3x.png",     180),
        ("Icon-App-76x76@1x.png",     76),
        ("Icon-App-76x76@2x.png",     152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    ios_dir = os.path.join(
        BASE_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset"
    )
    print("\niOS icons:")
    for filename, size in ios_specs:
        save(make_icon(size, android_icon=True),
             os.path.join(ios_dir, filename))

    print("\nDone.")


if __name__ == "__main__":
    generate()
