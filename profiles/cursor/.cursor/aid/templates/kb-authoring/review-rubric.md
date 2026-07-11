# KB Authoring — Review Rubric

> Per-category review treatment for `/aid-discover` REVIEW state. The reviewer reads
> each KB doc's frontmatter, picks the rubric below, and produces findings to the
> temp ledger at `.aid/.temp/review-pending/discovery.md`.

## Routing — which rubric applies

The combination of `kb-category:` and `source:` determines which rubric to apply:

| kb-category | source | Rubric |
|-------------|--------|--------|
| primary | hand-authored | **Full Primary** — most rigorous |
| primary | generated | **Full Primary + Build-Verify** — content reviewed AND generator confirmed to have run. Applies to `INDEX.md` (the RAG-navigation index). |
| meta | hand-authored | **Spot-Check Snapshot** — current correctness of top-level fields only |
| meta | generated | **Build-Verify Only** — confirm script ran; skip content grading. Applies to `metrics.md`, `project-index.md`. |
| extension | hand-authored | **Extension-Scope** — same as primary but flagged as outside the canonical 16 |
| extension | generated | **Extension Build-Verify** — confirm script ran; spot-check content for extension-scope correctness. Rare. |

Files in `.aid/.temp/` and `.aid/generated/` (other than registered build outputs) are
SKIPPED entirely — not reviewed, not graded.

## Rubric: Full Primary (hand-authored)

The bulk of the review effort.

**Verify (per finding, log to temp ledger):**

1. **Frontmatter parses** — valid YAML; `kb-category:` and `source:` present; `intent:`
   non-empty. Parse failure = HIGH severity finding.
2. **Intent alignment** — does the doc's actual content match its declared `intent:`?
   Scope creep (content unrelated to intent) = MEDIUM finding. Coverage gap (intent
   declares something not actually covered) = MEDIUM finding.
3. **Contracts hold against disk** — for each entry in `contracts:`, derive the
   asserted fact from disk and compare. Mismatch = HIGH finding.
4. **T1 Concept claims correct** — for each pattern, definition, or architectural
   law, validate against the canonical source. Incorrect concept = HIGH or CRITICAL.
5. **T2 Structure claims correct** — for each cardinality / schema / fixed-list
   assertion, validate against disk. Mismatch = HIGH.
6. **No T3 inline** — any line-count, byte-count, function-count, etc. inlined in the
   body is a finding. Severity: MINOR per occurrence, MEDIUM if widespread.
7. **No T4 inline** — any date stamp, "verified during cycle-N", "as of YYYY-MM-DD"
   inline is a finding. Severity: MINOR per occurrence, MEDIUM if widespread.
   *Exception:* T4 markers that are LOAD-BEARING semantic anchors (e.g.,
   "post-FR2 retirement") are allowed — judgment call.
8. **Citations are durable + resolve** — every cited file must exist, and any anchor
   (symbol / heading / unique string) must be findable in it. **Do NOT verify line
   numbers:** a bare `file.ext:LINE` cite is a P1(d) volatile pointer — flag it for
   replacement with a grep-recoverable anchor rather than checking whether the line is
   still correct. Cite to a missing file or unfindable anchor = HIGH if widespread,
   MEDIUM otherwise.
9. **Cross-doc consistency** — claims that overlap with other primary docs must agree.
   Contradiction across docs = HIGH.
10. **Q-ID / H-ID references resolve** — every `Q##` / `H##` mentioned must exist in
    `STATE.md` (Q-IDs) or `tech-debt.md` (H-IDs). Dangling reference = MEDIUM.

**Severity scale** (matches reviewer convention):

| Severity | Meaning | Typical examples |
|----------|---------|------------------|
| CRITICAL | False claim that could cause downstream wrong decision | Wrong pattern, wrong contract, missing key doc |
| HIGH | Significant gap or inaccuracy | Contract mismatch, broken widespread citation, cross-doc contradiction |
| MEDIUM | Noticeable inaccuracy, but agent could work around | Dangling Q-ID, single broken citation, scope creep |
| LOW | Minor inaccuracy, low blast radius | Awkward phrasing of an otherwise-correct claim |
| MINOR | Style / convention issue | Single inline T3 or T4 marker; trailing whitespace |

Worst-issue dominates the grade (per `.cursor/aid/templates/grading-rubric.md`).

## Altitude checks (folded into the M2 Anatomy mandate) — Full Primary only

**Applies after the Full Primary checklist, as part of the M2 Anatomy / Coverage mandate.**
Meta and generated docs are not altitude-graded. The altitude dimension grades whether each
Full Primary doc sits at the useful altitude — summary plus pointer — rather than transcribing
its sources (too fat) or deferring to them without synthesising (too thin). There is **no
separate Calibration mandate** and **no mechanical transcription-ratio**: the M2 Anatomy
reviewer makes these judgments from the doc text plus `closure-check.sh` output (b)'s coverage
table.

