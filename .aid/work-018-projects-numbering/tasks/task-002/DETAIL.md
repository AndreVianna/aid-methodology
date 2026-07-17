# task-002: Test numbered `aid projects list` and `remove <N>` across both CLI twins

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

**Source:** work-018-projects-numbering -> delivery-001

**Depends on:** task-001

**Scope:**
- Extend the CLI test suites that gate `bin/aid` / `bin/aid.ps1` — `tests/canonical/test-aid-cli-parity.sh` (twin behavior-parity; `module-map.md`, `test-landscape.md`) and the existing projects/registry CLI coverage — to assert the new behavior on **both** twins against a fixture registry with a known ordered set of paths:
  - Numbered `list`: rows are prefixed with a 1-based index (first row `1`, incrementing) in `_registry_read_raw_union` order, and the `*` cwd marker still appears. *(SPEC AC-1)*
  - `remove <N>` in range: `aid projects remove K` (all-digits `K`, `1 <= K <= N`) unregisters exactly the Kth listed project and no other entry; the number `list` showed for that project is the number that removed it. *(SPEC AC-2, AC-6)*
  - Registered path form preserved: `aid projects remove <registered-path>` (argument containing a non-digit) still unregisters that path. *(SPEC AC-3)*
  - Digit-named folder: with a project whose folder is literally named `1` registered, `aid projects remove ./1` (or its absolute path) unregisters it, while `aid projects remove 1` resolves as an index (never that folder). *(SPEC AC-13)*
  - Error — index `> count` / empty registry: `remove K` with all-digits `K > N`, and `remove 1` against an empty registry, each write a clear message to stderr, exit `2`, and leave the registry unchanged. *(SPEC AC-4, AC-5)*
  - Error — index `< 1`: `remove 0` (and `00`) writes a clear message to stderr, exits `2`, and leaves the registry unchanged. *(SPEC AC-10)*
  - Base-10 leading-zero index: `remove 008` (a leading-zero all-digits value containing an 8) is parsed base-10 — it resolves as decimal index 8 (a valid removal if in range, else the exit-2 out-of-range error) and never raises a raw shell/octal error (e.g. bash's "value too great for base"). *(SPEC AC-2, AC-4; NFR-1)*
  - Error — negative: `remove -1` is rejected upstream as an unknown flag, exits `2`, registry unchanged. *(SPEC AC-11)*
  - Error — unregistered path: `remove abc` (a non-digit path that does not resolve to a registered project) writes a clear message to stderr, exits `2`, registry unchanged — not the former idempotent no-op. *(SPEC AC-12)*
  - `add` unaffected: `aid projects add <path>` behavior/output unchanged. *(SPEC AC-7)*
  - Empty-case `list`: prints `(no projects registered)` with no numbered rows. *(SPEC AC-8)*
  - Twin parity: the Bash and PowerShell runs produce identical output/behavior for all cases above (including the error text/exit code). *(SPEC AC-9)*
- Run the suites on both twins; do NOT weaken existing assertions. No production code is written in this task (any code defect found routes back to task-001).

**Acceptance Criteria:**
- [ ] New/extended tests cover numbered `list`, `remove <N>` (in-range), registered-path removal, the digit-named-folder path form (`./1`) vs. bare-index behavior, the index `> count` / empty-registry / `< 1` (`0`) / negative (`-1`) / unregistered-path error cases (each stderr + exit 2, registry unchanged), a base-10 leading-zero index (`008` parsed as decimal 8, never a raw shell/octal error), `add` unchanged, and empty-case `list`, and all pass. *(SPEC AC-1..AC-8, AC-10..AC-13)*
- [ ] `tests/canonical/test-aid-cli-parity.sh` passes with the new cases, confirming byte-identical Bash/PowerShell behavior for the numbered `list`, `remove <N>`, and every error case. *(SPEC AC-9; NFR-1)*
- [ ] The full pre-existing CLI/registry suite still passes (no regression, no weakened assertion).
- [ ] All section-6 quality gates pass.
