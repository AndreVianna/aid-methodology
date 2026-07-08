# Delivery SPEC -- delivery-001: Registry Foundation — Declare, Register, Persist, Consume

> **Delivery:** delivery-001
> **Work:** work-002-external_sources
> **Created:** 2026-07-08

---

## Objective

Deliver the standalone-usable core of external-sources/tool-integration support: running
`aid-discover` prompts (skippably) for external **sources** and **tools**, restoring the
elicitation lost when `aid-init` folded into `aid-config`. Sources are gathered and populated
into `external-sources.md` (URLs included) and discoverable via the KB; tools (preset + custom)
are captured as committed descriptors under `.aid/connectors/` with local-only auth (reference,
never value); the deterministic connectors `INDEX.md` is built and referenced from the host
context files, so the repo's agents can **discover** the whole toolchain and **consume**
non-MCP tools per the documented contract. This is the smallest grouping that is genuinely
usable on its own.

## Scope

In scope — features:
- **feature-001-integration-store-placement** — the `.aid/connectors/` home + P7 carve-out, the registry/descriptor schema, the three secret-reference forms, the cross-platform git-ignored secret store, the connectors `INDEX.md` contract, and the `CLAUDE.md`/`AGENTS.md` + `settings.yml` wiring.
- **feature-002-source-and-tool-elicitation** — the P7-exempt `ELICIT` discover state; source elicitation → `external-sources.md` (via Scout); tool elicitation → descriptors; skippable; presets + generic; URL cataloguing.
- **feature-003-local-auth-registration** — the feature-003-owned `connector-secret` twin (`write`+`purge`, path-confined, no-echo/no-persist); the `file:` default reference form; local git-ignored secret store.
- **feature-005-registry-persistence-and-consumption** — the deterministic connectors `INDEX.md` builder + regeneration; the documented FR-6 consumption contract in the `## Connectors` context section.

**Out of scope:** MCP host-config wiring (delivery-002 — so `mcp`-typed tools are captured and discoverable here but NOT yet directly invocable); idempotent reconcile / safe re-run (delivery-003); non-MCP agent-side descriptor-consumption code (Q4, out of scope for the whole work).

## Gate Criteria

- [ ] AC-1 — Running `aid-discover` prompts for external sources and tools (distinct kinds); skips cleanly with no empty artifacts when there are none.
- [ ] AC-2 — A user can declare both a preset tool (e.g. GitHub) and a custom tool via the generic descriptor; each captured with connection type, endpoint/target, and an auth reference.
- [ ] AC-3 — After entering a secret, grepping repo + KB + STATE + transcript for that value finds nothing; the value exists only in the local git-ignored store (reference-not-value proven; scope = our registered secret, not a repo-wide pre-existing scan).
- [ ] AC-5 — Sources persisted to `external-sources.md` and the tool registry to `.aid/connectors/`, both machine-readable and documented for humans; connectors `INDEX.md` referenced from the host context files.
- [ ] AC-7 — The placement decision (registry + auth home) exists as an explicit analysis artifact (feature-001 SPEC).
- [ ] AC-8 — Verified on Windows, macOS, and Linux; no new heavy runtime dependency.
- [ ] All section-6 quality gates pass.

## Tasks

Navigational overview (authored by `aid-detail`). Full definitions live in `tasks/task-NNN/SPEC.md`; execution order is in `PLAN.md` `## Execution Graph`.

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Connectors registry frontmatter-accessor twin |
| task-002 | DOCUMENT | P7 read-only carve-out for `.aid/connectors/` in principles.md |
| task-003 | IMPLEMENT | Installer managed-region Connectors heading-stem allowlist |
| task-004 | DOCUMENT | Connectors context-file section, settings.yml pointer, and consumption contract |
| task-005 | IMPLEMENT | Deterministic connectors INDEX.md builder twin |
| task-006 | IMPLEMENT | connector-secret twin with no-echo write and path-confined purge |
| task-007 | CONFIGURE | Connector preset catalog canonical asset |
| task-008 | IMPLEMENT | ELICIT discover state and aid-discover state-machine wiring |
| task-009 | IMPLEMENT | GENERATE source-populate path |
| task-010 | DOCUMENT | pipeline-contracts.md aid-discover state-machine row update |
| task-011 | TEST | connector-secret twin behavior and AC-3 leak-proof sweep tests |
| task-012 | TEST | INDEX builder determinism and registry accessor tests |

## Dependencies

- **Depends on:** -- (none — foundation)
- **Blocks:** delivery-002, delivery-003

## Notes

Honest boundary: `mcp`-typed tools (including presets like `github`) are captured and
discoverable in this delivery but become directly **invocable** only after delivery-002 wires
them into host MCP configs. Non-MCP tools (`api|ssh|url|cli`) and all sources are fully usable
within this delivery.
