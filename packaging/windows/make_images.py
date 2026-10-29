"""Render the images of the Windows installer from the SVG icon.

Usage: make_images.py ICON_PNG OUTPUT_DIR

ICON_PNG is the application icon rendered large and square. Writes reto.ico
for the program and the installer, and the wizard images of reto.iss. Several
sizes per wizard image let Setup pick the sharpest one for the DPI scaling of
the display.
"""

import sys
from pathlib import Path

from PIL import Image

ICO_SIZES = [
    (16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256),
]
# (width, height) of the tall image on the welcome and finish pages.
LARGE_SIZES = [(202, 386), (336, 643), (430, 824)]
# Side of the square image in the top-right corner of the other pages.
SMALL_SIZES = [58, 97, 124]


def main(icon_path, out):
    icon = Image.open(icon_path).convert("RGBA")
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)

    icon.save(out / "reto.ico", sizes=ICO_SIZES)

    for width, height in LARGE_SIZES:
        image = Image.new("RGBA", (width, height), (255, 255, 255, 255))
        side = round(width * 0.7)
        image.alpha_composite(
            icon.resize((side, side), Image.LANCZOS),
            ((width - side) // 2, round(height * 0.2)),
        )
        image.convert("RGB").save(out / f"wizard-large-{width}.png")

    for side in SMALL_SIZES:
        icon.resize((side, side), Image.LANCZOS).save(
            out / f"wizard-small-{side}.png"
        )


if __name__ == "__main__":
    main(*sys.argv[1:3])
