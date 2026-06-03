# task-002: `branch-commit.sh` — branch-ensure + per-stage commit helper

**Type:** IMPLEMENT

**Source:** feature-001-skill-and-state-machine → delivery-001

**Depends on:** —

**Scope:**
- Implement `canonical/scripts/housekeep/branch-commit.sh` (feature-001 SPEC § Layers &
  Components `branch-commit.sh` bullet, § "C-4. Branch-naming contract", § Git/Version-Control
  Boundary).
- Branch-ensure: read current branch via `git rev-parse --abbrev-ref HEAD`; if `master`,
  create/switch to `aid/housekeep-<slug>` (off current `master` HEAD) via `git switch -c`; if
  already on a branch named `aid/housekeep-*`, reuse it (resume case). Never operate on
  `master` directly.
- Per-stage commit: stage changes (`git add`) and make exactly one commit per stage
  (`git commit`) with a descriptive message (e.g. `chore(housekeep): KB delta refresh
  [feature-002]`). The script contains **no `git push`** and never commits to `master`.
- Bash style per `.aid/knowledge/coding-standards.md`; arg/usage error → exit 2; place under
  `canonical/scripts/housekeep/` per `.aid/knowledge/module-map.md`.

**Acceptance Criteria:**
- [ ] Against a throwaway `git init` repo on `master`, the helper creates an `aid/housekeep-*`
  branch before any mutation and never commits on `master`.
- [ ] When already on an existing `aid/housekeep-*` branch, the helper reuses it (no new
  branch) — the resume case.
- [ ] A commit invocation produces exactly one commit with the supplied message; the script
  source contains no `git push` and the test asserts no remote interaction occurs.
- [ ] A canonical unit suite `tests/canonical/test-housekeep-branch-commit.sh` (auto-discovered
  by the `tests/canonical/test-*.sh` glob, sourcing `tests/lib/assert.sh`) exercises the above
  against a throwaway git repo (feature-001 SPEC § Testing `test-housekeep-branch-commit.sh`).
- [ ] All §6 quality gates pass (NFR1/NFR4/NFR5); build/render passes; all existing tests pass.
