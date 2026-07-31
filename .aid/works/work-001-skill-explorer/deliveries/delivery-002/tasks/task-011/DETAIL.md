# task-011: Curated taxonomy, group assignment and its four guards

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-011. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-011/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-002 (feature-002-grouped-skill-index)

**Depends on:** task-008

**Scope:**
- Create `site/scripts/skills/groups.mjs`: the `CURATED_GROUPS` table implementing REQUIREMENTS FR-5's owner-corrected Placement rules, and `assignGroups(records, catalog) -> GroupSection[]` carrying the four assignment guards. Deliberately **not** named `SKILL_GROUPS` -- the identically-named constant at `gen-reference.mjs`:150-199 holds the stale taxonomy FR-5 overrides, and a distinct name stops a future reader assuming the two tables agree.
- Group order is fixed: `Support` -> `Knowledge Base Maintenance` -> `Definition` -> `Execution`. `aid-triage` sits first in `Support`; `Definition` opens with the five full-path skills (`aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`) un-subdivided in pipeline order, then verb families; `aid-deploy` and `aid-monitor` leave the curated table entirely and land under their own `deploy` and `monitor` families by the ordinary rule, with no special case in code.
- Family derivation: `familyOf(record) = catalog.byName.get(record.dirName).verb` for every non-curated skill. The family list is built by walking `catalog.rows` in **file order**, skipping curated names, appending each newly-seen verb to an **ordered array** -- never an object keyed by verb, which feature-001's AC-6 rule 5 forbids. A verb whose every member is curated produces **no empty section**.
- Card order within a family is catalog row order, which puts canonical forms before their aliases.
- Member lists stay explicit and hand-maintained: which skills are curated is a curatorial choice, not a filesystem fact, and deriving it would make the assignment tautological with itself. The clamp is what makes the table self-policing rather than trusted.
- Same conventions as the rest of the cluster: ESM `.mjs`, `node:` builtins only, 2-space indentation, pure exported functions with no import-time side effect, no new dependency. Nothing is read from `gen-reference.mjs`.

**Acceptance Criteria:**
- [ ] `aid-triage` resolves to `Support` and is first in that group.
- [ ] The five full-path skills open `Definition` in pipeline order, un-subdivided and carrying no verb family.
- [ ] `aid-deploy` resolves to family `deploy` and `aid-monitor` to family `monitor`, each by the ordinary catalog rule with **no special case in the code**, verified by grep for those two names in the module.
- [ ] Family order is derived by walking `catalog.rows` in file order; **no hard-coded family list exists** anywhere in the module -- the construct that rotted in `gen-reference.mjs`'s `SHORTCUT_FAMILIES` (KI-009).
- [ ] A verb whose every member is curated produces no section at all.
- [ ] All four guards throw with their stable names and an actionable detail: `unassignable skill` (the clamp -- a directory that is neither curated nor catalog-backed), `curated skill missing`, `duplicate assignment`, `full-path catalog row`.
- [ ] `assignGroups()` returns only after all four guards pass, so no downstream renderer needs a defensive branch.
- [ ] No `Object.keys` or equivalent object-key iteration is applied to parsed data anywhere in the module.
- [ ] No numeric count literal appears in the module.
- [ ] Unit tests exist for each guard, for family first-appearance ordering, and for the three Placement-rule placements; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
