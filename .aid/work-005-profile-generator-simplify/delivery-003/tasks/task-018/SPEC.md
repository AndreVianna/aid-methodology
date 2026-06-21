# task-018: Promote capability-study to durable host-tool-capabilities.md KB doc

**Type:** DOCUMENT

**Source:** work-005-profile-generator-simplify -> delivery-003

**Depends on:** task-016, task-017

**Scope:**
- Promote the **verified** work-local study `.aid/work-005-profile-generator-simplify/research/capability-study.md` (feature-001's owned deliverable, carrying both the per-tool table and the embedded decision section) to a durable primary KB doc at `.aid/knowledge/host-tool-capabilities.md`, per feature-004 SPEC §B.3.iv / §B.4 (OQ4 option a):
  - **Promote/copy the verified content — do NOT re-derive or re-run the study.**
  - Include the per-tool capability matrix (discovery / execution / activation / capability / dispatchability + the always-on verdict).
  - Add `kb-category:` and `intent:` frontmatter so the doc is INDEX-discoverable.
  - Structure it so a 6th host tool slots in identically (NFR5 future-tool-extensible design).
- Add `[CHANGE]` entries for work-005 to the Unreleased section of `.aid/knowledge/release-tracking.md` (per the release-tracking KB convention, newest-first).
- **Out of scope (do NOT touch):** the INDEX.md/README.md regen (task-019 — this task only *adds* the doc + release-tracking entries; the index regen is a separate CONFIGURE task), the other KB term edits (tasks 016/017), and any `canonical/*`/generator/`lib/*` surface.

**Acceptance Criteria:**
- [ ] `.aid/knowledge/host-tool-capabilities.md` exists with `kb-category:` + `intent:` frontmatter and the per-tool capability matrix (discovery/execution/activation/capability/dispatchability + always-on verdict).
- [ ] The doc is structured so a 6th tool slots in identically (NFR5 extensibility evident in the matrix layout).
- [ ] The content is the **promoted verified study** from `research/capability-study.md`, not a re-derivation.
- [ ] `.aid/knowledge/release-tracking.md` Unreleased section carries the work-005 `[CHANGE]` entries.
- [ ] DOCUMENT default: accuracy verified against the verified source study and the current layout.
- [ ] All §6 quality gates pass.
