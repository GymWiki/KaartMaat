#!/usr/bin/env python3
"""Makes every app icon from the logo (store_assets/logo/logo.png, transparent).

    python tools/make_icons.py

Writes:
  Android adaptive icon  drawable-nodpi/ic_launcher_foreground.png (432 px) and
                         values/ic_launcher_background.xml (logo green)
  Android legacy icons   mipmap-*/ic_launcher.png
  iOS                    AppIcon.appiconset (opaque, as Apple requires)
  Play Store             store_assets/play/icon_512.png and docs/store/icon-512.png

Not part of the Flutter app; needs only Pillow (see tools/README.md).
"""
import json
import re
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "store_assets" / "logo" / "logo.png"
GREEN = (0x34, 0x65, 0x4E)  # the green of logo_green.png
RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"


def trimmed_logo():
    im = Image.open(LOGO).convert("RGBA")
    return im.crop(im.getchannel("A").getbbox())


def place(canvas_size, logo, height_share, offset=(0, 0)):
    """The logo centered on a transparent square, this share of its height."""
    h = round(canvas_size * height_share)
    w = round(logo.width * h / logo.height)
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    scaled = logo.resize((w, h), Image.LANCZOS)
    img.alpha_composite(
        scaled,
        ((canvas_size - w) // 2 + offset[0], (canvas_size - h) // 2 + offset[1]),
    )
    return img


def on_green(size, logo, share=0.78, radius=0.0):
    """Logo on the green square. radius > 0 rounds the corners (legacy)."""
    base = Image.new("RGBA", (size, size), GREEN + (255,))
    base.alpha_composite(place(size, logo, share))
    if radius:
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            (0, 0, size - 1, size - 1), round(size * radius), fill=255
        )
        base.putalpha(mask)
    return base


def main():
    logo = trimmed_logo()

    # Android adaptive icon: 108 dp canvas, the safe area is the middle 72 dp.
    place(432, logo, 0.52).save(RES / "drawable-nodpi" / "ic_launcher_foreground.png")
    bg = RES / "values" / "ic_launcher_background.xml"
    bg.write_text(
        re.sub(r"#[0-9A-Fa-f]{6}", "#%02X%02X%02X" % GREEN, bg.read_text())
    )

    # Android legacy icons (before Android 8)
    for folder, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
        on_green(px * 4, logo, 0.74, radius=0.2).resize((px, px), Image.LANCZOS).save(
            RES / f"mipmap-{folder}" / "ic_launcher.png"
        )

    # iOS: opaque squares, the system rounds them
    contents = json.loads((IOS / "Contents.json").read_text())
    for entry in contents["images"]:
        size = float(entry["size"].split("x")[0]) * int(entry["scale"].rstrip("x"))
        px = round(size)
        on_green(px * 2 if px < 512 else px, logo, 0.74).convert("RGB").resize(
            (px, px), Image.LANCZOS
        ).save(IOS / entry["filename"])

    # Play Store icon (and the copy used by the web pages)
    store = on_green(1024, logo, 0.74).resize((512, 512), Image.LANCZOS)
    (ROOT / "store_assets" / "play").mkdir(parents=True, exist_ok=True)
    store.save(ROOT / "store_assets" / "play" / "icon_512.png")
    store.save(ROOT / "docs" / "store" / "icon-512.png")
    print("icons written")


if __name__ == "__main__":
    main()
