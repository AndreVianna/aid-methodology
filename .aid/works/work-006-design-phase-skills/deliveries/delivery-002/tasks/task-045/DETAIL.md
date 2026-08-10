# task-045: Absent destinations created, registered in the same run, and left forward-authored

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-045/STATE.md.
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

**Type:** TEST

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-043

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §11 rows **V14** (creation
  registers, in the same run), **V20** (a created doc is `forward-authored` with empty `sources:`)
  and **V17**'s `forward-authored` half, with §6e, §3b, §8 and §8c as the rules under test. It closes
  the **CC-2** half of BLUEPRINT criterion 7 -- the other half, CC-4's four surfaces, is task-034's.
- **Every run happens in a scratch project under `mktemp -d`, never against this repository's own
  `.aid/`**, and the reason is not only hygiene: this repository has **no** absent foundation
  destination. All five -- `architecture.md`, `technology-stack.md`, `test-landscape.md`,
  `quality-gates.md`, `infrastructure.md` -- are present and declared members
  (`.aid/settings.yml:41-59`), so the creation path is unreachable here by construction and needs a
  project that lacks the document. This task therefore writes no path under `.aid/knowledge/`,
  `.aid/design/`, `.aid/settings.yml` or `.aid/works/` in the working tree, which is what makes it
  schedulable beside task-044, task-046 and task-047. It **renders nothing and reverts nothing**.
- **Fixture policy -- two baselines, a fresh copy per mutating row.** Each baseline is created under
  `mktemp -d` and `git init`-ed with a baseline commit, because the `git diff` and
  `git status --porcelain` assertions below return a real result only inside a work tree -- outside
  one `git status` exits 128, which is not "empty". Each carries this repository's rendered dogfood
  `.claude/` copied in, so the twenty-seven skills are invocable from that directory.
  - **F-noC8** -- a project declaring domain `methodology-tooling`, where the C8 doc is
    `conditional:the tooling ships/runs as a deployed artifact`
    (`canonical/aid/templates/kb-authoring/domain-doc-matrix.md:325`), so its absence is legitimate
    rather than a broken fixture. **The domain is declared where this repository declares its
    own** -- the `- **Domain:**` line in `.aid/knowledge/README.md`'s header (`:20` here) -- and
    **not** in `.aid/settings.yml`, which carries `knowledge.doc_set` but no domain key; a fixture
    that put it there would leave the resolution falling back to the wrong matrix row. It has
    **no** `.aid/knowledge/infrastructure.md` and **no** `infrastructure.md` entry in
    `.aid/settings.yml` `knowledge.doc_set`; it has a `.aid/knowledge/README.md` carrying a
    Completeness table and a `**Doc-set:** N documents` line; and a **ready**
    `.aid/design/cicd.md` seed -- `## Open questions` empty, `## Destination` naming the C8 doc --
    so the only thing under test is the creation-and-registration path.
  - **F-noGate** -- the same shape with **no** `.aid/knowledge/quality-gates.md` and no
    `quality-gates.md` doc-set entry, a present populated `test-landscape.md`, and a ready
    `.aid/design/testing-strategy.md` seed whose `## Destination` names both C6 halves. This is
    feature-004 §8's on-demand creation, and §8c's *"a project that runs it gets the document **and**
    the registration in the same run"*.
  - **F-fwd** -- a `cp -a` snapshot of F-noC8 taken **immediately after** its `create` run and its
    commit, so the C8 doc exists carrying `source: forward-authored`. V17's `forward-authored` half
    runs here. The snapshot is taken rather than reconstructed, because a hand-written
    `forward-authored` document would not be one this feature's `create` produced.
- **Three authored runs and no fourth**: `/aid-create-cicd` in a fresh copy of F-noC8;
  `/aid-create-testing-strategy` in a fresh copy of F-noGate; `/aid-update-cicd` in a fresh copy of
  F-fwd. Each allocates a `work-NNN` folder **inside its scratch project** and executes feature-002
  §3e's full-verify loop.
- **The owner field is the doc's matrix row slot, never a blanket `skill-self`**, and that is what
  the criteria below assert: `infrastructure.md` -> `aid-researcher-quality`
  (`domain-doc-matrix.md:144`, `:173`, `:203`, `:294`, `:325`); `quality-gates.md` ->
  `aid-researcher-quality` (`:321`). Writing `skill-self` for either would silently remove that
  document's researcher discovery dispatches and contradict every shipped matrix row.
