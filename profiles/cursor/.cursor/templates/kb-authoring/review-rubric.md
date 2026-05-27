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
8. **Citations resolve** — every `file.ext:LINE` cite must resolve to existing file
   and valid line. Broken cite = HIGH if widespread, MEDIUM otherwise.
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

Worst-issue dominates the grade (per `.cursor/templates/grading-rubric.md`).

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
2. **Top-of-file status fields are current** — for STATE.md: `**Current Grade:**`,
   `**User Approved:**`, `**Last KB Review:**`, etc., reflect the latest cycle's
   reality. Stale = MEDIUM (not HIGH — the values are skill-managed, not
   human-authored).
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

Per `.cursor/templates/grading-rubric.md`, the grade is COMPUTED from the severity
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

## See also

- [principles.md](principles.md) — the 7 principles, especially P3 (temp ledger), P4 (lint enforcement), P7 (read-only on repo)
- [tier-model.md](tier-model.md) — T1-T4 stability tiers referenced throughout the rubric
- [frontmatter-schema.md](frontmatter-schema.md) — `kb-category`, `source`, `contracts` fields the rubric reads
