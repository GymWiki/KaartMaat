#!/usr/bin/env python3
"""Builds the Google Play assets for Kaartmaat from the raw screenshots.

    python tools/store_assets.py            # build everything
    python tools/store_assets.py --check    # only verify the outputs

Input : store_assets/raw/NN_name.png (full-screen device screenshots)
Output: store_assets/play/phone/01.png .. 08.png   1080x1920, RGB
        store_assets/play/feature_graphic.png      1024x500, RGB
        store_assets/play/icon_512.png             512x512
        store_assets/play/overzicht.png            contact sheet

Not part of the Flutter app. Needs only Pillow (see tools/README.md).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "store_assets" / "raw"
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

W, H = 1080, 1920
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


def phone_image(raw_name, headline):
    canvas = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    # headline, centered, up to 2 lines, vertically centered in its block
    f, lines = wrap(draw, headline, 104, W - 2 * SIDE)
    line_h = f.size * 1.08
    block = line_h * len(lines)
    y = HEAD_TOP + (HEAD_BOTTOM - HEAD_TOP - block) / 2
    for line in lines:
        draw.text((W / 2, y), line, font=f, fill=CREAM, anchor="mt")
        y += line_h
    draw.rounded_rectangle((W / 2 - 40, HEAD_BOTTOM + 8, W / 2 + 40, HEAD_BOTTOM + 14), 3, fill=BRASS)

    # screenshot, straight, rounded corners, soft shadow
    shot = Image.open(RAW / f"{raw_name}.png").convert("RGB")
    top = HEAD_BOTTOM + 44
    height = H - top - SHOT_BOTTOM_GAP
    width = round(shot.width * height / shot.height)
    shot = shot.resize((width, height), Image.LANCZOS)
    x = (W - width) // 2
    radius = 46

    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, top + 14, x + width, top + height + 14), radius, fill=(0, 0, 0, 150)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
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
    th = round(tw * H / W)
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
    phone_files = [PHONE / f"{i + 1:02d}.png" for i in range(len(SHOTS))]
    if "--check" not in sys.argv:
        PHONE.mkdir(parents=True, exist_ok=True)
        for out, (raw, headline) in zip(phone_files, SHOTS):
            phone_image(raw, headline).save(out, optimize=True)
        feature_graphic().save(OUT / "feature_graphic.png", optimize=True)
        if ICON_SRC.exists():
            Image.open(ICON_SRC).resize((512, 512), Image.LANCZOS).save(OUT / "icon_512.png")
        contact_sheet(phone_files).save(OUT / "overzicht.png", optimize=True)

    items = [(f, (W, H)) for f in phone_files]
    items.append((OUT / "feature_graphic.png", (1024, 500)))
    items.append((OUT / "icon_512.png", None))
    items.append((OUT / "overzicht.png", None))
    sys.exit(0 if check(items) else 1)


if __name__ == "__main__":
    main()
