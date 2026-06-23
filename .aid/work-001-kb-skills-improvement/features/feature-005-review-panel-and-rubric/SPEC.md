# Review Panel & Calibration Rubric

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-17, FR-18, FR-19) | /aid-interview |

## Source

- REQUIREMENTS.md §5.D (FR-17, FR-18, FR-19)
- REQUIREMENTS.md §1.4 (review side, the panel, calibration, evidence-anchored grading), §2.2/§2.4 (P2, P4)
- §4 S4

## Description

This feature replaces the single blended reviewer with a **multi-mandate review
panel** and adds the missing rubric dimension so the gate stops selecting for
"shallow-but-true." The panel applies five mandates — **Correctness** (claims true
vs source), **Anatomy/Coverage** (what in the source is unrepresented),
**Concept-closure** (every native term defined; salient-term coverage),
**Teach-back** (using only the KB, explain the engine and answer "what is X?"), and
**Calibration** (summary vs transcription — the sweet spot). The mandates are
**invariant across paths**; the **panel size scales** (full parallel panel for
brownfield-large, collapsing onto fewer reviewers — down to one running the
checklist — for brownfield-small / greenfield).

**Teach-back closure becomes the keystone exit criterion**, displacing "severity
distribution ≥ A+." The new **Calibration** dimension grades transcription (too
fat), hollowness (too thin), coverage-vs-source (a load-bearing fact in the doc's
`sources:` is absent), and deferral-must-point — all graded against
mechanically-generated evidence lists (salient terms, source files), so grading is
evidence-anchored and repeatable rather than pure recall.

## User Stories

- As an **AID adopter (incl. AI-skeptic)**, I want the gate to certify usefulness
  (teach-back) and not just "true + template-complete" so that a green gate actually
  means the KB captured my project.
- As an **AI agent** consuming the KB, I want calibration grading to catch
  transcription and hollowness so that docs sit at the useful altitude (summary +
  pointer), not as fat duplicates or empty link-farms.
- As an **AID maintainer**, I want reviewers graded against mechanically-generated
  evidence lists so that grading is repeatable and CI-anchored, and the panel scales
  by path.

## Priority

Must

## Acceptance Criteria

- [ ] Given a KB under review, when the panel runs, then it applies all five
  mandates (Correctness, Anatomy/Coverage, Concept-closure, Teach-back, Calibration),
  invariant across paths, with panel size scaling by path. *(FR-17)*
- [ ] Given a reviewed KB, when the exit is evaluated, then teach-back closure is the
  keystone exit criterion (not severity distribution). *(FR-18; supports AC1)*
- [ ] Given planted calibration fixtures, when the rubric grades them, then it flags
  transcription (too fat), hollowness (too thin), and coverage-vs-source gaps,
  graded against mechanically-generated evidence lists. *(FR-19, AC6)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — evidence
> lists (salient terms, source files) are mechanically generated; the review panel
> is fully parallel (wall-clock); teach-back is anchored to a fixed question set
> derived from the harvest. The AC6 calibration fixtures are provided by f012.

---

## Technical Specification

> Methodology/tooling feature — the **validation half of the essence engine**. f004
> PRODUCES the essence (harvest -> spine -> closure); **f005 GRADES it.** It changes
> `aid-discover`'s REVIEW from **one blended `aid-reviewer` dispatch** into a **five-mandate
> parallel panel** aggregated into **one ledger**, adds **teach-back closure** as a
> clean-context **hard gate** (the keystone exit), and adds a **Calibration** dimension to
> `review-rubric.md` graded against mechanically-generated evidence lists (f004's
> `candidate-concepts.md` salient terms + f001's per-doc `sources:`). "Components" here are
> `aid-discover` REVIEW reference snippets, the rubric template, a new teach-back question-set
> + prompt, two new mechanical scripts (the salient-term coverage check + the teach-back
> question-set generator), and a canonical test suite — not application code. Every claim is grounded against the files cited inline;
> genuine unknowns are flagged **[SPIKE]**, not guessed.
>
> **Boundaries (NOT absorbed here).** The **generation-time** harvest / spine / closure loop
> is **f004** — f005 only *consumes* f004's `.aid/generated/candidate-concepts.md` (the fixed
> evidence list) + the upgraded `domain-glossary.md` spine and *grades against them*; it does
> not re-spec their production. **Panel-size scaling by path** (full panel for
> brownfield-large; collapse to 1 checklist-reviewer for brownfield-small / greenfield) is
> **f006**'s wiring — f005 defines the five mandates and the **full panel as the default**;
> f006 collapses it. The **frontmatter `sources:` schema** (the calibration coverage-vs-source
> evidence) is **f001**'s; f005 *consumes* `sources:`. The **concern model** / open-question
> expectations are **f003**'s. **Migration** of AID's own KB into review (re-grading under the
> new panel) is **f011**. The **Calibration fixtures** (planted transcription / hollowness /
> coverage-gap docs that AC6 grades) are **f012**'s. Reuse the **existing `aid-reviewer`
> agent + reviewer-ledger schema + `grade.sh`** — f005 invents **no new grading infra**.

### Overview

Today `aid-discover`'s REVIEW (`state-review.md`) dispatches a **single** `aid-reviewer`
sub-agent against a blended 6-criteria rubric (`reviewer-prompt.md`), grades the one ledger
via `grade.sh`, and exits on "severity distribution >= minimum_grade". That single blended
reviewer is exactly P2's "selects for shallow-but-true": Correctness + template-coverage are
both satisfied by generic content, and there is no essence / calibration axis (REQUIREMENTS
2.2, 2.4).

