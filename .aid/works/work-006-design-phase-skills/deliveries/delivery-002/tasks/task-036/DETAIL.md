# task-036: `/aid-create-testing-strategy` -- the C6 realizer that creates the gate document

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-036/STATE.md.
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

**Depends on:** task-035

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §6 (gates and the
  realization event), §6b, §6c, §6e (creating a destination that is absent -- this is one of the
  two skills that can), §7a (frontmatter invariants), §7e (`testing-strategy`, concern C6, **two
  documents**), §8 and §8a (`quality-gates.md` conditional, created on demand), §8c, §3b
  (registration), §4 rows 1, 2 and 4 (the contested regions), §9, §10. It binds feature-002 §3g's
  **Class 1** column and REQUIREMENTS **CC-1**, **CC-2**, **CC-3**, **CC-6** by reference.
- **It is its own task, and the reason is that it is the heaviest of the four.** It owns **two**
  destinations rather than one, it is the skill that creates `quality-gates.md` on demand (§6e,
  §8), and it stands on three of §4's four contested rows -- 1 (CI/CD pipeline), 2 (test
  frameworks) and 4 (gate enforcement). Bundling it with a sibling would put two destinations and
  three collision boundaries in one reviewable unit.
- Author `canonical/skills/aid-create-testing-strategy/SKILL.md` on feature-002 §3e's shape
  (`INTAKE -> CREATE -> VERIFY -> PRESENT -> DONE`; Work Initiation Gate allocation with
  `pipeline.path: lite`, `initiator: aid-create-testing-strategy`, **`phase` not driven**;
  `aid-architect` tiered, verifier tier >= producer tier; **full verify**), and append one row to
  `canonical/aid/templates/shortcut-catalog.yml` at the end of the G4 block: `verb: create`,
  `artifact: testing-strategy`, `alias_of: null`, `default_type: DOCUMENT`, `group: G4`, the
  `intent` string §1a supplies verbatim, `repurpose: true`.
- **Two destinations, each wholly owned, with one restriction** (§7e): the project's C6 doc(s) --
  `test-landscape.md` (default seed member) **and** `quality-gates.md` (conditional). Owned region
  in the C6 **test** doc is the whole document *with its CI section restricted to the test-lane
  mapping*; owned region in the **gate** doc is the whole document.
- **What goes where, and the two split lines** (§7e, §4): into the test doc -- test levels and what
  each is for, coverage expectations, which suites run in which CI lane, known gaps. Into the gate
  doc -- gate policy: what blocks a merge, the thresholds, who may waive and how. It must **not**
  write pipeline stages, triggers, environments or promotion rules (C8, §4 row 1), and must **not**
  cite a framework **version in either C6 document** (C0, §4 row 2) -- a version in a C6 doc is a
  duplicate that will drift. The C6-test / gate-doc boundary is a content split **under one owner**,
  not a contest between two skills, and the split line is the one this repository already draws in
  prose: `quality-gates.md`'s own `summary:` says it is *"distinct from the automated test suites in
  test-landscape.md"* (`.aid/knowledge/quality-gates.md:5`).
- **Creating `quality-gates.md` on demand** (§6e, §8): where the concern's gate document is absent,
  `create` creates it, sets `source: forward-authored` and `sources: []`, and registers it in the
  same run per §3b -- one `.aid/settings.yml` `knowledge.doc_set` entry
  `quality-gates.md|aid-researcher-quality|required` (presence `required` per **CC-1**; owner from
  the matrix row at `canonical/aid/templates/kb-authoring/domain-doc-matrix.md:321`), and one
  `.aid/knowledge/README.md` Completeness row with its `**Doc-set:** N documents` line (`:21`)
  incremented. Both via the R13 append-block idiom; `term_exclusions` is never touched. **No hand
  edit outside the skill run performs any of this** (CC-2).
- **The CREATE state enumerates exactly three refusal conditions and no fourth** (§6c): seed
  absent; `## Open questions` non-empty by feature-002 §4's detection rule with no override;
  destination `source: generated`. A populated destination is the **normal** case. The exclusion
  list is `hand-authored`, and `source: generated` is the third **mandated** condition -- removing
  it deletes a refusal the spec requires.
- **The realization event and the repeat `create`** as §6c states them: merge per §7e, offer any
  additional user-requested output, delete the seed; on a repeat whose seed targets content this
  skill previously committed, write what is new, name and route the rest to
  `/aid-update-testing-strategy`, and leave the seed carrying only the unrealized parts for `update`
  to consume under CC-3.
- **Frontmatter invariants** (§7a): created-here -> `forward-authored` + `sources: []`; already
  existed -> `source:` **unchanged**; `generated` -> refuse. `approved_at_commit:` never written or
  restamped (`canonical/aid/templates/kb-authoring/frontmatter-schema.md:98`;
  `canonical/skills/aid-update-kb/references/state-apply.md:262`). **Write discipline** (§4): read
  whole, edit in place, everything outside the edited range byte-identical, never regenerate or
  restructure (`state-apply.md:252-258`); a new `## ` section obliges its `## Contents` entry in the
  same write.
