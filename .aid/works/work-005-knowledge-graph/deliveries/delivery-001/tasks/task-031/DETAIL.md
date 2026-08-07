# task-031: Emit AC-6's runtime prerequisites into the run's console summary

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-031/STATE.md.
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

**Source:** feature-007-graph-view-shell -> delivery-001 (Wave 3)

> **WHY THIS TASK EXISTS, AND IT IS NOT A SCOPE ADDITION.** feature-007's SPEC assigns this
> deliverable to feature-007 twice, in the same words both times. `:1604`-`:1608`: "**Runtime
> prerequisites must be written down (AC-6).** The generator emits, into the page footer *and* the
> run's console summary: whether a network is required, which companion files must travel with the
> entry point, whether a build output is involved, and -- new in the redesign -- that a **working
> WebGL context** is required for the live graph, with the statement that the table view remains fully
> usable without one." And `:1817` (GV23): "the generated `graph.html` footer **and** the run's console
> summary **each** state the runtime prerequisites ... | **AC-6**".
>
> **Only the footer half was ever built.** `canonical/aid/scripts/graph/render-graph-view.sh` emits
> **no output at all on a successful run** -- its only `echo` statements are the unknown-argument path
> (`:49`-`:50`) and the node-missing path (`:57`), both on stderr, both failure paths. Verified on
> disk.
>
> **The Detail phase never turned the console half into a task.** A sweep of all 30 task DETAILs finds
> **zero** occurrences of `GV23`, and "runtime prerequisite" appears in only two files: `task-011`
> (type DOCUMENT -- it re-issues feature-002's decision record, it emits nothing) and `task-017`, whose
> criteria *explicitly exclude* prerequisite and ceiling messaging. feature-007's IMPLEMENT task is
> `task-013`, which built `render-graph-view.sh` and is already `Done`. `task-023` was the other
> candidate -- `:1604` sits inside feature-007's "Packaging and the entry point (FR-16, AC-6, ...)"
> section -- but `task-023` is sourced from **feature-012**, and its DETAIL contains no occurrence of
> `console`, `prerequisite`, `summary`, `footer`, `WebGL` or `network`. So the obligation is owned by
> no task.
>
> **This is the fifth ownerless obligation found in this work, and all five were found by an executor
> DOING the work, never by a reviewer READING it.** The other four: feature-013's D3 roster slots,
> `read-setting.sh --probe` (which became `task-030`), `state-emit.md`'s ordering, and `task-013`'s two
> new files. This one was surfaced by `task-014`'s executor, which wrote `GV23b` as a real assertion
> and **left it failing** rather than muting it -- the correct call, and the reason this is visible at
> all. Recorded as tech-debt **W5-10**, whose *implementation* half this task closes; `GV23b` is
> already its oracle.
>
> Created 2026-08-06 during wave-3 execution. **The owner was asleep when this was created**, under a
> standing instruction to run the remaining tasks overnight. It follows the precedent the owner set by
> approving `task-030` for the identical situation, but it is an orchestrator decision made in the
> owner's absence and is flagged as such rather than presented as routine.

**Depends on:** task-013

**Scope:**
- Make `canonical/aid/scripts/graph/render-graph-view.sh` print a **console summary on the success
  path**, carrying the four prerequisite facts `:1604`-`:1608` names and `:1817` re-states: the
  **network requirement**, the **companion files** that must travel with the entry point, whether a
  **build output** is involved, and a **working WebGL context** named explicitly, with the sentence
  that the **table view remains fully usable without one**.
- **The footer is PARTLY complete, and here is exactly which facts it has -- do not re-derive this,
  but do not trust my earlier version of it either.** I first recorded that the footer was complete.
  **That was wrong**, and the correction matters to your scope:
    - **WebGL context + "the relationship table remains fully usable"** -- PRESENT and unconditional,
      `graph-skeleton.html`:229-231. Both halves of that fact are there. (A grep for
      `"remains fully usable"` returns nothing because the phrase wraps a line break -- match across
      whitespace or you will conclude it is missing, as I did.)
    - **JavaScript required** -- present, `:232`-`:234`. Not one of AC-6's four, but do not delete it.
    - **Network requirement** and **companion files** -- these two are **MUTUALLY EXCLUSIVE**, and this
      is the real defect. `build-graph-src.mjs`:192-194 computes `{{PREREQUISITES}}` as a **ternary**:
      a non-empty `graph-assets/` beside `relationships.md` yields the companion-files sentence,
      otherwise the network sentence. **The page can never state both.** So whichever branch fires,
      one of AC-6's four facts is absent from the footer -- and `:1817` says *each* carrier states the
      prerequisites, plural. Today AID's own KB takes the else-branch, which is why the network
      sentence is visible and the gap is invisible.
    - **Build output** -- the literal phrase is absent; the nearest text is "built at load time"
      (`:232`-`:234`) and a generator stamp. **Decide whether that discharges "whether a build output
      is involved" or whether a distinct sentence is owed**, and record the ruling either way. Do not
      leave it implicit.
  **So the footer needs work too, not just the console.** Fix the ternary so both facts can coexist
  (they are not alternatives -- a page can require companion files *and* no network, which is in fact
  exactly what the vendored packaging shape means per the decision record's Part 13). Found by
  `task-014`'s executor while widening `GV23a`; the `graph-assets` branch has never been exercised by
  any test.
- **The two carriers must not drift.** The four facts are one set of strings with two destinations.
  Author them **once** and have both carriers read that single source, so a future edit to one cannot
  silently diverge from the other. A copy-paste pair that happens to match today is not acceptable
  here; divergence is the predictable failure and it is cheap to design out.
- Decide and record **which** script is "the generator" for this purpose --
  `render-graph-view.sh` (the driver) or `build-graph-src.mjs` (the assembler) -- and put the summary
  where a normal run actually reaches it. `render-graph-view.sh` is the documented entry point, so it
  is the expected home; if `build-graph-src.mjs` turns out to be the right owner, say why.
- **`canonical/` only.** The render to `profiles/` and both dogfood trees belongs to `task-024`, as it
  does for `task-006`, `task-013` and `task-030`. Do not run the profile generator.

**Out of scope, explicitly:**
- **The WebGL sentence's *content* is not decided here.** `:1608`-`:1609` is explicit: "The content of the
  WebGL sentence depends on feature-002's Stage-1 verdict; its presence does not." Read the verdict
  from `task-011`'s re-issued decision record; do not re-derive it, and do not re-open it.
- **No performance figure, no node-count ceiling and no ceiling warning.** Those are `task-010`'s
  measurement and `task-021`'s warning. A prerequisite statement is not a capacity statement, and
  conflating them would duplicate `task-021`.
- **`GV23b` is not to be edited, weakened, or re-scoped.** It is the oracle for this task and it
  currently fails for a true reason. Making it pass by changing the assertion instead of the subject
  is the exact defect this task exists to repair. If you believe the assertion is wrong, raise an
  IMPEDIMENT -- do not amend it.
- Tech-debt **W5-9** (jsdom unresolvable, so 11 `TV` verdicts skip in CI as well as locally) is a
  different defect and is not fixed here.

**Acceptance Criteria:**
- [ ] A successful `render-graph-view.sh` run prints a console summary naming **all four** facts:
      network requirement, companion files, build output, and a working WebGL context
- [ ] The summary states, in words, that **the table view remains fully usable without a WebGL
      context**. This sentence is load-bearing rather than decorative: `task-010` measured the canvas
      failing NFR-7 by ~2.8x at the median against a 1,609-node bench with NFR-8's ceiling at
      (500,550], and `graph-controls.js:883` mounts the table **first and unconditionally** -- so on
      this project's own Knowledge Base the table is the rendering that actually works, and a reader
      who cannot get WebGL must be told plainly that they have lost nothing essential
- [ ] `GV23b` in `tests/canonical/test-graph-view-shell.sh` **passes, unmodified.** Show the assertion
      is unchanged (`git diff` on that file confirms no edit to `GV23b`) and that the suite's failure
      count drops by exactly one, with no other verdict changing state
- [ ] **The absence of the summary would FAIL a test.** Prove `GV23b` bites: revert the change in a
      scratch copy, run against it, and show that assertion -- and only it -- goes red. A passing
      assertion that would also pass without the feature is vacuity class 1, and four distinct
      vacuity classes have already been found in this work
- [ ] The four facts have **exactly one authoring site** shared by footer and console. Demonstrate it:
      change one fact at that single site and show both carriers move together
- [ ] The **footer** also carries all four facts. If it did not before, it does now, and `GV23a`
      still passes
- [ ] Failure paths are unchanged: the unknown-argument (`:49`-`:50`) and node-missing (`:57`) routes
      keep their current text, stream and exit codes, byte-for-byte
- [ ] Nothing is written to stdout that a caller parses as data. Confirm no caller of
      `render-graph-view.sh` consumes its stdout as a value; if one does, the summary goes to stderr
      instead and that choice is recorded with the call site that forced it
- [ ] `profiles/`, `.claude/` and `.cursor/` are untouched; the byte-identity gate for
      `render-graph-view.sh` is expected red until `task-024`, exactly as for `task-006` and
      `task-013`
- [ ] S1 budget updated in the header of any suite this task adds invocations to. Derive it by
      grepping **call-site multiplicity for every wrapper**, not by counting direct calls -- an S1
      figure in this work was once declared "24 in-process + 2 spawns" when the truth was 75 + 3,
      because wrapper bodies were counted once instead of once per call site
- [ ] **All existing tests still pass** (IMPLEMENT type-default, `task-decomposition.md`:175). Named
      explicitly because `render-graph-view.sh` is the view's entry point and is invoked by suites
      beyond the `test-graph-*` set. Use `tests/canonical/select-suites.sh --run` to pick the affected
      suites by change set -- but note it fail-safe-selects ~140 of 147 suites, which will not finish
      locally, so map the changed files to their covering suites by `# COVERS:` and run those
- [ ] All section-6 quality gates pass
