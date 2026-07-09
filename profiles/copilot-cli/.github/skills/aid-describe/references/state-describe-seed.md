# State: DESCRIBE-SEED

The seed-authoring step of `aid-describe` (the `aid-describe` step per D3, executed today by
`aid-describe`). Entered after the seasoned-analyst engine has gathered all requirements intent
from a greenfield project and before REQUIREMENTS.md is approved. Consumes the elicitation engine
(`references/elicitation-engine.md`) with a seed-specific gap inventory, stop predicate, and
record sink to elicit and author the 5-element KB seed, then invokes the layered coherence check
(`references/coherence-check.md`) and the greenfield-mode review gate
(`.github/skills/aid-discover/references/state-review.md` with `greenfield: true`).

Feature-003 owns steps 3-5 of the forward-authoring flow; the engine (feature-002) provides the
adaptive elicitation machinery (step 2). Do NOT re-implement the engine -- consume it.

**Cross-references.**
- `references/elicitation-engine.md` -- the engine consumed here via the three-parameter
  consumption contract (gap inventory / stop predicate / record sink). The "Consumption Contract"
  section names the parameters; the "Adaptive Loop" and "Step 1 STOP CHECK" sections define
  the per-turn mechanics.
- `references/coherence-check.md` -- the two-layer gate invoked at step 4 (both layers always
  run; [HUMAN GATE] blocks progress until all conflicts are resolved).
- `.github/skills/aid-discover/references/state-review.md` -- the review subsystem invoked at
  step 5 with `greenfield: true`; the "Greenfield -- two distinct cases" block in state-review.md
  confirms this is a DISTINCT entry point from the discovery-triage greenfield path (Step 0f).
- `.github/skills/aid-discover/references/reviewer-brief.md` -- reviewer brief template; the
  `{{GREENFIELD_BLOCK}}` substitution ("`greenfield: true` case") must be populated.
- `.github/skills/aid-discover/references/document-expectations.md` -- `## Greenfield Mode`
  block applies when `greenfield: true` (evidence substitution + as-built red flags relaxed +
  dimension floors retained).
- `.github/aid/templates/kb-authoring/frontmatter-schema.md` -- `source: forward-authored` is
  the third enum value (task-020 schema); `sources: []` is correct for a pure-intent doc;
  `sources: [<path>]` when the user cited external design notes.

---

## Contents

