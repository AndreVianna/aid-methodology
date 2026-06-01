# task-003: Author provider-mapping.md core — per-tool convention sections + the mapping table

**Type:** RESEARCH

**Source:** feature-001-provider-research → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Create and author the **core** of the single findings document `/home/andre.vianna/projects/AID/.aid/work-001-add-providers/research/provider-mapping.md` from the task-001 (Copilot CLI) and task-002 (Antigravity) findings, in the shape required by SPEC §"Required shape of `provider-mapping.md`". One file, not per-tool files. This task authors the per-tool convention sections + the mapping table; task-004 completes the SAME file with the Q-A..Q-J rulings and the FR1 Deliverable Contract crosswalk.
- Write **per-tool convention sections** (Copilot CLI, Antigravity), each with a source reference on every load-bearing claim (URL + access date, or fork path) — folding in task-001/task-002 findings: agent/instruction file conventions, instructions/context options, MCP config location, workflow/slash primitive, install/CLI surface.
- Write the **mapping table** — one row per AID primitive (sub-agent, skill, helper script, template, recipe, context/instructions file, MCP — all 7), plus the profile-config rows (`[model_tiers]`, `[tool_names]`, `[capabilities]`, rule-file extension, `agent.format` label — 5 rows), with a Copilot CLI column, an Antigravity column, and a disposition column. Every cell is a concrete value/path/ruling — never "TBD".
- **Tag every cell** with exactly one disposition: `[data]` (expressible by a new `profiles/<tool>.toml` + existing renderer passes — name the profile TOML key), `[transform:engine]` (needs new renderer code — name the specific renderer gap from SPEC §Renderer validation: closed agent-format enum in `aid_profile.py` `_KNOWN_AGENT_FORMATS`, fixed per-kind passes / no cross-kind routing, no MCP emitter, or profile-schema gap), or `[omit]` (no home — state what is dropped and why it is safe). Apply the SPEC agent-frontmatter rule: any Copilot `.agent.md` frontmatter beyond the hardcoded `name/description/tools/model` (+ `permissionMode`/`background`) set is `[transform:engine]`, never `[data]`.
- The mapping-table cells must be self-consistent with (and not contradict) the definitive Q-A..Q-J rulings task-004 will add to the same file; this task supplies the concrete per-cell value/disposition, task-004 supplies the prose ruling + crosswalk. Do NOT drop any `[FR1-owned]` value or disposition that the FR1 Deliverable Contract or Key Questions require a cell for — the table must already carry the per-tool `[model_tiers]`, `[tool_names]`, `[capabilities]`, rule-extension, `agent.format`, context-file, and MCP cells so task-004 can crosswalk them.
- Do NOT write any `profiles/*.toml`, renderer code, or setup-script change (OOS — feature-002/003/004). Do NOT author the Q-A..Q-J rulings prose or the FR1 Deliverable Contract crosswalk — those are task-004. This task only authors the convention sections and the dispositioned mapping table.

**Acceptance Criteria:**
- [ ] `provider-mapping.md` exists at the specified path with both per-tool convention sections (each load-bearing claim sourced: URL + access date, or fork path) and the cross-tool mapping table (all 7 AID-primitive rows + the 5 profile-config rows × both tools).
- [ ] Every mapping cell is tagged `[data]` | `[transform:engine]` | `[omit]` with no untagged cell and no faked primitive; every `[transform:engine]` cell names the specific renderer constraint it violates; every `[data]` cell names the profile TOML key that expresses it.
- [ ] The mapping table carries a concrete cell (value/path/ruling, never "TBD") for every AID primitive and every profile-config row the FR1 Deliverable Contract / Key Questions reference, so task-004 can crosswalk each `[FR1-owned]` item without re-deriving it.
- [ ] At least 2 alternatives compared where applicable (the disposition tags themselves are alternative-bearing; e.g. skills→agent vs skills→instructions home, repo vs user-home MCP location), sources cited, with an actionable recommendation per cell.
- [ ] All §6 quality gates pass (no invented/faked primitives; convention-over-infrastructure rulings respected; OOS boundary held — no profile/renderer/setup changes).
