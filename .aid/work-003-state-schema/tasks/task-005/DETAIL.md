# task-005: Migrate on-disk STATE files + verify the real bug is fixed

**Type:** MIGRATE

**Source:** work-003-state-schema -> delivery-001

**Depends on:** task-004

**Scope:**
- Migrate every on-disk `STATE.md` file to the new frontmatter format, preserving each
  narrative body verbatim. Enumerate the live set at execution time — do NOT rely on a
  frozen count: `find .aid -name STATE.md` (the work-002 tree, `.aid/knowledge/STATE.md`,
  and this work's own STATE files).
- **Backfill the newly-captured fields** (not just relocate existing prose): set
  `pipeline.{path,initiator}` per work — work-002 = `full`/`aid-describe`, work-003 = `lite`/
  `aid-refactor`; carry `started`/`minimum_grade`/`user_approved` from each work's header
  blockquote; and for `.aid/knowledge/STATE.md` set `kb_status`/`kb_grade`/`summary_approved`/
  `last_summary`/`last_kb_review` from its header blockquote + Summary-Status.
- Verify end-to-end: the dashboard renders this repo's approved Knowledge Base as
  **approved** with the KB card opening `kb.html` — driven by the new frontmatter format,
  NOT the stopgap markdown edit made on the main checkout. Confirm this fixes the original
  defect (approved KB shown as "Building" / dead button).
- Confirm no status regression during rollout: the tolerant reader (task-002) reads both a
  migrated file and a spot-checked not-yet-migrated (legacy) file correctly.

**Acceptance Criteria:**
- [ ] Every on-disk STATE.md file (live-enumerated via `find .aid -name STATE.md`) migrated to frontmatter format; every narrative body preserved verbatim (diff shows only machine-field relocation) (traces to BLUEPRINT gate criteria #7).
- [ ] The dashboard reads `.aid/knowledge/STATE.md` as approved and the KB card opens `kb.html`, driven by the frontmatter (not the stopgap) (traces to BLUEPRINT gate criteria #2).
- [ ] No status regression: a migrated file and a legacy-format fallback file both read correctly (traces to BLUEPRINT gate criteria #6).
- [ ] The newly-captured + relocated frontmatter fields are backfilled per work (`pipeline.{path,initiator}`; `started`/`minimum_grade`/`user_approved`; KB run-state fields) (traces to BLUEPRINT gate criteria #13).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