| Check | Definition | Evidence anchor | Severity |
|-------|------------|-----------------|----------|
| **CAL-1 Transcription (too fat)** | The doc faithfully duplicates volatile source detail (full signatures, exhaustive enumerations) instead of synthesising — a "rotting duplicate". | **Runtime LLM judgment from the doc text** (corroborated by **`closure-check.sh` output (b)**'s salient-token coverage signal): a doc whose body re-narrates a local source near-verbatim, with no added *why* / *how-it-relates*, is transcription. There is no mechanical overlap ratio — the reviewer judges from the prose. **URL `sources:` cannot be read offline → not a transcription finding.** | `[MEDIUM]` `[CAL-TRANSCRIPTION]` |
| **CAL-2 Hollowness (too thin)** | A "see file X" link-farm conveying no durable understanding. | The doc's `sources:` vs body ratio: a doc that is mostly pointers with no synthesised cross-cutting content (no *why*, no *how parts interact*) is hollow. **Runtime judgment — NOT a mechanical assertion.** | `[MEDIUM]` `[CAL-HOLLOW]` |
| **CAL-3 Coverage-vs-source** | A load-bearing fact present in the doc's `sources:` is absent from the doc — "the source has Y and the doc forgot it". | **`closure-check.sh` output (b)** — per-doc `sources:`-anchored coverage table `term | doc | anchoring-source | present|absent`: every `absent` row is a salient term anchored to this doc's local-file `sources:` that has no representation in the doc body. **URL `sources:` → N/A in (b)** — offline helper cannot fetch them. | `[HIGH]` `[CAL-COVERAGE]` |
| **CAL-4 Deferral-must-point** | Where the doc defers depth ("see source"), it MUST point to a concrete `sources:` entry (durable, grep-recoverable anchor — the existing P1(d) anchor convention), not a vague "see the code". | The doc's `sources:` list: every deferral phrase must resolve to a declared source. | `[LOW]` `[CAL-DEFERRAL]` |

**Mechanical vs judgment boundary.**
CAL-3 (coverage-vs-source) is **mechanical-anchored**: the M2 reviewer grades against
`closure-check.sh` output (b)'s `absent` rows, not free recall. CAL-1 (transcription) and
CAL-2 (hollowness) are **runtime LLM judgment**: no mechanical oracle scores "does this doc
re-narrate its source?" or "does this doc convey durable understanding?" — these are the
named, minimised judgment surfaces the M2 reviewer owns (output (b) corroborates CAL-1 but
does not score it).

**Severity rationale.** CAL-3 coverage-vs-source is `[HIGH]` (same weight as a broken
contract — a load-bearing source fact absent from the doc is a genuine gap). CAL-1 and
CAL-2 are `[MEDIUM]` (altitude nits that do not misstate facts). CAL-4 is `[LOW]` (a
deferral without a concrete pointer is a usability issue, not an accuracy gap).

### Round-trip test (operationalisation)

The four checks are run by the M2 Anatomy reviewer as part of its altitude pass per Full
Primary doc:

1. **Forward orientation.** From the doc alone (summary side), can a reader orient — get the
   *why* / *how parts interact* / the gotchas? A doc that is all pointers with no synthesised
   content fails forward (**CAL-2 hollow**). *(Judgment: the reviewer reads the doc, no source.)*

2. **Reverse coverage.** From the doc's `sources:` (the authoritative side), are the
   load-bearing facts and salient terms that those sources contain represented in the doc?
   A `sources:` fact the doc forgot fails reverse (**CAL-3 coverage-vs-source**). *(Anchored to
   `closure-check.sh` **output (b)** — the per-doc `sources:`-anchored coverage table
   `term | doc | anchoring-source | present|absent`: every `absent` row is a salient term that
   anchors to this doc's local-file `sources:` but is missing from the doc body. URL `sources:`
   resolve to N/A in (b) — they yield no reverse-coverage finding.)*

3. **Transcription scan.** Is the doc a near-verbatim copy of its `sources:` (fat) rather than
   a synthesis? *(Runtime judgment from the prose: does the doc body re-narrate a local source —
   full signatures, exhaustive enumerations, copied detail — instead of explaining *why* and
   *how things relate*? Output (b)'s salient-token coverage corroborates, but there is no
   mechanical overlap ratio. URL `sources:` cannot be read offline — never flagged.)*

Forward orientation catches *too thin*; reverse coverage and transcription scan catch *too fat*
and *coverage gaps* — the sweet spot calibration the KB methodology commits to.

## Rubric: Full Primary + Build-Verify (generated, INDEX.md-class)

Same as Full Primary, PLUS:

11. **Generator was run since last upstream change** — check mtime of generated file
    vs mtime of any input the generator reads. Stale = HIGH. (Implementation: lint
    re-runs the generator and diffs the output against current file; non-empty diff
    = HIGH.)
12. **AUTO-GENERATED marker present** — file must begin with the standard comment
    block declaring its generator. Missing marker = MEDIUM.
13. **No manual edits between AUTO-GENERATED markers** — if the file has a "manual
    addendum" section explicitly outside the generated boundary, that section gets
    Full Primary treatment; everything else gets generator-output-only review.

## Rubric: Spot-Check Snapshot (meta, hand-authored)

Used for `STATE.md` and `README.md`. (`INDEX.md` is `primary` + `generated` per [frontmatter-schema.md](frontmatter-schema.md) and routes to Full Primary + Build-Verify instead.)

The doc is the skill's working ledger. History entries grow forever; this is
expected. The reviewer ONLY checks:

1. **Frontmatter parses** + `kb-category: meta` declared.
2. **Frontmatter run-state scalars are current** — for STATE.md: `kb_grade`,
   `kb_status`, `last_kb_review`, `summary_approved`, `last_summary` (relocated
   from the old header-blockquote `**Current Grade:**`/`**Status:**`/
   `**Last KB Review:**` lines by work-003-state-schema task-001/004), plus the
   still-header-blockquote `**User Approved:**` doc-set-approval line, all
   reflect the latest cycle's reality. Stale = MEDIUM (not HIGH — the values
   are skill-managed, not human-authored).
