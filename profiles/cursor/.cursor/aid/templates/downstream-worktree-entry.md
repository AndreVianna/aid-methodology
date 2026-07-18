# Downstream Worktree Entry

The single shared pre-flight step every downstream pipeline skill (`aid-define`, `aid-specify`,
`aid-plan`, `aid-detail`, `aid-execute`, `aid-deploy`) follows once the work id it is operating on
is known: **normalize -> `locate` -> enter -> never `create`.** It is the Concern D downstream
counterpart to `.cursor/aid/templates/work-initiation-gate.md` (Concern B, work-starting) and
consumes -- without re-implementing -- the fixed contract in
`.cursor/aid/scripts/works/worktree-lifecycle.sh` and
`.cursor/aid/templates/worktree-lifecycle.md` (Concern C).

Consulted by: `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`, `aid-deploy` --
each references THIS file at its own pre-flight anchor (see each `SKILL.md`'s pointer for the
exact insertion point) rather than re-describing the normalize / `locate` / enter mechanics six
times.

> **Where this document starts.** Resolving `<work-id>` itself -- from the invocation argument, or
> from whatever no-arg / auto-select / routing method the calling skill uses -- is that skill's own
> pre-flight concern, and runs **before** Step 1 below. This document begins the instant a work id
> is available to the calling skill (a bare `work-NNN`, or a full folder slug such as
> `work-NNN-{name}`), and its own Step 1 is the first thing that happens once that id is known --
> **strictly before** the calling skill reads or writes any work-scoped artifact under
> `.aid/works/{work}/`.
>
> **How that no-arg / auto-select resolution itself works (the calling skill's own step, named
> here for completeness).** An argument-given work id is parsed straight from the argument string
> -- no disk access. A **no-arg** resolution (single-work auto-select, a "which work?" prompt, or
> `aid-define`'s Approved-work routing) **MUST** enumerate works **cross-worktree** via
> `bash .cursor/aid/scripts/works/enumerate-works.sh` (it parses `git worktree list --porcelain`
> across every worktree) -- **never** a bare local `.aid/works/` glob, which is empty on `master`
> (every work lives in its own worktree; `master` tracks no `.aid/works/` at all) and would abort
> a main-checkout invocation with a false "no works found" before this document's Step 1 ever runs.
> A single enumerated record auto-selects; multiple records prompt the user to choose; zero records
> on any worktree is the genuine "no works" STOP. `aid-define` additionally narrows that
> cross-worktree candidate set to `## Interview State: Approved` via a per-candidate `git show`
> (its own `SKILL.md § Task Routing` documents that sub-filter; this document does not repeat it).

---

## Step 1 -- Normalize to the bare `work-NNN` branch name

These skills route to a work **directory**, so the identifier a calling skill resolves is often
the **full folder slug** `work-NNN-{name}` (or, for `aid-specify`, the `work-NNN/feature-NNN`
argument form). But `worktree-lifecycle.sh locate` keys on the **branch name** `work-NNN` only.
Before calling `locate`, derive the bare form (keep `work-` plus the number, drop any `-{name}`
suffix or `/feature-NNN` remainder):

```bash
[[ "$id" =~ ^(work-[0-9]+) ]] && work_id="${BASH_REMATCH[1]}"
```

Idempotent -- a no-op when the caller already holds the bare `work-NNN`. **This step is
safety-critical:** passing the full slug to `locate` would match no `work-NNN` branch, drop the
resolution ladder to its rung-3 fallback, and fabricate a wrongly-named duplicate worktree/branch
(an FR6/NFR2/NFR3 violation). Never skip it, and never pass anything but the normalized
`work_id` to Step 2.

## Step 2 -- `locate` (script call; never `create`)

Run the shared lifecycle script's `locate` operation with the normalized `work_id`:

```bash
LOC=$(bash .cursor/aid/scripts/works/worktree-lifecycle.sh locate "$work_id"); rc=$?
IFS=$'\t' read -r WT_PATH WT_STATUS <<< "$LOC"   # field 1 = path (may contain spaces); field 2 = status
```

- **Never** invoke the sibling `create` operation from a downstream skill's pre-flight. Worktree
  *creation* is the work-**starting** skills' responsibility (feature-002); every one of these six
  downstream skills calls `locate` **only** -- it resolves an **existing** work, never brands a new
  one off `master`.
- **stdout, on every resolution:** exactly one **TAB-delimited** line --
  `<absolute-path>\t<status>`, where `<status>` is one of `registered | recreated | created |
  current`. **Split on the TAB (`IFS=$'\t' read`), never on a space** -- a worktree path can
  legitimately contain spaces.
- **exit code:** `locate` **exits `0` on every resolution, including the degrade below -- it never
  fails the caller.** On an unrecoverable git state (git absent, not a git repo, a hard git
  failure mid-resolve, or a target-dir collision that survives `git worktree prune`), it cannot
  resolve a registered/branch worktree, so it **degrades to `<cwd-abs>\tcurrent`** (a **non-empty**
  path, status `current`), writes a one-line stderr note, and **still exits `0`**.
- A `created` status returned by `locate` is **not** the `create` primitive -- it is the ladder's
  rung 3 re-materializing an **existing** work's isolation off the tip that already holds
  `.aid/works/<work-id>/` (never a new work branched off `master`). Do not conflate the two; never
  reach for `create` because `locate` happened to report `created`.

**Defensive backstop (should not fire against the real helper):**

```bash
if [[ $rc -ne 0 || -z "$WT_PATH" ]]; then
    # DEFENSIVE BACKSTOP -- should NOT arise when consuming the real feature-001 helper, which
    # always exits 0 with a non-empty path (it degrades to <cwd-abs>\tcurrent rather than
    # failing). Kept only to fail safe if a future/foreign helper ever returned empty/non-zero:
    # surface the stderr diagnostic and STOP rather than operate blindly.
    exit 1
fi
```

## Step 3 -- Enter (agent action, never a script call)

Read `WT_PATH` and enter it using the host's native session-switch, per
`.cursor/aid/templates/worktree-lifecycle.md § Step 2` (this document never re-describes that
mechanics; it only names the contract every consumer follows):

- **claude-code:** the executing agent invokes the **`EnterWorktree` agent tool** with `WT_PATH`.
  Skills instruct the agent to switch; they never shell out to it -- it is a harness tool, not a
  shell command.
- **Any host with no native session-switch primitive** (codex, cursor, copilot-cli, antigravity --
  unless/until one exposes one): **fall back** to operating with `WT_PATH` as the working
  directory for every subsequent file operation, and **surface that path to the user**:
  `Working in worktree: <path>` (FR4 / AC4). Isolation still holds -- the work still happens on
  branch `work-NNN` in its own directory; only the ergonomics of the switch differ.
- **`WT_STATUS` is `current`:** the returned path is **already** the directory to operate in -- do
  **not** invoke enter; stay put. This one instruction has two provenances (the rung-4
  already-inside no-op, or the git-broken degrade) but both demand the identical, safe action, so
  no consumer ever branches on which produced it.

## Step 4 -- Continue, now inside the entered worktree

Only after Steps 1-3 complete does the calling skill run its remaining pre-flight checks and state
machine. This ordering is the whole point: the skill's first local `.aid/works/{work}/…` read (a
feature-SPEC glob, a `PLAN.md`/`DETAIL.md` existence check, a `STATE.md` read) now resolves inside
the entered worktree -- not against the empty `.aid/works/` a `master` checkout would show (`master`
tracks no `.aid/works/` at all; every work lives in its own worktree).

