# Document Skill Family (G8)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.1 (G8), §5.3 | /aid-define |
| 2026-07-08 | STRUCTURE/NAMING amendment sweep: task-def path `tasks/task-NNN/SPEC.md` → `tasks/task-NNN/DETAIL.md` (FR-15) | /aid-specify (user amendment) |

## Source

- REQUIREMENTS.md §5.1 (G8 — Document)
- REQUIREMENTS.md §5.3 (Artifact-type dimension — ownership boundary)

## Description

The G8 shortcut skills for producing human-facing explanatory, reference, and communication
artifacts — eight archetypes, each with a materially different document shape: `aid-document`
(bare default — a general Diataxis how-to/reference/explanation or a status/progress report),
`aid-document-decision` (ADR: context, decision, alternatives, consequences),
`aid-document-architecture` (components, boundaries, interactions, diagrams — C4/arc42),
`aid-document-guideline` (advisory recommended practice), `aid-document-standard` (mandatory
standard with compliance/enforcement/exceptions), `aid-document-runbook` (operational
trigger/diagnostic/remediation/escalation), `aid-document-tutorial` (learning-oriented worked
example), and `aid-document-changelog` (changelog/release notes). The doc/content domain belongs
wholly to `aid-document` (ownership boundary).

## User Stories

- As an AID adopter who needs to write a specific kind of document, I want the matching
  `aid-document-*` archetype so the Lite work is shaped to that document's structure.

## Priority

Should

## Acceptance Criteria

- [ ] Given the G8 skills, when the catalog is checked, then all eight document archetypes exist
  in `canonical/skills/` with valid `SKILL.md` state machines and the `aid-` prefix. (AC-1 — G8
  subset)
- [ ] Given each G8 skill, when `aid-reviewer` reviews it, then it scores >= the resolved `minimum_grade` (A+) before
  shipping. (AC-7 — G8 subset)

---

## Technical Specification

