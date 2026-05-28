---
kb-category: primary
source: hand-authored
intent: |
  Canonical feature list with status (Shipped / Partial / Deferred), source, and traceability to work items. Read this to understand WHAT the project does at a feature level.
contracts: []
changelog:
  - 2026-05-26: KB Authoring v2 template seed
  - 2026-05-27: Populated with 10 user-facing skills + 1 maintainer-only skill
---

# Feature Inventory

> The user-facing features of the AID methodology repository — i.e., the slash
> commands an adopter can invoke once they have AID installed in their project.

**Status legend:** ✓ Shipped · ⚠️ Partial · ❌ Pending · 🚧 In Progress

## User-facing skills (10)

| # | Skill | Status | Description | Source |
|---|-------|--------|-------------|--------|
| 1 | `/aid-config` | ✓ Shipped | View or update AID pipeline settings. Bare invocation shows all values in a table; first run auto-creates `.aid/settings.yml` from the template. Pass a dotted key to view and update one setting interactively. | `canonical/skills/aid-config/SKILL.md` |
| 2 | `/aid-discover` | ✓ Shipped | Brownfield project discovery with built-in quality gate. Analyzes all repository content (code, configuration, and documentation) to populate KB documents, then reviews, collects user input, fixes issues, and gets user approval — one step per run. | `canonical/skills/aid-discover/SKILL.md` |
| 3 | `/aid-interview` | ✓ Shipped | Adaptive requirements gathering through conversational interview. Builds REQUIREMENTS.md incrementally, then cross-references against the KB and decomposes functional requirements into discrete feature files; supports a lite path for small work. | `canonical/skills/aid-interview/SKILL.md` |
| 4 | `/aid-specify` | ✓ Shipped | Technical specification through conversational refinement, one feature at a time. Acts as a tech lead — reads KB, Requirements, and codebase, proposes technical solutions, and builds the spec collaboratively with the developer. | `canonical/skills/aid-specify/SKILL.md` |
| 5 | `/aid-plan` | ✓ Shipped | Sequences feature SPECs into deliverables, each one a functional MVP that builds on the previous. Answers one question: in what order do we deliver, and does each delivery stand on its own? | `canonical/skills/aid-plan/SKILL.md` |
| 6 | `/aid-detail` | ✓ Shipped | Breaks deliverables into small, dependency-driven, typed tasks — each one a reviewable unit. Detects task types from SPEC signals and builds an execution graph per delivery with explicit dependencies and parallelism. | `canonical/skills/aid-detail/SKILL.md` |
| 7 | `/aid-execute` | ✓ Shipped | Executes a task based on its type (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE) with a built-in review-fix loop per type. Runs until the grade meets the configured minimum. | `canonical/skills/aid-execute/SKILL.md` |
| 8 | `/aid-deploy` | ✓ Shipped | Packages completed deliveries into a release. Selects eligible deliveries, verifies the combined build, packages according to project infrastructure, generates release notes, and updates artifact statuses. | `canonical/skills/aid-deploy/SKILL.md` |
| 9 | `/aid-monitor` | ✓ Shipped | Observes production, classifies findings, and routes actions. Combines telemetry interpretation with triage — detects anomalies, performs root cause analysis, and routes bugs to `aid-execute` or change requests to `aid-discover`. | `canonical/skills/aid-monitor/SKILL.md` |
| 10 | `/aid-summarize` | ✓ Shipped | Generates a single self-contained `knowledge-summary.html` from `.aid/knowledge/`. Inlines Mermaid diagrams for offline use, supports light/dark themes, and enforces a two-grade quality gate (Machine + Human) before writing the final output. | `canonical/skills/aid-summarize/SKILL.md` |

## Maintainer-only skills (1)

| # | Skill | Status | Description | Source |
|---|-------|--------|-------------|--------|
| - | `/aid-generate` | ✓ Shipped | Regenerates the three install trees (claude-code, codex, cursor) from `canonical/` and `profiles/`. Not shipped to end users via `setup.sh`; lives only at `.claude/skills/aid-generate/` to avoid a chicken-and-egg deployment problem. | `.claude/skills/aid-generate/SKILL.md` |

## Engineering features (referenced for historical context)

The 10 user-facing skills above are the result of the following engineering work items:

- **Thin-Router Skills** (work-001 feature-002) — every `aid-*` SKILL.md is a state router (≤~360 lines) that delegates per-state logic to `references/state-*.md` files.
- **Two-tier review** (work-001 feature-004) — per-task quick-check (Small-tier reviewer, no grade loop) + per-delivery quality gate (full review/fix/review loop with `grade.sh` determinism).
- **Lite path with type-aware sub-paths** (work-001 feature-005) — `aid-interview` TRIAGE state routes small work to LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR / LITE-FEATURE sub-paths.
- **Pool dispatch** (work-001 feature-009) — `aid-execute` runs a PD-0..PD-6 pool model with `MaxConcurrent` capacity, wait-for-any-completion, failure-block-radius, and graceful degradation.
- **Recipes catalog** (work-001 feature-011) — `canonical/recipes/` ships 5 pre-filled lite-path templates with YAML front-matter and `{{slot}}` placeholders.
- **Always-on traceability** (work-003) — every long-running subagent dispatch surfaces L1 state markers, L2 ETA bracket pairs, and L3 heartbeat files.
