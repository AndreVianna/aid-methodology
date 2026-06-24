# M2 — Anatomy / Coverage Mandate FOCUS Body

**Mandate:** M2 — Anatomy / Coverage (incl. altitude: hollow vs transcription)
**Ledger:** Write findings to `.aid/.temp/review-pending/{{SCOPE}}-anatomy.md` (7-column schema).
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
   sections, then `## Change Log` last. A doc where content appears before the
   frontmatter block, or where content follows the Change Log section, or where the
   Change Log is absent = `[HIGH]` `[AUTHORING-LAYOUT]`.

10. **Index present** `[AUTHORING-LAYOUT]` — A doc with more than 3 sections MUST have
    a `## Contents` block (or equivalent table of contents) near the top, before the
    first content section. A doc with more than 3 sections and no index =
    `[MEDIUM]` `[AUTHORING-LAYOUT]`.

11. **Change Log last** `[AUTHORING-LAYOUT]` — The `## Change Log` section (or equivalent
    heading) MUST be the final section. Any section heading appearing after the Change
    Log heading = `[HIGH]` `[AUTHORING-LAYOUT]`.

12. **Required frontmatter fields** `[AUTHORING-FM]` — Each Full Primary doc MUST carry
    `audience:`, `owner:`, and `tags:` in addition to the required `objective:`,
    `summary:`, `sources:` checked by item 8 above. Missing any of these three additional
    fields = `[MEDIUM]` `[AUTHORING-FM]`.

13. **Concern tag in `tags:`** `[AUTHORING-FM]` — The `tags:` field SHOULD include a
    concern ID (C0-C9 or D) identifying the spine dimension the doc covers (per
    `concern-model.md`). A Full Primary doc with no concern tag in `tags:` =
    `[MEDIUM]` `[AUTHORING-FM]`. **Exempt:** orientation/meta docs (`external-sources.md`,
    `README.md`) carry no concern per `concern-model.md` and are NOT flagged.

