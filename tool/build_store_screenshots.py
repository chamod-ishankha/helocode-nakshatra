# -*- coding: utf-8 -*-
"""Frame the raw device captures into Play Store screenshots.

    python tool/build_store_screenshots.py

Reads  assets/store/screenshots/{en,si,ta}/NN-name.png   (raw, 1080x2340)
Writes assets/store/screenshots/framed/{en,si,ta}/NN-name.png  (1080x1920)

## Why frame them at all

A raw capture is perfectly legal on Play and plenty of good apps ship them.
Framed ones read better in a listing, and there is a second reason here: a
raw capture off this device is 1080x2340, which is 9:19.5 and taller than the
16:9-to-9:16 window Play documents for phone screenshots. Dropping the device
into a 1080x1920 canvas puts every shot squarely inside that window without
stretching anything.

## Where the words come from

Headings are the app's own strings, read out of the ARB files — `chartTitle`,
`dashaTitle` and so on. That is deliberate: those have been through the same
review as everything else on screen, so the store and the app say the same
words rather than two translations of the same idea.

Subtitles are the captions from docs/play-listing.md.

## Why a browser

The same reason as the feature graphic: Sinhala and Tamil need real shaping,
and the fonts are the app's own bundled Noto faces, so the store text and the
screenshot underneath it render identically.
"""
from __future__ import print_function

import io
import json
import os
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, "assets", "store", "screenshots")
OUT = os.path.join(SHOTS, "framed")
WORK = os.path.join(OUT, "_work")

WIDTH, HEIGHT = 1080, 1920

CHROME_PATHS = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
]

# shot file stem -> (ARB key for the heading, caption key below)
#
# The heading for shot 01 is the rāhu kālaya card's own label, because that
# card is what the screenshot is of and what the whole app is named after.
SHOTS_MAP = [
    ("01-home",          "homeRahuKalaya"),
    ("02-chart",         "chartTitle"),
    ("03-dasha",         "dashaTitle"),
    ("04-compatibility", "compatTitle"),
    ("05-horoscope",     "horoscopeTitle"),
    ("06-calendar",      "calendarTitle"),
    ("07-settings",      "settingsTitle"),
    ("08-positions",     "chartPositions"),
]

CAPTIONS = os.path.join(ROOT, "tool", "store_captions.json")


def subtitles():
    """The line under each heading, keyed by shot then language.

    A JSON file rather than a table in here: the Sinhala and Tamil would
    otherwise be hand-typed unicode escapes, and one truncated escape is a
    syntax error that says nothing about which caption broke.
    """
    with io.open(CAPTIONS, encoding="utf-8") as handle:
        data = json.load(handle)
    return {k: v for k, v in data.items() if not k.startswith("_")}


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


def png_size(path):
    with io.open(path, "rb") as handle:
        head = handle.read(32)
    assert head[:8] == b"\x89PNG\r\n\x1a\n", path
    return struct.unpack(">II", head[16:24])


def arb(lang):
    with io.open(os.path.join(ROOT, "lib", "l10n", "app_%s.arb" % lang),
                 encoding="utf-8") as handle:
        return json.load(handle)


