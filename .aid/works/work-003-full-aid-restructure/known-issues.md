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
