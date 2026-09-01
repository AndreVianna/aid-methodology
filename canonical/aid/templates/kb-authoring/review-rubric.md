# KB Authoring — Review Rubric

> Two things live here. **`§ Resolving review criteria` applies to every authored
> artifact** -- a `SKILL.md`, an `AGENT.md`, a template, a KB doc -- and is what any
> reviewer resolves before it starts. **The per-category rubrics below are KB-specific**:
> they are the `/aid-discover` REVIEW treatment, where the reviewer reads each KB doc's
> frontmatter, picks a rubric, and writes findings to the temp ledger at
> `.aid/.temp/review-pending/discovery.md`.

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

## Resolving review criteria

**Not KB-only.** The routing table above picks a rubric for a KB doc, but the criteria
resolution below applies to **every authored artifact a review touches** — a `SKILL.md`, an
`AGENT.md`, a template, a KB doc. Each one declares, or inherits, the list it must be true
against, so the reviewer checks a named list rather than improvising one.

**Resolve, in this order, and validate against the union:**

1. **Type** — read the file's path and frontmatter and resolve its **one** document type from
   the type registry in the project's conventions KB doc
   (`.aid/knowledge/authoring-conventions.md`).

   The registry's selectors are exhaustive **over the in-scope corpus** — the markdown under
   `canonical/skills/`, `canonical/agents/`, `canonical/aid/templates/` and `.aid/knowledge/`.
   For a file in that corpus this always resolves, and one resolving to no type, or to two, is
   itself a finding.

   **A file outside that corpus resolves to no type, and that is correct, not a finding.** A
   work artifact under `.aid/works/` is the case you will actually meet. Skip to step 2 with
   the type level empty; do not report the absence.
2. **Global** — every criterion the registry's criteria table marks `Applies to: *`.
3. **Type-level** — every criterion whose `Applies to` is the type resolved in step 1. None, if
   step 1 resolved none.
4. **File-class** — every criterion whose `Applies to` names a **file class** rather than a
   registry type, and whose membership test the file satisfies. The membership test is stated
   in that row's own `criterion` cell, so read it and apply it; the row exists precisely
   because these files cannot be given a type without breaking `G-07`, and cannot declare
   criteria on themselves.

   This is the level that reaches a work artifact. `G-14` and `G-15` bind the citation and
   quote rules to `REQUIREMENTS.md` (feature sections live in its section 11), `PLAN.md`
   (delivery definitions are its `### delivery-NNN` stanzas) and `tasks/*/DETAIL.md` under
   `.aid/works/`, none of which carries frontmatter or a type. Skipping this step is how a work artifact ends up reviewed against nothing.
5. **File-level** — the file's own `review-criteria:` frontmatter
   ([frontmatter-schema.md](frontmatter-schema.md)). Many artifacts carry none; that is normal.

**On an `id` collision the most specific wins** — file over file-class over type over global.
That is how an override applies, and how a `kind: exclude` entry cancels a `validate` criterion
inherited from above. File-class sits above type because a class is named by the criterion for
files a type cannot describe, so a class row is the more deliberate statement of the two.

**A `kind: exclude` criterion is binding.** It names something a reviewer would reasonably
check and must not, here. Reporting it anyway is a finding against the reviewer, not the file.

### Citing the criterion

**A finding names the criterion `id` as a prefix inside the ledger's existing `Description`
cell.** No column is added: the ledger keeps its 7-column shape
([reviewer-ledger-schema.md](../reviewer-ledger-schema.md)) and `grade.sh` its positional
parse.

```
| 3 | [HIGH] | Pending | canonical/skills/aid-plan/SKILL.md | 42 | SK-01 — dispatch table names a non-existent agent | ls canonical/agents/ |
```

- A **scope-prefixed** id (`G-`, `KB-`, `SK-`, …) resolves in the criteria table.
- An **`F-`** id resolves in the `review-criteria:` block of the file named in the `Doc` column.
- **A finding citing no id, or an id that resolves nowhere, is itself a defect** — it means the
  reviewer invented a criterion. Report the finding against the criterion, or do not report it.

