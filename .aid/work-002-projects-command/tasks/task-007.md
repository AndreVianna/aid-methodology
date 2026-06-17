# task-007: PowerShell `aid projects` command parity

**Type:** IMPLEMENT

**Source:** feature-001-projects-command → delivery-002

**Depends on:** task-001, task-002, task-003, task-004, task-005, task-006 (all of delivery-001)

**Scope:** Mirror the bash command in PowerShell (per SPEC §Layers C), matching behavior, output shape, and exit codes:
- **`Get-RegistryRawUnion`** — non-pruning union (mirror of `_registry_read_raw_union`).
- **`Resolve-AidTier`** — mirror of `_aid_resolve_tier` (Windows has no elevation prompt; the per-user/global distinction, `--local`/`--shared` override, and degrade-to-user still apply).
- **`Invoke-AidProjects`** — list (default) / add / remove / help, mirroring `_cmd_projects`; ASCII `*` "you are here" marker.
- Dispatch branch for `projects` in `bin/aid.ps1` (`~2286`, after `__migrate-repo`, before the reject); `Show-AidUsage` (`~140-207`) default block + per-command help.
- Reconcile **BOTH** PS tier prompts (FR7/AC6 — same two-prompt situation as bash): `Invoke-AidCwdClassify` prompt #1 (`~1315`, "Register this repo…") AND the `aid add` B-table prompt #2 (`~2609`, "Add this repo to the shared machine registry?") — replace both with `Resolve-AidTier` (no prompt). Confirm `Select-String "Register this|Add this repo" bin/aid.ps1` returns zero afterward. The PS dashboard/migrate auto-register paths degrade silently (never-elevate), mirroring bash task-005.
- ASCII-only (`bin/aid.ps1` is ASCII-guarded). (PS writers already emit `projects:` from task-001.)

**Acceptance Criteria:**
- [ ] `aid projects list/add/remove/help` on PowerShell match the bash semantics, output columns/marker, and exit codes (incl. add-rejects-non-`.aid/` exit 2; idempotent add/remove; remove repairs stale).
- [ ] Tier resolution matches the FR6 table; **neither** PS tier prompt remains (`Select-String "Register this|Add this repo" bin/aid.ps1` → 0); `aid add` on global/outside-home does not prompt.
- [ ] ASCII-only; `bin/aid.ps1` parses (pwsh parse-check).
- [ ] All §6 quality gates pass.
