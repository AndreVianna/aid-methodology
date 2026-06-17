# task-010: Release-tracking entry + count-drift note

**Type:** DOCUMENT

**Source:** feature-001-projects-command → delivery-002

**Depends on:** — (none)

**Scope:**
- Append a `[NEW]` entry for the `aid projects` command to the Unreleased section of `.aid/knowledge/release-tracking.md` (newest-first), describing the list/add/remove/help command, the deterministic-by-location tier, and the `repos:`→`projects:` terminology/key change. Regenerate `INDEX.md` if required by KB hygiene.
- Add a note (in the work `STATE.md` or a short follow-up marker) that the "N commands" count drift across help/KB docs (`feature-inventory.md`, `infrastructure.md`, file-header comments) is reconciled via `/aid-housekeep` — do NOT reconcile those counts inline here (CI does not catch the drift; precedent: skill-count drift).

**Acceptance Criteria:**
- [ ] `release-tracking.md` Unreleased has an accurate `[NEW] aid projects` entry; INDEX regenerated if needed.
- [ ] The count-drift reconciliation is explicitly deferred to `/aid-housekeep` (recorded, not done inline).
- [ ] All §6 quality gates pass.
