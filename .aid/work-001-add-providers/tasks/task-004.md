# task-004: Complete provider-mapping.md — Q-A..Q-J rulings + FR1 Deliverable Contract crosswalk

**Type:** RESEARCH

**Source:** feature-001-provider-research → delivery-001

**Depends on:** task-003

**Scope:**
- Complete the SAME findings document `/home/andre.vianna/projects/AID/.aid/work-001-add-providers/research/provider-mapping.md` authored in task-003 (do NOT create a new file). This task adds the definitive Key-Question rulings and the FR1 Deliverable Contract crosswalk on top of task-003's convention sections + mapping table, using the task-001/task-002 evidence and the dispositioned cells task-003 produced.
- **Answer every Key Question Q-A through Q-J** with a definite ruling (or `docs-only-noted` with the residual gap stated), per SPEC §"Key Questions the Mapping MUST Answer":
  - Q-A: exact `.agent.md` frontmatter key set/order AID emits + how invoked + the **exact new `agent.format` enum label string** (e.g. `copilot-agent`) feature-002 will set; skills→`.agent.md` disposition.
  - Q-B: definite Copilot MCP emit/omit ruling (+ location if emit), with justification.
  - Q-C: concrete referenced scripts/templates home for **each** tool, confirmed reachable via `[layout]` dirs alone (`[data]`).
  - Q-D: Antigravity sub-agents→rules / skills→workflows `[data]` vs `[transform:engine]` ruling + the explicit resulting feature-003→feature-002 dependency-edge statement.
  - Q-E: `[model_tiers]` strings for **each** tier alias `_resolve_model` resolves, **per tool**, with the **simple-vs-detailed form explicitly stated** (using the model-tier form evidence gathered in task-001/task-002), each value sourced.
  - Q-F: complete `[tool_names]` key→value map (or explicit empty-map ruling) **per tool**, sourced.
  - Q-G: verified true/false for all 4 `CapabilitiesConfig` flags (`hooks`, `skill_chaining`, `background_execution`, `stop_hook_autocontinue`) **per tool**, each sourced.
  - Q-H: single definite `[layout].project_context_file` value (AGENTS.md *or* GEMINI.md) for Antigravity, with doc evidence.
  - Q-I: exact Antigravity rule-file extension ruling (`.mdc` *or* `.md`) → the `[[extras.rules]].filename` extension, with doc evidence.
  - Q-J: context-file production convention ruling — each new provider's `project_context_file` is a committed profile-local file authored from the shared ~27-line template (NOT rendered from canonical, NOT in any `emission-manifest.jsonl`); record the verified ground truth and the OOS/byte-identical-gate rationale + ratifiable-emitter note.
- **Cross-walk the full 14-row FR1 Deliverable Contract table** (SPEC §"FR1 Deliverable Contract"): produce a definite value/ruling for every `[FR1-owned]` row so a downstream implementer can populate every `[FR1-owned]` cell in `profiles/copilot-cli.toml` and `profiles/antigravity.toml` (and scope every named engine extension) from this doc alone. All 14 rows: Copilot `.agent.md` frontmatter shape, new `agent.format` enum label, Copilot `[model_tiers]`, Antigravity `[model_tiers]`, Copilot `[tool_names]`, Antigravity `[tool_names]`, Copilot `[capabilities]`, Antigravity `[capabilities]`, Antigravity `project_context_file` (Q-H), Antigravity rule-file extension (Q-I), Copilot MCP emit/omit (Q-B), scripts/templates home both tools (Q-C), Antigravity cross-kind ruling + dependency edge (Q-D), context-file production convention (Q-J). No marker left uncrossed; no "TBD".
- Ensure the rulings fully preserve the coverage the original single synthesis task required — every `[FR1-owned]` value and every Q-A..Q-J ruling is present, none dropped in the task-003/task-004 split.
- Record the colleague's-fork status explicitly in the doc (proceeded docs-only, per STATE.md Q1) if task-003 did not already; do not duplicate the upstream gather criterion — task-001 owns the fork-status gather, this task ensures the deliverable doc states it.
- Do NOT write any `profiles/*.toml`, renderer code, or setup-script change (OOS — feature-002/003/004). This task only decides and documents in `provider-mapping.md`.

**Acceptance Criteria:**
- [ ] Q-A through Q-J are each answered in `provider-mapping.md` with a definite ruling (or explicitly `docs-only-noted` with the residual gap stated); Q-D states the feature-003→feature-002 dependency edge; Q-J states the context-file production convention with ground truth + OOS/byte-identical-gate rationale + ratifiable-emitter note.
- [ ] Every `[FR1-owned]` row in the 14-row FR1 Deliverable Contract has a definite value/ruling (no "TBD"): `[model_tiers]` per tier alias per tool (simple-vs-detailed form stated, sourced); `[tool_names]` complete map or empty-map ruling per tool; `[capabilities]` all 4 flags per tool (sourced); Antigravity `project_context_file` single value; Antigravity rule-file extension; new `agent.format` enum label + frontmatter key set/order; Copilot MCP emit/omit ruling; scripts/templates home per tool; Antigravity cross-kind ruling + dependency edge; context-file production convention.
- [ ] The split preserves full coverage — no `[FR1-owned]` value or Q-A..Q-J ruling that the original single synthesis task carried is dropped (verified by self-check against the FR1 Deliverable Contract table and the SPEC §"Acceptance / Done" itemized checklist).
- [ ] A downstream implementer can build `profiles/copilot-cli.toml` and `profiles/antigravity.toml` (plus any named engine extension) from this doc alone, without re-researching either tool — verified by self-check against the SPEC §"Acceptance / Done" itemized checklist.
- [ ] At least 2 alternatives compared where applicable (the disposition rulings are alternative-bearing; e.g. Q-B emit-vs-omit, Q-D data-vs-engine, Q-H/Q-I binary picks), sources cited, with an actionable recommendation per ruling.
- [ ] All §6 quality gates pass (no invented/faked primitives; backward-compat and convention-over-infrastructure rulings respected; OOS boundary held — no profile/renderer/setup changes).
