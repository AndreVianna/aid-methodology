# task-025: Re-key the remaining bundle-consuming suites to release staging

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-21

**Depends on:** task-012, task-013, task-015

**Scope:**
- Switch bundle construction to `tests/lib/bundle.sh` and re-key layout assertions (`<root>/aid/`,
  `<root>/skills/`, `CLAUDE.md`, manifest format 2, settings stamp 4) in:
  `tests/canonical/test-registry.sh`, `tests/canonical/test-self-commands.sh`,
  `tests/canonical/test-release-install-e2e.sh` and `tests/canonical/test-release-migrate-smoke.sh`
  (its seeded "old" repo now takes the clean-slate upgrade to format 5 through the channels).
- Any other suite still failing because of the layout change and not owned by another task
  (find them with `HOME=$(mktemp -d) bash tests/run-all.sh`) is re-keyed here too, and named in
  this task's hand-off.
- `tests/canonical/test-artifact-discipline.sh` (AD13): add `.agents/` and `.aid/runtime/` to the
  counter's `EXCLUDE` tuple (`.claude/` is already there), so the installed copies of
  `canonical/skills` and `canonical/aid` are not counted twice; ceilings stay unchanged. The
  exclusion holds before and after the task-027 resync, so no dependency is added.
- Removed or renamed keys get rows in `tests/coverage-accepted-removals.tsv` or the re-home
  allowlist.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/<suite>.sh` exits `0` for each of the four suites named in Scope (on a host with the runtimes each suite already requires).
- [ ] `grep -cE 'profiles/[a-z-]+/' tests/canonical/test-registry.sh tests/canonical/test-self-commands.sh tests/canonical/test-release-install-e2e.sh tests/canonical/test-release-migrate-smoke.sh` prints `0` for every file.
- [ ] The coverage-parity gate (run where `pwsh`, `node` and `python3` are on PATH) reports no un-excused removal for these suites.
- [ ] `bash tests/canonical/test-artifact-discipline.sh` prints a `PASS:` AD13 line for every class and exits `0`, both before and after the task-027 dogfood resync (with `.agents/` and `.aid/runtime/` populated).
- [ ] All section-6 quality gates pass.