- [Entry Conditions](#entry-conditions)
- [STATE.md Tracking](#statemd-tracking)
- [Gap Inventory -- 5-Element Seed Model](#gap-inventory----5-element-seed-model)
- [Stop Predicate (RQ-A5)](#stop-predicate-rq-a5)
- [Record Sink](#record-sink)
- [Step 1 -- Detect and Resume](#step-1----detect-and-resume)
- [Step 2 -- Engine Loop (elicit seed content)](#step-2----engine-loop-elicit-seed-content)
- [Step 3 -- Domain-Adaptive Shape](#step-3----domain-adaptive-shape)
- [Step 4 -- Coherence Check [HUMAN GATE]](#step-4----coherence-check-human-gate)
- [Step 5 -- Greenfield-Mode Review Gate](#step-5----greenfield-mode-review-gate)
- [Advance](#advance)

---

## Entry Conditions

DESCRIBE-SEED fires when ALL of the following hold (read from disk):

- `**Interview State:**` is `In Progress` AND every section in the Section Status table under
  `## Interview State` is `Complete` or `N/A`.
- Greenfield: no brownfield KB on disk. Read `.aid/knowledge/`: if no `.md` files are present
  OR every `.md` file present carries `source: forward-authored` (authored by DESCRIBE-SEED in a
  prior session), the project is greenfield. If any file carries `source: hand-authored` or
  `source: generated`, a brownfield KB already exists -- skip DESCRIBE-SEED entirely and route to
  COMPLETION.
- Seed authoring not yet complete: `## Seed Authoring` section is absent from STATE.md OR its
  `**Status:**` field is not `Complete`.

When DESCRIBE-SEED is re-entered on a subsequent `/aid-describe` call (after the user answered a
seed question), the same entry conditions still hold (seed not yet complete). Step 1 reads
STATE.md and `.aid/knowledge/` to determine exactly where to resume (engine loop vs. coherence
check vs. review gate re-run).

---

## STATE.md Tracking

DESCRIBE-SEED tracks its progress in STATE.md `## Seed Authoring`. If this section is absent,
write it before asking the first question:

```
## Seed Authoring

**Status:** In Progress
**Elements authored:**
- [ ] domain-glossary.md (C4 / concept-spine, MANDATORY)
- [ ] architecture.md (C1 / intended architecture, MANDATORY)
- [ ] coding-standards.md (C3 / conventions & standards, DEFERRABLE)
- [ ] technology-stack.md (C0 / technology stack, DEFERRABLE)
- [ ] decisions.md (D / decisions & rationale, CONDITIONAL)
**Domain extensions:** none proposed
**Coherence check:** Not run
**Review grade:** Not run
```

Update the tracking block after each change:
- Tick an element checkbox when its fit criterion passes (step 2 engine loop).
- Update `**Domain extensions:**` when a domain extension is proposed or confirmed (step 3).
- Update `**Coherence check:**` after step 4 completes (e.g., `Complete -- zero conflicts`).
- Update `**Review grade:**` after step 5 produces a grade.
- Set `**Status:** Complete` ONLY after step 5 passes at the minimum grade with essence PASS and
  assertiveness PASS.

---

## Gap Inventory -- 5-Element Seed Model

The engine's gap inventory for DESCRIBE-SEED is the set of under-pinned seed elements. Re-evaluate
every turn at STOP-CHECK before the next gap is selected. An element is OPEN when its fit
criterion (see Stop Predicate) is not yet satisfied.

| # | Element | KB doc | kb-category | Weight | Open when |
|---|---------|--------|-------------|--------|-----------|
| 1 | Declared concept-spine / ubiquitous language | `domain-glossary.md` | primary | MANDATORY | Doc absent OR not every load-bearing term is defined as this project uses it (not generic) with its relationships + `## Invariants` + a concrete example; OR the work cannot be explained using only defined native terms plus general knowledge (C4 stopping bar). |
| 2 | Intended architecture (boundaries + relationships, sketch altitude) | `architecture.md` | primary | MANDATORY | Doc absent OR major parts / boundaries / relationships are not named; OR `## Invariants` section is missing. Sketch altitude only -- not an as-built layout. |
| 3 | Conventions & standards | `coding-standards.md` | primary | DEFERRABLE | Doc absent OR no declared project rules AND no explicit "standard for `<stack>`, no project-specific deviations yet" statement. |
| 4 | Technology stack / medium | `technology-stack.md` | primary | DEFERRABLE | Doc absent OR the chosen language / runtime / framework is not named. |
| 5 | Decisions & rationale | `decisions.md` | extension | CONDITIONAL | Only added to the inventory when rationale-bearing choices are confirmed (propose->confirm gate, step 3). When in inventory: doc absent OR a decision does not state what was decided + why + the rejected alternative + Status (Accepted or Superseded). |

Gap selection priority uses the engine's precedence table (elicitation-engine.md Step 2 -- GAP
SELECTION): rank 1 = open coherence conflict; rank 2 = calibration unknown; rank 3 = missing
mandatory element (concept-spine `domain-glossary.md` first as the vocabulary keystone, then
`architecture.md`); rank 4 = missing deferrable element (conventions, then tech stack, then
decisions if in inventory); rank 5 = under-pinned existing element (doc present but fit criterion
not fully met -- a Partial gap).

---

## Stop Predicate (RQ-A5)

The engine halts (Step 1 STOP-CHECK fires) when ALL of the following pass. The stopping check
MUST NOT fire while any condition is false.

1. **Element 1 (concept-spine):** `domain-glossary.md` is present AND every load-bearing term is
   defined as this project uses it (not a generic definition), with its relationships, a
   `## Invariants` section, and a concrete example per term. The work is explainable using only
   defined native terms plus general knowledge -- the C4 stopping bar.

2. **Element 2 (architecture):** `architecture.md` is present AND major parts, boundaries, and
   relationships are named, with a `## Invariants` section stating the invariants a change must
   not break. Sketch altitude -- not an as-built layout.

3. **Element 3 (conventions):** `coding-standards.md` is present AND either (a) the project's own
   declared rules are stated, OR (b) an explicit "standard for `<stack>`, no project-specific
   deviations yet" statement is present (owner decision D4-default).

4. **Element 4 (tech stack):** `technology-stack.md` is present AND the chosen language, runtime,
   and framework are named. Version MAY be "latest-at-init / TBD-until-scaffolded"; build command
   MAY be "TBD" (owner decision 2).

5. **Element 5 (decisions):** IF the propose->confirm gate (step 3) added `decisions.md` to the
   inventory: `decisions.md` is present AND each decision states what was decided + why + the
   rejected alternative AND carries a `Status` field (`Status: Accepted` for current decisions;
   `Status: Superseded` + `Superseded-by:` link for replaced ones; superseding entries carry a
   `Supersedes:` back-link). If no rationale-bearing choices were confirmed, this condition is
   vacuously satisfied (element not in inventory).

6. **Zero Requirement orphans:** the coherence check (step 4) has been run AND its Layer B output
   shows zero Requirement orphans (every load-bearing REQUIREMENTS term maps to a seed concept).
   The engine MUST NOT halt while any Requirement orphan remains.

---

## Record Sink

Each confirmed answer is written to the corresponding KB doc in `.aid/knowledge/`. The first write
establishes the frontmatter. Subsequent writes extend the doc's content.

**Frontmatter for every seed doc:**

```yaml
---
kb-category: primary
source: forward-authored
objective: <one-line noun-phrase stating the doc's purpose; single physical line>
summary: <one-sentence scope; single physical line>
sources: []
tags: [<concern-id>, ...]
owner: <role>
audience: [developer, architect]
---
```

Set `kb-category: extension` for `decisions.md` instead of `primary`.

`sources: []` is correct for a pure-intent doc (no code exists yet). If the user cited external
design notes or documents during elicitation, list those file paths in `sources:`. Never list code
files as sources for a forward-authored doc.

Concern-id tags by element: `domain-glossary.md` -> `[C4, ...]`; `architecture.md` -> `[C1, ...]`;
`coding-standards.md` -> `[C3, ...]`; `technology-stack.md` -> `[C0, ...]`;
`decisions.md` -> `[D, ...]`.

**decisions.md entry schema (per decision; newest entries appended last):**

```
## <Decision title>
- **Status:** Accepted
- **Decided:** <what was decided>
- **Rationale:** <why>
- **Rejected alternative:** <what was not chosen and why not>
- **Supersedes:** <prior-title>    (present only when this entry replaces a prior one)
- **Superseded-by:** <new-title>   (present only when a later entry supersedes this one)
```

**ADR immutability rule (web-validation G1 -- Nygard / JPH ADR convention).**
A recorded decision is IMMUTABLE. When a decision changes, APPEND a NEW entry
(Status: Accepted + Supersedes: <old-title>) and mark the prior entry
(Status: Superseded + Superseded-by: <new-title>). The original entry is NEVER edited
in place or removed. The supersession chain is the historical record of "why we did it
that way" for future readers. (Grounds: Nygard 2011,
cognitect.com/blog/2011/11/15/documenting-architecture-decisions; JPH ADR README --
"Immutable: Don't alter existing information in an ADR. Instead, supersede the ADR by
creating a new ADR." -- web-validation G1.)

KB doc layout (authoring-conventions.md KB Document Layout):
frontmatter -> `# <Title>` -> `## Contents` (when more than 3 sections) -> content sections ->
`## Change Log` (always the last section).

After each confirmed answer, record it with Move 10 (scribe) from `references/move-playbook.md`:
"Got it: recording `[content]` in `.aid/knowledge/<doc>.md`."
Write the content to the doc on disk before returning to STOP-CHECK.

---

## Step 1 -- Detect and Resume

Print:
```
[State: DESCRIBE-SEED] -- Authoring forward-authored KB seed (greenfield mode).
aid-describe > you are here
  [* FIRST-RUN ] -> [* Q-AND-A ] -> [* CONTINUE ] -> [@ DESCRIBE-SEED ] -> [ COMPLETION ] -> [ /aid-define ]
  (greenfield only: engine-driven 5-element seed + coherence check + greenfield-mode review gate)
```
(* = complete, @ = current state)

Read STATE.md `## Seed Authoring`. If absent, write the initialization scaffold (see STATE.md
Tracking above).

**Determine resume point** by reading the tracking block and `.aid/knowledge/`:

| Condition | Resume at |
|-----------|-----------|
| `**Coherence check:** Complete` AND `**Review grade:**` is not set | Step 5 (review gate) |
| `**Coherence check:** Complete` AND `**Review grade:**` is a grade below minimum | Step 2 (fix seed elements identified by review findings, then step 4, then step 5) |
| `**Coherence check:**` not `Complete` AND all six stop-predicate conditions pass on the current docs | Step 4 (coherence check) |
| Stop-predicate conditions NOT all passing | Step 2 (engine loop) |

**Opener de-dup:** the D1 opener always already fired earlier in this session, at
`state-continue.md`'s entry (CONTINUE is DESCRIBE-SEED's unconditional predecessor -- see
`SKILL.md § Dispatch`). Enter the adaptive loop directly at STOP-CHECK / GAP-SELECTION;
never re-emit the D1 opener here.

Scan `.aid/knowledge/` to build the current gap inventory: for each of the 5 elements, check
whether its KB doc exists and whether it meets its fit criterion. A doc that exists but is only
partially filled (e.g., `## Invariants` missing) is a Partial gap (rank 5 in engine precedence).

---

## Step 2 -- Engine Loop (elicit seed content)

Invoke `references/elicitation-engine.md` with the three-parameter consumption contract.
Do NOT re-implement the engine's selector logic -- consume it as specified here.

| Parameter | Value supplied by DESCRIBE-SEED |
|-----------|--------------------------------|
| Gap inventory | Open seed element gaps from the 5-element table above; updated after each turn by re-checking fit criteria against the current `.aid/knowledge/` docs |
| Stop predicate | RQ-A5 -- all six conditions above must pass before the engine exits this loop |
| Record sink | `.aid/knowledge/<element-doc>.md`; each confirmed answer is written to the appropriate doc, stamped `source: forward-authored` |

Run the engine's five-step selector every turn:

1. **STOP-CHECK** -- evaluate the RQ-A5 stop predicate. If all six conditions pass, exit the
   engine loop and proceed to Step 3 (domain-adaptive shape). If any condition is false, fall
   through to gap selection.

2. **GAP-SELECTION** -- pick the highest-priority open gap using the 5-element inventory:
   - Rank 1: open coherence conflict (a contradiction or Term surface during elicitation).
   - Rank 2: calibration still Unknown (after at least one substantive answer, per calibration.md
     Part B gating rule -- never on turn 1).
   - Rank 3: missing mandatory element -- `domain-glossary.md` (C4 concept-spine) first (the
     vocabulary keystone; elicit it before architecture), then `architecture.md` (C1).
   - Rank 4: missing deferrable element -- `coding-standards.md` (C3), then `technology-stack.md`
     (C0), then `decisions.md` (D, only if in inventory).
   - Rank 5: under-pinned existing element -- a doc present but not fully meeting its fit
     criterion (Partial gap; deepen before declaring done).

3. **MOVE-SELECTION** -- delegate to `references/move-playbook.md` firing table. Seed-authoring
   gap-to-move mappings:
   - Undefined / ambiguous term: Move 2 (term-capture + disambiguation) -> `domain-glossary.md`
   - Unnamed boundary or relationship: Move 3 (boundary-elicitation) -> `architecture.md`
   - Unknown behavior / flow in a process-heavy domain: Move 4 -> `architecture.md`
   - Missing "why" behind a design choice: Move 7 (bounded why-probe) -> `decisions.md`
   - Claim without concrete example: Move 8 (concrete-example probe) -> any element
   - Cannot settle now: Move 9 (capture-and-defer) -> record to STATE.md Cross-phase Q&A

4. **CALIBRATION-SHAPING** -- delegate to `references/calibration.md` depth-shaping table.

5. **ENVELOPE + EMIT** -- wrap in the NFR-7 envelope (`references/advisor-stance.md`); run
   pre-emit self-check; emit. One question per turn, never batch (engine invariant 1).

After each user answer:
- Record the confirmed content to the appropriate KB doc (the record sink). Append or update
  `.aid/knowledge/<element-doc>.md`. Stamp `source: forward-authored` on the first write.
- Tick the element checkbox in STATE.md `## Seed Authoring **Elements authored:**` when its fit
  criterion passes.
- Re-read calibration state (calibration.md Part A).
- Return to STOP-CHECK.

**Whole-picture read-back (elicitation-engine.md Invariant 8):** Before the engine exits and the
domain-adaptive shape is applied, reflect the assembled seed content back to the user for
confirmation and correction:

```
Here is what I have gathered for each seed element:

- Concept-spine (domain-glossary.md): [summary of defined terms and invariants]
- Architecture (architecture.md): [summary of major parts and invariants]
- Conventions (coding-standards.md): [summary of declared rules or deferred statement]
- Technology stack (technology-stack.md): [summary of named language / runtime / framework]
- Decisions (decisions.md): [summary of decisions, or "none recorded"]

Does this accurately reflect your intent? Any corrections before I check coherence?

[1] Looks right, proceed
[2] Correct: ___
```

Record any corrections before moving to step 3.

---

## Step 3 -- Domain-Adaptive Shape

After the engine loop exits and the whole-picture read-back is confirmed, apply the domain-adaptive
shape (RQ-A4) before running the coherence check.

**Invariant core (never flexes):**
- Elements 1 (`domain-glossary.md`, C4) and 2 (`architecture.md`, C1) are ALWAYS present.
- The 11-dimension spine (C0-C9 + D) is fixed; adaptivity is in doc realization, not the
  dimension list.
- "Name boundaries + relationships" stays the invariant shape for architecture.
- The mandatory core (elements 1-2) and per-element fit criteria are unchanged across domains.

**Domain-selected extensions (propose->confirm gate):**

Propose an extension ONLY when the domain warrants it. Use the same propose->confirm mechanism
`aid-discover` uses for domain-driven doc-sets. One proposal at a time:

```
I notice this project is [process/workflow-heavy | data/ML-heavy | integration-heavy].
Would you like me to author [process-architecture.md | schemas.md | integration-map.md]
as part of the seed?

Suggested: [Yes, include it -- it is load-bearing for downstream phases on this project]
Why: [because <domain signal> means <element> will be needed by aid-specify to act without KB-gap loopbacks]

[1] Yes, add it to the seed
[2] No, defer it to when code exists
```

Domain signals and their extensions:

| Domain signal | Extension proposed | KB doc | Concern |
|---------------|--------------------|--------|---------|
| Process / workflow-heavy | Event-flow / behavior content is load-bearing | Add to `architecture.md` OR `process-architecture.md` | C1 (primary) |
| Data / ML domain | Intended schema is load-bearing | `schemas.md` | C5 (primary) |
| Integration-heavy | Intended integration-map is load-bearing | `integration-map.md` | C2 (primary) |
| Non-software / methodology project | Alternate doc names for the same dimensions | e.g. `authoring-conventions.md` for C3 | (same concern) |

A confirmed extension is added to the gap inventory and elicited via the engine loop (return to
Step 2 for the new gap) before the coherence check. A rejected extension stays in the exclusion
list below.

**Exclusions (RQ-A2 -- MUST NOT be authored in the seed):**

These docs describe as-built state and have no greenfield source. Do NOT propose or author:

| Excluded doc | Concern | Reason |
|--------------|---------|--------|
| `module-map.md` | C2 | No modules exist yet |
| `test-landscape.md` | C6 | No tests exist yet |
| `schemas.md` | C5 | As-built data shapes (domain-adaptive exception above) |
| `infrastructure.md` | C8 | Nothing ships or runs yet |
| `feature-inventory.md` | C9 | Scope is owned by the pipeline (REQUIREMENTS.md), not the KB |
| `integration-map.md`, `pipeline-contracts.md` | C2 | As-built connections (domain-adaptive exception above) |
| `project-structure.md` | C1 | As-built on-disk layout; nothing is on disk yet |

The seed carries intent, not inventory (NFR-4 -- minimal, not bloated). Excluding these docs is
what keeps the seed minimal-but-sufficient.

---

## Step 4 -- Coherence Check [HUMAN GATE]

After the domain-adaptive shape is applied (and any confirmed extensions are authored via the
engine loop), invoke the layered coherence check (`references/coherence-check.md`). Both layers
MUST run; neither can be skipped (coherence-check.md Invariant 1).

**Inputs:**
- The just-authored seed docs: all elements now in `.aid/knowledge/` authored by this step.
- The gathered REQUIREMENTS: `.aid/{work}/REQUIREMENTS.md`.

The check reads both inputs as they stand on disk at invocation time. Complete both layers before
surfacing any conflict (coherence-check.md Invariant 2 -- do not interleave).

**If any conflict is found (Layer A mismatch or Layer B orphan):**

1. Surface each conflict one at a time using the NFR-7 conflict-surfacing template in
   `references/coherence-check.md` "Conflict Surfacing and Human Gate". Always include
   a concrete `Suggested:` resolution and a grounded `Why:` rationale -- never a bare
   problem statement.
2. [HUMAN GATE]: Block the flow at each conflict. Work MUST NOT proceed to step 5 while
   any conflict remains open (coherence-check.md Invariant 4).
3. After the user confirms a resolution: record it with Move 10 (scribe move from
   `references/move-playbook.md`). Amend the seed doc or REQUIREMENTS as confirmed.
4. Re-run BOTH layers of the coherence check in full after any amendment
   (coherence-check.md "Re-Run Protocol"). A full re-run catches cascades.
5. Repeat until both layers produce zero conflicts.

Surface Requirement orphans before Seed orphans (coherence-check.md "Ordering"). Confirmed
retention of a Seed orphan concept does NOT block the sufficiency bar -- only Requirement orphans
block it (coherence-check.md "Sufficiency-Bar Output").

**Sufficiency precondition (gate before step 5):**

Both of the following MUST hold before proceeding:
- Every kept element meets its fit criterion (all six stop-predicate conditions pass).
- The Requirement orphan set from Layer B is empty (zero Requirement orphans; every REQUIREMENTS
  load-bearing term maps to a seed concept).

Update STATE.md `## Seed Authoring`:
`**Coherence check:** Complete -- zero conflicts`

---

## Step 5 -- Greenfield-Mode Review Gate

After the coherence check passes (zero conflicts, zero Requirement orphans), invoke the
aid-discover review subsystem with `greenfield: true`. This is a DISTINCT path from the
discovery-triage greenfield case (Step 0f in `aid-discover`, which collapses the panel for
projects with no KB to extract). See `state-review.md` "Greenfield -- two distinct cases."

Per NFR-3, the seed MUST traverse the FULL panel (`panel: full`): all four mandates (M1-M4),
same dimension floors, intent-evidence substituted for code/config evidence, named as-built red
flags relaxed.

**Invoke `.github/skills/aid-discover/references/state-review.md` with `greenfield: true`.**

**Reviewer brief (`.github/skills/aid-discover/references/reviewer-brief.md`):**

- `{{ARTIFACTS}}` -- the seed doc paths in `.aid/knowledge/`:
  - `.aid/knowledge/domain-glossary.md`
  - `.aid/knowledge/architecture.md`
  - `.aid/knowledge/coding-standards.md`
  - `.aid/knowledge/technology-stack.md`
  - `.aid/knowledge/decisions.md` (if present)
  - Any domain-promoted extension docs (e.g., `schemas.md` if domain-promoted)
- `{{CONTEXT}}` -- descriptive-only: "These are forward-authored greenfield seed docs elicited
  from user intent before any code exists. Seed authoring step (feature-003, flow step 5)."
- `{{GREENFIELD_BLOCK}}` -- render the full greenfield instruction block (`reviewer-brief.md`
  "Substitution at dispatch time", `greenfield: true` case). This activates:
  - Evidence substitution: C3 depth standard / architecture.md / C4 depth standard -> substitute
    intent-evidence (the user's confirmed elicited statements and gathered REQUIREMENTS).
  - As-built red flags relaxed: C0 "Version TBD" accepted as "latest-at-init /
    TBD-until-scaffolded"; C1 "generic descriptions without file paths" relaxed to sketch-altitude
    intended boundaries; C3 "convention named but no example from code" accepted when doc declares
    "standard for `<stack>`, no project-specific deviations yet".
  - All dimension floors retained at full strength: no dimension skipped; the same depth-standard
    bar applies across C0-C9 and D; only the evidence source changes.

**Pre-dispatch oracle runs** (state-review.md Step 1 "Pre-dispatch"): run `closure-check.sh`,
`kb-dual-intent-probes.sh essence`, `kb-dual-intent-probes.sh work`, and `kb-actback-task.sh
check` as specified in state-review.md. If `candidate-concepts.md` does not exist, oracle outputs
are empty and the panel degrades gracefully -- not an error.

**Dispatch:** `panel: full` -- four parallel mandate dispatches M1, M2, M3, M4 per state-review.md
"panel: full" section. M2 inlines `document-expectations.md` `## Greenfield Mode` via
`{{DOCUMENT_EXPECTATIONS}}`.

**Grade requirement:**

```bash
bash .github/aid/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A
```

Compute `ready = (grade >= minimum_grade AND essence_verdict == PASS AND
assertiveness_verdict == PASS)`.

Update STATE.md `## Seed Authoring` `**Review grade:**` with the grade from `grade.sh`.

**If NOT ready:** loop back to Step 2 (resume engine loop with the review findings as additional
gap signals; each finding identifies a seed element needing more content or correction). After
correcting seed docs: re-run coherence check (Step 4), then re-invoke the review gate (Step 5).
Update `**Review grade:**` with the new grade on each cycle.

**If ready:** seed authoring is complete.
Update STATE.md `## Seed Authoring` `**Status:** Complete`.

---

## Advance

**Advance: CHAIN -> [State: COMPLETION]**

When step 5 passes (grade >= minimum, essence PASS, assertiveness PASS), chain inline to COMPLETION
(`references/state-completion.md`). The seed docs are now a forward-authored KB in `.aid/knowledge/`;
COMPLETION's KB Hydration step finds them already populated and proceeds to the summary and
requirements-approval gate. The downstream phases (`aid-specify`, `aid-plan`, `aid-execute`) read
the seed docs from `.aid/knowledge/` unchanged.

Do NOT re-emit the D1 opener in COMPLETION. The opener already fired at the entry to CONTINUE
(DESCRIBE-SEED's unconditional predecessor); the fire-once check in `state-continue.md` covers
this for every downstream state.
