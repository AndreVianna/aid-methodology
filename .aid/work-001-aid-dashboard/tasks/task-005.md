# task-005: M3 — type the `## Tasks Status` `Status` column to the closed enum

**Type:** IMPLEMENT

**Source:** feature-001-pipeline-state-architecture → delivery-001

**Depends on:** task-003

**Scope:**
- Type the `## Tasks Status` `Status` column to the closed enum `Pending | In Progress | In Review | Blocked | Done | Failed | Canceled` (feature-001 §2.3 / §4 M3).
- Make `writeback-state.sh --field Status --value …` validate the value against this enum (the six strings produced today from `state-execute.md:165,230,256,311` are unchanged — now validated; `Canceled` is a reserved member with no current task-level producer).
- The validator MUST also accept the empty `_none yet_` placeholder row (feature-001 §2.3; feature-002 DM-5 skips it).
- Behavior diff = none: the produced strings are identical, just constrained. Re-run the FULL `run_generator.py`.

**Acceptance Criteria:**
- [ ] `writeback-state.sh --field Status` accepts exactly the 7 enum members + the `_none yet_` placeholder row, and rejects any other value with a nonzero exit.
- [ ] The six strings the pipeline produces today validate successfully — no observable behavior change (C4); `Canceled` is accepted as a reserved member with no producer.
- [ ] The enum is declared consistently with feature-002's imported `TaskStatus` vocabulary (single source of truth; feature-001 DD enum-drift).
- [ ] FULL generator re-run; no render-drift; `verify_deterministic.py` exits 0.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Unit tests for the `Status` enum validation added (task-006 owns the suite); existing tests pass; FULL generator build passes.
