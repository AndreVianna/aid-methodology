# task-074: DESIGN — settings.yml validate/repair + era-b synthesis contract (DM-1/DD-3/RC-4)

**Type:** DESIGN

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** none (Wave-1 design seam; independent start)

**Scope:**
- Pin the exact **"valid" definition** the Wave-2 SETTINGS step (task-077) repairs/synthesizes to, so all
  current readers parse **without falling back** (SPEC DM-1 "valid" contract; grounding §1). A settings.yml
  is valid iff: a top-level `project:` block carrying `name:` (non-empty, single-line) and `description:`
  (present, single-line, no newlines), `project.type` ∈ {`brownfield`,`greenfield`}, plus the four scalar
  sections present + well-typed: `tools.installed` (list, ≥0 entries, block must exist),
  `review.minimum_grade` (`^[A-F][+-]?$`), `execution.max_parallel_tasks` (int>0),
  `traceability.heartbeat_interval` (int≥0). Enumerate every **REQUIRED** key vs every **OPTIONAL/preserve**
  key from the DM-1 table (REQUIRED: project.name/description/type, tools.installed, review.minimum_grade,
  execution.max_parallel_tasks, traceability.heartbeat_interval; OPTIONAL/PRESERVE-verbatim:
  `kb_baseline.{branch,tip_date}` and `<skill>.minimum_grade` overrides).
- Specify the **readers the output must stay parseable for** (the validate-against set; grounding §1):
  `canonical/scripts/config/read-setting.sh` (awk flat-section + list lookup), the dashboard server
  `_read_settings` (`dashboard/server/server.py:189-214` line-scan `project:`→`name:`/`description:`; Node
  twin), the reader `parse_project_name` (`parsers.py:155-199`), `parse_kb_baseline` (`parsers.py:231-279`),
  `_strip_yaml_inline_comment` (`parsers.py:202-228`). The repaired/synthesized shape MUST NOT trip any
  fallback (`(None,None)`, basename-fallback, baseline-skip).
- Define the **targeted-edit-not-overwrite repair rules** (DD-3/R21 — the highest-consequence hazard):
  era-a repair edits **only** the missing/malformed REQUIRED keys, leaving every present `kb_baseline` and
  per-skill override **byte-intact**; it reuses the `/aid-config` crash-safe idioms — single-line in-place
  replace (`canonical/skills/aid-config/SKILL.md:124`) for a present-but-malformed scalar, append-block
  (`:126-132`) for a wholly-missing required section — written via **temp-file + `mv -f`** (never an
  in-place truncating rewrite). Decide and record the repair granularity (OQ-4: edit-missing-keys-in-place
  vs rewrite-from-template-splicing-back-preserved-blocks) — pick the simplest-correct; the invariant
  (preserve `kb_baseline`+overrides, crash-safe) is fixed.
- Define the **era-b synthesis field map** (RC-4/DD-2): when no `settings.yml` exists but a
  `.aid/knowledge/{DISCOVERY_STATE.md|DISCOVERY-STATE.md|STATE.md}` marker does, synthesize a fresh
  template-derived file — `project.name` = repo folder **basename** (the dashboard's own fallback,
  `models.py:166`), `project.type` = `brownfield`, `project.description` = placeholder/empty,
  `tools.installed` = keys of `.aid/.aid-manifest.json` `"tools"` (via the existing `manifest_list_tools`/
  `manifest_read_*` readers in `lib/aid-install-core.sh`, NOT from STATE.md — DD-2), and
  `review`/`execution`/`traceability` = template defaults (`A`/`5`/`1`). Confirm STATE.md/DISCOVERY_STATE.md
  carry **no** name/description/tools (grounding §2b) and are used **only** to qualify the repo as era-b.
- Output a concise design note (added to `.aid/work-001-aid-dashboard/design/`, e.g.
  `feature-011-settings-contract.md`): the valid/required/optional key matrix, the era-a repair decision
  tree (per-key keep-if-valid-else-default, preserve-optional), the era-b synthesis field map, and the
  exact crash-safe write idiom mapping — the seam task-077's SETTINGS step (and task-081's era-a/era-b unit
  tests) resolve against. **No production code; advisory only** (the implementation is task-077).

**Acceptance Criteria:**
- [ ] The "valid" definition is pinned as a per-key matrix (REQUIRED vs OPTIONAL/PRESERVE) covering every
      DM-1 key, and explicitly names the reader set (read-setting.sh, server `_read_settings`,
      parse_project_name/parse_kb_baseline) the shape must not trip into a fallback.
- [ ] The era-a repair rule is **targeted-edit-not-overwrite** (DD-3/R21): only missing/malformed REQUIRED
      keys are touched; present `kb_baseline` + per-skill overrides are preserved byte-intact; the write is
      crash-safe (temp-file + `mv -f`), reusing the `/aid-config` single-line-replace + append-block idioms.
- [ ] The era-b synthesis field map is fully specified (basename name, brownfield type, placeholder
      description, manifest-derived `tools.installed` via `manifest_list_tools`, template defaults
      elsewhere) and confirms STATE.md is a qualifier only, not a config source (DD-2/RC-4).
- [ ] The repair-granularity residual (OQ-4) is resolved with a recorded simplest-correct decision; the
      invariant (preserve + crash-safe) is restated as the fixed contract for task-077.
- [ ] The design note is written and the seam is unambiguous enough that task-077 can implement and
      task-081 can assert era-a-repair-preserves and era-b-synthesize without re-deciding any contract.
