# Reviewer Prompt — Panel Index

Thin index for the four-mandate review panel. The full-panel orchestration is in
`state-review.md` Step 1. Each mandate's FOCUS body is a separate file; this index
lists them for back-compatibility with any direct reader.

**⚠️ CLEAN CONTEXT:** Each mandate reviewer evaluates purely on what is on disk —
as if a stranger wrote it. No generation process, no prior state, no prior grade.

**⚠️ CONTAMINATION PREVENTION (applies to all mandate dispatches and FIX re-review):**
- Do NOT include previous review results in any mandate prompt
- Do NOT tell a reviewer what was fixed or what the previous grade was
- Do NOT say "re-review" — each mandate reviewer must approach fresh

---

## The Four Mandate FOCUS Bodies

| # | Mandate | FOCUS file | Scratch ledger |
|---|---------|-----------|----------------|
| M1 | Correctness | `reviewer-prompt-correctness.md` | `<scope>-correctness.md` |
| M2 | Anatomy / Coverage (incl. altitude: hollow vs transcription) | `reviewer-prompt-anatomy.md` | `<scope>-anatomy.md` |
| M3 | Teach-back (keystone) | `reviewer-prompt-teachback.md` | `<scope>-teachback.md` |
| M4 | Operational sufficiency (act-back, keystone) | `reviewer-prompt-actback.md` | `<scope>-actback.md` |

Each FOCUS body instructs its reviewer to write to its **own transient scratch ledger**
`.aid/.temp/review-pending/<scope>-<mandate>.md` (7-column schema). The orchestrator
aggregates all four scratch ledgers into the single canonical `<scope>.md` ledger and
deletes the transients (Step 2 of `state-review.md`).

**The `{{DOCUMENT_EXPECTATIONS}}` placeholder** (document-expectations.md contents) is
injected into the M2 (Anatomy) body only — it is the Anatomy mandate's authoritative
per-doc criteria. **The `{{CLOSURE_CHECK_B}}` placeholder** (`closure-check.sh` output
(b), the per-doc `sources:`-anchored coverage table) is also injected into the M2 body —
it anchors M2's coverage-gap and altitude judgments.

**Concept self-containment** (every native/synthesis term grounded in the spine) is NOT a
panel mandate: it is enforced mechanically by `closure-check.sh` output (a) as the
GENERATE closure loop's termination oracle (`state-closure.md` DETECT) and the FR-32
cap-trip escalation — a reviewer mandate would only restate that gate. **Transcription
and altitude** ("too fat" / "too thin") are reviewer judgments folded into M2 above —
there is no separate Calibration mandate and no mechanical overlap-ratio.

**`{{SCOPE}}` default:** `discovery` (aid-discover's call site). The `{{SCOPE}}`
parameter is substituted at dispatch time by the orchestrator, making all scratch ledger
paths and the canonical ledger path parametric.
