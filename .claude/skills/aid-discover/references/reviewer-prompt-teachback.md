# M3 — Teach-Back Mandate FOCUS Body

**Mandate:** M3 — Teach-Back (keystone hard gate)
**Ledger:** Write findings to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md` (7-column schema).
**Do NOT write to STATE.md.** The orchestrator updates STATE; this mandate writes only to its own scratch ledger.

---

## FOCUS: Using Only the KB, Explain the Engine + Answer "What Is X?"

You are the **Teach-back reviewer** for this KB panel review cycle. This is the
**keystone mandate** — teach-back closure is the hard exit criterion. Your mandate is to
simulate a fresh agent given ONLY the KB, and verify:

**(a) Per-term limb:** Can you define each core concept listed in the question set using
only the KB?

**(b) Non-lexical engine-narration limb:** Can you produce a coherent end-to-end account
of how this system works, in the system's own native terms, using only the KB?

Both limbs are **independent FAIL sources** — a clean per-term quiz does NOT excuse a
broken engine-narration, and vice versa.

**⚠️ STRICT CLEAN-CONTEXT (stronger than other mandates):**
You MUST use ONLY the KB documents (`.aid/knowledge/*.md`). Do NOT consult:
- The project source code
- The project-index or discovery generation artifacts
- The candidate-concepts list
- Any prior review results or grades
- Any system knowledge outside the KB

If you cannot find a definition or narration support in the KB alone, that IS a
teach-back FAIL — do not supplement from general knowledge.

**⚠️ CONTAMINATION PREVENTION:**
- Do NOT reference prior grades or review history
- Do NOT say "re-review" — approach the KB fresh

### The fixed question set

The orchestrator inlines the deterministic question set derived from
`candidate-concepts.md` (via `kb-teachback-questions.sh`) below. Every listed term is a
cross-source concept the KB must support defining. The final question is the
engine-narration question.

--- BEGIN TEACH-BACK QUESTION SET ---
{{TEACHBACK_QUESTIONS}}
--- END TEACH-BACK QUESTION SET ---

If the question set is empty (no `candidate-concepts.md` yet), answer only the
engine-narration question: "Explain how this system works, in its own language."

### Grading each question

**Per-term limb (all "What is X?" questions):**

For each term question, answer it using ONLY the KB, then self-score:
- PASS: The KB lets you give the *definition-as-used-here* (not a generic dictionary
  definition) with a specific KB anchor (doc + section). The answer must explain what
  the term means IN THIS PROJECT.
- FAIL: The KB does not let you define the term from the KB alone, OR you can only give
  a generic dictionary definition with no KB anchor, OR you reach an undefined native
  term while answering. Each FAIL = one `[HIGH]` `[TEACHBACK]` row.

**Non-lexical engine-narration limb ("Explain how this system works"):**

Answer this question using ONLY the KB. Produce an end-to-end narration of how the
system works — how the load-bearing parts connect, what the system does, using the
system's native terms throughout. Then self-score:
- PASS: The narration is coherent end-to-end, uses only native terms from the KB, and
  does not stall on any undefined concept or fail to connect the parts.
- FAIL: The narration stalls on an undefined native term, cannot connect how the parts
  fit together into a working account, or the KB does not support a coherent end-to-end
  account — even if every individual coined term is defined. A narration FAIL is a
  first-class FAIL source independent of the per-term quiz. Narration FAIL =
  one `[HIGH]` `[TEACHBACK]` row naming the specific gap (which concept or flow
  is unsupported).

**Severity:** Every FAIL item from EITHER limb = `[HIGH]` `[TEACHBACK]` row.

**Verdict (single mechanism):** Teach-back is PASS iff zero open `[TEACHBACK]` rows.
There is NO separate verdict sentinel — the rows ARE the verdict.

### Binary bar

This is a binary pass/fail per term and per narration. Do not grade on a curve. A
concept the KB almost-defines, or a narration that mostly connects (but stalls on one
load-bearing part), is a FAIL — the KB must close the loop completely for a concept the
system uses as load-bearing.

### Output format

Write all findings to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md` using the
7-column ledger schema:

```
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|----------|--------|-----|------|-------------|----------|
| TB-001 | [HIGH] | Pending | — | — | [TEACHBACK] Per-term FAIL: "relay-bridge" — KB has no definition of this term | Searched domain-glossary.md, architecture.md — no definition found |
| TB-002 | [HIGH] | Pending | — | — | [TEACHBACK] Engine-narration FAIL: narration stalls at "dispatch cycle" — how the dispatch cycle initiates is not explained in KB | architecture.md describes components but not how dispatch cycle starts |
```

- Use stable IDs: `TB-001`, `TB-002`, ...
- Prefix every Description with `[TEACHBACK]`
- Status: `Pending` for new findings
- `Doc` column: use `—` for teach-back rows (the gap spans the whole KB, not one doc);
  fill in a specific doc if the FAIL is localized to one document's scope
- If re-reviewing: read existing `{{SCOPE}}-teachback.md`, update Status for your
  prior rows (Pending→Fixed if resolved; Fixed→Recurred if regressed), append new
  findings

**No narrative, no summary sections — the ledger table is the entire output.**
