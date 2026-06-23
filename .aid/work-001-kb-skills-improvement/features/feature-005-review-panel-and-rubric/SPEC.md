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
> + prompt, **one** new mechanical script (the teach-back question-set generator), and a
> canonical test suite — not application code. The salient-term coverage oracle is **f004's**
> (its `closure-check.sh`, which now emits a 3-output contract: (a) the ungrounded/un-closed
> concept set, (b) the per-doc `sources:`-anchored coverage table, (c) the per-doc
> transcription-ratio hint); f005 *consumes* it rather than shipping a second coverage script.
> Every claim is grounded against the files cited inline;
> genuine unknowns are flagged **[SPIKE]**, not guessed.
>
> **Boundaries (NOT absorbed here).** The **generation-time** harvest / spine / closure loop
> is **f004** — f005 only *consumes* f004's `.aid/generated/candidate-concepts.md` (the fixed
> evidence list, incl. f004's NEW `synthesis`-tagged concepts) + the upgraded
> `domain-glossary.md` spine + **f004's merged `closure-check.sh` 3-output coverage oracle**
> (outputs (a) ungrounded set, (b) per-doc `sources:`-anchored coverage table, (c) per-doc
> transcription-ratio hint — f005 ships **no** `kb-salient-coverage.sh`; that script is dropped
> and its function absorbed into f004's `closure-check.sh`) and *grades against them*; it does not
> re-spec their production. The **f008↔f005 seam is f005-owned**: `state-review.md` exposes the
> ledger `<scope>` + the graded doc-set as injectable parameters so f008's `aid-update-kb` can
> reuse the panel — f005 *provides* the seam, f008 *consumes* it (f005 does not author
> `aid-update-kb`). **Panel-size scaling by path** (full panel for
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
   given ONLY the KB + a **fixed question set** sourced from f004's `candidate-concepts.md`,
   that must (a) *define each core concept* (the **per-term** limb — the lexical candidate
   list, incl. f004's `synthesis`-tagged concepts) AND (b) produce a coherent
   *engine-narration* of how the project works from the KB alone (the **non-lexical** limb — a
   first-class FAIL source independent of the per-term quiz, so a KB that defines every coined
   term but cannot support an end-to-end narration of the engine still FAILS teach-back). Each
   FAIL item is a `[HIGH]` `[TEACHBACK]` row; **any open `[TEACHBACK]` row => not-Ready**
   (FR-18; REQUIREMENTS 1.4 "Teach-back closure is THE keystone exit criterion — not severity
   distribution >= A+"). The engine-narration grade is the explicit **LLM-judgment** limb (vs
   the mechanical term-coverage half) — see the Judgment Boundary.
4. **The Calibration rubric dimension** — a new section in `review-rubric.md`
   (transcription / hollowness / coverage-vs-source / deferral-must-point), graded against
   f004's salient terms + f001's `sources:`, operationalized by the **round-trip test**
   (forward orientation / reverse coverage / transcription scan) (FR-19).
5. **One mechanical evidence helper** — `kb-teachback-questions.sh`, the deterministic
   teach-back question-set generator. The **coverage + transcription evidence** the
   Concept-closure (M3) and Calibration (M5) reviewers grade against is **NOT a f005 script**:
   it is **consumed from f004's merged `closure-check.sh`**, which now emits **three** outputs:
   **(a)** the ungrounded/un-closed concept set (harvest + synthesis); **(b)** the per-doc
   `sources:`-anchored coverage table (`term | doc | anchoring-source | present|absent`,
   `sources:` resolved to local readable files, URL -> N/A); **(c)** the per-doc
   transcription-ratio hint (lexical overlap of the doc body vs each local-file `sources:`
   entry, URL -> N/A). One coverage oracle, owned by f004 — f005 ships no second coverage
   script. This is the NFR-3 "evidence-anchored grading" / "salient-term coverage is
   scriptable" lever, realized by consuming f004's single 3-output oracle rather than
   duplicating it.

The deterministic substrate (f004's `closure-check.sh` coverage output, the fixed teach-back
question set, the existing `grade.sh`) is mechanical/CI-able; the irreducible LLM judgment
("did it explain the engine", "is this transcription") is **minimized and evidence-anchored**
(REQUIREMENTS 1.6 honest floor; NFR-3).

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
| M3 | **Concept-closure** | Every native term is defined; salient-term coverage holds. | (a) Self-containment: no project-specific term used in the KB is left undefined (consumes f004's `closure-check.sh` **output (a)** — the ungrounded/un-closed concept set, harvest + synthesis); (b) **`sources:`-anchored coverage**: every salient term anchored to a doc's `sources:` is `present` in that doc or explicitly dismissed (consumes f004's `closure-check.sh` **output (b)** — the per-doc `sources:`-anchored coverage table `term \| doc \| anchoring-source \| present\|absent`, the merged oracle below). | A coined term ('Relative bus') is absent or undefined. | Uncovered salient term (`absent` row) = `[HIGH]` `[CLOSURE-GAP]` (new tag, below); undefined-used term = `[HIGH]`. |
| M4 | **Teach-back** | Using ONLY the KB, explain the engine (non-lexical limb) + answer "what is X?" for each core concept (per-term limb). | A clean-context reviewer, fed the fixed question set, must (a) define each core concept (incl. f004's `synthesis`-tagged concepts) AND (b) produce a coherent **engine-narration** of how the system works in native terms — a **first-class FAIL source independent of the per-term quiz** (see Teach-Back Exit). | It cannot explain a core concept **OR** cannot narrate the engine — narration is its own FAIL even if every term is defined. | `[HIGH]` `[TEACHBACK]` row per FAIL item; any open `[TEACHBACK]` row ⇒ not-Ready (the keystone gate is realized through the rows — see Grade Aggregation). |
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
      [TEACHBACK] FAIL-item rows (per-term AND engine-narration FAIL items are both ordinary
      [TEACHBACK] rows — there is NO separate verdict sentinel; the teach-back "verdict" is
      simply whether any [TEACHBACK] row is open) — into
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
  2c  Evaluate the TEACH-BACK HARD GATE (see Grade Aggregation): the teach-back "verdict" is
      NOT a stored sentinel — it is simply derived from discovery.md itself: teach-back is
      PASS iff ZERO open ([TEACHBACK]) rows (Status in {Pending,Recurred}), FAIL otherwise.
      Both the per-term FAIL items and the engine-narration FAIL items are ordinary [HIGH]
      [TEACHBACK] rows merged in 2a, whose Pending/Fixed Status the teach-back reviewer
      maintains cycle-to-cycle exactly like every other mandate's rows. There is therefore
      no second verdict to reconcile with the rows: the rows ARE the verdict.
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

#### Injectable ledger-scope + doc-set (f005-owned REVIEW parameterization)

`state-review.md` is reused by **f008's `aid-update-kb`**, not only by `aid-discover`. So the
panel's two caller-specific bindings — **(1) the ledger `<scope>`** (which today is hard-coded
to `discovery` → `.aid/.temp/review-pending/discovery.md`) and **(2) the doc-set under review**
(today hard-coded to `discovery.doc_set` — the full KB) — are **f005-owned injectable
parameters**, NOT downstream assumptions left for f008 to bolt on. f005 owns adding them
because f005 is the feature that rewrites Step 1/Step 2 around the scope+doc-set; closing the
seam here avoids the f005↔f008 gap where neither feature owns the parameterization.

Concretely, `state-review.md` takes the scope and doc-set as **injected inputs** rather than
literals:

- **Ledger scope** is a `{{SCOPE}}` parameter (default `discovery`). Every `discovery.md` /
  `discovery-<mandate>.md` path in Steps 1–2 is written as `<scope>.md` /
  `<scope>-<mandate>.md`; `aid-discover` supplies `discovery`, `aid-update-kb` supplies its own
  scope (e.g. `update-kb`). `grade.sh` already takes the ledger path as an argument, so this is
  a pure substitution — no `grade.sh` change.
- **Doc-set** is supplied via the existing `{{ARTIFACTS}}`/`{{CONTEXT}}` injection (the brief's
  render inputs): the caller passes the set of KB docs the panel grades. `aid-discover` passes
  the full KB (`discovery.doc_set`); `aid-update-kb` passes only its touched/affected docs. The
  five mandates and the teach-back clean-context rule are doc-set-agnostic — they grade whatever
  doc-set is injected.

This is listed as an **f005 deliverable** (see Affected Components: `state-review.md`). f008
*consumes* the seam (it injects its own `<scope>` + affected-doc-set); it does not have to add
the parameterization. Boundary note: f005 wires `aid-discover`'s call site to inject
`discovery` + `discovery.doc_set` (preserving today's behaviour byte-for-byte); f008 wires its
own call site — f005 does not author `aid-update-kb`.

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
finding every cycle. The **teach-back verdict is not a separate stored value** — it is just
"any open `[TEACHBACK]` row?" read off the merged ledger; the `[TEACHBACK]` FAIL rows (per-term
and engine-narration alike) persist and are re-verified like any mandate's. This lets cycle-N
reviewers re-verify only their own mandate's rows while the merged ledger stays one file.

### Teach-Back Exit (the keystone hard gate)

#### The clean-context dispatch

Teach-back is **M4**, but it is special: it is the **keystone exit criterion** (FR-18,
REQUIREMENTS 1.4/1.10). It is a **clean-context `aid-reviewer`** dispatched with a *stricter*
context rule than the other four, and it grades along **two limbs**: a **per-term** limb (the
lexical "what is X?" quiz, derived from the candidate list) and a **non-lexical
engine-narration** limb (can the KB support a coherent end-to-end account of how the project
works), each an independent FAIL source:

- **Input = ONLY the KB** (`.aid/knowledge/*.md`) **+ the fixed question set**. It is **not**
  given the project source, the project-index, the candidate-concepts list, or any generation
  context. The whole point is to simulate "a fresh agent given only the KB" (AC1) — if the
  reviewer can reach the source it is not teaching *back from the KB*, it is re-deriving.
  This is the strongest form of `state-review.md`'s existing CLEAN-CONTEXT rule.
- **The fixed question set** is sourced **deterministically** from f004's
  `.aid/generated/candidate-concepts.md`: the question set is **"What is X?" for every
  cross-source `Term` row that the candidate table actually emits — including f004's NEW
  `synthesis`-tagged concepts** (f004 is adding a non-lexical conceptual-synthesis channel to
  `candidate-concepts.md`; those synthesis concepts become teach-back *targets*, not just
  harvest terms, so a tokenless load-bearing idea f004 surfaces as a synthesis concept is
  quizzed here) — **plus** the single fixed engine question **"Explain how this system works,
  in its own language."** which drives the **non-lexical engine-narration limb** below.
  Concretely, f004's
  table emits its top-`N` candidates (default 60) **plus** every candidate with spread `>= 3`,
  **plus** every `synthesis`-tagged concept. The teach-back set takes **every emitted row where
  `spread >= 2` OR `Source == synthesis`** — the **explicit two-clause selection rule**. The two
  clauses cover the two harvest channels:
  - **Lexical clause (`spread >= 2`):** the cross-source bar for ordinary harvest terms. All
    spread `>= 3` terms are always included (f004 guarantees emitting them); spread `== 2` terms
    are included **iff they fall within f004's emitted top-`N`**. A spread `== 2` term below the
    top-`N` cut is **not** in f004's table and is therefore **not** a teach-back question.
  - **Synthesis clause (`Source == synthesis`):** f004 emits `synthesis`-tagged rows with an
    **empty / `—` `Spread`** (they are tokenless — a non-lexical conceptual channel, so they
    have no cross-source token count). A pure numeric `spread >= 2` filter would therefore
    **drop every synthesis concept** — exactly the tokenless ideas the non-lexical teach-back
    limb exists to quiz. The `OR Source == synthesis` clause makes **every emitted synthesis
    concept a teach-back target regardless of (empty) spread**, so the per-term limb covers
    them too.

  The set is bounded by what the harvest deterministically emits — it never invents un-emitted
  terms. The lexical cap is f004's `--top`; if a future harvest needs deeper spread-2 coverage,
  raising f004's `--top` widens the set (the dependency, not a f005 change). Synthesis concepts
  are uncapped by `--top` (f004 emits them in full).
  Because the candidate list is mechanically generated and byte-reproducible (f004's NFR-3
  guarantee), the question set is a **fixed, repeatable** function of the emitted candidate
  table — the "teach-back as a fixed
  question set derived from the harvest" REQUIREMENTS 1.6/NFR-3 names. A new helper
  `kb-teachback-questions.sh` derives the question list from `candidate-concepts.md` (a
  trivial column-extract + the one fixed engine question) so the set is generated, not
  recalled.

#### Pass / fail (the hard gate)

The teach-back reviewer answers each question **using only the KB**, then self-scores each
answer against a binary bar. The two limbs are **independent FAIL sources** — a clean per-term
quiz does not excuse a broken engine-narration, and vice versa:

- **Per-term limb ("what is X?"):** PASS iff the KB lets the reviewer give the
  *definition-as-used-here* (not a generic dictionary definition) with a KB anchor. A concept
  it cannot define from the KB, or can only define generically, = a **FAIL item**. (This is the
  mechanical term-coverage half — every quizzed term comes from f004's deterministic candidate
  list, incl. `synthesis` concepts.)
- **Non-lexical engine-narration limb ("explain how this system works"):** PASS iff the
  reviewer can produce a **coherent end-to-end narration of the engine from the KB alone** —
  how the load-bearing parts connect and what the project *does* — in the project's native
  terms without reaching an undefined term. **This is a first-class FAIL source INDEPENDENT of
  the per-term quiz:** if the KB cannot support that narration, teach-back **FAILS even if every
  individual coined/synthesis term is defined** (the hardest 'Relative bus' case — a tokenless
  load-bearing idea that no single "what is X?" row would catch). A narration that stalls on an
  undefined native term, or that cannot assemble the parts into a working account, = a **FAIL
  item**. This limb is the **LLM-judgment** half of teach-back (vs the mechanical per-term
  coverage half) — see Judgment Boundary.
- **Verdict (single mechanism):** each FAIL item from EITHER limb is written as a `[HIGH]`
  `[TEACHBACK]` row in `discovery-teachback.md` naming the concept/flow that could not be
  explained (so FIX has an actionable target). There is **no separate verdict sentinel** — the
  teach-back verdict is **exactly "are any `[TEACHBACK]` rows open?"**: teach-back is PASS iff
  zero open `[TEACHBACK]` rows, FAIL otherwise.

#### How it combines with the grade (teach-back fail => not-Ready)

This is the keystone mechanism, and it is realized through **a single encoding** — the
`[HIGH]` `[TEACHBACK]` rows — not a separate boolean reconciled against the grade. Every
teach-back FAIL item (per-term OR engine-narration) is a `[HIGH]` `[TEACHBACK]` Pending row in
`discovery.md`. Because a `[HIGH]` row forces the **existing** `grade.sh` to **D**, any open
teach-back gap already drops the grade below `minimum_grade`, so the ordinary grade gate alone
holds REVIEW open:

```
READY  iff  grade(discovery.md) >= minimum_grade
         (any open [HIGH] [TEACHBACK] row forces grade <= D, so an open teach-back gap
          is, by construction, a not-Ready grade — no second gate, no AND to reconcile)
```

- The **severity grade** is computed by the **unchanged `grade.sh`** over the merged
  `discovery.md` (M1/M2/M3/M5 rows + the teach-back `[TEACHBACK]` rows).
- **The `[HIGH] [TEACHBACK]` rows ARE the keystone gate.** They integrate with `grade.sh`
  naturally: any Pending `[TEACHBACK]` row already forces the grade to `<= D`, which IS the
  hard gate REQUIREMENTS 1.4 demands ("Teach-back closure is THE keystone exit criterion — not
  severity distribution"). No separate boolean sentinel, no `AND`, and no reconciliation prose
  is needed — there is one mechanism, so there is nothing to keep in agreement.
- **Verdict for reporting** is simply read off the same rows: teach-back is FAIL iff any
  `[TEACHBACK]` row is open. The exit print and STATE update report the human-readable **pair**
  `Grade: <g> | Teach-back: <PASS|FAIL>` derived from that one fact — e.g. an open `[TEACHBACK]`
  row yields `Grade: D | Teach-back: FAIL -> NOT Ready (FIX teach-back gaps first)`. The
  `[TEACHBACK]` description tag also keeps these rows un-relaxable in practice: a reviewer
  cannot quietly downgrade a teach-back gap below `[HIGH]` without dropping the tag FIX targets.

#### Judgment Boundary (honest mechanical/LLM split)

To keep the honest floor explicit (REQUIREMENTS 1.6; NFR-3), teach-back's two limbs sit on
**opposite sides** of the mechanical/judgment line, and the spec does not pretend otherwise:

- **Per-term limb = mechanical-anchored.** The quizzed term set is f004's deterministic,
  byte-reproducible candidate list (incl. `synthesis` concepts) — the reviewer's only judgment
  is "is each listed term definable from the KB?", anchored to a fixed enumerated set, not free
  recall of which terms to ask about.
- **Engine-narration limb = LLM judgment, and is labelled as such.** "Can the KB support a
  coherent end-to-end account of the engine?" is **irreducibly an LLM judgment** — there is no
  mechanical oracle for narrative coherence, and the spec does NOT claim one. This is the
  deliberate, minimized judgment surface that lets teach-back catch the tokenless 'Relative
  bus' case the mechanical term-coverage half structurally cannot. It is the honest LLM-judgment
  limb of the gate (paired with calibration's "is this transcription?" as the feature's other
  named judgment call); everything else in f005 is mechanical/CI-able.

### Calibration Rubric Dimension (FR-19)

#### The new `review-rubric.md` section

A new section **"Calibration (summary vs transcription)"** is added to
`canonical/aid/templates/kb-authoring/review-rubric.md`, after the Full Primary rubric (it is
a Full-Primary-only dimension — meta/generated docs are not calibration-graded). It adds four
checks, each **evidence-anchored** against a mechanically-generated list (f004's salient terms
+ f001's `sources:`), so grading is repeatable, not pure recall (NFR-3):

| Check | Definition | Evidence anchor | Severity |
|-------|------------|-----------------|----------|
| **CAL-1 Transcription (too fat)** | The doc faithfully duplicates volatile source detail (full signatures, exhaustive enumerations) instead of synthesizing — a "rotting duplicate" (REQUIREMENTS 1.3, P4). | **f004's `closure-check.sh` output (c)** — the per-doc transcription-ratio hint (lexical overlap of the doc body vs each **local-file** `sources:` entry): a doc whose body is a near-verbatim restatement of such a file, with high overlap and no added *why*/*how-it-relates*, is transcription. **URL `sources:` -> N/A in (c) (skipped, not a finding)** — the offline helper cannot fetch them. | `[MEDIUM]` `[CAL-TRANSCRIPTION]` |
| **CAL-2 Hollowness (too thin)** | A "see file X" link-farm conveying no durable understanding (REQUIREMENTS 1.3, P4). | The doc's `sources:` vs body ratio: a doc that is mostly pointers with no synthesized cross-cutting content (no *why*, no *how parts interact*) is hollow. | `[MEDIUM]` `[CAL-HOLLOW]` |
| **CAL-3 Coverage-vs-source** | A load-bearing fact present in the doc's `sources:` is **absent** from the doc — "the source has Y and the doc forgot it" (P4, never caught today). | **f004's `closure-check.sh` output (b)** — the per-doc `sources:`-anchored coverage table `term \| doc \| anchoring-source \| present\|absent`: every `absent` row is a salient term anchored to this doc's local-file `sources:` that has no representation in the doc body. **URL `sources:` -> N/A in (b)** (offline helper cannot fetch them). | `[HIGH]` `[CAL-COVERAGE]` |
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
   `sources:` fact the doc forgot fails reverse (CAL-3 coverage-vs-source). *(Anchored to
   **f004's `closure-check.sh` output (b)** — the per-doc `sources:`-anchored coverage table
   `term | doc | anchoring-source | present|absent`: every `absent` row is a salient term that
   anchors to this doc's local-file `sources:` but is missing from the doc body. URL `sources:`
   resolve to N/A in (b), so they yield no reverse-coverage finding — same polarity and
   URL-N/A scoping f004 specifies.)*
3. **Transcription scan.** Is the doc a near-verbatim copy of its `sources:` (fat) rather than
   a synthesis? *(Mechanical signal: **f004's `closure-check.sh` output (c)** — the per-doc
   transcription-ratio hint, the lexical-overlap signal between the doc body and each
   **local-file** `sources:` entry; the reviewer confirms. `sources:` that are URLs are N/A in
   (c) — skipped by the offline helper, never flagged.)*

The forward/reverse framing is the "sweet spot" calibration REQUIREMENTS 1.3 commits to:
forward catches *too thin*, reverse + transcription-scan catch *too fat* and *coverage gaps*.

#### The mechanical evidence helper + new finding tags

- **Coverage + transcription evidence = f004's merged `closure-check.sh` (3-output oracle)**
  (NOT a f005 script). f004 is merging the former `kb-salient-coverage.sh` into its
  `closure-check.sh`, so that one oracle now emits a fully-specified **3-output** contract:
  - **(a) Ungrounded/un-closed concept set** (harvest + synthesis) — the M3 self-containment
    evidence.
  - **(b) Per-doc `sources:`-anchored coverage table** — schema
    **`term | doc | anchoring-source | present|absent`**: for each KB doc, which salient terms
    anchor to that doc's `sources:` and whether each is `present` in or `absent` from the doc
    body. An `absent` row is the CAL-3 / M3 coverage finding. This is what **M3 (concept-closure)
    coverage**, **CAL-3 (coverage-vs-source)**, and the **reverse-coverage** round-trip pass
    consume.
  - **(c) Per-doc transcription-ratio hint** — the lexical-overlap signal between the doc body
    and each local-file `sources:` entry. This is what **CAL-1 (transcription)** and the
    **transcription-scan** round-trip pass consume.
  f005 **consumes** these outputs; it ships **no** second coverage script. **`sources:`
  resolution scope (deterministic), owned by f004's oracle.** f001 permits a `sources:` entry to
  be a repo-relative path, a glob, a directory, OR a URL. Both the coverage table (b) and the
  transcription hint (c) are computed **only over `sources:` entries that resolve to local
  readable files** — plain paths, directories (their contained files), and globs (their matched
  files). A **URL `sources:` entry resolves to N/A in both (b) and (c): the offline coreutils
  helper cannot fetch it, so it is silently SKIPPED — not read, not a finding** (no-new-runtime,
  C1). URL-only-sourced facts are out of the mechanical coverage/transcription scope (the
  reviewer may still judge them, but the helper emits no coverage/transcription evidence for a
  URL). This is the "salient-term coverage check is scriptable" determinism lever (NFR-3): the
  reviewer grades against f004's outputs, it does not recall from memory. The mechanical
  assertions (planted uncovered term reported as an `absent` row; fully-covered fixture all
  `present`; byte-reproducible) are **f004's `closure-check.sh` test responsibility** — f005 does
  not re-test the oracle, it asserts only its own consumption surface (the question-set
  generator, below).
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
1. Five mandate reviewers (M1..M5) run in parallel, each writing discovery-<mandate>.md.
   M4 teach-back writes one [HIGH] [TEACHBACK] row per FAIL item — per-term FAILs AND
   engine-narration FAILs alike (NO separate verdict sentinel).
2. Orchestrator MERGES M1/M2/M3/M5 rows + M4's [TEACHBACK] FAIL-item rows into the single
   discovery.md (stable per-mandate # ID Mi-NNN/TB-NNN, [Mi]/[TEACHBACK] description prefix),
   then deletes the 5 transient scratch ledgers.
3. grade  = grade.sh discovery.md            # EXISTING grader, worst-severity-dominates,
                                              # counts Status in {Pending,Recurred} only.
                                              # Any open [HIGH] [TEACHBACK] row forces <= D.
4. READY iff grade >= minimum_grade          # single gate; an open teach-back gap is a [HIGH]
                                              # row, so it already makes grade < minimum_grade.
                                              # No second boolean, no AND to reconcile.
5. verdict (for reporting only) = FAIL iff any open [TEACHBACK] row in discovery.md, else PASS.
6. STATE + exit print report the PAIR: "Grade: <g> | Teach-back: <verdict> -> <Ready|NOT>".
```

This is fully consistent with the reviewer-ledger schema (one `<scope>.md`, 7-column table,
Status-filtered grading) and `grade.sh` (worst-severity dominates, modifier by count) — f005
adds **no new grade computation**; it adds an **input fan-out** (5 reviewers -> 1 ledger) and
encodes the keystone teach-back gate as `[HIGH] [TEACHBACK]` rows that the **existing** grader
already enforces (no separate boolean gate). The `minimum_grade` resolution is unchanged
(`read-setting.sh --skill discover --key minimum_grade --default A`).

### Affected Components

| Component | Path | Change |
|-----------|------|--------|
| REVIEW flow | `canonical/skills/aid-discover/references/state-review.md` | Rewrite Step 1 (single dispatch -> 5 parallel mandate dispatches, full-panel default + A3 sequential degradation; per-mandate scratch ledgers); rewrite Step 2 (aggregate 5 scratch ledgers -> single `<scope>.md`, run **unchanged** `grade.sh`; teach-back gate realized via the merged `[HIGH] [TEACHBACK]` rows — no separate verdict sentinel); Step 3 exit print/STATE report the **(grade, teach-back)** pair (teach-back derived from open `[TEACHBACK]` rows). Clean-context + contamination blocks preserved (stronger for teach-back). **Parameterize the ledger `<scope>` (default `discovery`) + the graded doc-set as injectable inputs** (`{{SCOPE}}` for the ledger path; `{{ARTIFACTS}}`/`{{CONTEXT}}` for the doc-set) so f008's `aid-update-kb` can reuse this flow with its own scope + affected-doc-set — **f005-owned, not a downstream assumption**. `aid-discover`'s call site injects `discovery` + `discovery.doc_set` (byte-identical to today). |
| Mandate prompt bodies | `canonical/skills/aid-discover/references/reviewer-prompt-*.md` (5 NEW: `-correctness`, `-anatomy`, `-concept-closure`, `-teachback`, `-calibration`) | Split today's monolithic `reviewer-prompt.md` into 5 focused per-mandate FOCUS bodies. M1 = today's Accuracy checklist; M2 = Completeness/Anatomy vs `document-expectations.md`; M3 = closure self-containment + `sources:`-anchored coverage (consumes f004's merged `closure-check.sh` outputs (a) ungrounded set + (b) per-doc coverage table `term \| doc \| anchoring-source \| present\|absent`; no f005 coverage script); M4 = teach-back (fixed question set + binary bar, two limbs: per-term + non-lexical engine-narration); M5 = Calibration round-trip. `reviewer-prompt.md` becomes a thin index pointing to the five (back-compat for any direct reader). **Output redirection (required):** today's `reviewer-prompt.md` instructs the reviewer to "Write the review results ... to STATE.md"; each of the 5 split FOCUS bodies MUST instead instruct its reviewer to write findings to its **own scratch ledger** `.aid/.temp/review-pending/discovery-<mandate>.md` (the 7-column ledger schema), NOT to STATE.md — the STATE.md write wording is dropped from every per-mandate body (the orchestrator, not the reviewers, touches STATE, per the ledger-schema "orchestrator only orchestrates" rule). |
| Teach-back question set | `canonical/skills/aid-discover/references/reviewer-prompt-teachback.md` + **NEW** `canonical/aid/scripts/kb/kb-teachback-questions.sh` | The fixed question set derived deterministically from `.aid/generated/candidate-concepts.md`: every **emitted** `Term` row where **`spread >= 2` OR `Source == synthesis`** (all spread `>= 3`, plus spread `== 2` within f004's top-`N` cap, **plus every `synthesis`-tagged concept regardless of its empty/`—` `Spread`**) -> "what is X?", + the one fixed engine question. The `OR Source == synthesis` clause is load-bearing: f004 sets synthesis rows' `Spread` empty, so a bare `spread >= 2` filter would drop exactly the tokenless concepts the non-lexical limb quizzes. Bounded by f004's emitted table (never invents un-emitted terms). ASCII bash; no LLM. |
| Review rubric | `canonical/aid/templates/kb-authoring/review-rubric.md` | Add the **Calibration** section (CAL-1..CAL-4 + the round-trip test) after Full Primary; add the new tags (`[CLOSURE-GAP]`, `[CAL-*]`, `[TEACHBACK]`) to the "Lint output -> severity mapping" table with their severities. The category routing + existing rubrics are unchanged. |
| Salient-coverage oracle (CONSUMED, not shipped) | f004's `closure-check.sh` (NOT a f005 file) | f005 ships **no** coverage script — `kb-salient-coverage.sh` is **dropped**. The M3/M5 coverage + transcription evidence is **f004's merged `closure-check.sh` 3-output contract**: (a) ungrounded/un-closed set, (b) per-doc `sources:`-anchored coverage table `term \| doc \| anchoring-source \| present\|absent` (URL -> N/A), (c) per-doc transcription-ratio hint (URL -> N/A). M3+CAL-3+reverse-coverage consume (b); CAL-1+transcription-scan consume (c). f005 consumes it; f004 owns + tests the one oracle. |
| CI — canonical suites | `tests/canonical/test-teachback-questions.sh` (NEW) + fixtures under `tests/canonical/fixtures/` | Assert the question-set generator extracts cross-source terms (incl. `synthesis` concepts) + the engine question deterministically + byte-reproducibly. Auto-discovered by `tests/run-all.sh`. The salient-coverage helper's tests are **f004's** (it owns that script now). |
| CI — ascii-only | `tests/canonical/test-ascii-only.sh` | Add **`kb-teachback-questions.sh`** to `SHIPPED_SCRIPTS` (C2). (No `kb-salient-coverage.sh` entry — f005 ships no coverage script.) |
| render-drift | `test.yml` job `render-drift` | No edit; stays green by editing canonical only + re-running `run_generator.py` (the 5 new reference snippets + **1** new script + rubric edit render to all 5 trees). |

### Constraints

- **C2 / Q2 — ASCII-only.** The **one** new script (`kb-teachback-questions.sh`) vendors into
  the install bundles -> ASCII-only bash (PS-5.1 N/A). Added to `test-ascii-only.sh`'s
  allow-list. (The salient-coverage oracle is f004's `closure-check.sh` — f004's ASCII
  responsibility, not f005's.) The new `review-rubric.md` / `reviewer-prompt-*.md` are markdown
  (not ASCII-gated, but kept ASCII for sibling consistency).
- **C1 / NFR-8 — no new runtime.** The one new script is pure coreutils (`grep`/`awk`/`sort`/
  `tr`) — the toolset f004's siblings already use. No embedding model, binary, MCP, or
  `python3`/`pwsh` escalation. The panel reuses the **existing** `aid-reviewer` agent and
  `grade.sh`; no new grading runtime. f005 also adds **no** coverage runtime — it consumes
  f004's existing `closure-check.sh`.
- **C3 / NFR-4 — render-drift green.** All authored files are canonical (the 5
  `reviewer-prompt-*.md`, `state-review.md`, `review-rubric.md`, the **1** `scripts/kb/*.sh`).
  Edit canonical only; re-run `python .claude/skills/generate-profile/scripts/run_generator.py`;
  commit regenerated `profiles/` (render-drift-full-generator precedent). **[SPIKE-C2]** —
  verify the renderer auto-emits the net-new `reviewer-prompt-*.md` reference files + the new
  `scripts/kb/kb-teachback-questions.sh` to all 5 trees (it enumerates the tree; expected yes);
  if an emission manifest pins the `aid-discover/references/` or `scripts/kb/` list, regen,
  never hand-place.
- **C5 / NFR-3 — deterministic, CI-testable + evidence-anchored.** f004's `closure-check.sh`
  coverage output, the question-set generator, and `grade.sh` are mechanical, stable-sorted,
  byte-reproducible (the coverage oracle asserted in f004's suite; the question-set generator
  in f005's new suite). The teach-back question set is a **fixed** input derived from f004's
  reproducible `candidate-concepts.md`; the irreducible judgment — teach-back's
  **engine-narration** limb ("did it explain the engine") and calibration's "is this
  transcription" — is the named, minimized LLM surface, anchored to the evidence list (NFR-3
  honest floor; see Judgment Boundary).
- **NFR-2 — wall-clock / parallel panel.** The 5 mandate dispatches run **in parallel** (one
  message, 5 dispatches), keeping the sequential critical path at one reviewer's wall-clock,
  not five (A3: degrade to sequential where parallel dispatch is unavailable). The evidence
  helpers are single sub-second script passes (no dispatch).
- **NFR-1 — cost.** The panel is 5 reviewer dispatches vs today's 1; this is the deliberate
  cost f006 *scales down* per path (brownfield-small/greenfield collapse to 1). For
  brownfield-large the extra reviewers are justified by complexity (REQUIREMENTS NFR-1); the
  mechanical evidence (f004's coverage oracle + f005's question-set script) is **zero-token**
  deterministic substrate, holding the LLM surface to the irreducible judgment.
- **C4 — human-gated.** REVIEW grades + flags; the human approval gate (`state-approval.md`)
  is unchanged. Teach-back FAIL (per-term or engine-narration) routes to FIX (or, for an
  ungroundable concept, to the f004 human-Q&A escape hatch), never auto-resolves.
- **C6 — content-isolation.** The new script is namespaced under `aid/scripts/kb/`; the panel's
  scratch ledgers live under the gitignored `.aid/.temp/review-pending/` (existing isolated
  tree); the merged ledger is the existing `<scope>.md` (`discovery.md` for `aid-discover`).

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-C1]** Calibration severity tuning — the `[MEDIUM]` vs `[HIGH]` cut for
  transcription/hollowness and the transcription-ratio threshold are **f012-calibrated**
  against the planted fixtures (AC6): the fixtures are the executable acceptance test for
  recall (flag the planted fat/thin/coverage-gap docs) vs precision (do not false-positive a
  well-calibrated doc). f005 sets the *shape* (which tag, which check); f012 tunes the *floor*.
- **[SPIKE-C2]** Net-new reference + script render — verify `run_generator.py` emits the 5
  net-new `reviewer-prompt-*.md` and the **1** net-new `scripts/kb/kb-teachback-questions.sh` to
  all 5 trees (it enumerates the tree); if any emission manifest pins the
  `aid-discover/references/` or `scripts/kb/` file list, update canonical + regen, never
  hand-place (render-drift-full-generator precedent).
- **[SPIKE-C3 — boundary, panel scaling]** The collapse of the full 5-mandate panel to fewer
  reviewers (down to 1 checklist-reviewer) for brownfield-small / greenfield is **f006**'s
  wiring. f005 authors the full-panel default and exposes the per-mandate dispatch list as the
  scaling unit; confirm with PLAN.md that f005 (mandates + full panel) lands before f006 wires
  the path->panel-size mapping (provide-before-consume).
- **[SPIKE-C4 — sequencing]** f005 consumes f004's `candidate-concepts.md` (incl. the NEW
  `synthesis`-tagged concepts) + the upgraded `domain-glossary.md` spine + **f004's merged
  `closure-check.sh` coverage output** (the salient/transcription evidence) and f001's per-doc
  `sources:` *schema* (which f004's oracle parses). f005 ships **no** coverage script of its own,
  so it has **no** direct f001 code dependency (the only f001 dependency, the `sources:` schema,
  is consumed transitively through f004's oracle). Confirm with PLAN.md that **f001 + f004 land
  before f005** (consume-after-define); if f005 is sequenced earlier, the coverage consumption
  degrades to "no `closure-check.sh` salient-coverage output yet -> empty evidence list" and
  teach-back degrades to "no question set -> engine-narration question only" (degrade-gracefully,
  never an error), but the essence-grading value is not realized until f004 lands. **Note the
  f005→f008 direction:** f005 *provides* the injectable-scope + injectable-doc-set seam that
  f008's `aid-update-kb` consumes; confirm with PLAN.md that f005 lands before f008 wires its
  call site (provide-before-consume).
- **[SPIKE-C5 — boundary, fixtures]** The Calibration AC6 fixtures (planted transcription /
  hollowness / coverage-gap docs) + the teach-back AC1/AC2 end-to-end validation are **f012**.
  f005's own canonical suites assert the *mechanical* halves (coverage helper, question-set
  generator); the *judgment* halves (does the reviewer flag a planted fat doc; does teach-back
  fail on a missing concept) are validated by f012's fixtures. Confirm the f005->f012
  dependency in PLAN.md.
