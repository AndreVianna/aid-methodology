# task-048: Local commit and safety proof that nothing was deployed or changed outside scope

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

**Source:** feature-006-workflow-and-safety -> delivery-004 -> AC-13

**Depends on:** task-047

**Scope:**
- Feature 006 § Feature Flow step 9: commit every remaining change locally on `work-005` (`git status --porcelain`
  empty afterwards). No push, no tag.
- Step 10, from the repo root, right after that commit and before anything else is written (this task's own
  `In Progress` state write precedes the commit, so it is inside it): run the six checks of the step-10 table, in
  order, and capture each command with its exact output and exit status:
  1. `git status --porcelain` -> no output;
  2. `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/|\.aid/knowledge/)'`
     -> no output;
  3. the unlisted-KB-file loop of step 10 -> no output;
  4. `git diff --name-only site-aid...HEAD -- '*.sh' '*.ps1' '*.psm1'` -> no output;
  5. `git tag --points-at HEAD` -> no output;
  6. `git rev-parse --abbrev-ref work-005@{upstream}` -> fails (no upstream), and
     `git ls-remote --heads origin work-005` -> no output.
- `git ls-remote` is read-only and the single network use this task may make, because AC-13 itself names it
  (PLAN.md delivery-004 Notes, item 3). If the network is unavailable, or the operator does not allow it, it is
  not run: record the two local checks of row 6 and the sentence `remote check not run: <reason>`.
- Step 11, only after step 10: append one entry to `lifecycle_history` in the work's `STATE.yml`
  (`.aid/works/work-005-site-rework/STATE.yml`, an AUTHORED key: `date`, `event: 'Safety proof (AC-13)'`,
  `grade: --`, `notes:` holding first the line `checked: <sha>`, the `<sha>` being the output of
  `git rev-parse HEAD` right after the step-9 commit, then the six commands with their observed output and exit
  status; task-049 reads that sha). This write is not
  part of the step-10 checks; it stays uncommitted for the work's closing commit (Feature 006 step 11).
- A failing check is not fixed here: the task ends `Failed`, naming the check and the owning task of the offending
  path (or the commit that added it).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no `release.sh`, no workflow
  run, no `gh` command; no network use other than `npm ci` / `npm install` run from `site/` and the one read-only
  `git ls-remote` above; no edit under `canonical/`; no edit to any file except the commit of what tasks 036-047
  left and the step-11 entry; no change to any path outside the delivery-004 AC-13 allowed set (`site/`,
  `.github/workflows/docs.yml`, `.aid/knowledge/` documents listed in the audit's FR-10 table,
  `.aid/works/work-005-site-rework/`).

**Acceptance Criteria:**

Run from the repo root.

- [ ] Committed: right after the step-9 commit, `git status --porcelain` prints nothing.
- [ ] Allowed paths only: check 2 prints nothing.
- [ ] Every changed KB file is in the audit: check 3 prints nothing.
- [ ] No shell or PowerShell file touched (NFR-5): check 4 prints nothing; `git diff --name-only site-aid...HEAD -- canonical profiles bin lib install.sh install.ps1`
  prints nothing.
- [ ] No tag: `git tag --points-at HEAD` prints nothing.
- [ ] Never pushed, never deployed: `git rev-parse --abbrev-ref work-005@{upstream}` exits non-zero; and
  `git ls-remote --heads origin work-005` prints nothing, or the record says `remote check not run: <reason>`.
- [ ] Outcome recorded (step 11): the work `STATE.yml`'s last `lifecycle_history` entry has
  `event: 'Safety proof (AC-13)'` and its `notes:` starts with `checked: <sha>` where `<sha>` equals
  `git rev-parse HEAD` (no commit after step 9 yet) and names all six checks with their output; after it,
  `git status --porcelain` lists only `.aid/works/work-005-site-rework/STATE.yml` (plus this task's own
  `STATE.yml` state writes).
- [ ] Deterministic, clean setup and teardown (TEST default): re-running checks 2-6 gives the same output; the task
  creates no file anywhere.
- [ ] All acceptance criteria from the source feature covered (TEST default): every row of the Feature 006 step-10
  table maps to one criterion above.