> Family-specific content on top of the settled shortcut engine (feature-003). Every G8 skill is a
> thin doorway binding `{verb=document, artifact}` and delegating to
> `canonical/aid/templates/shortcut-engine.md` (writes feature-001's flattened work, runs
> feature-004's gates). This feature contributes catalog rows + the document scaffolding reference.

### Catalog rows owned (AC-1 — G8 subset)

**8 canonical archetypes, no aliases ⇒ 8 `canonical/skills/aid-*/SKILL.md` directories.** No alias
family — each archetype has a materially different document shape (§5.1), so the artifact suffix
selects the *structure*, not a synonym:

| `name` | verb | artifact | alias_of | group |
|---|---|---|---|---|
| `aid-document` | document | `""` (bare: Diátaxis how-to/reference/explanation **or** status/progress report) | null | G8 |
| `aid-document-decision` | document | `decision` (ADR) | null | G8 |
| `aid-document-architecture` | document | `architecture` | null | G8 |
| `aid-document-guideline` | document | `guideline` | null | G8 |
| `aid-document-standard` | document | `standard` | null | G8 |
| `aid-document-runbook` | document | `runbook` | null | G8 |
| `aid-document-tutorial` | document | `tutorial` | null | G8 |
| `aid-document-changelog` | document | `changelog` | null | G8 |

### Per-skill binding & default-type (feature-003 A-6 mapping)

**All 8 → `DOCUMENT`** (`task-type-rules.md ## DOCUMENT` "Write documentation … verify accuracy
against current codebase and KB … ADRs follow Context → Decision → Consequences … Diagrams use
Mermaid"):

| Skills | `default_type` | Task set |
|---|---|---|
| all 8 archetypes | `DOCUMENT` | single `DOCUMENT` task (grounded in the `add-docs` recipe, task=1) |

> **`add-report` territory:** only the **status/progress-report** half of the old
> `add-report`/`change-report` recipes lands here (as bare `aid-document` — narration of known
> state). Their **analytical** half is authoritatively reclassified to G11 `aid-report` as
> `RESEARCH` (feature-011), matching this family's ownership boundary below.

### Scaffolding knowledge (`canonical/aid/templates/shortcut-scaffolding/document.md`)

The substantive per-archetype axis is the **document shape** the DOCUMENT task must emit (the
capture slots are thin — subject + audience + the archetype-specific fields). For DOCUMENT work the
single `SPEC.md`'s `## Technical Specification` is light (Data Model "no schema changes"; the
document's structure lives in the task Scope, not a conditional SPEC section). Grounded in Diátaxis
and `digital-project-activities.md § 5` (Diátaxis 4 types; runbook; changelog; ADR) and `§ 8`
(SRE runbook/postmortem):

| Archetype | Document shape emitted by the DOCUMENT task | CAPTURE slots (beyond subject/audience) |
|---|---|---|
| `aid-document` (general) | Diátaxis how-to / reference / explanation **or** status/progress report | which Diátaxis type (or report); scope |
| `aid-document-decision` | ADR: **Context → Decision → Alternatives → Consequences** | the decision; alternatives considered; consequences |
| `aid-document-architecture` | components, boundaries, interactions, **C4/arc42 diagrams (Mermaid)** | system scope; the views to draw |
| `aid-document-guideline` | advisory: **principle → rationale → do/don't examples** | the recommended practice; examples |
| `aid-document-standard` | mandatory: **rule → scope → compliance/enforcement → exceptions** | the rule; enforcement mechanism; exceptions |
| `aid-document-runbook` | operational: **trigger → diagnostic → remediation → escalation** | the trigger/alert; diagnostic + remediation steps; escalation path |
| `aid-document-tutorial` | learning: **prerequisites → worked steps → outcome** | the learning goal; the worked example |
| `aid-document-changelog` | **[Added]/[Changed]/[Fixed]/[Removed]/[Security]** release notes | version; headline changes; breaking changes |

### Ownership boundary

**Doc/content belongs wholly to `aid-document`** (§5.3). A document that describes something not yet
built routes the build to `aid-create[-artifact]` first (the doc then describes reality —
`task-type-rules.md ## DOCUMENT` "verify accuracy against current codebase"). An ADR that mandates a
refactor: the ADR is `aid-document-decision`, the refactor is `aid-refactor`. A runbook needing new
observability wiring: the wiring is `aid-change-infra`/`aid-monitor`, the runbook is
`aid-document-runbook`. An **analytical** report (insight from data) is `aid-report` (G11), not
`aid-document` — `aid-document` communicates already-known information; a **status/progress** report
(narration of known state) stays here.

### Layers & Components (canonical files)

| File | Change |
|---|---|
| `canonical/aid/templates/shortcut-catalog.yml` | **add 8 rows** |
| `canonical/aid/templates/shortcut-scaffolding/document.md` | **new** — the 8 archetype document shapes (table above) |
| `canonical/skills/aid-document*/SKILL.md` × 8 | **generated** by feature-003's `build-shortcut-skills.py` — not hand-written |

No family-specific engine branch — the artifact suffix selects the archetype's document shape from
the reference. Renders via the full `run_generator.py` to all five profiles (NFR-1, AC-6).

### Testing strategy

- **Family scaffold proof** (canonical fixture): `aid-document-decision` produces a flattened work
  whose `tasks/task-001/DETAIL.md` is `DOCUMENT`-typed with a Scope requiring the **Context → Decision
  → Alternatives → Consequences** ADR structure; halts pre-Execute (FR-10). A second fixture
  (`aid-document-runbook`) asserts the trigger→diagnostic→remediation→escalation shape — proving the
  suffix selects the correct archetype (AC-1/AC-4).
- **Catalog↔dirs parity** + `render-drift` cover the 8 rows/dirs (feature-003's tests; AC-1/AC-6).