14. **Diagram absence** `[AUTHORING-DIAGRAM]` — The document body MUST NOT contain
    Mermaid diagram blocks (` ```mermaid `) or ER diagram blocks (` ```erDiagram `).
    Code examples (` ``` ` blocks without a language tag or with non-diagram language
    tags) are NOT diagrams and are permitted. A found diagram block =
    `[MEDIUM]` `[AUTHORING-DIAGRAM]`.

**Judgment checks:**

15. **Reading level** `[AUTHORING-CLARITY]` — Does the prose use plain, clear, concrete
    language a junior professional can follow without decoding jargon? Flag sections with
    jargon-dense paragraphs where a plain-language alternative would carry the same
    meaning. `[MEDIUM]` `[AUTHORING-CLARITY]`. *(Runtime judgment -- assess prose
    density, not word-level vocabulary. A concise technical sentence is not jargon-dense.)*

16. **Single-concern coherence** `[AUTHORING-SCOPE]` — Does the document answer exactly
    ONE concern question (from the concern-model C0-C9 / D spine) without mixing
    material from an orthogonal concern? Flag content that clearly belongs in a different
    concern's doc (boundary smell). `[MEDIUM]` `[AUTHORING-SCOPE]`. *(Runtime judgment --
    a doc may reference related concerns via `see_also:` without mixing; the boundary
    smell is substantial content that belongs in another concern's primary section.)*

**Severity anchors for authoring-standard checks:**
- Layout order violation (content before frontmatter, content after Change Log, no Change
  Log) = `[HIGH]` / `[AUTHORING-LAYOUT]`
- Index absent in a doc with more than 3 sections = `[MEDIUM]` / `[AUTHORING-LAYOUT]`
- Missing `audience:` / `owner:` / `tags:` = `[MEDIUM]` / `[AUTHORING-FM]`
- No concern tag in `tags:` = `[MEDIUM]` / `[AUTHORING-FM]`
- Diagram found in `.md` doc = `[MEDIUM]` / `[AUTHORING-DIAGRAM]`
- Jargon-dense prose = `[MEDIUM]` / `[AUTHORING-CLARITY]`
- Mixed concerns = `[MEDIUM]` / `[AUTHORING-SCOPE]`

### Altitude checklist (Full Primary docs only)

**Applies to Full Primary docs only.** Meta and generated docs are NOT altitude-graded —
skip them for these checks.

9. **Sources-anchored coverage gap (`[CAL-COVERAGE]`).** Consult output (b) above. For
   each `absent` row for a Full Primary document: verify (spot-check) the term is
   genuinely absent from the doc body. If absent with no explicit dismissal, it is a
   load-bearing source fact the doc forgot = `[HIGH]` `[CAL-COVERAGE]`. If the doc
   explicitly defers the term with a valid `sources:` pointer, do not flag. URL
   `sources:` → N/A, never flag.

10. **Hollowness — too thin (`[CAL-HOLLOW]`).** Read the document alone. Can a reader
    orient from it — does it convey the *why*, *how the parts interact*, the gotchas? Or
    is it a link-farm: mostly "see X" pointers with no synthesised cross-cutting content?
    A hollow link-farm = `[MEDIUM]` `[CAL-HOLLOW]`. *(Runtime judgment — no mechanical
    oracle exists for "does this doc convey durable understanding?". Grade
    conservatively; do not flag a concise but informative doc as hollow.)*

11. **Transcription — too fat (`[CAL-TRANSCRIPTION]`).** Read the document against the
    spirit of its `sources:`. Does the body read like a re-narrated, near-verbatim copy
    of a source — full signatures, exhaustive enumerations, copied detail — rather than
    a synthesis that explains *why* and *how things relate*? A near-verbatim restatement
    with no added synthesis = `[MEDIUM]` `[CAL-TRANSCRIPTION]`. *(Runtime judgment from
    the doc text plus output (b)'s coverage signal — there is no mechanical overlap
    ratio. A doc whose body merely echoes its source's salient tokens with no
    cross-cutting *why* is transcription; judge from the prose, not a number.)*

12. **Deferral-must-point (`[CAL-DEFERRAL]`).** Where the document defers depth ("see
    source", "refer to the code"), it MUST point to a concrete `sources:` entry — a
    durable, grep-recoverable anchor. A vague "see the code" / "see the implementation"
    with no declared `sources:` entry = `[LOW]` `[CAL-DEFERRAL]`.

**Severity anchors:**
- Missing standard document, missing load-bearing part = `[HIGH]` / `[KB-MISSING]`
- Sources-anchored coverage gap (`[CAL-COVERAGE]`) = `[HIGH]`
- Coverage gap vs intent, cross-doc inconsistency = `[MEDIUM]`
- Missing term definition, missing edge case = `[MEDIUM]`
- Hollow (`[CAL-HOLLOW]`) / transcription (`[CAL-TRANSCRIPTION]`) = `[MEDIUM]`
- Deferral without pointer (`[CAL-DEFERRAL]`) = `[LOW]`

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
7-column ledger schema:

```
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|----------|--------|-----|------|-------------|----------|
| M2-001 | [HIGH] | Pending | architecture.md | — | [M2] [KB-MISSING] auth-service.md is not present on disk | ls .aid/knowledge/ — no auth-service.md |
| M2-002 | [HIGH] | Pending | architecture.md | — | [M2] [CAL-COVERAGE] Salient term "router-mesh" absent from doc though in local sources: | output (b) absent row: router-mesh | architecture.md | src/router.ts |
| M2-003 | [MEDIUM] | Pending | module-map.md | — | [M2] [CAL-TRANSCRIPTION] Doc is a near-verbatim restatement of src/index.ts with no synthesis (no why/how-it-relates) | reads as re-narrated source; output (b) shows full salient-token echo |
| M2-004 | [MEDIUM] | Pending | patterns.md | — | [M2] [CAL-HOLLOW] Doc is a list of "see X" references with no synthesised content | Forward read: all entries are pointers; no why/how-it-relates |
```

- Use stable IDs: `M2-001`, `M2-002`, ...
- Prefix every Description with `[M2]`
- Status: `Pending` for new findings
- If re-reviewing: read existing `{{SCOPE}}-anatomy.md`, update Status for your prior
  rows (Pending→Fixed if resolved; Fixed→Recurred if regressed), append new findings

**No narrative, no summary sections — the ledger table is the entire output.**
