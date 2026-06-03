# task-008: `--cleanup-only` enablement in SKILL.md `## Arguments` + State Detection routing to CLEANUP

**Type:** IMPLEMENT

**Source:** feature-004-aid-cleanup → delivery-003

**Depends on:** task-003

**Scope:**
- **Edit** `canonical/skills/aid-housekeep/SKILL.md`'s `## Arguments` table + `## State Detection`
  routing (the prose argument handling authored by task-003) to **start accepting** the
  `--cleanup-only` flag. In delivery-001, task-003 deliberately did **not** offer `--cleanup-only`
  (the `## Arguments` table omitted it and State Detection rejected it) because the CLEANUP body
  was still a stub no-op; delivery-003 ships the real CLEANUP body, so this flag is now enabled
  per feature-001 SPEC § Invocation / CLI Arguments (AC10) and feature-004 SPEC §
  "`--cleanup-only` Entry (AC10)". **This is a prose edit to `SKILL.md`, not a `parse-args.sh`
  edit** — `/aid-housekeep` handles arguments via the `## Arguments` table + State Detection in
  `SKILL.md` (consistent with the other five skills), and ships no dedicated CLI arg-parser
  script.
- When `--cleanup-only` is given, the `## Arguments` + State Detection prose surfaces
  **`**Mode:** cleanup-only`** so the skeleton routes PREFLIGHT → **CLEANUP directly**, bypassing
  KB-DELTA and SUMMARY-DELTA (feature-001 resume/State-Detection table row 2: PREFLIGHT →
  CLEANUP, `**Mode:** cleanup-only`, KB/Summary rows left `—`). This is the deliberate C1 skip
  path (feature-001 § Resume — "a deliberate cleanup-only run does not violate C1"); no KB/Summary
  gate fields are read or required.
- Wire the State Detection / dispatch routing (feature-001 § Feature Flow / Dispatch + § Resume,
  State Detection row 2) so that with `**Mode:** cleanup-only` set, the router enters CLEANUP's
  body (task-009) directly. Do NOT re-implement CLEANUP's body here — only the entry routing in
  `SKILL.md` prose.
- The `--cleanup-only` enablement combines with the existing delivery-001 grammar in the
  `## Arguments` table: *(no args)* = full gated sequence; `--grade X` pass-through unchanged; any
  unrecognized flag still rejected. The `--grade X` and `--cleanup-only` flags are independent of
  each other (`--grade` is meaningless in cleanup-only mode since SUMMARY-DELTA is bypassed;
  document precedence per feature-001 SPEC if it specifies one, else `--grade` is ignored under
  `--cleanup-only`).
- **Type rationale (IMPLEMENT, not REFACTOR):** accepting a previously-rejected flag and routing
  it to a stage is **new accepted behavior** (the rejected → Mode=cleanup-only → CLEANUP path did
  not exist before), so it carries the IMPLEMENT type-default verification obligation — the
  delivery-001 lesson (a newly-accepted input is new behavior, not a behavior-preserving
  refactor). Coverage of the row-2 routing precondition lands in the integration suite (task-010),
  since the routing now lives in `SKILL.md` prose (no parse-args unit suite).
- **No new design** — the flag grammar, `**Mode:** cleanup-only`, and the row-2 routing are all
  dictated verbatim by feature-001 SPEC (§ Invocation/CLI, § Resume) and feature-004 SPEC §
  "`--cleanup-only` Entry"; this task only enables what those SPECs already define, in `SKILL.md`
  prose. It supersedes task-003's delivery-001 "do not offer / reject `--cleanup-only`" behavior.

**Acceptance Criteria:**
- [ ] `SKILL.md`'s `## Arguments` table now **offers** `--cleanup-only` (no longer rejected) and
  State Detection surfaces `**Mode:** cleanup-only`; *(no args)* still yields the full gated
  sequence and `--grade X` is still accepted/passed through unchanged; any other unrecognized flag
  is still rejected.
- [ ] With `**Mode:** cleanup-only`, State Detection routes PREFLIGHT → CLEANUP directly
  (feature-001 row 2): KB-DELTA and SUMMARY-DELTA are bypassed and their `**KB Stage:**` /
  `**Summary Stage:**` fields are neither read nor required (no C1 violation — deliberate skip).
- [ ] The change is a `SKILL.md` prose edit (`## Arguments` + State Detection), not a
  `parse-args.sh` edit; `/aid-housekeep` ships no dedicated CLI arg-parser script.
- [ ] The integration suite (task-010) asserts the row-2 routing precondition (Mode=cleanup-only ⇒
  CLEANUP entry, KB/Summary fields untouched) at the deterministic state-machine layer; the
  delivery-001 state/resume + branch-commit suites remain green.
- [ ] All §6 quality gates pass; build/render passes (CI render-drift re-emits the edited
  `SKILL.md` to all 5 profiles, no renderer edit); all existing tests pass.
