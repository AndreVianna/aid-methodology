# You-Are-Here Map and Heartbeat

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-23 | **AC4 added — sub-unit drill-down.** Extended the "you are here" map to drill into states that iterate over a known list of sub-units (notably `aid-execute/EXECUTE-WAVE` and `aid-discover/GENERATE`). Adds AC4 to Acceptance Criteria, Flow D to Feature Flow, a new sub-unit-iteration row to Layers & Components, a soft dependency on work-001's `feature-009` (parallel execution model) for the `EXECUTE-WAVE` drill-down, and a Migration Plan note for the two-phase rollout. Sub-unit drill-down is graceful-degradable and never blocks the pipeline; for states without a qualifying iteration, AC3 behavior is unchanged. Per-task internal substates (implement → quick-check → done) are deferred to v2. | extension |
| 2026-05-23 | **Moved to `work-003-traceability` and renumbered: feature-007 (in `work-001-aid-lite`) → feature-001 (in `work-003-traceability`).** Underlying spec content unchanged; this entry records the rename only. The receiving REQUIREMENTS.md renumbers FR4 → FR1; this SPEC's body still references FR4 by historical name where it cites work-001's framing — those references remain valid as historical context. | split |
| 2026-05-22 | Feature identified from REQUIREMENTS.md §5 (FR4 — P1) | /aid-interview |
| 2026-05-22 | Technical Specification written — Data Model, State Machines, Feature Flow, Layers & Components, Events & Messaging, Migration Plan; 4 open questions surfaced (heartbeat cadence, watcher mechanism, state-map source-of-truth, OQ6 run-context ownership resolution) | /aid-specify |
| 2026-05-22 | Fresh-eyes scope reshape — redesigned standalone (no dependency on feature-006); pure skill-body text design (state-entry print + bracket-pair floor + ASCII state-map); all hook/JSONL/schema/context-file references removed; OQ-B (mid-wait tick) dropped; OQ6 (run-context ownership) dropped; (graded A) preamble references removed (prior grade reflects a different design). | /aid-specify |
| 2026-05-22 | Reviewer fixes (1 LOW + 3 MINOR): **LOW (cross-reference)** — every bare `feature-001` / `decision F` cross-work reference qualified as `work-002's feature-001-profile-driven-generator` / `work-002 decision F`, parallel to feature-002's SPEC cleanup (Data Model "canonical content" line, Layers & Components row, "Per-tool delivery via FR5" paragraph, Migration Plan step 4, OQ-A, OQ-C). **MINOR #1 (AC split)** — old AC1 split into AC1 (state-entry print) + AC3 (ASCII "you are here" map on state transition); old AC2 renumbered as AC2 (bracket-pair) unchanged. **MINOR #2 (threshold)** — Bracket-pair coverage paragraph clarified: threshold is per-skill judgment, **rough-time-hints table is the source of truth for what gets bracketed**, with a multi-second calibration aid (sub-second tool calls not bracketed). | /aid-specify |
| 2026-05-22 | Absorbed feature-002's OQ-A/OQ-C resolutions — descriptor carrier is the first line / opening sentence of `references/state-{name}.md` (owned by feature-002), SSoT is the `## Dispatch` table; updated 6 SPEC touch-points (Data Model "Form" cell, Data Model "Source of truth" cell, Data Model `data-model.md` reference paragraph, State Machines "Methodology preservation" paragraph, Layers & Components "State topology" row, "Per-tool delivery via FR5" paragraph, Dependencies, Migration Plan steps 1/3/4/5) — every conditional referencing a `references/state-map.md` or `states:` frontmatter carrier removed. Open Questions section restructured: OQ-A and OQ-C closed and moved to new "Resolved Questions" subsection pointing at feature-002 SPEC's *"State descriptors and single source of truth"* subsection. One remaining bare `FR5` at line 77 qualified as `FR5 (work-002's feature-001-profile-driven-generator)`. | /aid-specify (cross-feature absorption) |

## Source

- REQUIREMENTS.md §5 FR4 (mechanism P1), §1, §9, §10

## Description

