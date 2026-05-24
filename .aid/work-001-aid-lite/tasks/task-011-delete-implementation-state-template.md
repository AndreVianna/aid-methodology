# task-011: Delete `canonical/templates/implementation-state.md` + orphan-ref grep sweep

**Type:** IMPLEMENT

**Source:** feature-002-skill-footprint-refactor → delivery-001

**Depends on:** —

**Scope:**
- Delete `canonical/templates/implementation-state.md` (purpose now absorbed by work-003's per-area STATE rule).
- Grep across `canonical/`, `profiles/`, `.aid/` for any remaining reference to `implementation-state.md`.
- Update or remove every stale reference (commit messages excluded).
- Re-run work-002 generator + verify install trees no longer contain a copy.

**Acceptance Criteria:**
- [ ] `canonical/templates/implementation-state.md` does not exist.
- [ ] `grep -r 'implementation-state.md' canonical profiles .aid` returns zero matches (excluding `.git/`).
- [ ] Generator output (3 install trees) does not contain `implementation-state.md`.
- [ ] Manifest re-committed (`canonical/EMISSION-MANIFEST.md` no longer claims the file).
- [ ] All §6 quality gates pass.
