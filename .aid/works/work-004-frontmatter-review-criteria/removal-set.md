# The removal set — derived from this branch's disk

**AC-3 requires this set to be derived, not inherited.** Every row below was found by walking
`tests/canonical/` and `canonical/aid/scripts/` on this branch and reading each candidate's own
header to answer one question: *is this script's job to check a fact stated in prose?* No row is
carried over from a prior work's inventory.

## Removed

| # | File | Lines | Its job | What covers it now |
|---|------|-------|---------|--------------------|
| 1 | `tests/canonical/check-skill-counts.mjs` | 379 | Repo-wide guard: derive the skill-count triple, then assert every stated skill count in `README.md`, `docs/`, `.aid/knowledge/`, `canonical/`, and the repo-local maintainer skills matches it | Split — see the coverage table below |
| 2 | `tests/canonical/test-skill-counts.sh` | 83 | Thin wrapper so `run-all.sh`'s `test-*.sh` glob discovers and runs the checker | Nothing to cover: it exists only to run row 1 |

**462 guard lines removed.** Deleting row 1 without row 2 would have left `run-all.sh` with an
orphaned suite invoking a missing file — the count-guard analogue of task-008's README-pointer
prep.

## The `check-skill-counts.mjs` disposition: FULL DELETE

The SPEC flagged this as an owner judgement call, defaulting to full delete, with a **narrow**
fallback — keep the checker for `docs/` and root `README.md` only — if the owner preferred an
ongoing mechanical count gate on those surfaces.

**Chosen: full delete.** And the reason is stronger than the SPEC knew: **the narrow fallback is
redundant.** `tests/canonical/test-doc-counts.sh` (109 lines, retained) already derives the
counts from `canonical/` and asserts them against exactly that surface — root `README.md`,
`docs/repository-structure.md`, `docs/aid-methodology.md`, and the profile READMEs. Keeping a
narrowed second checker over the same files would have added a duplicate oracle, which is what
**C-1** forbids and what this work exists to reduce. Verified: `test-doc-counts.sh` passes on
this branch.

## Coverage after the removal, part by part

Stated honestly, because the parts differ and a single verdict would hide that.

| Corpus part | Before | After | Verdict |
|---|---|---|---|
| Root `README.md`, `docs/`, profile READMEs | the deleted checker **and** `test-doc-counts.sh` | `test-doc-counts.sh` — same derivation, same assertions | **No drop.** The retained guard was always the one doing this work |
| Markdown under `canonical/` and `.aid/knowledge/` | the deleted checker | criterion **`G-01`** — no cosmetic count unless load-bearing and measured from disk at authoring time | **Mechanical to declared.** A reviewer applies `G-01`; nothing re-derives the number automatically. This is the trade **NFR-2** and **C-1** intend: fewer guard lines, the obligation moved onto the writer |
| `.claude/skills/<repo-local>/` — the `generate-profile` and `release-aid` maintainer skills | the deleted checker | nothing | **Genuine coverage drop.** Outside the criteria corpus (not one of the four in-scope trees) and outside `test-doc-counts.sh`'s scope. Stated rather than papered over |
| Non-markdown files — `.sh`, `.mjs`, `.js`, `.ts`, `.py`, `.yml`, `.yaml` | the deleted checker | nothing | **Genuine coverage drop.** `G-07` scopes the registry to in-scope **markdown**, so a skill count stated in a script or a YAML comment is now unguarded |

The two drops are real and are the price of the removal. Neither is invisible: both are recorded
here and in `tech-debt.md`'s `W1-11`, which previously cited the deleted checker as its
machine-derived closure evidence and now says the closure is only partial.

## Non-candidates, confirmed surviving

The SPEC names two scripts that look like candidates and are not. Both verified present:

| File | Why it is not a prose-fact check |
|------|----------------------------------|
| `canonical/aid/scripts/kb/kb-citation-lint.sh` | Checks citation **form** — that a cite is a durable anchor rather than a bare `file:LINE`. That is a shape rule about the citation itself, not a claim about the world that could drift |
| `tests/canonical/test-dogfood-byte-identity.sh` | Asks a **build** question: does the render output match its canonical source byte for byte? Nothing in prose asserts the answer |

## KB claims corrected

Three docs made a *current* claim about the deleted checker:

- **`module-map.md`** — two places: the `skill-counts.mjs` observation row (its guard column named
  the deleted wrapper) and a Conventions bullet describing the repo-wide comparison. Both now name
  `test-doc-counts.sh` and its real scope, and say that counts elsewhere are governed by `G-01`.
- **`test-landscape.md`** — named the deleted suite in its live-suite split. Rewritten to **name**
  the exception suites rather than count them, because the stated arithmetic (144 suites, 132
  long-standing, 12 exceptions) had already drifted from a tree holding 148 suites and 13 graph
  suites. That drift is precisely what `G-01` exists to stop, in the document describing the tests.
- **`tech-debt.md` `W1-11`** — cited the checker as its machine-derived closure evidence. Now
  states the closure is partial and names what each half rests on.

Two files are deliberately **not** edited:

- **`.aid/knowledge/STATE.md`** — its mentions sit in dated Q&A and Review History rows. They were
  true when written, and correcting a record of a moment falsifies it (FIX contract **F3**).
- **`.aid/knowledge/relationships.md`** — `source: generated`. Its rows for the deleted files drop
  out when task-015 regenerates it; hand-editing a render is the defect **F2** exists to prevent.
