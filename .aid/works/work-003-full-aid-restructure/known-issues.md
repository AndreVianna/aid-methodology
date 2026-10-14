# Known Issues

<!-- Scoped to this work. Only issues that affect features in this work. -->
<!-- Created/updated by aid-specify during codebase exploration. -->
<!-- Consumed by aid-plan for deliverable sequencing. -->

<!-- Entry format:
## KI-NNN: {Title}
- **Type:** Bug | Security | Deprecated Dependency | Breaking API Contract
- **Severity:** Critical | High | Medium
- **Affects:** feature-NNN-{name}, feature-NNN-{name}
- **Source:** {file path}:{line} or {dependency}:{version}
- **Description:** {what's wrong and why it matters for the affected features}
- **See also:** tech-debt.md #TD-NNN (if already catalogued in KB)
-->

## KI-001: The always-loaded rules send agents to a work state file that no longer exists

- **Type:** Bug
- **Severity:** Medium
- **Affects:** Feature 001 — Ask for Work in Plain Language
- **Source:** `canonical/aid/rules.md` § Tracking discipline (IMPERATIVE) -- the sentence "the work's `.aid/works/work-NNN-*/STATE.md`" and the bullet "whether on the FULL or the LITE path"; installed verbatim as `.aid/runtime/rules.md`
- **Description:** The rules every session reads first name the work's state file as `STATE.md`, but a work's state lives in `STATE.yml` (`canonical/aid/templates/work-state-template.yml`). An agent that follows the rule literally creates or looks for a markdown file that no reader parses. The same section also speaks of a "FULL or LITE path", a split this work removes. Feature 001 rewrites the neighbouring `## Workflow` section into the orchestration section and makes the rules the place every plain request is routed from, so leaving the stale sentence in place undercuts the very file the feature depends on. It does not block the feature, but every new session inherits the wrong pointer until it is fixed.
- **See also:** tech-debt.md #SY-6 (the same stale name in `canonical/skills/**`; that entry does not cover `rules.md`)

## KI-002: Work state written in shapes the dashboard readers silently drop

- **Type:** Bug
- **Severity:** Medium
- **Affects:** Feature 001 — Ask for Work in Plain Language; Feature 002 — Clear, Step-by-Step Decisions
- **Source:** `dashboard/reader/state_schema.py` `_finalize_value` ("flow collection rejected") and `_MAX_LEVEL`; the same rules in the Node twin `dashboard/server/reader.mjs` `parseStateDocument`
- **Description:** Both dashboard readers accept only block-style YAML up to three levels deep: a flow list or mapping (`[a, b]`, `{k: v}`) other than the literal `[]` / `{}` is rejected, and a key nested deeper than three levels is skipped, each with only a parse warning. Three live shapes fall outside that: this work's own `STATE.yml` writes `features[].sections` entries as flow mappings (all six of Feature 001's section rows read back as an empty list); Feature 001's approved `intent.phases` sample is a flow list; and Feature 001's `sources[].written_back[]` entries put `part` and `files` at a fourth level, so a reader keeps only `at`. Nothing tells the writer the shape is wrong, so the dashboard shows less than the file holds. Feature 002 settles the single `STATE.yml` layout and owns the dashboard reading it (AC-41), so the layout it defines has to fit the readers' subset, and the keys Feature 001 introduced have to be reshaped to fit it.
- **See also:** --

## KI-003: Questions are recorded in three different places, one of which no longer exists

- **Type:** Bug
- **Severity:** Medium
- **Affects:** Feature 002 — Clear, Step-by-Step Decisions
- **Source:** `canonical/skills/aid-ask/SKILL.md` § Target-file resolution and `canonical/skills/aid-execute/references/state-delivery-gate.md` § Non-CODE issues (both write the delivery-level `qa` of `deliveries/delivery-NNN/STATE.yml` on a full work); `canonical/skills/aid-detail/references/task-decomposition.md` § Feedback Loops and `canonical/skills/aid-describe/references/state-q-and-a.md` (write to `## Cross-phase Q&A` in a work `STATE.md` that no longer exists)
- **Description:** The question protocol requires every question and answer to be recorded so a skipped question can be resumed later by any user. Today a work's questions are split between the work `STATE.yml` `qa`, each delivery's own `qa`, and a markdown section of a retired file, depending on which skill asked. A resuming session that reads only the work `qa` misses the rest, and the entries sent to the retired file are lost. The delivery-level split existed to keep two delivery branches from colliding on one file; with one branch per work that reason is gone.
- **See also:** tech-debt.md #SY-6 (covers the retired `## Cross-phase Q&A` heading sites, not the delivery-level split)
