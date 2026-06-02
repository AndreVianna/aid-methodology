# task-004: `aid-housekeep` thin-router SKILL.md + PREFLIGHT/DONE bodies

**Type:** IMPLEMENT

**Source:** feature-001-skill-and-state-machine → delivery-001

**Depends on:** task-001, task-002, task-003

**Scope:**
- Author `canonical/skills/aid-housekeep/SKILL.md` as a thin-router mirroring
  `canonical/skills/aid-discover/SKILL.md` and `canonical/skills/aid-summarize/SKILL.md`
  (feature-001 SPEC § Layers & Components, § Technical Specification intro). Frontmatter shape
  per `aid-summarize/SKILL.md` lines 1–14 (`name`, folded `description` naming the state
  machine, `allowed-tools`, `argument-hint`); `allowed-tools` set =
  `Read, Glob, Grep, Bash, Write, Edit, Agent` (matches `aid-discover`, since KB-DELTA
  dispatches sub-agents).
- Sections: `## Arguments` (the CLI table, minus `--cleanup-only` for delivery-001),
  `## Dispatch Protocol (L1+L2+L3)` (same block as `aid-discover/SKILL.md` — heartbeat
  pre-create via `read-setting.sh --path traceability.heartbeat_interval --default 1`, three
  armed L2 timers as separate background dispatches, Calibration-Log writeback; feature-001
  SPEC § Traceability), `## State Detection` (the six-row re-entry table + state-entry banners),
  `## Dispatch` (the five-row state→worker→advance table in feature-001 SPEC § Layers &
  Components), and a `canonical/templates/state-machine-chaining.md` citation line.
- Author `canonical/skills/aid-housekeep/references/state-preflight.md` (PREFLIGHT body):
  synchronous gate verifying `.aid/` present, not in Plan Mode, git repo present/clean enough
  to branch; on failure exit non-zero with an actionable message and **create no state** —
  mirror `aid-summarize/references/state-preflight.md` (feature-001 SPEC § Feature Flow
  PREFLIGHT).
- Author `canonical/skills/aid-housekeep/references/state-done.md` (DONE body): print closing
  summary (branch name, per-stage commits, "user pushes / opens PR" reminder per C3), HALT
  (feature-001 SPEC § Feature Flow DONE).
- Wire State Detection / Dispatch to call `housekeep-state.sh` (resume target),
  `parse-args.sh` (arg routing), and `branch-commit.sh` (commit target), and to route
  CHAIN/PAUSE-FOR-USER-ACTION/HALT advances per
  `canonical/templates/state-machine-chaining.md` (feature-001 SPEC § "Advance types").

**Acceptance Criteria:**
- [ ] `SKILL.md` carries the required frontmatter, the `## Dispatch Protocol (L1+L2+L3)` block
  matching `aid-discover/SKILL.md`, the six-row State Detection re-entry table, the five-row
  Dispatch table, and the state-machine-chaining citation line; `--cleanup-only` is absent from
  `## Arguments`.
- [ ] PREFLIGHT exits non-zero with an actionable message and writes no `## Housekeep Status`
  state on failure; on success it CHAINs to KB-DELTA.
- [ ] DONE prints branch + per-stage commit summary and the "user pushes / opens PR" reminder,
  then HALTs.
- [ ] Resume routing: a re-run reads `## Housekeep Status` via `housekeep-state.sh` and resumes
  at the first non-`passed`/non-`skipped` stage (AC9); a fully-`DONE` run reports "nothing to
  resume".
- [ ] All §6 quality gates pass; build/render passes; all existing tests pass.