---

## Never `create`

`worktree-lifecycle.sh create` is the work-**starting** primitive (feature-002): it brands a
**new** work's worktree/branch off `master`. None of `aid-define`, `aid-specify`, `aid-plan`,
`aid-detail`, `aid-execute`, or `aid-deploy` ever invokes it from this pre-flight step -- they call
`locate` only (Step 2). A `created` status token from `locate` is the ladder recovering a
**pre-existing** work's isolation (Step 2's note above), not the `create` operation.

## FR4 degradation (host without a native session-switch)

Covered in Step 3: on a host that exposes no `EnterWorktree`-equivalent primitive, the skill
proceeds with `WT_PATH` as the working directory for the remainder of the invocation and prints
`Working in worktree: <path>` so the user knows where files are landing. No profile is left
without isolation (the work still runs on the `work-NNN` branch, in its own directory); only the
switch's ergonomics degrade.

## Composition with `aid-execute`'s per-task worktrees

`aid-execute` already provisions **ephemeral per-task worktrees** at `.aid/.worktrees/task-NNN/`
(pool dispatch PD-2) on the shared delivery branch `aid/{work}-delivery-NNN`, removed after each
task completes. Entering the **work-level** worktree via Steps 1-3 above is the **outer**
isolation for the whole work; the per-task worktrees remain **nested and unchanged** inside it --
a different root and a different purpose. Once the agent's cwd is the work-level worktree root,
(a) the per-task `git worktree add .aid/.worktrees/task-NNN/` resolves relative to it, and (b) the
delivery branch is created from the current HEAD -- now `work-NNN`, not `master` -- so per-task
worktrees hang off the work branch exactly as intended. The two compose cleanly; this document
changes neither mechanism (see `aid-execute/SKILL.md § Workspace` "Ephemeral worktrees" paragraph
for the per-task side of the composition).

---

## Invariant preserved

`worktree-lifecycle.sh` is pure git mechanics; this document is the **only** place the downstream
consumption contract -- normalize, `locate`, enter, never-`create` -- is specified. A consuming
skill that needs this pre-flight step points here rather than re-describing the TAB parse, the
exit contract, or the `EnterWorktree` mechanics; it never re-implements `locate`'s ladder (owned by
feature-001) or the host-switch mechanics (owned by `worktree-lifecycle.md`).