A core pain point is that users feel disconnected from AID and assume it is stuck,
because skills give almost no progress feedback. This feature makes pipeline
progress continuously visible. Every skill shows a "you are here" map — the state
machine with the current state marked — so the user always knows where they are in
the pipeline. And during long operations, especially waits on sub-agents, each skill
brackets the operation with a "starting … (~rough expected time)" line before and a
"done in …" line after, so the user can see the process is alive and moving rather
than hung. This keeps the user informed and engaged throughout, which is part of
what success looks like for AID Lite.

Within long, structured states that iterate over a known list of sub-units —
notably `aid-execute/EXECUTE-WAVE` (which iterates over the tasks in a wave)
and `aid-discover/GENERATE` (which dispatches multiple parallel discovery
sub-agents) — the "you are here" map drills in: instead of a single
highlighted state, it shows the sub-unit list with per-item status (done /
running with elapsed time / queued) and an iteration counter. This answers
"how far through this state am I?" — the question that is most acute during
`EXECUTE-WAVE`, the longest opaque stretch in the pipeline.

## User Stories

- As an AID end user, I want every skill to show a "you are here" state map so that
  I always know which phase and state of the pipeline I am in.
- As an AID end user, I want each long operation to be bracketed with a "starting …
  (~rough expected time)" line and a "done in …" line so that I can tell the process
  is working and not stuck.
- As an AID end user running `aid-execute` against a delivery, I want the "you are
  here" map to drill into the current wave so I can see at a glance which tasks are
  done, which are still running (with elapsed time), and which are queued — without
  scrolling back through bracket-pair lines.

## Priority

Should

## Acceptance Criteria

- [ ] **AC1 — state-entry print.** Given any AID skill is running, when it enters
  a state, then it prints a `[State: NAME] — {one-line description}` line at the
  top of that state's output.
- [ ] **AC2 — bracket-pair around long operations.** Given a skill begins a long
  operation (sub-agent dispatch, validation script, long-running tool call), when
  the operation starts, then the skill prints
  `▶ {operation} starting (~{rough expected time})`; when it finishes, then the
  skill prints `✓ {operation} done in {actual time}`; when it errors, then the
  skill prints `✗ {operation} failed: {brief reason}`.
- [ ] **AC3 — "you are here" map on state transition.** Given any AID skill is
  running, when it enters a state, then (immediately after the AC1 state-entry
  print) it renders an ASCII "you are here" map showing the skill's ordered state
  sequence with the current state marked (and completed vs. upcoming states
  distinguished).
- [ ] **AC4 — sub-unit drill-down for states that iterate over a known list.**
  Given a skill is in a state whose body iterates over an enumerable list of
  sub-units (the qualifying states are enumerated in Technical Specification
  → Flow D), when the state is entered and on every sub-unit state transition
  (queued → running → done / failed), then the "you are here" map renders an
  expanded view showing each sub-unit with status icon, name, and elapsed /
  expected time on in-flight items, plus an iteration counter (e.g.
  `Wave 1 of 2 · 2/6 done`). Re-renders triggered by multiple transitions
  within the same second are coalesced into one render to bound chat noise.
  For skills/states without a qualifying iteration, AC3 (bare skill-level map)
  is unchanged.

---

## Technical Specification

> This feature is the **user-facing presentation layer** of FR4. It produces no new
> slash command and no new pipeline state — it is rendered **inside every existing
> skill body / chat**. It has three components, all implemented as **plain skill-body
> text printed in the chat**: (1) a **state-entry print** on entering every state
> (`[State: NAME] — {description}`), extending the bare `[State: NAME]` print
> several existing AID skills already do; (2) the **bracket-pair floor** —
> `▶ … starting (~…)` / `✓ … done in …` / `✗ … failed: …` lines around every long
> operation, which is the load-bearing answer to "am I stuck?"; and (3) the **"you
> are here" map** — an ASCII rendering of the running skill's state sequence with
> the current state marked. The design is **standalone**: no hooks, no event stream,
> no JSONL, no schema, no context file, no instrumentation — just text the skill
> body prints. This is guaranteed on every host tool because every host tool can
> print text.
>
> Consistency with the rest of the AID-Lite work: same SPEC structure, same
> "shipped payload vs. maintainer tooling" discipline, same NFR4
> graceful-degradation framing, same use of the FR5 (work-002's
> feature-001-profile-driven-generator) per-tool profile as the capability
> registry where needed.

### Data Model

feature-007 **defines no new persisted artifact** and reads no persisted artifact
either. It is a pure rendering layer over **one static, declarative input** plus
**transient in-memory render state**.

