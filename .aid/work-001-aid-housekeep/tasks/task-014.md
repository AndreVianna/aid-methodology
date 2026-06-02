# task-014: `--cleanup-only` enablement in `parse-args.sh` + State Detection routing to CLEANUP

**Type:** IMPLEMENT

**Source:** feature-004-aid-cleanup → delivery-003

**Depends on:** task-003

**Scope:**
- **Modify** `canonical/scripts/housekeep/parse-args.sh` (delivered by task-003) to **start
  accepting** the `--cleanup-only` flag. In delivery-001, task-003 deliberately rejected
  `--cleanup-only` as an unknown flag (exit 2) because the CLEANUP body was still a stub no-op;
  delivery-003 ships the real CLEANUP body, so this flag is now enabled per feature-001 SPEC §
  Invocation / CLI Arguments (AC10) and feature-004 SPEC § "`--cleanup-only` Entry (AC10)".
- When `--cleanup-only` is parsed, the parser surfaces **`**Mode:** cleanup-only`** so the
  skeleton routes PREFLIGHT → **CLEANUP directly**, bypassing KB-DELTA and SUMMARY-DELTA
  (feature-001 resume/State-Detection table row 2: PREFLIGHT → CLEANUP, `**Mode:** cleanup-only`,
  KB/Summary rows left `—`). This is the deliberate C1 skip path (feature-001 § Resume — "a
  deliberate cleanup-only run does not violate C1"); no KB/Summary gate fields are read or
  required.
- Wire the State Detection / dispatch routing (feature-001 § Feature Flow / Dispatch + § Resume,
  State Detection row 2) so that with `**Mode:** cleanup-only` set, the router enters CLEANUP's
  body (task-015) directly. Do NOT re-implement CLEANUP's body here — only the entry routing.
- The `--cleanup-only` enablement combines with the existing delivery-001 grammar: *(no args)* =
  full gated sequence; `--grade X` pass-through unchanged; any flag still unknown → exit 2. The
  `--grade X` and `--cleanup-only` flags are independent of each other (`--grade` is meaningless
  in cleanup-only mode since SUMMARY-DELTA is bypassed; document precedence per feature-001 SPEC
  if it specifies one, else `--grade` is ignored under `--cleanup-only`).
- **Type rationale (IMPLEMENT, not REFACTOR):** accepting a previously-rejected flag and routing
  it to a stage is **new accepted behavior** (the exit-2 → Mode=cleanup-only → CLEANUP path did
  not exist before), so it carries the IMPLEMENT type-default unit-test obligation — the
  delivery-001 task-008 lesson (a newly-accepted input is new behavior, not a behavior-preserving
  refactor).
- **No new design** — the flag grammar, `**Mode:** cleanup-only`, and the row-2 routing are all
  dictated verbatim by feature-001 SPEC (§ Invocation/CLI, § Resume) and feature-004 SPEC §
  "`--cleanup-only` Entry"; this task only enables what those SPECs already define.

**Acceptance Criteria:**
- [ ] `parse-args.sh` now **accepts** `--cleanup-only` (no longer exit 2) and surfaces
  `**Mode:** cleanup-only`; *(no args)* still yields the full gated sequence and `--grade X` is
  still accepted/surfaced unchanged; any other unknown flag still exits 2.
- [ ] With `**Mode:** cleanup-only`, State Detection routes PREFLIGHT → CLEANUP directly
  (feature-001 row 2): KB-DELTA and SUMMARY-DELTA are bypassed and their `**KB Stage:**` /
  `**Summary Stage:**` fields are neither read nor required (no C1 violation — deliberate skip).
- [ ] The existing `tests/canonical/test-housekeep-parse-args.sh` (task-003) is extended so the
  `--cleanup-only` case now asserts **acceptance + `Mode=cleanup-only`** (replacing/superseding
  task-003's "exit 2" assertion for this flag) and the no-args / `--grade` / other-unknown-flag
  cases remain green; auto-discovered by the `tests/canonical/test-*.sh` glob (no edit to
  `run-all.sh`).
- [ ] Unit coverage asserts the row-2 routing precondition (Mode=cleanup-only ⇒ CLEANUP entry,
  KB/Summary fields untouched) at the deterministic parse/route layer.
- [ ] All §6 quality gates pass; build/render passes; all existing tests pass (delivery-001's
  state/resume + branch-commit suites remain green).
