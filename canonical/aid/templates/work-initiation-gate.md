# Work Initiation Gate

The single shared front-door every work-starting skill consults **before** it
allocates a new work folder. It makes the new-vs-continuation decision explicit,
worktree-aware, and implemented once, so no starter silently assumes either
branch. This is the Concern B counterpart to Concern A's `.aid/works/` container
(the enumeration target below).

Consulted by: `/aid-orchestrate` (its start-or-resume flow creates each new work
through § 3a), the direct-entry shortcut engine's INTAKE
(`.aid/runtime/templates/shortcut-engine.md`), `aid-describe`, and the
collapse/standalone starters `aid-review`, `aid-research`, `aid-design`,
`aid-report`, `aid-test`, `aid-prototype`, `aid-create-document`,
`aid-update-document`. Each references THIS file at its allocation step rather
than re-implementing the logic.

> **Where the gate sits.** It runs at the exact point a starter would otherwise
> allocate `work-NNN` (scan `.aid/works/`, pick the next number, create the
> folder). The gate either lets the starter proceed with that allocation (NEW)
> or steps aside and hands the chosen work to the skill its record names
> (CONTINUATION). It is a thin front-door: it never authors artifacts, and on
> continuation it allocates nothing.

---

## Step 1 -- Enumerate existing works (main tree + every git worktree)

Run the shared enumeration helper. It lists `.aid/works/*` across the main tree
**and every git worktree**, mirroring the dashboard reader's already-proven
cross-worktree routine (`dashboard/reader/locator.py` `enumerate_worktree_roots`
-> `dashboard/reader/derivation.py` `run_worktree_list`: fixed-argv, no-shell,
git-toplevel-guarded, 2s-bounded `git worktree list --porcelain`, degrading to
main-tree-only on any git failure):

```bash
bash .aid/runtime/scripts/works/enumerate-works.sh
```

(Add `--root <repo-root>` only if the starter is not already running from the
project root.) The helper emits one TAB-separated record per work:

```
<work_id>\t<phase>\t<lifecycle>\t<branch_label>\t<title>
```

- **Empty stdout** = no works exist anywhere across any root.
- **Degradation is silent to the caller:** git absent / non-git dir / timeout
  makes the helper enumerate the main tree only and still exit 0 -- never fail
  the starter (the same degrade contract the reader guarantees).
- **De-duplicate for display.** The helper is the enumerate layer only, so a
  work that was committed (and is therefore checked out in more than one
  worktree) appears once per branch label. When you present the list, group by
  `work_id`: show each work once, noting the worktree(s)/branch(es) it lives on.

## Step 2 -- Branch on empty vs non-empty

- **Empty (no works across any root) -> NEW, no prompt.** Do not ask anything.
  Continue with Step 3a. This is the common first-work case.
- **One or more works exist -> ASK.** Present the enumerated list and ask a
  single question under the question protocol (`.aid/runtime/templates/question-protocol.md`;
  one topic at a time, never silently assume either branch):

  ```text
  Works -- question 1 of 1 -- importance: high
  Is this a NEW work, or a CONTINUATION of an existing one?
  Why I ask: an existing work may already hold this request, and a new work would duplicate it.
  My recommendation: NEW, unless the request names one of these works.

  Existing works:
    work-016-numberless-work-folder   [Specification · Paused-Awaiting-Input]   (worktree: work-016)
    work-017-orders-read-api          [Building · Running]                      (main)
    work-018-billing-report           [Planning · Running]                      (main)

    1. New work (recommended)
    2. Continue work-016-numberless-work-folder
    3. Continue work-017-orders-read-api
    4. Continue work-018-billing-report
  Or answer in your own words, ask me to explain, or skip this question.
  ```

  Compose the bracketed `[phase · lifecycle]` and `(worktree: <label>)` from the
  helper's record columns. Wait for the answer before doing anything else. A
  skipped question creates no work and leaves every existing one as it is.

## Step 3 -- Act on the answer

### 3a. NEW -> create the record, then hand back to the starter

The gate performs the steps below in this order, and only then hands the new work back to the starter:

1. **Resolve `<work-id>`** as `work-{NNN+1}`, where `NNN` is the **maximum
   `work-NNN` numeric prefix across every record Step 1's `enumerate-works.sh`
   already returned** (cross-worktree by construction -- the helper parses `git
   worktree list --porcelain` across every worktree). Each record's column 1 is
   the full folder id (e.g. `work-016-numberless-work-folder`); parse its leading
   `work-([0-9]+)` and take the maximum; `work-001` if Step 1 returned no records
   at all. **Never** re-scan a local `.aid/works/` glob for this number: the
   worktree the starter is about to create is freshly branched off `master`,
   which tracks no `.aid/works/` at all (verified: `master`'s `.aid/` holds no
   `works/` -- every existing work lives in a worktree), so a fresh local glob
   inside it would find nothing and re-allocate a colliding `work-001`. The starter derives its own kebab-case `<name>` slug exactly as it
   does today (from the description, or `{verb}-{artifact}`, or an asked name).