f005 replaces that with **five things**, all grafted onto the existing REVIEW state (graft,
don't replace — REQUIREMENTS 1.9):

1. **The five mandates** — Correctness, Anatomy/Coverage, Concept-closure, Teach-back,
   Calibration (REQUIREMENTS 1.4 panel table; FR-17). Each is a **scoped `aid-reviewer`
   dispatch** with its own prompt focus and fail condition. The mandates are **invariant
   across paths**; only the *panel size* scales (f006).
2. **Panel orchestration** — REVIEW changes from **1 dispatch to 5 parallel dispatches**;
   the orchestrator (`aid-discover` itself, per the ledger-schema "orchestrator only
   orchestrates" rule) **aggregates all five mandate findings into ONE ledger**
   (`.aid/.temp/review-pending/discovery.md` — unchanged path) and runs the **existing
   `grade.sh`** over it.
3. **The teach-back exit (keystone hard gate)** — a **clean-context** `aid-reviewer`
   given ONLY the KB + a **fixed question set** sourced from f004's
   `candidate-concepts.md`, that must *define each core concept* and *explain the engine*.
   **Teach-back fail => not-Ready regardless of the severity grade** (FR-18; REQUIREMENTS
   1.4 "Teach-back closure is THE keystone exit criterion — not severity distribution >= A+").
4. **The Calibration rubric dimension** — a new section in `review-rubric.md`
   (transcription / hollowness / coverage-vs-source / deferral-must-point), graded against
   f004's salient terms + f001's `sources:`, operationalized by the **round-trip test**
   (forward orientation / reverse coverage / transcription scan) (FR-19).
5. **One mechanical evidence helper** — `kb-salient-coverage.sh`, a deterministic
   script that diffs `candidate-concepts.md` (the salient-term universe) against the KB to
   produce the **evidence list** the Concept-closure and Calibration reviewers grade against
   (NFR-3: "evidence-anchored grading", and the salient-term coverage check is scriptable).

The deterministic substrate (the coverage script, the fixed teach-back question set, the
existing `grade.sh`) is mechanical/CI-able; the irreducible LLM judgment ("did it explain
the engine", "is this transcription") is **minimized and evidence-anchored** (REQUIREMENTS
1.6 honest floor; NFR-3).

### The Five Mandates

Each mandate is a **scoped `aid-reviewer` dispatch** with (a) a definition, (b) what it
checks, (c) what it fails on, (d) its prompt focus. They share the existing universal
reviewer brief (`reviewer-brief.md`) and write to the **same** ledger; what differs per
mandate is the **rubric focus injected into the appended prompt body** (today's monolithic
`reviewer-prompt.md` is split into five focused prompt sections — see Panel Orchestration).
The five are authored verbatim from REQUIREMENTS 1.4's panel table.

| # | Mandate | Definition | Checks | Fails when | Severity anchor |
|---|---------|------------|--------|------------|-----------------|
| M1 | **Correctness** | Claims are true vs the source. | Per-claim verification against disk (the **existing** `reviewer-prompt.md` Accuracy checklist: versions, paths, class/interface claims, config values, absolute statements). | A claim contradicts the source. | False claim = `[CRITICAL]`; extractable-but-TBD = `[HIGH]` (existing rubric). |
| M2 | **Anatomy / Coverage** | What in the source is *unrepresented* — load-bearing parts missing from the KB. | For each load-bearing part of the system (from the project-index + the doc's `sources:`), is it represented in some KB doc? Maps to the existing rubric's Anatomy/Completeness against `document-expectations.md` (f003's open questions). | A load-bearing part is missing/unrepresented. | Missing load-bearing part = `[HIGH]`; missing whole standard doc = `[KB-MISSING]` HIGH (existing lint tag). |
| M3 | **Concept-closure** | Every native term is defined; salient-term coverage holds. | (a) Self-containment: no project-specific term used in the KB is left undefined (consumes f004's `closure-check.sh` result); (b) **salient-term coverage**: every cross-source term in `candidate-concepts.md` is either grounded in the spine or explicitly dismissed (consumes `kb-salient-coverage.sh`, below). | A coined term ('Relative bus') is absent or undefined. | Uncovered salient term = `[HIGH]` `[CLOSURE-GAP]` (new tag, below); undefined-used term = `[HIGH]`. |
| M4 | **Teach-back** | Using ONLY the KB, explain the engine + answer "what is X?" for each core concept. | A clean-context reviewer, fed the fixed question set, must define each core concept and narrate how the system works in native terms (see Teach-Back Exit). | It cannot explain a core concept / cannot narrate the engine. | **Hard gate** (pass/fail), NOT a severity row — see Grade Aggregation. |
| M5 | **Calibration** | Summary vs transcription — the doc sits at the useful altitude (summary + pointer). | The round-trip test (forward orientation / reverse coverage / transcription scan) against f004's salient terms + f001's `sources:` (see Calibration Rubric Dimension). | Generic / transcribed (too fat) / hollow (too thin) / a `sources:` fact is absent / a deferral has no pointer. | Per the Calibration severity table (below): transcription/hollowness = `[MEDIUM]`; coverage-vs-source gap = `[HIGH]`. |

**Mandate-to-existing-rubric mapping (graft, don't replace).** M1 and M2 are the *existing*
blended rubric's Accuracy and Completeness/Depth criteria, now **split into focused
dispatches** so neither can be satisfied by generic content while the other passes (P2: the
blend is the bug). M3, M4, M5 are **new** essence/calibration axes. The rubric **routing**
(`review-rubric.md` "which rubric applies" by `kb-category`+`source`) is unchanged — each
mandate reviewer still routes meta/generated docs to Spot-Check / Build-Verify and skips
`.aid/.temp/`. The mandates layer **on top of** the per-category rubric, they do not replace
the category routing.

### Panel Orchestration

#### From 1 dispatch to 5 parallel dispatches

`state-review.md` Step 1 today renders one brief + one appended `reviewer-prompt.md` body and
fires **one** `aid-reviewer`. f005 rewrites Step 1 into a **fan-out**:

```
Step 1  Dispatch the Panel  (5 PARALLEL aid-reviewer dispatches — the full-panel default)
  1a  Render the universal brief (reviewer-brief.md) ONCE — {{ARTIFACTS}}/{{CONTEXT}} as today.
  1b  For each mandate Mi in {Correctness, Anatomy/Coverage, Concept-closure, Teach-back,
      Calibration}: append that mandate's FOCUS body (reviewer-prompt-<mandate>.md) +
      DOCUMENT_EXPECTATIONS (M2 only) + the evidence-list pointers (M3/M5 only).
  1c  Dispatch all 5 aid-reviewer sub-agents IN PARALLEL (one message, 5 dispatches) —
      A3 capability-probe: if parallel dispatch is unavailable, degrade to sequential.
  1d  Each mandate reviewer writes to ITS OWN transient per-mandate scratch ledger
      .aid/.temp/review-pending/discovery-<mandate>.md (NOT a schema <scope> ledger — these
      are short-lived transients created here and DELETED in Step 2 after the merge; the
      canonical schema <scope> ledger discovery.md is untouched), so the 5 do not race on
      one file.
  Wait for all 5 to complete (record per-mandate time).
```

The **full panel (all 5) is the default** f006 collapses. f005 authors REVIEW to dispatch
all five; f006 reads the recon-selected path and, for brownfield-small / greenfield,
**collapses** the panel (down to one reviewer running the multi-mandate checklist —
REQUIREMENTS 1.5 matrix "Review" row). **f005 does not implement the collapse**; it notes
the seam: the per-mandate dispatch list is the unit f006 scales (full 5 -> 1).

The **clean-context discipline is preserved and strengthened**: every mandate dispatch keeps
`state-review.md`'s existing CONTAMINATION-PREVENTION block (no generation process, no prior
grade, no "re-review"). The Teach-back mandate adds a *stronger* clean-context rule (it must
see ONLY the KB, not even the project source — see Teach-Back Exit).

#### Aggregation into ONE ledger + grade.sh

After the 5 reviewers return, the orchestrator **merges the 5 scratch ledgers into the single
canonical ledger** `.aid/.temp/review-pending/discovery.md` (the path `grade.sh` and FIX
already use — unchanged), then grades:

```
Step 2  Aggregate + Grade
  2a  Concatenate the data rows from ALL FIVE scratch ledgers — discovery-{correctness,
      anatomy,concept-closure,calibration}.md PLUS discovery-teachback.md's [HIGH]
      [TEACHBACK] FAIL-item rows (the teachback rows ARE merged into discovery.md; only
      the TEACHBACK-VERDICT sentinel row is NOT merged — it is read in 2c) — into
      discovery.md, assigning each merged row a STABLE per-mandate ID in the # column
      (e.g. M1-001, M3-002, TB-001) rather than a fresh global sequential #. Rationale:
      the schema's "never renumber / cite the row # in commit messages" convention requires
      stable IDs across cycles; a per-mandate ID (mandate marker + monotonic counter within
      that mandate's row set) stays stable cycle-to-cycle, so a FIX commit citing "row M3-002"
      still resolves next cycle. (If the host renderer requires a bare-integer # column, the
      merge instead assigns a fresh sequential # but the note records that the renumber is
      MERGE-LOCAL and commits MUST cite the stable [Mi] description marker + row text, not the
      volatile #.) Either way the cross-cycle citation anchor is mandate-stable, not the
      volatile global ordinal.
  2b  Run the EXISTING grader unchanged:
        bash .claude/aid/scripts/grade.sh --explain .aid/.temp/review-pending/discovery.md
      grade.sh already counts worst-severity over Status in {Pending,Recurred} across ALL
      rows — it does not care which mandate produced a row. No grade.sh change.
  2c  Evaluate the TEACH-BACK HARD GATE (see Grade Aggregation): read the teach-back
      reviewer's verdict (PASS/FAIL) from discovery-teachback.md's TEACHBACK-VERDICT
      sentinel row (this sentinel lives ONLY in the transient teachback scratch ledger and
      is consumed here, before 2d deletes it; it is NOT persisted into discovery.md). The
      verdict is therefore RE-DERIVED each REVIEW cycle by re-running the teach-back mandate
      and re-reading its fresh sentinel — there is no persisted verdict between cycles. What
      DOES persist in discovery.md across cycles is the set of [HIGH] [TEACHBACK] FAIL rows
      (merged in 2a), whose Pending/Fixed Status the teach-back reviewer maintains cycle-to-
      cycle exactly like every other mandate's rows; the recomputed verdict and those rows
      stay in agreement (verdict==PASS iff zero open [TEACHBACK] rows).
  2d  Delete the 5 transient per-mandate scratch ledgers (discovery-<mandate>.md, including
      discovery-teachback.md) — discovery.md is now the single source FIX reads, exactly as
      today.
```

**Why merge rather than five ledgers:** FIX (`state-fix.md`) and the ledger schema are built
around **one `<scope>.md` per skill invocation** that `grade.sh` reads and FIX resolves. Five
persistent ledgers would fork the FIX loop and the grade computation. Merging to the single
`discovery.md` keeps FIX, `grade.sh`, and the schema **unchanged** — the panel is an
*input-side* fan-out that collapses back to the existing single-ledger contract before
grading. The per-mandate scratch ledgers are transient (merged then deleted in the same
Step 2), so no schema or `grade.sh` change is needed (NFR-4 conventions-fit).

#### Cross-cycle (FIX -> re-REVIEW) consistency

On cycle N>=2 the panel re-runs against the **existing `discovery.md`** exactly as the schema
prescribes: each mandate reviewer, before appending, reads the existing `discovery.md`,
verifies its own prior rows on disk, and updates Status (Pending->Fixed if resolved,
Fixed->Recurred if regressed) for rows it owns. To make "rows it owns" unambiguous across the
merge, each row carries **both** a stable per-mandate `#` ID (`M1-001`..`M5-NNN`, `TB-NNN`) and
a leading mandate marker in its **Description** (`[M1]..[M5]`, `[TEACHBACK]`) — a description-text
convention that does NOT collide with `grade.sh` (which reads only the bracketed Severity in
column 3, never the `#` or Description columns — confirmed `grade.sh` lines 197-212). The
**stable per-mandate `#` ID is the cross-cycle citation anchor** that honors the schema's "cite
the row `#` in commit messages" convention: because the ID is mandate-scoped and monotonic
(never reassigned to a different finding), a FIX commit citing `M3-002` resolves to the same
finding every cycle. The **teach-back verdict is not a persisted row** — it is recomputed each
cycle from a fresh teach-back dispatch (Step 2c); only the `[TEACHBACK]` FAIL rows persist and
are re-verified like any mandate's. This lets cycle-N reviewers re-verify only their own
mandate's rows while the merged ledger stays one file.

### Teach-Back Exit (the keystone hard gate)

#### The clean-context dispatch

Teach-back is **M4**, but it is special: it is the **keystone exit criterion** (FR-18,
REQUIREMENTS 1.4/1.10), so it is **both** a panel mandate **and** the gate that overrides the
severity grade. It is a **clean-context `aid-reviewer`** dispatched with a *stricter*
context rule than the other four:

- **Input = ONLY the KB** (`.aid/knowledge/*.md`) **+ the fixed question set**. It is **not**
  given the project source, the project-index, the candidate-concepts list, or any generation
  context. The whole point is to simulate "a fresh agent given only the KB" (AC1) — if the
  reviewer can reach the source it is not teaching *back from the KB*, it is re-deriving.
  This is the strongest form of `state-review.md`'s existing CLEAN-CONTEXT rule.
- **The fixed question set** is sourced **deterministically** from f004's
  `.aid/generated/candidate-concepts.md`: the question set is **"What is X?" for every
  cross-source `Term` row that the candidate table actually emits**, **plus** the single fixed
  engine question **"Explain how this system works, in its own language."** Concretely, f004's
  table emits its top-`N` candidates (default 60) **plus** every candidate with spread `>= 3`;
  the teach-back set takes **every emitted row with spread `>= 2`** (the cross-source bar). This
  means: all spread `>= 3` terms are always included (f004 guarantees emitting them); spread
  `== 2` terms are included **iff they fall within f004's emitted top-`N`**. A spread `== 2`
  term below the top-`N` cut is **not** in f004's table and is therefore **not** a teach-back
  question (the set is bounded by what the harvest deterministically emits — it never invents
  un-emitted terms). The cap is f004's `--top`; if a future harvest needs deeper spread-2
  coverage, raising f004's `--top` widens the set (the dependency, not a f005 change).
  Because the candidate list is mechanically generated and byte-reproducible (f004's NFR-3
  guarantee), the question set is a **fixed, repeatable** function of the emitted candidate
  table — the "teach-back as a fixed
  question set derived from the harvest" REQUIREMENTS 1.6/NFR-3 names. A new helper
  `kb-teachback-questions.sh` derives the question list from `candidate-concepts.md` (a
  trivial column-extract + the one fixed engine question) so the set is generated, not
  recalled.

#### Pass / fail (the hard gate)

The teach-back reviewer answers each question **using only the KB**, then self-scores each
answer against a binary bar:

- **Per concept ("what is X?"):** PASS iff the KB lets the reviewer give the
  *definition-as-used-here* (not a generic dictionary definition) with a KB anchor. A concept
  it cannot define from the KB, or can only define generically, = a **FAIL item**.
- **The engine question:** PASS iff the reviewer can narrate how the system works end-to-end
  in the project's native terms without reaching an undefined term. A narration that stalls on
  an undefined native term = a **FAIL item**.
- **Verdict:** teach-back is **PASS** iff **zero FAIL items**; otherwise **FAIL**, and each
  FAIL item is written as a `[HIGH]` `[TEACHBACK]` row in `discovery-teachback.md` naming the
  concept/flow that could not be explained (so FIX has an actionable target). The verdict
  itself is recorded as a **sentinel row** (`Severity: —`, `Description: TEACHBACK-VERDICT:
  PASS|FAIL`) the orchestrator reads in Step 2c.

#### How it combines with the grade (teach-back fail => not-Ready)

This is the keystone mechanism. The exit decision is **two gates, both required**:

```
READY  iff  grade(discovery.md) >= minimum_grade   AND   teachback_verdict == PASS
```

- The **severity grade** is computed by the **unchanged `grade.sh`** over the merged
  `discovery.md` (M1/M2/M3/M5 rows + any teach-back `[TEACHBACK]` follow-up rows that were
  merged — see below).
- The **teach-back verdict** is an **independent hard gate**: even a clean A+ severity grade
  does **not** advance past REVIEW if `teachback_verdict == FAIL`. This is the literal
  displacement REQUIREMENTS 1.4 demands ("Teach-back closure is THE keystone exit criterion —
  not severity distribution"). The exit print and STATE update both report the **pair**:
  `Grade: A+ | Teach-back: FAIL -> NOT Ready (FIX teach-back gaps first)`.
- **Mechanically anchoring the gate to the existing grader:** to keep the gate within the
  existing single-grade machinery (no new "second grade" concept), each teach-back FAIL item
  is **also merged into `discovery.md` as a `[HIGH]` `[TEACHBACK]` Pending row** at
  aggregation (Step 2a/2c). Because an unresolved teach-back FAIL is a `[HIGH]` row,
  `grade.sh` already drops the grade to **D** while any teach-back gap is open — so the
  numeric grade and the hard gate **agree** (a teach-back FAIL cannot coexist with a passing
  grade). The explicit `teachback_verdict` sentinel is retained as the **human-visible**
  keystone signal and the canonical READY condition; the `[HIGH] [TEACHBACK]` rows are the
  mechanism that makes the existing grader enforce it without a second grading path. (This
  resolves the apparent tension between "teach-back is a hard gate distinct from the severity
  grade" and "reuse grade.sh unchanged": the verdict is the human-facing gate; the merged
  `[HIGH]` rows are how the *existing* grader mechanically realizes "teach-back fail =>
  not-Ready". The `READY` condition above is still written as the explicit `AND` so a future
  reviewer cannot accidentally relax the gate by reclassifying a `[TEACHBACK]` row.)

### Calibration Rubric Dimension (FR-19)

#### The new `review-rubric.md` section

A new section **"Calibration (summary vs transcription)"** is added to
`canonical/aid/templates/kb-authoring/review-rubric.md`, after the Full Primary rubric (it is
a Full-Primary-only dimension — meta/generated docs are not calibration-graded). It adds four
checks, each **evidence-anchored** against a mechanically-generated list (f004's salient terms
+ f001's `sources:`), so grading is repeatable, not pure recall (NFR-3):

| Check | Definition | Evidence anchor | Severity |
|-------|------------|-----------------|----------|
| **CAL-1 Transcription (too fat)** | The doc faithfully duplicates volatile source detail (full signatures, exhaustive enumerations) instead of synthesizing — a "rotting duplicate" (REQUIREMENTS 1.3, P4). | The doc's `sources:` that resolve to **local readable files** (paths/dirs/globs): a doc whose body is a near-verbatim restatement of such a file, with high overlap and no added *why*/*how-it-relates*, is transcription. **URL `sources:` -> N/A (skipped, not a finding)** — the offline helper cannot fetch them. | `[MEDIUM]` `[CAL-TRANSCRIPTION]` |
| **CAL-2 Hollowness (too thin)** | A "see file X" link-farm conveying no durable understanding (REQUIREMENTS 1.3, P4). | The doc's `sources:` vs body ratio: a doc that is mostly pointers with no synthesized cross-cutting content (no *why*, no *how parts interact*) is hollow. | `[MEDIUM]` `[CAL-HOLLOW]` |
| **CAL-3 Coverage-vs-source** | A load-bearing fact present in the doc's `sources:` is **absent** from the doc — "the source has Y and the doc forgot it" (P4, never caught today). | The doc's `sources:` (the authoritative content) + the salient terms from `candidate-concepts.md` that anchor to those sources: a salient/load-bearing fact in `sources:` with no representation in the doc is a coverage gap. | `[HIGH]` `[CAL-COVERAGE]` |
| **CAL-4 Deferral-must-point** | Where the doc defers depth ("see source"), it MUST point to a concrete `sources:` entry (durable, grep-recoverable anchor — the existing P1(d) anchor convention), not a vague "see the code". | The doc's `sources:` list: every deferral phrase must resolve to a declared source. | `[LOW]` `[CAL-DEFERRAL]` |

These severities are tuned so the calibration dimension *moves* the grade (a coverage-gap is
`[HIGH]` -> grade D, the same weight as a broken contract) without making every altitude nit a
gate-blocker (transcription/hollowness are `[MEDIUM]` -> grade C; deferral is `[LOW]`). The
exact `[MEDIUM]` vs `[HIGH]` cut for transcription/hollowness is **[SPIKE-C1]** —
f012-calibrated against the planted fixtures (AC6): the fixtures are the executable acceptance
test for whether the severities flag the planted fat/thin/coverage-gap docs without
false-positiving on a well-calibrated doc.

#### The round-trip test (operationalization)

The four checks are operationalized via the **round-trip test** (REQUIREMENTS 1.4) — three
mechanical-then-judgment passes the Calibration reviewer runs per Full-Primary doc:

1. **Forward orientation.** From the doc alone (summary side), can a reader orient — get the
   *why* / *how parts interact* / the gotchas? A doc that is all pointers fails forward
   (CAL-2 hollow). *(Judgment, anchored: the reviewer reads the doc, no source.)*
2. **Reverse coverage.** From the doc's `sources:` (the authoritative side), are the
   load-bearing facts + salient terms that those sources contain represented in the doc? A
   `sources:` fact the doc forgot fails reverse (CAL-3 coverage-vs-source). *(Anchored to the
   `kb-salient-coverage.sh` output — which salient terms in `candidate-concepts.md` anchor to
   this doc's `sources:` but are absent from the doc.)*
3. **Transcription scan.** Is the doc a near-verbatim copy of its `sources:` (fat) rather than
   a synthesis? *(Mechanical signal: high lexical overlap between body and a **local-file**
   `sources:` entry, surfaced by the coverage helper as a transcription-ratio hint; the reviewer
   confirms. `sources:` that are URLs are N/A — skipped by the offline helper, never flagged.)*

The forward/reverse framing is the "sweet spot" calibration REQUIREMENTS 1.3 commits to:
forward catches *too thin*, reverse + transcription-scan catch *too fat* and *coverage gaps*.

#### The mechanical evidence helper + new finding tags

- **NEW script `canonical/aid/scripts/kb/kb-salient-coverage.sh`** (shipped KB script;
  ASCII bash; no LLM — C1/C2/NFR-8; sibling of f004's `harvest-coined-terms.sh` /
  `closure-check.sh`). Inputs: `.aid/generated/candidate-concepts.md` (the salient-term
  universe) + the KB docs + (per-doc) `sources:` frontmatter. **`sources:` parsing is
  self-contained:** `kb-salient-coverage.sh` implements its own small inline frontmatter
  list-extraction (coreutils `awk`, mirroring the logic of f001's `extract_list`) rather than
  depending on f001. f001 defines `extract_list` as a **local function inside
  `build-kb-index.sh`**, not a sourceable library, so there is no cross-feature reuse path; this
  spec therefore self-contains the few lines of list-parsing and **does not require any change
  to f001** (which is Ready). The minor duplication of this small parser is **deliberate** — it
  avoids creating a cross-feature shared-library contract for a trivial frontmatter read.
  Outputs a deterministic **evidence list**: for each
  KB doc, (a) which salient cross-source terms anchored to that doc's `sources:` are **absent
  from the doc body** (the CAL-3 / M3 coverage evidence), and (b) a **transcription-ratio
  hint** (lexical-overlap signal between the doc body and each `sources:` file, for CAL-1).
  **`sources:` resolution scope (deterministic).** f001 permits a `sources:` entry to be a
  repo-relative path, a glob, a directory, OR a URL. The transcription/lexical-overlap signal
  (b) is computed **only over `sources:` entries that resolve to local readable files** — plain
  paths, directories (their contained files), and globs (their matched files). A **URL `sources:`
  entry is N/A for the transcription check: the offline coreutils helper cannot fetch it, so it
  is silently SKIPPED — not read, not a finding** (no-new-runtime, C1). The coverage signal (a)
  likewise reads only local-file sources for body text; URL-only-sourced facts are out of the
  mechanical coverage scope (the reviewer may still judge them, but the helper emits no
  transcription/coverage evidence for a URL). This makes CAL-1's mechanical input fully
  deterministic. This is the "salient-term coverage check is scriptable" determinism lever
  (NFR-3): the reviewer grades against this list, it does not recall from memory. Tested by
  `tests/canonical/test-kb-salient-coverage.sh` (a planted uncovered salient term is reported;
  a fully-covered fixture reports empty; re-run byte-identical).
- **New finding tags** (added to `review-rubric.md`'s "Lint output -> severity mapping" table,
  reusing the existing `[SEVERITY] [TAG] <description>` convention — no new grading infra):
  `[CLOSURE-GAP]` (HIGH — a salient cross-source term is neither grounded nor dismissed),
  `[CAL-TRANSCRIPTION]` (MEDIUM), `[CAL-HOLLOW]` (MEDIUM), `[CAL-COVERAGE]` (HIGH),
  `[CAL-DEFERRAL]` (LOW), `[TEACHBACK]` (HIGH). Each is a **description-side tag** the reviewer
  emits with its severity prefix; `grade.sh` still counts only the **Severity column**
  (unchanged), so the tags are for FIX-targeting + human readability, exactly like the
  existing `[FM-MISSING]`/`[KB-MISSING]` tags. **No `grade.sh` change.**

### Grade Aggregation

The complete exit computation, consistent with the existing `grade.sh` + ledger schema:

```
1. Five mandate reviewers (M1..M5) run in parallel, each writing discovery-<mandate>.md
   (M4 teach-back also writes a TEACHBACK-VERDICT sentinel row).
2. Orchestrator MERGES M1/M2/M3/M5 rows + M4's [TEACHBACK] FAIL-item rows into the single
   discovery.md (stable per-mandate # ID Mi-NNN/TB-NNN, [Mi]/[TEACHBACK] description prefix),
   then deletes the 5 transient scratch ledgers. M4's TEACHBACK-VERDICT sentinel row is NOT
   merged (it is read in the next step from the transient ledger before deletion).
3. grade  = grade.sh discovery.md            # EXISTING grader, worst-severity-dominates,
                                              # counts Status in {Pending,Recurred} only
4. verdict = TEACHBACK-VERDICT from M4 sentinel   # PASS | FAIL (the keystone hard gate);
                                              # re-derived each cycle from a fresh teach-back
                                              # dispatch, NOT persisted in discovery.md
5. READY iff grade >= minimum_grade AND verdict == PASS
     - because every teach-back FAIL item is ALSO a [HIGH] [TEACHBACK] row in discovery.md,
       grade.sh independently yields <= D whenever verdict == FAIL, so the two gates agree;
       the explicit AND makes the keystone gate un-relaxable by row reclassification.
6. STATE + exit print report the PAIR: "Grade: <g> | Teach-back: <verdict> -> <Ready|NOT>".
```

This is fully consistent with the reviewer-ledger schema (one `<scope>.md`, 7-column table,
Status-filtered grading) and `grade.sh` (worst-severity dominates, modifier by count) — f005
adds **no new grade computation**; it adds an **input fan-out** (5 reviewers -> 1 ledger) and
an **independent boolean gate** (teach-back) layered over the existing numeric grade. The
`minimum_grade` resolution is unchanged (`read-setting.sh --skill discover --key
minimum_grade --default A`).

### Affected Components

| Component | Path | Change |
|-----------|------|--------|
| REVIEW flow | `canonical/skills/aid-discover/references/state-review.md` | Rewrite Step 1 (single dispatch -> 5 parallel mandate dispatches, full-panel default + A3 sequential degradation; per-mandate scratch ledgers); rewrite Step 2 (aggregate 5 scratch ledgers -> single `discovery.md`, run **unchanged** `grade.sh`, evaluate teach-back hard gate); Step 3 exit print/STATE report the **(grade, teach-back)** pair. Clean-context + contamination blocks preserved (stronger for teach-back). |
| Mandate prompt bodies | `canonical/skills/aid-discover/references/reviewer-prompt-*.md` (5 NEW: `-correctness`, `-anatomy`, `-concept-closure`, `-teachback`, `-calibration`) | Split today's monolithic `reviewer-prompt.md` into 5 focused per-mandate FOCUS bodies. M1 = today's Accuracy checklist; M2 = Completeness/Anatomy vs `document-expectations.md`; M3 = closure self-containment + salient-coverage (consumes `closure-check.sh` + `kb-salient-coverage.sh`); M4 = teach-back (fixed question set + binary bar); M5 = Calibration round-trip. `reviewer-prompt.md` becomes a thin index pointing to the five (back-compat for any direct reader). **Output redirection (required):** today's `reviewer-prompt.md` instructs the reviewer to "Write the review results ... to STATE.md"; each of the 5 split FOCUS bodies MUST instead instruct its reviewer to write findings to its **own scratch ledger** `.aid/.temp/review-pending/discovery-<mandate>.md` (the 7-column ledger schema), NOT to STATE.md — the STATE.md write wording is dropped from every per-mandate body (the orchestrator, not the reviewers, touches STATE, per the ledger-schema "orchestrator only orchestrates" rule). |
| Teach-back question set | `canonical/skills/aid-discover/references/reviewer-prompt-teachback.md` + **NEW** `canonical/aid/scripts/kb/kb-teachback-questions.sh` | The fixed question set derived deterministically from `.aid/generated/candidate-concepts.md`: every **emitted** `Term` row with spread `>= 2` (all spread `>= 3`, plus spread `== 2` within f004's top-`N` cap) -> "what is X?", + the one fixed engine question. Bounded by f004's emitted table (never invents un-emitted terms). ASCII bash; no LLM. |
| Review rubric | `canonical/aid/templates/kb-authoring/review-rubric.md` | Add the **Calibration** section (CAL-1..CAL-4 + the round-trip test) after Full Primary; add the new tags (`[CLOSURE-GAP]`, `[CAL-*]`, `[TEACHBACK]`) to the "Lint output -> severity mapping" table with their severities. The category routing + existing rubrics are unchanged. |
| **NEW coverage helper** | `canonical/aid/scripts/kb/kb-salient-coverage.sh` | Deterministic salient-term coverage + transcription-ratio evidence list (consumes `candidate-concepts.md` + `sources:`; `sources:` parsed by a **self-contained inline `awk` list-extraction** mirroring f001's `extract_list` logic — no dependency on f001, deliberate minor duplication). ASCII bash; no LLM. The M3/M5 evidence anchor. |
| CI — canonical suites | `tests/canonical/test-kb-salient-coverage.sh` (NEW), `tests/canonical/test-teachback-questions.sh` (NEW) + fixtures under `tests/canonical/fixtures/` | Assert coverage helper reports a planted uncovered salient term / empty on covered / byte-reproducible; assert the question-set generator extracts cross-source terms + the engine question deterministically. Auto-discovered by `tests/run-all.sh`. |
| CI — ascii-only | `tests/canonical/test-ascii-only.sh` | Add `kb-salient-coverage.sh` + `kb-teachback-questions.sh` to `SHIPPED_SCRIPTS` (C2). |
| render-drift | `test.yml` job `render-drift` | No edit; stays green by editing canonical only + re-running `run_generator.py` (the 5 new reference snippets + 2 new scripts + rubric edit render to all 5 trees). |

### Constraints

- **C2 / Q2 — ASCII-only.** The two new scripts (`kb-salient-coverage.sh`,
  `kb-teachback-questions.sh`) vendor into the install bundles -> ASCII-only bash (PS-5.1
  N/A). Added to `test-ascii-only.sh`'s allow-list. The new `review-rubric.md` /
  `reviewer-prompt-*.md` are markdown (not ASCII-gated, but kept ASCII for sibling
  consistency).
- **C1 / NFR-8 — no new runtime.** Both scripts are pure coreutils (`grep`/`awk`/`sort`/
  `comm`/`tr`) — the toolset f004's siblings already use. No embedding model, binary, MCP, or
  `python3`/`pwsh` escalation. The panel reuses the **existing** `aid-reviewer` agent and
  `grade.sh`; no new grading runtime.
- **C3 / NFR-4 — render-drift green.** All authored files are canonical (the 5
  `reviewer-prompt-*.md`, `state-review.md`, `review-rubric.md`, the 2 `scripts/kb/*.sh`).
  Edit canonical only; re-run `python .claude/skills/generate-profile/scripts/run_generator.py`;
  commit regenerated `profiles/` (render-drift-full-generator precedent). **[SPIKE-C2]** —
  verify the renderer auto-emits the net-new `reviewer-prompt-*.md` reference files + the new
  `scripts/kb/*.sh` to all 5 trees (it enumerates the tree; expected yes); if an emission
  manifest pins the `aid-discover/references/` or `scripts/kb/` list, regen, never hand-place.
- **C5 / NFR-3 — deterministic, CI-testable + evidence-anchored.** The coverage helper, the
  question-set generator, and `grade.sh` are mechanical, stable-sorted, byte-reproducible, and
  asserted in the new canonical suites. The teach-back question set is a **fixed** input
  derived from f004's reproducible `candidate-concepts.md`; the irreducible judgment
  (teach-back "did it explain", calibration "is this transcription") is minimized + anchored
  to the evidence list (NFR-3 honest floor).
- **NFR-2 — wall-clock / parallel panel.** The 5 mandate dispatches run **in parallel** (one
  message, 5 dispatches), keeping the sequential critical path at one reviewer's wall-clock,
  not five (A3: degrade to sequential where parallel dispatch is unavailable). The evidence
  helpers are single sub-second script passes (no dispatch).
- **NFR-1 — cost.** The panel is 5 reviewer dispatches vs today's 1; this is the deliberate
  cost f006 *scales down* per path (brownfield-small/greenfield collapse to 1). For
  brownfield-large the extra reviewers are justified by complexity (REQUIREMENTS NFR-1); the
  mechanical evidence (coverage + question-set scripts) is **zero-token** deterministic
  substrate, holding the LLM surface to the irreducible judgment.
- **C4 — human-gated.** REVIEW grades + flags; the human approval gate (`state-approval.md`)
  is unchanged. Teach-back FAIL routes to FIX (or, for an ungroundable concept, to the f004
  human-Q&A escape hatch), never auto-resolves.
- **C6 — content-isolation.** New scripts are namespaced under `aid/scripts/kb/`; the panel's
  scratch ledgers live under the gitignored `.aid/.temp/review-pending/` (existing isolated
  tree); the merged ledger is the existing `discovery.md`.

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-C1]** Calibration severity tuning — the `[MEDIUM]` vs `[HIGH]` cut for
  transcription/hollowness and the transcription-ratio threshold are **f012-calibrated**
  against the planted fixtures (AC6): the fixtures are the executable acceptance test for
  recall (flag the planted fat/thin/coverage-gap docs) vs precision (do not false-positive a
  well-calibrated doc). f005 sets the *shape* (which tag, which check); f012 tunes the *floor*.
- **[SPIKE-C2]** Net-new reference + script render — verify `run_generator.py` emits the 5
  net-new `reviewer-prompt-*.md` and the 2 net-new `scripts/kb/*.sh` to all 5 trees (it
  enumerates the tree); if any emission manifest pins the `aid-discover/references/` or
  `scripts/kb/` file list, update canonical + regen, never hand-place (render-drift-full-
  generator precedent).
- **[SPIKE-C3 — boundary, panel scaling]** The collapse of the full 5-mandate panel to fewer
  reviewers (down to 1 checklist-reviewer) for brownfield-small / greenfield is **f006**'s
  wiring. f005 authors the full-panel default and exposes the per-mandate dispatch list as the
  scaling unit; confirm with PLAN.md that f005 (mandates + full panel) lands before f006 wires
  the path->panel-size mapping (provide-before-consume).
- **[SPIKE-C4 — sequencing]** f005 consumes f004's `candidate-concepts.md` + the upgraded
  `domain-glossary.md` spine (the salient evidence + teach-back question set) and f001's
  per-doc `sources:` (the calibration coverage evidence). The `sources:` **list-extraction is
  self-contained** in `kb-salient-coverage.sh` (an inline `awk` mirror of f001's `extract_list`
  logic — f005 does **not** depend on f001's local function and requires **no f001 change**), so
  the only f001 dependency is the `sources:` frontmatter *schema*, not any shared code. Confirm
  with PLAN.md that **f001 + f004 land before f005** (consume-after-define); if f005 is
  sequenced earlier, the coverage helper degrades to
  "no candidate-concepts.md yet -> empty evidence list" and teach-back degrades to "no
  question set -> engine question only" (degrade-gracefully, never an error), but the
  essence-grading value is not realized until f004 lands.
- **[SPIKE-C5 — boundary, fixtures]** The Calibration AC6 fixtures (planted transcription /
  hollowness / coverage-gap docs) + the teach-back AC1/AC2 end-to-end validation are **f012**.
  f005's own canonical suites assert the *mechanical* halves (coverage helper, question-set
  generator); the *judgment* halves (does the reviewer flag a planted fat doc; does teach-back
  fail on a missing concept) are validated by f012's fixtures. Confirm the f005->f012
  dependency in PLAN.md.
