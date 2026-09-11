# -*- coding: utf-8 -*-
"""Render the Play in-app product icons.

    python tool/build_product_icons.py

Writes assets/store/products/<product_id>.png, one per sellable product, at
1024 x 1024 as **32-bit** PNG.

## Play's rules, and what they rule out

> Use a unique and accurate image for each product. Don't include text,
> promotions, or branding. 32-bit PNG, 1:1, each side 512–1080 px.

So: no wordmark, no "50% off", and no app logo — which rules out the
eight-pointed star, however tempting. The palette is the app's, because the
purchase sheet should not look like it came from somewhere else, but a palette
is not branding in the sense the rule means.

`compatibility_report` is not built: it is declared `sellable: false` in
`products.dart` because nothing in the app gates on what it grants. If it is
ever sold, add it here and to that flag together.

## Why the icons mean what they mean

- `remove_ads` — an ad banner with a stroke through it. The one case where the
  obvious drawing is also the right one.
- `birth_chart_pdf` — a sheet of paper carrying the South Indian chart grid.
  Accurate rather than generic: the product is that chart, printed.
- `pro_monthly` / `pro_yearly` — an open padlock, because what Pro does is
  unlock. They have to differ from each other, so the badge is a crescent for
  the month and a sun for the year. In an almanac app that is not decoration:
  a month is one cycle of the moon and a year is one of the sun.

## Why the PNG is rewritten

Headless Chrome writes 24-bit RGB whatever it is asked for, including with
`--default-background-color=00000000`. Play asks for 32-bit. So the bitmap is
decoded, given a fully opaque alpha channel, and re-encoded as colour type 6.
No image library is involved because this machine has neither PIL nor
ImageMagick.
"""
from __future__ import print_function

import io
import os
import struct
import subprocess
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "store", "products")
WORK = os.path.join(OUT, "_work")

SIZE = 1024

CHROME_PATHS = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
]

# An ad banner, struck through.
REMOVE_ADS = """
  <rect x="16" y="30" width="68" height="40" rx="7"/>
  <path d="M28 44h30M28 56h18"/>
  <path d="M22 78 78 22" stroke-width="7" stroke-linecap="round"/>
"""

# A sheet carrying the South Indian chart grid.
BIRTH_CHART_PDF = """
  <path d="M26 12h34l16 16v60a4 4 0 0 1-4 4H26a4 4 0 0 1-4-4V16a4 4 0 0 1 4-4Z"/>
  <path d="M60 12v16h16"/>
  <rect x="32" y="40" width="36" height="36" rx="2"/>
  <path d="M32 52h36M32 64h36M44 40v36M56 40v36"/>
"""

# An open padlock: the shackle is lifted clear on one side.
PADLOCK = """
  <rect x="16" y="44" width="42" height="34" rx="6"/>
  <path d="M28 44V32a12 12 0 0 1 24 0v4"/>
  <circle cx="37" cy="61" r="4.4"/>
"""

# Badges that separate the two Pro terms. A month is one cycle of the moon,
# a year is one of the sun.
CRESCENT_BADGE = """
  <g transform="translate(56 52)">
    <circle class="disc" cx="18" cy="18" r="20"/>
    <path class="solid" d="M25.6 22.4A9.4 9.4 0 1 1 13.4 10.2
                           a7.4 7.4 0 0 0 12.2 12.2Z"/>
  </g>
"""

SUN_BADGE = """
  <g transform="translate(56 52)">
    <circle class="disc" cx="18" cy="18" r="20"/>
    <circle class="solid" cx="18" cy="18" r="6.2"/>
    <path class="thin" d="M18 6.4v3.4M18 26.2v3.4M6.4 18h3.4M26.2 18h3.4
             M9.8 9.8l2.4 2.4M23.8 23.8l2.4 2.4M26.2 9.8l-2.4 2.4M12.2 23.8l-2.4 2.4"/>
  </g>
"""

ICONS = [
    ("remove_ads", REMOVE_ADS, 5.5),
    ("birth_chart_pdf", BIRTH_CHART_PDF, 4.6),
    ("pro_monthly", PADLOCK + CRESCENT_BADGE, 5.0),
    ("pro_yearly", PADLOCK + SUN_BADGE, 5.0),
]

