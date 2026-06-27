# task-008: record M1 publish-enablement deferral

**Type:** DOCUMENT

**Source:** work-001-aid-interview-improvements -> delivery-002

**Depends on:** -- (none)

**Scope:**
- Record the M1 disposition per feature-007's recommended path: an EXPLICIT
  deferral-with-rationale (M1 closure -- creating the npm `@aid` scope + PyPI org/Trusted-Publisher
  and flipping `NPM_ENABLED`/`PYPI_ENABLED` -- is owner-only and externally blocked, so it cannot
  be closed by an agent; per AC-9 an explicit deferral satisfies the criterion).
- Write the deferral + rationale into (a) the work `STATE.md` (a Cross-phase Q&A or
  delivery-002 note capturing the decision) and (b) the `.aid/knowledge/tech-debt.md` M1 row
  (status = deferred, with the rationale and the owner steps required to close it later).
- Verify the claim it rests on: confirm `.github/workflows/release.yml` already gates publishing on
  `vars.NPM_ENABLED` / `vars.PYPI_ENABLED` (the workflow is OIDC-ready), so the deferral is
  accurate, not an excuse to skip real work.
- Documentation/tracking only -- NO code change, NO CI change, NO publish triggered. If the owner
  later chooses to CLOSE M1 instead, that is a separate owner-driven CONFIGURE action out of this
  task's scope.

**Acceptance Criteria:**
- [ ] The M1 deferral-with-rationale is recorded in the work `STATE.md` and the `tech-debt.md` M1 row (status + rationale + owner steps to close). *(M1; AC-9)*
- [ ] The rationale is accurate: `release.yml` is confirmed to already gate publish on `vars.NPM_ENABLED`/`vars.PYPI_ENABLED` (cited by file + the gating lines). *(DOCUMENT default: accuracy verified against codebase)*
- [ ] No code, CI, or publish behavior is changed; no real npm/PyPI publish is triggered. *(scope boundary; M1 "no code task")*
- [ ] `tech-debt.md` edit keeps KB-hygiene green (INDEX regen via canonical script if needed). *(index-md-canonical-regen)*
- [ ] All REQUIREMENTS.md §6 quality gates pass.
