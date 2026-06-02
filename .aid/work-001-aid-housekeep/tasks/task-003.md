# task-003: `aid-housekeep` thin-router SKILL.md + PREFLIGHT/DONE bodies + arg grammar (prose) + stub no-op bodies

**Type:** IMPLEMENT

**Source:** feature-001-skill-and-state-machine → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Author `canonical/skills/aid-housekeep/SKILL.md` as a thin-router mirroring
  `canonical/skills/aid-discover/SKILL.md` and `canonical/skills/aid-summarize/SKILL.md`
  (feature-001 SPEC § Layers & Components, § Technical Specification intro). Frontmatter shape
  per `aid-summarize/SKILL.md` lines 1–14 (`name`, folded `description` naming the state
  machine, `allowed-tools`, `argument-hint`); `allowed-tools` set =
  `Read, Glob, Grep, Bash, Write, Edit, Agent` (matches `aid-discover`, since KB-DELTA
  dispatches sub-agents).
- Sections: `## Arguments`, `## Dispatch Protocol (L1+L2+L3)`
  (same block as `aid-discover/SKILL.md` — heartbeat pre-create via
  `read-setting.sh --path traceability.heartbeat_interval --default 1`, three armed L2 timers
  as separate background dispatches, Calibration-Log writeback; feature-001 SPEC §
  Traceability), `## State Detection` (the six-row re-entry table + state-entry banners),
  `## Dispatch` (the five-row state→worker→advance table in feature-001 SPEC § Layers &
  Components), and a `canonical/templates/state-machine-chaining.md` citation line.
- **Argument grammar in `## Arguments` prose + State Detection (no dedicated arg-parse script).**
  Following the convention of the other five skills (args are handled by the prose
  `## Arguments` table + State Detection in `SKILL.md`, not a CLI parser script), the
  delivery-001 arg grammar lives directly in `SKILL.md` (feature-001 SPEC § Invocation / CLI
  Arguments table):
  - *(none)* = full gated sequence `KB-DELTA → SUMMARY-DELTA → CLEANUP` (FR7 default).
  - `--grade X` (`[A-F][-+]?`) pass-through for the SUMMARY-DELTA delegation to `/aid-summarize`,
    resolved otherwise via `read-setting.sh --skill summary --key minimum_grade --default A`.
  - `--cleanup-only` is **absent / REJECTED** in delivery-001 (feature-001 SPEC § "Incremental-
    delivery stub no-op": the CLEANUP body is still a stub no-op, so the flag arrives with the
    delivery that ships the real CLEANUP body — task-011/task-012, delivery-003). The
    `## Arguments` table does not offer it and State Detection does not route it.
  - The skeleton does **not** parse `--fetch`/offline (that boundary lives in feature-002's body
    — feature-001 SPEC § "`--fetch` / offline").
  State Detection maps the parsed arguments to the entry state (no-args → PREFLIGHT → KB-DELTA;
  resume rows 1–6 per the re-entry table), reading/writing `## Housekeep Status` via
  `housekeep-state.sh`.
- Author `canonical/skills/aid-housekeep/references/state-preflight.md` (PREFLIGHT body):
  synchronous gate verifying `.aid/` present, not in Plan Mode, git repo present/clean enough
  to branch; on failure exit non-zero with an actionable message and **create no state** —
  mirror `aid-summarize/references/state-preflight.md` (feature-001 SPEC § Feature Flow
  PREFLIGHT).
- Author `canonical/skills/aid-housekeep/references/state-done.md` (DONE body): print closing
  summary (branch name, per-stage commits, "user pushes / opens PR" reminder per C3), HALT
  (feature-001 SPEC § Feature Flow DONE).
- Author the two **inert stub no-op bodies**
  `canonical/skills/aid-housekeep/references/state-summary-delta.md` and
  `canonical/skills/aid-housekeep/references/state-cleanup.md` per feature-001 SPEC §
  "Incremental-delivery stub no-op (skeleton contract)". Each stub body: writes
  `**Stage Status:** skipped` and its own `**<X> Stage:** skipped`
  (`**Summary Stage:** skipped` / `**Cleanup Stage:** skipped`) to `## Housekeep Status` via
  `housekeep-state.sh`, does **no work**, does **not pause**, makes **no commit**, and **CHAINs
  straight onward** (SUMMARY-DELTA → CLEANUP → DONE), so a KB-refresh run terminates cleanly at
  DONE. Each body explicitly documents it is a stub no-op to be replaced by its owning feature
  in a later delivery (003 = summary → task-009; 004 = cleanup → task-012); the stub is distinct
  from a *runtime* `skipped` (a real, fully-implemented stage deciding to skip).
- Wire State Detection / Dispatch to call `housekeep-state.sh` (resume target) and
  `branch-commit.sh` (commit target), to route argument handling in prose (no `parse-args.sh`),
  and to route CHAIN/PAUSE-FOR-USER-ACTION/HALT advances per
  `canonical/templates/state-machine-chaining.md` (feature-001 SPEC § "Advance types").

**Acceptance Criteria:**
- [ ] `SKILL.md` carries the required frontmatter, the `## Dispatch Protocol (L1+L2+L3)` block
  matching `aid-discover/SKILL.md`, the six-row State Detection re-entry table, the five-row
  Dispatch table, and the state-machine-chaining citation line.
- [ ] The `## Arguments` table + State Detection handle the delivery-001 grammar in prose (no
  dedicated arg-parse script): *(none)* → full gated sequence; `--grade X` accepted and passed
  through to SUMMARY-DELTA; `--cleanup-only` is NOT offered/REJECTED in delivery-001; `--fetch`
  is not parsed by the skeleton.
- [ ] PREFLIGHT exits non-zero with an actionable message and writes no `## Housekeep Status`
  state on failure; on success it CHAINs to KB-DELTA.
- [ ] DONE prints branch + per-stage commit summary and the "user pushes / opens PR" reminder,
  then HALTs.
- [ ] Resume routing: a re-run reads `## Housekeep Status` via `housekeep-state.sh` and resumes
  at the first non-`passed`/non-`skipped` stage (AC9); a fully-`DONE` run reports "nothing to
  resume".
- [ ] `state-summary-delta.md` writes `**Summary Stage:** skipped` + `**Stage Status:** skipped`
  and CHAINs to CLEANUP with no work, no pause, no commit; `state-cleanup.md` writes
  `**Cleanup Stage:** skipped` + `**Stage Status:** skipped` and CHAINs to DONE with no work, no
  pause, no commit. Each documents it is a stub no-op to be replaced by its owning feature
  (summary → task-009, cleanup → task-012). Both bodies write only through `housekeep-state.sh`
  (never hand-edit `## Housekeep Status`).
- [ ] All §6 quality gates pass; build/render passes; all existing tests pass.
