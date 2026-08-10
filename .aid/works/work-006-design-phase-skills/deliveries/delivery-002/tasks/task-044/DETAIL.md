# task-044: The three `create` refusals and the repeat-`create` route, in scratch projects

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-044/STATE.md.
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
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §11 rows **V6**
  (seed-absent refusal), **V7** (the readiness gate), **V18** (`source: generated` refused by both
  verbs), **V26** (the repeat `create` routes, does not overwrite and does not halt) and **V27** (no
  fourth `create` gate, over all four bodies), with §6a, §6b, §6c and §6d as the rules under test.
  It closes the refusal half of BLUEPRINT criterion 4 -- the half whose failure mode is a **fourth**
  gate re-entering.
- **Every run in this task happens in a scratch project under `mktemp -d`, never against this
  repository's own `.aid/`.** That is what keeps the task free of shared mutable state: it writes no
  path under `.aid/knowledge/`, `.aid/design/`, `.aid/settings.yml` or `.aid/works/` in the working
  tree, so it is schedulable beside task-045, task-046 and task-047, which are bounded the same way.
  It **renders nothing and reverts nothing**; task-039 owns the render and task-048 the revert.
- **Fixture policy -- one baseline, four fresh copies, no row inheriting another row's mutation.**
  The expensive unit is an authored skill run, which allocates a `work-NNN` folder inside the scratch
  project and executes feature-002 §3e's full-verify loop. A `cp -a` is not. So runs are shared,
  directories are not.
  - **F-pop** -- the pristine baseline, created under `mktemp -d` and then `git init`-ed with a
    baseline commit. The `git init` premise is stated because the `git status --porcelain` assertions
    below return empty only inside a work tree -- outside one `git status` exits 128, which is not
    "empty" and would be misread as a pass. It carries: this repository's rendered dogfood `.claude/`
    copied in, so the twenty-seven skills are invocable from that directory; a `.aid/settings.yml`
    declaring `architecture.md|aid-researcher-architecture|required`; a **populated**
    `.aid/knowledge/architecture.md` whose frontmatter carries `source: hand-authored` and a
    `## Contents` list consistent with its body; a `.aid/knowledge/README.md` with a Completeness
    table and a `**Doc-set:** N documents` line; and **no** `.aid/design/`.
  - **F-noseed** -- a fresh `cp -a` of F-pop, unchanged. V6 runs here.
  - **F-open** -- a fresh `cp -a` of F-pop plus `.aid/design/architecture.md` whose
    **`## Open questions` is non-empty** by feature-002 §4's detection rule: at least one non-blank
    line that is neither the literal token `None` nor a line consisting wholly of a single `{...}`
    placeholder span. That clause belongs to the fixture rather than to the row, because V7's whole
    subject is `create` refusing against exactly that state. V7 runs here.
  - **F-gen** -- a fresh `cp -a` of F-pop with the destination's frontmatter changed to
    `source: generated` and a **ready** seed present (`## Open questions` empty), so the only reason
    to refuse is the production mode. V18 runs here, for **both** verbs.
  - **F-committed** -- a fresh `cp -a` of F-pop in which the **first** `/aid-create-architecture` run
    realizes a ready seed and the result is **committed** in that scratch repository, then a
    **second** seed is written whose `## Destination` names one section the first run wrote **plus**
    one section it did not. The commit is what makes the second run's subject *"content this
    lifecycle previously committed"* (§6b) rather than as-built content, which is the distinction
    §6a exists to preserve. V26 runs here.
- **Two authored runs and four non-realizing invocations, and the two words carry the delivery's two
  senses.** An **authored run** realizes -- it allocates a `work-NNN` folder inside the scratch
  project and executes the full-verify loop -- while a **non-realizing invocation** (a refusal or a
  routing exit) writes nothing and allocates nothing. The authored runs are V26's two
  `/aid-create-architecture` runs; the non-realizing invocations are V6's `create`, V7's `create`,
  and V18's `create` **and** `update`. V6, V7 and V18 refuse **by construction** -- that is what each
  row tests -- so none produces a work folder, and none owes a `phase:` record.
- **V27 is static and is aggregated here**, over all four `create` bodies rather than one: for each,
  the CREATE state enumerates exactly three refusal conditions and the grep set returns nothing.
  task-035, task-036 and task-037 each asserted their own share at authoring time; this is the row
  read whole.
