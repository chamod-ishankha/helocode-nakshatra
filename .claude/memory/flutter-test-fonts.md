# A layout test lies until the real fonts are loaded

A widget test that asks **"does this fit?"** is meaningless in `flutter_test`
until the bundled fonts are loaded. The framework replaces every face with a
placeholder whose glyphs are all one em square — far wider than Noto.

It misleads in **both** directions: a genuine Tamil overflow passes, while
English cases fail on layouts that are perfectly fine on a phone. Those false
failures read exactly like real evidence.

**Load the bundled faces from `assets/fonts/` with `FontLoader`** — see
`test/support/fonts.dart`. Once loaded the numbers match the device: a card
that overflowed by 18px on the phone reports 20px in the test.

## The rules around it

- Call it from **`setUpAll`**, never a pump helper. `FontLoader` re-parses the
  file every call: six minutes instead of three seconds.
- Do **not** memoise it in a top-level `Future`. That future belongs to the
  test zone that created it, and awaiting it from the next test hangs the whole
  suite with "did not complete".
- Latin still renders in the placeholder, so English stays pessimistic. That is
  the safe direction for a *measuring* test — English is the short language.
- It is the **wrong** direction for anything that **exports** what it rendered.
  A PDF or screenshot written out of a test has every Latin letter as a solid
  black box. A KAN-37 sample went to the owner exactly like that, and he had to
  point it out. Use `loadLatinFont()` for anything leaving the machine as
  evidence.
- Registering a real face is **not enough**. An unset `fontFamily` resolves to
  the placeholder, which claims every glyph, so `fontFamilyFallback` is never
  consulted. Name the family explicitly.
- Load fonts **before anything renders**. `FontLoader` notifies every live
  render object that the system fonts changed, and tearing down a tree with one
  of those pending trips `!_hasPendingSystemFontsDidChangeCallBack` in
  `RenderObject.dispose` — on the *next* render, not at the load.

## Two other reasons l10n tests passed on visibly broken screens

Each sufficient on its own:

- **`Intl.defaultLocale` was never set.** `app.dart` sets it and
  `bootstrap.dart` calls `initializeDateFormatting()`; a test pumping
  `MaterialApp` directly does neither, so `DateFormat` falls back to `en_US`
  and every time on screen is measured at English width — in tests whose whole
  point is that Sinhala and Tamil are wider.
- **The viewport was too short.** At 360×720 the lower half of a scrolling
  screen is never laid out, so a card overflowing below the fold is invisible.
  Use a real width and a viewport tall enough to build the whole page.

## The wider lesson

Three bugs reached closed testing because the tests covered one screen and
nothing else. **Coverage was the gap, not assertion design.** Check what is
actually pumped before concluding that a test "couldn't have caught" something.
