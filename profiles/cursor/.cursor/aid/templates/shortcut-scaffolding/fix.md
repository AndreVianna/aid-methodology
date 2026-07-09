# Shortcut Scaffolding: fix

Per-family scaffolding reference for the **`fix`** verb (bare -- `aid-fix`, no
artifact suffix; feature-008, work-001-lite-aid-skills). Consulted by the
shared engine (`.cursor/aid/templates/shortcut-engine.md § Family
Scaffolding Consult`) at CAPTURE, SPEC, and DETAIL for every `{verb, artifact}`
whose `verb` field resolves to `fix`. Free-form prose, like any other
`state-*.md` reference doc -- the dispatched `aid-architect` reads this for
judgment; it is not machine-parsed.

Grounded in the `fix-*` recipes this family generalizes (`fix-application`,
`fix-security`, ...) -- the G6 "Fix & Remediate" activity group: corrective
maintenance; incident response; respond-to-vulnerability (RV).

`aid-fix` stays **bare** (`artifact: ""`) -- the fix-kind below is a captured
slot, not a separate skill or artifact suffix (feature-008 SPEC AC-4
`fix-bare`).

## CAPTURE -- minimal slot list

Beyond the engine's generic slot inventory
(`shortcut-engine.md § Capture-Minimization Rules`), a fix additionally needs:

| Slot | Maps to | Notes |
|---|---|---|
| Symptom / bug title | `REQUIREMENTS.md` Identity block `**Name:**` + §2 Problem Statement | one concise sentence; what is observably wrong |
| Reproduction steps | §5 Functional Requirements / §9 Acceptance Criteria | concrete, ordered steps; the `task-002` regression test is built directly from these |
| Expected vs. actual behavior | §2 Problem Statement | the delta reproduction proves |
| `fix-kind` | §4 Scope (states which kind) | closed enum: `defect` \| `regression` \| `incident` \| `vulnerability`; default `defect` when the description does not name one |
| Affected area | §4 Scope | inferred from the reproduction steps where possible (file/module/endpoint named or clearly implied); escalate only if genuinely unidentifiable from the description and KB |

**Escalation.** The generic engine rule already covers this: escalate to the
one combined CAPTURE question only when §5/§9 cannot be made concrete and
testable -- for a fix this most often means the reproduction steps or the
expected-vs-actual delta are missing entirely, not merely terse. `fix-kind`
itself never blocks CAPTURE -- default to `defect` and let the description's
own wording (e.g. "since the last release", "in production", "exploit",
"CVE") drive the classification the same way the engine infers any other
slot from `{description}` + KB context before asking.

## SPEC -- conditional section activation

The mandatory three sections (`### Data Model`, `### Feature Flow`,
`### Layers & Components`) always apply -- root-causing and patching a
defect touches at least one of them. On top of those, `fix-kind` gates one
conditional section:

| `fix-kind` | Conditional `## Technical Specification` section | Activated because |
|---|---|---|
| `defect` (default) | none | the base three sections are sufficient for an ordinary correction |
| `regression` | none | same as `defect`; the distinguishing fact (the regressing change) is narrative, not a new section |
| `incident` | none | the mitigation is ordinary code/config; a postmortem is a **separate** document routed elsewhere (Ownership boundary below), not a SPEC section here |
| `vulnerability` | `### Security Specs` | the exploit path and the closure mechanism are security-specific content the base three sections do not carry |

## DETAIL -- default task breakdown

A richer, correctly-typed split of the legacy single-task `fix-*` recipe
(which folded the regression test into the `IMPLEMENT` task) -- the
regression test is now its own `TEST` task, per feature-008 SPEC:

| Task | Type | Title (representative) | Depends on |
|---|---|---|---|
| `task-001` | `IMPLEMENT` | "Reproduce, root-cause, and patch {bug}" | -- (none) |
| `task-002` | `TEST` | "Regression test that fails on pre-fix code and passes on post-fix code" | `task-001` |

`task-002`'s Acceptance Criteria MUST state both halves of the
fail-then-pass contract explicitly (this is the `fix-application` AC this
family generalizes): the test **fails against the pre-fix code** (proving it
actually exercises the reported symptom) and **passes against the post-fix
code** (proving the patch closes it). This is the default two-task shape for
every `fix-kind` except where the adaptations below add or redirect work; no
`fix-kind` ever removes `task-002` or folds it back into `task-001` -- one
type per task always holds (`artifact-schemas.md § Task DETAIL.md`).

## `fix-kind` adaptations

| `fix-kind` | SPEC | `task-001` (IMPLEMENT) | `task-002` (TEST) |
|---|---|---|---|
| `defect` (default) | base `Feature Flow` | reproduce -> root-cause -> patch, as above | fails pre-fix / passes post-fix, as above |
| `regression` | base + a note identifying the regressing change | reproduction is **pinned to the regressing commit/change** (name it in Scope) so the root-cause search starts from the actual delta, not from scratch | same fail/pass contract, additionally anchored to "did not fail before {regressing change}" |
| `vulnerability` | `### Security Specs` activated | patches the vulnerability (the `fix-security` shape) | proves the **exploit path is closed**, not just that the symptom disappeared; a deep SAST/DAST scan or dependency audit is **out of this task's scope** -- route that to `aid-test-security` (Ownership boundary below), do not fold it into `task-002` |
| `incident` | base `Feature Flow` (no new section) | the mitigation code/config stays in `aid-fix`'s own `task-001` | same fail/pass contract for the mitigation; the **postmortem / runbook document is a separate deliverable** -- route it to `aid-document-runbook` (Ownership boundary below), never authored as a task here |

## Ownership boundary

`aid-fix` owns **corrective** work only -- closing a defect, regression,
incident, or vulnerability already observed. Related but distinct requests
route elsewhere; do not fold them into this shortcut's task set:

| Request | Route to | Why not `aid-fix` |
|---|---|---|
| Broad test-authoring not scoped to *this* defect | `aid-test` | `aid-fix`'s own `task-002` is coverage scoped narrowly to proving this one defect closed, not general test authoring |
| New behavior / intent (not a defect) | `aid-change` | not corrective -- a defect is "the code violates its own spec/intent"; new intent is a change |
| Behavior-preserving cleanup | `aid-refactor` | no observable defect being corrected |
| Security **verification** (SAST/DAST/fuzz/dependency audit) beyond the one exploit path `task-002` closes | `aid-test-security` | deep security verification is its own specialized activity, not a regression test |
| Incident **postmortem / runbook** | `aid-document-runbook` | documentation-of-the-incident is a DOCUMENT-typed deliverable, distinct from the IMPLEMENT mitigation |
| Infra provisioning to close an incident | `aid-change-infra` | infrastructure change, not application-level correction |

`aid-fix` itself performs the security **remediation** (the vulnerability
patch) and the incident **mitigation** (the code/config fix) -- only the
deeper verification and the narrative documentation route away.

## See also

- `.cursor/aid/templates/shortcut-engine.md § Family Scaffolding Consult` --
  how this file is looked up and what happens when it is absent
- `features/feature-008-fix-family/SPEC.md` (work-001-lite-aid-skills) --
  the settled design this reference implements
- `.aid/knowledge/artifact-schemas.md § Task DETAIL.md` -- the one-type-per-task
  contract