- Out of scope: the brownfield realization sequence and the `update` seed contract (task-040 through
  task-043); the three refusals and the repeat `create` (task-044); FR-8's asking and the
  Conformance-Lane divergence (task-046); the engine additivity comparison (task-047); any edit to
  this repository's `.aid/settings.yml`, `.aid/knowledge/README.md` or
  `.aid/knowledge/quality-gates.md` -- §8b shows all three already carry what §3b would write;
  CC-4's four canonical surfaces (task-034); authoring any test script under `tests/` or adding any
  bash assertion id (feature-001 AC-3); and the `coverage-parity` re-bootstrap.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** (TEST default: all acceptance criteria from the source feature covered)
- [ ] **feature-004 V14 / AC-16 -- creation registers, in the same run**, in a fresh copy of
      F-noC8. All four conjuncts hold after the single `/aid-create-cicd` run:
      (a) `.aid/knowledge/infrastructure.md` now exists;
      (b) `git diff .aid/settings.yml` shows **exactly one** added line matching
      `infrastructure.md|aid-researcher-quality|required` -- presence `required` per **CC-1**, owner
      from the matrix row, and one line, not a rewritten block;
      (c) `git diff .aid/knowledge/README.md` shows **exactly one** added Completeness row, whose
      `Concern` is the doc's spine dimension (**C8**) and whose `Owner` is the same owner;
      (d) that same diff shows a **`+1`** on the `**Doc-set:** N documents` line (`:21`)
- [ ] **No hand edit outside the run performs any of it** (CC-2): the run is the only action taken
      between the fixture's baseline commit and the `git diff` above, and the transcript records no
      manual edit to `.aid/settings.yml` or `.aid/knowledge/README.md`
- [ ] `term_exclusions` is untouched and the doc-set block is **appended to**, not rewritten:
      `git diff .aid/settings.yml` shows a single `+` line inside the existing `doc_set:` list and no
      `-` line anywhere (the R13 append-block idiom)
- [ ] **feature-004 V20:** the created `.aid/knowledge/infrastructure.md` carries
      `source: forward-authored` and `sources: []`. Listing code files as sources for a
      forward-authored doc is forbidden, so a non-empty `sources:` fails
- [ ] **feature-004 §8 / §8c and BLUEPRINT criterion 7's same-run half, for the gate document**, in
      a fresh copy of F-noGate: the single `/aid-create-testing-strategy` run creates
      `.aid/knowledge/quality-gates.md` **and**, in that run, appends exactly one doc-set entry
      matching `quality-gates.md|aid-researcher-quality|required` and exactly one `README.md`
      Completeness row with concern **C6**, incrementing the `**Doc-set:** N documents` line by one.
      The created document carries `source: forward-authored` and `sources: []`
- [ ] The same run also writes `test-landscape.md`, and neither C6 document's diff contains a
      framework **version** (§4 row 2) nor any pipeline stage, trigger, environment or promotion rule
      (§4 row 1)
- [ ] **feature-004 V17, the `forward-authored` half**, in a fresh copy of F-fwd: after
      `/aid-update-cicd`, `git diff` on the C8 document shows **no change to the `source:` line** --
      it is `forward-authored` before and after. `update` never rewrites a destination's production
      mode. The `hand-authored` half was task-040's, so V17 is closed for both values only with both
      tasks
- [ ] `approved_at_commit:` is not written on either created document and not restamped by the
      `update` run, and `bash canonical/aid/scripts/kb/lint-frontmatter.sh` -- run against the scratch
      project's KB -- is green after each writing run
- [ ] **feature-004 V21 / AC-11 for the created documents:** each created document's `## Contents`
      set-comparison returns empty in **both** directions (`comm -3` of the `^## ` heading set minus
      `Contents` against the `## Contents` link-text set)
- [ ] **Every row runs against the fixture the § Scope list assigns it, and every mutating row gets a
      fresh `cp -a` copy.** F-fwd is a snapshot taken **after** F-noC8's `create` run and commit, not
      a hand-written `forward-authored` document; a row that repairs its own precondition once it has
      started fails this criterion
- [ ] Each authored run's allocated work folder and the confirmed absence of a `phase:` value
      (`grep -c '^phase: .'` over that run's work `STATE.md` captured to a variable -> `0`) are
      recorded into this task's STATE.md notes **before** the scratch project is torn down
- [ ] **This task mutates no shared tree:** `git status --porcelain` over `.aid/knowledge/`,
      `.aid/design/`, `.aid/settings.yml`, `.aid/works/`, `profiles/`, `.claude/` and `.cursor/` is
      **identical before and after** the task, and `git diff --cached --name-only` is empty in this
      repository, with no `git add -A` / `git add .` / `git add -u` / `git commit -a` used while
      task-039's render is live
- [ ] Tests are deterministic and setup/teardown is clean: both baselines and every per-row copy live
      under `mktemp -d` and are removed on exit **including on failure**; **three** authored runs and
      no fourth; two executions over the same inputs produce identical outcomes
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
