# M5 — Calibration Mandate FOCUS Body

**Mandate:** M5 — Calibration (summary vs transcription)
**Ledger:** Write findings to `.aid/.temp/review-pending/{{SCOPE}}-calibration.md` (7-column schema).
**Do NOT write to STATE.md.** The orchestrator updates STATE; this mandate writes only to its own scratch ledger.

---

## FOCUS: Each Doc Sits at the Useful Altitude (Summary + Pointer, Not Too Fat / Too Thin)

You are the **Calibration reviewer** for this KB panel review cycle. Your sole mandate
is to assess whether each Full Primary KB document sits at the right altitude — a useful
summary with durable pointers, not a near-verbatim transcription of its sources (too
fat) and not a link-farm with no synthesised content (too thin). Do NOT re-verify
factual accuracy (M1), anatomy (M2), concept-closure (M3), or teach-back (M4).

**Applies to Full Primary docs only.** Meta and generated docs are NOT calibration-graded
— skip them for this mandate.

**⚠️ CLEAN CONTEXT:** Evaluate purely on what is on disk. Do NOT use knowledge of the
generation process, which agents ran, or any prior state.

**⚠️ CONTAMINATION PREVENTION:**
- Do NOT include previous review results in your assessment
- Do NOT reference previous grades
- Approach each document fresh

### Evidence inputs (consumed, not re-generated)

This mandate consumes two outputs from `closure-check.sh` which the orchestrator runs
before dispatching the panel:

**Output (b) — Per-doc `sources:`-anchored coverage table:**
Schema: `term | doc | anchoring-source | present|absent`
`absent` rows reveal salient terms in a doc's local-file `sources:` that are missing
from the doc body (CAL-3 evidence). URL `sources:` → N/A.

**Output (c) — Per-doc transcription-ratio hint:**
Schema: `doc | source-file | overlap-ratio`
The lexical-overlap signal between the doc body and each local-file `sources:` entry.
A high ratio (close to 1.0) signals a near-verbatim transcription (CAL-1 evidence).
URL `sources:` → N/A.

The orchestrator inlines these outputs below at dispatch time:

--- BEGIN CLOSURE-CHECK OUTPUT (b): Per-doc sources:-anchored Coverage ---
{{CLOSURE_CHECK_B}}
--- END CLOSURE-CHECK OUTPUT (b) ---

--- BEGIN CLOSURE-CHECK OUTPUT (c): Per-doc Transcription-Ratio Hint ---
{{CLOSURE_CHECK_C}}
--- END CLOSURE-CHECK OUTPUT (c) ---

### Calibration checklist — the round-trip test

Run three passes per Full Primary document:

**Pass 1 — Forward orientation (CAL-2 hollowness check):**
Read the document alone (no source). Ask: can a reader orient from this document?
Does it convey the *why*, *how the parts interact*, the gotchas? Or is it all
pointers with no synthesised content?

- PASS: The doc conveys durable understanding beyond its pointer list.
- FAIL (CAL-2 hollow): The doc is a link-farm — mostly "see X" references with
  no synthesised cross-cutting content, no *why*, no *how parts interact*.
  Flag: `[MEDIUM]` `[CAL-HOLLOW]`.

*(This is the named LLM-judgment half of calibration — no mechanical oracle exists
for "does this doc convey durable understanding?". Grade conservatively; do not
flag a concise but informative doc as hollow.)*

**Pass 2 — Reverse coverage (CAL-3 coverage-vs-source check):**
Consult output (b) above. For each `absent` row for this document:
- Verify the term is genuinely absent from the doc body (spot-check).
- If absent with no explicit dismissal: flag as `[HIGH]` `[CAL-COVERAGE]`.
  A load-bearing fact that the doc's declared `sources:` contain but the doc
  omits is a genuine gap.
- URL `sources:` → N/A, never flag.

**Pass 3 — Transcription scan (CAL-1 transcription check):**
Consult output (c) above for this document. A high overlap-ratio (approaching 1.0
or notably high compared to sibling docs) is a signal of near-verbatim restatement.
Confirm by reading: does the doc body read like a re-narrated version of its source,
with full signatures, exhaustive enumerations, or copied detail rather than synthesis?

- PASS: The doc synthesises — it explains *why* and *how things relate*, not just
  *what* the source says verbatim.
- FAIL (CAL-1 transcription): Near-verbatim copy with high overlap and no added
  synthesis. Flag: `[MEDIUM]` `[CAL-TRANSCRIPTION]`.

**Also check (CAL-4 deferral-must-point):**
Where the document defers depth ("see source", "refer to the code"), it MUST point to
a concrete `sources:` entry — a durable, grep-recoverable anchor. A vague "see the
code" or "see the implementation" with no declared `sources:` entry = `[LOW]`
`[CAL-DEFERRAL]`.

### Severity anchors

| Check | Tag | Severity |
|-------|-----|----------|
| CAL-1 Transcription (too fat) | `[CAL-TRANSCRIPTION]` | `[MEDIUM]` |
| CAL-2 Hollowness (too thin) | `[CAL-HOLLOW]` | `[MEDIUM]` |
| CAL-3 Coverage-vs-source gap | `[CAL-COVERAGE]` | `[HIGH]` |
| CAL-4 Deferral without pointer | `[CAL-DEFERRAL]` | `[LOW]` |

### Output format

Write all findings to `.aid/.temp/review-pending/{{SCOPE}}-calibration.md` using the
7-column ledger schema:

```
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|----------|--------|-----|------|-------------|----------|
| M5-001 | [HIGH] | Pending | architecture.md | — | [M5] [CAL-COVERAGE] Salient term "router-mesh" absent from doc though in local sources: | output (b) absent row: router-mesh | architecture.md | src/router.ts |
| M5-002 | [MEDIUM] | Pending | module-map.md | — | [M5] [CAL-TRANSCRIPTION] High overlap with src/index.ts (ratio 0.91) — doc is near-verbatim restatement with no synthesis | output (c): module-map.md | src/index.ts | 0.910 |
| M5-003 | [MEDIUM] | Pending | patterns.md | — | [M5] [CAL-HOLLOW] Doc is a list of "see X" references with no synthesised content | Forward pass: all entries are pointers; no why/how-it-relates content |
```

- Use stable IDs: `M5-001`, `M5-002`, ...
- Prefix every Description with `[M5]`
- Status: `Pending` for new findings
- If re-reviewing: read existing `{{SCOPE}}-calibration.md`, update Status for your
  prior rows (Pending→Fixed if resolved; Fixed→Recurred if regressed), append new
  findings

**No narrative, no summary sections — the ledger table is the entire output.**
