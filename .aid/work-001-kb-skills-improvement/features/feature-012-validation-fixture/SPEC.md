# Validation Fixture

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-35) | /aid-interview |

## Source

- REQUIREMENTS.md §5.I (FR-35)
- REQUIREMENTS.md §1.2 (the 'Relative bus' miss — the original complaint), §1.4 (the honest limit), §2.1/§2.2 (P1, P2)
- §10 (Must)

## Description

This feature validates the whole overhaul against the **known failure case** and
guards against regression. It provides a **fixture project containing a planted
'Relative bus'-style coined concept** — a load-bearing native concept of exactly
the kind discovery silently missed before — and a regression test asserting the
method **captures and defines it**, proving the essence-capture gap is closed.

The fixture is also the substrate for the other validation ACs: the planted
calibration fixtures (transcription / hollowness / coverage-vs-source) that the
rubric must flag (f005), and the greenfield / brownfield-small / brownfield-large
fixtures the triage must classify and run to teach-back closure (f006). Together
with the deterministic closure self-containment check, this feature is the
CI-anchored proof that the method works and stays working.

## User Stories

- As an **AID maintainer**, I want a fixture with a planted 'Relative bus'-style
  concept and a regression test so that the original essence-capture failure is
  proven closed and cannot regress.
- As an **AID adopter (incl. AI-skeptic)**, I want the method validated against a
  known failure case in CI so that I can trust the overhaul actually works.
- As an **AID maintainer**, I want calibration and three-path fixtures so that
  f005's rubric and f006's triage have a deterministic test substrate.

## Priority

Must

## Acceptance Criteria

- [ ] Given a fixture project with a planted 'Relative bus'-style coined concept,
  when the method runs, then it captures and defines the concept, and a regression
  test guards it. *(FR-35, FR-12, AC2)*
- [ ] Given the KB produced for the fixture, when the self-containment check runs,
  then no project-specific term is left undefined (concept closure passes). *(AC3,
  with f004)*
- [ ] Given calibration and three-path fixtures, when f005's rubric and f006's
  triage run, then the fixtures exercise transcription/hollowness/coverage flagging
  (AC6) and correct path classification to teach-back closure (AC7). *(supports AC6,
  AC7)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — the fixtures
> and regression tests are deterministic and CI-able (the AC2/AC3/AC11 proof
> substrate). Provides fixtures consumed by f004, f005, and f006.

---

## Technical Specification

