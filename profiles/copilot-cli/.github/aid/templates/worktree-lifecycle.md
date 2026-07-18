# Worktree Lifecycle Helper

The single shared agent contract every worktree-consuming skill binds to **after** it calls
`.github/aid/scripts/works/worktree-lifecycle.sh`. The script is pure git mechanics -- it
creates or resolves a work's isolated worktree and prints a path; it **never** switches a
session. This document specifies what the executing agent does with that path: which
host-native session-switch to invoke, the fallback for a host that exposes none, and the
consumption contract every consumer binds to. This is the Concern C counterpart to
`enumerate-works.sh` + `work-initiation-gate.md`'s enumeration pair -- a shared helper
implemented and specified exactly once, because skills are prose + bash and cannot call a
harness tool on the script's behalf.

Consulted by: feature-002's work-starting automation (the Work Initiation Gate's NEW/CONTINUATION
branches), feature-003's downstream locate-and-enter (`aid-define` / `aid-specify` / `aid-plan` /
`aid-detail` / `aid-execute` / `aid-deploy`), and feature-004's `aid-housekeep` teardown. Each
references THIS file at its enter step rather than re-implementing the switch logic.

---

## Step 1 -- Obtain the path (script call)

Run the shared lifecycle script for the desired operation:

```bash
bash .github/aid/scripts/works/worktree-lifecycle.sh create <work-id> <name> [--base <ref>]
bash .github/aid/scripts/works/worktree-lifecycle.sh locate <work-id> [--name <slug>]
```

- **`create`** -- on success or no-op (idempotent, keyed on the `<work-id>` branch), stdout is
  **exactly the worktree's absolute path**, nothing else. `create` **fails closed**: a non-zero
  exit or an empty path means STOP -- never allocate the new work on the current (possibly
  `master`) tree.
- **`locate`** -- stdout is **one TAB-separated line**: `<absolute-path>\t<status>`, where
  `<status>` is one of `registered | recreated | created | current`. **Split on TAB, never on
  space** -- a worktree path can legitimately contain spaces. `locate` **never fails the
  caller**: an unrecoverable git state degrades to `<cwd-abs>\tcurrent` and still exits `0`.

The full script contract -- arguments, exit codes, the 4-rung "most-intact-state-first" ladder,
and input validation -- lives in the script's own header and in feature-001's Technical
Specification. **This document never re-implements that ladder**; it specifies only what happens
after the script returns.

## Step 2 -- Enter it (agent action, never a script call)

Read stdout field 1 (the absolute path) and enter it using the host's **native session-switch**:

- **claude-code:** the executing agent invokes the **`EnterWorktree` agent tool** with the
  resolved path. This is a harness tool the agent calls directly -- skills *instruct the agent to
  switch*; they never shell out to it, and `worktree-lifecycle.sh` itself never switches a
  session.
- **Any profile without such a primitive** (codex, cursor, copilot-cli, antigravity -- unless/until
  a host exposes one): **fall back** to operating with the resolved path as the working directory
  for all subsequent file operations, and **surface that path to the user**:
  `Working in worktree: <path>`. Isolation still holds -- the work still happens on branch
  `<work-id>` in its own directory; only the ergonomics of the switch differ.
- **`current` status (locate only):** the returned path is **already** the directory to operate
  in -- do **NOT** invoke enter; stay put. This one instruction has two provenances (rung-4
  already-inside, or the git-broken degrade) but both demand the identical, safe action, so no
  consumer ever branches on which produced it.

**Enter is an agent action, never a script call.** `worktree-lifecycle.sh` only prints a path; it
never switches a session -- separation of concerns keeps portable git mechanics in bash and the
host-specific session-switch in the agent. This is what lets `create`/`locate` run identically on
all five profiles while only the ergonomics of the switch degrade gracefully on a host without a
native primitive (FR4 / NFR5): no profile is left without isolation, and none is blocked on a
primitive it lacks.

## Step 3 -- Consumption contract

| Consumer (parallel feature) | Calls | Then |
|---|---|---|
| feature-002 work-starting automation | gate NEW -> `create <work-id> <name>`; gate CONTINUATION -> `locate <work-id>` | agent enters (Step 2). Wires into the Work Initiation Gate + every work-starting skill. |
| feature-003 downstream locate-and-enter | `locate <work-id>` (never `create`) | agent enters, then operates. Applies to `aid-define` / `aid-specify` / `aid-plan` / `aid-detail` / `aid-execute` / `aid-deploy`. |
| feature-004 `aid-housekeep` teardown | `locate <work-id>` to resolve the path to remove | the confirm-before-delete checklist offers `git worktree remove` + `<work-id>` branch prune. **Teardown is exclusively feature-004** -- this helper exposes no `remove` operation. |

---

## Invariant preserved

`worktree-lifecycle.sh` is **pure git mechanics** and never touches a session; this document is
the **only** place the host-native switch and its cwd-fallback are specified. A consumer that
needs the enter step points here rather than re-describing the `EnterWorktree` tool or the
fallback message wording -- exactly as it points to feature-001's script for the ladder, never
re-implementing either.
