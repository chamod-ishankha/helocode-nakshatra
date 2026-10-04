# What to test, and what not to

A standing instruction, given 2026-09-06:

> *"from here dont need to test with test files. i will test manually. only you
> have to do implementation correctly. but you need to do calculation test and
> logical test. because i dont understand this calculations"*

**Why:** the owner can look at a screen and tell instantly whether it is right.
They cannot look at a daśā date, a porondam verdict or a muhūrta score and tell
— and a wrong one looks exactly like a correct one. The tests go where their
own QA cannot reach.

## How to apply it

- **No widget test for behaviour they can see.** Build it correctly, put it on
  the device, and tell them what to look at.
- **Test calculations, tables and state logic thoroughly.** Anything
  astrological, anything with a sequence or a boundary, anything where a wrong
  answer is plausible rather than obviously broken.
- These tables are memorised lists in the tradition, so **assert their
  structure, not the list** — restating a list only proves a typo was copied
  twice. Assert nāḍī's 1-2-3-3-2-1 cycle, rajju's symmetry about the head, the
  13 vedha pairs covering 26 of 27, the 4-5-5-2-3-4-4 nakṣatra split.
- **Navigation and data-lifecycle logic is logic, not UI.** The deletion and
  back-button bugs both escaped because nothing tested them.
- **Verify against the real backend**, not by inspection, for anything touching
  Firestore or auth.
- **A migration gets its own test.** The failure mode is losing somebody's birth
  time, which they cannot be asked to type again.

## Rendering across three scripts is also out of their reach

Established by their own reasoning rather than a new instruction. They cannot
eyeball whether a Tamil screen is *fully* translated, or whether a Sinhala row
overflows on a phone they do not own. Six shipped bugs proved it: English
leaking into the chart, a Tamil settings row collapsing to one character per
line, an 18px overflow below the fold.

- Assert on **characters, not strings**. "No Latin letter is drawn" proves there
  is nothing left to find; `find.text('රාහු')` proves only the one string
  somebody thought of.
- Assert the **invariant, not the symptom** — all twelve label boxes inside the
  frame, not the one that overflowed today.
- The traps that make these tests lie are in
  [flutter-test-fonts.md](flutter-test-fonts.md). Read it first.

## Confirm the test can fail

**Break the code on purpose and watch the test fail**, one change at a time.
This is not ceremony — it has repeatedly caught tests that passed for the wrong
reason. One tapped a price below the fold, hit nothing, and passed even with
the behaviour it was guarding completely reversed.

Stashing a whole file removes more than the fix, and the test then passes for a
different wrong reason. Revert one thing.

## Some invariants are better checked in the source

Screens whose content comes from the ephemeris cannot be pumped at all. Where
the rule is structural — "a banner is the last thing on the page", "the paywall
lists no more benefits than the app gates" — read the source file and assert on
it. `gates_test.dart` and `banner_placement_test.dart` both do.

## Expect

The suite was at **795 tests** when the monetisation work landed, and runs in
about 30 seconds. `flutter analyze` is kept clean.
