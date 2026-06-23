# Reviewer Prompt — Panel Index

Thin index for the five-mandate review panel. The full-panel orchestration is in
`state-review.md` Step 1. Each mandate's FOCUS body is a separate file; this index
lists them for back-compatibility with any direct reader.

**⚠️ CLEAN CONTEXT:** Each mandate reviewer evaluates purely on what is on disk —
as if a stranger wrote it. No generation process, no prior state, no prior grade.

**⚠️ CONTAMINATION PREVENTION (applies to all mandate dispatches and FIX re-review):**
- Do NOT include previous review results in any mandate prompt
- Do NOT tell a reviewer what was fixed or what the previous grade was
- Do NOT say "re-review" — each mandate reviewer must approach fresh

---

## The Six Mandate FOCUS Bodies

| # | Mandate | FOCUS file | Scratch ledger |
|---|---------|-----------|----------------|
| M1 | Correctness | `reviewer-prompt-correctness.md` | `<scope>-correctness.md` |
| M2 | Anatomy / Coverage | `reviewer-prompt-anatomy.md` | `<scope>-anatomy.md` |
| M3 | Concept-closure | `reviewer-prompt-concept-closure.md` | `<scope>-concept-closure.md` |
| M4 | Teach-back (keystone) | `reviewer-prompt-teachback.md` | `<scope>-teachback.md` |
| M5 | Calibration | `reviewer-prompt-calibration.md` | `<scope>-calibration.md` |
| M6 | Operational sufficiency (act-back, keystone) | `reviewer-prompt-actback.md` | `<scope>-actback.md` |

Each FOCUS body instructs its reviewer to write to its **own transient scratch ledger**
`.aid/.temp/review-pending/<scope>-<mandate>.md` (7-column schema). The orchestrator
aggregates all six scratch ledgers into the single canonical `<scope>.md` ledger and
deletes the transients (Step 2 of `state-review.md`).

**The `{{DOCUMENT_EXPECTATIONS}}` placeholder** (document-expectations.md contents) is
injected into the M2 (Anatomy) body only — it is the Anatomy mandate's authoritative
per-doc criteria.

**`{{SCOPE}}` default:** `discovery` (aid-discover's call site). The `{{SCOPE}}`
parameter is substituted at dispatch time by the orchestrator, making all scratch ledger
paths and the canonical ledger path parametric.
