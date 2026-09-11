# Birth-place data

Generated. Do not edit these files by hand — run:

```
python tool/build_places.py
```

`index.json` lists the countries; `<CC>.json` holds one country's places.

## Attribution

Place names, coordinates, districts and timezones come from
[GeoNames](https://www.geonames.org/), used under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

The licence requires attribution, so it also appears in the app's licences
screen beside the Swiss Ephemeris notice — a line in a repository nobody
installs does not discharge the obligation.

The Sri Lankan entries additionally come from the hand-checked list that used
to live in `assets/data/sl_places.json`. Those Sinhala and Tamil names are
ours, not GeoNames'.

## What is in a place

| Key | Meaning |
|---|---|
| `id` | GeoNames id, or `lk-<slug>` for a curated town GeoNames does not carry |
| `en` | Name in English |
| `si`, `ta` | Name in Sinhala or Tamil — **present only where a real translation exists** |
| `lat`, `lon` | Degrees, 4 decimal places — about 10 m, far finer than an ascendant needs |
| `district` | GeoNames admin2, falling back to admin1 (state or province) |
| `timezone` | IANA zone |

The country code is written once at the top of each file and stamped onto each
place when it is read, rather than repeated on all 3,779 Indian rows.

`si` and `ta` are **absent**, not empty, where there is no translation. They are
never filled with the English name: that would record "the Sinhala for Chennai
is Chennai" as a fact, and no later release could tell it from a real
translation. The UI falls back to English at display time instead.

## The timezone is the reason this data exists

Every row carries an IANA zone. Before this, `Place.timezone` defaulted to
`Asia/Colombo`, which was correct while every place in the app was Sri Lankan
and catastrophic the moment one was not: a wrong zone moves a chart by hours,
which moves the lagna by whole signs, with nothing on screen to say so.

A row GeoNames has no zone for is dropped rather than guessed. A missing city
is a nuisance; a confidently wrong chart is the worst thing this app can do.

## Coverage and its limits

GeoNames' worldwide cut is population 15,000 and up. Sri Lanka keeps its
curated list on top of that, because GeoNames' Sri Lankan population figures
are municipal-council numbers and its 15,000 cut misses towns as large as
Gampaha, Polonnaruwa and Bandarawela.

Translations are partial and cannot be completed from this source:

| | Sinhala | Tamil |
|---|---|---|
| Sri Lanka | ~78% of rows | ~80% of rows |
| India | — | ~13% of rows, ~19% in Tamil Nadu |

That is GeoNames' own ceiling, not a filtering choice — the per-country
alternate-name files were checked and carry no more. The gap is filled by
falling back to English rather than by transliterating: a machine-generated
Tamil spelling of a town name is a proper noun rendered wrong, which is worse
for the reader trying to recognise their birthplace than the English they can
already read.
