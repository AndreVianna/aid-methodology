# task-017: MCP wiring idempotence, reference-not-value, and clean-skip tests

**Type:** TEST

**Source:** work-002-external_sources -> delivery-002

**Depends on:** task-015

**Scope:**
- Deterministic fixture tests for task-015's twin: `wire` into a `.mcp.json` already carrying `playwright-project` preserves it; a re-wire is byte-stable; `unwire` removes only the connector entry and leaves others intact; the committed config carries only `${VAR}` (grep for the value finds nothing); an uninstalled host is a clean no-op; an `api | ssh | url | cli` connector yields a connect-sufficient descriptor with no host-config write.

**Acceptance Criteria:**
- [ ] Tests are deterministic with clean setup/teardown over fixture host configs
- [ ] Idempotent merge + preservation of unrelated servers proven; `unwire` preservation proven
- [ ] Reference-not-value proven post-wiring (no secret value in the committed config)
- [ ] Uninstalled-host clean-skip and non-`mcp` descriptor sufficiency covered (AC-4 both clauses; AC-8)
- [ ] All §6 quality gates pass
