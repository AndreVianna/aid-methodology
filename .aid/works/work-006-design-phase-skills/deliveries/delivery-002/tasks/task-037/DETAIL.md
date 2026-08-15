# task-037: `/aid-create-cicd` -- the C8 realizer that writes the stage, never the policy

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-037/STATE.md.
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

**Depends on:** task-036

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §6, §6b, §6c, §6e
  (creating a destination that is absent -- this is the second of the two skills that can), §7a,
  §7f (`cicd`, concern C8), §4 rows 1, 3 and 4 (the contested regions, from the C8 side), §3b
  (registration), §9, §10. It binds feature-002 §3g's **Class 1** column and REQUIREMENTS
  **CC-1**, **CC-2**, **CC-3**, **CC-6** by reference.
- **Its own task because it stands on the other side of three of task-036's collision rows.**
  Authoring the two together would put both sides of §4 rows 1 and 4 in one head, which is exactly
  how the non-owner rule gets softened into "mention it briefly". It follows task-036 so that the
  gate-policy owner is on disk when the stage-only rule is written against it -- and because both
  append to the one catalog file.
- Author `canonical/skills/aid-create-cicd/SKILL.md` on feature-002 §3e's shape
  (`INTAKE -> CREATE -> VERIFY -> PRESENT -> DONE`; Work Initiation Gate allocation with
  `pipeline.path: lite`, `initiator: aid-create-cicd`, **`phase` not driven**; `aid-architect`
  tiered, verifier tier >= producer tier; **full verify**), and append one row to
  `canonical/aid/templates/shortcut-catalog.yml` at the end of the G4 block: `verb: create`,
  `artifact: cicd`, `alias_of: null`, `default_type: DOCUMENT`, `group: G4`, §1a's `intent`
  verbatim, `repurpose: true`.
- **Owned region** (§7f): the project's C8 doc's pipeline sections --
  `## Deployment Pipeline` / `## CI/CD Pipeline` and `## Environments` -- plus whatever else the
  seed's `## Destination` names within that document. **Writes:** stages and their order; triggers;
  environments and promotion between them; the release flow; and **that** a stage runs a gate.
