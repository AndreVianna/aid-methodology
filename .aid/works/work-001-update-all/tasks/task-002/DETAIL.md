# task-002: Verify bulk-update behavior and bash/pwsh twin parity via test-aid-cli-parity.sh

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

**Source:** work-001-update-all -> delivery-001

**Depends on:** task-001

**Scope:**
- Extend `tests/canonical/test-aid-cli-parity.sh` (KB `test-landscape.md`) with coverage
  that exercises `aid update all` on BOTH twins (`bin/aid`, `bin/aid.ps1`) under identical
  fixtures and asserts matching observable behavior.
- Add parity assertions: for identical inputs, bash and PowerShell produce matching
  registry enumeration, download-once behavior, failure isolation, end-of-run summary
  format, and exit code (SPEC § Twin parity / AC8).
- Add behavioral assertions covering each acceptance criterion the implementation
  satisfies: download-once (observed `fetch_tarball` invocations for a given
  `(tool, version)` == 1), enumeration equals the source `aid projects list` reads,
  failure isolation with non-zero exit, `--dry-run` plan-only with no destination writes
  and exit 0, updated/skipped/failed summary counts, `--version <v>` pinning, the
  `.aid`-missing skip, the `--target`-with-`all` usage error (exit 2), the `aid update all`
  reserved-subcommand invocation surface (AC9 -- exercised via `aid update all --dry-run`:
  consumed as a subcommand, not rejected as an unknown positional), and the
  self-update-at-most-once guarantee (AC10 -- at most once per bulk run, zero self-update
  fetches under `--dry-run`).
- Author tests only -- no production behavior is added or changed here (that is task-001).

**Acceptance Criteria:**
- [ ] `tests/canonical/test-aid-cli-parity.sh` gains `aid update all` cases and passes on
  both twins. *(SPEC AC8)*
- [ ] The tests assert that `bin/aid` and `bin/aid.ps1` produce matching observable
  behavior (enumeration, download-once, failure isolation, summary format, exit code) for
  identical inputs. *(SPEC AC8)*
- [ ] The tests assert the behavioral criteria: download-once (== 1 `fetch_tarball` per
  `(tool, version)`) *(AC1)*, exact registry enumeration *(AC2)*, failure isolation with
  non-zero exit *(AC3)*, `--dry-run` plan-only + exit 0 *(AC4)*, summary counts *(AC5)*,
  `--version` pinning *(AC6)*, and the `.aid`-missing skip *(AC7)*.
- [ ] The tests assert the invocation surface: `aid update all --dry-run` is consumed as a
  reserved subcommand -- it prints a per-project plan for every registered project and
  exits 0, and is NOT rejected as an unknown positional / usage error. *(SPEC AC9 /
  BLUEPRINT.md:54)*
- [ ] The tests assert the self-update-at-most-once guarantee: across a bulk run the
  self-update preamble runs at most once, and under `--dry-run` it runs zero times
  (observed self-update fetches under `--dry-run` == 0). *(SPEC AC10 / BLUEPRINT.md:55)*
- [ ] All section-6 quality gates pass.
