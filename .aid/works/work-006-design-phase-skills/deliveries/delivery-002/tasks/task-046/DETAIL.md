# task-046: FR-8's asking with no stored state, and a lane divergence that survives an `update`

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-046/STATE.md.
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
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §11 rows **V16** (AC-9's
  four parts) and **V23** (AC-12(b)), with §3d/FR-8 and §9 as the rules under test. Both rows need an
  `update` run and neither is satisfiable from a working-tree listing alone, which is why they are cut
  as a task rather than folded into task-040..task-043.
- **Every run happens in a scratch project under `mktemp -d`, never against this repository's own
  `.aid/`.** V16(c) greps the project's `.aid/settings.yml` and its work `STATE.md` for a stored
  answer, and V23 runs `/aid-housekeep`, whose KB-DELTA sweep over a real repository would be a large
  mutation for a verification row. This task therefore writes no path under `.aid/knowledge/`,
  `.aid/design/`, `.aid/settings.yml` or `.aid/works/` in the working tree, which is what makes it
  schedulable beside task-044, task-045 and task-047. It **renders nothing and reverts nothing**.
- **Fixture policy -- two baselines, a fresh copy per mutating row**, each created under `mktemp -d`
  and `git init`-ed with a baseline commit, because the `git diff` and `git status --porcelain`
  assertions return a real result only inside a work tree; each carries this repository's rendered
  dogfood `.claude/` copied in, so the skills are invocable from that directory.
  - **F-ask** -- a project with a **populated** `.aid/knowledge/architecture.md`
    (`source: hand-authored`) declared in `.aid/settings.yml` `knowledge.doc_set`, no
    `.aid/design/`, and a `.aid/knowledge/README.md`. V16 runs here: the same
    `/aid-update-architecture` twice, with the user naming a change each time.
  - **F-flagged** -- a project with a `.aid/knowledge/architecture.md` carrying
    `source: forward-authored`, and a **Conformance-Lane divergence already recorded** as a KB Q&A
    entry in `.aid/knowledge/STATE.md`, in the shape
    `canonical/skills/aid-housekeep/references/state-kb-delta.md` § *Sub-step 2b* prescribes, with the
    divergence deferred (`[3] Accept / defer` -- *"records the divergence as a known delta for later
    reconciliation"*, `:525`) and the doc consequently **byte-unchanged**. V23 runs here.
- **The flag is established by a fixture edit, and the reason is the same one task-040 gives for its
  step-4 seed.** What a real code -> design divergence detection produces is not under the executor's
  control, so a precondition defined as *"the housekeep run happens to flag item X"* would be
  unreachable. The lane's own mechanism makes the fixture faithful rather than a stand-in: the lane
  **flags and does not reconcile**, so *"every forward-authored doc is byte-unchanged"* until the
  entry is actioned (`state-kb-delta.md:564`), and the recorded entry **is** the flag. This is a
  fixture built before the row starts, not a row repairing its own precondition.
- **Three authored `update` runs and one `/aid-housekeep` run, and no more**: two
  `/aid-update-architecture` runs in one copy of F-ask (V16(b)), then one
  `/aid-update-architecture` run in a copy of F-flagged followed by one `/aid-housekeep` re-run
  (V23). Each `update` allocates a `work-NNN` folder **inside its scratch project** and executes
  feature-002 §3e's full-verify loop.
- **V16's static part (a) is re-read here as part of the row**, over the four `update` bodies
  task-038 authored, because AC-9 is only closed when all four parts hold together. task-038 asserted
  its own share at authoring time; this is the row read whole.
- Out of scope: the brownfield realization sequence and the `update` seed contract (task-040 through
  task-043); the three refusals and the repeat `create` (task-044); the absent-destination creation
  path (task-045); the engine additivity comparison (task-047); resolving the flagged divergence,
  which is human by the lane's design and is exactly what the row asserts does **not** happen;
  authoring any test script under `tests/` or adding any bash assertion id (feature-001 AC-3); and
  the `coverage-parity` re-bootstrap.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** (TEST default: all acceptance criteria from the source feature covered)
- [ ] **feature-004 V16(a) / AC-9(a) -- static, over all four `update` bodies.** In each of
      `canonical/skills/aid-update-{architecture,stack,testing-strategy,cicd}/SKILL.md`,
      `grep -n 'derived outputs'` returns a hit inside the UPDATE state and that hit is **not** inside
      an `if`/`when` clause -- it is an unconditional step
- [ ] **feature-004 V16(b) / AC-9(b) -- behavioral**, in one copy of F-ask: run
      `/aid-update-architecture` twice. **Run 2 asks the derived-outputs question again.** An
      `update` that never asks fails (a) and (b); one that asks once and remembers fails (b) and (c).
      The transcript of both runs is recorded, since "asked again" is a reading of the run rather than
      of a file
- [ ] **feature-004 V16(c) / AC-9(c) -- no stored answer**, in that same copy after run 2:
      `grep -rniE 'derived[-_]outputs|output_list|outputs:' .aid/settings.yml .aid/works/<work>/STATE.md`
      returns **nothing**, and the skill wrote no other state file -- `git status --porcelain` inside
      the scratch project lists only the destination document and the work folder
- [ ] **feature-004 V16(d) / AC-9(d) -- no tracking metadata**:
      `grep -rniE 'derived-from|source-doc|generated-by|aid-tracked'` over **every file the two runs
      wrote** returns **nothing**. The file list is derived from the run's own
      `git status --porcelain`, not from a remembered list
- [ ] **feature-004 V23 / AC-12(b) -- the flagged divergence survives**, in a copy of F-flagged: after
      `/aid-update-architecture` changes only what the user named, (i) the Conformance-Lane Q&A entry
      in `.aid/knowledge/STATE.md` is **byte-identical**, (ii) the destination's diff touches **only**
      what the user named -- every other region byte-identical -- and (iii) after the `/aid-housekeep`
      re-run the entry is **still present**. An `update` that silently "fixes" the divergence defeats
      the lane and fails this criterion
- [ ] The `update` run in F-flagged leaves the destination's `source:` line **unchanged** at
      `forward-authored`, and `approved_at_commit:` unwritten and unrestamped
- [ ] **Every row runs against the fixture the § Scope list assigns it, and every mutating row gets a
      fresh `cp -a` copy** -- V16's two runs share one copy **by design**, because "run 2 asks again"
      is only meaningful in a project run 1 already touched; V23 gets its own. A row that repairs its
      own precondition once it has started fails this criterion
- [ ] Each baseline is a git work tree (`git init` plus a baseline commit) **before** any row runs, so
      an empty `git status --porcelain` inside any copy is a real result rather than an exit-128
      misread
- [ ] Each authored run's allocated work folder and the confirmed absence of a `phase:` value
      (`grep -c '^phase: .'` over that run's work `STATE.md` captured to a variable -> `0`) are
      recorded into this task's STATE.md notes **before** the scratch project is torn down
- [ ] **This task mutates no shared tree:** `git status --porcelain` over `.aid/knowledge/`,
      `.aid/design/`, `.aid/settings.yml`, `.aid/works/`, `profiles/`, `.claude/` and `.cursor/` is
      **identical before and after** the task, and `git diff --cached --name-only` is empty in this
      repository, with no `git add -A` / `git add .` / `git add -u` / `git commit -a` used while
      task-039's render is live
- [ ] Tests are deterministic and setup/teardown is clean: both baselines and every per-row copy live
      under `mktemp -d` and are removed on exit **including on failure**; **three** authored `update`
      runs and **one** `/aid-housekeep` run, and no more; two executions over the same inputs produce
      identical outcomes
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