PAGE = u"""<!doctype html><meta charset="utf-8">
<style>
  @font-face {{ font-family:'NSinhala'; src:url('{fonts}/NotoSansSinhala.ttf') format('truetype'); }}
  @font-face {{ font-family:'NTamil';   src:url('{fonts}/NotoSansTamil.ttf') format('truetype'); }}
  html,body {{ margin:0; padding:0; }}
  .canvas {{
    width:{w}px; height:{h}px; overflow:hidden; position:relative;
    background:
      radial-gradient(760px 620px at 50% -6%, #3A2566 0%, transparent 64%),
      linear-gradient(158deg, #171238 0%, #241a4a 52%, #15102F 100%);
    font-family:'NSinhala','NTamil','Segoe UI',system-ui,Arial,sans-serif;
    color:#fff; box-sizing:border-box;
    display:flex; flex-direction:column; align-items:center;
    padding:84px 64px 0;
  }}
  .heading {{
    font-size:62px; font-weight:700; line-height:1.14;
    letter-spacing:-.5px; text-align:center;
  }}
  .sub {{
    margin-top:20px; font-size:31px; line-height:1.34;
    color:#BCAFDD; text-align:center; max-width:900px;
  }}
  /* The device. A bezel rather than a photographic frame: at listing size a
     glossy mockup adds nothing and hides pixels of the actual app. */
  .phone {{
    margin-top:{gap}px;
    width:{pw}px; height:{ph}px;
    border-radius:46px; padding:12px;
    background:linear-gradient(160deg,#4b3d72,#241c3f);
    box-shadow:0 26px 70px rgba(0,0,0,.55), 0 0 0 1px rgba(224,180,80,.22);
    box-sizing:border-box;
  }}
  .phone img {{ display:block; width:100%; height:100%;
                border-radius:35px; object-fit:cover; object-position:top; }}
</style>
<div class="canvas">
  <div class="heading">{heading}</div>
  {subline}
  <div class="phone"><img src="{shot}"></div>
</div>
"""


def build(lang, stem, heading, subtitle, src, dest):
    # The device keeps its own aspect ratio; only the canvas changes.
    sw, sh = png_size(src)
    text_block = 300 if subtitle else 230
    gap = 56
    avail = HEIGHT - 84 - text_block - gap
    ph = avail
    pw = int(round(ph * (sw / float(sh))))
    # Never wider than the canvas allows.
    max_w = WIDTH - 2 * 120
    if pw > max_w:
        pw = max_w
        ph = int(round(pw * (sh / float(sw))))

    sub_html = u'<div class="sub">%s</div>' % subtitle if subtitle else u""
    html = PAGE.format(
        w=WIDTH, h=HEIGHT, pw=pw, ph=ph, gap=gap,
        heading=heading, subline=sub_html,
        shot=as_url(src),
        fonts=as_url(os.path.join(ROOT, "assets", "fonts")).rstrip("/"),
    )

    page = os.path.join(WORK, "%s-%s.html" % (lang, stem))
    with io.open(page, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(html)

    subprocess.check_call([
        chrome(), "--headless=new", "--disable-gpu", "--hide-scrollbars",
        "--allow-file-access-from-files",
        "--force-device-scale-factor=1",
        "--screenshot=%s" % dest,
        "--window-size=%d,%d" % (WIDTH, HEIGHT),
        as_url(page),
    ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def main():
    for folder in (OUT, WORK):
        if not os.path.isdir(folder):
            os.makedirs(folder)

    captions = subtitles()
    made = 0
    for lang in ("en", "si", "ta"):
        strings = arb(lang)
        src_dir = os.path.join(SHOTS, lang)
        out_dir = os.path.join(OUT, lang)
        if not os.path.isdir(out_dir):
            os.makedirs(out_dir)

        print("%s/" % lang)
        for stem, key in SHOTS_MAP:
            src = os.path.join(src_dir, "%s.png" % stem)
            if not os.path.exists(src):
                continue

            heading = strings.get(key)
            if not heading:
                print("   %-18s no ARB string for %s" % (stem, key))
                continue
            subtitle = captions.get(stem, {}).get(lang, "")

            dest = os.path.join(out_dir, "%s.png" % stem)
            build(lang, stem, heading, subtitle, src, dest)

            w, h = png_size(dest)
            ok = (w, h) == (WIDTH, HEIGHT)
            print("   %-18s %dx%d %s" % (stem, w, h, "" if ok else "WRONG"))
            made += 1
        print("")

    for name in os.listdir(WORK):
        os.remove(os.path.join(WORK, name))
    os.rmdir(WORK)

    print("framed %d screenshots at %dx%d" % (made, WIDTH, HEIGHT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
