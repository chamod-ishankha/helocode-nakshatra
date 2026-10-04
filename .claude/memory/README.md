# Project memory

What a Claude session needs to know about Nakshatra that the code does not say
for itself: decisions already settled, instructions the owner has given, and
traps that have already cost a day.

These moved out of one machine's private memory and into the repository on
2026-10-04 so every session reads the same thing.

## The files

| File | What it is for |
|---|---|
| [project.md](project.md) | What the app is, what was decided and why, where it stands |
| [release-status.md](release-status.md) | Live on Play since Oct 2026; what shipped, what is still open |
| [monetisation.md](monetisation.md) | The ad and purchase ladder as it actually runs |
| [astro-engine.md](astro-engine.md) | Moshier, Lahiri, whole-sign, IANA zones, and the AGPL |
| [firebase-spark.md](firebase-spark.md) | Free tier only — what that structurally rules out |
| [release-signing.md](release-signing.md) | Three keys, versionCode arithmetic, the gitignored files |
| [testing.md](testing.md) | What to test and what not to, by the owner's instruction |
| [flutter-test-fonts.md](flutter-test-fonts.md) | Why a layout test lies until the real fonts are loaded |
| [device-debugging.md](device-debugging.md) | adb and logcat gotchas on this project |
| [jira-workflow.md](jira-workflow.md) | Forward-only board, and when a bug deserves a ticket |

## How to use them

Read the index, then open only what the task touches. They are written to be
read by a person as much as by a model, so they argue rather than assert: when
one says "do not re-litigate this", the reason is in the same paragraph.

## Keeping them true

A memory that has gone stale is worse than no memory, because it is believed.
Two of these were describing closed testing and an inert purchase layer weeks
after both had changed.

- Update the file in the same commit as the change that dated it.
- Say when something was decided, so a reader can judge its age.
- Prefer deleting a claim to softening it.

## What is deliberately not here

Nothing secret, because this repository is public: no keys, no device
identifiers, no personal addresses. Those stay in the gitignored `env/*.json`,
`android/key.properties`, `android/admob.properties`, and in the owner's own
machine-level memory.
