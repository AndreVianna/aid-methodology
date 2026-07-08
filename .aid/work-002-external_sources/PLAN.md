# Plan -- External Sources & Tool Integrations

## Deliverables

### delivery-001: Registry Foundation — Declare, Register, Persist, Consume
- **What it delivers:** Running `aid-discover` prompts (skippably) for external **sources** and **tools**. Sources are gathered/populated into `external-sources.md` (URLs included) and discoverable via the KB — this alone restores the lost `aid-init` elicitation, the work's originating objective. Tools (preset + custom) are captured as committed descriptors under `.aid/connectors/`; `file:` auth secrets are stored locally (no echo/persist, only a reference committed); `env:`/`keychain:` references recorded. The connectors `INDEX.md` is built (deterministic) and referenced from `CLAUDE.md`/`AGENTS.md`, so agents can **discover** the whole toolchain and **consume** non-MCP tools per the documented contract.
- **Features:** feature-001-integration-store-placement, feature-002-source-and-tool-elicitation, feature-003-local-auth-registration, feature-005-registry-persistence-and-consumption
- **Depends on:** -- (foundation)
- **Priority:** Must

#### Execution Graph

- **Wave 1 (parallel -- no intra-delivery dependencies):** task-001, task-002, task-003, task-005, task-006, task-007, task-009
- **Wave 2:** task-004 (<- task-003) - task-008 (<- task-002, task-005, task-006, task-007) - task-011 (<- task-006) - task-012 (<- task-005, task-001)
- **Wave 3:** task-010 (<- task-008)

### delivery-002: MCP Host Wiring
- **What it delivers:** Declared `mcp` tools are wired into each **installed** host's MCP configuration via that host's mechanism, so agents can **invoke** them directly through the host harness — not merely discover them. Today `tools.installed = [claude-code]`, so the repo-root `.mcp.json` is wired; the other four hosts are carried in the mechanism table and skipped cleanly until installed. `api|ssh|url|cli` descriptors are validated as connect-sufficient (no bespoke clients).
- **Features:** feature-004-connection-wiring
- **Depends on:** delivery-001
- **Priority:** Must

#### Execution Graph

- **Wave 1:** task-013 (RESEARCH spike -- gates the delivery)
- **Wave 2:** task-014 (<- task-013)
- **Wave 3:** task-015 (<- task-014, task-001)
- **Wave 4 (parallel):** task-016 (<- task-015, task-008) - task-017 (<- task-015)

### delivery-003: Idempotent Reconcile
- **What it delivers:** Re-running `aid-discover` reconciles the registry — add new, update-in-place, remove-and-purge absent — without clobbering surviving entries or their secrets, with no index churn (deterministic builder) and interrupt-safe (purge-before-delete). Removing an `mcp` tool also unwires it from installed host configs.
- **Features:** feature-006-idempotent-reconcile
- **Depends on:** delivery-001, delivery-002
- **Priority:** Must

#### Execution Graph

- **Wave 1:** task-018 (<- task-001, task-005, task-006, task-008, task-015 -- cross-delivery deps; first within delivery-003)
- **Wave 2:** task-019 (<- task-018)

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | Per-host MCP mechanism unverified — only `claude-code` is CONFIRMED (repo `.mcp.json`); `codex`/`copilot-cli`/`antigravity` are SPIKE-verify-at-implementation, `cursor` high-confidence-unverified. AC-4's "all 5 profiles" is aspirational today. | H | Structural: wire-only-installed defers each host until it is in `tools.installed`. delivery-002 ships against `claude-code` (verified); the delivery-002 gate accepts "claude-code verified; four hosts carried as verify-at-install" rather than claiming full 5-host coverage. |
| 2 | Out-of-repo host-config writes — `codex` (`~/.codex/config.toml`) and likely `antigravity`/`copilot-cli` write user-home files outside the repo tree, beyond feature-001's repo-tree P7 carve-out; codex TOML has no stdlib writer (`tomllib` is read-only). | M | Deferred by wire-only-installed (surfaces only when such a host is installed). Each out-of-repo host needs its own idempotency + installed-check contract at implementation. |
| 3 | P7 write-guard is prose-only — `principles.md` P7 claims a hard pre-flight guard, but `discover-preflight.sh` has no write-scope allowlist. The ELICIT exemption's narrow scope is upheld by agent adherence, not code. | M | Not fixed in this work's write path (out of scope). Surface as a tech-debt candidate: add a real pre-flight write-scope allowlist check. |

## Deferred

*(No feature deferred — all 6 Must features are assigned to deliveries. Upstream scope boundaries already fixed in requirements/specify, not delivery deferrals: non-MCP agent-side consumption code (Q4, OOS); non-`claude-code` host wiring (wire-only-installed); pre-existing committed-secret cleanup (Q5b, discovery tech-debt); KB-index→YAML migration (Q6e, future work).)*