**When the criterion was overridden**, record the **resolved severity and the overriding file's
`why`** in the finding's `Evidence` cell, so the reader sees which level won and why. The
`Evidence` cell is already inert to `grade.sh`, so this adds no machinery.

## Rubric: Full Primary (hand-authored)

The bulk of the review effort.

**Verify (per finding, log to temp ledger):**

1. **Frontmatter parses** — valid YAML; `kb-category:` and `source:` present; `intent:`
   non-empty. Parse failure = HIGH severity finding.
2. **Intent alignment** — does the doc's actual content match its declared `intent:`?
   Scope creep (content unrelated to intent) = MEDIUM finding. Coverage gap (intent
   declares something not actually covered) = MEDIUM finding.
3. **Declared review criteria hold against disk** — resolve the file's criteria through the
   three levels (below), then check each one against disk. A violation is a finding at **that
   criterion's own `severity`**, not at a severity this rubric fixes. See
   [`§ Resolving review criteria`](#resolving-review-criteria) — that section applies to **any**
   authored artifact, not only a KB doc, and item 3 is the KB-doc entry point into it.
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
7b. **No work references — zero tolerance, no exception** — grep the doc for
   `work-[0-9]{3}`. Any hit is a finding: a work id or folder path (`work-042`,
   `.aid/works/work-042-*/`, "specified by work-042", "added in work-042"), in prose,
   in a table cell, in a heading, or in frontmatter. Severity: **HIGH** — work folders
   are pruned when their work ships, so the cite is a dangling pointer by design, and
   it states a fact about project history rather than about the current sources. This
   check has **no load-bearing-anchor exception**; unlike check 7 it is not a judgment
   call. The fix is to name the durable artifact the work left on disk, or to drop the
   clause. See [principles.md](principles.md) P1(e).
   *Not a finding:* a real repository path that merely contains the substring (e.g. the
   test fixture `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-006-lite-sample/`),
   or shortcut/command syntax being illustrated (`` `/aid-execute work-001 task-001` ``).
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

**Severity scale.** The five levels are defined once, in
`canonical/aid/templates/grading-rubric.md § Issue Severities`; classify against that document
rather than against a copy here. Worst issue dominates the grade
(`grading-rubric.md § Grade Calculation`).

What this rubric adds is how the levels land **on a KB doc specifically** — the per-check
severities named in the numbered checks above (a false T1 concept claim is HIGH or CRITICAL, an
inline T3 count is MINOR per occurrence, and so on). Those are prices against the scale, not a
redefinition of it. Where the doc's own resolved criteria carry a `severity:`, that value wins:
it was set for that criterion.

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
   `**Last KB Review:**` lines), plus the
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
- A T2 `review-criteria:` entry may declare project-specific cardinality (not universal).
- Cross-doc consistency rules apply against other extensions of the same project,
  not against the canonical 16.

## Temp ledger format

`/aid-discover` REVIEW state writes findings to `.aid/.temp/review-pending/discovery.md`.

**The ledger's shape is defined once, in
[`reviewer-ledger-schema.md`](../reviewer-ledger-schema.md), and this document does not
restate it.** Read it there: the 7 columns and their order, the Severity and Status enums,
the status lifecycle across cycles, and the rule that the table is the **entire file** — no
title, no `## Findings` heading, no `## Notes` scratch space, no narrative.

That rule matters more than it looks. `grade.sh` parses each row **positionally**, reading
`cols[3]` as Severity and `cols[4]` as Status. A ledger written to any other column order
therefore does not fail loudly — it hands the grader a `Doc` path where a bracketed severity
tag should be, matches nothing, counts zero findings, and reports **`A+`**. A second copy of
the schema in this file is exactly how that happens, so there is none.

The Status lifecycle drives this state's own exit: FIX completes when no row is `Pending` or
`Recurred` (the two statuses `grade.sh` counts). Delete the file at DONE.

## Grade computation

Per `canonical/aid/templates/grading-rubric.md`, the grade is COMPUTED from the severity
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
- [frontmatter-schema.md](frontmatter-schema.md) — `kb-category`, `source`, `review-criteria` fields the rubric reads