#### The skill state-map descriptor (new canonical content, static)

The "you are here" map must know **every state of every skill's state machine** to
draw the full map with one state marked, and the state-entry print needs a one-line
description per state. Both come from a small **per-skill state-map descriptor** —
a static, declarative list of the skill's ordered states (and the lite-path branch
where one exists), with a short description per state. It is **canonical content**
(FR5 — delivered by work-002's feature-001-profile-driven-generator), co-located
with each skill, rendered into every install tree unchanged.

| Property | Decision | Rationale |
|----------|----------|-----------|
| Form | A short ordered list of state ids + display labels + descriptions, **derived per skill** from feature-002's authored artifacts: state ids and ordering come from the skill's `## Dispatch` table in `SKILL.md`; the one-line description per state is the **opening sentence / first line of `references/state-{name}.md`** (the "what this state does and the precondition that selects it" line in feature-002's per-state schema). There is **no separate `references/state-map.md` file, no `states:` frontmatter block, and no second registry** — feature-002 owns the on-disk shape, feature-007 reads it. See feature-002 SPEC's *"State descriptors and single source of truth"* subsection (resolves feature-007 OQ-A and OQ-C). | The FR3 thin-router refactor (feature-002) enumerates every state in the `SKILL.md` dispatch table and externalizes each to `references/state-{name}.md` with a canonical first-line role — so the state list and per-state descriptors are already structured, authored artifacts feature-007 can read directly rather than inventing a parallel topology that could drift. feature-007's soft dependency on feature-002 (see Dependencies) reflects exactly this. |
| Content per state | `id` (machine name, UPPERCASE-with-hyphens per **CR6** — e.g. `LOAD-TASKS`, `EXECUTE-WAVE`), `label` (human display string), `description` (one short line, used by the state-entry print), `order` (position in the sequence), optional `branch` (e.g. `lite` / `full` for the FR1 fork in `aid-interview`). | `order` drives left-to-right rendering; `description` powers the `[State: NAME] — {description}` line; `branch` lets the `aid-interview` map show the lite/full fork (FR1) and lets the map collapse to the active branch. |
| Source of truth | The skill's own state set, as defined by the **`## Dispatch` table in `SKILL.md`** — the single source of truth per feature-002 SPEC's *"State descriptors and single source of truth"* subsection. Consumers (notably feature-007) **derive** the state-map descriptor from the dispatch table and **never duplicate** the state list elsewhere. The descriptor therefore cannot disagree with the dispatch table — there is no second copy to drift. | §7 constraint — the methodology (the phases and their state machines) is preserved; feature-007 *visualizes* the state machine, it does not redefine it. Resolves feature-007 OQ-C (closed; see Open Questions). |

The render state (which state is current, elapsed time in the current operation) is
**transient** — held in memory for the duration of a skill run. It is never
persisted by feature-007.

> **Reference `.aid/knowledge/data-model.md`.** No new pipeline artifact is
> introduced by this feature. The state-map descriptor is **derived** from
> feature-002's `SKILL.md` dispatch table and `references/state-{name}.md`
> first-lines — both of which are *skill content* (they travel with `SKILL.md` /
> `references/`), not `.aid/` runtime artifacts. The on-disk conventions for
> dispatch tables and per-state files are owned by feature-002 and documented in
> `coding-standards.md` (SKILL.md / `references/` conventions); `data-model.md`
> needs no entry for feature-007.

### State Machines

The "you are here" map is, literally, **a rendered projection of each skill's state
machine** — so the state-machine model is load-bearing for this feature.

**What feature-007 does NOT do.** It does not define, add, or alter any state
machine. Per the §7 constraint, the 10 skills' phases and state machines are
preserved exactly. The FR3 thin-router refactor (feature-002, not yet shipped)
**will** make each skill's state set explicit in its dispatch table; once it
lands, feature-007 consumes that set (see Dependencies — soft dependency on
feature-002).

**The projection.** For the running skill, feature-007 renders:

- the **ordered state sequence** from the state-map descriptor (Data Model);
- the **current state** marked, resolved from the skill body's own knowledge of
  the state it just entered (the skill *is* in that state — no external lookup
  needed);
- **completed states** distinguished from **upcoming states** (everything before
  the current `order` is done; everything after is pending);
- for `aid-interview` only, the **FR1 lite/full fork** — before triage the map shows
  the fork point; after triage it collapses to the chosen branch.

**Example projection** (illustrative — not a literal output format). State ids
follow feature-002's UPPERCASE-with-hyphens convention per **CR6** (aligning with
the on-disk corpus, e.g. `STALE-CHECK`), which the "you are here" map inherits
verbatim from FR3:

```
aid-execute   ▸ you are here
  [✓ PRE-FLIGHT] → [✓ LOAD-TASKS] → [● EXECUTE-WAVE] → [ QUICK-CHECK ] → [ DELIVERY-GATE ] → [ DONE ]
                                         ▲
                                    current state
```

**Cross-skill scope.** Each skill renders **its own** state machine. The map is
per-skill, not a single global pipeline map — feature-007's job is the *immediate*
"where am I in *this* skill" answer.

**Methodology preservation (§7).** Because the descriptor's source of truth is the
FR3 dispatch table (Data Model; see also feature-002 SPEC's *"State descriptors
and single source of truth"* subsection that resolves feature-007 OQ-C), the map
cannot drift from the actual pipeline: if a skill's states are what they are
today, the map shows exactly those.
feature-007 is additive presentation — it changes *how progress is shown*, never
*what the pipeline does*.

### Feature Flow

feature-007 has **three flows** that run within every skill, all printing text into
the chat: the **state-entry print** (on entering each state), the **state-map
render** (on entering each state, immediately after the state-entry print), and the
**bracket-pair** around every long operation.

#### Flow A — state-entry print

```
skill enters a new state
        │
        ▼
[print-state-line]  the skill body prints:
        │   [State: <ID>] — <one-line description from the descriptor>
        ▼
user sees the state announcement at the top of each state's output
```

This extends the existing bare `[State: <ID>]` print that several AID skills
already do today — the description suffix is the only addition. If the descriptor
is missing a description for a state, the print degrades cleanly to the bare
`[State: <ID>]` form (NFR4).

#### Flow B — "you are here" state-map render

```
skill enters a new state  (immediately after Flow A)
        │
        ▼
[render-state-map]  the skill body renders the map:
        │  1. load this skill's state-map descriptor (ordered states)
        │  2. mark completed / current / upcoming based on the state the skill
        │     just entered; collapse to the active FR1 branch if this is
        │     aid-interview
        │  3. print the ASCII map to the chat
        ▼
user sees the map at the top of each state's output
```

The state map is re-rendered **once per state transition** — cheap, deterministic,
and exactly when the "where am I" answer changes. It is text printed into the chat;
no file is written and no event is emitted.

#### Flow C — bracket-pair floor around long operations

```
skill starts a long operation  (sub-agent dispatch, validation script,
        │                       long-running tool call)
        ▼
[print-start]  the skill body prints:
        │   ▶ <operation> starting (~<rough expected time>)
        │   (rough expected time comes from the static per-operation-class
        │    table — see "Rough time expectation" below)
        ▼
operation runs  (no mid-wait ticks — the bracket pair is the floor)
        │
        ├── on success ──► [print-done]  ✓ <operation> done in <actual time>
        │
        └── on error   ──► [print-error] ✗ <operation> failed: <brief reason>
```

**Bracket-pair coverage.** Every long operation the skill body knows it is about
to invoke is bracketed: sub-agent dispatches (the dominant disconnection pain in
REQUIREMENTS §2 weakness 4), validation script runs, and any tool call the
skill-author judges long enough to warrant a bracket. The threshold is
**qualitative per-skill judgment, not a hard numeric cutoff** — the
**rough-time-hints table is the source of truth for what gets bracketed**:
every operation class with an entry in that table is bracketed, and adding a new
operation class to the table is the act of declaring it long enough to bracket.
As a calibration aid (not a contractual rule), the table's existing entries cover
operations in the multi-second-and-up range (e.g. validation scripts ~30 s,
reviewer sub-agent ~1-2 min, discovery-architect sub-agent ~3-5 min); sub-second
tool calls are not bracketed. Because the skill body initiates the operation, it
owns both ends of the bracket.

**Rough time expectation.** Each "starting" line includes a *rough* expectation,
not a precise ETA. The expectation is a coarse band sourced from a **static
per-operation-class table** shipped with feature-007 — e.g. "discovery-architect
sub-agent: ~3-5 min", "reviewer sub-agent: ~1-2 min", "validate-links script:
~30 s". The bands are intentionally coarse; refinement from measured durations is
a future, additive improvement if data accumulates, not a v1 requirement.

**Degradation path (NFR4).** feature-007's three components degrade independently:

1. **Full fidelity.** State-entry print, state-map render, and bracket-pair all
   print as designed.
2. **Missing descriptor entry.** If a state has no description in the descriptor,
   the state-entry print falls back to the bare `[State: NAME]` form. If a state
   is missing from the descriptor entirely, the map renders without that state
   highlighted (and the skill still prints the bare `[State: NAME]` line).
3. **Missing descriptor entirely.** If the per-skill descriptor is absent (a skill
   not yet refactored), the state-entry print falls back to the bare
   `[State: NAME]` form and the map is skipped; the bracket-pair floor still
   prints — the "is it stuck?" question is still answered on every tool.

**Bracket-pair as the floor.** The bracket-pair floor is **always available** —
it is just text the skill body prints around an operation it is about to invoke.
There is no host-tool capability gate, no hook, no background process, nothing
that can fail to be present. This is the guaranteed-minimum behavior on every
tool and the load-bearing answer to "am I stuck?".

**Never blocks the pipeline.** Map rendering and bracket-pair printing are
observability, not control flow — a failure to render the map (e.g. malformed
descriptor) is swallowed and never aborts the skill.

#### Flow D — sub-unit drill-down (AC4)

For **qualifying states** that iterate over a known list of sub-units, the AC3
map render is extended with a sub-unit snapshot block. The snapshot re-renders
on every sub-unit transition (queued → running → done / failed); multiple
transitions within the same second are coalesced into one render.

```
sub-unit transitions  (any of: dispatched, completed, failed)
        │
        ▼
[snapshot tick]  the skill body re-prints the sub-unit block:
        │  1. iteration header line:  Wave M of N · K/T done
        │  2. one row per sub-unit:
        │       <status icon> <sub-unit name>   <elapsed / expected time>
        │     where status icon is:  ✓ done · ● running · ✗ failed · (blank) queued
        │  3. coalesce: if >1 transition happened in the last second,
        │     emit only one snapshot for the batch
        ▼
user sees a refreshed snapshot of the wave's progress
```

**Qualifying states for drill-down (v1):**

| Skill | State | Iteration source | Notes |
|---|---|---|---|
| `aid-execute` | `EXECUTE-WAVE` | Tasks in the current wave (from PLAN.md execution graph, or the work-root SPEC.md for lite path) | Highest-value drill-down; the longest opaque stretch. Full fidelity activates once work-001's `feature-009` lands (wave-level concurrent dispatch). Until then the wave runs serially and the snapshot shows one task in flight at a time — still useful but not the multi-task view. |
| `aid-discover` | `GENERATE` | The set of parallel discovery sub-agents (architect, analyst, integrator, quality, plus the earlier solo scout and the later solo reviewer) | Full fidelity from day 1; discovery already dispatches concurrently. |

**Out of v1 scope:**

- Other skill states that iterate but iterate very fast (sub-second per item) — bracket-pairs already cover them and a snapshot block would be noise.
- Per-sub-unit substates (e.g. a task running its developer step vs its quick-check step). Surfacing those would couple AC4 to work-001's `feature-004` (two-tier review) and is deferred to a v2 iteration once we see whether the outer-status snapshot is sufficient.
- Global pipeline view ("where in the overall AID lifecycle am I") — out of scope per the original SPEC's per-skill scope decision.

**Render placement.** The sub-unit snapshot is printed in the chat as a fresh block on each coalesced tick (not updated in place — markdown chat does not support in-place edits). Readers see the most recent snapshot by scrolling to the bottom; older snapshots remain in the history as a poor-man's timeline.

**Never blocks the pipeline.** Same as AC3: a snapshot render failure (malformed iteration source, missing rough-time entry) is swallowed and never aborts the skill.

### Layers & Components

| Layer | Component | Role |
|-------|-----------|------|
| Skill body (FR3 thin router) | State-entry print + map-render + bracket-pair invocation points in each `SKILL.md` / `references/state-*.md` | feature-007 is woven into every skill: each state's entry prints `[State: NAME] — {description}` and renders the map; each long-operation site brackets itself with start/done/error prints. This is **canonical content** edited once and rendered to all trees by FR5 (work-002's feature-001-profile-driven-generator). |
| State topology | Per-skill **state-map descriptor**, **derived** from feature-002's `SKILL.md` `## Dispatch` table (state ids + ordering) and the opening sentence of each `references/state-{name}.md` (per-state description). No separate descriptor file. | The dispatch table is the single source of truth for the state list (feature-002 SPEC's *"State descriptors and single source of truth"* subsection — resolves feature-007 OQ-A and OQ-C); feature-007 reads, never duplicates. |
| Rough-time hints | Static **per-operation-class table** | Ships with feature-007. Maps an operation class (sub-agent name, script name, tool-call kind) to a rough expected-time band used in the bracket-pair "starting" line. |
| Sub-unit drill-down (AC4) | Per-qualifying-state **sub-unit iteration logic** inside the skill body — for `aid-execute/EXECUTE-WAVE` and `aid-discover/GENERATE`, the skill body knows its sub-unit list (from PLAN.md execution graph / lite-path SPEC for tasks; from the fixed agent set for discovery) and re-renders the map snapshot on each sub-unit transition, with 1-second coalescing. | New for v1. Couples to work-001's `feature-009` for `EXECUTE-WAVE` (the wave-execution model defines the iteration source); `GENERATE` has no work-001 coupling. |

