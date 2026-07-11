# task-001: Define the STATE YAML-frontmatter schema + update the 4 templates

**Type:** DESIGN

**Source:** work-003-state-schema -> delivery-001

**Depends on:** — (none)

**Scope:**
- Define the structured YAML-frontmatter schema for the machine-parsed values in each STATE
  file type, and embody it in the **canonical** templates
  `canonical/aid/templates/{work,delivery,task,discovery}-state-template.md` (NOT the generated
  `.claude/aid/...` mirror). Machine fields move into the frontmatter block; narrative sections
  (Review History, Q&A, Calibration Log, Lifecycle History) stay markdown body.

- **Work `STATE.md` frontmatter — fields (relocated + newly-captured):**
  - `pipeline:` block — `path: lite|full` (retires the `_detect_flat` "lite" hard-fallback) and
    `initiator: <skill>` (the pipeline-starting skill — a shortcut skill `aid-refactor`/`aid-fix`/…
    from `shortcut-catalog.yml`, or `aid-describe`; supersedes the null `recipe`).
  - Relocated (already parsed from prose → move to frontmatter, **behavior preserved**):
    `lifecycle`, `phase`, `active_skill`, `updated`, `pause_reason`, `block_reason`,
    `block_artifact` (from `## Pipeline State`, closed enums verbatim); and `minimum_grade` —
    which is ALREADY parsed (`_parse_minimum_grade`, `derivation.py:1065`) and drives the
    sub-minimum Blocked gate, so the move MUST keep that parse + Blocked behavior (do not drop it).
  - **Newly captured (authored but genuinely never parsed):** `started` (retires the fragile
    "Work created" `## Lifecycle History` row-scrape for `created`) and the WORK-level
    `user_approved` (distinct from the KB approval).
  - Delivery lifecycle/gate scalars for flattened works (`delivery_state`, `gate_grade`,
    `gate_tier`, `gate_timestamp`) as frontmatter; the `### Tasks lifecycle` per-task table stays body.
  - Keep INFERRED (do NOT author): `number` (folder), `branch` (git worktree),
    `title`/`description`/`objective` (REQUIREMENTS/SPEC content files). Keep DERIVED (counts,
    readiness/execution %, `source_mode`) computed, not stored.

- **Discovery `.aid/knowledge/STATE.md` frontmatter — extend the existing block** (it already
  carries doc-routing keys) with a run-state group:
  - **Genuinely never-parsed** (authored in the header blockquote, invisible to the reader):
    `kb_status`, `kb_grade`, `last_kb_review`.
  - **Already read but brittle** (relocate, preserving behavior): `summary_approved` — as a single
    scalar that eliminates the table-row-vs-bold-line dual-representation that caused the original
    bug — and `last_summary` (both currently read by `parse_kb_state`/`_parse_kb_summary_approval`).
  - Keep DERIVED/other-file (`doc_count` from README, `kb_baseline` from settings.yml,
    `summary_present` from kb.html stat, freshness) out of STATE.

- Record the schema in a work-local schema note (field → frontmatter key → legacy prose location it
  replaces) so task-002/004/005 have an unambiguous mapping.
- Render: `python .claude/skills/generate-profile/scripts/run_generator.py` → all 5 profiles +
  dogfood resync; `tests/canonical/test-dogfood-byte-identity.sh` passes. No reader/writer code here.

**Acceptance Criteria:**
- [ ] The frontmatter schema covers every machine-parsed field the reader twins consume — relocating the already-parsed ones (incl. `minimum_grade`, KB `summary_approved`/`last_summary`) with closed-enum values verbatim and no behavior change — AND adds the genuinely-missing fields (`pipeline{path,initiator}`, `started`, work-level `user_approved`, KB `kb_status`/`kb_grade`/`last_kb_review`) (traces to BLUEPRINT gate criteria #1, #13).
- [ ] All 4 canonical STATE templates carry the frontmatter block; machine fields live there; narrative sections remain markdown body; inferred/derived values are explicitly NOT authored (traces to BLUEPRINT gate criteria #1, #7).
- [ ] The schema note maps each field to its key + the legacy prose location (unambiguous for task-002/004/005), and lists the keep-inferred / keep-derived exclusions.
- [ ] `run_generator.py` re-rendered; `tests/canonical/test-dogfood-byte-identity.sh` passes.
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
