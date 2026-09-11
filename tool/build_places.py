# -*- coding: utf-8 -*-
"""Build the bundled birth-place data for every country.

    python tool/build_places.py              # download if needed, then build
    python tool/build_places.py --report     # build nothing, just print what would change

Writes `assets/data/places/index.json` plus one file per country.

Why bundled and not fetched
---------------------------
Onboarding must complete with no network at all — that is the promise in the
store listing and the reason `place_repository.dart` loads an asset. It is also
a privacy promise: a geocoding call would send a birth place to a third party,
which the privacy policy says we do not do. Corrections ship with a release.

Why one file per country
------------------------
The picker chooses a country before it searches, so only one country is ever
parsed. A single 2.7 MB blob would cost a low-end phone a few hundred
milliseconds of JSON decode during onboarding, for data it will never look at.

Why `cities15000`
-----------------
GeoNames publishes cuts at population 15000, 5000 and 1000. The finer cuts are
four and fifteen times the size for towns that almost nobody enters as a birth
place, and the app is not a gazetteer. Sri Lanka keeps its hand-curated list on
top of the cut, so the home market is not thinned by that choice.

The timezone is the point
-------------------------
Every row carries an IANA zone from GeoNames. Before this, `Place.timezone`
defaulted to `Asia/Colombo` and that was correct, because every place was Sri
Lankan. A place outside Sri Lanka with the wrong zone produces a chart that is
hours out — the lagna moves by whole signs — with nothing on screen to say so.
A confidently wrong chart is worse than a missing city, so a row without a
resolvable zone is dropped rather than guessed.

Licence
-------
GeoNames data is CC BY 4.0. Attribution is required and lives in
`assets/data/places/README.md` and beside the Swiss Ephemeris notice in the
app's licences screen.
"""
from __future__ import print_function

import io
import json
import math
import os
import re
import shutil
import sys
import zipfile

try:
    from urllib.request import urlopen
except ImportError:  # Python 2
    from urllib2 import urlopen

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "build", "geonames")
OUT = os.path.join(ROOT, "assets", "data", "places")
CURATED = os.path.join(ROOT, "tool", "sl_places_curated.json")

BASE = "https://download.geonames.org/export/dump/"

# Plain files, and zips we want one member out of.
PLAIN = ["countryInfo.txt", "admin1CodesASCII.txt", "admin2Codes.txt"]
ZIPS = {
    "cities15000.zip": "cities15000.txt",
    "alternatenames/LK.zip": "LK.txt",
    "alternatenames/IN.zip": "IN.txt",
}

# Which scripts each market gets. Everywhere else is English only.
#
# This mirrors where the app is actually read: Sri Lanka in all three, India in
# Tamil, and the rest of the world in the one language its place names are
# already written in. Translating 34,000 towns into three scripts would be
# waste; translating the two markets that matter is not.
LOCALISED = {"LK": ("si", "ta"), "IN": ("ta",)}

# The only two country names worth carrying in script. Everything else shows in
# English in the country picker, which is what the requirement asks for.
COUNTRY_NAMES = {
    "LK": {"si": u"ශ්‍රී ලංකාව",
           "ta": u"இலங்கை"},
    "IN": {"ta": u"இந்தியா"},
}

# A language tag is not a script guarantee. GeoNames carries an `isolanguage`
# of `ta` for the Latin-script string "Chennai", which is the English name
# wearing a Tamil label — storing it would record "the Tamil for Chennai is
# Chennai" and defeat the whole point of keeping the field absent when there is
# no translation. So every candidate is checked against the Unicode block it
# claims to be written in.
SCRIPTS = {
    "si": re.compile(u"[඀-෿]"),
    "ta": re.compile(u"[஀-௿]"),
}


def in_script(lang, name):
    return bool(SCRIPTS[lang].search(name))


# Curated rows are matched to GeoNames by name and proximity. Sri Lankan towns
# sit close together, so this stays tight: beyond it, treat them as different
# places rather than silently merging two towns into one row.
MATCH_KM = 15.0


# --------------------------------------------------------------------------
# fetching


def fetch(name):
    """Download `name` into the cache if it is not already there."""
    local = os.path.join(CACHE, os.path.basename(name))
    if os.path.exists(local):
        return local
    if not os.path.isdir(CACHE):
        os.makedirs(CACHE)
    sys.stderr.write("downloading %s ...\n" % name)
    response = urlopen(BASE + name)
    with open(local, "wb") as handle:
        shutil.copyfileobj(response, handle)
    return local


def source(name):
    """Path to a usable text file, unzipping first when the source is a zip."""
    if name in ZIPS:
        member = ZIPS[name]
        target = os.path.join(CACHE, member)
        if not os.path.exists(target):
            with zipfile.ZipFile(fetch(name)) as archive:
                with archive.open(member) as src:
                    with open(target, "wb") as dst:
                        shutil.copyfileobj(src, dst)
        return target
    return fetch(name)


