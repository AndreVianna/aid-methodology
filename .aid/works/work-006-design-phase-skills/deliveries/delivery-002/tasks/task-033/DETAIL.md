# task-033: Four foundation `design` doorways that resolve their destination by concern

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-033/STATE.md.
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

**Depends on:** task-032

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §1a and §1c (the four
  `design` rows, their supplied `intent` strings, their seed paths), §3a (the resolution rule and
  what it writes into the seed), §5 (the four bodies and what each draws out), §10's four
  `design` rows (negative routing), and §1b (placement). It binds feature-002 §3g's **Class 1**
  column for the `design` stage. It implements REQUIREMENTS **CC-6** and restates it nowhere.
- **First of feature-004's tasks, because §12's internal order makes it first.** The
  destination-resolution rule and the four collision assignments are settled in the SPEC (§3,
  §4); what this task lands is the *design* stage that resolves the concern and writes the
  resolved path into the seed, which is the input every later `create` reads. Authoring a
  `create` before it would fork the resolution four ways.
- **Why it follows task-032 rather than running beside the grid tasks.** feature-004 §1b places
  these four rows *"in the G3 block after feature-005's fourteen"*, and all five preceding tasks
  append to the one `canonical/aid/templates/shortcut-catalog.yml`.
- Author four hand-authored bodies --
  `canonical/skills/aid-design-{architecture,stack,testing-strategy,cicd}/SKILL.md` -- on
  feature-002 §3e's on-demand shape: Work Initiation Gate -> `worktree-lifecycle.sh create` on
  new work -> allocate `pipeline.path: lite`, `initiator: aid-design-<artifact>`,
  `lifecycle: Running`, **`phase` not driven** -> `aid-architect` dispatch tiered by complexity
  with verifier tier >= producer tier -> **full verify** -> PRESENT (hard stop) -> DONE. Each
  carries feature-002 §2d's first-use acquisition of `.aid/design/` and its `README.md`, and
  binds `canonical/aid/templates/design-lifecycle.md` without restating it.
- **Each body reads and writes exactly what §5 permits**: it reads the existing seed if present,
  the Knowledge Base and the project source; it writes **only** `.aid/design/<artifact>.md` in
  `design-seed.md`'s shape; it **never writes `.aid/knowledge/`** and **never writes production
  config** -- a `cicd` design does not edit a workflow file under `.github/`.
- **Destination resolution, which is the substance of this task** (§3a). Each body binds a
  **concern**, not a filename: `/aid-design-architecture` -> **C1** (build & shape,
  `canonical/aid/templates/kb-authoring/concern-model.md:86`); `/aid-design-stack` -> **C0**
  (technology, `:95`); `/aid-design-testing-strategy` -> **C6** (quality & testing, `:91`);
  `/aid-design-cicd` -> **C8** (shipping & operation, `:93`). Each resolves its concern against
  the project's declared doc-set (`.aid/settings.yml` `knowledge.doc_set`, falling back to the
  domain matrix row in
  `canonical/aid/templates/kb-authoring/domain-doc-matrix.md`), **confirms the resolution with
  the user at DESIGN**, and writes the resolved path into the seed's **`## Destination`** section
  -- a required section for class-1 seeds. A hybrid project whose concern is realized by two
  documents states both; this repository is that case for C6 (`test-landscape.md` **and**
  `quality-gates.md`).
- **Two resolution rules that are easy to lose.** A concern may hold more than one default doc
  and the extra one is not always a destination: C1's default set is `project-structure.md`
  **and** `architecture.md`, and `/aid-design-architecture` resolves to the doc describing the
  system's shape and **never** `project-structure.md`, which describes the repo layout. And
  where the realization is genuinely ambiguous the body **asks**; it never picks silently.
