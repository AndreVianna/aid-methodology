# Work Initiation Gate

The single shared front-door every work-starting skill consults **before** it
allocates a new work folder. It makes the new-vs-continuation decision explicit,
worktree-aware, and implemented once, so no starter silently assumes either
branch. This is the Concern B counterpart to Concern A's `.aid/works/` container
(the enumeration target below).

Consulted by: the direct-entry shortcut engine's INTAKE
(`.codex/aid/templates/shortcut-engine.md`), `aid-describe`, and the
collapse/standalone starters `aid-review`, `aid-research`, `aid-design`,
`aid-report`, `aid-test`, `aid-prototype`, `aid-create-document`,
`aid-change-document`. Each references THIS file at its allocation step rather
than re-implementing the logic.

> **Where the gate sits.** It runs at the exact point a starter would otherwise
> allocate `work-NNN` (scan `.aid/works/`, pick the next number, create the
> folder). The gate either lets the starter proceed with that allocation (NEW)
> or steps aside and routes the user to an existing work's own resume door
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
bash .codex/aid/scripts/works/enumerate-works.sh
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
  Return control to the starter, which allocates exactly as it does today (see
  Step 3a). This is the common first-work case.
- **One or more works exist -> ASK.** Present the enumerated list and ask a
  single question (the project's one-question-at-a-time convention -- never
  silently assume either branch):

  ```
  Works already exist. Is this a NEW work, or a CONTINUATION of an existing one?

  Existing works:
    work-016-numberless-work-folder   [Specify · Paused-Awaiting-Input]   (worktree: work-016)
    work-017-orders-read-api          [Execute · Running]                 (main)
    work-018-billing-report           [Plan · Running]                    (main)

  [N] New work
  [1] Continue work-016-numberless-work-folder
  [2] Continue work-017-orders-read-api
  [3] Continue work-018-billing-report
  ```

  Compose the bracketed `[phase · lifecycle]` and `(worktree: <label>)` from the
  helper's record columns. Wait for the answer before doing anything else.

## Step 3 -- Act on the answer

### 3a. NEW -> hand back to the starter

The gate hands back to the starter, which now performs, in this order:

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
   inside it would find nothing and re-allocate a colliding `work-001` (see
   `feature-002/SPEC.md § Next-work-NNN derivation` for the full collision
   analysis). The starter derives its own kebab-case `<name>` slug exactly as it
   does today (from the description, or `{verb}-{artifact}`, or an asked name).

2. **Create and enter the worktree, BEFORE authoring anything:**

   ```bash
   bash .codex/aid/scripts/works/worktree-lifecycle.sh create <work-id> <name>
   ```

   Idempotent (a no-op re-print if the worktree already exists, keyed on the
   `<work-id>` branch); prints the worktree's **absolute path** to stdout on
   success/no-op; exits 0 on success/no-op, non-zero with **empty stdout** on
   failure. **Create-failure guard (fail-closed -- the real NFR1 protection for
   this branch):** if the exit code is non-zero **or** the printed path is
   empty, surface the error and **STOP** -- do **not** fall through to allocate
   the new work on the current (possibly `master`) tree. On success, **enter**
   the resolved path per `.codex/aid/templates/worktree-lifecycle.md § Step
   2`: the executing agent invokes the host-native `EnterWorktree` tool where
   available, else treats the resolved path as the working directory for all
   subsequent file operations and surfaces it to the user (`Working in
   worktree: <path>` -- FR4 fallback).

3. **Only now**, inside the entered worktree, allocate and scaffold: create
   `.aid/works/<work-id>-<name>/` (reusing the `<work-id>` resolved in step 1
   above -- do **not** re-derive it from the fresh worktree's own, still-empty
   `.aid/works/`) and scaffold `STATE.md`, exactly as the starter did before
   this worktree automation existed.

The gate changed nothing about the allocation mechanics; it only gated the
decision to allocate, and now also gates *where* that allocation lands.

### 3b. CONTINUATION -> route to the chosen work's resume entry point, then STOP

The gate allocates **nothing**. It reads the chosen work's `STATE.md`
frontmatter (`pipeline.path`, `phase`, `lifecycle`, and -- for flattened works --
`delivery_state`) and routes the user to that work's correct existing resume
door, per this decision (first match wins):

| Chosen work's state | Resume entry point |
|---|---|
| Flattened Lite work halted at the shortcut engine's APPROVAL-HALT (`lifecycle: Paused-Awaiting-Input` **and** `delivery_state: Specified`) | `/aid-execute <work>` |
| Deploy in progress (`active_skill: aid-deploy` -- an interrupted `/aid-deploy`; Deploy is a separate path, no longer a `phase:`) | `/aid-deploy <work>` |
| Mid-Execute or beyond (`phase: Execute`, or `delivery_state` is `Executing`/`Gated`/`Done`) | `/aid-execute <work>` |
| Partial full-path work still in a definition phase -- route to the skill matching `STATE.md` `phase` | `Describe` -> `/aid-describe <work>`; `Define` -> `/aid-define <work>`; `Specify` -> `/aid-specify <work>`; `Plan` -> `/aid-plan <work>`; `Detail` -> `/aid-detail <work>` |
| Already `Completed` / `Canceled` | Tell the user the work is finished (nothing to resume) and stop; suggest a NEW work if they meant to start fresh |

