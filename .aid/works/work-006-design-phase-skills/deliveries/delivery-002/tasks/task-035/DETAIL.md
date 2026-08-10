# task-035: `/aid-create-architecture` and `/aid-create-stack` -- the C1 and C0 realizers

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-035/STATE.md.
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

**Depends on:** task-034

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §6 (the gate set and the
  realization event), §6b (how feature-002 §3c's four first-write situations resolve for a
  whole-document owner), §6c (the three refusal conditions and the repeat-`create` path), §6d,
  §6e, §7a (frontmatter invariants), §7b (`architecture`, concern C1), §7c (`stack`, concern C0),
  §7d (where rationale and rejected alternatives go), §3b (registration when the concern has no
  doc), §4 (region ownership rows 2 and 3, and the write discipline), §9 (Conformance Lane), §10.
  It binds feature-002 §3g's **Class 1** column and REQUIREMENTS **CC-1**, **CC-2**, **CC-3**,
  **CC-5**, **CC-6** by reference, restating none of them.
- Author two hand-authored bodies -- `canonical/skills/aid-create-architecture/SKILL.md` and
  `canonical/skills/aid-create-stack/SKILL.md` -- on feature-002 §3e's shape
  (`INTAKE -> CREATE -> VERIFY -> PRESENT -> DONE`, Work Initiation Gate allocation with
  `pipeline.path: lite`, `initiator: aid-create-<artifact>`, **`phase` not driven**,
  `aid-architect` tiered with verifier tier >= producer tier, **full verify**), and append two
  rows to `canonical/aid/templates/shortcut-catalog.yml` at the **end of the G4 block** (§1b),
  each with `verb: create`, `artifact: architecture|stack`, `alias_of: null`,
  `default_type: DOCUMENT`, `group: G4`, the `intent` string §1a supplies verbatim, and
  `repurpose: true`.
- **The CREATE state enumerates exactly three refusal conditions and no fourth** (§6c): (1) no
  seed at `.aid/design/<artifact>.md` -- refuse, name `/aid-design-<artifact>`, write nothing;
  (2) seed present with `## Open questions` non-empty by feature-002 §4's detection rule and no
  explicit override -- refuse, leave the seed intact; (3) destination `source: generated` -- refuse,
  a registered build script owns the content. **Otherwise -- including a fully populated as-built
  destination -- it realizes.** A populated destination is the normal case, never a refusal
  condition; a fourth gate keyed on the destination's size, emptiness or `hand-authored` status is
  the defect the criteria below exist to catch, because it is how the withdrawn file-level refusal
  re-enters. The exclusion list is `hand-authored`; `source: generated` is the third **mandated**
  condition and forbidding it would delete a refusal the spec requires.