- Out of scope: the brownfield realization sequence and the `update` seed contract, which are
  task-040 through task-043's; the absent-destination creation path and its registration (task-045);
  FR-8's asking and the Conformance-Lane divergence (task-046); the engine additivity comparison
  (task-047); authoring any test script under `tests/` or adding any bash assertion id -- the ground
  is **feature-001 AC-3**; and the `coverage-parity` re-bootstrap.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** (TEST default: all acceptance criteria from the source feature covered)
- [ ] **feature-004 V6 -- seed-absent refusal**, in F-noseed: `/aid-create-architecture` **refuses**,
      **names `/aid-design-architecture`** in its output, and leaves
      `git status --porcelain .aid/knowledge/` **empty** inside the scratch project. A refusal that
      writes nothing but does not name the `design` skill fails this criterion -- writing nothing is
      not sufficient
- [ ] **feature-004 V7 -- the readiness gate**, in F-open: with `## Open questions` non-empty by
      feature-002 §4's detection rule and **no** override, `/aid-create-architecture` **refuses**,
      the seed is **still present** afterwards, and the destination is byte-identical
- [ ] **feature-004 V18 -- `source: generated` refused by both verbs**, in two fresh copies of
      F-gen: `/aid-create-architecture` refuses and `/aid-update-architecture` refuses, and in each
      case `git diff --exit-code` on the destination inside the scratch project is clean. A
      working-tree check is valid here precisely because the edit is never made
- [ ] **feature-004 V26 -- the repeat `create` routes rather than overwriting or halting**, in
      F-committed: the second run **writes the new section**, leaves the previously committed section
      **byte-identical**, **names `/aid-update-architecture`** for it, and leaves the seed in place
      carrying **only** the unrealized part. A run that halts with nothing done fails, and so does one
      that rewrites the committed section
- [ ] The surviving seed has a consumer, asserted rather than asserted-of: immediately after V26's
      second run, `/aid-update-architecture` in that same copy consumes it -- the seed file is gone
      and the destination carries its `## Current direction`. This is CC-3 closing the loop V26 opens,
      and without it the routed seed would accumulate. It is a **third** authored run and is counted
      as such below
- [ ] **feature-004 V27 -- no fourth `create` gate, over all four bodies.** For each of
      `canonical/skills/aid-create-{architecture,stack,testing-strategy,cicd}/SKILL.md`: the CREATE
      state enumerates **exactly three** refusal conditions, and
      `grep -niE 'empty|populated|non-empty|hand-authored|line count'` over that state's text returns
      **nothing**. A gate keyed on the destination's size, emptiness or `hand-authored` status is the
      defect this row exists to catch -- it is how the withdrawn file-level refusal re-enters
- [ ] `source: generated` is still present as the **third** refusal condition in all four bodies, so
      V27 is not satisfied by deleting a refusal the spec mandates
- [ ] **Every row runs against the fixture the § Scope list assigns it, and every mutating row gets a
      fresh `cp -a` copy** -- no row inherits a directory another row's run has already mutated. Each
      fixture satisfies its stated invariants at the moment its row begins; a row that has to repair
      its own precondition fails this criterion
- [ ] F-pop is a git work tree (`git init` plus a baseline commit) **before** any row runs, so an empty
      `git status --porcelain` inside any copy is a real result rather than an exit-128 misread
- [ ] **The three refusals are recorded as non-realizing**, each with the evidence that it allocated
      no `work-NNN` folder inside its scratch project. V6, V7 and V18's two invocations fail their own
      rows if they realize; this criterion makes the counting consequence explicit
- [ ] Each **authored run** has its allocated work folder and the confirmed absence of a `phase:`
      value recorded into this task's STATE.md notes **before** its scratch project is torn down. The
      obligation is scoped to authored runs, because a non-realizing invocation allocates no work
      folder and requiring a record from one would be unsatisfiable
- [ ] **This task mutates no shared tree:** `git status --porcelain` over `.aid/knowledge/`,
      `.aid/design/`, `.aid/settings.yml`, `.aid/works/`, `profiles/`, `.claude/` and `.cursor/` is
      **identical before and after** the task, and nothing is committed in this repository --
      `git diff --cached --name-only` is empty, with no `git add -A` / `git add .` / `git add -u` /
      `git commit -a` used while task-039's render is live
- [ ] Tests are deterministic and setup/teardown is clean: F-pop and every per-row copy live under
      `mktemp -d` and are removed on exit **including on failure**; two executions over the same
      inputs produce identical outcomes. **Three authored runs** -- V26's two plus the CC-3 consumer
      run -- **and four non-realizing invocations**; a fourth authored run means a row built its own
      project instead of copying the fixture assigned to it, and a fifth non-realizing invocation
      means a row was run that this task does not own
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
