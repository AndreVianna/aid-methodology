# task-003: M2 — `writeback-state.sh --pipeline` mode (sentinel-locked, enum-validated)

**Type:** IMPLEMENT

**Source:** feature-001-pipeline-state-architecture → delivery-001

**Depends on:** task-002

**Scope:**
- Add a new `writeback-state.sh --pipeline --field FIELD --value VALUE` mode to `canonical/scripts/execute/writeback-state.sh` (feature-001 §4 M2) — the ONLY writer of the `## Pipeline Status` block.
- Reuse the EXISTING sentinel lock (`writeback-state.sh:138-168`) — do not introduce a new lock — so the new mode is safe on the parallel-pool hot path.
- Validate each written field against the closed enums declared in `work-state-template.md` (task-002): reject `Lifecycle`/`Phase`/`Active Skill` values outside their enum; manage the conditional `Pause/Block Reason/Artifact` fields (present only for the matching `Lifecycle`).
- The new write prints no user-facing line and gates nothing (behavior-preserving — feature-001 §5 risk row).
- Re-run the FULL `run_generator.py` (the script renders into 7 byte-identical copies).

**Acceptance Criteria:**
- [ ] `writeback-state.sh --pipeline` writes/updates the `## Pipeline Status` block fields as `**Field:** value` lines, grep-recoverable, matching the template shape (feature-001 §2.2).
- [ ] Enum validation rejects an out-of-enum `Lifecycle`/`Phase`/`Active Skill` value with a nonzero exit; the conditional `Pause/Block` fields are written only when `Lifecycle` matches.
- [ ] The mode acquires the existing sentinel lock (no new mutex) and is the sole writer of the block (never hand-edited).
- [ ] The write emits no user-facing output and changes no existing `writeback-state.sh` mode behavior (`--field`/`--findings`/`--block`/`--append-issue` unchanged); C4 observable-behavior preservation holds.
- [ ] FULL generator re-run; 7 byte-identical copies; `verify_deterministic.py` exits 0.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Unit tests for the new `--pipeline` mode's public behavior added (task-004 owns the suite); existing tests pass; FULL generator build passes.