3. **Pending Q&A entries are reachable** — every `**Status:** Pending` entry in
   STATE.md must be surfacable by `aid-discover` Q-AND-A state. Format-broken
   entries = HIGH.
4. **No content beyond meta role** — meta docs shouldn't carry primary knowledge.
   If primary knowledge has migrated into a meta doc, FLAG as scope drift (MEDIUM).

Everything else (history rows, calibration log, review history) is **not graded**.

## Rubric: Build-Verify Only (meta + generated)

For `.aid/generated/metrics.md`, `.aid/generated/project-index.md`, and similar.

1. **Frontmatter parses** + `source: generated` + `generator:` present.
2. **AUTO-GENERATED marker present** at file top.
3. **Generator ran cleanly** — re-run the generator script; exit 0; output matches
   current file. Non-zero exit or diff = HIGH.
4. **Skip all content grading.** Even spot-checks are unnecessary — the script is
   the authority.

## Rubric: Extension-Scope

Same as Full Primary, but:

- The doc is FLAGGED in the review summary as "extension" (not part of the canonical
  16 contract).
- T2 contracts may declare project-specific cardinality (not universal).
- Cross-doc consistency rules apply against other extensions of the same project,
  not against the canonical 16.

## Temp ledger format

`/aid-discover` REVIEW state writes findings to
`.aid/.temp/review-pending/discovery.md`:

```markdown
# Review Pending — discovery cycle N

> Auto-generated by /aid-discover REVIEW. Edited by FIX as items are resolved.
> Delete this file when empty.

## Findings

| # | Severity | Doc | Line | Tier | Status | Claim |
|---|----------|-----|------|------|--------|-------|
| 001 | HIGH | example-a.md | 42 | T2 | pending | Cardinality contract mismatch — declared count is N but disk count is M |
| 002 | MINOR | example-b.md | 105 | T4 | pending | Inline date stamp in primary doc body (banned per tier-model.md T4) |
| 003 | MEDIUM | example-c.md | 18 | T1 | deferred | Concept claim contradicts canonical source — defer to next cycle |

## Notes

(reviewer scratch space)
```

Status values: `pending` | `in-progress` | `fixed` | `deferred`.
When all entries are `fixed` or `deferred`, FIX state completes. Delete the file.

## Grade computation

Per `.cursor/aid/templates/grading-rubric.md`, the grade is COMPUTED from the severity
distribution, not judged. Worst issue dominates. Auto-generated and meta files do not
contribute findings to the grade (they appear in the summary but are filtered out
of the grade calculation).

## Project-specific extension

A project may add `.aid/knowledge/.review-checklist.md` to extend this rubric:

```yaml
---
kb-category: meta
source: hand-authored
intent: |
  Project-specific review checklist additions, supplementing the canonical rubric.
---

## Additional checks for primary docs in this project

- (project-specific check 1)
- (project-specific check 2)

## Files exempt from review (project-specific)

- path/to/some/file.md — reason
```

Lint discovers this file and merges its rules with the canonical rubric.

## Lint output → severity mapping

The `aid-reviewer` sub-agent emits findings in the canonical format
`[SEVERITY] [TAG] <description>` so the orchestrator and any downstream
tool can extract severity programmatically without a translation table.

