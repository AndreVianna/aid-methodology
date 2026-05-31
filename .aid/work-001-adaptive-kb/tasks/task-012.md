# task-012: DERIVATION test suite — propose→confirm + edit-honored

**Type:** TEST

**Source:** feature-004-declared-doc-set → delivery-002 (DERIVATION wave)

**Depends on:** task-010, task-011

**Scope:**
- Add `tests/canonical/test-doc-set-propose-confirm.sh`:
  - **default path**: no override ⇒ resolved set == default seed; propose→default→confirm is a no-op (writes nothing).
  - **user-edit path**: a fixture `settings.yml` with an omission + an addition ⇒ the resolved set honors both verbatim (AC4 edits-honored), mechanically (no "appropriateness" assertion).
- Do NOT duplicate the carve-out / non-software set-difference already covered by `test-doc-set-mapping.sh` (task-009) — single home per invariant; assert here only the propose→confirm-specific edit-honored path.
- Auto-discovered; existing suite shape; bash+awk only.

**Acceptance Criteria:**
- [ ] Default path is a no-op; user-edit path honors omission + addition verbatim (mechanical).
- [ ] No assertion duplicates the carve-out/non-software set-difference covered in task-009.
- [ ] `bash tests/run-all.sh` all green (now +5 suites total from this work).
- [ ] All §6 quality gates pass (deterministic, clean setup/teardown, render-drift clean).