PAGE = """<!doctype html><meta charset="utf-8">
<style>
  html,body {{ margin:0; padding:0; }}
  .icon {{
    width:{size}px; height:{size}px; overflow:hidden;
    background:
      radial-gradient(70% 70% at 30% 22%, #3A2566 0%, transparent 70%),
      linear-gradient(150deg, #1B1440 0%, #2A1E55 52%, #14102C 100%);
    display:flex; align-items:center; justify-content:center;
  }}
  svg {{ width:72%; height:72%; overflow:visible; }}
  svg * {{
    fill:none; stroke:#E7BC5C;
    stroke-width:{stroke}; stroke-linecap:round; stroke-linejoin:round;
  }}
  /* The global rule above strokes everything. Badges need the opposite:
     a filled shape reads at this size where a stroked one fills in. */
  svg .disc  {{ fill:#15102F; stroke:#15102F; stroke-width:7; }}
  svg .solid {{ fill:#E7BC5C; stroke:none; }}
  svg .thin  {{ stroke-width:3; }}
</style>
<div class="icon">
  <svg viewBox="0 0 100 100">{glyph}</svg>
</div>
"""


def chrome():
    for path in CHROME_PATHS:
        if os.path.exists(path):
            return path
    print("Chrome not found")
    sys.exit(1)


def as_url(path):
    path = os.path.abspath(path).replace("\\", "/")
    if not path.startswith("/"):
        path = "/" + path
    return "file://" + path


def decode_png(path):
    """Returns (width, height, RGB bytes). Handles what Chrome writes."""
    raw = io.open(path, "rb").read()
    assert raw[:8] == b"\x89PNG\r\n\x1a\n", path

    pos, idat = 8, b""
    width = height = None
    while pos < len(raw):
        (length,) = struct.unpack(">I", raw[pos:pos + 4])
        kind = raw[pos + 4:pos + 8]
        body = raw[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, depth, colour, _, _, interlace = struct.unpack(
                ">IIBBBBB", body)
            assert depth == 8 and colour == 2 and interlace == 0, \
                "unexpected PNG from Chrome: depth %d colour %d" % (depth, colour)
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break

    data = zlib.decompress(idat)
    stride = width * 3
    out = bytearray(stride * height)
    prev = bytearray(stride)
    at = 0

    for y in range(height):
        ftype = data[at]
        at += 1
        line = bytearray(data[at:at + stride])
        at += stride

        if ftype == 1:
            for i in range(3, stride):
                line[i] = (line[i] + line[i - 3]) & 0xFF
        elif ftype == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif ftype == 3:
            for i in range(stride):
                left = line[i - 3] if i >= 3 else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:
            for i in range(stride):
                a = line[i - 3] if i >= 3 else 0
                b = prev[i]
                c = prev[i - 3] if i >= 3 else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF

        out[y * stride:(y + 1) * stride] = line
        prev = line

    return width, height, out


def write_rgba(path, width, height, rgb):
    """Re-encode as colour type 6, fully opaque. Play asks for 32-bit."""
    raw = bytearray()
    for y in range(height):
        raw.append(0)                       # filter: none
        row = rgb[y * width * 3:(y + 1) * width * 3]
        for x in range(width):
            raw += row[x * 3:x * 3 + 3]
            raw.append(255)

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data +
                struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR",
                 struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")

    with io.open(path, "wb") as handle:
        handle.write(png)


def main():
    for folder in (OUT, WORK):
        if not os.path.isdir(folder):
            os.makedirs(folder)

    for product, glyph, stroke in ICONS:
        page = os.path.join(WORK, "%s.html" % product)
        with io.open(page, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(PAGE.format(size=SIZE, glyph=glyph, stroke=stroke))

        shot = os.path.join(WORK, "%s.png" % product)
        subprocess.check_call([
            chrome(), "--headless=new", "--disable-gpu", "--hide-scrollbars",
            "--force-device-scale-factor=1",
            "--screenshot=%s" % shot,
            "--window-size=%d,%d" % (SIZE, SIZE),
            as_url(page),
        ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

        w, h, rgb = decode_png(shot)
        dest = os.path.join(OUT, "%s.png" % product)
        write_rgba(dest, w, h, rgb)

        size = os.path.getsize(dest)
        square = w == h
        in_range = 512 <= w <= 1080
        print("%-18s %dx%d  32-bit  %s  %s  %s bytes"
              % (product, w, h,
                 "1:1" if square else "NOT SQUARE",
                 "in range" if in_range else "OUT OF RANGE",
                 format(size, ",")))
        if size > 8 * 1024 * 1024:
            print("   over Play's 8 MB cap")

    for name in os.listdir(WORK):
        os.remove(os.path.join(WORK, name))
    os.rmdir(WORK)
    return 0


if __name__ == "__main__":
    sys.exit(main())
