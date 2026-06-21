# task-019: KB INDEX regeneration and README completeness update

**Type:** CONFIGURE

**Source:** work-005-profile-generator-simplify -> delivery-003

**Depends on:** task-016, task-017, task-018

**Scope:**
- Regenerate `.aid/knowledge/INDEX.md` via the **canonical** script (NOT hand-edited — per the INDEX-md-canonical-regen rule; the `kb-hygiene` CI INDEX-fresh check fails on the embedded script path if the wrong copy is used), per feature-004 SPEC §B.3.v:
  - `bash canonical/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`
  - This must run **after** the KB content edits (tasks 016/017) and the new doc (task-018) so the INDEX reflects `host-tool-capabilities.md` and the retired terms.
- Update `.aid/knowledge/README.md` (`kb-category: meta` completeness tracker) to reflect the new `host-tool-capabilities.md` doc and the retired terms — update the completeness table/count and the revision history.
- **Out of scope (do NOT touch):** the KB content docs themselves (tasks 016/017/018 own those), any numeric script/suite counts (deferred to `/aid-housekeep`, OQ2), and all `canonical/*` source / generator / `lib/*` surfaces (only the `build-kb-index.sh` *invocation* is in scope, not editing the script).

**Acceptance Criteria:**
- [ ] `.aid/knowledge/INDEX.md` is regenerated via the canonical `canonical/scripts/kb/build-kb-index.sh` (not hand-edited) so the `kb-hygiene` INDEX-fresh check passes clean.
- [ ] INDEX.md reflects the new `host-tool-capabilities.md` doc and the task-016/017 retirements.
- [ ] `.aid/knowledge/README.md` reflects the new doc (completeness count/table) and the retired terms, with an updated revision-history entry.
- [ ] The regen is idempotent: re-running `build-kb-index.sh` produces no diff.
- [ ] CONFIGURE defaults: configuration is idempotent; no plaintext secrets.
- [ ] All §6 quality gates pass.
