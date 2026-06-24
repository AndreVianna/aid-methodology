# State: SYNTHESIS + CLOSURE (Step 5b loop body)

> **Thin-router pattern (C8).** This file is the loop body for Step 5b of GENERATE. It is
> invoked by `aid-architect` after the deep-dive agents (Steps 2-5) complete. The orchestrator
> sets the cap via the `--max-clean-passes`/`--max-rounds`/`--token-budget` argument interface
> defined here (defaults from `discovery.closure` in `.aid/settings.yml`; f006 path-config
> supplies per-run overrides through this interface — NOT via `read-setting.sh`, which resolves
> only 2-level `section.key` paths).

## Inputs

- `.aid/generated/candidate-concepts.md` — term universe (harvest rows from Step 0e; synthesis
  rows appended in the SYNTHESIZE step below). Both partitions enter the loop.
- `.aid/knowledge/domain-glossary.md` — the concept spine (grounded concept entries populated
  by this loop; pre-seeded top candidates from harvest as "to ground" rows).
- `.aid/knowledge/*.md` — all KB docs produced by Steps 2-5.
- `.aid/knowledge/external-sources.md` — inventory of external doc paths (including any
  `--history-file` bundle declared there, consumed by Step 0e's harvest).
- Cap arguments: `--max-clean-passes N --max-rounds N --token-budget N` (supplied by Step 5b;
  defaults read from `discovery.closure` block in `.aid/settings.yml`).

## Transient work-list: spine-todo.md

**Before entering the loop**, SEED the transient work-list `.aid/generated/spine-todo.md` from
`candidate-concepts.md`. This is the "no candidate silently dropped" guarantee:

```bash
# Seed spine-todo.md 1:1 from candidate-concepts.md (every row, both harvest and synthesis)
# Each candidate row becomes a checklist item with status: OPEN
# Status values: OPEN | GROUNDED | DISMISSED
```

Every `harvest` AND `synthesis` row in `candidate-concepts.md` becomes one row in
`spine-todo.md`. Columns:

| # | Term | Source | Status | Disposition |
|---|------|--------|--------|-------------|
| 1 | `Relative Bus` | harvest | OPEN | — |
| 2 | `eventual-consistency contract` | synthesis | OPEN | — |
| … |

- **OPEN** — not yet driven to a terminal state; the loop must process it.
- **GROUNDED** — a concept entry exists in `domain-glossary.md` for this term
  (definition-as-used-here + relates-to + `sources:`).
- **DISMISSED** — explicitly not a load-bearing concept (e.g., generated-identifier dump,
  vendored token); one-line reason recorded in the Disposition column.

**No candidate is silently dropped.** Every row must reach GROUNDED or DISMISSED before the
loop declares CLOSED (in addition to the DETECT output (a) termination oracle). New native
terms discovered *during* grounding (understanding is recursive — f004 SPEC §1.4) are
appended to both `candidate-concepts.md` (tagged `Source = synthesis`, with a cited supporting
span) and `spine-todo.md` (Status: OPEN), re-feeding the work-list for subsequent loop passes.

This seed-list grounding is **distinct** from `closure-check.sh` output (a): output (a) is
the used-but-undefined termination oracle (fires on terms *used in a doc* that lack a spine
entry); the `spine-todo.md` seed-list enumerates ALL harvested + synthesis candidates whether
or not they are yet used anywhere in the KB docs.

## Loop body

The loop runs at most `max_rounds` rounds. It tracks `clean_passes` (consecutive passes where
output (a) returns zero ungrounded terms). CLOSED when `clean_passes >= max_clean_passes`.

```
round = 0
clean_passes = 0
while round < max_rounds AND clean_passes < max_clean_passes:
  round++
  if round == 1:
    step SYNTHESIZE
  step EXPLAIN
  step DETECT
  if DETECT output (a) is empty:
    clean_passes++
  else:
    clean_passes = 0
    step INVESTIGATE (batched-parallel)
→ if CLOSED: print summary
→ if cap-trip: step ESCALATE (FR-32)
```

Token-budget guard (when `token_budget > 0`): after each round, estimate cumulative loop
tokens consumed; if the estimate exceeds `token_budget`, treat as a cap-trip even if
`max_rounds` not yet reached (best-effort secondary cap; see f004 SPEC [SPIKE-H6]).

---

### SYNTHESIZE (conceptual-synthesis channel — runs once, at round 1 entry)

`aid-architect` proposes **load-bearing concepts that have no stable recurring coined token**
— ideas spread across prose that the lexical harvest could not fingerprint. This is the
non-lexical candidate-concept source.

**Mandate:**
- Review the project index (`.aid/generated/project-index.md`), deep-dive KB docs (Steps
  2-5), external sources (`.aid/knowledge/external-sources.md`), and the *why* sources
  (ADRs/reports/commit prose referenced in `external-sources.md`) for ideas the project
  *actually turns on* that were never given a stable coined token.
- For each proposed concept, record a **MANDATORY cited supporting source span**: a
  path + grep-recoverable distinct string anchoring the inference. A synthesis concept with
  no cited span is **invalid and must be rejected** (not stored).
- Merge accepted concepts into `.aid/generated/candidate-concepts.md` as `synthesis`-tagged
  rows (Source = synthesis; Class = synthesis; Freq/Spread/Salience = `—`; Example source =
  the cited span). Append them after the `harvest` partition; do not reorder harvest rows.
- Append accepted concepts to `spine-todo.md` (Status: OPEN).
- Rejected proposals (uncited or not load-bearing) are discarded and not stored.

**Output:** `.aid/generated/candidate-concepts.md` now contains both `harvest` rows
(byte-reproducible mechanical partition) and `synthesis` rows (LLM judgment, source-anchored).
The `synthesis` partition is the explicit LLM-judgment limb; the `harvest` partition stays
independently auditable (unchanged by SYNTHESIZE).

---

### EXPLAIN

`aid-architect` writes a "how it works" narrative in the project's **native terms**, drawing
only on the concept spine (`domain-glossary.md`) and the deep-dive KB docs.

- The narrative covers how the system works end-to-end, using the project's coined terms and
  grounded spine concepts.
- Every term used in the narrative that is not in general knowledge MUST be either defined in
  the concept spine or a candidate in `candidate-concepts.md`. Terms the architect reaches for
  but cannot ground from the spine or the KB docs trigger the **can't-explain-it tripwire**:
  they are added to `spine-todo.md` (Status: OPEN) and flagged for the INVESTIGATE step.
- The narrative is written into a transient explain buffer (not a persisted KB doc at this
  stage); the DETECT step scans it.

---

### DETECT

Run the mechanical self-containment check (the deterministic substrate):

```bash
bash .cursor/aid/scripts/kb/closure-check.sh \
  --concepts .aid/generated/candidate-concepts.md \
  --spine .aid/knowledge/domain-glossary.md \
  --kb-dir .aid/knowledge \
  --output-a .aid/generated/closure-ungrounded.md \
  --output-b .aid/generated/closure-coverage.md
```

The loop consumes **output (a) only** as its termination oracle. Output (b) is the
coverage signal consumed by f005's M2 Anatomy mandate — not a loop input. (A former
output (c) lexical transcription-ratio was retired; transcription is now an M2 reviewer
judgment.)

