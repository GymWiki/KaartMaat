#!/usr/bin/env python3
"""Builds the Google Play assets for Kaartmaat from the raw screenshots.

    python tools/store_assets.py            # build everything
    python tools/store_assets.py --check    # only verify the outputs

Input : store_assets/raw/NN_name.png (phone), raw_tablet7/ and raw_tablet10/
Output: store_assets/play/phone/01.png .. 08.png   1080x1920, RGB
        store_assets/play/tablet7/01.png ..        1200x1920, RGB (7-inch, portrait)
        store_assets/play/tablet10/01.png ..       1600x2560, RGB (10-inch, portrait)
        store_assets/play/feature_graphic.png      1024x500, RGB
        store_assets/play/icon_512.png             512x512
        store_assets/play/overzicht*.png           contact sheets

Not part of the Flutter app. Needs only Pillow (see tools/README.md).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW_ROOT = ROOT / "store_assets"
OUT = ROOT / "store_assets" / "play"
PHONE = OUT / "phone"
# The app's own headline font (Roboto Condensed Bold, Apache 2.0, see
# assets/fonts/LICENSE-Roboto.txt).
FONT = ROOT / "assets" / "fonts" / "RobotoCondensed-Bold.ttf"
ICON_SRC = ROOT / "docs" / "store" / "icon-512.png"

BG = (0x14, 0x23, 0x1C)       # dark green
CREAM = (0xF2, 0xF5, 0xF0)    # headline text
BRASS = (0xD9, 0xA0, 0x2F)    # accent (app primary)
RED = (0xC9, 0x4A, 0x3E)      # hearts and diamonds

# raw file -> headline (max 2 lines)
SHOTS = [
    ("01_overzicht", "Scoreblad voor al je kaartspellen"),
    ("02_scoretabel", "Altijd duidelijk wie de deler is"),
    ("03_instellingen", "Stel je eigen spelregels in"),
    ("04_verloop", "Het verloop in één oogopslag"),
    ("05_groep", "Je vaste groep met één tik"),
    ("06_duizenden", "Invullen of optellen, jij kiest"),
    ("07_statistieken", "Statistieken van je kaartavonden"),
    ("08_regelboek", "Regelboek bij elk spel"),
]

# name -> (raw folder, output folder, canvas size). The layout is drawn for a
# 1080 px wide canvas and scaled with the width, so every set looks the same.
SETS = {
    "phone": ("raw", "phone", (1080, 1920)),
    "tablet7": ("raw_tablet7", "tablet7", (1200, 1920)),
    "tablet10": ("raw_tablet10", "tablet10", (1600, 2560)),
}
W, H = 1080, 1920   # the phone size, used by the checks below
BASE_W = 1080
SIDE = 70           # minimum space left and right of the headline
HEAD_TOP = 90       # headline starts here
HEAD_BOTTOM = 330   # headline block ends here
SHOT_BOTTOM_GAP = 60


def font(size):
    return ImageFont.truetype(str(FONT), size)


def wrap(draw, text, size, max_width):
    """Breaks text over at most 2 lines, as large as it fits."""
    while size > 40:
        f = font(size)
        words, lines, line = text.split(), [], ""
        for w in words:
            trial = (line + " " + w).strip()
            if draw.textlength(trial, font=f) <= max_width:
                line = trial
            else:
                lines.append(line)
                line = w
        lines.append(line)
        if len(lines) <= 2 and all(
            draw.textlength(x, font=f) <= max_width for x in lines
        ):
            return f, lines
        size -= 4
    raise ValueError("headline does not fit: " + text)


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=255)
    return m


def phone_image(raw_dir, raw_name, headline, size=(W, H)):
    cw, ch = size
    k = cw / BASE_W
    canvas = Image.new("RGB", size, BG)
    draw = ImageDraw.Draw(canvas)

    # headline, centered, up to 2 lines, vertically centered in its block
    head_top, head_bottom = HEAD_TOP * k, HEAD_BOTTOM * k
    f, lines = wrap(draw, headline, round(104 * k), cw - 2 * SIDE * k)
    line_h = f.size * 1.08
    block = line_h * len(lines)
    y = head_top + (head_bottom - head_top - block) / 2
    for line in lines:
        draw.text((cw / 2, y), line, font=f, fill=CREAM, anchor="mt")
        y += line_h
    draw.rounded_rectangle(
        (cw / 2 - 40 * k, head_bottom + 8 * k, cw / 2 + 40 * k, head_bottom + 14 * k),
        round(3 * k), fill=BRASS,
    )

    # screenshot, straight, rounded corners, soft shadow
    shot = Image.open(RAW_ROOT / raw_dir / f"{raw_name}.png").convert("RGB")
    top = round(head_bottom + 44 * k)
    height = round(ch - top - SHOT_BOTTOM_GAP * k)
    width = round(shot.width * height / shot.height)
    shot = shot.resize((width, height), Image.LANCZOS)
    x = (cw - width) // 2
    radius = round(46 * k)

    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, top + 14 * k, x + width, top + height + 14 * k), radius, fill=(0, 0, 0, 150)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(26 * k))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB")
    canvas.paste(shot, (x, top), rounded_mask(shot.size, radius))
    return canvas


# ---- feature graphic ------------------------------------------------------

def suit(draw, kind, cx, cy, s, color):
    """Draws a card suit about 2*s wide, centered on (cx, cy)."""
    if kind == "diamond":
        draw.polygon([(cx, cy - s), (cx + s * 0.72, cy), (cx, cy + s), (cx - s * 0.72, cy)], fill=color)
    elif kind == "heart":
        r = s * 0.5
        draw.ellipse((cx - s + 0.02 * s, cy - s * 0.85, cx - s + 0.02 * s + 2 * r, cy - s * 0.85 + 2 * r), fill=color)
        draw.ellipse((cx + s - 0.02 * s - 2 * r, cy - s * 0.85, cx + s - 0.02 * s, cy - s * 0.85 + 2 * r), fill=color)
        draw.polygon([(cx - s * 0.97, cy - s * 0.2), (cx + s * 0.97, cy - s * 0.2), (cx, cy + s * 0.95)], fill=color)
    elif kind == "spade":
        r = s * 0.5
        draw.polygon([(cx, cy - s), (cx + s * 0.97, cy + s * 0.1), (cx - s * 0.97, cy + s * 0.1)], fill=color)
        draw.ellipse((cx - s + 0.02 * s, cy - s * 0.2, cx - s + 0.02 * s + 2 * r, cy - s * 0.2 + 2 * r), fill=color)
        draw.ellipse((cx + s - 0.02 * s - 2 * r, cy - s * 0.2, cx + s - 0.02 * s, cy - s * 0.2 + 2 * r), fill=color)
        draw.polygon([(cx - s * 0.6, cy + s * 0.15), (cx + s * 0.6, cy + s * 0.15), (cx, cy - s * 0.3)], fill=color)
        draw.polygon([(cx, cy + s * 0.1), (cx + s * 0.32, cy + s), (cx - s * 0.32, cy + s)], fill=color)
    elif kind == "club":
        r = s * 0.46
        for dx, dy in ((0, -0.5), (-0.52, 0.18), (0.52, 0.18)):
            draw.ellipse((cx + dx * s - r, cy + dy * s - r, cx + dx * s + r, cy + dy * s + r), fill=color)
        draw.polygon([(cx - s * 0.45, cy + s * 0.25), (cx + s * 0.45, cy + s * 0.25), (cx, cy - s * 0.4)], fill=color)
        draw.polygon([(cx, cy), (cx + s * 0.32, cy + s), (cx - s * 0.32, cy + s)], fill=color)


def feature_graphic():
    w, h = 1024, 500
    img = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(img)

    # everything stays at least 60 px from the edges
    d.text((70, 150), "Kaartmaat", font=font(112), fill=CREAM, anchor="ls")
    d.rounded_rectangle((70, 178, 150, 186), 4, fill=BRASS)
    d.text((70, 262), "Scoreblad voor", font=font(60), fill=CREAM, anchor="ls")
    d.text((70, 330), "kaartspellen", font=font(60), fill=CREAM, anchor="ls")

    tile, gap = 150, 24
    x0, y0 = w - 70 - 2 * tile - gap, (h - 2 * tile - gap) // 2
    kinds = [("spade", BG), ("heart", RED), ("club", BG), ("diamond", RED)]
    for i, (kind, color) in enumerate(kinds):
        tx = x0 + (i % 2) * (tile + gap)
        ty = y0 + (i // 2) * (tile + gap)
        d.rounded_rectangle((tx, ty, tx + tile, ty + tile), 26, fill=CREAM)
        suit(d, kind, tx + tile / 2, ty + tile / 2 - 2, 44, color)
    return img


# ---- contact sheet and checks ---------------------------------------------

def contact_sheet(files):
    cols, tw = 4, 270
    first = Image.open(files[0])
    th = round(tw * first.height / first.width)
    pad = 24
    rows = (len(files) + cols - 1) // cols
    sheet = Image.new("RGB", (pad + cols * (tw + pad), pad + rows * (th + pad)), (0x0B, 0x14, 0x10))
    for i, f in enumerate(files):
        im = Image.open(f).convert("RGB").resize((tw, th), Image.LANCZOS)
        sheet.paste(im, (pad + (i % cols) * (tw + pad), pad + (i // cols) * (th + pad)))
    return sheet


def check(paths_and_sizes):
    # The feature graphic is exactly 1024x500 by Play rule, so the 2:1 limit
    # only applies to the other images.
    ok = True
    for path, size in paths_and_sizes:
        im = Image.open(path)
        mb = path.stat().st_size / 1e6
        ratio_ok = max(im.size) <= 2 * min(im.size) or size == (1024, 500)
        side_ok = all(320 <= v <= 3840 for v in im.size) and ratio_ok
        good = (size is None or im.size == size) and side_ok and mb <= 8 and im.format == "PNG"
        if size and im.mode != "RGB":
            good = False
        print(f"{'OK ' if good else 'BAD'} {path.relative_to(ROOT)}  {im.size[0]}x{im.size[1]} {im.mode} {mb:.2f} MB")
        ok &= good
    return ok


def main():
    out_files = {}
    for name, (raw_dir, out_dir, size) in SETS.items():
        out = OUT / out_dir
        files = [out / f"{i + 1:02d}.png" for i in range(len(SHOTS))]
        out_files[name] = (files, size)
        if "--check" in sys.argv:
            continue
        if not (RAW_ROOT / raw_dir).exists():
            print(f"skip {name}: no {raw_dir}/")
            continue
        out.mkdir(parents=True, exist_ok=True)
        for f, (raw, headline) in zip(files, SHOTS):
            phone_image(raw_dir, raw, headline, size).save(f, optimize=True)
        sheet = "overzicht.png" if name == "phone" else f"overzicht_{name}.png"
        contact_sheet(files).save(OUT / sheet, optimize=True)

    if "--check" not in sys.argv:
        OUT.mkdir(parents=True, exist_ok=True)
        feature_graphic().save(OUT / "feature_graphic.png", optimize=True)
        if ICON_SRC.exists():
            Image.open(ICON_SRC).resize((512, 512), Image.LANCZOS).save(OUT / "icon_512.png")

    items = []
    for name, (files, size) in out_files.items():
        items += [(f, size) for f in files if f.exists()]
    items.append((OUT / "feature_graphic.png", (1024, 500)))
    items.append((OUT / "icon_512.png", None))
    for sheet in ["overzicht.png", "overzicht_tablet7.png", "overzicht_tablet10.png"]:
        if (OUT / sheet).exists():
            items.append((OUT / sheet, None))
    sys.exit(0 if check(items) else 1)


if __name__ == "__main__":
    main()
