# task-019: CI invariance guard for root `AGENTS.md`

**Type:** TEST

**Source:** feature-006-invariant-agents-md → delivery-005

**Depends on:** task-018

**Scope:**
- Add a CI-able assertion that all four root `AGENTS.md` share one sha256 (feature-006 §6), placed alongside the canonical render/copy tests — either extending `tests/canonical/test-setup.sh` (the SU14a byte-compare, renamed to `test-install.sh` if task-004 has landed) or as a focused check auto-discovered by `tests/run-all.sh`.
- Implement the guard via `sha256sum profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md | awk '{print $1}' | sort -u | wc -l` asserted equal to `1`, so any future maintainer who reintroduces a tool-specific token fails CI.
- Verify the replacement line does not trip any markdown line-length lint applied to these files (§7); trim the parenthetical wording if needed.

**Acceptance Criteria:**
- [ ] A CI-discovered assertion fails when the four root `AGENTS.md` do not share exactly one sha256 and passes on the normalized state (guarding against future drift, since nothing generates these files).
- [ ] The guard is auto-discovered by `tests/run-all.sh` (runs in `test.yml`) and references the four hand-maintained profile files only.
- [ ] The normalized line passes any applicable markdown line-length lint (wording trimmed if required).
- [ ] All §6 quality gates pass.
