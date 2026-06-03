# task-007: Regenerate install trees and verify all three + full test suite

**Type:** CONFIGURE

**Source:** work-002-canonical-bug-fixes → delivery-001

**Depends on:** task-001, task-002, task-003, task-004, task-005, task-006

**Scope:**
- All fixes in this work edit `canonical/` only; the three install trees (`claude-code`, `codex`,
  `cursor`) and `.aid/generated/` are stale until regenerated. Run `/aid-generate` (LOAD → VALIDATE
  → RENDER → VERIFY → REPORT) to re-render the canonical sources into all three trees.
- Confirm the regenerated trees reflect every fix: the two `scripts/execute/` scripts
  (`complexity-score.sh`, `compute-block-radius.sh`), and the `interviewer` / `tech-writer` /
  `simple-formatter` / `discovery-quality` / `discovery-reviewer` / `reviewer` agent files.
- Run the full canonical test suite (`bash tests/run-all.sh`) and the generator's own VERIFY step;
  both must be green.

**Acceptance Criteria:**
- [ ] `/aid-generate` completes with VERIFY passing and no drift reported.
- [ ] The fixed scripts and agent files are present and correct in all three install trees
      (claude-code, codex, cursor).
- [ ] `bash tests/run-all.sh` passes in full.
- [ ] All §6 quality gates pass.