2. **Create and enter the worktree, BEFORE authoring anything:**

   ```bash
   bash .aid/runtime/scripts/works/worktree-lifecycle.sh create <work-id> <name>
   ```

   Idempotent (a no-op re-print if the worktree already exists, keyed on the
   `<work-id>` branch); prints the worktree's **absolute path** to stdout on
   success/no-op; exits 0 on success/no-op, non-zero with **empty stdout** on
   failure. **Create-failure guard (fail-closed -- the real NFR1 protection for
   this branch):** if the exit code is non-zero **or** the printed path is
   empty, surface the error and **STOP** -- do **not** fall through to allocate
   the new work on the current (possibly `master`) tree. On success, **enter**
   the resolved path per `.aid/runtime/templates/worktree-lifecycle.md § Step
   2`: the executing agent invokes the host-native `EnterWorktree` tool where
   available, else treats the resolved path as the working directory for all
   subsequent file operations and surfaces it to the user (`Working in
   worktree: <path>` -- FR4 fallback).

3. **Read the work's type** with `/aid-orchestrate`'s `references/check-intent.md`, from the user's words. The calling skill's own kind is only a hint (FR-4).

4. **Create the folder, then scaffold `STATE.yml` through the writer**, inside the entered worktree. Create `.aid/works/<work-id>-<name>/` (reusing the `<work-id>` from step 1 -- do **not** re-derive it from the fresh worktree's own, still-empty `.aid/works/`), then make the work record in one locked write:

   ```bash
   bash .aid/runtime/scripts/execute/writeback-state.sh --create \
     --work-dir .aid/works/<work-id>-<name> \
     --reading <type from step 3> --request '<the user's words>' \
     --skill <calling skill> --step <its first step> \
     [--phase <phase>] [--depth lite|full] [--path lite|full] [--minimum-grade <grade>]
   ```

   `--create` copies `work-state-template.yml` and fills the record in that one write: `intent.reading`, `intent.request`, `active_skill`, `step`, `pipeline.initiator` (the calling skill), `lifecycle: Running`, `started` and `updated`. It exits 8 when the folder already holds a `STATE.yml`. A skill started by a bare slash command with no words takes its request from its first question (`.aid/runtime/templates/question-protocol.md`); if the user does not answer, no work is created.

   A non-zero exit stops the gate at once: tell the user in one plain line what failed, and that nothing more runs until it is fixed.

5. **Hand back** to the starter with this one line: "`STATE.yml` was created by the gate; skip any instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand; set other keys through the writer." The starter then adds only its own keys, through the writer.

The gate changed nothing about the allocation mechanics; it only gated the decision to allocate, and now also gates *where* that allocation lands and who writes the work record.

### 3b. CONTINUATION -> the work's record decides where it resumes

The gate allocates **nothing**. The work's record -- `intent.reading`, `active_skill`, `step` and `step_detail` in its `STATE.yml` -- is the only thing that decides where the work resumes. The gate reads that record; it never reads a phase name to decide.

1. **Normalize** the chosen work's id to its **bare** `work-NNN` branch name first: `[[ "$chosen_work" =~ ^(work-[0-9]+) ]] && work_id="${BASH_REMATCH[1]}"`. Step 1's enumeration supplies the **full folder slug** (e.g. `work-016-numberless-work-folder`), but `worktree-lifecycle.sh locate` keys on the **bare `work-NNN` branch name** -- passing the full slug would match no branch, drop the resolution ladder to its rung-3 fallback, and fabricate a wrongly-named duplicate worktree. Idempotent if the id is already bare.

2. **Locate** the work's worktree, without entering it:

   ```bash
   bash .aid/runtime/scripts/works/worktree-lifecycle.sh locate <work-id>
   ```

   `locate` resolves via its 4-rung "most-intact-state-first" ladder and **exits 0 on every resolution** (`registered | recreated | created | current`), printing one TAB-separated line `<abs-path>\t<status>` -- split on the TAB, never on space (a worktree path can contain spaces). On an unrecoverable git state it **degrades** to `<cwd-abs>\tcurrent` (a **non-empty** path, still exit 0); it **never** fails the caller and is **not** a fail-closed / exit-1 contract.

3. **Defensive backstop (NOT fail-closed):** still check non-zero exit **or** empty path -> surface the error and STOP. Because the real helper always returns a non-empty path at exit 0, this check is a **backstop that cannot fire against the real helper** -- it guards only a mis-behaving or not-yet-built helper. The genuine protection is that a work reaches this point only because Step 1's enumeration already listed it, so `locate` resolves it onto its own isolated `work-NNN` tree whenever git is functional.

4. **Check the record** in the located worktree. The check writes nothing:

   ```bash
   AID_STATE_FILE=<abs-path>/.aid/works/<work-folder>/STATE.yml \
     bash .aid/runtime/scripts/execute/writeback-state.sh --check
   ```

   It prints one `PROBLEM` line for each missing or inconsistent part of the record, and exits 9 when there is any; 0 otherwise.

5. **Route by the record**, first match wins:

   | # | Chosen work's state | Resume entry point |
   |---|---|---|
   | 1 | Already `Completed` / `Canceled` | Tell the user the work is finished (nothing to resume) and stop; suggest a new work if they meant to start fresh |
   | 2 | `--check` reports the record missing or inconsistent | The recovery below; once the user confirms and `--repair` has written, continue at row 3 |
   | 3 | The record (every other open work) | `active_skill` at its saved `step`; with an open call, inside the called skill. A halted Lite work resumes at its doorway skill's APPROVAL-HALT step, which asks for the pending approval again |

   **Recovery (row 2), never silent.** The agent tells the user, in plain words, which parts of the record are missing or inconsistent, and proposes the **whole** repaired record -- skill, step and, when `intent.reading` is missing, the type -- as **one** confirmation question under the question protocol (`.aid/runtime/templates/question-protocol.md`), with its recommendation:

   - **skill and step**: from the skill's own detection; for a work not yet migrated, from the legacy block below;
   - **type** (only when `intent.reading` is missing): proposed from the evidence on disk -- the request or objective in `REQUIREMENTS.md` § 1, an idea draft in `.aid/design/`, or `pipeline.initiator` (e.g. a `/aid-fix` work is a bug fix) -- read the same way as `check-intent.md`.

   Only after the user confirms (or corrects any part, in the same answer) does the agent run `--repair`, which writes the whole repaired record in one write, appends a `lifecycle_history` entry, and requires `--reading` when the record has none:

   ```bash
   AID_STATE_FILE=<abs-path>/.aid/works/<work-folder>/STATE.yml \
     bash .aid/runtime/scripts/execute/writeback-state.sh --repair --skill <skill> --name <step> [--detail <step detail>] [--reading <type>]
   ```

   After one confirmed repair the record is complete and `--check` passes, so row 2 never fires twice for the same problem; the work continues at row 3. A saved step whose artifact is not on disk is found by the resumed skill's own validation and takes this same recovery path (`.aid/runtime/templates/skill-steps.md`, The work record).

6. **Enter and run** (row 3, and row 2 after its repair): enter the located worktree per `.aid/runtime/templates/worktree-lifecycle.md § Step 2` -- invoke the host-native `EnterWorktree` tool where available, else treat the path as the working directory and surface it (`Working in worktree: <path>` -- FR4 fallback). Skip the enter only when `locate` printed `current`. Then run the skill the record names (`active_skill`, itself or another skill) at its saved `step`, under `.aid/runtime/templates/skill-steps.md`. There is no special case for a resume in the same invocation.

<!-- legacy-phase-map: begin -->

**Legacy map (never routes).** A work started before the record existed has no `active_skill`, so its phase and file names are the only evidence. Recovery reads this block only to propose a skill and step for such a work; its type comes from the evidence named above. Nothing here routes a work.

The proposed step is the skill's entry step, or the step the old record's state names; the
skill's own validation on resume moves it on when the work is further along.

| Old record | Proposed skill | Proposed step |
|---|---|---|
| `phase: Describe` | `/aid-describe <work>` | `FIRST-RUN` |
| `phase: Define` | `/aid-define <work>` | `FEATURE-DECOMPOSITION` |
| `phase: Specify` | `/aid-specify <work>` | `INITIALIZE` |
| `phase: Plan` | `/aid-plan <work>` | `FIRST-RUN` |
| `phase: Detail` | `/aid-detail <work>` | `FIRST-RUN` |
| `phase: Execute` | `/aid-execute <work>` | `EXECUTE` |
| `lifecycle: Paused-Awaiting-Input` with `delivery_state: Specified` (a flattened Lite work halted at APPROVAL-HALT) | `/aid-execute <work>` | `EXECUTE` |
| `delivery_state: Executing` | `/aid-execute <work>` | `EXECUTE` |
| `delivery_state: Gated` or `Done` | `/aid-execute <work>` | `DELIVERY-GATE` |
| `active_skill: aid-deploy` (an interrupted deploy) | `/aid-deploy <work>` | `IDLE` |

<!-- legacy-phase-map: end -->

---

## Invariant preserved

The gate creates each work's record through the writer, and it routes nothing by phase: a continuation enters the chosen work's worktree and runs the skill its record names, at its saved step. A continuation allocates nothing, and only the writer changes the record.