**If the resolved route resumes in THIS SAME invocation** (today this is only
`aid-describe`, when the chosen work's `phase` is `Describe` -- the gate hands
control back to the very skill the user already invoked rather than routing to
a different command), the starter locates and enters the chosen work's
isolated worktree before resuming:

1. **Normalize** the chosen work's id to its **bare** `work-NNN` branch name
   first: `[[ "$chosen_work" =~ ^(work-[0-9]+) ]] && work_id="${BASH_REMATCH[1]}"`.
   Step 1's enumeration supplies the **full folder slug** (e.g.
   `work-016-numberless-work-folder`), but `worktree-lifecycle.sh locate` keys
   on the **bare `work-NNN` branch name** -- passing the full slug would match
   no branch, drop the resolution ladder to its rung-3 fallback, and fabricate
   a wrongly-named duplicate worktree. Idempotent if the id is already bare
   (identical normalization to feature-003 § 3.3 "Work-id normalization").

2. **Locate:**

   ```bash
   bash .codex/aid/scripts/works/worktree-lifecycle.sh locate <work-id>
   ```

   `locate` resolves via its 4-rung "most-intact-state-first" ladder and
   **exits 0 on every resolution** (`registered | recreated | created |
   current`), printing one TAB-separated line `<abs-path>\t<status>` -- split
   on the TAB, never on space (a worktree path can contain spaces). On an
   unrecoverable git state it **degrades** to `<cwd-abs>\tcurrent` (a
   **non-empty** path, still exit 0); it **never** fails the caller and is
   **not** a fail-closed / exit-1 contract.

3. **Defensive backstop (NOT fail-closed):** still check non-zero exit **or**
   empty path -> surface the error and STOP. Because the real helper always
   returns a non-empty path at exit 0, this check is a **backstop that cannot
   fire against the real helper** -- it guards only a mis-behaving or
   not-yet-built helper, never the normal path. The genuine NFR1 protection on
   this branch is that a work only reaches this in-invocation resume because
   Step 1's enumeration already listed it as an existing work, so `locate`
   resolves it onto its own isolated `work-NNN` tree (rung 1, or a rung-2/3
   recreate) whenever git is functional -- not this guard. The degrade to
   `current` fires only in a pathological git-broken state where no tool could
   isolate anyway.

4. **Enter** (rungs 1-3 -- `registered | recreated | created`), unless
   `<status>` is `current` (the rung-4 already-inside no-op, or the
   git-broken degrade -- both mean stay put, skip the enter): per
   `.codex/aid/templates/worktree-lifecycle.md § Step 2`, invoke the
   host-native `EnterWorktree` tool where available, else treat the resolved
   path as the working directory and surface it (FR4 fallback).

Only then does the starter proceed into its own resumed state machine (e.g.
`aid-describe`'s State Detection) for `<work_id>`.

**Every other route** (a route-and-halt target naming a different command the
user must run next) gets none of the above in this invocation. Print the
resolved command (e.g. `Continuing work-016 -- run: /aid-execute
work-016-numberless-work-folder`) and **HALT**. Do not allocate, do not
author, do not enter the starter's own state machine here -- the locate+enter
for that target happens inside the routed command's own run (feature-003),
not in this gate.

> **Why route, not resume.** A shortcut is a one-shot INTAKE->DETAIL producer
> whose engine carries an explicit *"Accepted limitation -- no cross-session
> resume"* and *"One run, one work"* design note. Routing keeps that single
> responsibility intact -- the engine only ever authors a fresh work -- while
> still honoring "keep working on that one" by handing the user the door that
> already knows how to resume it. It also uniformly handles the common case
> where the chosen work is a **full-path** work the flattened engine could never
> resume anyway: routing to the matching phase skill is the only coherent
> continuation for those.

**Rejected alternative.** *Teach the shortcut engine to resume its own
INTAKE->DETAIL pipeline over the chosen existing work* (re-enter at the state
matching which artifacts already exist on disk). Rejected because (a) it directly
contradicts the engine's committed "no cross-session resume" / "one run, one
work" invariants; (b) it would require per-state idempotency/re-entry machinery
the engine deliberately does not build speculatively (no FR/AC requires it); (c)
existing works are frequently full-path works the flattened engine structurally
cannot drive; (d) re-running authoring states over a partially-executed work
risks corrupting it. Routing avoids all four.

---

## Invariant preserved

The gate **routes**; it does not teach the flattened INTAKE->DETAIL engine (or
any collapse starter) to resume its own partial run. The shortcut engine's
"no cross-session resume" invariant is untouched -- a starter that is handed
back control on NEW still allocates a brand-new work exactly as before, and on
CONTINUATION the gate steps aside entirely.
