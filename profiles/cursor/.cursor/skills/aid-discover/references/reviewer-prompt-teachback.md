# M3 -- Blind Reconstruction + Source Confrontation FOCUS Body

**Mandate:** M3 -- Essence Gate (Blind Reconstruction + Source Confrontation, keystone hard gate)
**Ledger:** Write findings to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md` (7-column schema).
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
In Stage 1 you MUST use ONLY the KB documents (`.aid/knowledge/*.md`). Do NOT consult:
- The project source code
- The project-index or discovery generation artifacts
- The candidate-concepts list
- Any prior review results or grades
- Any system knowledge outside the KB

If the KB does not let you answer a probe, record exactly what the KB supplied and where
you were left uncertain -- that gap is Stage 1's finding, and Stage 2 will classify it.

**CONTAMINATION PREVENTION:**
- Do NOT reference prior grades or review history
- Do NOT say "re-review" -- approach the KB fresh

### The essence probe set

The orchestrator inlines the derived essence probe set (output of
`.cursor/aid/scripts/kb/kb-dual-intent-probes.sh essence`) below. The probes are seeded
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

The essence gate PASS = **no Divergence** + **load-bearing essence-coverage >= threshold**.

- **Zero open `[HIGH] [FIDELITY]` rows** (no KB divergence from source).
- **Load-bearing essence-coverage >= 90%** (at most 10% of load-bearing source facts are
  missing from the KB reconstruction; minor/incidental gaps do not count toward this).

Both conditions must hold. A KB with no Divergence but significant Omission still FAILs.
A KB with even one Divergence FAILs regardless of coverage.

The threshold (90%) is the starting-strict calibration value (feature-016 §8 / task-086).
Task-086 wires this into `state-review.md`'s grade aggregation; this mandate emits the
`[FIDELITY]`/`[ESSENCE-GAP]` rows whose count and severity the aggregation reads.

---

## Severity and verdict (single mechanism)

**Severity:**
- Every **Divergence** = `[HIGH]` `[FIDELITY]` row.
- Every load-bearing **Omission** = `[MED]` `[ESSENCE-GAP]` row.

**Verdict (single mechanism):** Essence is PASS iff zero open `[FIDELITY]` rows AND
load-bearing essence-coverage >= threshold. There is NO separate verdict sentinel --
the rows ARE the verdict. Task-086 wires the verdict-derivation grep:
- Count rows with `[FIDELITY]` in Description AND Status in {Pending, Recurred}.
- Count rows with `[ESSENCE-GAP]` in Description AND Status in {Pending, Recurred}.
- `essence_verdict = PASS` iff both counts are within threshold.

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
7-column ledger schema:

```
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|----------|--------|-----|------|-------------|----------|
| TB-001 | [HIGH] | Pending | architecture.md | -- | [FIDELITY] Divergence: KB states the pipeline uses two stages; source shows three stages (ingest, transform, load). KB misrepresents the pipeline shape. | src/pipeline.py lines 12-47: three distinct stage classes; KB architecture.md "two-stage pipeline" is factually wrong |
| TB-002 | [MED]  | Pending | domain-glossary.md | -- | [ESSENCE-GAP] Omission: KB reconstruction could not supply the project's data retention policy (7-day rolling window); this is a load-bearing design constraint newcomers must know. | source/config/retention.yaml: retention_days=7; domain-glossary.md has no entry for retention or data lifecycle |
```

- Use stable IDs: `TB-001`, `TB-002`, ...
- Prefix every Description with `[FIDELITY]` (Divergence) or `[ESSENCE-GAP]` (Omission),
  then the class name: "Divergence: ..." or "Omission: ..."
- `Doc` column: the KB doc that should be corrected or extended to fix this finding.
  Use `--` if the gap spans the whole KB (no single doc is the fix target).
- `Line` column: `--` for essence findings (the gap is topical, not line-localized)
  unless the Divergence is localized to a specific KB doc line.
- Status: `Pending` for new findings
- If re-reviewing: read existing `{{SCOPE}}-teachback.md`, update Status for prior rows
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
