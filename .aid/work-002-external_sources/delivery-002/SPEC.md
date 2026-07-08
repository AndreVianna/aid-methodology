# Delivery SPEC -- delivery-002: MCP Host Wiring

> **Delivery:** delivery-002
> **Work:** work-002-external_sources
> **Created:** 2026-07-08

---

## Objective

Make declared `mcp` tools directly **invocable** by the repo's agents (not merely
discoverable): wire each `mcp` connector into the MCP configuration of every **installed** host
via that host's own mechanism. Today `tools.installed = [claude-code]`, so the repo-root
`.mcp.json` is wired (its mechanism is CONFIRMED from the repo); the other four host profiles
are carried in a mechanism table and skipped cleanly until installed. `api|ssh|url|cli`
connectors are validated as connect-sufficient via their recorded descriptor — no bespoke
per-tool clients are built.

## Scope

In scope — features:
- **feature-004-connection-wiring** — the per-host MCP-config mechanism table; the generic
  idempotent read-merge-write wiring twin (Bash + PowerShell, Python stdlib for nested JSON,
  no new heavy dependency); wire-only-installed; committed MCP configs carry secret references
  (never values).

**Out of scope:** wiring hosts not present in `settings.yml tools.installed` (deferred by
design until installed); bespoke per-tool client code; idempotent reconcile / unwire-on-remove
(delivery-003 composes feature-004's unwire path); non-MCP agent-side consumption code (Q4).

## Gate Criteria

- [ ] AC-4 — An `mcp` tool is wired into each **installed** host's MCP configuration (today: `claude-code` → repo-root `.mcp.json`, verified); an `api|ssh|url|cli` tool yields a connection descriptor an agent can act on. Uninstalled hosts are skipped cleanly.
- [ ] Committed MCP configs carry only secret **references** (e.g. `env:VAR`), never values (reference-not-value holds post-wiring; AC-3 leak-proof).
- [ ] Wiring is idempotent (re-wire preserves existing unrelated servers, e.g. the repo's `playwright-project`).
- [ ] AC-8 — cross-platform (Win/mac/Linux); no new heavy runtime dependency.
- [ ] All section-6 quality gates pass.

## Tasks

Navigational overview (authored by `aid-detail`). Full definitions live in `tasks/task-NNN/SPEC.md`; execution order is in `PLAN.md` `## Execution Graph`.

| Task | Type | Title |
|------|------|-------|
| task-013 | RESEARCH | Per-host MCP-config mechanism spike |
| task-014 | CONFIGURE | Per-host MCP mechanism-table data artifact |
| task-015 | IMPLEMENT | Host-MCP-config wire/unwire twin |
| task-016 | IMPLEMENT | Wire-on-declare hook in the connector sub-phase |
| task-017 | TEST | MCP wiring idempotence, reference-not-value, and clean-skip tests |

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-003

## Notes

Risk-accepted gate scope: only `claude-code`'s MCP mechanism is CONFIRMED from the codebase;
`cursor` is high-confidence-unverified and `codex`/`copilot-cli`/`antigravity` are
SPIKE-verify-at-implementation (KI-006, KI-007). The gate accepts "claude-code verified; the
four other hosts carried as verify-at-install" rather than asserting full 5-host coverage.
Some hosts (e.g. `codex` → `~/.codex/config.toml`) write config **outside** the repo tree,
beyond feature-001's repo-tree P7 carve-out — this surfaces only when such a host is installed
and needs its own out-of-repo idempotency + installed-check contract at implementation.
