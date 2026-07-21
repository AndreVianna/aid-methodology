# task-003: Parity + guardrail coverage in `tests/canonical/test-aid-cli-parity.sh`

[!NOTE]
This is the TASK-LEVEL DETAIL.md — the IMMUTABLE DEFINITION for this task in a flattened (Lite)
work. Written once; not a state file. This flattened work has NO per-task `STATE.md`; each task's
mutable cells live in the work-root `STATE.md § ## Delivery Lifecycle → ### Tasks lifecycle`.

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

**Source:** work-019-discover-projects -> delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Add a new `PAR`-prefixed test block to `tests/canonical/test-aid-cli-parity.sh` that exercises the
  scan subcommand on BOTH twins over a shared fixture tree via BOTH the zero-arg HOME default
  (achieved hermetically by pointing the pinned `$HOME` / `%USERPROFILE%` at the fixture root, so
  the default scope resolves to the fixture) and the `--path <folder>` fast path (never the real
  machine — see the last scope bullet), using the suite's existing `run_sh` / `run_ps1` helpers and
  the pinned-HOME isolation already in the file.
- Build the fixture tree covering every guardrail:
  - At least two `.aid/` project roots (one whose manifest carries an `aid_version`, one with
    no/invalid manifest → `untracked`).
  - A decoy `.aid/` nested inside a heavy/cache/build directory — exercise the NEW names too
    (`obj` / `bin` / `logs`) plus a classic one (`node_modules` / `.git` / a cache dir), and a
    MIXED-CASE variant (e.g. `Build` / `OBJ`) to prove case-insensitive matching — all matched by
    BASENAME at any depth and MUST NOT be discovered (NFR-2).
  - **NFR-3 system set is `--all`-only:** under the HOME-default AND `--path` scan root, place a
    TOP-LEVEL folder named like a system dir (e.g. `dev` / `run`) holding a `.aid/` project — it
    MUST be DESCENDED into and the project inside FOUND (the system set does NOT apply at a
    HOME/`--path` root; this is the `~/dev` projects-convention case). Keep the deeper
    same-named-subfolder case too (a `dev`/`run` nested below the top level, NOT inside a project,
    is descended normally). The system-dir SKIP itself is asserted separately on the `--all` path
    (below): against the mocked filesystem/drive-root set, a system-named immediate child of a true
    root (`/proc`, or `C:\Windows` on Windows) MUST be skipped.
  - **Nested-in-project (NFR-9):** a valid project `P` that itself contains, under one of its
    subdirectories, a nested `.aid/` (and/or a whole nested project) — the nested one MUST NOT be
    separately discovered/registered (P's subtree is pruned once P is found).
  - **Exclusion-named project (NFR-9):** a project whose OWN folder name is an exclusion (e.g. a repo
    literally named `bin` / `obj` / `logs`) holding a valid `.aid/` — it MUST still be discovered
    (the `.aid/` check precedes name-based pruning).
  - **Dedupe (NFR-10):** a directory symlink that points at an already-walked real project (and/or
    a `.`/`..`-reachable overlap) — the project MUST be registered EXACTLY ONCE.
  - **State-home / non-project `.aid` (FR-5):** the CLI state home (`$HOME/.aid`) present in the tree
    MUST NOT be registered, and a path whose `.aid` is NOT a valid project dir (fails
    `_aid_is_project_dir` / `Test-AidIsProjectDir`) MUST NOT be registered.
  - **Termination (NFR-4):** a pathologically deep chain of nested directories (deeper than the user
    `--depth` yet bounded by the hard `_AID_SCAN_MAX_DEPTH`) — the scan MUST terminate.
  - A permission-denied directory; and a directory-symlink cycle.
- Assert, on each twin and for bash↔pwsh parity: the zero-arg HOME default scans the fixture-pinned
  HOME and registers its projects (AC-2 home default); register-then-`list` (AC-1); `--path <folder>`
  narrowing, non-directory `--path` → exit 2, `--path` together with `--all` → exit 2 (mutually
  exclusive), `--include-network`/`--include-removable` WITHOUT `--all` → exit 2, `--depth` bound +
  non-integer `--depth` → exit 2 + negative `--depth` (e.g. `--depth -1`) → exit 2 (AC-3, AC-9); a
  scan-specific flag passed to `list`/`add`/`remove`
  → exit 2; `--dry-run` leaves `registry.yml` byte-unchanged and exits 0 (AC-4); a re-scan does not
  duplicate and leaves an already-registered project's record UNCHANGED (no re-tier/rewrite/reorder)
  and a no-`.aid/` folder is never registered (AC-5); version / `untracked` reporting
  (AC-6); summary counts (AC-7); unreadable-skip + basename-anywhere (case-insensitive, ALL modes)
  heavy/cache prune incl. `obj`/`bin`/`logs` + the HOME/`--path` top-level `dev`/`run` DESCENDED with
  the project inside FOUND (system set is `--all`-only, NOT applied at a HOME/`--path` root) +
  termination on both the symlink cycle AND the deep chain (hard `_AID_SCAN_MAX_DEPTH`) (AC-8); the
  project-subtree prune so a nested-in-project `.aid/` is NOT separately registered while an
  exclusion-named project (`bin`/`obj`/`logs`) IS discovered (AC-14); canonical dedupe so a
  symlink/overlap to an already-walked project registers it exactly once (AC-15); the state home and
  a non-project `.aid` are never registered (AC-16); default-run registers in the USER tier with no
  elevation probe while `--shared` selects the shared path (AC-13); and that no file under any
  fixture project's `.aid/` was created or modified by either twin (NFR-7).
- Assert the `--all` drive/root classifier against a known/mocked filesystem/drive-root set — NOT a
  real whole-disk crawl: on Windows the classifier excludes network + removable from the FIXED set
  by default (included only with the opt-in flags), and a system-named immediate child of a true
  root (`/proc`, `C:\Windows`) is skipped (NFR-3 `--all`-only); on Unix, note that `--all` walks all
  mounts under `/` with network/removable NOT auto-excluded and the opt-in flags inert-with-note
  (documented NFR-5 limitation) (AC-2, AC-8, AC-9).
- Preserve the suite's SKIP-if-`pwsh`-absent gate; the Bash-side assertions still run when `pwsh` is
  absent so the block is never a vacuous pass.

**Acceptance Criteria:**
- [ ] The new `PAR` block runs within `tests/canonical/test-aid-cli-parity.sh` and passes on both
  twins (and Bash-only when `pwsh` is absent, via the existing skip gate) (AC-10).
- [ ] The block asserts, for the same fixture, identical discovery/registration results and identical
  exit codes across `bin/aid` and `bin/aid.ps1`, and that neither twin created or modified any file
  under a discovered project's `.aid/` (AC-10, NFR-7).
- [ ] The block covers AC-1, AC-2 (zero-arg HOME default scans the fixture-pinned HOME with no drive
  enumeration; the `--all` drive classifier excludes network+removable on Windows, and
  network/removable WITHOUT `--all` → exit 2), AC-3 (incl. `--path`/`--all` mutual exclusion → exit 2,
  non-integer AND negative `--depth` → exit 2), AC-4, AC-5 (incl. no-change-on-re-scan), AC-6, AC-7,
  AC-8 (incl. the NFR-3 rule that the system set is `--all`-only — a top-level `dev`/`run` under a
  HOME/`--path` root is DESCENDED and the project inside FOUND, while under `--all` a system child of
  a true root is skipped; the NFR-2 basename-anywhere case-insensitive heavy/cache prune incl.
  `obj`/`bin`/`logs` in all modes; and termination on BOTH the symlink cycle and the deep chain via
  the hard `_AID_SCAN_MAX_DEPTH`), AC-9 (incl. the Unix inert-with-note behavior), AC-13 (USER-tier
  forcing, no elevation), AC-14 (nested-in-project `.aid/` NOT separately registered +
  exclusion-named project STILL discovered), AC-15 (canonical dedupe of a symlink/overlap ⇒ once),
  and AC-16 (state home + non-project `.aid` never registered) on each twin, each with an explicit
  assertion.
- [ ] The fixture is a self-contained temp folder — used both as the pinned fake HOME (so the
  zero-arg default resolves to it) and as the `--path` argument; the test never enumerates real
  fixed drives, the real machine, or the real `$HOME` (test-isolation).
- [ ] All section-6 quality gates pass.
