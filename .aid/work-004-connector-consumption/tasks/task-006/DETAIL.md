# task-006: Register the two new skills for emission + run /generate-profile

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

**Type:** CONFIGURE

**Source:** work-004-connector-consumption -> delivery-001

**Depends on:** task-002, task-003, task-004

**Scope:**
- Ensure `aid-set-connector` and `aid-unset-connector` are emitted by `/generate-profile` to all 5
  profile trees + dogfood `.claude/`. The generator auto-discovers skill directories under
  `canonical/skills/` (`generate-profile/scripts/render.py`, `iterdir()` over the skills dir); where
  a skill inventory/manifest is NOT auto-derived (installer file lists, any per-skill settings
  entry, `generated-files.txt`), register the two skills there so they install — otherwise confirm
  auto-discovery already covers them (no fabricated manifest step).
- Run `python .claude/skills/generate-profile/scripts/run_generator.py` (`/generate-profile`) to
  render every canonical edit from task-001/002/003/004 — `reconcile.md`, both skills,
  `consumption-protocol.md`, the refactored `state-elicit.md`, the seam wiring, and the `ticket_ref`
  STATE/SPEC schema additions — into the 5 profiles, then resync the dogfood `.claude/` tree.
- Verify the standing distribution gates: `/generate-profile` renders deterministically (a re-run
  produces no diff), dogfood byte-identity, connector-twin PS-parity, PS 5.1 lanes.

**Acceptance Criteria:**
- [ ] `aid-set-connector` and `aid-unset-connector` appear in all 5 profile trees + dogfood
  `.claude/` after `/generate-profile`, and are reachable as installed skills (traces to AC11).
- [ ] `/generate-profile` renders clean and deterministically (a re-run produces no diff);
  `tests/canonical/test-dogfood-byte-identity.sh` passes (traces to AC11).
- [ ] Connector-twin PS-parity (`test-connector-twins-ps1-parity.sh`) and the PS 5.1 lanes stay
  green (traces to AC11).
- [ ] All section-6 quality gates pass.
