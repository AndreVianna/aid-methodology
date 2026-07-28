# task-001: Citation lint: profiles, resolver and range check

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-003-review-subsystem-redesign -> delivery-002

**Depends on:** --

**Scope:**
- `canonical/aid/scripts/kb/kb-citation-lint.sh`: the en-dash fix to the linespec character class, `--profile durable|resolvable`, `--depth N`
- The resolver: verbatim `test -f`, then a suffix match over `git ls-files` with a **mandatory single-sweep `find` fallback**, then `[UNRESOLVED]` / `[AMBIGUOUS]`
- The range check, and the extension of `tests/canonical/test-kb-citation-lint.sh`

**Acceptance Criteria:**
- [ ] A range citation written with an en-dash against a shorter file reports `[OUT-OF-RANGE]` -- non-trivially false today, since the upper bound is currently invisible
- [ ] `--profile durable` output on `.aid/knowledge` is byte-identical to today's
- [ ] The `find` fallback is exercised by a fixture where `git ls-files` fails, which is the live condition inside this repository's own worktrees under WSL
- [ ] The three inherited exemptions stay silent under both profiles
- [ ] All section-6 quality gates pass
