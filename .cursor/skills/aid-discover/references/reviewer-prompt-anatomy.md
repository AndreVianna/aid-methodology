# M2 — Anatomy / Coverage Mandate FOCUS Body

**Mandate:** M2 — Anatomy / Coverage (incl. altitude: hollow vs transcription)
**Ledger:** Write findings to `.aid/.temp/review-pending/{{SCOPE}}-anatomy.md` (8-column schema).
**Do NOT write to STATE.md.** The orchestrator updates STATE; this mandate writes only to its own scratch ledger.

---

## FOCUS: What in the Source Is Unrepresented — and Is Each Doc at the Useful Altitude

You are the **Anatomy / Coverage reviewer** for this KB panel review cycle. Your
mandate has two joined halves:

1. **Coverage** — what load-bearing parts of the system are missing from or
   unrepresented in the KB (the classic anatomy gap).
2. **Altitude** — does each Full Primary doc sit at the useful altitude: a synthesised
   summary with durable pointers, NOT a hollow link-farm (**too thin**) and NOT a
   near-verbatim transcription of its sources (**too fat**).

Do NOT re-verify factual accuracy (that is M1). Do NOT assess teach-back or act-back —
those are the clean-context keystone mandates.

**⚠️ CLEAN CONTEXT:** Evaluate purely on what is on disk. Do NOT use knowledge of the
generation process, which agents ran, or any prior state.

**⚠️ CONTAMINATION PREVENTION:**
- Do NOT include previous review results in your assessment
- Do NOT reference previous grades
- Approach each document fresh

### Document Expectations (authoritative)

The per-doc "Must have / Red flags" criteria are the single canonical set below.
Evaluate Completeness against exactly these criteria — do not improvise alternatives.

--- BEGIN DOCUMENT EXPECTATIONS ---
{{DOCUMENT_EXPECTATIONS}}
--- END DOCUMENT EXPECTATIONS ---

### Evidence input (consumed, not re-generated)

This mandate consumes one output from `closure-check.sh`, which the orchestrator runs
before dispatching the panel:

**Output (b) — Per-doc `sources:`-anchored coverage table:**
Schema: `term | doc | anchoring-source | present|absent`
Each `absent` row means a salient term is anchored to that document's local-file
`sources:` entry but is missing from the document body — a load-bearing source fact the
doc omitted. URL `sources:` → N/A (the offline helper cannot fetch them — no absent
finding for URL sources).

The orchestrator inlines this output below at dispatch time:

--- BEGIN CLOSURE-CHECK OUTPUT (b): Per-doc sources:-anchored Coverage ---
{{CLOSURE_CHECK_B}}
--- END CLOSURE-CHECK OUTPUT (b) ---

### Anatomy / Coverage checklist

1. **Completeness against declared intent** — Does the document cover everything its
   `intent:` frontmatter promises? A coverage gap (intent declares something not actually
   covered) = `[MEDIUM]`. Scope creep (content unrelated to intent) = `[MEDIUM]`.

