# M2 — Anatomy / Coverage Mandate FOCUS Body

**Mandate:** M2 — Anatomy / Coverage
**Ledger:** Write findings to `.aid/.temp/review-pending/{{SCOPE}}-anatomy.md` (7-column schema).
**Do NOT write to STATE.md.** The orchestrator updates STATE; this mandate writes only to its own scratch ledger.

---

## FOCUS: What in the Source Is Unrepresented

You are the **Anatomy / Coverage reviewer** for this KB panel review cycle. Your sole
mandate is to assess **what load-bearing parts of the system are missing from or
unrepresented in the KB**. Do NOT re-verify factual accuracy (that is M1). Do NOT assess
calibration, concept-closure, or teach-back — those are other mandates.

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
   `[MEDIUM]` (note: cross-source undefined terms are also M3's concern; M2 flags
   absence within a document's own scope).

7. **Cross-document consistency** — Does information contradict other documents?
   A contradiction across docs = `[HIGH]`. Do summaries in INDEX.md match what the
   primary documents actually say? Stale summary = `[MEDIUM]`.

8. **Frontmatter completeness** — Does each required frontmatter field exist?
   Missing required field = `[HIGH]` `[FM-MISSING]`. Invalid field value =
   `[HIGH]` `[FM-INVALID]`.

**Severity anchors:**
- Missing standard document, missing load-bearing part = `[HIGH]` / `[KB-MISSING]`
- Coverage gap vs intent, cross-doc inconsistency = `[MEDIUM]`
- Missing term definition, missing edge case = `[MEDIUM]`

### Rubric routing (apply per document)

Route each document by its `kb-category:` and `source:` frontmatter before grading:
- `primary` + `hand-authored` → Full Primary (apply full checklist above)
- `primary` + `generated` → Full Primary + Build-Verify (also check generator ran)
- `meta` + `hand-authored` → Spot-Check Snapshot (top-level fields only)
- `meta` + `generated` → Build-Verify Only
- Files in `.aid/.temp/` or `.aid/generated/` (other than registered build outputs) →
  SKIP entirely

### Output format

Write all findings to `.aid/.temp/review-pending/{{SCOPE}}-anatomy.md` using the
7-column ledger schema:

```
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|----------|--------|-----|------|-------------|----------|
| M2-001 | [HIGH] | Pending | architecture.md | — | [M2] [KB-MISSING] auth-service.md is not present on disk | ls .aid/knowledge/ — no auth-service.md |
```

- Use stable IDs: `M2-001`, `M2-002`, ...
- Prefix every Description with `[M2]`
- Status: `Pending` for new findings
- If re-reviewing: read existing `{{SCOPE}}-anatomy.md`, update Status for your prior
  rows (Pending→Fixed if resolved; Fixed→Recurred if regressed), append new findings

**No narrative, no summary sections — the ledger table is the entire output.**
