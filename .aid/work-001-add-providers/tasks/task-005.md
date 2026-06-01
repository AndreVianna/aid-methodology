# task-005: Widen aid_profile.py — register the Copilot `agent.format` value

**Type:** IMPLEMENT

**Source:** feature-002-copilot-cli → delivery-002

**Depends on:** task-004

**Scope:**
- Widen the profile schema/validator in `/home/andre.vianna/projects/AID/.claude/skills/aid-generate/scripts/aid_profile.py` so the E1 `.agent.md` emitter (task-006) can be selected as pure data. This is the ONLY schema knob delivery-002 needs after the FR1 loopback — E2 (skills→agent) and E3 (MCP) are dropped (FR1 Q-A: skills are native `[data]`; FR1 Q-B: MCP `[omit]`), so there is **no** `[skill].emit_as` knob and **no** MCP table here. This task adds only the agent-format enum value (no emitter behavior) so it lands first and task-006 edits `render_agents.py` after it — per SPEC §"Schema/validator widening (`aid_profile.py`) required by E1".
- **E1 knob — agent format enum:** add `"copilot-agent"` (FR1 Q-A, SPEC §E1) to `_KNOWN_AGENT_FORMATS` (`aid_profile.py:334`, currently `{"markdown", "toml"}`). The exact label is pinned by `provider-mapping.md` Q-A (`"copilot-agent"`); do NOT invent it. There is **no** `agent_suffix` key — the `.agent.md` vs `.md` suffix is a property of the format branch (bound in E1/task-006), NOT a data key. The `validate` agent-format check (lines 394-398) must accept `"copilot-agent"` and still reject any unknown format with a clear message.
- **No `[skill].emit_as` knob** (E2 dropped per Q-A — skills are native Agent Skills emitted as folders by the existing `render_skills` pass, pure `[data]`). **No MCP table** added to the `Profile` dataclass (E3 dropped per Q-B — `grep -ri mcp canonical/ profiles/*.toml` returns zero matches; nothing to emit). State in this task's notes that both knobs are intentionally absent per the Q-A / Q-B rulings.
- The edit is **additive and default-preserving**: the 3 existing profiles (claude-code, codex, cursor) set no new key, so they parse and validate exactly as before. Do NOT touch any render_*.py, run_generator.py, profiles/*.toml, or setup scripts.

**Acceptance Criteria:**
- [ ] `_KNOWN_AGENT_FORMATS` includes `"copilot-agent"` (FR1 Q-A); `validate` accepts a profile with `agent.format = "copilot-agent"` and still rejects an unknown format value with a clear message.
- [ ] **No** `[skill].emit_as` schema knob is added (E2 dropped, Q-A); **no** MCP table/parser/validator is added to `Profile` (E3 dropped, Q-B). Both omissions are documented as deliberate, sourced to the Q-A / Q-B rulings in `provider-mapping.md`.
- [ ] The 3 existing profiles (claude-code, codex, cursor) still load and `validate` clean with zero errors (defaults unchanged) — verified by `python .claude/skills/aid-generate/scripts/aid_profile.py --profile profiles/<name>.toml` for each.
- [ ] Unit tests for the new validation path (a profile with `agent.format = "copilot-agent"` passes; an unknown `agent.format` is rejected; the existing 3 still validate clean). All existing tests still pass; build passes.
- [ ] All §6 quality gates pass (stdlib-only, backward compatible by construction, convention-over-infrastructure: the format value is data, no new engine framework).
