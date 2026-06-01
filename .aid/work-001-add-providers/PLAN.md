# Plan — Add Providers (Copilot CLI + Antigravity)

## Deliverables

### delivery-001: Provider research & mapping
- **What it delivers:** A single committed findings doc (`research/provider-mapping.md`) that pins each tool's *current* extension conventions and produces the verified AID-primitive→tool-primitive mapping table, with every `[FR1-owned]` value/ruling crossed off (model tiers, tool-name remaps, capability flags, Antigravity context-file pick + rule extension, the `agent.format` enum label, the Copilot MCP emit/omit ruling, scripts/templates home, the Antigravity cross-kind ruling Q-D, and the context-file production convention Q-J). Standalone value: it is the design decision record the two profiles are built from without re-research, and it resolves the F003→F002 edge before any profile work starts.
- **Features:** feature-001-provider-research
- **Depends on:** —
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | — |
| task-003 | task-001, task-002 |
| task-004 | task-003 |

| Can Be Done In Parallel |
|------------------------|
| task-001, task-002 |

### delivery-002: GitHub Copilot CLI profile
- **What it delivers:** `profiles/copilot-cli.toml` + the narrow renderer extension (E1 `.agent.md` sub-agent emitter only, after the FR1 loopback) + the profile-local committed `AGENTS.md`, so `run_generator.py` emits an installable Copilot CLI tree — sub-agents as invocable `.agent.md` custom agents, skills as native Agent Skills `SKILL.md` folders (`[data]`, like cursor), recipes as `[data]` — that is render-drift clean while the existing 3 profiles stay byte-identical. FR1 dropped E2 (skills are native `[data]`, not a cross-kind route) and E3 (MCP is `[omit]`). Standalone value: a Copilot CLI adopter can render + use the AID tree (setup wiring lands in delivery-004, but the emitted tree is complete and gated here).
- **Features:** feature-002-copilot-cli
- **Depends on:** delivery-001
- **Priority:** Must

#### Execution Graph

> **task-007/008 removed (E2/E3 dropped per FR1 loopback):** task-007 (E2 skills→agent cross-kind route) is obsolete — skills are native Agent Skills emitted as `[data]` folders by the existing `render_skills` pass (Q-A); task-008 (E3 MCP emitter) is obsolete — MCP is `[omit]` (Q-B, zero `mcp` matches in the repo). Numbers 007/008 are intentional, auditable gaps; tasks are NOT renumbered.

| Task | Depends On |
|------|-----------|
| task-005 | task-004 |
| task-006 | task-004, task-005 |
| task-009 | task-004, task-005 |
| task-010 | task-004, task-006, task-009 |

| Can Be Done In Parallel |
|------------------------|
| task-006, task-009 (after task-005 — render_agents.py E1 · copilot-cli.toml+AGENTS.md, file-disjoint) |