**Output (a) polarity:** a row IS a finding (a candidate-concept term or spine `relates-to`
term that is **used in a KB doc but has no defining concept entry in the spine**). Zero rows
= fully closed for this pass.

**Loop termination oracle:** after DETECT, if output (a) has zero rows, increment
`clean_passes`. If `clean_passes >= max_clean_passes`, the loop is CLOSED — exit cleanly
without an INVESTIGATE step.

---

### INVESTIGATE (batched-parallel grounding sub-agents)

For every ungrounded term in output (a), dispatch a **grounding sub-agent** (one per term, or
chunked into small batches) in **parallel** (background: true). This is the batched-parallel
pattern that turns N sequential investigations into ~2-3 rounds (NFR-2 wall-clock lever).

Each grounding sub-agent receives the `## Grounding` prompt from
`references/agent-prompts.md` and works on exactly one term (or a small chunk):

- **Ground the term:** read the KB docs, the concept spine, external sources, and the
  candidate's `Example source` anchor. Produce a concept entry in `domain-glossary.md`:
  - Term (as coined/used here)
  - Definition-as-used-here (what it means in *this* project, NOT a generic definition)
  - Relates-to (how it connects to other spine concepts)
  - `sources:` (paths + grep-recoverable anchors that ground it — per f001 schema)
  Mark the term as GROUNDED in `spine-todo.md`.
