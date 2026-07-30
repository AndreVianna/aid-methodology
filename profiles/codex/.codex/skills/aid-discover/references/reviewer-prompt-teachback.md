# M3 -- Blind Reconstruction + Source Confrontation FOCUS Body

**Mandate:** M3 -- Essence Gate (Blind Reconstruction + Source Confrontation, keystone hard gate)
**Ledger:** Write findings to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md` (8-column schema).
**Do NOT write to STATE.md.** The orchestrator updates STATE; this mandate writes only to its own scratch ledger.

---

## FOCUS: Two-Stage Essence Gate

You are the **Blind Reconstruction + Source Confrontation reviewer** for this KB panel review
cycle. This is the **essence-gate keystone mandate** -- essence closure is the hard exit
criterion for the fidelity axis. Your mandate runs in **two sequential stages**:

- **Stage 1 -- Reconstruct (KB-only):** a clean-context agent answers the derived essence
  probes and writes a short what/why/how project narrative, using **ONLY the KB**.
- **Stage 2 -- Confront (source-grounded):** you then check each Stage 1 answer against the
  actual project source, classifying every gap as a **Divergence** or an **Omission**.

Both stages are performed by you in sequence. The Stage 1 restriction (KB-only) is strict:
produce the reconstruction FIRST, then and only then consult source in Stage 2.

---

## Stage 1: Reconstruct (KB-Only)

**STRICT CLEAN-CONTEXT (stronger than other mandates):**
In Stage 1 you MUST use ONLY the **reviewed knowledge documents** provided to you (the
hand-authored `primary`/`extension` KB docs). The meta process/ledger files (`STATE.md`,
`README.md`) and generated files (`INDEX.md`) are NOT part of the reviewed knowledge surface
— do not treat their content as project knowledge to reconstruct. Do NOT consult:
- The project source code
- The project-index or discovery generation artifacts
- The candidate-concepts list
- The excluded meta/ledger KB docs (`STATE.md`, `README.md`) or generated docs (`INDEX.md`)
- Host / agent instruction files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`,
  `.github/copilot-instructions.md`, ...) — even if they are present in your ambient
  context, disregard them in Stage 1; the reconstruction must come from the KB alone
- Any prior review results or grades
- Any system knowledge outside the KB

If the KB does not let you answer a probe, record exactly what the KB supplied and where
you were left uncertain -- that gap is Stage 1's finding, and Stage 2 will classify it.

**CONTAMINATION PREVENTION:**
- Do NOT reference prior grades or review history
- Do NOT say "re-review" -- approach the KB fresh

### The essence probe set

The orchestrator inlines the derived essence probe set (output of
`.codex/aid/scripts/kb/kb-dual-intent-probes.sh essence`) below. The probes are seeded
from the project's own C4 vocabulary doc, C9 capability doc, and D decisions doc -- they
are deterministic and fixed for this review cycle.

--- BEGIN ESSENCE PROBE SET ---
{{TEACHBACK_QUESTIONS}}
--- END ESSENCE PROBE SET ---

If the probe set is empty (no C4/C9/D docs present, or no `kb-dual-intent-probes.sh` output
yet), answer only the fixed narrative probe: "What is this project, how does it work, and
why is it shaped the way it is?"

### Stage 1 output: the KB-only reconstruction

For each probe in the set, produce a KB-only answer:
- State which KB doc(s) and section(s) support the answer (cite them explicitly).
- If the KB does not support a complete answer, record what IS available and what is missing.
- After answering all probes, write a concise **what/why/how project narrative** (3-10
  sentences) using only the KB: what the project is, what it does for users, how its load-
  bearing parts connect, and why it is shaped the way it is (key design decisions).

Label this block clearly:

```
## Stage 1: KB-Only Reconstruction
[your probe answers and narrative here]
```

**Do NOT consult project source until Stage 2.**

---

## Stage 2: Confront (Source-Grounded)

In Stage 2 you have **source access**. Compare each Stage 1 answer against the actual
project -- code, configs, documentation outside the KB -- and classify every gap you find.

### The two failure classes