> Validation/harness feature — the **acceptance proof of the whole overhaul**. f012 owns
> NOTHING in the runtime: it ships **planted fixture corpora** + **regression test suites**
> that EXERCISE the scripts/mandates f004/f005/f006 build and ASSERT the ACs, plus it is the
> **executable calibration oracle** that pins the thresholds those features explicitly deferred
> here (f004's denylist/salience floor — `[SPIKE-H2]`; f005's CAL-N severity floors —
> `[SPIKE-C1]`; f006's recon thresholds — `[SPIKE-T1]`). "Components" here are markdown/code
> fixture trees under `tests/canonical/fixtures/` + new `tests/canonical/test-*.sh` suites
> (auto-discovered by `tests/run-all.sh`) — **not** application code, **not** the scripts
> themselves. Every claim is grounded against the files cited inline; genuine unknowns are
> flagged **[SPIKE]**, not guessed.
>
> **Boundaries (NOT built here — f012 EXERCISES, it does not RE-SPEC).** The
> `harvest-coined-terms.sh` / `coined-term-denylist.txt` / `closure-check.sh` scripts + the
> phrase-survival rule + the spine = **f004** (f012 *runs* them over fixtures). The
> five-mandate panel / teach-back exit / Calibration rubric / `kb-salient-coverage.sh` /
> `kb-teachback-questions.sh` = **f005** (f012 *runs* those scripts and *asserts* the
> mandate verdicts the rubric defines). The `recon-classify.sh` + `triage.*` thresholds =
> **f006** (f012 *runs* recon over path fixtures). The `sources:` frontmatter schema =
> **f001**; the concern/doc-set model = **f003**; AID's own KB migration = **f011**. f012
> owns ONLY: (a) the fixture corpus, (b) the AC1/AC2/AC6/AC7 regression tests, and (c) the
> threshold-calibration pinning of the f004/f005/f006 deferred defaults. f012 never edits a
> shipped script or a rubric — when a fixture proves a default is wrong, the **default is
> changed in the owning feature's file** and f012's test re-asserts; f012's tests are the
> oracle, not the patch.

### Overview

f012 is the **CI-anchored proof that the essence thesis holds and cannot regress**
(REQUIREMENTS §1.2 the 'Relative bus' miss, §1.10, FR-35, AC1/AC2/AC3/AC6/AC7). It is built
from two kinds of artifact, both under `tests/canonical/`:

1. **Fixture corpora** — small, deterministic, ASCII planted projects/KBs under
   `tests/canonical/fixtures/kb-essence/` that contain *exactly* the inputs the overhaul
   must handle: a 'Relative bus'-style coined cross-source concept (AC2), planted
   transcription/hollowness/coverage-gap docs (AC6), teach-back pass/fail KBs (AC1), and
   greenfield/brownfield-small/brownfield-large project shapes (AC7).
2. **Regression suites** — new `tests/canonical/test-*.sh` files (auto-discovered by
   `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob, line 33) that invoke the f004/f005/f006
   scripts against those fixtures and assert each AC, plus assert the calibrated thresholds
   hold (the fixtures *are* the regression oracle the defaults are tuned against).

The whole feature is **deterministic substrate** (REQUIREMENTS §1.6, NFR-3): no LLM, no
dispatch — every assertion runs a shipped bash script over a static fixture and checks the
output. The *judgment* halves of the ACs (does a reviewer flag a fat doc; does teach-back
narrate the engine) are LLM-mediated at runtime and are NOT mechanically testable in CI; f012
asserts the **mechanical substrate those judgments are anchored to** — the harvest surfaces
the concept, the coverage helper reports the gap, the closure oracle reports the undefined
term, recon classifies the shape — which is the deterministic floor REQUIREMENTS §1.6 commits
to (the irreducible "did it understand" judgment is anchored, not pretended away). This is
spelled out per-AC under [The Judgment Boundary](#the-judgment-boundary).

The fixtures are **HOME/scope-pinned** (every suite runs over its own `tests/canonical/fixtures/`
tree or a `mktemp -d` copy, never the real repo or `$HOME` — the AID test-isolation discipline,
mirroring `test-aid-migrate.sh`'s canary), so the harvest/recon scripts (which default their
root to the cwd/`$HOME`) cannot touch the developer's real repos.

### The Fixture Corpus

All fixtures live under a single new tree `tests/canonical/fixtures/kb-essence/` (sibling of
the existing `tests/canonical/fixtures/migrate/`), partitioned by AC. Every file is ASCII and
checked into git (deterministic — no generation step). The tree:

```
tests/canonical/fixtures/kb-essence/
  relative-bus/                 # AC2 — the planted coined cross-source PHRASE (a project tree)
    src/bus/relative.ts          # code channel: quoted string "Relative Bus" (E5) — the phrase, cross-source
    src/bus/handlers.ts          # code channel: "Relative Bus" quoted again (recurrence in code)
    docs/adr/0007-relative-bus.md# docs channel: "Relative Bus" / "Relative ME" prose + the why
    README.md                    # docs channel: "Relative Bus" named in the overview
    .gitlog.txt                  # history channel surrogate (see [SPIKE-V1]) — commit subjects naming Relative Bus
    expected/candidate-row.txt   # the asserted harvest row (Term=Relative Bus, spread>=2)
  closed-kb/                    # AC2(b)+AC3 — a CLOSED spine that DEFINES Relative Bus (closure passes)
    knowledge/domain-glossary.md # spine WITH a "Relative Bus" concept entry (definition-as-used-here)
    knowledge/architecture.md    # a doc that USES "Relative Bus" (term resolved by the spine)
    generated/candidate-concepts.md # the term universe closure-check.sh reads
  unclosed-kb/                  # AC3 negative — same KB but the spine OMITS Relative Bus (closure fails)
    knowledge/domain-glossary.md # spine WITHOUT the Relative Bus entry
    knowledge/architecture.md    # USES "Relative Bus" -> reported ungrounded
    generated/candidate-concepts.md
  calibration/                  # AC6 — the three planted calibration docs + the well-calibrated control
    knowledge/transcription-fat.md  # CAL-1: near-verbatim copy of its sources: file (too fat)
    knowledge/hollow-thin.md        # CAL-2: all "see file X" pointers, no synthesis (too thin)
    knowledge/coverage-gap.md       # CAL-3: a salient/load-bearing fact in sources: is absent
    knowledge/well-calibrated.md    # CONTROL: summary+pointer at the right altitude (must NOT flag)
    src/payment-engine.ts           # the sources: target the fat/coverage docs reference
    generated/candidate-concepts.md # the salient terms kb-salient-coverage.sh diffs against
  teachback/                    # AC1 — pass + fail KBs for the teach-back question-set
    pass-kb/knowledge/domain-glossary.md   # every cross-source candidate concept is DEFINED
    pass-kb/generated/candidate-concepts.md
    fail-kb/knowledge/domain-glossary.md   # a core candidate concept is UNDEFINED
    fail-kb/generated/candidate-concepts.md
  paths/                        # AC7 — three project shapes for recon-classify (f006)
    # Each project-index.md carries BOTH the "Language Breakdown" section (RM1/RM2) AND the
    # "Full File Inventory" section (RM3 dir count) per f006 SPEC L179-181 — see F4 below.
    greenfield/generated/project-index.md      # RM1<=5 src files, RM2<=500 LOC; Full File Inventory = few dirs
    greenfield/generated/candidate-concepts.md # near-empty (nothing to extract)
    brownfield-small/generated/project-index.md# source present, every dim (RM1/2/3/4) under large_min_*
    brownfield-small/generated/candidate-concepts.md
    brownfield-large/generated/project-index.md# RM2>=20000 LOC (LOC variant) | Full File Inventory >=25 dirs (dirs variant)
    brownfield-large/generated/candidate-concepts.md          # (concepts variant: Summary Cross-source >=40)
    settings.yml                               # shared fixture settings carrying the shipped triage.* defaults (see TEST-D --settings seam)
```

#### Fixture schema fidelity (the hand-authored files MUST match the scripts' parse contracts)

Every fixture is hand-authored (no harvest/index step produced them), so each MUST replicate
the exact emitted schema the consuming script parses, or the script reads nothing:

- **`candidate-concepts.md`** (every `generated/candidate-concepts.md`: closed-kb, unclosed-kb,
  calibration, teachback pass/fail, the three paths) MUST carry **f004's documented table schema**
  (f004 SPEC L275-289): a **`## Summary`** block with the **`Cross-source (spread >= 2)`** count
  row, and a **`## Ranked Candidates`** table with the `# | Term | Class | Freq | Spread |
  Channels | Salience | Example source` columns. This is load-bearing because (a) f005's
  `kb-teachback-questions.sh` extracts the `Term` rows whose `Spread >= 2` (f005 SPEC) — a fixture
  missing the `Spread` column or the `## Ranked Candidates` table yields an empty question set;
  (b) f004's `closure-check.sh` reads the term universe from the same table; and (c) f006's recon
  RM4 reads the `## Summary` `Cross-source (spread >= 2)` value — a fixture missing the Summary
  block makes RM4 parse 0. The fixtures therefore reproduce f004's emitted columns verbatim, not
  an ad-hoc shorthand.
- **`project-index.md`** (the three path fixtures) MUST carry both the **`Language Breakdown`**
  table (RM1/RM2) AND the **`Full File Inventory`** section (RM3) per f006 SPEC L179-181 — see F4.

#### F1 — The 'Relative bus' planted concept (AC2) — how it is faithfully planted

The fixture is a **faithful analogue of the caprica miss** (REQUIREMENTS §1.2): a load-bearing
native concept that is (a) a **phrase whose every word is common English** (`relative`, `bus`
are both in f004's denylist), (b) **project-coined as a unit** (the *phrase* is not generic),
and (c) **cross-source** — the **phrase** `"Relative Bus"` appears in code (a quoted string,
E5), in docs (an ADR + the README), in comments, and in commit history (the CamelCase
identifier `RelativeBus` may also be present, but f004's E2 split-and-keep is what emits the
`Relative Bus` *phrase* form from it — the phrase, not the joined token, is what survives). This is
the precise shape f004's `[SPIKE-H2]` phrase-survival rule must catch: the harvest "never asks
'is this *word* non-standard'; it asks 'is this *term* (word or phrase) non-standard,
recurring, and cross-source'" (f004 SPEC, Denylist filter). The fixture **plants the concept
so that:**

- the **load-bearing survival mechanism is f004's phrase-salience escape** (f004 SPEC
  L219-236), NOT a joined-token allowlist. f004 SPLITS every candidate into component words
  before the denylist check (CamelCase on humps, snake/kebab on separators, phrase on spaces)
  and a candidate survives **iff at least one component word is NOT in the denylist** — so the
  CamelCase identifier `RelativeBus` splits to `relative`+`bus`, BOTH of which are denylisted,
  and the joined token is **never evaluated as a unit**. f004's *only* escape for a term whose
  every component word is common is the **whole-phrase escape**: the multi-word phrase
  `"Relative Bus"` is retained as a unit when the phrase-as-a-unit is not in the denylist AND it
  clears the **phrase salience floor** (cross-source spread `>= 2`). The fixture therefore plants
  `"Relative Bus"` as a **recurring cross-source PHRASE** — a quoted string in code (E5), prose
  in the ADR/README/comments (E4) — so that the phrase clears the salience floor at spread `>= 2`
  and survives via f004's documented phrase-survival path. **This is the exact mechanism that
  closes the caprica 'Relative bus' miss, which was itself a coined *phrase*** (not a joined
  identifier). The CamelCase `RelativeBus` identifier MAY also be present in the source (it is
  what f004's E2 split-and-keep emits the `Relative Bus` form from), but it is **not** the
  asserted survival mechanism — f012 pins f004's actual phrase-salience escape, not a joined-token
  allowlist f004 never implements;
- the concept spread is `>= 2` distinct channels (code + docs at minimum; comments + history
  when those channels are populated), so it is **never truncated by `--top`** (f004 emits
  every spread `>= 3` candidate, and the teach-back question-set takes every emitted spread
  `>= 2` row — f005 SPEC).

The fixture's `expected/candidate-row.txt` records the asserted harvest output: the `Term`
`Relative Bus` with `Spread >= 2`. **[SPIKE-V1]** flags the one genuine unknown — how the
**history channel** is exercised deterministically (a fixture is a static dir, not a git repo;
f004's harvest reads `git log` and degrades to an empty history channel on a non-git tree). The
fixture therefore does NOT depend on git history to make the concept surface (code+docs alone
give spread `>= 2`); the `.gitlog.txt` surrogate is a `--history-file` input *if* f004's harvest
accepts a history-file arg (f004 `[SPIKE-H1]`), tested as a separate, optional assertion. The
**load-bearing AC2 assertion uses only the always-present code+docs channels** so it never
depends on the git/history-file seam.

#### F2 — The calibration docs (AC6)

Four docs that exercise f005's Calibration rubric (CAL-1..CAL-4) against
`kb-salient-coverage.sh`'s mechanical evidence:

- **`transcription-fat.md` (CAL-1 — too fat).** Its body is a near-verbatim restatement of
  `src/payment-engine.ts` (high lexical overlap, no added *why*/*how-it-relates*). Its
  `sources:` frontmatter declares that file (a **local readable file** — the only kind the
  offline helper scans; f005 SPEC: URL sources are N/A). The helper's **transcription-ratio
  hint** (lexical overlap between body and the `sources:` file) must read HIGH.
- **`hollow-thin.md` (CAL-2 — too thin).** Mostly "see `src/...`" pointers, no synthesized
  cross-cutting content. Its `sources:`/body ratio is the hollowness signal.
- **`coverage-gap.md` (CAL-3 — coverage-vs-source).** Declares `sources: src/payment-engine.ts`
  but **omits** a salient/load-bearing term that the source (and `candidate-concepts.md`)
  carries — "the source has Y and the doc forgot it." `kb-salient-coverage.sh` must report that
  salient term as **absent from the doc body** for this doc.
- **`well-calibrated.md` (CONTROL).** A summary+pointer doc at the right altitude — synthesizes
  the *why*, points to `sources:` for detail, covers the salient terms. The helper must report
  **no coverage gap and a LOW transcription ratio** — this is the **precision guard**: the
  calibrated severity floors (f005 `[SPIKE-C1]`) must NOT false-positive a good doc.

#### F3 — The teach-back pass/fail KBs (AC1)

Two minimal KBs, each with a `generated/candidate-concepts.md` (the term universe
`kb-teachback-questions.sh` derives the question set from — carrying f004's full table schema
per [Fixture schema fidelity](#fixture-schema-fidelity-the-hand-authored-files-must-match-the-scripts-parse-contracts),
so the `Spread >= 2` `Term` filter has its columns to read) and a `knowledge/domain-glossary.md`
spine:

- **`pass-kb`** — every cross-source candidate concept (every emitted spread `>= 2` `Term`) has
  a **definition-as-used-here** concept entry in the spine. The question set generated from
  `candidate-concepts.md` is fully answerable from the KB alone (teach-back PASS shape).
- **`fail-kb`** — identical candidate list, but the spine **omits the definition of one core
  concept** (it is named/used but never defined). The question set contains a "what is X?" the
  KB cannot answer → teach-back FAIL shape.

f012 mechanically asserts the **question-set substrate**: `kb-teachback-questions.sh` over each
fixture's `candidate-concepts.md` emits the same fixed question set (deterministic), and a
**self-containment check** (`closure-check.sh`) over each KB reports the pass-KB as closed
(zero ungrounded) and the fail-KB as having the one undefined concept. The *reviewer's binary
verdict* (does the LLM teach-back reviewer self-score PASS/FAIL) is the judgment half — see
[The Judgment Boundary](#the-judgment-boundary).

#### F4 — The three path fixtures (AC7)

Three `generated/` directories holding the two markdown tables `recon-classify.sh` reads
(`project-index.md` + `candidate-concepts.md`) — **not** real source trees, because f006's
recon "does NOT re-scan the tree" (f006 SPEC: it aggregates the already-emitted index +
candidates). This is the lightweight, deterministic way to drive the classifier.

**Each `project-index.md` fixture MUST populate BOTH sections recon parses (f006 SPEC
L179-181), not only Language Breakdown:** (a) the **Language Breakdown** table (RM1 source-file
count + RM2 source LOC, summed over `is_source` rows) AND (b) the **Full File Inventory**
section (RM3 — the count of distinct top-2-level directory prefixes over `is_source` files).
RM4 (concept count) comes from the sibling `candidate-concepts.md` Summary block. A fixture that
omits the Full File Inventory section gives RM3 nothing to parse, so the **dirs variant of
brownfield-large (V-D4) would silently never trip `large_min_dirs`** — the section is therefore
required, with the dir structure each fixture's RM3 must yield planted in it explicitly.

- **`greenfield/`** — Language Breakdown sums to `<= greenfield_max_source_files` source files
  AND `<= greenfield_max_source_loc` LOC; Full File Inventory holds only a few `is_source` dir
  prefixes; near-empty candidate list. Must classify **greenfield**.
- **`brownfield-small/`** — source present, but every dimension under `large_min_*`: RM2 LOC
  (Language Breakdown), RM3 dir count (Full File Inventory `< large_min_dirs`), RM4 concepts
  (Summary). Must classify **brownfield-small**.
- **`brownfield-large/`** — at least one large dimension trips: **LOC variant** (RM2 `>=
  large_min_source_loc`, via Language Breakdown), **dirs variant** (RM3 `>= large_min_dirs`,
  via a Full File Inventory carrying `>= large_min_dirs` distinct top-2-level `is_source` dir
  prefixes), OR **concepts variant** (RM4 `>= large_min_concepts`, via the candidate Summary's
  `Cross-source (spread >= 2)` count). Three variants — one per large dimension — so each
  OR-branch of f006's classifier is independently exercised. Must classify **brownfield-large**.

These are the AC7 path-classification oracle and the f006 `[SPIKE-T1]` threshold-calibration
substrate (below). The **end-to-end "each path reaches teach-back closure"** half of AC7 is a
judgment/orchestration outcome (it runs the whole GENERATE method with LLM dispatch); f012
mechanically asserts only the **path-classification** half (recon proposes the right path) —
the closure-reached half is the judgment boundary.

### The Regression Tests

Four new canonical suites, one per AC family, all auto-discovered by `tests/run-all.sh` (the
`tests/canonical/test-*.sh` glob), all following the `test-doc-set-mapping.sh` pattern (`set -u`,
`source ../lib/assert.sh`, numbered `T01..` mechanical assertions, `mktemp -d` scratch,
`trap ... EXIT` cleanup, `test_summary` + `exit $?`).

#### TEST-A — AC2 essence-capture regression (`test-essence-capture.sh`)

The **proof the 'Relative bus' gap is closed + the regression guard.** It invokes f004's
shipped scripts over the `relative-bus/` and `closed-kb/`/`unclosed-kb/` fixtures:

| # | Asserts | How (deterministic) |
|---|---------|---------------------|
| V-A1 | **Harvest surfaces the concept.** `Relative Bus` appears in `candidate-concepts.md` with **spread `>= 2`** when `harvest-coined-terms.sh` runs over `relative-bus/`. | Run f004's harvest with `--root <fixture>` (`mktemp -d` copy), grep the `Term` column for `Relative Bus`, parse the `Spread` column `>= 2`. This is the **mechanical half of AC2** (f004 T09 asserts presence in top rows; V-A1 asserts the spread `>= 2` cross-source guarantee). |
| V-A2 | **The common-word phrase survives via f004's phrase-salience escape.** `Relative Bus` (a multi-word phrase whose every component word — `relative`, `bus` — IS denylisted) is in the candidate list **because the phrase-as-a-unit clears the phrase salience floor at spread `>= 2`** (f004 SPEC L219-236: split-then-check drops the joined token; the whole-phrase escape retains the recurring cross-source phrase). This is f004's documented escape, NOT a joined-token allowlist. | grep the `Term` column for `Relative Bus`; assert the row is present and its `Spread >= 2` (the phrase-floor survival condition). |
| V-A3 | **The common-word phrase is not buried.** `Relative Bus` ranks within the emitted rows (it clears the phrase salience floor) — the precision assertion: it is not lost under incidental **capitalized** single-channel phrase noise (the E4 class, e.g. `The System`/`This File`). | assert the `Relative Bus` row is present (emitted), and — the calibration assertion — that the phrase floor is set so it survives while the single-channel capitalized noise stays below the candidate-count cap (see Threshold Calibration / CAL-floor). |
| V-A4 | **After closure, the concept is DEFINED (closure passes).** `closure-check.sh` over `closed-kb/` (spine defines Relative Bus) reports **zero ungrounded terms**. This is the AC2(b) "captures *and defines* it" + the AC3 self-containment proof. | Run f004's `closure-check.sh` with the closed-kb spine + candidates + KB docs; assert empty ungrounded set. |
| V-A5 | **Regression guard (the negative).** `closure-check.sh` over `unclosed-kb/` (spine OMITS Relative Bus, a doc USES it) **reports `Relative Bus` as ungrounded.** This is what fails if a future change lets the concept be dropped — the guard. | Same script, unclosed-kb fixture; assert `Relative Bus` is in the reported ungrounded set. |
| V-A6 | **Determinism.** Re-running the harvest over the fixture is **byte-identical** (NFR-3). | Run harvest twice, `diff` the two outputs, assert identical. |

V-A1 + V-A4 together are the literal FR-35/AC2 bar: the method **captures** (harvest surfaces
it, spread `>= 2`) **and defines** (closure passes once the spine grounds it); V-A5 is the
**regression guard** (the concept cannot silently fall out — closure reports it the moment a
doc uses it undefined).

#### TEST-B — AC6 calibration regression (`test-calibration-fixtures.sh`)

Invokes f005's `kb-salient-coverage.sh` over the `calibration/` fixture:

| # | Asserts | How |
|---|---------|-----|
| V-B1 | **CAL-3 coverage gap flagged.** The helper reports the planted salient term as **absent from `coverage-gap.md`**. | Run `kb-salient-coverage.sh` over the calibration fixture; assert the coverage-gap doc + the omitted salient term appear in the "absent from doc body" output. |
| V-B2 | **CAL-1 transcription flagged.** The helper's **transcription-ratio hint** for `transcription-fat.md` (vs its `sources:` file) reads HIGH (above the calibrated floor). | Parse the transcription-ratio output for the fat doc; assert ratio `>=` the CAL-1 floor. |
| V-B3 | **CAL-2 hollowness signal.** The hollow doc's pointers-vs-synthesis ratio reads thin (the CAL-2 evidence the reviewer grades against). | Parse the hollowness signal for the thin doc; assert below the synthesis floor. |
| V-B4 | **Precision: the control is clean.** `well-calibrated.md` produces **no coverage gap** and a **LOW transcription ratio** — the calibrated floors do NOT false-positive a good doc. | Assert the control doc is absent from the gap output and its ratio is below the CAL-1 floor. |
| V-B5 | **Determinism.** Re-run byte-identical. | `diff` two runs. |

These assert the **mechanical evidence** the Calibration reviewer (M5) grades against (f005
SPEC: "the reviewer grades against this list, it does not recall from memory"). The
*reviewer's MEDIUM/HIGH verdict* is the judgment half — but f012 pins the **severity floors**
the verdict uses (Threshold Calibration, below). AC6's "the rubric flags transcription /
hollowness / coverage-vs-source" is realized mechanically as "the evidence helper emits the
signal at/above the calibrated floor for the planted docs and below it for the control."

#### TEST-C — AC1 teach-back regression (`test-teachback-fixtures.sh`)

Invokes f005's `kb-teachback-questions.sh` + f004's `closure-check.sh` over `teachback/`:

| # | Asserts | How |
|---|---------|-----|
| V-C1 | **Question-set generation is deterministic + correct.** `kb-teachback-questions.sh` over `pass-kb/generated/candidate-concepts.md` emits a "what is X?" for every emitted spread `>= 2` `Term` + the one fixed engine question. | Run the generator; assert each planted cross-source term yields a question and the engine question is present; re-run byte-identical. |
| V-C2 | **Teach-back PASS substrate.** `closure-check.sh` over `pass-kb` reports **zero ungrounded** — every concept the question set asks about is defined in the spine (the KB *can* answer every question). | Run closure-check; assert empty. |
| V-C3 | **Teach-back FAIL substrate.** `closure-check.sh` over `fail-kb` reports the **one undefined core concept** — the KB *cannot* answer that "what is X?" (the FAIL shape). | Run closure-check; assert the omitted concept is in the ungrounded set. |
| V-C4 | **The fail-KB's missing concept is a question-set member.** The undefined concept in `fail-kb` is one the question generator asks about (so the FAIL is on a *required* question, not a noise term). | Cross-check: the V-C3 ungrounded term appears in the V-C1 question set. |

V-C2/V-C3 are the **mechanically-assertable half** of the teach-back verdict: a KB whose spine
grounds every question-set concept is closed (PASS-able); a KB missing one is not (FAIL). The
*reviewer's clean-context narration self-score* (f005 M4) is the judgment half — f012 proves
the substrate that makes PASS reachable and FAIL detectable.

#### TEST-D — AC7 path-classification regression (`test-path-fixtures.sh`)

Invokes f006's `recon-classify.sh` over the `paths/` fixtures (this overlaps f006's own
`test-recon-classify.sh`; f012 owns the **fixtures**, f006's suite asserts the classifier
mechanics — see Boundaries / [SPIKE-V3]):

| # | Asserts | How |
|---|---------|-----|
| V-D1 | greenfield fixture → recon proposes **greenfield**. | Run `recon-classify.sh --index <fx>/project-index.md --candidates <fx>/candidate-concepts.md --settings paths/settings.yml`; grep proposed path. (`--settings` resolves to the checked-in fixture settings carrying the shipped `triage.*` defaults — see the TEST-D `--settings` seam below.) |
| V-D2 | brownfield-small fixture → **brownfield-small**. | same |
| V-D3 | brownfield-large (LOC variant) → **brownfield-large**. | same |
| V-D4 | brownfield-large (dirs variant) → **brownfield-large** (independent OR-branch). | same |
| V-D5 | brownfield-large (concepts variant) → **brownfield-large** (RM4 OR-branch — the "small but conceptually dense" case). | same |
| V-D6 | **Determinism.** Re-run byte-identical. | `diff` two runs. |
| V-D7 | **Shipped-defaults parity.** The fixture `paths/settings.yml` `triage.*` values are byte-identical to the shipped `canonical/aid/templates/settings.yml` `triage.*` block — so V-D1..V-D5 pin the SHIPPED defaults, not a drifted fixture copy. | grep the `triage.*` keys/values out of both files; assert identical. |

These are the AC7 path-classification oracle. The "each path reaches teach-back closure" half
is the judgment boundary.

**The `--settings` seam (how the "shipped-defaults pin" stays isolation-clean and enforceable).**
f006's `recon-classify.sh` REQUIRES `--settings <path>` (f006 SPEC L160-164), but the isolated
`mktemp -d`/HOME-pinned fixture has no `.aid/settings.yml`, and pointing `--settings` at the
repo's live `.aid/settings.yml` would re-introduce a real-repo read (violating the Isolation
Discipline) and couple the pin to mutable live settings. f012 therefore ships a **checked-in
fixture `tests/canonical/fixtures/kb-essence/paths/settings.yml`** carrying ONLY the `triage.*`
block with the **shipped default values** (the same values f006 seeds into
`canonical/aid/templates/settings.yml`). TEST-D always passes `--settings paths/settings.yml`
(copied into the `mktemp` scratch alongside the fixture); no test ever reads the live repo
settings. To keep the fixture from silently drifting from the shipped defaults (which would
defeat the "pinned to shipped defaults" guarantee), TEST-D adds **V-D7 — a defaults-parity
assertion**: it greps the `triage.*` values out of `paths/settings.yml` and out of the shipped
`canonical/aid/templates/settings.yml` and asserts they are **byte-identical**. So the pin is on
the *shipped* defaults (V-D7 keeps the fixture honest), while the classifier runs fully isolated
(V-D1..V-D5 read only the fixture settings). This makes the V-D1..V-D5 "under shipped defaults"
oracle actually enforceable.

### Threshold Calibration (the fixtures ARE the oracle)

This is f012's load-bearing responsibility beyond the regression tests: the planted fixtures
are the **executable acceptance test** against which the three deferred default sets are tuned.
The contract is **the default lives in the owning feature's file; f012's test pins it.** When a
fixture proves a default wrong, the number is changed in f004/f005/f006's shipped file and
f012's test re-asserts the corrected behavior — f012 is the oracle, never the patch site.

| Deferred default | Owner / spike | The f012 fixture that pins it | The assertion (the pin) |
|---|---|---|---|
| **Denylist size + phrase salience floor** (the all-common-word-phrase survival rule) | f004 `[SPIKE-H2]` | `relative-bus/` (recall) + the `calibration/` control + a **noise floor** in the relative-bus fixture | **Recall:** V-A1/V-A2/V-A3 — the cross-source PHRASE `Relative Bus` MUST survive via f004's phrase-salience escape (spread `>= 2` phrase floor catches it; the joined identifier never survives as a unit). **Precision:** the phrase floor MUST be high enough that the fixture's incidental **capitalized** common-word phrases (e.g. `The System`, `This File` — the E4-extracted class, runs of `[A-Z][a-z]+` words, NOT lowercase pairs which E4 never extracts) that appear in only ONE channel do NOT flood the candidate list — asserted by a cap on the candidate count for the small fixture (the planted concept ranks above the single-channel incidental noise). The phrase salience floor default (spread `>= 2`) is **pinned by these two assertions**: lower it and the single-channel `The System` noise leaks (precision breaks); raise it and recall breaks on the 2-channel `Relative Bus`. |
| **CAL-N severity floors** (transcription-ratio threshold; MEDIUM-vs-HIGH cut) | f005 `[SPIKE-C1]` | `calibration/` (the 3 planted docs + the control) | V-B2 — `transcription-fat.md` ratio `>=` CAL-1 floor (flag the fat doc); V-B4 — `well-calibrated.md` ratio `<` CAL-1 floor (do NOT flag the good doc). The **transcription-ratio floor default** is pinned to the value that separates the planted fat doc from the control. V-B1/V-B3 pin the coverage/hollowness signals analogously. |
| **Recon path thresholds** (`greenfield_max_source_files`/`_loc`, `large_min_source_loc`/`_dirs`/`_concepts`) | f006 `[SPIKE-T1]` | `paths/` (greenfield / brownfield-small / brownfield-large×3) | V-D1..V-D5 — each fixture MUST classify to its intended path under the **shipped `settings.yml` defaults**. The five `triage.*` defaults are pinned to the values that classify all three shapes correctly: the greenfield fixture sits below the greenfield ceilings, the small fixture between the ceilings and the large floors, each large variant trips exactly one large floor. |

**How the calibration loop works in practice (and stays in-bounds).** During implementation,
f012's tests run against the *current* f004/f005/f006 defaults; where a planted fixture
mis-classifies (e.g. the phrase floor buries `Relative Bus`, or a `triage.*` default
mis-bins a path fixture), the **owning feature's default is adjusted** (the denylist file, the
rubric's CAL-1 floor constant, the `settings.yml` `triage.*` value) and f012's test goes
green. The fixtures are committed as the **permanent regression oracle**: any later change to a
default that breaks a planted case reds f012 in CI. This is the precise meaning of "the
fixtures are the regression oracle the defaults are tuned against" — f012 does not *hold* the
defaults, it *constrains* them, and CI enforces the constraint forever.

> **[SPIKE-V2] — the exact floor VALUES are the spike, not the mechanism.** f012 owns *that*
> the fixtures pin the floors and *which* assertion pins each; the concrete numeric value of
> the transcription-ratio floor (V-B2/V-B4) and the precise phrase-salience floor (V-A3) are
> determined **empirically during implementation** by running the helpers over the planted +
> control fixtures and choosing the value that cleanly separates flag-from-control. They are
> recorded as the pinned defaults in the owning features' files; f012's tests assert the
> separation, not a guessed constant. This is flagged so the implementer measures rather than
> invents the floors.

### The Judgment Boundary

f012 is honest about what CI can and cannot prove (REQUIREMENTS §1.6 honest floor; NFR-3). For
each AC, the **mechanical substrate** is asserted in f012's suites; the **irreducible LLM
judgment** is exercised at runtime (a real `/aid-discover` run with dispatch) and is NOT a CI
assertion — but it is *anchored* to the substrate f012 pins, so the judgment runs on a fixed,
proven input:

| AC | Mechanical half (f012 asserts in CI) | Judgment half (runtime, anchored, NOT a CI assert) |
|---|---|---|
| AC2 | harvest surfaces `Relative Bus` (V-A1); closure reports it grounded/ungrounded (V-A4/V-A5) | a researcher writes the definition-as-used-here into the spine |
| AC6 | coverage/transcription/hollowness signals at/above floor for planted, below for control (V-B1..B4) | the Calibration reviewer (M5) emits the `[CAL-*]` severity verdict |
| AC1 | question set generated deterministically (V-C1); closure pass/fail substrate (V-C2/V-C3) | the clean-context teach-back reviewer (M4) self-scores PASS/FAIL |
| AC7 | recon proposes the right path per fixture (V-D1..V-D5) | the path runs the full method to teach-back closure |

This boundary is the design honesty REQUIREMENTS §1.6 demands: f012 maximizes the deterministic
substrate (the entire harvest/coverage/closure/recon layer is scripted + CI-asserted) and
**anchors** — does not pretend to mechanically grade — the residual synthesis judgment.

### Isolation Discipline (HOME/scope-pinned — the AID test contract)

The hazard: f004's `harvest-coined-terms.sh` and f006's `recon-classify.sh` default their
`--root`/scan to the cwd, and the AID migration scan defaults to `$HOME` — a fixture suite that
fired them carelessly could scan the developer's real repo or `$HOME` (the
[[aid-scan-tests-must-pin-home]] hazard that bit d011 three times). f012's suites therefore:

- **Always pass an explicit `--root`/`--index`/`--candidates`/`--settings`** pointing at the
  fixture tree (a `mktemp -d` copy of `tests/canonical/fixtures/kb-essence/<case>/`), **never**
  relying on a cwd/`$HOME` default and **never** pointing `--settings` at the live repo's
  `.aid/settings.yml` — TEST-D's `--settings` resolves to the checked-in
  `paths/settings.yml` fixture (shipped `triage.*` defaults, parity-guarded by V-D7), so recon
  reads no real-repo file. No suite runs a script with a defaulted root or live settings.
- **Pin `HOME` to a throwaway dir** (`export HOME="${TMP}/fakehome"`) before any script run, and
  carry the **`_CANARY_BEFORE`/`_CANARY_AFTER` real-HOME `.aid` snapshot** from
  `test-aid-migrate.sh` (lines 58-64, 1567-1574) — `ISO-CANARY` asserts the real `$HOME` gained
  no `.aid` dir, so no scan escaped the throwaway. The canary snapshots *before* (it must not
  assume an empty real HOME — under CI the repo checkout lives under `$HOME`, per
  [[ci-runs-as-root-repo-under-home]]).
- **Use `mktemp -d` scratch + `trap ... EXIT` cleanup** for any fixture the harvest writes into
  (the harvest emits `candidate-concepts.md`); the checked-in fixture trees are read-only
  inputs, copied into scratch before any write — so a test run never mutates the committed
  fixture.
- **Never invoke a script with the repo root as `--root`** — that would harvest AID's own tree
  (slow, non-deterministic across branches) and defeat the fixture isolation.

This is the same isolation contract `test-aid-migrate.sh` enforces; f012 reuses its canary
verbatim so the fixtures can never touch the real repo or `$HOME`.

### Affected Components

| Component | Path | Change |
|-----------|------|--------|
| **NEW fixture corpus** | `tests/canonical/fixtures/kb-essence/{relative-bus,closed-kb,unclosed-kb,calibration,teachback,paths}/` | The planted fixtures (F1-F4): the 'Relative bus' cross-source concept + closed/unclosed spines; the 4 calibration docs + control; the teach-back pass/fail KBs; the 3 path-shape index+candidate tables (each `project-index.md` carrying BOTH Language Breakdown and Full File Inventory) + the `paths/settings.yml` shipped-`triage.*`-defaults fixture. All ASCII, checked-in, deterministic. |
| **NEW** AC2 suite | `tests/canonical/test-essence-capture.sh` | V-A1..V-A6 — runs f004's `harvest-coined-terms.sh` + `closure-check.sh` over the relative-bus / closed-kb / unclosed-kb fixtures; asserts capture (spread `>= 2`) + define (closure passes) + the regression guard (unclosed reports the concept) + determinism. HOME-pinned, canary, `mktemp` scratch. |
| **NEW** AC6 suite | `tests/canonical/test-calibration-fixtures.sh` | V-B1..V-B5 — runs f005's `kb-salient-coverage.sh` over the calibration fixture; asserts coverage-gap/transcription/hollowness signals fire for planted docs and NOT for the control; determinism. |
| **NEW** AC1 suite | `tests/canonical/test-teachback-fixtures.sh` | V-C1..V-C4 — runs f005's `kb-teachback-questions.sh` + f004's `closure-check.sh` over the teach-back pass/fail KBs; asserts deterministic question-set + closure PASS/FAIL substrate. |
| **NEW** AC7 suite | `tests/canonical/test-path-fixtures.sh` | V-D1..V-D7 — runs f006's `recon-classify.sh` over the 3 path fixtures (with the checked-in `paths/settings.yml`); asserts correct path proposal per shape + determinism + shipped-defaults parity (V-D7). |
| run-all auto-discovery | `tests/run-all.sh` | **No edit** — the four new `test-*.sh` are picked up by the existing `tests/canonical/test-*.sh` glob (line 33). |
| ascii-only guard | `tests/canonical/test-ascii-only.sh` | **No edit needed** for the test scripts (they are tests, not shipped `SHIPPED_SCRIPTS`); the *fixtures* are ASCII by construction. (f004/f005/f006 add their own scripts to the allow-list.) **[SPIKE-V4]** — confirm fixture markdown under `tests/canonical/fixtures/` is not swept by `test-ascii-only.sh`; if it is, the fixtures (intentionally ASCII) pass anyway. |
| render-drift | `test.yml` job `render-drift` | **No edit** — fixtures + tests live under `tests/`, NOT `canonical/`, so they are not render-pipeline inputs (no `run_generator.py` involvement). f012 ships zero canonical-tree files. |

### Constraints

- **C5 / NFR-3 — deterministic, CI-testable.** Every f012 assertion runs a shipped script over
  a static fixture and checks the output; every suite asserts re-run byte-identity (V-A6/V-B5/
  V-C1/V-D6). No LLM, no dispatch, no network — pure script-over-fixture, the canonical
  helper-suite pattern (`test-doc-set-mapping.sh`).
- **C2 — ASCII-only.** All fixtures + test scripts are ASCII. The test scripts are not
  `SHIPPED_SCRIPTS` (they do not vendor into install bundles), so they are not on the
  `test-ascii-only.sh` allow-list, but they are kept ASCII for sibling consistency; the fixture
  content is ASCII by construction (the 'Relative bus' analogue is plain ASCII).
- **C1 / NFR-8 — no new runtime.** f012 adds **no new script and no runtime dependency** — it
  only invokes the f004/f005/f006 scripts (pure coreutils) and `tests/lib/assert.sh`. Zero new
  binaries.
- **C3 / NFR-4 — render-drift green / no canonical edits.** f012 ships **nothing under
  `canonical/`** — fixtures + tests are `tests/`-only, outside the render pipeline. render-drift
  is untouched (no `run_generator.py` run needed for f012's own files).
- **Test isolation (the load-bearing constraint).** HOME-pinned, real-HOME `.aid` canary,
  explicit `--root` always, `mktemp` scratch, never the repo root — the
  [[aid-scan-tests-must-pin-home]] + [[ci-runs-as-root-repo-under-home]] discipline, reused
  from `test-aid-migrate.sh`.
- **C6 — content-isolation.** Fixtures live under the existing isolated `tests/canonical/fixtures/`
  tree (sibling of `migrate/`); they never write outside their `mktemp` scratch.

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-V1] — faithful 'Relative bus' planting + the history channel.** The genuine design
  question: make the planted concept a faithful analogue of the caprica miss
  (common-word phrase × project-coined × cross-source) **without depending on a non-deterministic
  channel**. RESOLVED for the load-bearing assertion: the concept surfaces from the
  **always-present code + docs channels** (spread `>= 2`), so AC2 never depends on git history.
  The **history channel** is exercised only as an *optional* assertion via f004's
  `--history-file` arg (a checked-in `.gitlog.txt` surrogate) — gated on f004 `[SPIKE-H1]`'s
  history-file contract landing; if f004 does not expose `--history-file`, the history assertion
  is dropped and the code+docs spread `>= 2` carries AC2. **PLAN sequencing:** PLAN.md MUST
  sequence f004's `[SPIKE-H1]` resolution (does `--history-file` ship?) **before** f012's optional
  history-channel assertion is authored — otherwise that optional assertion is silently dead
  (authored against a flag that never landed). The load-bearing AC2 assertion (code+docs only)
  has no such dependency and proceeds regardless.
- **[SPIKE-V2] — empirical floor values.** The exact transcription-ratio floor (V-B2/V-B4) and
  phrase-salience floor (V-A3) numbers are **measured during implementation** (run the helpers
  over planted + control, pick the separating value), not guessed; recorded as the owning
  features' pinned defaults. f012 asserts the separation, not a constant.
- **[SPIKE-V3 — boundary, fixture ownership vs f004/f005/f006 own suites.]** f004/f005/f006 each
  ship a *small in-suite* fixture for their unit assertions (f004 T09 plants a 'Relative bus'
  phrase in its own suite; f006 has path fixtures in `test-recon-classify.sh`). f012 owns the
  **shared, end-to-end fixture corpus** under `tests/canonical/fixtures/kb-essence/` that the
  *acceptance* (AC2/AC6/AC1/AC7) regression tests run over. Confirm with PLAN.md that f004/f005/
  f006's in-suite fixtures and f012's corpus do not duplicate/diverge — ideally f004/f005/f006's
  unit fixtures and f012's corpus are the **same files** (f012's corpus is the single source;
  the feature suites point at it), so a single 'Relative bus' fixture serves both the unit and
  acceptance layers and cannot drift. f012 sequences **after** f004/f005/f006 (consume-after-
  define: f012 runs their shipped scripts), per the §10 Must ordering.
- **[SPIKE-V4 — boundary, ascii-only sweep scope.]** Confirm whether `test-ascii-only.sh`
  globs `tests/canonical/fixtures/` (it should sweep only `SHIPPED_SCRIPTS`); the fixtures are
  ASCII regardless, so this is a no-risk confirmation, not a blocker.
- **[SPIKE-V5 — sequencing.]** f012's four suites consume f004's `harvest-coined-terms.sh` +
  `closure-check.sh`, f005's `kb-salient-coverage.sh` + `kb-teachback-questions.sh`, and f006's
  `recon-classify.sh`. All three features must land before f012's suites go green (a suite over a
  not-yet-shipped script fails). Confirm with PLAN.md that **f004 + f005 + f006 land before
  f012** (the §10 Must "validation fixture" sequences last in the essence cluster). Until then,
  f012's suites are authored but skipped/red; the fixtures (static, dependency-free) can land
  first as the calibration oracle the implementers tune against.
