# -*- coding: utf-8 -*-
"""Print the four subscription benefits, ready to paste into Play Console.

    python tool/print_subscription_benefits.py
    python tool/print_subscription_benefits.py --check

Play's subscription form takes **up to four** benefits, each **40 characters
or fewer**, per language. The same four go against `pro_monthly` and
`pro_yearly`: those tiers differ in billing period, not in what they give.

The strings come from the app's ARB files rather than being written again
here. What a buyer reads in the store and what they read on the paywall
should be the same sentence, and the only way to keep that true is to have
one source.

`paywallFeatureCompat` is the fifth bullet on the paywall and the one left
out. Play allows four, and it is the weakest claim of the five: Pro does open
the full porondam working, but so does watching one rewarded video, so it is
not something only subscribers have. The four below are gated by
`PaidFeature` and by nothing else.

Writes to a file rather than the terminal when redirected, because a Windows
console in cp1252 cannot print Sinhala or Tamil and raises rather than
mangling it.
"""
from __future__ import print_function

import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIMIT = 40

BENEFITS = [
    ("paywallFeatureNoAds", "removeAds"),
    ("paywallFeatureCharts", "divisionalCharts"),
    ("paywallFeatureDasha", "fullDashaTimeline"),
    ("paywallFeatureProfiles", "multipleProfiles"),
]

LOCALES = [("en", "en-US"), ("si", "si-LK"), ("ta", "ta-IN")]


def arb(lang):
    path = os.path.join(ROOT, "lib", "l10n", "app_%s.arb" % lang)
    with io.open(path, encoding="utf-8") as handle:
        return json.load(handle)


def main():
    check_only = "--check" in sys.argv
    strings = {short: arb(short) for short, _ in LOCALES}

    over = []
    out = []
    for short, locale in LOCALES:
        out.append("[%s]" % locale)
        for key, _ in BENEFITS:
            value = strings[short][key]
            if len(value) > LIMIT:
                over.append((locale, key, len(value)))
            out.append(value)
        out.append("")

    if check_only:
        print("%-26s %s" % ("benefit", "  ".join(l for _, l in LOCALES)))
        for key, feature in BENEFITS:
            lens = [len(strings[s][key]) for s, _ in LOCALES]
            print("%-26s %s   gates %s"
                  % (key, "  ".join("%5d" % n for n in lens), feature))
        print("")
        if over:
            for locale, key, n in over:
                print("OVER: %s %s is %d characters, limit %d"
                      % (locale, key, n, LIMIT))
            return 1
        print("all %d benefits are within %d characters in every language"
              % (len(BENEFITS), LIMIT))
        return 0

    # stdout on this machine is cp1252 and cannot carry these scripts.
    text = "\n".join(out)
    target = os.path.join(ROOT, "docs", "play-subscription-benefits.txt")
    with io.open(target, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
    print("wrote %s" % target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
