# Shortcut Scaffolding: document

Per-family scaffolding reference for the **`document`** verb (bare `aid-document`
plus the seven archetype-suffixed forms `-decision`, `-architecture`, `-guideline`,
`-standard`, `-runbook`, `-tutorial`, `-changelog`; feature-010,
work-001-lite-aid-skills). Consulted by the shared engine
(`canonical/aid/templates/shortcut-engine.md § Family Scaffolding Consult`) at
CAPTURE, SPEC, and DETAIL for every `{verb, artifact}` whose `verb` field resolves to
`document`. No `aid-document*` row carries an alias (feature-010 SPEC "Catalog rows
owned" -- 8 canonical, no aliases; the artifact suffix selects the document's
**structure**, not a synonym). Free-form prose, like any other `state-*.md` reference
doc -- the dispatched `aid-architect` reads this for judgment; it is not
machine-parsed.

Grounded in the eight archetypes' materially different document shapes -- general
explanatory writing, an ADR, an architecture write-up, a guideline, a mandatory
standard, an operational runbook, a tutorial, and a changelog -- and
`task-type-rules.md ## DOCUMENT` ("Write documentation ... verify accuracy against
current codebase and KB ... ADRs follow: Context -> Decision -> Consequences format
... Diagrams use Mermaid").

## CAPTURE -- thin, per archetype

Every archetype first captures the two generic slots **subject** (what the document
is about) and **audience** (who reads it), then the archetype-specific fields below.
The engine infers the project's documentation style/location from the KB, so those
are never capture slots.

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

**Escalation.** Same rule as the generic engine: escalate to the one combined CAPTURE
question only when the subject or the archetype-specific fields above cannot be made
concrete from `{description}` + KB context -- for `aid-document` this most often
means which shape (Diataxis type vs. status report) is genuinely ambiguous.

## SPEC -- always the mandatory three, no conditional section

The mandatory three sections (`### Data Model`, `### Feature Flow`,
`### Layers & Components`) always apply, per the engine's own contract -- every
generated `SPEC.md` carries them regardless of family. For every one of the 8
archetypes: `### Data Model` reads "no schema changes"; `### Feature Flow` and
`### Layers & Components` stay light (the document's own structure -- Diataxis shape,
ADR sections, C4/arc42 views, etc. -- lives in the task's Scope, not a conditional
SPEC section). No archetype activates a conditional `## Technical Specification`
section.

## DETAIL -- single DOCUMENT task, per archetype

Every archetype emits exactly one `task-001` DOCUMENT task (grounded in the legacy
`add-docs` recipe's task=1 shape); the archetype only changes the **Scope**'s
required document structure:

| Archetype | `task-001` Scope requires this document shape |
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

- `canonical/aid/templates/shortcut-engine.md § Family Scaffolding Consult` -- how
  this file is looked up and what happens when it is absent
- `canonical/aid/templates/shortcut-scaffolding/analyze-report.md § Ownership
  boundary` -- where an analytical report routes instead
- `features/feature-010-document-family/SPEC.md` (work-001-lite-aid-skills) -- the
  settled design this reference implements
- `canonical/skills/aid-execute/references/task-type-rules.md ## DOCUMENT` -- the
  per-type execution rule this breakdown maps onto
- `.aid/knowledge/artifact-schemas.md § Task SPEC.md` -- the one-type-per-task
  contract
