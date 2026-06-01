# task-002: Confirm Google Antigravity conventions vs current docs

**Type:** RESEARCH

**Source:** feature-001-provider-research → delivery-001

**Depends on:** — (none)

**Scope:**
- Fetch the *current* Google Antigravity vendor docs via Context7 / web fetch — not training data — and confirm/correct the conventions seeded in REQUIREMENTS §2/§8. Each load-bearing claim carries a doc URL + access date.
- Produce raw findings (not the final mapping doc) covering:
  - **Rules:** `.agent/rules/*.md` (project) + `~/.gemini/…` (global) — confirm path, file shape, and frontmatter (if any).
  - **Slash-workflows:** `.agent/workflows/*.md` — confirm slash-invocation (e.g. `/generate-unit-tests`) and file shape.
  - **Context/instructions file (Q-H input):** evidence for which file Antigravity actually reads — `AGENTS.md` vs `GEMINI.md` — and whether both are read with one canonical. Capture enough to let the synthesis (task-004 Q-H ruling) commit to a single value.
  - **Rule-file extension (Q-I input):** whether Antigravity consumes Cursor-style `.mdc` rule files verbatim or requires a `.md` variant. Capture sourced evidence for the binary ruling in task-004 (Q-I).
  - **"Antigravity ≈ Cursor" assumption (REQUIREMENTS §8):** validate or correct it against the docs.
  - **Custom sub-agent file:** confirm whether Antigravity has any native custom sub-agent file convention (expected: none — customization is rules + workflows).
- Capture the cross-kind evidence the Q-D ruling (task-004) needs: whether Antigravity rules/workflows are plain markdown in renamed dirs with the same body and thin/absent frontmatter (would support `[data]`), or whether sub-agents would have to be transformed into a different artifact shape to live as rules (would support `[transform:engine]`). Note the existing Cursor profile does NOT derive `.mdc` rules from `canonical/agents/` (they come from `[[extras.rules]]` + `canonical/rules/`), so Antigravity sub-agents→rules is a genuinely new question.
- Capture the data needed for downstream FR1 Q-E/Q-F/Q-G rulings (Antigravity / Gemini-lineage model strings per tier; tool-name remaps — confirm Bash→Terminal etc.; documented support for `hooks` / `skill_chaining` / `background_execution` / `stop_hook_autocontinue`), each sourced. For Q-E specifically, capture not just the model strings per tier alias but the **evidence of the model-tier form** — whether Antigravity / Gemini-lineage exposes only a plain `tier = "model-string"` (simple form) or also a reasoning-effort/detailed knob (`[model_tiers.<tier>]` with `model` + `reasoning_effort`) — so the synthesis (task-004) can state the simple-vs-detailed form per SPEC Q-E without inferring from incomplete evidence.
- Do NOT write `provider-mapping.md`, any profile TOML, renderer code, or disposition tags — this task only gathers and sources Antigravity facts for the synthesis tasks (task-003, task-004).

**Acceptance Criteria:**
- [ ] Antigravity rules (`.agent/rules/`) and slash-workflows (`.agent/workflows/`) conventions confirmed/corrected against current docs, each sourced.
- [ ] Context-file evidence captured for `AGENTS.md` vs `GEMINI.md` (Q-H) — sufficient to support a single definite pick in task-004.
- [ ] Rule-file extension evidence captured for `.mdc` vs `.md` (Q-I) — sufficient for a binary ruling in task-004.
- [ ] "Antigravity ≈ Cursor" assumption validated or corrected, sourced.
- [ ] Native custom sub-agent file existence explicitly confirmed (present or absent), sourced.
- [ ] Cross-kind evidence captured (rules/workflows body+frontmatter shape) sufficient for task-004 to rule Q-D `[data]` vs `[transform:engine]`.
- [ ] Raw inputs for Antigravity Q-E (model strings per tier alias **and** the model-tier form evidence: whether a reasoning-effort/detailed-form knob exists vs simple `tier = "model-string"` only), Q-F (tool-name remaps), and Q-G (all 4 capability flags) captured with sources, sufficient for the synthesis (task-004) to state the simple-vs-detailed `[model_tiers]` form.
- [ ] At least 2 alternatives compared where applicable (AGENTS.md vs GEMINI.md; sub-agents→rules vs sub-agents→workflows; `.mdc` vs `.md`), sources cited, with an actionable handoff for the synthesis tasks (task-003/task-004).
- [ ] All §6 quality gates pass (no invented/faked conventions; claims tied to current documented sources).
