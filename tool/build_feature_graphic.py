# -*- coding: utf-8 -*-
"""Render assets/store/feature_graphic.html to Play's exact size.

    python tool/build_feature_graphic.py

Writes assets/store/feature_graphic_1024x500.png at exactly 1024 x 500, which
is what Play requires and refuses to resize for you.

## Why a browser

Play's feature graphic carries the app's name in Sinhala and Tamil. Image
generators cannot shape either script: two attempts produced a misspelt app
name, a wrong vowel sign, and on the second pass a page of invented English.
A browser shapes Indic text correctly, and the page loads the same Noto faces
the app bundles — so the wordmark on the store matches the wordmark on the
phone, glyph for glyph.

## Why 2x then down

Rendered at device scale 2 and downsampled, so the icon and the hairline
strokes resample cleanly rather than aliasing at 1x. Chrome does the
downsample itself on a second pass; no image library is needed, which matters
because this machine has neither PIL nor ImageMagick.
"""
from __future__ import print_function

import io
import os
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORE = os.path.join(ROOT, "assets", "store")
PAGE = os.path.join(STORE, "feature_graphic.html")
OUT = os.path.join(STORE, "feature_graphic_1024x500.png")

WIDTH, HEIGHT = 1024, 500

CHROME = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
]


def chrome():
    for path in CHROME:
        if os.path.exists(path):
            return path
    print("Chrome not found. Looked in:")
    for path in CHROME:
        print("  " + path)
    sys.exit(1)


def as_url(path):
    """A file:// URL Chrome accepts on Windows and on POSIX."""
    path = os.path.abspath(path).replace("\\", "/")
    if not path.startswith("/"):
        path = "/" + path          # C:/... -> /C:/...
    return "file://" + path


def png_size(path):
    with io.open(path, "rb") as handle:
        raw = handle.read(32)
    assert raw[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG: %s" % path
    return struct.unpack(">II", raw[16:24])


def shoot(page_url, out, width, height, scale):
    subprocess.check_call([
        chrome(),
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        # The page is local and loads local fonts; without this Chrome
        # refuses the @font-face requests and silently falls back to a
        # Latin face, which is exactly the failure this script prevents.
        "--allow-file-access-from-files",
        "--force-device-scale-factor=%d" % scale,
        "--screenshot=%s" % out,
        "--window-size=%d,%d" % (width, height),
        page_url,
    ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def main():
    if not os.path.exists(PAGE):
        print("missing %s" % PAGE)
        return 1

    big = os.path.join(STORE, "_feature_2x.png")

    # Pass 1: render at 2x.
    shoot(as_url(PAGE), big, WIDTH, HEIGHT, 2)
    w, h = png_size(big)
    print("rendered  %dx%d" % (w, h))

    # Pass 2: place that bitmap at exactly 1024x500 and shoot again, which
    # is Chrome resampling it for us.
    shim = os.path.join(STORE, "_downscale.html")
    with io.open(shim, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(
            "<!doctype html><meta charset='utf-8'>"
            "<style>html,body{margin:0;padding:0;overflow:hidden}"
            "img{display:block;width:%dpx;height:%dpx}</style>"
            "<img src='%s'>" % (WIDTH, HEIGHT, os.path.basename(big))
        )
    shoot(as_url(shim), OUT, WIDTH, HEIGHT, 1)

    os.remove(big)
    os.remove(shim)

    w, h = png_size(OUT)
    ok = (w, h) == (WIDTH, HEIGHT)
    size = os.path.getsize(OUT)
    print("exported  %dx%d  %s  %s bytes"
          % (w, h, "OK" if ok else "WRONG SIZE", format(size, ",")))
    print("          %s" % OUT)

    # Play rejects anything over 15 MB, and a banner near that is a mistake.
    if size > 2 * 1024 * 1024:
        print("warning: over 2 MB, which is large for a banner")

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
