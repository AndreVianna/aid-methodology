# task-011: Cross-cutting regressions + path-ref triage + run-all + render-drift + Windows/workflow smokes

**Type:** TEST

**Source:** work-003-content-isolation → delivery-001

**Depends on:** task-003, task-004, task-005, task-007, task-008, task-010

**Scope:**
- Add regression tests covering: orphan `aid-*` removed on update; user (non-`aid-`) files untouched by the prune; `.github` prune scoped to `{agents,skills,aid}` (R1); nested-path resolution works (a rewritten `canonical/scripts/...` body resolves under `<install_root>/aid/scripts/...`); root-agent in-place region update preserves user content outside markers; NO `.aid-new` written under any branch; both root-agent migration branches (sha-match clean rewrite; sha-mismatch excise-and-rewrap in place).
- Triage the ~80 affected test path-refs: repo-root dev invocations under `canonical/` are unaffected; install-root/profile-root refs must move to the nested (`aid/…`) or `aid-`-prefixed paths.
- Run the FULL `tests/run-all.sh` (51 suites, HOME pinned per the migration-scan hazard) and confirm green; confirm generator render-drift is clean (FULL `run_generator.py`, second run byte-identical).
- Update the Windows-only `tests/windows/Test-AidInstaller.ps1` and the workflow inline smokes (both outside `run-all.sh`) wherever this work changed install/CLI behavior (prune, root-agent region update); push and watch Windows CI.

**Acceptance Criteria:**
- [ ] New regression tests assert: orphan `aid-*` removed; user files untouched; `.github` prune scoped (R1); nested-path resolution; root-agent region update + user-content preserved; no `.aid-new`; both migration branches.
- [ ] All ~80 path-refs are triaged; install-root/profile-root refs updated to nested/prefixed paths; canonical repo-root dev invocations confirmed unaffected.
- [ ] `tests/run-all.sh` is green (51 suites) with HOME pinned; render-drift is clean (second FULL `run_generator.py` byte-identical; VERIFY deterministic passes).
- [ ] `tests/windows/Test-AidInstaller.ps1` and the workflow inline smokes are updated for the prune + root-agent behavior and Windows CI is green.
- [ ] All §6 quality gates pass.
