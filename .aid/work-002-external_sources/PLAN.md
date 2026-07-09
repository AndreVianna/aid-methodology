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

### delivery-002: MCP Host Wiring — WITHDRAWN (Q10, 2026-07-09)
- **Status:** WITHDRAWN. Q10 retracted the wiring premise — AID does not write/wire/manage host MCP configs. feature-004 was rewritten to "Connection Modes & Consumption" (a documentation/contract feature with **no code**); its content is realized within delivery-001 (feature-001 descriptor schema, feature-002 ELICIT mode-capture, feature-005 consumption contract). All five delivery-002 tasks (013 mechanism spike, 014 mechanism table, 015 wire/unwire twin, 016 wire-on-declare hook, 017 wiring tests) are **DROPPED**; the delivery-002 folder is removed and the committed mechanism artifacts reverted. The Q10 corrections to the already-shipped delivery-001 catalog are applied as a **delivery-001 correction pass** (mode-aware descriptor/ELICIT/consumption text), not as a separate delivery.
- **Features:** feature-004 (Connection Modes & Consumption — no code; realized within delivery-001)
- **Depends on:** -- (withdrawn)

### delivery-003: Idempotent Reconcile
- **What it delivers:** Re-running `aid-discover` reconciles the registry — add new, update-in-place, remove-and-purge absent — without clobbering surviving entries or their secrets, with no index churn (deterministic builder) and interrupt-safe (purge-before-delete). REMOVE = delete descriptor + purge the local secret (**aid-managed connectors only**) + regenerate INDEX; there is **NO unwire step** (Q10 supersedes Q8 — AID wrote no host config to unwire).
- **Features:** feature-006-idempotent-reconcile
- **Depends on:** delivery-001
- **Priority:** Must

#### Execution Graph

- **Wave 1:** task-018 (<- task-001, task-005, task-006, task-008 -- all delivery-001 (Done); the former task-015 dependency is dropped with delivery-002)
- **Wave 2:** task-019 (<- task-018)

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | P7 write-guard is prose-only — `principles.md` P7 declares the ELICIT connector-sub-phase write allowlist (post-Q10: `.aid/connectors/` only), but `discover-preflight.sh` has no write-scope allowlist check. The exemption's narrow scope is upheld by agent adherence, not code. | M | Not fixed in this work's write path (out of scope). Surface as a tech-debt candidate: add a real pre-flight write-scope allowlist check. |

*Risks previously tracked here — per-host MCP-mechanism uncertainty, out-of-repo host-config writes, and the codex TOML-writer gap — were **eliminated by Q10**: AID no longer writes any host MCP config, so those write paths and their verify-at-install / out-of-repo hazards no longer exist.*

## Deferred

*(No feature deferred. Upstream scope boundaries (not delivery deferrals): agent-side code that actively consumes connection descriptors (Q4, OOS); **all host-MCP-config wiring removed entirely (Q10** — feature-004 is now a no-code "Connection Modes & Consumption" documentation/contract feature realized within delivery-001; delivery-002 withdrawn); pre-existing committed-secret cleanup (Q5b, discovery tech-debt); KB-index→YAML migration (Q6e, future work).)*