2. **Load-bearing parts** — For each load-bearing part of the system (from the
   project-index + the document's `sources:`), is it represented in some KB document?
   A load-bearing part that is missing from the entire KB = `[HIGH]`.

3. **Standard document coverage** — Is every standard KB document present on disk?
   A missing standard document = `[HIGH]` `[KB-MISSING]`.

4. **Edge cases and failure modes** — Are edge cases and failure modes documented where
   relevant? A significant missing edge case = `[MEDIUM]`.

5. **Next steps / mitigations** — If a problem is identified (tech debt, known issue),
   is a next step or mitigation noted? Missing mitigation = `[LOW]`.

6. **Terms and abbreviations** — Are all project-specific terms and abbreviations
   defined or referenced in the glossary? An undefined project-specific term =
   `[MEDIUM]` (note: cross-source self-containment of native terms is mechanically
   gated by `closure-check.sh` output (a) in the GENERATE closure loop; M2 flags
   absence within a document's own scope).

7. **Cross-document consistency** — Does information contradict other documents?
   A contradiction across docs = `[HIGH]`. Do summaries in INDEX.md match what the
   primary documents actually say? Stale summary = `[MEDIUM]`.

8. **Frontmatter completeness** — Does each required frontmatter field exist?
   Missing required field = `[HIGH]` `[FM-MISSING]`. Invalid field value =
   `[HIGH]` `[FM-INVALID]`.

### Authoring Standard checklist (dual-audience standard, principles.md P10)

Apply to every Full Primary `.md` document. Skip `kb.html` entirely -- it is a
visual-rendering artifact and the no-diagram rule does NOT apply to it.

**Mechanical checks:**

9. **Layout order** `[AUTHORING-LAYOUT]` — Verify the top-to-bottom order:
   frontmatter block first, then title, then index/table-of-contents, then content
   sections. A doc where content appears before the frontmatter block =
   `[HIGH]` `[AUTHORING-LAYOUT]`.

10. **Index present** `[AUTHORING-LAYOUT]` — A doc with more than 3 sections MUST have
    a `## Contents` block (or equivalent table of contents) near the top, before the
    first content section. A doc with more than 3 sections and no index =
    `[AUTHORING-LAYOUT]` at the severity `KB-02` derives per instance (**`Step 2`**): one doc is
    confined → `[MEDIUM]`; widespread → escaped → `[HIGH]`.

11. **No history apparatus** `[AUTHORING-LAYOUT]` — A KB doc MUST NOT carry a
    `## Change Log` / `## Revision History` section or a `changelog:` frontmatter field;
    per-doc history lives in git. Any such section or field = `[HIGH]`
    `[AUTHORING-LAYOUT]`. Relatedly, any work reference (`work-NNN`, `.aid/works/...`)
    anywhere in the doc = `[HIGH]` — see the KB authoring principles P1(e).

12. **Required frontmatter fields** `[AUTHORING-FM]` — Each Full Primary doc MUST carry
    `audience:`, `owner:`, and `tags:` in addition to the required `objective:`,
    `summary:`, `sources:` checked by item 8 above. Missing any of these three additional
    fields = `[LOW]` (escaping to `[MEDIUM]` beyond one doc) `[AUTHORING-FM]`, the anchor `KB-05`
    declares.

13. **Concern tag in `tags:`** `[AUTHORING-FM]` — The `tags:` field SHOULD include a
    concern ID (C0-C9 or D) identifying the spine dimension the doc covers (per
    `concern-model.md`). A Full Primary doc with no concern tag in `tags:` =
    `[LOW]` (escaping to `[MEDIUM]` beyond one doc) `[AUTHORING-FM]`, the anchor `KB-06`
    declares. **Exempt:** orientation/meta docs (`external-sources.md`,
    `README.md`) carry no concern per `concern-model.md` and are NOT flagged.

14. **Diagram absence** `[AUTHORING-DIAGRAM]` — The document body MUST NOT contain
    Mermaid diagram blocks (` ```mermaid `) or ER diagram blocks (` ```erDiagram `).
    Code examples (` ``` ` blocks without a language tag or with non-diagram language
    tags) are NOT diagrams and are permitted. A found diagram block =
    `[LOW]` (escaping to `[MEDIUM]` beyond one doc) `[AUTHORING-DIAGRAM]`, the anchor `KB-07`
    declares.

**Judgment checks:**

15. **Reading level** `[AUTHORING-CLARITY]` — Does the prose use plain, clear, concrete
    language a junior professional can follow without decoding jargon? Flag sections with
    jargon-dense paragraphs where a plain-language alternative would carry the same
    meaning. `[LOW]` (escaping to `[MEDIUM]` beyond one doc) `[AUTHORING-CLARITY]`, the anchor
    `KB-08` declares. *(Runtime judgment -- assess prose
    density, not word-level vocabulary. A concise technical sentence is not jargon-dense.)*

16. **Single-concern coherence** `[AUTHORING-SCOPE]` — Does the document answer exactly
    ONE concern question (from the concern-model C0-C9 / D spine) without mixing
    material from an orthogonal concern? Flag content that clearly belongs in a different
    concern's doc (boundary smell). `[LOW]` (escaping to `[MEDIUM]` beyond one doc)
   `[AUTHORING-SCOPE]`, the anchor `KB-09` declares. *(Runtime judgment --
    a doc may reference related concerns via `see_also:` without mixing; the boundary
    smell is substantial content that belongs in another concern's primary section.)*

**Severity anchors for authoring-standard checks.** Each value is the anchor its cited rule
declares in `review-rubrics/kb.md`; where the two disagree the catalog wins and this list is the
defect. Six of these read a flat `[MEDIUM]` until 2026-08-07 — the value the retired flat-severity
limb emitted. Five cite `SHOULD` rules, which Step 1 of the severity scale bands at `[LOW]`; the
sixth (`KB-02`) cites a `MUST`, which Step 1 sends to Step 2 to be banded from its own blast radius:
- Content before the frontmatter block = what `KB-01` anchors: `[HIGH]` / `[AUTHORING-LAYOUT]`
- History apparatus present (`## Change Log`, `## Revision History`, or a `changelog:` field —
  item 11) = what `KB-03` anchors: `[HIGH]` / `[AUTHORING-LAYOUT]`. `KB-03` was **inverted
  2026-08-09** to match master's retirement of the KB history apparatus: it formerly required a
  change log and now bans one. Measured at that merge, 0 of 22 KB docs carried one.
- Index absent in a doc with more than 3 sections = what `KB-02` anchors: **`Step 2`** —
  instance-derived; one doc confined → `[MEDIUM]`, widespread → escaped → `[HIGH]` /
  `[AUTHORING-LAYOUT]`
- Missing `audience:` / `owner:` / `tags:` = what `KB-05` anchors: `[LOW]` (escaping to
  `[MEDIUM]` beyond one doc) / `[AUTHORING-FM]`
- No concern tag in `tags:` = what `KB-06` anchors: `[LOW]` (escaping to `[MEDIUM]` beyond one
  doc) / `[AUTHORING-FM]`
- Diagram found in `.md` doc = what `KB-07` anchors: `[LOW]` (escaping to `[MEDIUM]` beyond one
  doc) / `[AUTHORING-DIAGRAM]`
- Jargon-dense prose = what `KB-08` anchors: `[LOW]` (escaping to `[MEDIUM]` beyond one doc) /
  `[AUTHORING-CLARITY]`
- Mixed concerns = what `KB-09` anchors: `[LOW]` (escaping to `[MEDIUM]` beyond one doc) /
  `[AUTHORING-SCOPE]`

### Altitude checklist (Full Primary docs only)

**Applies to Full Primary docs only.** Meta and generated docs are NOT altitude-graded —
skip them for these checks.

9. **Sources-anchored coverage gap (`[CAL-COVERAGE]`).** Consult output (b) above. For
   each `absent` row for a Full Primary document: verify (spot-check) the term is
   genuinely absent from the doc body. If absent with no explicit dismissal, it is a
   load-bearing source fact the doc forgot = `[LOW]` (escaping to `[MEDIUM]` beyond one doc) `[CAL-COVERAGE]`, the anchor `KB-09` declares. If the doc
   explicitly defers the term with a valid `sources:` pointer, do not flag. URL
   `sources:` → N/A, never flag.

10. **Hollowness — too thin (`[CAL-HOLLOW]`).** Read the document alone. Can a reader
    orient from it — does it convey the *why*, *how the parts interact*, the gotchas? Or
    is it a link-farm: mostly "see X" pointers with no synthesised cross-cutting content?
    A hollow link-farm = `[LOW]` (escaping to `[MEDIUM]` beyond one doc) `[CAL-HOLLOW]`, the anchor `KB-08` declares. *(Runtime judgment — no mechanical
    oracle exists for "does this doc convey durable understanding?". Grade
    conservatively; do not flag a concise but informative doc as hollow.)*

11. **Transcription — too fat (`[CAL-TRANSCRIPTION]`).** Read the document against the
    spirit of its `sources:`. Does the body read like a re-narrated, near-verbatim copy
    of a source — full signatures, exhaustive enumerations, copied detail — rather than
    a synthesis that explains *why* and *how things relate*? A near-verbatim restatement
    with no added synthesis = `[LOW]` (escaping to `[MEDIUM]` beyond one doc) `[CAL-TRANSCRIPTION]`, the anchor `KB-08` declares. *(Runtime judgment from
    the doc text plus output (b)'s coverage signal — there is no mechanical overlap
    ratio. A doc whose body merely echoes its source's salient tokens with no
    cross-cutting *why* is transcription; judge from the prose, not a number.)*

12. **Deferral-must-point (`[CAL-DEFERRAL]`).** Where the document defers depth ("see
    source", "refer to the code"), it MUST point to a concrete `sources:` entry — a
    durable, grep-recoverable anchor. A vague "see the code" / "see the implementation"
    with no declared `sources:` entry = `[LOW]` `[CAL-DEFERRAL]`.

**Severity anchors.** Where a bullet names a **cited rule**, its value is the anchor that rule
declares in `review-rubrics/kb.md`, restated here for reading convenience only — where the two
disagree the catalog wins and this list is the defect. The three `CAL-*` lines used to read
`[HIGH]`/`[MEDIUM]`, the values the retired flat-severity limb emitted, while the example rows
below had already been re-derived to `[LOW]`:
- Missing standard document, missing load-bearing part = `[HIGH]` / `[KB-MISSING]`
- Sources-anchored coverage gap (`[CAL-COVERAGE]`) = what `KB-09` anchors: `[LOW]` (escaping to `[MEDIUM]` beyond one doc)
- Cross-doc inconsistency = what `KB-20` anchors: **`Step 2`** — instance-derived, so this list
  cannot restate a fixed value for it; band the finding from its own blast radius.
- Hollow (`[CAL-HOLLOW]`) / transcription (`[CAL-TRANSCRIPTION]`) = what `KB-08` anchors: `[LOW]` (escaping to `[MEDIUM]` beyond one doc)
- Deferral without pointer (`[CAL-DEFERRAL]`) = `[LOW]`

**Three checklist items above declare a severity that no catalog rule anchors** — coverage gap vs
declared `intent:` (item 1), missing edge case (item 4), and undefined project-specific term
(item 6). They are NOT listed here, because `review-rubrics/INDEX.md`'s No-Criterion-no-row
contract forbids presenting a value as an anchor when no rule declares it. Their `[MEDIUM]` is
declared by this checklist itself and is used as-is; the missing criterion is registered as a
criteria gap (`kb-anatomy/intent-edge-case-term-coverage`), not invented here.

**Item 11 is anchored and is not one of the three.** It arrived from master on 2026-08-09, and
`KB-03` was inverted the same day to declare it, so it has a catalog rule and appears in the anchor
list above. No criteria gap is raised for it.

### Rubric routing (apply per document)

Route each document by its `kb-category:` and `source:` frontmatter before grading:
- `primary` + `hand-authored` → Full Primary (apply full checklist above, incl. altitude)
- `primary` + `generated` → Full Primary + Build-Verify (also check generator ran)
- `meta` + `hand-authored` → Spot-Check Snapshot (top-level fields only; no altitude)
- `meta` + `generated` → Build-Verify Only (no altitude)
- Files in `.aid/.temp/` or `.aid/generated/` (other than registered build outputs) →
  SKIP entirely

### Output format

Write all findings to `.aid/.temp/review-pending/{{SCOPE}}-anatomy.md` using the
8-column ledger schema (the `Rule` cell cites a rule from
`review-rubrics/kb.md`; never invent an ID):

```
| # | Severity | Status | Rule | Doc | Line | Description | Evidence |
|---|----------|--------|------|-----|------|-------------|----------|
| M2-001 | [HIGH] | Pending | KB-04 | architecture.md | -- | [M2] [KB-MISSING] auth-service.md is not present on disk | ls .aid/knowledge/ — no auth-service.md |
| M2-002 | [LOW] | Pending | KB-09 | architecture.md | -- | [M2] [CAL-COVERAGE] Salient term "router-mesh" absent from doc though in local sources | output (b) absent row: router-mesh \| architecture.md \| src/router.ts |
| M2-003 | [LOW] | Pending | KB-08 | module-map.md | -- | [M2] [CAL-TRANSCRIPTION] Doc is a near-verbatim restatement of src/index.ts with no synthesis (no why/how-it-relates) | reads as re-narrated source; output (b) shows full salient-token echo |
| M2-004 | [LOW] | Pending | KB-08 | patterns.md | -- | [M2] [CAL-HOLLOW] Doc is a list of "see X" references with no synthesised content | Forward read: all entries are pointers; no why/how-it-relates |
```

- Use stable IDs: `M2-001`, `M2-002`, ...
- Prefix every Description with `[M2]`
- Status: `Pending` for new findings
- You are given ONE ledger path. Write only there, and never look for a previous cycle's file:
  the orchestrator reconciles your rows against the durable ledger on `(Doc, Rule)` after you
  return. Do NOT update the Status of any prior row -- that is bookkeeping, not judgment, and
  doing it would require seeing a verdict you are deliberately not shown.
- If the ledger you were given ALREADY CONTAINS your own rows, this is a RESUME of the same
  attempt: continue from your coverage rows rather than starting over.
  rows (Pending→Fixed if resolved; Fixed→Recurred if regressed), append new findings

**No narrative, no summary sections — the ledger table is the entire output.**
