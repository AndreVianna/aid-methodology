# task-016: Behavioral verification of the `design` and `create` stages, and the deferred acquisition oracles

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-016/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-021

**Scope:**
- Source specs: `features/feature-003-planning-artifact-skills/SPEC.md` §8's `design`- and
  `create`-stage behavioral rows, and `features/feature-002-design-lifecycle-machinery/SPEC.md`
  §7's acquisition rows. **Scoped to the two stages whose skills its ancestors author**:
  every row below is exercised with `design` and `create` skills only (task-010 through
  task-013). Rows needing an `update` skill are task-022's and task-023's, which depend on
  task-014 -- that edge is what keeps the graph, rather than the task numbering, the
  authority on ordering.
- **Execution path** (BLUEPRINT § Notes): task-024 has already produced the throwaway local
  render, so the skills are invocable. This task **renders nothing and reverts nothing** --
  it reads that tree, and task-025 reverts it once every consumer is done.
- **Every run in this task happens in a scratch project under `mktemp -d`, never against
  this repository's own `.aid/`.** That is what keeps the task free of shared mutable state:
  it writes no path under `.aid/knowledge/`, `.aid/design/` or `.aid/settings.yml` in the
  working tree, so it can be scheduled beside any task that does.
- **Fixture policy -- one baseline, two snapshots, and a fresh copy per mutating row.** The
  expensive unit here is an authored skill run: each allocates a `work-NNN` folder and executes
  feature-002 §3e's full-verify loop. A `cp -a` is not. So the policy separates the two: **runs
  are shared, directories are not.** No row builds a project from zero, and no row inherits a
  project another row's run has already mutated -- which is the failure an earlier draft had,
  where the rows' own runs destroyed the invariants the fixtures were defined by.
  - **F-base** -- the pristine baseline: created under `mktemp -d`, then `git init`-ed with a
    baseline commit, and carrying no `.aid/design/` and no KB planning documents. Everything
    else is a copy of it or of a snapshot of it. The `git init` premise is stated because the
    `git status --porcelain` assertions below return empty only inside a work tree -- outside
    one `git status` exits 128, which is not "empty" and would be misread as a pass. The
    sibling task-022 states the same premise for its own case.
  - **The run sequence** -- in one working copy `W` of F-base, the three `design`-stage runs
    execute in order: `/aid-design-roadmap`, `/aid-design-mvp`, `/aid-design-backlog`.
  - **F-seeded** -- a `cp -a` snapshot of `W` taken **immediately after run 1**, so it holds
    exactly one seed, `.aid/design/roadmap.md`, **whose `## Open questions` section is
    non-empty** under feature-002 §4's detection rule. That clause belongs to the fixture
    rather than to a row, because V6's whole subject is `create` refusing against exactly that
    state.
  - **F-designed** -- a `cp -a` snapshot of `W` taken **after run 3**: all three seeds present,
    `.aid/design/README.md` present, and still no KB planning document. Its **`mvp` seed's
    `## Open questions` is empty** -- only the roadmap seed carries an open question -- so when
    V16 runs `/aid-create-mvp` there, the sole reason to route is the absent `roadmap.md`, and
    the row tests routing rather than the readiness gate.
  - **Both `## Open questions` states are established by editing the snapshot, not by hoping
    the run produced them.** What an authored `/aid-design-*` run writes into that section is
    not under the executor's control, so a fixture defined as *"the run happens to leave it
    non-empty"* would be a precondition with no way to reach it. After each snapshot is taken,
    the executor **writes one open question into F-seeded's roadmap seed** and **clears
    F-designed's mvp seed's `## Open questions`**, if the runs did not already leave them that
    way. This is a fixture edit -- the same device task-022 uses to establish F-no-MVP and
    F-horizons-empty -- and it is explicitly **not** the row-level repair the criteria below
    forbid: fixtures are built before a row starts, and a row may not repair its own
    precondition once it has. Determinism is preserved because the edit is part of the input,
    not a reaction to the output.

  | Row | Fixture it runs against | Invocations it adds | Realizing? |
  |---|---|---|---|
  | V4 | `W` itself | the three `design` runs -- asserted after each | **authored runs** (3) |
  | B3 | `W`, at run 1 | none; run 1 is the first run in a project with no `.aid/design/` | -- |
  | V6 | a **fresh** `cp -a` copy of **F-seeded** | one `/aid-create-roadmap` (the verb matching that seed), which **refuses** | **non-realizing** |
  | V16 (= E1) | a **fresh** `cp -a` copy of **F-designed** | one `/aid-create-mvp`, which **routes** | **non-realizing** |

  **Total authored runs: three**, plus **two non-realizing invocations**. The two words carry
  the delivery's two senses: an **authored run** *realizes* -- it writes its destination,
  consumes its seed, and executes feature-002 §3e's full-verify loop -- while a
  **non-realizing invocation** (a readiness refusal or a routing exit) writes nothing to the
  destination, leaves the seed in place for the skill it routes to, and runs no verify loop.
  V6 and V16 are refusal and routing **by construction** -- that is what each row tests -- so
  neither is counted in the run total.

  **Allocation is not part of that distinction, and a non-realizing invocation still
  allocates.** Allocation is unconditional skill shape: `design-lifecycle.md § Skill shape --
  Allocation` and its binding table (`Allocation via the Work Initiation Gate | Binds | Binds
  | Binds`) bind all 36 skills without a refusal or routing carve-out, feature-002 §3e records
  REQUIREMENTS FR-3 as the tiebreaker that settled it, and both `create` skills allocate at
  **INTAKE step 2** -- before the GUARD that refuses and the REALIZE that routes. What the
  contract *does* scope to the realizing path is seed deletion ("a routing exit leaves it for
  the skill it routes to"), which is why the seed's survival, not a folder's absence, is the
  evidence these two rows turn on. An earlier revision of this task asserted that a
  non-realizing invocation "allocates nothing" and made an absent `work-NNN` folder the
  acceptance evidence; that premise was false against both the contract and the shipped
  skills, no correct implementation could satisfy it, and it was corrected here (and in
  task-023, which used the same words) rather than by changing shipped allocation behaviour.
  Copies are not runs either, which is what keeps this task inside one agent session while
  still giving every mutating row an unmutated precondition.
- **feature-003 rows to run**: V4 in `W` (each of the three `design` skills leaves
  `git status --porcelain .aid/knowledge/` empty), V6 in a fresh copy of **F-seeded** (the
  readiness gate -- `create` against a seed whose `## Open questions` is non-empty by
  feature-002 §4's detection rule refuses without an override, the destination is
  byte-identical afterwards, the seed is still present, and the transcript names the
  unresolved question(s) **and** the override), and V16 in a fresh copy of **F-designed**
  (`/aid-create-mvp` with no `roadmap.md` routes to `/aid-create-roadmap`, naming it;
  `roadmap.md` still absent; `.aid/design/mvp.md` still present -- which F-designed supplies,
  since run 2 of the sequence wrote it).
- **Record, for each of the five invocations, the allocated work folder and the confirmed
  absence of a `phase:` value in its `STATE.md`, into this task's STATE.md notes -- before the
  scratch project is torn down.** All five allocate, including V6's refusal and V16's routing
  exit, because allocation precedes both exits (see the allocation paragraph above); the
  acceptance criterion below is scoped the same way. V23 is a nine-skill sweep aggregated in task-023, and the evidence
  lives inside scratch projects this task's own teardown destroys; capturing it is therefore
  this task's obligation, not the aggregator's.
- **feature-002 rows to run**: B2 **part (b)** -- for each of the five rendered contracts
  **under its own profile**, at
  `profiles/{claude-code/.claude, codex/.codex, cursor/.cursor, copilot-cli/.github,
  antigravity/.agent}/aid/templates/design-lifecycle.md`, the file names
  `R/aid/templates/design-folder-readme.md` for that profile's own root `R` and carries no
  occurrence of `canonical/aid/templates/design-folder-readme.md`. The profile path prefix is
  load-bearing: three of the five bare root names do not exist at the repository root and a
  fourth is the GitHub config directory there. (Part (a), the five rendered copies of each
  template, is a completeness property of the render itself and is asserted by task-024; part
  (b) is the one that fails if the acquisition rule was written in a form
  `rewrite_install_paths` cannot rewrite, and part (a) alone would pass on a dangling
  reference.) Also B3 (**run 1 of the sequence, in `W`** -- a project that has no
  `.aid/design/` before it -- creates `.aid/design/` and writes its `README.md` from the
  installed template. It authors no run of its own, and the snapshot taken immediately after
  it is F-seeded); and E1, which is the same case as V16 and is recorded as
  satisfied by that run rather than run twice.
- **Named with their evaluator, so nothing is silently dropped**: V5 is discharged in
  task-015 and task-021 (seed present before `create`, absent after); **V18 and V20 are
  task-020's**, because both grep this repository's own `tech-debt.md`, `backlog.md` and
  `roadmap.md` and must therefore read the KB in its **final** state -- after task-018's
  migration writes into `backlog.md` -- rather than race a concurrent writer; V7 and V8
  (= feature-002 E3) are task-022's, because both need `/aid-update-*`; V17, V21, V22, V23,
  V24 and V27 are task-023's for the same reason; feature-002 E2 is feature-004's, in
  delivery-002; V26 and V28 are feature-006's, in delivery-003; feature-002 G1 is
  delivery-002's and H1 is delivery-003's (task-005 records both).
- Out of scope: authoring any new test script under `tests/` or adding any bash assertion id
  -- the ground is **feature-001 AC-3** alone, which requires the suite scripts to stay
  untouched. Not the `coverage-parity` re-bootstrap: this delivery already mints roughly 36
  new assertion ids without a script edit (four per catalog row at
  `tests/canonical/test-catalog-dirs-parity.sh:126-141`, times the nine rows tasks 010-014
  add), so that re-bootstrap is already scheduled in delivery-003 regardless (PLAN
  § Cross-Cutting Risks, risk 1).

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that
      produced it** -- no row is reported as covered without its oracle and result (TEST
      default: all acceptance criteria from the source feature covered)
- [ ] V4, stated as feature-003 §8 states it and no wider: after each of
      `/aid-design-roadmap`, `/aid-design-mvp` and `/aid-design-backlog`,
      `git status --porcelain .aid/knowledge/` is **empty**. The oracle is scoped to
      `.aid/knowledge/` alone; it makes **no** claim that the seed is the only new file,
      because feature-002 §2d binds every `design`-stage skill to create `.aid/design/` and
      write its `README.md` on first use -- so run 1 in `W` correctly leaves **two** new
      files, and B3 below asserts the second one. A "only the seed" conjunct would make a
      correct implementation fail
- [ ] V6 runs against a **fresh copy of F-seeded**, whose definition already guarantees the
      non-empty `## Open questions` the row tests; a refusal that writes nothing but names
      **neither** the unresolved questions **nor** the override fails this criterion, per
      feature-003 AC-10 -- writing nothing is not sufficient
- [ ] **Every row runs against the fixture the § Scope table assigns it, and every mutating
      row gets a fresh `cp -a` copy** -- no row inherits a directory another row's run has
      already mutated. `W`, F-seeded and F-designed each satisfy their stated invariants at
      the moment the row that names them begins; a row that has to repair its own precondition
      fails this criterion
- [ ] F-base is a git work tree (`git init` plus a baseline commit) **before** run 1, so every
      copy taken from it inherits the `.git` directory and an empty `git status --porcelain`
      inside any of them is a real result rather than an exit-128 misread
- [ ] V16 (= feature-002 E1), run against a **fresh copy of F-designed**: the run names
      `/aid-create-roadmap`, leaves `roadmap.md` absent, and leaves `.aid/design/mvp.md` in
      place. It neither stops silently nor scaffolds a document it does not own (CC-5). That
      the routing -- not the readiness gate -- is what fired is checkable because F-designed's
      `mvp` seed carries no open question
- [ ] B2(b), with the locative qualifier its SPEC oracle carries -- *"the rendered
      `design-lifecycle.md` **under that profile**"*. The five rendered contracts are
      `profiles/claude-code/.claude/`, `profiles/codex/.codex/`, `profiles/cursor/.cursor/`,
      `profiles/copilot-cli/.github/` and `profiles/antigravity/.agent/`, each plus
      `aid/templates/design-lifecycle.md`. For each, with `R` the profile's own root name,
      the file contains the literal `R/aid/templates/design-folder-readme.md` and **no**
      occurrence of `canonical/aid/templates/design-folder-readme.md`. The bare root names
      do not resolve at the repository root -- `.codex` and `.agent` do not exist there and
      `.github` is the GitHub config directory -- so the path prefix is load-bearing. Part
      (a) alone would pass on a dangling reference
- [ ] B3, asserted on **run 1 in `W`** -- a project with no `.aid/design/` before that run --
      which afterwards holds `.aid/design/README.md`, present and byte-identical to the
      installed template. It is asserted on a run V4 already authors, not on one of its own
- [ ] Every **invocation** here -- all five, the three authored runs and the two non-realizing
      ones alike -- has its allocated work folder and the confirmed absence of a `phase:` value
      recorded **before** its scratch project is torn down -- the V23 evidence task-023
      aggregates. A teardown that destroys the record before it is written fails this
      criterion. The obligation covers all five because allocation happens at INTAKE, ahead of
      both the GUARD refusal and the REALIZE routing exit, so a non-realizing invocation has a
      work folder to record like any other
- [ ] **V6 refuses and V16 routes -- and each is recorded as non-realizing**, with the
      evidence being what the contract scopes to the realizing path: the destination is
      unwritten (byte-identical, or still absent), the seed is still present, and no verify
      loop ran. The presence of an allocated `work-NNN` folder is **not** evidence either way
      and must not be asserted against -- see the allocation paragraph in § Scope. A V6 that
      realizes, or a V16 that writes `roadmap.md`, fails its own row anyway; this criterion
      makes the *counting* consequence explicit so the run total and task-023's tally cannot
      drift apart
- [ ] Tests are deterministic and setup/teardown is clean: F-base, `W`, both snapshots and
      every per-row copy live under `mktemp -d` and are removed on exit including on failure;
      two runs over one input produce identical outcomes. **The authored-run count is three**
      -- the three `design` runs -- **plus two non-realizing invocations**, and both figures
      are recorded; a fourth authored run means a row built its own project instead of copying
      the snapshot the § Scope table assigns it, and a third non-realizing invocation means a
      row was run that this task does not own
- [ ] **Both `## Open questions` fixture states are established before their rows begin**, by
      editing the snapshot if the `design` runs did not leave them that way: F-seeded's roadmap
      seed carries at least one open question, F-designed's mvp seed carries none. Verified by
      inspecting each seed at fixture-build time, not by inferring it from the row's outcome --
      a row that discovers its precondition is wrong and repairs it fails the criterion below
- [ ] This task mutates no shared tree: `git status --porcelain` over `.aid/knowledge/`,
      `.aid/design/`, `.aid/settings.yml`, `profiles/`, `.claude/` and `.cursor/` is
      **identical before and after** the task. It neither renders nor reverts -- task-024
      owns the render and task-025 the revert
- [ ] `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
