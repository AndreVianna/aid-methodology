# task-009: CORE test suites — declared-set read/resolve + mapping

**Type:** TEST

**Source:** feature-004-declared-doc-set → delivery-002 (CORE wave)

**Depends on:** task-007, task-008

**Scope:**
- Add `tests/canonical/test-doc-set-read.sh`: unset ⇒ default-seed; present ⇒ exact rows + all 4 accessors; trailing inline `#` stripped + a full-line trailing comment doesn't truncate; **comma-in-`when` safety invariant** (fragment 1 survives as a valid `discovery-quality` record with a truncated display-only `when`; fragments 2+ warn + skip; no wrong/unknown-owner dispatch; a comma-free `;`/`/` rephrase parses cleanly); no `category`/`expectations` in output; unknown-owner ⇒ architect + warn; dependency-free.
- Add `tests/canonical/test-doc-set-mapping.sh` (MECHANICAL): no-hang-on-omission; dispatch-on-addition; carve-out-as-config (the §1.4 set contains `pipeline-contracts`/`schemas`/`repo-presentation` and excludes `api-contracts`/`data-model`/`ui-architecture`/`security-model`); non-software fixture (declared set differs-from-default + user-edit honored-verbatim + equals list-filenames).
- Auto-discovered; follow existing suite shape; bash+awk only (no yq/python/new script).

**Acceptance Criteria:**
- [ ] Both suites pass; the comma-in-`when` test asserts the safety invariant (no wrong/unknown-owner dispatch), not blanket rejection.
- [ ] Carve-out and non-software assertions are mechanical set-difference checks (no "appropriateness" claim).
- [ ] `bash tests/run-all.sh` all green; suites run with only bash+awk.
- [ ] All §6 quality gates pass (deterministic, clean setup/teardown, render-drift clean).
