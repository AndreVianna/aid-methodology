# task-016: Final full-suite reconciliation green sweep (CODE/STATE consistency, bash + ps1)

**Type:** TEST

**Source:** feature-005-bootstrap-and-test-migration → delivery-003

**Depends on:** task-014, task-015

**Scope:**
- Run the final full-suite reconciliation green sweep (feature-005 Testing "Full sweep green" + "No conflation remains"). The breaking-test migration of categories C1-C5 was pulled forward into d001/d002; this task confirms whole-suite consistency, bash + ps1 in lockstep.
  - **Full sweep green, HOME-pinned:** `bash tests/run-all.sh` passes end-to-end, with every migration/encounter suite pinning a throwaway `HOME` and the escape canary intact.
  - **No conflation remains (audit grep over `tests/canonical/*`):** zero `$AID_HOME/lib` / `$AID_HOME/VERSION` references that assume code relocation by `AID_HOME` (categories C1), and zero live `.migrated` / `_aid_scan_for_repos` / `_aid_check_migrate_sentinel` / `_aid_write_migrated_marker` references (C2/C3). Confirm the install-suite fixture refs (`test-npm-installer.sh` l.350-354, `test-pypi-installer.sh` l.295-299, `test-release-install-e2e.sh` l.484-486) are re-anchored on the code-home payload, and `test-release-migrate-smoke.sh` (l.9-10) describes "first encounter stamps + registers", not the removed sentinel.
  - Confirm no stray `$AID_HOME/lib`, `$AID_HOME/VERSION`, or `.migrated` reference survives end-to-end (AC4/AC8; NFR test-suite compatibility).
- Any drift surfaced is reconciled here (the closeout sweep), keeping bash and ps1 in lockstep. No production code edits beyond test-file reconciliation.

**Acceptance Criteria:**
- [ ] `bash tests/run-all.sh` passes end-to-end HOME-pinned, with the escape canary intact on every migration/encounter suite.
- [ ] An audit grep over `tests/canonical/*` finds zero code-relocation-by-`AID_HOME` `$AID_HOME/lib` / `$AID_HOME/VERSION` refs and zero live `.migrated` / scan / sentinel / marker refs (C1-C3 fully discharged).
- [ ] Install-suite fixture refs are re-anchored on the code-home payload; `test-release-migrate-smoke.sh` describes the stamp+register encounter model.
- [ ] bash and ps1 suites are consistent (lockstep) with the CODE/STATE split.
- [ ] All §6 quality gates pass.