**Implementation — pure skill-body text.** No shipped scripts, no helpers, no
hooks. The state-entry print, map render, and bracket-pair are instructions in
the skill body itself: "when you enter state X, print this line; before you
dispatch sub-agent Y, print the starting line; after it returns, print the done
line." The skill body is just markdown the host AI coding tool follows. NFR5 is
trivially satisfied — there is no end-user runtime dependency to add.

**Per-tool delivery via FR5.** The rough-time hints table and the print
invocation points in skill bodies are **canonical content**, rendered into each
install tree by the FR5 generator (work-002's
feature-001-profile-driven-generator). The state-map descriptor itself is
**derived at render time** from feature-002's `SKILL.md` `## Dispatch` table and
`references/state-{name}.md` first-lines — both of which are themselves canonical
content. All three FR5 profiles use `references` decomposition (locked work-002
decision F, owned by work-002's feature-001-profile-driven-generator), so
feature-002's per-state files render cleanly on all three tools with no per-tool
special-casing, and feature-007 inherits that cleanly.

**Placement.** All feature-007 content is **shipped payload** — it installs into
the end user's project as skill-body text. None of it is maintainer-only tooling.
No new mandatory end-user dependency (NFR5).

**Dependencies.**

- **Soft dependency on feature-002 (FR3 thin router / FR3-M1)** — feature-002
  owns the **on-disk carriers** the descriptor is derived from: the `## Dispatch`
  table in each refactored `SKILL.md` (state ids + ordering) and each
  `references/state-{name}.md` file (whose first line is the per-state
  description). For skills already refactored under feature-002, feature-007
  reads those carriers directly. For skills not yet refactored, feature-007
  degrades to the bare `[State: NAME]` print and skips the map (NFR4 — see
  Degradation path). Either way feature-007 ships complete and is not blocked.
  `aid-plan` sequences feature-007 after (or alongside) the FR3 rollout for
  cleanest fit.
- **No dependency on any event stream, hook infrastructure, JSONL file, context
  file, or telemetry pipeline.** feature-007 is standalone — pure skill-body text.
- **AC4 — soft dependency on work-001's `feature-009` (parallel execution)** for
  the `aid-execute/EXECUTE-WAVE` sub-unit drill-down. Before feature-009 lands,
  the wave runs tasks serially and the drill-down still works but shows only one
  task in flight at a time. After feature-009, the drill-down shows the full
  concurrent wave with relative progress. AC4 ships with this feature; its
  `EXECUTE-WAVE` fidelity scales up as feature-009 lands.
- **AC4 — no dependency on work-001's `feature-004` (two-tier review)** for v1.
  Surfacing per-task internal substates (implement → quick-check → done) would
  make feature-004 a soft dependency; that is deferred to a v2.
- **AC4 — `aid-discover/GENERATE` drill-down has no work-001 dependency.** The
  parallel discovery sub-agents already dispatch concurrently in the current
  implementation.

### Migration Plan

This is an **additive, near-greenfield** change — there is no existing progress map
or bracket-pair print to migrate from (REQUIREMENTS §2 weakness 4: "Skills provide
almost no traceability or progress feedback"). The bare `[State: NAME]` print that
several skills already do is **extended** (description suffix) rather than replaced.

1. **Sequencing.** feature-002 (FR3 thin router) ideally lands first or alongside
   (see Dependencies) — it produces the on-disk carriers (the `## Dispatch` table
   and `references/state-{name}.md` first-lines) that feature-007's descriptor is
   derived from. feature-007 then adds the state-entry print, map-render, and
   bracket-pair invocation points to each skill body, plus the static rough-time
   hints table — all additively. `aid-plan` fixes the exact slot.

   **AC4 phasing.** The `aid-discover/GENERATE` drill-down ships at full fidelity
   from day 1 (discovery already runs in parallel). The `aid-execute/EXECUTE-WAVE`
   drill-down ships with this feature but reaches full fidelity only after
   work-001's `feature-009` lands (concurrent wave dispatch); before then,
   `EXECUTE-WAVE` runs serially and the snapshot shows one task in flight at a
   time.
2. **No existing data, no existing contract.** feature-007 persists nothing of its
   own and reads nothing it doesn't ship; it has no schema and no backward-
   compatibility surface of its own.
3. **NFR2 (backward compatibility).** Purely additive: no existing skill behavior,
   artifact, or `.aid/` workspace changes shape. An AID install without feature-007
   simply shows no map and no bracket-pair — exactly today's behavior. An install
   with feature-007 applied to a not-yet-FR3-refactored skill still works — without
   feature-002's dispatch table and per-state files there is nothing to derive a
   descriptor from, so feature-007 degrades to the bare `[State: NAME]` print and
   skips the map (NFR4); the bracket-pair floor still prints. Nothing breaks if
   the feature is absent, partial, or degraded.
4. **Rollout across the 10 skills.** The state-entry print, map render, and
   bracket-pair invocation points are added to **all 10 skills** — uniform, like
   the FR3 refactor. Because the content is canonical (FR5 — delivered by
   work-002's feature-001-profile-driven-generator) and woven into the thin-router
   structure feature-002 produces, the rollout is one edit per skill in
   `canonical/`, then an FR5 re-render to all three trees. If feature-007 lands
   before the FR5 cutover (i.e. before work-002's feature-001-profile-driven-generator
   is in place), the invocation points are added by hand to the three trees
   (current pre-FR5 practice) and folded into `canonical/` at the FR5 bootstrap;
   if after, straight into `canonical/`. `aid-plan` fixes the order.
5. **No `data-model.md` update.** feature-007 registers no new pipeline artifact
   (see Data Model). The on-disk carriers the descriptor is derived from (the
   `## Dispatch` table shape and `references/state-{name}.md` first-line role)
   are owned by feature-002 and documented in `coding-standards.md` — feature-007
   adds nothing to either `data-model.md` or `coding-standards.md`.

---

## Open Questions

Genuine decision points — surfaced, not assumed.

(none open)

### Resolved Questions

- **OQ-A — Carrier for the per-skill state-map descriptor.** **RESOLVED by
  feature-002** (see feature-002 SPEC's *"State descriptors and single source of
  truth (resolves feature-007 OQ-A and OQ-C)"* subsection). The descriptor is
  the **opening sentence / first line of `references/state-{name}.md`** — the
  "what this state does and the precondition that selects it" line in
  feature-002's per-state schema. There is **no separate `references/state-map.md`
  file, no `states:` frontmatter block, and no second registry**. feature-002
  owns the convention (the file shape, the first-line role); feature-007 reads
  it. All references in this SPEC that previously floated rejected carriers have
  been updated to reflect this resolution.
- **OQ-C — Single source of truth for the state list.** **RESOLVED by
  feature-002** (same subsection above). The `## Dispatch` table in each skill's
  `SKILL.md` is the **single source of truth** for that skill's state set,
  ordering, and advance edges. Consumers (notably feature-007's state-map
  descriptor) **derive** the list from the dispatch table and **never duplicate**
  it. Because there is no second copy, there is no drift to enforce — agreement
  is structural, not policy. All references in this SPEC that previously framed
  this as an open enforcement question have been updated to reflect this
  resolution.
