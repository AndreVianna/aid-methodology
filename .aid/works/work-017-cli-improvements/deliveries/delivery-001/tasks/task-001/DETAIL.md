# task-001: --allow-writes write gate + write_enabled envelope signal

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

**Type:** IMPLEMENT

**Source:** feature-001-write-infrastructure -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Deliver the fail-safe write gate end-to-end (CLI flag -> spawn argv -> server parse -> enforcement signal) plus the additive `write_enabled` envelope key both DM channels echo, so consuming features can hide controls the server would refuse. The gate ENFORCEMENT point (HTTP 403 in `_serve_op`) is delivered by task-004 (it needs the POST router); this task ships the flag, policy, spawn argv, server parse, and the envelope signal.
- `bin/aid` `_cmd_dashboard_ctl` arg loop (~line 1049): add a `--allow-writes` flag beside `--remote`/`--port`/`--verbose`; reject it for the `stop` verb exactly as `--remote` is rejected.
- `bin/aid` `_dc_start` (~line 1141): receive `--allow-writes` as a 5th positional; compute the policy `write_enabled = (remote == 0) || (remote == 1 && allow_writes == 1)` (loopback always write-enabled; `--remote` alone read-only; `--remote --allow-writes` write-enabled; `--allow-writes` on loopback accepted + redundant, no error). Append `--allow-writes` to the interpreter spawn argv (~line 1216, extending `... "$entry_point" --host 127.0.0.1 --port "$port"`) IFF `write_enabled`.
- Server `_parse_args` (`server.py` ~line 1113) and `parseArgs` (`server.mjs` ~line 65): add a `--allow-writes` store-true; absent => read-only (fail-safe default). The flag is a fixed token, never read from request/config/env (SEC-1 bind posture preserved).
- Additive `write_enabled` key: DM-1 `serialize_model` top level (beside `generated_by`) and DM-2 `machine` block (`build_home_model`, after `cli_runtime`), applied identically to `server.py` and `server.mjs`. No `schema_version` bump (DM-1 stays 3, DM-2 stays 1; DM-A3 / RC-2 no-bump precedent). Regenerate golden fixtures for both twins in lockstep.
- `_aid_remote_expose` (~line 951): extend the tailnet-ACL guidance note to state that with `--allow-writes`, any granted identity can also modify this project's state.
- `bin/aid.ps1` (Windows CLI twin — module-map maintains `bin/aid <-> bin/aid.ps1` as a behavior-parity pair): mirror ALL of the above into the PowerShell reimplementation — `Invoke-AidDashboardCtl` accepts `--allow-writes` for `start` and rejects it for `stop`; the `_dc_start`-equivalent spawn computes the identical `write_enabled` policy and appends `--allow-writes` to the server spawn argv IFF `write_enabled`; the remote-expose guidance note carries the same write-reachability warning. Required because on native Windows (no Git-Bash) `aid.ps1`/`aid.cmd` is the path that starts the dashboard; without this the gate defaults the server to read-only even on loopback once task-004 wires enforcement. (Scope extension recorded during EXECUTE — the original DETAIL named only `bin/aid`; the `bin/aid.ps1` twin was surfaced by the task-001 executor and folded in per "fix everywhere".)

**Acceptance Criteria:**
- [ ] `aid dashboard start --allow-writes` is accepted; the flag is rejected for the `stop` verb (parity with `--remote`).
- [ ] Policy holds: loopback => `write_enabled` true; `--remote` alone => false; `--remote --allow-writes` => true; `--allow-writes` on loopback => accepted with no error.
- [ ] `_dc_start` appends `--allow-writes` to the spawn argv iff `write_enabled`; a bare `server ... --host 127.0.0.1 --port N` (no flag) parses as read-only in both twins.
- [ ] `write_enabled` appears at the DM-1 envelope top level and in the DM-2 `machine` block, identically in `server.py` and `server.mjs`, with `schema_version` unchanged (DM-1 = 3, DM-2 = 1); golden fixtures are regenerated in lockstep and the cross-runtime parity suites stay green (AC4).
- [ ] `_aid_remote_expose` guidance names the write-reachability consequence of `--allow-writes` for granted tailnet identities (AC8).
- [ ] `bin/aid.ps1` mirrors the `--allow-writes` gate identically to `bin/aid` (accepted for `start`, rejected for `stop`; same `write_enabled` policy; flag appended to the server spawn argv iff `write_enabled`; remote-expose note updated) — the two CLI twins stay behavior-consistent.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
