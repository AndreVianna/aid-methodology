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

## Term rules (feature-014)

These rules govern how concept terms are identified, matched, and excluded. Rules 1-2 are
**deterministic** (applied automatically by `closure-check.sh` and when authoring glossary
headings). Rules 3-5 are **identify-then-confirm**: the loop proposes candidates, but a term is
excluded ONLY after the user confirms it at the exclusion-review gate (Step 5c).

1. **No slash-joined compounds.** Never write a heading or relates-to entry as `A / B`. Treat
   each word of a slash compound as its own term. The checker splits on `/` and matches each
   part independently (so `canonical / profile` resolves only when both `Canonical` and
   `Profile` are defined). When authoring, list them separately (`Canonical`, `Profile`).
2. **Always singular (best-effort FILTER).** Headings and terms are written in the singular. The
   checker normalizes **regular** plurals (`-s` / `-es` / `-ies`, e.g. `tasks` -> `task`)
   symmetrically on both the defined identifiers and the used terms. This is a *filter, not a
   full lemmatizer*: a word with an **irregular** plural (e.g. `indices`/`index`,
   `matrices`/`matrix`, `people`/`person`) that escapes the rule and stays flagged is **NOT**
   silently resolved or assumed. It falls under the **NO-ASSUMPTIONS rule** and is submitted to
   the user at the exclusion-review gate (Step 5c) / Q&A — where it is typically resolved as an
   **alias** of the existing concept (or grounded/excluded per the user's decision). Do NOT
   extend the singularizer to chase irregular plurals; defer them to the user.
3. **Not-concepts (identify -> confirm -> exclude).** Terms that are not concepts: enum/field
   values (`in progress`, `user approved`), instance names (skill names like `aid-execute`,
   file names), and similar. The loop proposes them; the user confirms before exclusion.
4. **Descriptive phrases (identify -> confirm -> exclude).** Multi-word descriptions that are
   not a coined term (`quick check findings`, `state detection`). Proposed, then user-confirmed.
5. **Token junk (identify -> confirm -> exclude).** Harvest/tokenizer artifacts -- mangled
   tokens (`emissionmanifest`, a stray trailing `)`). Proposed, then user-confirmed.

**Confirmation is mandatory for rules 3-5.** The loop NEVER auto-excludes a rule 3/4/5 term;
it writes them to `.aid/generated/exclusion-candidates.md` (categorized) for the Step 5c gate.
Confirmed exclusions persist to `.aid/knowledge/.term-exclusions.md` so re-runs do not re-ask.

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
# Build the combined "excluded" term list the checker subtracts (feature-014 Q10 + rules #3-#5).
# Two sources:
#   (a) the closure loop's own DISMISSED decisions in spine-todo.md (this run), plus
#   (b) the project's PERSISTED, USER-CONFIRMED exclusions in .aid/knowledge/.term-exclusions.md
#       -- not-concepts / descriptive phrases / token junk the user confirmed at a prior run's
#       exclusion-review gate (Step 5c). Persisting them means re-runs never re-ask.
# Once every USED term is GROUNDED (its slash-split + singularized parts each match a clean
# concept identifier -- rules #1/#2) or excluded, output (a) is empty and the loop closes.
{
  awk -F'|' 'NR>2 && $5 ~ /DISMISSED/ {t=$3; gsub(/`/,"",t); gsub(/^[ ]+|[ ]+$/,"",t); if(t!="" && t!="Term") print t}' \
    .aid/generated/spine-todo.md 2>/dev/null || true
  grep -E '^- ' .aid/knowledge/.term-exclusions.md 2>/dev/null | sed -E 's/^- //; s/[[:space:]]+#.*$//' || true
} | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -v '^$' | LC_ALL=C sort -u \
  > .aid/generated/closure-dismissed.txt

bash canonical/scripts/kb/closure-check.sh \
  --concepts .aid/generated/candidate-concepts.md \
  --spine .aid/knowledge/domain-glossary.md \
  --kb-dir .aid/knowledge \
  --dismissed .aid/generated/closure-dismissed.txt \
  --output-a .aid/generated/closure-ungrounded.md \
  --output-b .aid/generated/closure-coverage.md
```

(The coined-term denylist is auto-resolved from the script's sibling
`coined-term-denylist.txt`. The concept-heading match treats a heading as a clean IDENTIFIER:
it strips any `(explanation)` parenthetical, then a used term resolves iff every slash-split,
singularized part of it equals a defined identifier -- e.g. `### Triage (full vs lite path)`
defines `triage`; `tasks` resolves to `Task`; `canonical / profile` resolves when both
`Canonical` and `Profile` are defined.)

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

Print: `[5b] Round {round}: {N} terms are still undefined; assigning {K} helpers to define them from the code and docs...`
Print: `[5b] Round {round}: {G} terms defined, {D} set aside (not real project terms), {E} saved as questions for you.`

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

Print: `[5b] Stopped after {round}/{max_rounds} passes. {N} terms still couldn't be defined from the project and are saved as questions for you.`

This converts a silent miss into a caught human question (FR-32). A budget exhaust degrades
to "surface the gaps", never "ship shallow silently".

### EXCLUSION-REVIEW (categorize the residual for the Step 5c gate)

After the loop ends (CLOSED or ESCALATE), any terms still in output (a) are the residual the
deterministic rules (#1 slash-split, #2 singular) could not resolve and the loop did not ground.
**Do NOT auto-exclude them.** Categorize each into exactly one bucket and write
`.aid/generated/exclusion-candidates.md` for the user-confirmation gate (Step 5c in
`references/state-generate.md`):

| Bucket | Rule | What goes here | Example |
|--------|------|----------------|---------|
| not-concept | #3 | enum/field values, instance names (skill/file names) | `in progress`, `aid-execute` |
| descriptive-phrase | #4 | multi-word descriptions that are not a coined term | `quick check findings` |
| token-junk | #5 | mangled tokenizer artifacts / stray punctuation | `emissionmanifest`, `no install-time marker)` |
| real-concept | -- | a genuine concept that is just missing a clean heading or is a near-miss of one | `concept spine` (-> `Spine`), `wave` (-> own heading) |

The first three buckets are **exclusion candidates** (the user confirms before they are
excluded). The `real-concept` bucket is **NOT excludable** -- surface it as a recommended
glossary fix (add a clean heading, or correct a relates-to) so the term resolves on the next run.

Write the file as:

```markdown
# Exclusion candidates (Step 5c -- confirm before excluding)

## not-concept (rule #3)
- in progress
- user approved
- aid-execute

## descriptive-phrase (rule #4)
- quick check findings
- state detection

## token-junk (rule #5)
- emissionmanifest

## real-concept (NOT excludable -- glossary fix recommended)
- concept spine -> add/rename heading `Spine` (or alias)
- wave -> give it its own `### Wave` heading (do not bury concepts in a parenthetical)
```

Print: `[5b] Exclusion review: {N} candidate terms to confirm (not-concept / descriptive / junk) + {M} glossary fixes recommended. Continue to confirm them.`

**Advance:** the orchestrator chains to Step 5c (`references/state-generate.md`), a
PAUSE-FOR-USER-DECISION, which presents the candidates and persists the confirmed ones.

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
