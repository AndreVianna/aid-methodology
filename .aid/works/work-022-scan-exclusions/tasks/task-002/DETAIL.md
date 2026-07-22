# task-002: Parity + guardrail tests for the expanded prune sets and the config merge

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
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

**Source:** work-022-scan-exclusions -> delivery-001

**Depends on:** task-001

**Scope:**
- Extend `tests/canonical/test-aid-cli-parity.sh` (the existing `PAR019` scan block, or a
  new `PAR022` block in the same style) with parity + guardrail coverage for the expanded
  prune sets and the config merge. Reuse the established fixture-tree + `run_sh_scan` /
  `run_ps1_scan` helpers and the exact-set assertion pattern (`assert_eq` on the discovered
  set, `assert_exit_eq`, `assert_output_contains`).
- Build a fixture tree exercising the new behavior: directories named with the new Tier-A
  names (`node_modules`, `.pnpm-store`, `.pytest_cache`, `.next`, `.vscode`, `.cursor`,
  `.pyenv`, `cache`, `tmp`, `AppData`, `User Data`, etc.) each holding a stray `.aid/` that
  MUST NOT be registered; a directory named `build`/`bin`/`.vscode` that DOES hold a valid
  `.aid/` and MUST be discovered (is-project check precedes prune); and a real project that
  MUST be discovered so the exact-set assertion is meaningful.
- Assert: (a) each new Tier-A name prunes at any depth in all modes; (b) a Tier-B name
  prunes ONLY as an immediate child of an `--all` drive/filesystem root and NOT deeper /
  not under HOME-default/`--path` (assert against the mocked/known `--all` root classifier
  the PAR019 block already uses; do NOT crawl the real machine); (c) a `build`/`bin` project
  is still discovered; (d) a `scan-config.yml` adding a non-built-in name extends the prune
  set while built-ins still prune; (e) a repeated built-in name changes nothing; (f) a
  missing/unreadable config yields exit 0 with the built-in set; (g) both twins produce the
  identical discovered set + identical exit codes over an identical config + fixture
  (including a spaced `- Code Cache`); (h) a non-`--dry-run` scan seeds `scan-config.yml`
  and a `--dry-run` scan does not.
- Pin isolation: set `HOME` and `AID_STATE_HOME` (and `USERPROFILE` + `HOMEDRIVE` +
  `HOMEPATH` for the native Windows pwsh twin, which derives `$HOME` from `USERPROFILE`) to
  the fixture root so no real `~/.aid` / `registry.yml` / `scan-config.yml` is read or
  written (repo test-isolation rule). Do NOT run any port-binding, dashboard-parity, or
  full bash suite locally; scope the local check to this block. Defer canonical byte-parity
  and full-suite runs to CI.
- Read the script's own self-reported summary line for pass/fail counts (not a grep over
  stdout).

**Acceptance Criteria:**
- [ ] Tests prove each new Tier-A name prunes at any depth in all modes and a stray `.aid/`
  beneath it is not registered. (AC-3)
- [ ] Tests prove a new Tier-B name prunes only as an `--all` root-only child and is not
  pruned deeper or under HOME-default/`--path`. (AC-4)
- [ ] Tests prove a `build`/`bin`/`.vscode` directory containing a valid `.aid/` is still
  discovered. (AC-5)
- [ ] Tests prove the config extends the built-in set (non-built-in name prunes), a
  repeated built-in is deduped, and a missing/unreadable config yields exit 0 with the
  built-in set. (AC-7, AC-8, AC-9)
- [ ] Tests prove both twins read an identical `scan-config.yml` (including a spaced entry)
  identically and produce the identical discovered set + identical exit codes; and that a
  non-`--dry-run` scan seeds the config while `--dry-run` does not. (AC-6, AC-10)
- [ ] Tests pin `HOME`/`AID_STATE_HOME` (+ `USERPROFILE`/`HOMEDRIVE`/`HOMEPATH` for pwsh)
  at the fixture root so no real `~/.aid` is touched. (NFR-2, test-isolation rule)
- [ ] All section-6 quality gates pass.
