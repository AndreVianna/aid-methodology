# task-013: Per-host MCP-config mechanism spike

**Type:** RESEARCH

**Source:** work-002-external_sources -> delivery-002

**Depends on:** -- (none)

**Scope:**
- Verify, at implementation time, each of the five hosts' MCP-config mechanism (config file path, scope project-vs-user-home, format, servers container, per-server entry shape): `claude-code` CONFIRMED from the repo `.mcp.json`; `cursor` high-confidence; `codex` / `copilot-cli` / `antigravity` are `SPIKE-verify-at-implementation` (KI-006, KI-007) via host docs or probing an installed host.
- Do NOT fabricate unknown paths — state unknowns as unknown.
- Produce findings with per-host CONFIDENCE flags + sources + a recommendation on the wire-now set vs the deferred set (wire-only-installed). Feeds task-014's data artifact.

**Acceptance Criteria:**
- [ ] Each host row is either CONFIRMED with its source (repo artifact / host docs / probe) or explicitly flagged `verify-at-install` — no fabricated paths
- [ ] For a host whose mechanism is unknown, at least two candidate encodings are compared with their evidence before recommending defer
- [ ] Sources are cited for every non-CONFIRMED claim
- [ ] An actionable recommendation names the set safe to wire now (`claude-code`) and the deferred set, in the shape task-014 will materialize
- [ ] All §6 quality gates pass
