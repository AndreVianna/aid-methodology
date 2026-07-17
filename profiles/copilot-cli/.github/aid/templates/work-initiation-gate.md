# Work Initiation Gate

The single shared front-door every work-starting skill consults **before** it
allocates a new work folder. It makes the new-vs-continuation decision explicit,
worktree-aware, and implemented once, so no starter silently assumes either
branch. This is the Concern B counterpart to Concern A's `.aid/works/` container
(the enumeration target below).

Consulted by: the direct-entry shortcut engine's INTAKE
(`.github/aid/templates/shortcut-engine.md`), `aid-describe`, and the
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
bash .github/aid/scripts/works/enumerate-works.sh
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

The gate is done. The starter allocates a brand-new work under `.aid/works/` via
its own normal path (scan `.aid/works/` for `work-NNN-*`, next number,
kebab-slug, create `.aid/works/work-NNN-<slug>/`, scaffold `STATE.md`) -- exactly
the behavior it had before the gate existed. The gate changed nothing about
allocation; it only gated the decision to allocate.

### 3b. CONTINUATION -> route to the chosen work's resume entry point, then STOP

The gate allocates **nothing**. It reads the chosen work's `STATE.md`
frontmatter (`pipeline.path`, `phase`, `lifecycle`, and -- for flattened works --
`delivery_state`) and routes the user to that work's correct existing resume
door, per this decision (first match wins):

| Chosen work's state | Resume entry point |
|---|---|
| Flattened Lite work halted at the shortcut engine's APPROVAL-HALT (`lifecycle: Paused-Awaiting-Input` **and** `delivery_state: Specified`) | `/aid-execute <work>` |
| Mid-Execute or beyond (`phase: Execute`, or `delivery_state` is `Executing`/`Gated`/`Done`) | `/aid-execute <work>` |
| In the Deploy phase (`phase: Deploy`) | `/aid-deploy <work>` |
| Partial full-path work still in a definition phase -- route to the skill matching `STATE.md` `phase` | `Describe` -> `/aid-describe <work>`; `Define` -> `/aid-define <work>`; `Specify` -> `/aid-specify <work>`; `Plan` -> `/aid-plan <work>`; `Detail` -> `/aid-detail <work>` |
| Already `Completed` / `Canceled` | Tell the user the work is finished (nothing to resume) and stop; suggest a NEW work if they meant to start fresh |

Print the resolved command (e.g. `Continuing work-016 -- run: /aid-execute work-016-numberless-work-folder`) and **HALT**. Do not allocate, do not
author, do not enter the starter's own state machine.

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
