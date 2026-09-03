"""
generate_store_icon.py

Upscales the largest existing launcher icon (192x192) to a
Play Store-ready 512x512 PNG with clean rounded corners, and saves it
to assets/store_icon.png.

Strategy
--------
The source icon has its own rectangular background baked in.
To get clean rounded corners we:
  1. Sample the background colour from a corner pixel of the source.
  2. Fill the entire 512x512 canvas with that colour.
  3. Paste the upscaled icon on top using the rounded mask — so the
     area outside the mask is the same colour as the icon's own
     background, making the transition invisible.

Requirements:
    pip install Pillow

Usage:
    python generate_store_icon.py
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageChops, ImageFilter

# ── config ─────────────────────────────────────────────────────────────────
SOURCE = Path("android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png")
OUTPUT = Path("assets/store_icon.png")
TARGET_SIZE = (512, 512)

# Corner radius as a fraction of the icon width.
# 0.225 ≈ Android 12 squircle style (115 px on a 512 canvas).
# Increase toward 0.5 for a full circle, decrease for subtler rounding.
CORNER_RADIUS_RATIO = 0.225


def sample_background_colour(img: Image.Image) -> tuple[int, int, int]:
    """
    Sample the icon's background colour by averaging the four corner pixels.
    Works whether the source uses a solid fill or near-solid gradient edge.
    """
    w, h = img.size
    corners = [
        img.getpixel((0, 0)),
        img.getpixel((w - 1, 0)),
        img.getpixel((0, h - 1)),
        img.getpixel((w - 1, h - 1)),
    ]
    # Each pixel is (R, G, B) or (R, G, B, A) — only take RGB
    rgb_corners = [c[:3] for c in corners]
    avg = tuple(int(sum(ch) / len(ch)) for ch in zip(*rgb_corners))
    return avg  # type: ignore[return-value]


def make_rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    """
    Return a high-quality greyscale mask: white inside the rounded rect,
    black outside. Rendered at 4× then downscaled for smooth anti-aliasing.
    """
    scale = 4
    big = (size[0] * scale, size[1] * scale)
    mask = Image.new("L", big, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        [(0, 0), (big[0] - 1, big[1] - 1)],
        radius=radius * scale,
        fill=255,
    )
    return mask.resize(size, Image.LANCZOS)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Source icon not found: {SOURCE}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    with Image.open(SOURCE) as src:
        print(f"Source: {SOURCE}  ({src.width}x{src.height}, mode={src.mode})")
        src_rgba = src.convert("RGBA")

    # 1. Sample the icon's own background colour from its corner pixels
    bg_colour = sample_background_colour(src_rgba)
    print(f"Detected background colour: rgb{bg_colour}")

    # 2. Upscale to target size
    upscaled = src_rgba.resize(TARGET_SIZE, Image.LANCZOS)

    # 3. Build anti-aliased rounded mask
    radius = int(TARGET_SIZE[0] * CORNER_RADIUS_RATIO)
    rounded_mask = make_rounded_mask(TARGET_SIZE, radius)

    # 4. Apply mask to the upscaled icon's alpha channel
    existing_alpha = upscaled.split()[3]
    final_alpha = ImageChops.multiply(existing_alpha, rounded_mask)
    upscaled.putalpha(final_alpha)

    # 5. Composite onto a background filled with the icon's own background colour.
    #    This means the cut corners blend invisibly into the surrounding area.
    background = Image.new("RGB", TARGET_SIZE, bg_colour)
    background.paste(upscaled, mask=upscaled.split()[3])

    background.save(OUTPUT, format="PNG", optimize=True)
    print(f"Saved:  {OUTPUT}  ({TARGET_SIZE[0]}x{TARGET_SIZE[1]}, RGB, radius={radius}px)")
    print("Done! Upload assets/store_icon.png to the Play Store.")


if __name__ == "__main__":
    main()
