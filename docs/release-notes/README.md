# Release notes

One file per version, named for the `version:` line in `pubspec.yaml` at the
time it shipped. Each file is the **"What's new"** text, already in Play's
multi-language tagged format:

```
<en-US>
…
</en-US>
<si-LK>
…
</si-LK>
<ta-IN>
…
</ta-IN>
```

Paste the whole file into **Play Console → Release → Production (or a test
track) → Release notes**, with "Copy from a previous release" off. The console
splits it by tag and fills every listing at once; typing them one language at a
time is where a listing ends up with English notes under a Sinhala listing.

The locale codes have to match the ones the store listing uses — `en-US`,
`si-LK`, `ta-IN`. A tag for a language the app is not listed in is rejected.

## The limit

**500 characters per language**, newlines included. Play truncates rather than
warning, and Sinhala reaches it sooner than the English reads: a single letter
with a vowel sign and a joiner is several characters to the counter and one
glyph to a reader.

Count before pasting:

```
python -c "import io,re,sys; t=io.open(sys.argv[1],encoding='utf-8').read(); [print('%-8s %3d' % (m.group(1), len(m.group(2)))) for m in re.finditer(r'<([a-z]{2}-[A-Z]{2})>\n(.*?)\n</\1>', t, re.S)]" docs/release-notes/1.0.1+3.txt
```

## What belongs in them

What a user would notice, in the words the app uses for it. Not ticket numbers,
not internal names, and not the fixes nobody saw break — a release note listing
things that were only ever broken in an unreleased build reads as an app that
ships badly.

Where a feature has a name in the app, use that name. The store and the app
should say the same words; the listing copy in
[play-listing.md](../play-listing.md) follows the same rule.