def rows(path):
    """Yield tab-separated rows, skipping GeoNames' `#` comment banner."""
    with io.open(path, encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("#"):
                continue
            line = line.rstrip("\n")
            if line:
                yield line.split("\t")


# --------------------------------------------------------------------------
# loading


def load_countries():
    """code -> English country name, for countries we will actually emit."""
    out = {}
    for c in rows(source("countryInfo.txt")):
        if len(c) > 4 and c[0]:
            out[c[0]] = c[4]
    return out


def load_admin(path, width):
    """`LK.1` or `LK.1.2` -> its English name."""
    out = {}
    for c in rows(source(path)):
        if len(c) > 1 and c[0].count(".") == width - 1:
            out[c[0]] = c[1]
    return out


def load_alternates(country):
    """geonameid -> {lang: name}, best name first.

    GeoNames marks one name per language as preferred and flags historic ones.
    Historic names are dropped outright: a birth place should read as the town
    is called now, not as it was called under a former administration.
    """
    best = {}
    for c in rows(source("alternatenames/%s.zip" % country)):
        if len(c) < 4:
            continue
        gid, lang, name = c[1], c[2], c[3]
        if lang not in ("si", "ta"):
            continue
        if len(c) > 7 and c[7] == "1":  # historic
            continue
        if not in_script(lang, name):
            continue
        preferred = len(c) > 4 and c[4] == "1"
        colloquial = len(c) > 6 and c[6] == "1"
        # Lower sorts first: preferred beats plain beats colloquial.
        rank = (0 if preferred else 2) + (1 if colloquial else 0)
        slot = best.setdefault(gid, {})
        if lang not in slot or rank < slot[lang][0]:
            slot[lang] = (rank, name)
    return {gid: {lang: value[1] for lang, value in langs.items()}
            for gid, langs in best.items()}


def load_cities():
    """Every city row, grouped by country code."""
    by_country = {}
    for c in rows(source("cities15000.zip")):
        if len(c) < 19:
            continue
        if not c[17]:  # no timezone: unusable, see module docstring
            continue
        by_country.setdefault(c[8], []).append(c)
    return by_country


def harvest_inline(cities, alternates, langs):
    """Fill gaps from the city row's own comma-separated alternate names.

    `cities15000` carries an untagged list of alternate names per city. The
    tagged per-country files miss names that this list has — Chennai is in the
    tagged file only as Latin-script "Chennai", while the inline list holds the
    real Tamil one — so where a language is still missing, take the first
    candidate actually written in that script.
    """
    for c in cities:
        gid = c[0]
        have = alternates.setdefault(gid, {})
        missing = [lang for lang in langs if not have.get(lang)]
        if not missing:
            continue
        for candidate in c[3].split(","):
            candidate = candidate.strip()
            if not candidate:
                continue
            for lang in list(missing):
                if in_script(lang, candidate):
                    have[lang] = candidate
                    missing.remove(lang)
            if not missing:
                break


def load_curated():
    with io.open(CURATED, encoding="utf-8") as handle:
        return json.load(handle)["places"]


# --------------------------------------------------------------------------
# merging


def haversine(lat1, lon1, lat2, lon2):
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = p2 - p1
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def norm(text):
    """Loose name key: 'Dehiwala-Mount Lavinia' and 'Dehiwala' stay distinct,
    but case and punctuation differences do not create a duplicate row."""
    return re.sub(r"[^a-z0-9]", "", text.lower())


# GeoNames writes Sri Lankan districts as "Colombo District"; the curated list
# and every Sri Lankan reader write them as "Colombo".
DISTRICT_SUFFIX = re.compile(r"\s+District$")


def place_from_geonames(c, admin1, admin2, alternates, langs,
                        districts=None, country=None):
    """One emitted row, built from a GeoNames city.

    `districts` maps an English district name to its Sinhala and Tamil forms.
    Only Sri Lanka has one, and it comes from the curated list rather than from
    GeoNames, which has no Sinhala district names at all.
    """
    gid = c[0]
    key1 = "%s.%s" % (c[8], c[10])
    key2 = "%s.%s.%s" % (c[8], c[10], c[11])
    # admin2 is the district and is what a reader recognises; admin1 (the
    # state or province) is the fallback. City-states and small territories —
    # Singapore, Hong Kong, Aruba — have neither, and there the country is the
    # only true answer. Never blank: the subtitle is what tells two towns of
    # the same name apart.
    district = DISTRICT_SUFFIX.sub(
        "", admin2.get(key2) or admin1.get(key1) or country or "")
    place = {
        "id": gid,
        "en": c[1],
        "lat": round(float(c[4]), 4),
        "lon": round(float(c[5]), 4),
        "district": district,
        "timezone": c[17],
    }
    names = alternates.get(gid, {})
    for lang in langs:
        if names.get(lang):
            place[lang] = names[lang]
    if districts:
        english, si, ta = districts.get(norm(district), (None, None, None))
        if si:
            # The curated spelling wins: GeoNames writes "Moneragala" where
            # every Sri Lankan writes "Monaragala".
            place["district"] = english
            place["districtSi"] = si
        if ta:
            place["districtTa"] = ta
    return place


def merge_sri_lanka(geo, curated, admin1, admin2, alternates):
    """Curated rows win; GeoNames fills the gaps.

    The 45 curated entries carry Sinhala and Tamil names that were checked by
    hand, and GeoNames only has Sinhala for about two thirds of Sri Lanka. So
    the curated name is authoritative wherever it exists, and GeoNames supplies
    the geonameid, the timezone and every town the curated list never had.
    """
    out = []
    used = set()
    for row in curated:
        match, best = None, MATCH_KM
        for c in geo:
            distance = haversine(row["lat"], row["lon"], float(c[4]), float(c[5]))
            if distance < best and norm(c[1])[:4] == norm(row["en"])[:4]:
                match, best = c, distance
        place = {
            "id": match[0] if match else "lk-%s" % slug(row["en"]),
            "en": row["en"],
            "si": row["si"],
            "ta": row["ta"],
            "lat": row["lat"],
            "lon": row["lon"],
            "district": row["district"],
            "timezone": match[17] if match else "Asia/Colombo",
        }
        if row.get("districtSi"):
            place["districtSi"] = row["districtSi"]
        if row.get("districtTa"):
            place["districtTa"] = row["districtTa"]
        if match:
            used.add(match[0])
        out.append(place)

    # Every district the curated list knows, so the towns GeoNames adds get the
    # same Sinhala and Tamil district under them as the towns beside them. A
    # Sinhala reader should not see half the list subtitled in English.
    districts = {}
    for row in curated:
        if row.get("districtSi") or row.get("districtTa"):
            districts[norm(row["district"])] = (row["district"],
                                                row.get("districtSi"),
                                                row.get("districtTa"))
    # GeoNames spells one district differently from everyone in Sri Lanka.
    if norm("Monaragala") in districts:
        districts[norm("Moneragala")] = districts[norm("Monaragala")]

    curated_names = set(norm(r["en"]) for r in curated)
    for c in geo:
        if c[0] in used or norm(c[1]) in curated_names:
            continue
        place = place_from_geonames(c, admin1, admin2, alternates,
                                    ("si", "ta"), districts)
        if "districtSi" not in place:
            # GeoNames has no admin2 for this town, so it fell back to the
            # province — accurate but coarser than every row beside it, and
            # untranslated. The nearest curated town knows the real district,
            # which is both more precise and already in three scripts. Bounded
            # tightly: beyond this, guessing is worse than showing the province.
            near, best = None, 25.0
            for row in curated:
                distance = haversine(float(c[4]), float(c[5]),
                                     row["lat"], row["lon"])
                if distance < best:
                    near, best = row, distance
            if near and near.get("districtSi"):
                place["district"] = near["district"]
                place["districtSi"] = near["districtSi"]
                place["districtTa"] = near["districtTa"]
        out.append(place)
    return out


# --------------------------------------------------------------------------
# emitting


def write_json(path, payload):
    with io.open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(json.dumps(payload, ensure_ascii=False,
                                separators=(",", ":"), sort_keys=False))
        handle.write(u"\n")
    return os.path.getsize(path)


def main():
    report_only = "--report" in sys.argv

    countries = load_countries()
    admin1 = load_admin("admin1CodesASCII.txt", 2)
    admin2 = load_admin("admin2Codes.txt", 3)
    cities = load_cities()
    alt = {cc: load_alternates(cc) for cc in LOCALISED}
    for cc, langs in LOCALISED.items():
        harvest_inline(cities.get(cc, []), alt[cc], langs)
    curated = load_curated()

    if not report_only:
        if not os.path.isdir(OUT):
            os.makedirs(OUT)
        # Clear only what this script generates. The directory also holds
        # README.md, which carries the CC BY attribution GeoNames requires —
        # wiping the directory wholesale would quietly delete the licence
        # notice on every rebuild.
        for stale in os.listdir(OUT):
            if stale.endswith(".json"):
                os.remove(os.path.join(OUT, stale))

    index = []
    total = 0
    for cc in sorted(cities):
        if cc not in countries:
            continue
        langs = LOCALISED.get(cc, ())
        if cc == "LK":
            places = merge_sri_lanka(cities[cc], curated, admin1, admin2, alt["LK"])
        else:
            places = [
                place_from_geonames(c, admin1, admin2, alt.get(cc, {}), langs,
                                    country=countries[cc])
                for c in cities[cc]
            ]
        places.sort(key=lambda p: (-1 if p["id"].startswith("lk-") else 0, p["en"]))

        entry = {"cc": cc, "en": countries[cc], "n": len(places)}
        entry.update(COUNTRY_NAMES.get(cc, {}))
        index.append(entry)

        if not report_only:
            total += write_json(os.path.join(OUT, "%s.json" % cc),
                                {"cc": cc, "places": places})

    index.sort(key=lambda e: e["en"])
    if not report_only:
        total += write_json(os.path.join(OUT, "index.json"), {"countries": index})

    print("countries: %d" % len(index))
    print("places:    %d" % sum(e["n"] for e in index))
    if not report_only:
        print("bundle:    %.2f MB across %d files" % (total / 1048576.0, len(index) + 1))
    for cc in sorted(LOCALISED):
        row = [e for e in index if e["cc"] == cc]
        if row:
            print("  %s: %d places" % (cc, row[0]["n"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
