# task-014: Per-host MCP mechanism-table data artifact

**Type:** CONFIGURE

**Source:** work-002-external_sources -> delivery-002

**Depends on:** task-013

**Scope:**
- Materialize the verified per-host MCP mechanism table (from task-013) as a committed DATA artifact under `canonical/aid/scripts/connectors/` — the single source of truth BOTH the `wire` and `unwire` ops key off (data, not per-host code).
- Rows carry `Host | Config file | Scope | Format | Servers container | Per-server entry shape | CONFIDENCE`.

**Acceptance Criteria:**
- [ ] The data artifact contains one row per host with the CONFIDENCE flags from task-013 (`claude-code` CONFIRMED; others `verify-at-install`)
- [ ] The artifact holds no secret value (references / templates only)
- [ ] Regenerating / re-rendering the artifact is idempotent (byte-stable)
- [ ] Adding or correcting a host is a data-row edit both ops inherit (no per-host code)
- [ ] All §6 quality gates pass
