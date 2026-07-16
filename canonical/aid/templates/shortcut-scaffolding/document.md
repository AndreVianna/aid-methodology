# Shortcut Scaffolding: document

**Genre-structures reference for the document family (work-005 reframe of feature-010).**
`document` is now a create/change **artifact**, not an engine verb: it is served by the
hand-authored collapse skills `aid-create-document` / `aid-change-document` (+ the `-add`/
`-update` aliases, the genre kind-siblings `aid-document-decision`/`-architecture`/
`-guideline`/`-standard`/`-runbook`/`-tutorial`/`-changelog`, and the `aid-create-diagram`
format sibling). This file is **no longer consulted by the shared engine** -- instead the
hand-authored `aid-create-document`/`aid-change-document` bodies read it for the per-genre
document **structure** (ADR, C4/arc42, runbook, tutorial, changelog, Diataxis, ...) they
produce. Free-form prose, like any other `state-*.md` reference doc -- read for judgment,
not machine-parsed. (The CAPTURE/SPEC/DETAIL sections below are retained as that structural
guidance; the collapse bodies own the actual state machine, so read the shapes here, not the
engine flow.)

Grounded in the eight archetypes' materially different document shapes -- general
explanatory writing, an ADR, an architecture write-up, a guideline, a mandatory
standard, an operational runbook, a tutorial, and a changelog -- and
`task-type-rules.md ## DOCUMENT` ("Write documentation ... verify accuracy against
current codebase and KB ... ADRs follow: Context -> Decision -> Consequences format
... Diagrams use Mermaid").

## CAPTURE -- thin, per archetype

Every archetype first captures the two generic slots **subject** (what the document
is about) and **audience** (who reads it), then the archetype-specific fields below.
The hand-authored collapse body infers the project's documentation style/location from
the KB, so those are never capture slots.

| Archetype | CAPTURE slots beyond subject/audience |
|---|---|
| `aid-document` (general) | which shape applies -- a Diataxis how-to / reference / explanation, **or** a status/progress report; scope |
| `aid-document-decision` | the decision; alternatives considered; consequences |
| `aid-document-architecture` | system scope; the views to draw |
| `aid-document-guideline` | the recommended practice; examples (do/don't) |
| `aid-document-standard` | the rule; enforcement mechanism; exceptions |
| `aid-document-runbook` | the trigger/alert; diagnostic + remediation steps; escalation path |
| `aid-document-tutorial` | the learning goal; the worked example |
| `aid-document-changelog` | version; headline changes; breaking changes |

**Escalation.** Same minimal-escalation discipline the engine's Capture-Minimization
Rules define (the hand-authored collapse body applies it -- the engine no longer runs
this family): escalate to the one combined CAPTURE question only when the subject or the
archetype-specific fields above cannot be made concrete from `{description}` + KB context -- for `aid-document` this most often
means which shape (Diataxis type vs. status report) is genuinely ambiguous.

## Document structure -- the genre shape, not a SPEC.md

The hand-authored collapse body produces the document **directly** and emits no separate
`SPEC.md`. The document's own internal structure is the per-genre shape in the DETAIL table
below (Diataxis shape, ADR sections, C4/arc42 views, runbook steps, changelog headings,
etc.) -- there is no `## Technical Specification` to activate and no schema change. (Legacy
note: when this family was engine-driven, a generated `SPEC.md` carried the mandatory three
sections with `### Data Model` = "no schema changes"; the collapse drops that scaffolding.)

## Genre structure -- per archetype (what the collapse produces)

The collapse body produces the document in the archetype's structure below -- this table is
the substantive genre guidance this file exists to convey (`aid-create-document` reads it and
writes the document directly; the collapse emits no task or SPEC artifact):

| Archetype | Document shape the collapse produces |
|---|---|
| `aid-document` (general) | Diataxis how-to / reference / explanation **or** status/progress report, per the captured shape |
| `aid-document-decision` | ADR: **Context -> Decision -> Alternatives -> Consequences** |
| `aid-document-architecture` | components, boundaries, interactions, **C4/arc42 diagrams (Mermaid)** |
| `aid-document-guideline` | advisory: **principle -> rationale -> do/don't examples** |
| `aid-document-standard` | mandatory: **rule -> scope -> compliance/enforcement -> exceptions** |
| `aid-document-runbook` | operational: **trigger -> diagnostic -> remediation -> escalation** |
| `aid-document-tutorial` | learning: **prerequisites -> worked steps -> outcome** |
| `aid-document-changelog` | **[Added]/[Changed]/[Fixed]/[Removed]/[Security]** release notes |

`aid-document-decision`'s Context -> Decision -> Alternatives -> Consequences shape
extends `task-type-rules.md ## DOCUMENT`'s baseline Context -> Decision ->
Consequences ADR format with an explicit Alternatives step (feature-010 SPEC).

## Ownership boundary

**Doc/content belongs wholly to `aid-document`.** A document describing something
not yet built routes the build to `aid-create[-artifact]` first (the doc then
describes reality -- `task-type-rules.md ## DOCUMENT` "verify accuracy against
current codebase"). An ADR mandating a refactor: the ADR is `aid-document-decision`,
the refactor is `aid-refactor`. A runbook needing new observability wiring: the
wiring is `aid-change-infra`/`aid-monitor`, the runbook is `aid-document-runbook`.
**Analytical** reports (insight derived from data) cede to `aid-report` (G11) --
`aid-document` communicates already-known information; only the **status/progress**
half of the legacy `add-report`/`change-report` recipes (narration of known state)
stays here, as the bare `aid-document` shape.

## See also

- `canonical/skills/aid-create-document/SKILL.md` (+ `aid-change-document`) -- the
  hand-authored collapse bodies that read this file for per-genre document structure
  (work-005; `document` is no longer engine-consulted)
- `canonical/aid/templates/shortcut-scaffolding/analyze-report.md § Ownership
  boundary` -- where an analytical report routes instead
- `features/feature-010-document-family/SPEC.md` (work-001-lite-aid-skills) -- the
  settled design this reference implements
- `canonical/skills/aid-execute/references/task-type-rules.md ## DOCUMENT` -- the
  per-type execution rule this breakdown maps onto
- `.aid/knowledge/artifact-schemas.md § Task DETAIL.md` -- the one-type-per-task
  contract
