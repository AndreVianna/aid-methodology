# task-004: Bash installer test suite (`test-install.sh`)

**Type:** TEST

**Source:** feature-001-shared-install-core-and-bootstrap → delivery-001

**Depends on:** task-003

**Scope:**
- Author `tests/canonical/test-install.sh` per feature-001 §Testing-approach, mirroring the existing `tests/canonical/test-*.sh` conventions (auto-discovered by `tests/run-all.sh`; `source ../lib/assert.sh`; `mktemp -d` targets; exit 0/1).
- Cover: fresh install per tool; byte-fidelity vs `profiles/<tool>/` (SU06f/SU14 patterns); idempotent re-install → `Up to date:`; `--force` over a locally edited file; manifest written with correct paths/version/root_agent sha; uninstall removes exactly the manifested paths and leaves the repo pre-install-clean.
- Cover protect-on-diff (pre-place a user `AGENTS.md`, install codex → no overwrite, `AGENTS.md.aid-new` created, exit 5; `--force` → overwritten); uninstall safety (modify AID-owned `AGENTS.md`, uninstall → left in place); comma-list `--tool codex,cursor` (second AGENTS.md write triggers protect-on-diff pre-FR12); auto-detect (single→used, two→exit 2, none→exit 2); usage errors (unknown flag → 2, missing target → 2).
- Drive network paths via `--from-bundle` with a locally-built fixture tarball (no live GitHub calls in CI); cover the online `/latest`+download path via a stubbable/network-gated function-level test.
- Own the bash-side rename: remove/rename the legacy `tests/canonical/test-setup.sh` to `tests/canonical/test-install.sh` as part of this task (task-008's reference-cleanup grep excludes the `test-setup*.sh` suite files, which are owned here and in task-006).

**Acceptance Criteria:**
- [ ] All install/update/uninstall, byte-fidelity, manifest, auto-detect, and usage-error cases pass and are auto-discovered by `tests/run-all.sh`.
- [ ] The protect-on-diff case asserts the **default exit 5** when a root agent file is blocked without `--force`, the `*.aid-new` artifact, and the `--force` override.
- [ ] The suite is CI-safe: install network paths run only via `--from-bundle` fixtures; the live `/latest` path is stubbed or network-gated to avoid rate-limit flakiness.
- [ ] `tests/canonical/test-setup.sh` is removed/renamed to `test-install.sh` (the legacy setup suite no longer runs).
- [ ] All §6 quality gates pass.
