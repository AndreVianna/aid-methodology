# task-001: Frontmatter schema + 14 templates + principles/rubric notes

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Add the 8 new fields to `canonical/aid/templates/kb-authoring/frontmatter-schema.md`:
  `objective:` / `summary:` / `sources:` (required, hand-authored), `tags:` / `see_also:` /
  `owner:` / `audience:` (optional), `approved_at_commit:` (generator-written). Add the field
  table (YAML type / class / default / semantics / well-formedness), the updated canonical YAML
  block (with `intent:` retained + marked superseded during the coexistence window), the
  `owner:`/`audience:` enum-vs-free-string justification, and the `intent:` coexistence/migration note.
- Amend P6 in `canonical/aid/templates/kb-authoring/principles.md`: the required new fields
  (`objective`/`summary`/`sources`) are NOT exempt from review (presence/shape lint applies);
  legacy fields + optional new fields stay exempt.
- Add the `[FM-*]` note to `canonical/aid/templates/kb-authoring/review-rubric.md`: the lint
  REUSES the existing `[FM-MISSING]` (absent required field, HIGH) / `[FM-INVALID]` (malformed
  shape/value, HIGH) tags -- no new tag is introduced; required new fields are graded for
  presence/shape (carve-out), optional fields stay exempt.
- Seed `objective:` / `summary:` / `sources:` (required) + the optional fields into all 14
  `canonical/aid/templates/knowledge-base/*.md` primary/extension templates' frontmatter; keep
  `intent:` during coexistence. Seed `sources: []` only for a genuinely sourceless pure-synthesis
  template. `external-sources.md` is the exception: seed its `sources:` with the external
  URL/registry it summarizes (external URLs, not repo paths), NOT `sources: []`. Leave the `meta`
  `README.md` as-is (lint skips `meta`).
- Edit canonical only; re-run `python .claude/skills/generate-profile/scripts/run_generator.py`
  and commit the regenerated `profiles/` (deferred-aware: render plumbing is exercised here but
  the `extract_list`/generator change lands in task-002).

**Acceptance Criteria:**
- [ ] `frontmatter-schema.md` defines all 8 fields with YAML type, required/optional/generator
  class, default, semantics, and well-formedness rules; `intent:` is retained and explicitly
  marked superseded; the canonical YAML block matches the f001 SPEC.
- [ ] P6 in `principles.md` is narrowed so `objective`/`summary`/`sources` are graded for
  presence/shape while legacy + optional fields stay exempt.
- [ ] `review-rubric.md` documents that the lint reuses `[FM-MISSING]`/`[FM-INVALID]` (no new tag)
  and that required new fields are presence/shape-graded.
- [ ] All 14 `knowledge-base/*.md` templates carry `objective:`/`summary:`/`sources:` + the
  optional fields in their frontmatter seed; `intent:` retained.
- [ ] `external-sources.md`'s seed `sources:` are the external URLs/registry it summarizes (not
  `sources: []`, not repo paths); any genuinely sourceless template uses `sources: []`.
- [ ] The `meta` `README.md` is unchanged.
- [ ] All authored files are canonical (no hand-edited rendered copy); `run_generator.py` re-run
  and regenerated `profiles/` committed -- render-drift CI green.
- [ ] All section-6 quality gates pass (ASCII-where-required, render-drift, KB-hygiene, INDEX-fresh).
