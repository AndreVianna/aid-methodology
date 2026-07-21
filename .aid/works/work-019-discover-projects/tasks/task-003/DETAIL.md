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
  scan subcommand on BOTH twins over a shared fixture tree via the `<root>` fast path (never the real
  machine — see the last scope bullet), using the suite's existing `run_sh` / `run_ps1` helpers and
  the pinned-HOME isolation already in the file.
- Build the fixture tree: at least two `.aid/` project roots (one whose manifest carries an
  `aid_version`, one with no/invalid manifest → `untracked`); a decoy `.aid/` nested inside a
  heavy/cache directory (`node_modules` / `.git` / a cache dir) matched by BASENAME at any depth that
  MUST NOT be discovered (NFR-2); an OS/system-named directory scenario for NFR-3's ROOT-ONLY rule —
  a directory named like a system dir (e.g. `run` / `dev`, or `Windows` on Windows) placed as an
  immediate child of the scan `<root>` that MUST be skipped, AND the SAME name nested one level
  deeper as an ordinary subfolder holding a `.aid/` project that MUST still be discovered (proving
  the deeper same-named subfolder is NOT falsely pruned); a permission-denied directory; and a
  directory-symlink cycle.
- Assert, on each twin and for bash↔pwsh parity: register-then-`list` (AC-1); `<root>` narrowing,
  non-directory `<root>` → exit 2, `--depth` bound + non-integer `--depth` → exit 2 + negative
  `--depth` (e.g. `--depth -1`) → exit 2 (AC-3); a scan-specific flag passed to `list`/`add`/`remove`
  → exit 2; `--dry-run` leaves `registry.yml` byte-unchanged and exits 0 (AC-4); a re-scan does not
  duplicate and a no-`.aid/` folder is never registered (AC-5); version / `untracked` reporting
  (AC-6); summary counts (AC-7); unreadable-skip + basename-anywhere heavy/cache prune + root-only
  OS/system skip (with the deeper same-named subfolder still discovered) + symlink-termination
  (AC-8); default-run registers in the USER tier with no elevation probe while `--shared` selects the
  shared path (AC-13); and that no file under any fixture project's `.aid/` was created or modified by
  either twin (NFR-7).
- Assert drive-classification parity (network + removable excluded by default) via the roots/drive
  classifier against a known/mocked drive set — NOT a real whole-disk crawl (AC-2, AC-9).
- Preserve the suite's SKIP-if-`pwsh`-absent gate; the Bash-side assertions still run when `pwsh` is
  absent so the block is never a vacuous pass.

**Acceptance Criteria:**
- [ ] The new `PAR` block runs within `tests/canonical/test-aid-cli-parity.sh` and passes on both
  twins (and Bash-only when `pwsh` is absent, via the existing skip gate) (AC-10).
- [ ] The block asserts, for the same fixture, identical discovery/registration results and identical
  exit codes across `bin/aid` and `bin/aid.ps1`, and that neither twin created or modified any file
  under a discovered project's `.aid/` (AC-10, NFR-7).
- [ ] The block covers AC-1, AC-3 (incl. negative `--depth` → exit 2), AC-4, AC-5, AC-6, AC-7, AC-8
  (incl. the NFR-3 root-only OS/system case: root-level skip + deeper same-named subfolder still
  discovered, and the NFR-2 basename-anywhere heavy/cache prune), and AC-13 (USER-tier forcing, no
  elevation) on each twin, and AC-2/AC-9 via the drive classifier, each with an explicit assertion.
- [ ] The fixture is a self-contained temp `<root>` under the suite's pinned fake HOME; the test never
  enumerates real fixed drives, the real machine, or the real `$HOME` (test-isolation).
- [ ] All section-6 quality gates pass.
