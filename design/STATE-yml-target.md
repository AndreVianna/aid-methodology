# Target STATE.yml — design summary

> Design brief for the **follow-up work** to work-009. work-009 itself is a plain,
> behavior-preserving markdown→STATE.yml translation and does NOT implement any of this.
> This document is the seed for the optimization work, to be started right after work-009 ships.
> Captured 2026-08-13.

## Purpose (the sentence everything follows from)

`STATE.yml` is **machine state that controls a skill's state machine**, consumed **primarily and
mainly by AI agents**, pushed only to preserve/resume a work across an interruption or a handoff to
another machine. It is **not** a human document and **not** a PR-review artifact.

## Design metric

Minimize **tokens** and maximize **agent comprehension reliability** per read — *not* bytes-on-disk,
*not* parse-time. The deterministic dashboard reader twins are the **secondary** consumer.

## What it SHOULD contain — the control vector only

- Pipeline identity (`path`, `initiator`) — enough to route on resume
- `lifecycle`, `phase`, `active_skill` — the state-machine position
- `pause_reason` / `block_reason` / `block_artifact` — why halted, so resume is correct
- `delivery_state` + gate sub-state
- Per-task `state` (done / pending / in-progress) — so a wave resumes correctly

Roughly **tens of tokens of live state**: self-describing keys, closed enums, no prose.

## What it should NOT contain

- **Schema documentation.** The zone docs, enum rationale, and STATE-ADVANCEMENT-ORDERING block —
  today ~62% of the template — live **once** in the template/skill (where the agent learns the
  schema), never copied into each instance. An agent re-ingesting ~141 comment lines on every read
  pays tokens for near-zero marginal comprehension.
- **Audit trail.** `lifecycle_history`, `qa`, per-task `dispatch_log` / `quick_check` / `elapsed` /
  `notes`. This is history, not control. Git holds it at higher fidelity. Split it into an
  append-only log the agent loads only when it actually needs the past.

## How it's written

- A **deterministic writer** — never the agent hand-editing critical state (that is the source of
  the malformed / dropped-key bugs caught during work-009). The agent is the primary *reader*; the
  writer stays a tool.
- With comment preservation and human-diff-legibility both gone, the writer collapses from ~1,700
  lines of surgical multi-shape text-patching to **read-all → set-one → write-all under the existing
  per-work lock** — plausibly a few hundred lines. Surgical single-key writes were never required
  for correctness, only for human diff legibility; concurrency stays safe via the lock.

## Open question to decide during that work (not now)

Whether YAML is even still the right format. It was chosen *only* for comment preservation, which is
moot for a machine-only file. JSON parses in Python/Node stdlib (zero-dependency); bash has no
native JSON parser. A real tradeoff to weigh deliberately — not to flip reflexively.

## Net effect

The file an agent loads to know "where is this work and what runs next" goes from a ~1,500-token
commented document carrying its own history to a compact **~30–40-line control vector**, with audit
and schema each moved to where they belong.

## Constraints that stay real

Zero runtime dependency (C-3) is still a distribution constraint to weigh; cross-runtime (bash
writer, Python + Node readers) is unchanged; **resume-after-interruption correctness** is the actual
functional requirement.

## Inputs from work-009 known-issues (feed these into scoping)

Recorded in the transient `.aid/works/work-009-refactor/known-issues.md`:
- **KI-002** — the extra `.is_file()` stat for legacy detection.
- **KI-005** — quick-check findings stored in two different shapes, one per layout.
- **KI-006** — writes with no home in the schema (calibration / seed-authoring / review-history /
  deploy / work-level qa).
- **KI-008** — the writer-installed-before-convert ordering hazard.

Several are **resolved-by-redesign** here — e.g. KI-006's homeless writes largely disappear once
audit is split from control and the model is minimized. Pull them forward as inputs.