- **If the term cannot be grounded from any artifact after investigation:** it is an
  ungroundable gap. The grounding sub-agent writes a Q&A entry (see FR-32 escalation below)
  and marks the term as DISMISSED in `spine-todo.md` with disposition "Ungroundable —
  escalated to Q&A".
- **If investigation reveals a new native term** (understanding is recursive): append it to
  `candidate-concepts.md` (Source = synthesis, with cited span) and `spine-todo.md`
  (Status: OPEN) so it enters the term universe for the next DETECT pass.

Wait for ALL parallel grounding sub-agents to complete before proceeding to the next DETECT.

Print: `[5b] Round {round}: {N} ungrounded terms dispatched to {K} grounding sub-agents...`
Print: `[5b] Round {round}: grounding complete — {G} GROUNDED, {D} DISMISSED, {E} escalated.`

---

### REPEAT

Return to EXPLAIN (for the re-run narrative check) then DETECT. Repeat until CLOSED or the
cap trips.

> **Batched-parallel discipline:** detect ALL gaps in one DETECT pass → fill ALL in parallel
> → re-check. Never investigate one term and immediately re-check — batch the round.

---

### CLOSED

When `clean_passes >= max_clean_passes` (output (a) returned zero rows for K consecutive
passes):

1. Confirm all `spine-todo.md` rows are in a terminal state (GROUNDED or DISMISSED). If any
   OPEN rows remain (possible if a term was appended late), run one final DETECT+INVESTIGATE
   cycle for those specific terms before declaring CLOSED.
2. Print final summary:
   ```
   [5b] CLOSED after {round} rounds, {clean_passes} clean passes.
        Concepts grounded: {G}  |  Dismissed: {D}  |  Escalated to Q&A: {E}
   ```

---

### ESCALATE (FR-32 — cap-trip before CLOSED)

When the cap trips (`round >= max_rounds` or `token_budget` exceeded) before CLOSED:

For every term that remains in output (a) ungrounded (and every `spine-todo.md` OPEN row),
write a Q&A entry to `.aid/knowledge/.scout-questions.tmp` using the **existing scout-questions
format** (Step 6b reads and consolidates this file — no new queue):

```markdown
### Q{N}
- **Category:** Concept
- **Impact:** High
- **Status:** Pending
- **Context:** Term `{term}` recurs in {candidate-concepts.md anchor} but could not be
  grounded from project artifacts within the closure budget. Closure capped at
  max_rounds={max_rounds} (or token_budget={token_budget}).
- **Suggested:** {best partial inference from artifacts, or "—"}
- **Question:** What does `{term}` mean in this project? Where is it defined or described?
```

Print: `[5b] Cap-trip at round {round}/{max_rounds}. {N} ungrounded terms escalated to Q&A.`

This converts a silent miss into a caught human question (FR-32). A budget exhaust degrades
to "surface the gaps", never "ship shallow silently".

## Reference documents for aid-architect in Step 5b

The architect reads these before entering the loop:

```
REFERENCE DOCUMENTS (read these FIRST):
- .aid/generated/project-index.md — full file inventory
- .aid/generated/candidate-concepts.md — term universe (harvest + synthesis rows)
- .aid/generated/spine-todo.md — work-list (seeded 1:1 from candidate-concepts.md)
- .aid/knowledge/domain-glossary.md — concept spine (ground terms here)
- .aid/knowledge/project-structure.md — repository structure map
- .aid/knowledge/external-sources.md — external documentation inventory
- .aid/knowledge/*.md — all deep-dive KB docs (read to EXPLAIN in native terms)
```

See `references/agent-prompts.md` §Grounding for the grounding sub-agent prompt.