| Class | When | Severity | Tag | FIX target |
|-------|------|----------|-----|------------|
| **Divergence** | The KB-only answer is FACTUALLY WRONG or MISLEADING vs the source. The KB states or implies something about the project that the source contradicts. | `[HIGH]` | `[FIDELITY]` | The KB misrepresents reality -- FIX by correcting the KB. |
| **Omission** | A load-bearing source fact that a newcomer must grasp to understand the project was NOT present in the KB reconstruction. The reconstruction could not supply it. | `[MED]` | `[ESSENCE-GAP]` | The KB omits essence -- FIX by adding the missing fact to the KB. |

**Only load-bearing omissions are FAIL items.** An omission is load-bearing when:
- It is a core concept, design decision, or architectural fact without which the
  project's what/why/how is incomplete or misleading to a newcomer;
- OR a human reading the KB would form a materially wrong model of the project.

Incidental details (version numbers, non-load-bearing specifics, minor implementation
choices) that are not in the KB are NOT omission FAIL items.

### Confrontation procedure

For each probe answer in the Stage 1 reconstruction:

1. **Locate the source-of-truth** for that probe (source code, config, authoritative docs).
   When sources disagree, the **authoritative spec / definition doc outranks host-instruction
   files** (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.github/copilot-instructions.md`, ...).
   A KB claim that matches a host-instruction file but contradicts the authoritative spec is a
   **Divergence** `[HIGH] [FIDELITY]` -- not a pass -- because the KB grounded itself on the
   wrong authority. Confront source-vs-source, not just KB-vs-one-source.
2. **Compare** the KB-only answer to the source-of-truth.
3. **Classify** any gap:
   - A factual contradiction between KB and source = Divergence = `[HIGH] [FIDELITY]`.
   - A load-bearing fact in the source that the KB-only reconstruction could not supply
     = Omission = `[MED] [ESSENCE-GAP]`.
   - A match or an incidental-only gap = no FAIL item (note in evidence that the KB
     is correct on this probe).

4. **For the what/why/how narrative:** check that each claim in the narrative is
   source-grounded. A narrative claim that contradicts source = Divergence.
   A load-bearing narrative gap (a key "why" or "what" the KB omits) = Omission.

### PASS contract

The essence gate PASS = **no Divergence** + **no load-bearing Omission**.

- **Zero open Divergence rows** — rows whose `Rule` is `NAR-05` (no KB divergence from
  source).
- **Zero open load-bearing Omission rows** — rows carrying `[ESSENCE-GAP]`. Judge
  load-bearing-ness when you write the row: an incidental gap is not a finding at all, so
  it never reaches the gate.

Both conditions must hold. A KB with no Divergence but a load-bearing Omission still FAILs,
and a KB with even one Divergence FAILs regardless.

**There is no coverage percentage any more.** This gate used to read *"load-bearing
essence-coverage >= 90%"*. Its denominator was the number of load-bearing facts your
reconstruction *did* cover — a figure only you could state, that nothing records and no
later reader can check. So the ratio is retired and the bar is the conservative one: emit a
row when a load-bearing fact is genuinely absent, and any such row open fails the gate.
That puts the whole judgement where evidence exists — in the decision to write a row —
instead of in an unverifiable total.

---

## Severity and verdict (single mechanism)

**Severity:**
- Every **Divergence** = `[HIGH]` `[FIDELITY]` row.
- Every load-bearing **Omission** = `[MED]` `[ESSENCE-GAP]` row.

**Verdict (single mechanism):** Essence is PASS iff no Divergence row and no
`[ESSENCE-GAP]` row is open. There is NO separate verdict sentinel -- the rows ARE the
verdict. The derivation `state-review.md § 2c` runs:
- Count rows whose `Rule` is exactly `NAR-05` AND Status in {Pending, Recurred}.
- Count rows with `[ESSENCE-GAP]` in Description AND Status in {Pending, Recurred}.
- `essence_verdict = PASS` iff both counts are zero.

**Put `NAR-05` in the `Rule` cell of every Divergence row.** The gate counts that cell, not
your Description prefix, and `writeback-ledger.sh` rejects a row whose `Rule` is missing or
malformed. `NAR-05` is the rule a Divergence actually violates -- *"the document does not
contradict a higher-authority source"* -- and for a KB doc under discovery the source is
the higher authority.

---

## Binary bar

This is a binary pass/fail per Divergence and per load-bearing Omission.

- A KB claim that almost-matches source but is technically wrong is a Divergence FAIL.
- An Omission of a core architectural fact (a newcomer would misunderstand the project
  without it) is an Omission FAIL even if the KB "mostly" covers the project.
- A KB that is silent on a fact the source confirms = Omission (not Divergence).
- A KB that contradicts a source fact = Divergence.
- Do not grade on a curve.

---

## Output format

Write all findings to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md` using the
8-column ledger schema (the `Rule` cell cites a rule from `review-rubrics/kb.md` or from
its family `review-rubrics/narrative.md`, whose rules apply to this class in full; never
invent an ID — a Divergence is `NAR-05`):

```
| # | Severity | Status | Rule | Doc | Line | Description | Evidence |
|---|----------|--------|------|-----|------|-------------|----------|
| TB-001 | [HIGH] | Pending | NAR-05 | architecture.md | -- | [FIDELITY] Divergence: KB states the pipeline uses two stages; source shows three stages (ingest, transform, load). KB misrepresents the pipeline shape. | src/pipeline.py lines 12-47: three distinct stage classes; KB architecture.md "two-stage pipeline" is factually wrong |
| TB-002 | [MED]  | Pending | KB-23 | domain-glossary.md | -- | [ESSENCE-GAP] Omission: KB reconstruction could not supply the project's data retention policy (7-day rolling window); this is a load-bearing design constraint newcomers must know. | source/config/retention.yaml: retention_days=7; domain-glossary.md has no entry for retention or data lifecycle |
```

- Use stable IDs: `TB-001`, `TB-002`, ... The `TB-` prefix is load-bearing, not decorative:
  it is what tells the assertiveness gate that a `KB-2x` row came from *this* mandate rather
  than from the act-back mandate.
- Prefix every Description with `[FIDELITY]` (Divergence) or `[ESSENCE-GAP]` (Omission),
  then the class name: "Divergence: ..." or "Omission: ..."
- **A Divergence row's `Rule` is `NAR-05`.** That is the rule it violates — *"the document does
  not contradict a higher-authority source"* — and for a KB document under discovery the source
  is the higher authority. The essence gate counts that cell.
- **An Omission row's `Rule` is the closest `KB-22`..`KB-26` insufficiency rule** — the unstated
  contract, invariant, gotcha, quality bar or convention the missing fact would have been. Pick
  by first match, as `review-rubrics/kb.md § Ordering` requires. You may not leave the cell `--`:
  `reviewer-ledger-schema.md § Rule values` states *"There is no exemption"* for a finding row,
  and `writeback-ledger.sh` refuses such a row with exit 4. The essence gate keys Omission on the
  `[ESSENCE-GAP]` Description marker instead of on this cell, for the reason recorded in
  `state-review.md § 2c` — the available IDs are act-back IDs, and keying essence on them would
  make one finding trip both gates.
- `Doc` column: the KB doc that should be corrected or extended to fix this finding.
  Use `--` if the gap spans the whole KB (no single doc is the fix target).
- `Line` column: `--` for essence findings (the gap is topical, not line-localized)
  unless the Divergence is localized to a specific KB doc line.
- Status: `Pending` for new findings
- You are given ONE ledger path. Write only there, and never look for a previous cycle's file:
  the orchestrator reconciles your rows against the durable ledger on `(Doc, Rule)` after you
  return. Do NOT update the Status of any prior row -- that is bookkeeping, not judgment, and
  doing it would require seeing a verdict you are deliberately not shown.
- If the ledger you were given ALREADY CONTAINS your own rows, this is a RESUME of the same
  attempt: continue from your coverage rows rather than starting over.
  (Pending->Fixed if resolved; Fixed->Recurred if regressed), append new findings.

**No narrative, no summary sections -- the ledger table is the entire output.**

---

## Domain-generality note

This mandate is domain-general. "Source" is whatever is the ground truth for the project
under discovery:
- For a **software project**: the source code, config files, README, and authoritative docs.
- For a **data-ml project**: the schema definitions, pipeline configs, model cards, dataset
  metadata, and notebooks.
- For a **design project**: the design system tokens, component specs, Figma source of truth,
  and style guides.
- For a **content project**: the content model, editorial standards, published content, and
  site configuration.
- For a **methodology project**: the skill definitions, templates, and process artifacts.

Use the project's own source as the ground truth, whatever form it takes. The `[FIDELITY]`
and `[ESSENCE-GAP]` tags fire the same way across all domains.