### delivery-003: Google Antigravity profile
- **What it delivers:** `profiles/antigravity.toml` (modeled on cursor) + the one engine increment + the profile-local committed `AGENTS.md` (Q-H), so `run_generator.py` emits an installable Antigravity tree — skills as native `.agent/skills/<slug>/SKILL.md` folders (`[data]`, like cursor), sub-agents reshaped into `.agent/rules/*.md` via a new `"antigravity-rule"` agent-format that reuses feature-002's E1 format-branch mechanism, methodology `[[extras.rules]]` as `.md` rules (via a `RuleEntry.output_filename` touch) — render-drift clean with all prior profiles byte-identical. FR1 reversed the original skills→`.agent/workflows/` route (skills are native `[data]` now). Standalone value: an Antigravity adopter can render the AID tree; the repo stays coherent, tested, drift-clean.
- **Features:** feature-003-antigravity
- **Depends on:** delivery-001, **delivery-002** (E1 format-branch mechanism reuse — see Risk #1)
- **Priority:** Must

#### Execution Graph

> **task-013 removed (skills→workflows route obsolete; skills native `[data]`):** task-013 (R2 skills→flat-workflows cross-kind + R3 `RuleEntry.output_filename`) is obsolete — skills are native `.agent/skills/` folders handled as `[data]` by the profile (task-011) + the existing `render_skills` pass, so the skills→workflows route is gone (it had reused feature-002's now-deleted E2). R3 (`RuleEntry.output_filename`) is **folded into task-012**. Number 013 is an intentional, auditable gap; tasks are NOT renumbered.
>
> task-012 (the `"antigravity-rule"` sub-agents→rules reshape) **depends on task-006** because it reuses the new-agent-format-branch mechanism feature-002's E1 introduces in `_render_agent_for_profile` — NOT E1's Copilot `.agent.md` output, and NOT the deleted E2. This is the precise feature-003→feature-002 edge (delivery-003 → delivery-002).

| Task | Depends On |
|------|-----------|
| task-011 | task-004, task-005 |
| task-012 | task-004, task-005, task-006 |
| task-014 | task-004, task-011, task-012 |

| Can Be Done In Parallel |
|------------------------|
| task-011, task-012 (file-disjoint: antigravity.toml/AGENTS.md · render_agents.py+RuleEntry reshape; task-012 also needs task-006 from delivery-002) |

### delivery-004: Setup options & all-5 non-regression
- **What it delivers:** `setup.sh` + `setup.ps1` extended (in lockstep parity) to offer Copilot CLI and Antigravity as selectable install targets with diff-aware copy semantics + the Option-A AGENTS.md multi-install collision handling; and the finalized all-5-profile non-regression gate (render-drift clean across 5; existing 3 byte-identical; generator self-tests + canonical suites green; actions SHA-pinned). Standalone value: both new providers become one-command installable and the whole pipeline is provably backward compatible.
- **Features:** feature-004-setup-and-nonregression
- **Depends on:** delivery-002, delivery-003
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-015 | task-004, task-009, task-010, task-011, task-014 |
| task-016 | task-004, task-009, task-010, task-011, task-014 |
| task-017 | task-010, task-014, task-015, task-016 |

| Can Be Done In Parallel |
|------------------------|
| task-015, task-016 (setup.sh · setup.ps1 — different files, lockstep-parity criterion in both) |

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | The F003→F002 edge is now **resolved by FR1 (delivery-001 complete)**: feature-003's `"antigravity-rule"` sub-agents→rules reshape (task-012) reuses the new-agent-format-branch mechanism feature-002's E1 introduces in `_render_agent_for_profile` (task-006). The skills→`.agent/skills/` half is independent `[data]` and creates no edge; the E2 route F003 originally would have reused is **deleted** (skills are native `[data]`), but the edge survives because it rides on E1's *format-branch machinery*, not E2. | If sequenced wrong, task-012 has no format-branch mechanism to reuse. | Keep delivery-003 dependent on delivery-002 (task-012 depends on task-006): E1's format-branch mechanism must exist before the `"antigravity-rule"` branch is added. This sequences FR2 before FR3 — inverting REQUIREMENTS §10's within-tier FR3-then-FR2 listing, which §10 licenses by delegating sequencing to /aid-plan; the two are a co-priority tier-2 set, not a hard order. |
| 2 | The "existing 3 (then 4) byte-identical" guarantee is a **continuous invariant**, not a final check — F002's engine addition (E1 `.agent.md` emitter + schema widening) could silently perturb the existing 3 trees, and F003's reshape (`antigravity-rule` branch + `RuleEntry.output_filename` touch) could perturb the existing 4. | A regression introduced in delivery-002/003 but only detected at delivery-004 would be expensive to localize. | Every profile delivery (002, 003) must pass the byte-identical gate as a merge precondition, not defer it to delivery-004. The mechanism is structurally continuous: the `render-drift` CI job re-renders and `git diff --exit-code -- profiles/` runs on every PR to master. Each addition is default-guarded (new `[agent].format` values select new branches only for the new profiles; `RuleEntry.output_filename` is unset for cursor) so the existing profiles are byte-identical by construction. delivery-004 *finalizes* the all-5 coverage; it does not own the invariant. |
| 3 | (Resolved by FR1.) The original Copilot E3 MCP-pass dual-list-wiring risk is **moot**: FR1 Q-B rules MCP `[omit]` (zero `mcp` matches in `canonical/` + `profiles/*.toml`), so no `render_mcp` pass is built and neither `run_generator.py`'s live-emit list nor `verify_deterministic._render_all` is touched. No new emitting pass is added by delivery-002 or delivery-003 (both reuse existing passes), so the two-pass-list drift never becomes a delivered gate blind spot. | none (no MCP pass shipped). | delivery-004's all-5 render-drift gate (NR1/NR2) remains the backstop for any unexpected `EXTRA`/missing file across all five profiles. |