| Lint tag | Severity | Meaning |
|---|---|---|
| `[FM-MISSING]` | HIGH | Frontmatter field absent (kb-category / source / intent / generator / AUTO-GENERATED marker missing; or required new field absent: objective / summary / sources) |
| `[FM-INVALID]` | HIGH | Frontmatter field has invalid value (e.g., kb-category not in primary/meta/extension; or required new field has malformed shape: objective/summary not a single-line scalar; sources/tags/see_also/audience not a list; approved_at_commit not hex) |
| `[KB-MISSING]` | HIGH | A standard primary KB document is not present on disk |
| `[GEN-MISSING]` | HIGH | A registered generated file (per `generated-files.txt`) does not exist; the build command needs to be run |
| `[CLOSURE-GAP]` | HIGH | A salient cross-source term (from `closure-check.sh` output (a)) is neither grounded in the KB nor explicitly dismissed — a coined or synthesis term with no KB definition. Enforced mechanically by the GENERATE closure loop's termination oracle (`state-closure.md` DETECT); not a panel mandate. |
| `[CAL-TRANSCRIPTION]` | MEDIUM | Doc is a near-verbatim transcription of its `sources:` (too fat) rather than a synthesis — a runtime M2 Anatomy judgment from the doc text, corroborated by `closure-check.sh` output (b)'s salient-token coverage (no mechanical overlap ratio) |
| `[CAL-HOLLOW]` | MEDIUM | Doc is a link-farm that conveys no durable understanding (too thin) — a `sources:` vs body ratio finding; runtime LLM judgment, not a mechanical assertion |
| `[CAL-COVERAGE]` | HIGH | A salient term anchored to this doc's local-file `sources:` is absent from the doc body — an `absent` row in `closure-check.sh` output (b); URL sources are N/A |
| `[CAL-DEFERRAL]` | LOW | Doc defers depth ("see source") without pointing to a concrete `sources:` entry — a deferral phrase that does not resolve to a declared source |
| `[TEACHBACK]` | HIGH | A teach-back FAIL item — the KB does not support defining the cited concept from the KB alone (per-term limb), or the KB cannot support a coherent engine-narration (non-lexical limb); any open `[TEACHBACK]` row forces grade <= D |
| `[ACTBACK]` | HIGH | An act-back FAIL item — using ONLY the KB, the agent cannot produce a correct plan for the representative change (plan-correctness limb), or it had to assume a convention, guess an invariant, hit an un-anticipated gotcha, or reach for source for a contract (sufficiency limb); any open `[ACTBACK]` row forces grade <= D |

**`[FM-MISSING]` and `[FM-INVALID]` cover the new required fields (P6 carve-out) — no
new lint tag is introduced.** The required new fields (`objective:`, `summary:`,
`sources:`) are graded for presence/shape by `lint-frontmatter.sh` using these existing
tags. Specifically:

- **Presence check** (required for `source: hand-authored`, `kb-category: primary` or
  `extension`, when the doc already carries any of the new fields): `objective:` and
  `summary:` non-empty, `sources:` present as a YAML list. Missing → `[FM-MISSING]` HIGH.
- **Shape check**: `objective:`/`summary:` are single-line scalars; list fields are lists;
  each `sources:` entry is a path/glob/URL; `approved_at_commit:` (if present) is 7-40
  lowercase hex. Malformed → `[FM-INVALID]` HIGH.

**Scope:** `meta` docs and `source: generated` docs are **skipped** by this lint.
Docs carrying NONE of the new fields are treated as pre-migration and skipped (soft-skip
until f011; see [principles.md](principles.md) P6 and [frontmatter-schema.md](frontmatter-schema.md) for the
coexistence/migration contract).

**Optional fields stay exempt.** `tags:`, `see_also:`, `owner:`, `audience:` (when
present) are shape-checked but NOT required; their absence is never a lint error.
Prose quality of `objective:`/`summary:` is also exempt (shape only, not semantics).

All current lint findings are HIGH severity by the rubric's check-1/3/5/8
rules (frontmatter parse failure, contract mismatch, T2 structure mismatch,
broken citation). If future lint checks emit MEDIUM/LOW findings, the
emission MUST prefix the appropriate severity tag — never emit a bare
`[TAG]` without a severity prefix.

## See also

- [principles.md](principles.md) — the 9 principles, especially P3 (temp ledger), P4 (lint enforcement), P7 (read-only on repo), P9 (resolved items leave no trace)
- [tier-model.md](tier-model.md) — T1-T4 stability tiers referenced throughout the rubric
- [frontmatter-schema.md](frontmatter-schema.md) — `kb-category`, `source`, `contracts` fields the rubric reads
