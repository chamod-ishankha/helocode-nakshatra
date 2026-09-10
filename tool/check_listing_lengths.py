# -*- coding: utf-8 -*-
"""Check the Play listing copy against Play's field limits.

    python tool/check_listing_lengths.py

Reads the fenced blocks out of `docs/play-listing.md` and measures each one.
Exits non-zero if anything is over, so it can go in CI later.

## Why this is not done by eye

Play's counter is not a glyph counter. Sinhala builds a letter from a
consonant, a vowel sign and sometimes a zero-width joiner, and every one of
those is a separate character to the limit — so a Sinhala title that *looks*
half the length of the English one can be over while the English one is fine.
Getting it wrong is not a warning either: the console refuses to save the long
fields and silently truncates in some surfaces.

Counts are in Unicode code points, which is what Play documents. Nothing here
counts UTF-8 bytes; that would be a much harsher and wrong limit.

Prints ASCII only. The console this runs on is cp1252 and printing the copy
itself would raise UnicodeEncodeError after the check had already passed.
"""
from __future__ import print_function

import io
import os
import re
import sys

DOC = os.path.join(os.path.dirname(__file__), "..", "docs", "play-listing.md")

LIMITS = {
    "App name": 30,
    "Short description": 80,
    "Full description": 4000,
}

# "## English (en-US ...)" / "## Sinhala (si-LK)" / "## Tamil (ta-IN)"
LANGUAGE = re.compile(r"^## (English|Sinhala|Tamil)\b")
FIELD = re.compile(r"^\*\*(App name|Short description|Full description)\*\*")


def blocks(path):
    """Yields (language, field, text) for every fenced block under a heading."""
    with io.open(path, encoding="utf-8") as handle:
        lines = handle.read().split("\n")

    language = None
    field = None
    i = 0

    while i < len(lines):
        line = lines[i]

        found = LANGUAGE.match(line)
        if found:
            language = found.group(1)
            field = None

        found = FIELD.match(line)
        if found:
            field = found.group(1)

        if line.strip() == "```" and language and field:
            body = []
            i += 1
            while i < len(lines) and lines[i].strip() != "```":
                body.append(lines[i])
                i += 1
            yield language, field, "\n".join(body).strip()
            field = None

        i += 1


def main():
    if not os.path.exists(DOC):
        print("missing %s" % DOC)
        return 1

    seen = set()
    failures = []

    print("%-9s %-18s %6s %6s   %s" % ("LANG", "FIELD", "COUNT", "LIMIT", ""))
    for language, field, text in blocks(DOC):
        limit = LIMITS[field]
        count = len(text)
        over = count > limit
        seen.add((language, field))
        if over:
            failures.append((language, field, count, limit))

        print(
            "%-9s %-18s %6d %6d   %s"
            % (language, field, count, limit, "OVER" if over else "ok")
        )

    # A field that vanished from the doc must not pass by being absent.
    missing = [
        (lang, field)
        for lang in ("English", "Sinhala", "Tamil")
        for field in LIMITS
        if (lang, field) not in seen
    ]
    for lang, field in missing:
        print("MISSING  %s / %s" % (lang, field))

    if failures or missing:
        print("")
        for language, field, count, limit in failures:
            print(
                "%s %s is %d over the %d limit"
                % (language, field, count - limit, limit)
            )
        return 1

    print("\nall fields within Play's limits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
