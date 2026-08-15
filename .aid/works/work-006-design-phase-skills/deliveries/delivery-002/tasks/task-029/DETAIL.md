# task-029: Five `design` grid doorways and rows -- api, ui, theme, cli, data-model

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-029/STATE.md.
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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-028

**Scope:**
- Source spec: `features/feature-005-design-grid-and-brainstorm/SPEC.md` §2 (the positive
  selection -- these five are members of it), §3a (row shape), §3b (placement), §6a and §6b
  (the body, and the four things that vary), §7b (the neighbour assignments). It binds
  feature-002 §3g's **Class 2** column: §2d, §3a's two `design` rows, §3e, §3f, and §4's seed
  shape, `## Destination` and `<token>` rules.
- Author five hand-authored bodies -- `canonical/skills/aid-design-{api,ui,theme,cli,data-model}/SKILL.md`
  -- on feature-002 §3e's shape, modelled on `canonical/skills/aid-design/SKILL.md` as
  task-028 left it: frontmatter (`name` == directory name, `description`, `allowed-tools`,
  `argument-hint`); states `INTAKE -> DESIGN -> VERIFY -> PRESENT -> DONE`; allocation through
  the Work Initiation Gate (`canonical/aid/templates/work-initiation-gate.md` --
  `enumerate-works.sh`, then `worktree-lifecycle.sh create` on new work, stopping on a non-zero
  exit or an empty path) with `pipeline.path: lite`, `initiator: aid-design-<artifact>`,
  `lifecycle: Running`, and **`phase` not driven**; `aid-architect` dispatch tiered by
  complexity with verifier tier >= producer tier; **full verify** as `design-lifecycle.md`
  defines it; PRESENT is a hard stop and the user iterates by re-invoking; DONE sets
  `lifecycle: Completed` and the seed **persists** (feature-002 §2c Entry C).
- **Each body binds the contract and restates none of it** (feature-005 §6a). It carries the
  binding line in the shape the generated doorways use for the engine
  (`canonical/skills/aid-create-api/SKILL.md:18` is that shape) but pointing at the contract:
  *"Bind **VERB=`design`**, **ARTIFACT=`<artifact>`** ... then follow the shared contract at
  `canonical/aid/templates/design-lifecycle.md`."* `VERB`/`ARTIFACT` rather than `STAGE`,
  because those are the catalog's own field names and the tokens
  `tests/canonical/test-catalog-dirs-parity.sh` looks for in a body (`:151-167`) -- that suite
  exempts `repurpose: true` rows from the body assertion (`:143-145`), so using them costs
  nothing and keeps one vocabulary.
- **Only four things vary per body** (§6b): the bound `{stage, artifact}` pair with its seed
  path `.aid/design/<artifact>.md`; the `description`'s negative route; the `argument-hint`,
  which names a **subject**, never a question; and one to three lines of artifact-specific slot
  hints in the DESIGN state -- for `api` the resource shape, the contract and the error model;
  for `data-model` entities, relationships and migration impact; and the equivalent for `ui`,
  `theme` and `cli`. The seed's six headings supply the *structure*, so these are content
  guidance and never a second shape.
- Append five rows to `canonical/aid/templates/shortcut-catalog.yml` -- the canonical source; a
  row added under a profile copy is discarded by the next render -- immediately after the
  existing `aid-design` row (`:441-448`), each carrying all eight fields of §3a's shape:
  `name` == directory, `verb: design`, `artifact: api|ui|theme|cli|data-model`,
  `alias_of: null`, `default_type: DESIGN` (inside the closed 8-enum enforced at
  `.claude/skills/generate-profile/scripts/build-shortcut-skills.py:219-224`), `group: G3` --
  the group `aid-design` and `aid-prototype` already occupy -- the `intent` string, and
  `repurpose: true`.
