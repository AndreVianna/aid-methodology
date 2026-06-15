# task-006: Per-repo format stamp + fail-safe migration gate (PowerShell parity)

**Type:** IMPLEMENT

**Source:** feature-003-per-repo-format-stamp → delivery-001

**Depends on:** task-002, task-005

**Scope:**
- `bin/aid.ps1` only — parity twin of task-005. Apply feature-003 rows C1', C2', C3', C4', C5', C6'.
  - C1': add the `$AidSupportedFormat = 1` parity constant immediately after the `$env:AID_HOME` resolution (~`bin/aid.ps1:892`), defined exactly once; integer must equal the bash `AID_SUPPORTED_FORMAT`.
  - C2': era-b settings synthesizer ps1 region (`:1563-1596`) — prepend `format_version: <sup>` line.
  - C3': era-a settings repair ps1 twin (the `minimum_grade`/`heartbeat_interval` ensure pattern, `:1507-1544`) — same `format_version` ensure-key step.
  - C4': NEW `_aid_repo_format` (ps1) — replicate the strip logic from the `$getScalarValue` closure (`:1426` inside `Invoke-AidRepairSettingsEraA`, **not** reused) + `-match '^\d+$'` validation; `0` on absent/malformed.
  - C5': NEW `_aid_format_gate` (ps1) — same 3-way classify (refuse / warn-offer / silent), same messages, honor the `AID_NO_MIGRATE` equivalent (suppress offer only).
  - C6': wire the gate into the ps1 dashboard/status/update dispatch (the twins of bash `:1918`/`:1978`), running before operating.

**Acceptance Criteria:**
- [ ] `$AidSupportedFormat = 1` defined exactly once; its integer equals the bash constant.
- [ ] ps1 `_aid_repo_format`/`_aid_format_gate` reproduce the bash refuse/warn-offer/silent outcomes for the same fixtures, collapsing malformed/absent to `0` (never to newer).
- [ ] The gate is wired into the ps1 repo-command entry points and runs before operating; era-a repair + era-b synthesizer write `format_version: 1`.
- [ ] bash/ps1 behavioral parity holds; all new strings/messages/comments are ASCII-only.
- [ ] All §6 quality gates pass.
