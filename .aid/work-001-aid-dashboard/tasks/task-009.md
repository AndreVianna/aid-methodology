# task-009: M4+M5 behavior-preservation walk-through tests

**Type:** TEST

**Source:** feature-001-pipeline-state-architecture → delivery-001

**Depends on:** task-008

**Scope:**
- Add walk-through / integration tests validating the C4 invariant (feature-001 §4 verification surface + AC3): after wiring M4 (phase emits) and M5 (pause/block emits), observable pipeline behavior — same phases, same gates, same outputs, same decisions — is unchanged.
- Cover: a full-path phase progression (Interview→…→Deploy) confirming the `## Pipeline Status` `Phase`/`Active Skill` track correctly AND no new prompt/gate appeared; a pause/resume flow (pending Q&A / approval gate) confirming `Paused-Awaiting-Input` ↔ `Running`; an impediment flow confirming `Blocked` with the correct `Block Artifact` and that the existing impediment behavior is unchanged.
- Treat any observable-behavior change as a CRITICAL finding (feature-001 AC3 / §4 checklist).
- Confirm the full C4 surface stays green: FULL generator (no render-drift), `tests/run-all.sh` (35 suites), Windows installer suite, ASCII-only gate.

**Acceptance Criteria:**
- [ ] A full-path progression test asserts the `Phase`/`Active Skill`/`Lifecycle` block values match the phase reached at each transition AND that no new prompt/gate/output was introduced.
- [ ] Pause/resume and impediment walk-throughs assert the `Lifecycle` enum transitions match feature-001 §3 SM and that the existing flows are byte/behavior-identical to pre-change (C4).
- [ ] Any observable-behavior divergence is surfaced as a CRITICAL-class failure (feature-001 AC3).
- [ ] The full C4 verification surface (render-drift, `run-all.sh`, Windows installer suite, ASCII-only) is green.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean per-case setup/teardown and cover the source ACs (feature-001 AC2/AC3); FULL generator build passes.