- **Conformance Lane disclosure** (§9): the frontmatter `description:` discloses the lane
  consequence using the literal phrase **`Conformance Lane`** -- this skill can create a document,
  and creating one opts it into that lane permanently.
- Out of scope: any hand edit to `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` or
  `concern-model.md` -- task-034 landed both, and a second write is a defect rather than a
  duplicate; any file under `canonical/aid/templates/knowledge-base/`, so `quality-gates.md`
  acquires **no** template and no seed-count assertion moves; any edit to this repository's
  `.aid/settings.yml` or `.aid/knowledge/quality-gates.md` (§8b -- both already carry what §3b
  would write); the three stale catalog count comments and the render; and every behavioral run,
  which is task-042's and task-045's.

**Acceptance Criteria:**
- [ ] feature-004 V1/V2, this task's share: `ls -d canonical/skills/aid-create-testing-strategy`
      succeeds, and
      `grep -cE '^  - name: aid-create-testing-strategy$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `1`, with frontmatter `name:` == directory name == row `name`, all
      eight fields, `default_type: DOCUMENT`, `group: G4`, `alias_of: null`, `repurpose: true`, and
      §1a's `intent`
- [ ] Placement: the row's line number is greater than task-035's two G4 rows and less than
      `grep -n '^  # --- G5: Change + Refactor family'` (today `:233`)
- [ ] **feature-004 V27 / BLUEPRINT criterion 4, this task's share.** The CREATE state enumerates
      **exactly three** refusal conditions, and
      `grep -niE 'empty|populated|non-empty|hand-authored|line count'` over **that state's text**
      returns **nothing**. `source: generated` is present as the third condition -- deleting it
      fails this criterion in the opposite direction
- [ ] **Both destinations are named as owned regions, and the restriction on the test doc's CI
      section is stated**: the whole test-landscape document with its CI section limited to the
      **test-lane mapping**, and the whole gate document. A body that names one destination fails
- [ ] The two **must-not-write** boundaries are present: no pipeline stage, trigger, environment or
      promotion rule (§4 row 1, cite the C8 doc instead), and **no framework version in either C6
      document** (§4 row 2)
- [ ] §4 row 4 is stated from the owning side: this skill owns the **policy** -- what blocks, the
      threshold, who may waive and how -- and the body says so, so that task-037's `/aid-create-cicd`
      can be held to writing only the stage
- [ ] The on-demand creation path is written out: absent gate document -> create it, set
      `source: forward-authored` and `sources: []`, and register **in the same run** with presence
      `required` and owner `aid-researcher-quality`, plus the `README.md` Completeness row and the
      `**Doc-set:** N documents` increment. The body names the append-block idiom and states that
      `term_exclusions` is never touched
- [ ] §7a's three `source:` situations, the `approved_at_commit:` invariant and the
      `sources:`-gains-only-what-was-used rule are each stated in the body
- [ ] §4's write discipline is stated -- read whole, edit in place, everything outside the edited
      range byte-identical, never regenerate or restructure -- and a new `## ` section obliges its
      `## Contents` entry in the same write
- [ ] feature-004 V22 / AC-12(a):
      `grep -c 'Conformance Lane' canonical/skills/aid-create-testing-strategy/SKILL.md` captured to
      a variable is `>= 1`, with the hit **inside** the frontmatter `description:` block
- [ ] feature-004 V15, this task's share: the `description` names `/aid-update-testing-strategy`,
      `/aid-create-test` and `/aid-update-test`, and names no neighbour §10 does not assign
- [ ] feature-004 V24, this task's share: `canonical/skills/aid-create-test/` and
      `canonical/skills/aid-create-testing-strategy/` are **distinct** directories, and
      `grep -c 'artifact: test-strategy' canonical/aid/templates/shortcut-catalog.yml` captured to a
      variable -> `0` (its value today)
- [ ] `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-create-testing-strategy/SKILL.md`
      is empty, the body drives no `phase:` value, and a reviewer confirms it restates no rule the
      contract states
- [ ] No template is added and no doctrine file is re-edited:
      `ls canonical/aid/templates/knowledge-base/*.md | wc -l` captured to a variable is `14`, and
      `git diff --exit-code master -- canonical/aid/templates/kb-authoring/` shows only the hunks
      task-034 and delivery-001 committed
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` and
      `git status --porcelain .aid/knowledge/ .aid/settings.yml` are clean; no count comment inside
      `shortcut-catalog.yml` is edited; `git diff --exit-code -- tests/ site/scripts/__tests__/` is
      clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
