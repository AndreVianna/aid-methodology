# Analyze & Report Skill Family (G11)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.1 (G11), §5.3 | /aid-define |
| 2026-07-08 | STRUCTURE/NAMING amendment sweep: task-def path `tasks/task-NNN/SPEC.md` → `tasks/task-NNN/DETAIL.md` (FR-15) | /aid-specify (user amendment) |

## Source

- REQUIREMENTS.md §5.1 (G11 — Analyze / Show)
- REQUIREMENTS.md §5.3 (Artifact-type dimension — ownership boundary)

## Description

The G11 shortcut skills for extracting insight from data or usage and communicating it for
decisions: `aid-report` (bare — analyze data/usage and communicate insight: EDA, metrics, A/B
analysis) and `aid-show-dashboard` (build a durable dashboard or BI view: data source to
visualization to publish/refresh). The report and dashboard domain belongs wholly to these verbs
(ownership boundary).

## User Stories

- As an AID adopter who needs to analyze data and communicate a finding, I want `aid-report` so
  the analysis and insight get a scaffolded Lite work.
- As an AID adopter building a BI view, I want `aid-show-dashboard` so a durable dashboard gets
  its own Lite work.

## Priority

Should

## Acceptance Criteria

- [ ] Given the G11 skills, when the catalog is checked, then `aid-report` and
  `aid-show-dashboard` exist in `canonical/skills/` with valid `SKILL.md` state machines and the
  `aid-` prefix. (AC-1 — G11 subset)
- [ ] Given each G11 skill, when `aid-reviewer` reviews it, then it scores >= the resolved `minimum_grade` (A+) before
  shipping. (AC-7 — G11 subset)

---

## Technical Specification

> Family-specific content on top of the settled shortcut engine (feature-003). Both G11 skills are
> thin doorways binding `{verb, artifact}` and delegating to
> `canonical/aid/templates/shortcut-engine.md` (writes feature-001's flattened work, runs
> feature-004's gates). This feature contributes catalog rows + the analyze/report scaffolding
> reference.

### Catalog rows owned (AC-1 — G11 subset)

**2 canonical skills, no aliases ⇒ 2 `canonical/skills/aid-*/SKILL.md` directories:**

| `name` | verb | artifact | alias_of | group |
|---|---|---|---|---|
| `aid-report` | report | `""` (bare: EDA, metrics, A/B analysis) | null | G11 |
| `aid-show-dashboard` | show-dashboard | `""` (bare: durable dashboard / BI view) | null | G11 |

> Naming flag carried from §5.1: `aid-show-dashboard` overlaps AID's own "Dashboard" concept;
> retained per stakeholder preference — revisit if it causes confusion. The catalog `verb` for it is
> `show-dashboard` (the whole name is the verb; it takes no artifact suffix).

### Per-skill binding & default-type (feature-003 A-6 mapping)

**`report → RESEARCH`** (analysis producing a document) and **`show-dashboard → IMPLEMENT`** (a BI
view is code/config) — both per feature-003's settled table:

| Skill | `default_type` | Multi-type task set |
|---|---|---|
| `aid-report` | `RESEARCH` | `RESEARCH` (EDA/analysis + recommendation); optional `DOCUMENT` (write up the report) |
| `aid-show-dashboard` | `IMPLEMENT` | `IMPLEMENT` (build the view: source → viz → publish/refresh); optional `TEST` (validate data accuracy/refresh) |

> Grounded reclassification vs. the legacy recipes: `add-report`/`change-report` were `DOCUMENT`
> tasks living in G4/G5. Per the §5.3 ownership boundary + feature-003's mapping, **report/analysis
> moves to G11 as `RESEARCH`** (the insight is investigative — `task-type-rules.md ## RESEARCH`
> "compare ≥2 alternatives … end with a recommendation"), with the written artifact as an optional
> `DOCUMENT` follow-up.

### Scaffolding knowledge (`canonical/aid/templates/shortcut-scaffolding/analyze-report.md`)

Grounded in `digital-project-activities.md § 2` (EDA / CRISP-DM Data Understanding; build a
dashboard/BI view) and `§ 9` (product metrics + A/B analysis) and `§ 11` (Analyze & Report). The
engine infers the data-access/BI stack from the KB, so those are not capture slots.

| Skill | SPEC section(s) | CAPTURE slots (min) | Task-breakdown template |
|---|---|---|---|
| `aid-report` | (base) | the question/hypothesis; data source; metric(s); audience; the decision it informs | `001` RESEARCH — EDA + metrics + ≥2 interpretations + recommendation; opt `002` DOCUMENT — write up for the audience |
| `aid-show-dashboard` | `### Telemetry & Tracking` + `### UI Specs` | data source; metrics/dimensions; visualization type; refresh cadence; publish target | `001` IMPLEMENT — build source→viz→publish/refresh; opt `002` TEST — validate data accuracy + refresh |

### Ownership boundary

**Report/dashboard belong wholly to G11** (§5.3), distinguished from neighbors by intent:
`aid-report` = **derive insight** from data (RESEARCH); `aid-document` = **communicate already-known**
information (a status/progress report is G8, an analytical report is G11). Building the **data
pipeline** that feeds a report/dashboard is `aid-create-data-pipeline` (G4); adding **data-quality
checks** on the source is `aid-test-data-quality` (G7); a controlled **experiment/A-B test** (design
+ run) is `aid-experiment` (G7) — `aid-report` analyzes results, it does not design the trial.

### Layers & Components (canonical files)

| File | Change |
|---|---|
| `canonical/aid/templates/shortcut-catalog.yml` | **add 2 rows** (`aid-report`, `aid-show-dashboard`) |
| `canonical/aid/templates/shortcut-scaffolding/analyze-report.md` | **new** — the family scaffolding reference (table above) |
| `canonical/skills/aid-report/`, `aid-show-dashboard/SKILL.md` | **generated** by feature-003's `build-shortcut-skills.py` — not hand-written |

No family-specific engine branch — `aid-report`'s `RESEARCH` default and `aid-show-dashboard`'s
`IMPLEMENT` default come straight from their catalog rows, resolved by the generic engine. Renders
via the full `run_generator.py` to all five profiles (NFR-1, AC-6).

### Testing strategy

- **Family scaffold proof** (canonical fixture): `aid-report` produces a flattened work whose
  `tasks/task-001/DETAIL.md` is `RESEARCH`-typed (EDA + recommendation), halting pre-Execute (FR-10) —
  proving the non-code default-type mapping and the G4→G11 reclassification. An `aid-show-dashboard`
  fixture asserts an `IMPLEMENT`-typed `task-001` with `### Telemetry & Tracking` activated (AC-4).
- **Catalog↔dirs parity** + `render-drift` cover the 2 rows/dirs (feature-003's tests; AC-1/AC-6).