- **The three must-not-write boundaries, each the non-owner half of a §4 row.** It must **not**
  write which test suites run (C6, §4 row 1 -- `/aid-*-testing-strategy` owns the test-lane
  mapping); it must **not** write what blocks a merge, any threshold, or any waiver rule (the C6
  gate doc, §4 row 4 -- it names the stage, its order, its trigger and that it runs the gate, and
  **cites** the gate doc instead); and it must **not** write build-tool **versions** (C0, §4 row 3
  -- `/aid-*-stack` owns the build tool and its version, this skill owns the pipeline stage that
  invokes it, and neither restates the other's half).
- **Production config is opt-in per run, never default** (§7f): `design` never touches `.github/`
  or any workflow file; `create` writes the KB record by default and may additionally emit a
  workflow file **only** when the user asks for it in that run (FR-1's *"any other output the user
  wants"*). Its description routes a user who wants a provisioned resource to `/aid-create-infra`.
- **Creating an absent C8 document** (§6e): possible on a `methodology-tooling` project, where
  `infrastructure.md` is `conditional:the tooling ships/runs as a deployed artifact`
  (`canonical/aid/templates/kb-authoring/domain-doc-matrix.md:325`). In that case `create` creates
  the document, sets `source: forward-authored` and `sources: []`, and registers it in the same run
  per §3b -- one `.aid/settings.yml` `knowledge.doc_set` entry at presence `required` (**CC-1**)
  whose owner is the doc's **matrix** row slot (`aid-researcher-quality`,
  `domain-doc-matrix.md:144`, `:173`, `:203`, `:294`, `:325`), plus one `.aid/knowledge/README.md`
  Completeness row and its `**Doc-set:** N documents` line (`:21`) incremented. Both via the R13
  append-block idiom; `term_exclusions` untouched; **no hand edit outside the run** does any of it
  (CC-2). Writing `skill-self` for this document would silently remove its researcher discovery
  dispatches and contradict every shipped matrix row.
- **The CREATE state enumerates exactly three refusal conditions and no fourth** (§6c): seed
  absent; `## Open questions` non-empty by feature-002 §4's detection rule with no override;
  destination `source: generated`. A populated destination is the **normal** case; the exclusion
  list is `hand-authored`; `source: generated` is the third **mandated** condition.
- **The realization event and the repeat `create`** as §6c states them, with the routed remainder
  left for `/aid-update-cicd` to consume under CC-3. **Frontmatter invariants** (§7a) and **write
  discipline** (§4) exactly as task-035 and task-036 state them, bound rather than re-derived:
  created-here -> `forward-authored` + `sources: []`; already existed -> `source:` unchanged;
  `generated` -> refuse; `approved_at_commit:` never written or restamped; read whole, edit in
  place, everything outside the edited range byte-identical; a new `## ` section obliges its
  `## Contents` entry in the same write.
- **Conformance Lane disclosure** (§9): the frontmatter `description:` discloses the lane
  consequence using the literal phrase **`Conformance Lane`**.
- Out of scope: any workflow file under `.github/` in this repository -- this task authors a skill
  and emits no CI configuration; any hand edit to the doctrine files task-034 landed; any file
  under `canonical/aid/templates/knowledge-base/`; the four `update` bodies (task-038); the three
  stale catalog count comments and the render; and every behavioral run, which is task-043's and
  task-045's.

**Acceptance Criteria:**
- [ ] feature-004 V1/V2, this task's share: `ls -d canonical/skills/aid-create-cicd` succeeds, and
      `grep -cE '^  - name: aid-create-cicd$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `1`, with frontmatter `name:` == directory name == row `name`, all
      eight fields, `default_type: DOCUMENT`, `group: G4`, `alias_of: null`, `repurpose: true`, and
      §1a's `intent`
- [ ] Placement: the row's line number is greater than task-036's G4 row and less than
      `grep -n '^  # --- G5: Change + Refactor family'` (today `:233`). With task-035's and
      task-036's rows, the four `create` rows now close the G4 block
- [ ] **feature-004 V27 / BLUEPRINT criterion 4, this task's share.** The CREATE state enumerates
      **exactly three** refusal conditions, and
      `grep -niE 'empty|populated|non-empty|hand-authored|line count'` over **that state's text**
      returns **nothing**; `source: generated` is present as the third condition
- [ ] **The stage/policy line is written from this side, and is falsifiable:** the body states that
      it writes the stage -- its name, its order, its trigger, and that it runs a gate -- and states
      that it writes **no threshold, no blocking/advisory verdict and no waiver rule**, citing the
      C6 gate doc instead. A body that describes the gate's effect fails this criterion
- [ ] The other two non-owner boundaries are present: it writes no statement of **which test suites
      run** (§4 row 1) and no **build-tool version** (§4 row 3)
- [ ] The production-config rule is stated as opt-in per run: the KB record by default, a workflow
      file **only** on the user's request in that run, and `/aid-create-infra` named as the route
      for a provisioned resource
- [ ] The absent-C8-document path is written out with its registration: create the document, set
      `source: forward-authored` and `sources: []`, and in the **same run** append the doc-set entry
      at presence `required` with owner **`aid-researcher-quality`** (never `skill-self`), the
      `README.md` Completeness row and the `**Doc-set:** N documents` increment, via the
      append-block idiom, `term_exclusions` untouched
- [ ] §7a's three `source:` situations, the `approved_at_commit:` invariant, the
      `sources:`-gains-only-what-was-used rule and §4's write discipline are each stated in the
      body, and a new `## ` section obliges its `## Contents` entry in the same write
- [ ] feature-004 V22 / AC-12(a): `grep -c 'Conformance Lane' canonical/skills/aid-create-cicd/SKILL.md`
      captured to a variable is `>= 1`, with the hit **inside** the frontmatter `description:` block
- [ ] feature-004 V15, this task's share: the `description` names `/aid-update-cicd`,
      `/aid-create-infra`, `/aid-update-infra`, `/aid-create-data-pipeline`,
      `/aid-update-data-pipeline` and `/aid-deploy`, and names no neighbour §10 does not assign
- [ ] `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-create-cicd/SKILL.md`
      is empty, the body drives no `phase:` value, and a reviewer confirms it restates no rule the
      contract states
- [ ] `git status --porcelain .github/` is clean and no workflow file is added, modified or deleted
      by this task
- [ ] `ls canonical/aid/templates/knowledge-base/*.md | wc -l` captured to a variable is `14`, and
      `git diff --exit-code master -- canonical/aid/templates/kb-authoring/` shows only the hunks
      task-034 and delivery-001 committed
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` and
      `git status --porcelain .aid/knowledge/ .aid/settings.yml` are clean; no count comment inside
      `shortcut-catalog.yml` is edited; `git diff --exit-code -- tests/ site/scripts/__tests__/` is
      clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