- **The `intent` strings are derived from the one form the spec fixes, not invented.**
  feature-005 §3a supplies `aid-design-api`'s verbatim: *"Develop an API design in .aid/design/
  before building it; writes a seed, builds nothing."* The remaining four take that same form
  with the artifact's own noun substituted. This is the one form the spec gives and no row
  departs from it; nothing in this delivery asserts anything else about `intent` text.
- **Row order is presentational and no oracle asserts it.** These five are written in the order
  feature-005 §2's result block prints them; V2's oracle is a `comm -3` over **sorted** artifact
  values, so it is order-insensitive by construction. The order matters only in that the
  fourteen stay together ahead of task-033's four foundation `design` rows (feature-004 §1b).
- Out of scope: the three stale count comments inside `shortcut-catalog.yml` (the G4 and G5
  family headers and the `repurpose` schema note) -- handed to delivery-003 so that features
  003, 004 and 005 do not collide on one file; the full `run_generator.py` render, which is
  delivery-003's single run (C-5); any change to `canonical/skills/aid-create-{api,ui,theme,cli,data-model}/`
  or their `update` counterparts (feature-005 §1 excludes all 28 paired doorways beyond the two
  `document` files); and every count-bearing assertion, which is an aggregate over the finished
  thirty-six.

**Acceptance Criteria:**
- [ ] feature-005 V1, this task's share:
      `ls -d canonical/skills/aid-design-{api,ui,theme,cli,data-model}` returns 5 lines, exit 0,
      and each holds a `SKILL.md`
- [ ] feature-005 V1/AC-1, per row:
      `grep -cE '^  - name: aid-design-(api|ui|theme|cli|data-model)$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `5`, and for each of the five, frontmatter `name:` == directory
      name == row `name`
- [ ] Each of the five rows carries all eight fields, with `default_type: DESIGN` from the
      closed 8-enum and `group: G3` -- not `G8`, whose own catalog header forbids writing
      `.aid/knowledge/`
- [ ] `repurpose: true` is present on all five rows. It is the one field
      `build-shortcut-skills.py` does **not** enforce -- `:354` reads it with
      `r.get("repurpose", False)` -- so a row that loses it parses cleanly and is silently
      regenerated. The byte-identity oracle for that is task-039's, at the point the render
      actually consumes the catalog
- [ ] Placement: the five rows sit **after** the existing `aid-design` row and **before** the
      G8 `Document family` comment block. Capture
      `A = grep -n '^  - name: aid-design$'` and
      `G = grep -n '^  # --- G8: Document family'`; every new row's line number lies strictly
      between them
- [ ] feature-005 V15, this task's share:
      `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-design-{api,ui,theme,cli,data-model}/SKILL.md`
      produces **empty** output -- every body binds the contract by path
- [ ] feature-005 V16, this task's share: no body restates the `design` invariant, the
      allocation steps, the seed headings or the verify depth. Prose conformance has no script,
      so this is a reviewer reading against `canonical/aid/templates/design-lifecycle.md`
- [ ] feature-005 V10, this task's share: each `description` contains the literal name of every
      neighbour §7b assigns it -- all five name `/aid-create-<artifact>`, and `aid-design-ui`
      **additionally** names `/aid-prototype-ui` -- and **no** description names a neighbour §7b
      does not assign it
- [ ] feature-005 V8, this task's half: `canonical/skills/aid-design-ui/SKILL.md` names
      `/aid-prototype-ui` inside its `description:` block **and** states the
      kept-versus-throwaway distinction, which the name grep does not establish; task-028 wrote
      the other side
- [ ] Each `argument-hint` names a **subject**, not a question, and each body's INTAKE requires
      a subject
- [ ] No `intent` value contains a backtick or any other markdown, and its em-dashes are ASCII
      `--`, matching how all 58 live rows write theirs
- [ ] Each body drives no `phase:` value and states that `design` never writes
      `.aid/knowledge/` and never writes production code
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean; no count comment inside
      `shortcut-catalog.yml` is edited; and `git diff --exit-code -- tests/ site/scripts/__tests__/`
      is clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