- **The realization event** (§6c row 4): merge the settled content into the destination per §7,
  offer any additional user-requested output, then **delete the seed**. §6b's four situations
  resolve here as: destination absent and the skill owns the whole document -> create it (§6e);
  destination absent with only a region owned -> **no instance in this feature** (CC-5's only
  instance is `/aid-create-mvp`, feature-003's); destination present and populated with the owned
  region absent -> add the region, the dominant path; owned region carrying content **this
  lifecycle previously committed** -> route to `/aid-update-<artifact>` for that content. "Committed
  content" means content an earlier `create` for this same artifact wrote, at the granularity of the
  sections the seed's `## Destination` names -- **not** the as-built content `/aid-discover` wrote.
- **The repeat `create` writes what is new, routes what is not, and never halts with nothing
  done** (§6c): every part of the seed that is new is written; the parts that would overwrite
  previously committed content are named and routed to `/aid-update-<artifact>`; the seed is
  deleted only when everything its `## Destination` named was written, otherwise left in place
  carrying just the unrealized parts -- which `update` then consumes under CC-3.
- **Frontmatter invariants, identical for both** (§7a): a document the skill itself creates gets
  `source: forward-authored` and `sources: []`; a document that already existed keeps whatever
  `source:` it had, **unchanged**; `source: generated` refuses. `approved_at_commit:` is **never**
  written or restamped -- it is generator-written by `/aid-discover` and `/aid-update-kb` on
  approval (`canonical/aid/templates/kb-authoring/frontmatter-schema.md:98`;
  `canonical/skills/aid-update-kb/references/state-apply.md:262`), and these skills are neither.
  `sources:` gains only what the run actually used.
- **Write discipline** (§4): read the whole destination, edit in place, write back with everything
  outside the edited range byte-identical; never regenerate or restructure -- the same guard
  `/aid-update-kb` places on its own KB writes
  (`canonical/skills/aid-update-kb/references/state-apply.md:252-258`), bound rather than
  reinvented. Adding a `## ` section obliges updating the document's `## Contents` list in the
  **same** write.
- **Content rules, per artifact.** `/aid-create-architecture` (C1): writes components and their
  responsibilities, boundaries and what crosses them, interactions and data flow, invariants a
  change must not break, and what is deliberately *not* a component; into existing sections
  wherever one fits, a new `## ` section only when the seed's content maps to none. It must **not**
  write framework or runtime **versions** (C0, §4 row 2), pipeline stages or environments (C8, §4
  row 1), or **rejected alternatives** (concern D, §7d). `/aid-create-stack` (C0): writes languages,
  runtimes, frameworks, package managers, build and test tooling **each with its version**, and
  version constraints or floors; **among these twelve skills** it is the only writer of
  framework/tool versions. It must **not** write rejected alternatives into the C0 doc -- that
  document has no section for them and inventing one would put concern-D content in a C0 doc -- nor
  architecture structure (C1), nor CI runner configuration (C8). Rejected alternatives go to the
  project's **D** doc, `decisions.md` by default, owner `aid-researcher-architecture`
  (`canonical/aid/templates/kb-authoring/domain-doc-matrix.md:146`, `:176`, `:229`, `:278`, `:301`,
  `:322`); in this repository it is already present and declared `required`, so nothing is created
  there.
- **Registration when the concern has no doc** (§3b, CC-2): `create` creates the document **and,
  in the same run**, appends one `.aid/settings.yml` `knowledge.doc_set` entry
  `<file>|<owner>|required` (presence `required` per **CC-1**) and one `.aid/knowledge/README.md`
  Completeness row, incrementing that file's `**Doc-set:** N documents` line (`:21`). Both follow
  the R13 append-block idiom -- one entry appended, never a rewrite of the block, never a touch to
  `term_exclusions`. The owner is the doc's **matrix** row slot, never a blanket `skill-self`:
  `skill-self` is written only where no matrix row assigns a slot, and no document in this feature
  falls in that case.
- **Conformance Lane disclosure** (§9): each body's frontmatter `description:` discloses the lane
  consequence using the literal phrase **`Conformance Lane`**, because creating a document opts it
  into that lane permanently and the user is choosing it.
- Out of scope: `/aid-create-testing-strategy` (task-036) and `/aid-create-cicd` (task-037); the
  four `update` bodies (task-038); any edit to `canonical/skills/aid-config/SKILL.md`, whose
  `knowledge.doc_set` line delivery-001 already amended to name both producers -- this task
  **verifies** and adds nothing, and a second write there is a defect rather than a duplicate; any
  file under `canonical/aid/templates/knowledge-base/`; the three stale catalog count comments and
  the render; and every behavioral run, which needs the render and is task-040 and task-041's.

**Acceptance Criteria:**
- [ ] feature-004 V1/V2, this task's share:
      `ls -d canonical/skills/aid-create-{architecture,stack}` returns 2 lines, and
      `grep -cE '^  - name: aid-create-(architecture|stack)$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `2`, each with frontmatter `name:` == directory name == row
      `name`, all eight fields, `default_type: DOCUMENT`, `group: G4`, `alias_of: null`,
      `repurpose: true`, and the `intent` string §1a supplies
- [ ] Placement: both rows sit at the **end of the G4 block** -- each row's line number is greater
      than every existing `group: G4` row's and less than
      `grep -n '^  # --- G5: Change + Refactor family'`
- [ ] **feature-004 V27 / BLUEPRINT criterion 4, this task's share.** For each of the two files,
      the CREATE state enumerates **exactly three** refusal conditions, and
      `grep -niE 'empty|populated|non-empty|hand-authored|line count'` over **that state's text**
      returns **nothing**. A fourth gate keyed on the destination's size, emptiness or
      `hand-authored` status fails this criterion
- [ ] `source: generated` is present as the **third** refusal condition in both bodies -- deleting
      it also fails the criterion above, in the opposite direction
- [ ] The repeat-`create` path is written out in both bodies: what is new is written, what would
      overwrite previously committed content is **named and routed** to `/aid-update-<artifact>`,
      and the seed is deleted only when everything its `## Destination` named was written. A body
      whose repeat path halts with nothing done fails
- [ ] §7a's three `source:` situations and both further invariants are stated in each body:
      created-here -> `forward-authored` with `sources: []`; already existed -> **unchanged**;
      `generated` -> refuse. `approved_at_commit:` is named as never written or restamped, and
      `sources:` gains only what the run used
- [ ] §4's write discipline is stated in each body -- read whole, edit in place, everything outside
      the edited range byte-identical, never regenerate or restructure -- and adding a `## ` section
      obliges the matching `## Contents` entry in the same write
- [ ] The per-artifact **Must not write** lists are present verbatim in substance:
      `aid-create-architecture` excludes versions, pipeline stages/environments and rejected
      alternatives; `aid-create-stack` excludes rejected alternatives from the C0 doc,
      architecture structure and CI runner configuration, and routes rejected alternatives to the
      project's D doc
- [ ] §3b's registration is stated as a **same-run** effect of the skill (CC-2) with presence
      `required` (CC-1) and the owner taken from the doc's matrix row, and each body names the
      append-block idiom and states that `term_exclusions` is never touched
- [ ] feature-004 V22 / AC-12(a): `grep -c 'Conformance Lane' canonical/skills/aid-create-architecture/SKILL.md`
      and the same over `aid-create-stack/SKILL.md` are each `>= 1`, with the hit **inside** the
      frontmatter `description:` block
- [ ] feature-004 V15, this task's share: each `description` names every neighbour §10 assigns it
      -- `aid-create-architecture` -> `/aid-update-architecture` and `/aid-document-architecture`;
      `aid-create-stack` -> `/aid-update-stack`, `/aid-create-config` and `/aid-update-config` --
      and names no neighbour §10 does not assign
- [ ] `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-create-{architecture,stack}/SKILL.md`
      is empty, each body drives no `phase:` value, and a reviewer confirms neither restates a rule
      the contract states
- [ ] `ls canonical/aid/templates/knowledge-base/*.md | wc -l` captured to a variable is `14`, and
      `git diff --exit-code master -- canonical/skills/aid-config/SKILL.md` shows only the hunks
      delivery-001 committed
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` and
      `git status --porcelain .aid/knowledge/ .aid/settings.yml` are clean -- this task authors
      skills and writes no Knowledge Base content; no count comment inside `shortcut-catalog.yml` is
      edited; `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
