# Step 1: foundation (goal card)

**Goal:** cut what AID loads into every session from about 20k tokens to about 5k or less, keep every skill
runnable, and make the project's rules checkable.

**Out of scope:** what skills do (the lanes are steps 2 and 3); removing skills; push protection (it needs an
approval signal, step 3).

| # | Criterion | How it is checked |
|---|---|---|
| C1 | A plain request with AID costs at most 25% more context than without AID (today +85% for the fix, +140% for the feature) | `tests/measure/measure.py`, fix and feature, with and without AID |
| C2 | The rules file is loaded once: the project notes file imports it and no longer orders a second read | static check |
| C3 | The skill list costs about 4k tokens or less: about 10 entry skills keep descriptions of at most 300 characters, every other skill at most about 100; no skill is hidden, because hidden skills cannot be started by other skills (Q6) | static check |
| C4 | (merged into C3) | |
| C5 | `rules.md` is at most 60 lines, and every rule it drops is moved or justified in an inventory | static check; one review |
| C6 | A one-page project card (stack, build/test/lint commands, top rules) exists as a template, with this repo's own card, and is always loaded | static check |
| C7 | Moved to step 3 with push protection (Q7): master's installer has no hook support, and adding it is about 900 lines in two installer twins | — |

**Budget:** about one day of agent time; no per-task ceremony; one independent review of the whole change; the
measurement runs cost about $2.
