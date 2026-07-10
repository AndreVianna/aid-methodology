# task-001: Define the STATE YAML-frontmatter schema + update the 4 templates

**Type:** DESIGN

**Source:** work-003-state-schema -> delivery-001

**Depends on:** — (none)

**Scope:**
- Define a structured YAML-frontmatter schema for the machine-parsed values in each STATE
  file type (work / delivery / task / discovery): approval, machine/human grades, status +
  lifecycle enums (closed sets, values preserved verbatim), doc/task counts, output path,
  timestamps.
- Embody the schema in the **canonical** STATE templates — edit
  `canonical/aid/templates/{work,delivery,task,discovery}-state-template.md` (NOT the
  generated `.claude/aid/...` mirror): add the frontmatter block, relocate machine fields
  out of the prose (blockquote / table / bold-label forms) into it, keep narrative sections
  (Review History, Q&A, Calibration Log, Lifecycle History) as markdown body.
- **Additive, not greenfield:** the KB `discovery-state` STATE.md already carries a YAML
  frontmatter block (kb-category/source/objective/… with zero machine-state keys), so the
  schema adds machine keys to an existing block rather than introducing one.
- **Account for the post-merge template reality:** the `work-state-template` was rewritten for
  flattened works and the reader now accepts dual section spellings (`## Pipeline State|Status`,
  `## Tasks State|Status`) and a flat/Lite layout (`### Tasks lifecycle`, singular
  `## Delivery Gate`). The schema must cover both the full and flat layouts and not regress the
  dual-name acceptance.
- Record the schema in a work-local schema note (design artifact under
  `.aid/work-003-state-schema/`). Do NOT edit the KB `artifact-schemas.md` here — that
  refresh rides the post-merge `/aid-housekeep`.
- Render: run `python .claude/skills/generate-profile/scripts/run_generator.py` to render
  `canonical/` into all 5 `profiles/`, resync the dogfood `.claude/`, and confirm
  `tests/canonical/test-dogfood-byte-identity.sh` passes.
- No reader or writer code changes in this task (task-002 / task-004).

**Acceptance Criteria:**
- [ ] A documented frontmatter schema covers every machine-parsed field the reader twins consume, per STATE file type, with closed-enum values preserved verbatim (traces to BLUEPRINT gate criteria #1).
- [ ] All 4 **canonical** STATE templates carry the frontmatter block; machine fields live there; narrative sections remain markdown body (traces to BLUEPRINT gate criteria #1, #7).
- [ ] The schema note maps each field to its exact frontmatter key and the legacy prose location it replaces (unambiguous mapping for task-002/004).
- [ ] `run_generator.py` re-rendered; `tests/canonical/test-dogfood-byte-identity.sh` passes (canonical → profiles + dogfood in sync) (traces to BLUEPRINT gate criteria #8).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
