# task-004: Connectors context-file section, settings.yml pointer, and consumption contract

**Type:** DOCUMENT

**Source:** work-002-external_sources -> delivery-001

**Depends on:** task-003

**Scope:**
- Author a new `## Connectors` section inside the AID-managed region (`<!-- AID:BEGIN -->` / `<!-- AID:END -->`) of the five hand-maintained root context files (`profiles/claude-code/CLAUDE.md` + the four `profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md`) plus the repo-root `CLAUDE.md` (the only repo-root context file — there is no repo-root `AGENTS.md`), referencing `@.aid/connectors/INDEX.md` in the style of `@.aid/knowledge.`
- The section carries the FR-6 consumption contract (feature-005 Component 2): scan `@.aid/connectors/INDEX.md` -> open the descriptor -> for `mcp` (tool-managed) **request the connection from the host tool's own MCP/plugin** (the tool handles auth; AID stores no credential), else (aid-managed `api|ssh|url|cli`) resolve `secret_reference` at use-time (`env:` env var, `file:` `.aid/connectors/.secrets/<connector>`, `keychain:` OS keychain), plus the explicit OUT-OF-SCOPE boundary (no agent-side code that actively consumes connection descriptors — Q4). (Q10: AID wires nothing — `mcp` = request from the host tool, not "use the wired host config".)
- Fold a `.aid/settings.yml` pointer into an existing allowlisted section (e.g. `## Knowledge Base` or `## Workflow`) to avoid a new managed-region stem beyond `Connectors`.
- These files are hand-maintained (NOT canonical->profiles rendered); the repo-root `CLAUDE.md` receives the change via the installer's in-place managed-region updater.

**Acceptance Criteria:**
- [ ] The four `AGENTS.md` files remain byte-identical (single sha256) after the edit — the `## Connectors` addition is applied identically to all four plus `CLAUDE.md` (FR12; `tests/canonical/test-agents-md-invariant.sh` passes)
- [ ] The `## Connectors` section references `@.aid/connectors/INDEX.md`, states the FR-6 consumption protocol, and names the non-MCP OOS boundary
- [ ] A `.aid/settings.yml` pointer is present, folded into an existing allowlisted section (no new managed-region stem beyond `Connectors`)
- [ ] Content accuracy verified against feature-001 §Context-file wiring and feature-005 Component 2
- [ ] All §6 quality gates pass