- **What each draws out** (§5's table): `architecture` -- components, boundaries, interactions,
  invariants, and what is deliberately *not* a component; `stack` -- languages, runtimes,
  frameworks and build/test tooling **with versions**, plus the rejected alternatives, recording
  **two** destinations (the C0 doc, and the project's D doc for the rejected alternatives, §7d);
  `testing-strategy` -- test levels, coverage expectations, which gates block a merge and who may
  waive one, naming the test-landscape half and the gate-policy half **separately**; `cicd` --
  pipeline stages, triggers, environments, promotion and release flow.
- Append four rows to `canonical/aid/templates/shortcut-catalog.yml`, in the G3 block after
  feature-005's fourteen and `/aid-brainstorm`, carrying all eight fields of §1a's table:
  `name` == directory, `verb: design`, `artifact: architecture|stack|testing-strategy|cicd`,
  `alias_of: null`, `default_type: DESIGN`, `group: G3`, the **`intent` string §1a supplies
  verbatim**, and `repurpose: true`.
- **No `(verb, artifact)` key collides.** `artifact: architecture` already exists on
  `aid-document-architecture` but with `verb: document`, so `{design, architecture}` is a
  distinct key; `cicd`, `stack` and `testing-strategy` are new tokens, and
  `grep -c 'artifact: cicd'`, `grep -c 'artifact: stack'` and
  `grep -c 'artifact: testing-strategy'` on the catalog each return `0` before this task.
- Out of scope: the eight `create`/`update` skills (task-035..task-038); `quality-gates.md`'s
  registration (task-034); the three stale catalog count comments and the full render
  (delivery-003); any edit to `canonical/skills/aid-config/SKILL.md`, whose `knowledge.doc_set`
  line delivery-001 already amended to name both producers -- this delivery **verifies** rather
  than repeats, and a second write there is a defect; and any file under
  `canonical/aid/templates/knowledge-base/`, so that no seed-count assertion moves.

**Acceptance Criteria:**
- [ ] feature-004 V1, this task's share:
      `ls -d canonical/skills/aid-design-{architecture,stack,testing-strategy,cicd}` returns 4
      lines, exit 0, and each holds a `SKILL.md`
- [ ] feature-004 V2, this task's share:
      `grep -cE '^  - name: aid-design-(architecture|stack|testing-strategy|cicd)$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `4`, each with frontmatter `name:` == directory name == row
      `name`, all eight fields present, `default_type: DESIGN`, `group: G3`, `alias_of: null`,
      `repurpose: true`
- [ ] Each `intent` matches §1a's supplied string for that row -- these four are quoted in the
      spec rather than authored here
- [ ] Placement: every new row's line number is greater than
      `B = grep -n '^  - name: aid-brainstorm$'` and less than
      `G = grep -n '^  # --- G8: Document family'`, so feature-004's four sit after all fourteen
      grid rows (§1b)
- [ ] **The bound concern is in the body, and the filename is not the binding.** For each of the
      four, its `SKILL.md` names its concern id (`C1`, `C0`, `C6`, `C8` respectively) and states
      the resolution order -- `.aid/settings.yml` `knowledge.doc_set` first, the domain matrix row
      as the fallback, the user confirming at DESIGN. A body that hardcodes `architecture.md`,
      `technology-stack.md`, `test-landscape.md` or `infrastructure.md` as *the* destination fails
      this criterion; naming one as the **default** is permitted and is what §1a's table records
- [ ] Each body writes the resolved path into the seed's **`## Destination`** section, and
      `/aid-design-testing-strategy` records the C6 test-landscape half and the gate-policy half
      **separately** while `/aid-design-stack` records **two** destinations (C0 and the D doc)
- [ ] `/aid-design-architecture`'s body states that it never writes `project-structure.md`, and
      every body states that an ambiguous realization is **asked**, never picked silently
- [ ] feature-004 V15, this task's share: each `description` contains the literal name of every
      neighbour §10 assigns it -- `aid-design-architecture` -> `/aid-create-architecture`, bare
      `/aid-design`, `/aid-document-architecture`; `aid-design-stack` -> `/aid-create-stack`,
      `/aid-design-config`, `/aid-research`; `aid-design-testing-strategy` ->
      `/aid-create-testing-strategy`, `/aid-design-test`, `/aid-test`; `aid-design-cicd` ->
      `/aid-create-cicd`, `/aid-design-infra`, `/aid-design-data-pipeline`, `/aid-deploy` -- and
      **no** description names a neighbour §10 does not assign it
- [ ] feature-004 V15's mutual halves that close here: `/aid-design-stack` <-> `/aid-design-config`
      and `/aid-design-cicd` <-> `/aid-design-infra` and `/aid-design-testing-strategy` <->
      `/aid-design-test` are each **mutual** at this task's close, since task-030 and task-031
      wrote the feature-005 sides
- [ ] feature-004 AC-2's static half: each body states that `design` writes only
      `.aid/design/<artifact>.md`, never `.aid/knowledge/`, and never a workflow file under
      `.github/`. The behavioral half is task-040..task-043's
- [ ] `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-design-{architecture,stack,testing-strategy,cicd}/SKILL.md`
      is empty, and a reviewer confirms no body restates a rule the contract states
- [ ] Each body drives no `phase:` value; no `intent` contains a backtick or other markdown and
      its em-dashes are ASCII `--`
- [ ] `ls canonical/aid/templates/knowledge-base/*.md | wc -l` captured to a variable is `14`
      before and after this task; `git diff --exit-code master -- canonical/skills/aid-config/SKILL.md`
      shows only the hunks delivery-001 committed
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean; no count comment inside
      `shortcut-catalog.yml` is edited; `git diff --exit-code -- tests/ site/scripts/__tests__/`
      is clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
