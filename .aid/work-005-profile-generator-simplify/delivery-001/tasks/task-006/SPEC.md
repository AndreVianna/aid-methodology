# task-006: Re-render profiles/* + dogfood .claude/ + EMISSION-MANIFEST

**Type:** MIGRATE

**Source:** work-005-profile-generator-simplify -> delivery-001

**Depends on:** task-005

**Scope:**
- Run the new copy-based generator (task-005's `render.py` via `run_generator.py`) and **commit the reshaped `profiles/*` output** trees (feature-002 Migration Plan — output-tree reshape only; install-time user-repo migration is delivery-002, out of scope).
- **Codex unify (FR2):** `profiles/codex/.agents/{skills,aid}` + `profiles/codex/.codex/agents/` → unified `profiles/codex/.codex/{agents, skills, aid}`; `.agents/` is retired.
- **Cursor / Antigravity rules outputs (FR3):** delete `profiles/cursor/.cursor/rules/` and `profiles/antigravity/.agent/rules/` outputs.
- **Antigravity agents (FR4 uniform markdown):** the 9 agent personas that were reshaped *into* `.agent/rules/` via the `antigravity-rule` branch now render as **uniform markdown agents under a NEW `.agent/agents/`** (not merely deleted) — the FR4-uniform-markdown change for antigravity.
- **Dogfood re-render:** re-render the repo's own `.claude/` tree so it is a **byte-twin** of `profiles/claude-code/.claude/` (the dogfood change here is the `canonical/aid/` reshape per A4 + any FR5 content edits; `.claude/` never had a rules output).
- **Update `canonical/EMISSION-MANIFEST.md`:** collapse the Codex split-layout column to a single `.codex/` root; update the per-emitter references to `render.py`. *(Note: there is no `rules` Asset-Kind row — rules ship via `[extras]`, not as an Asset Kind — so no Asset-Kinds row is dropped here.)*

**Acceptance Criteria:**
- [ ] All 5 tool trees render the uniform `{agents, skills, aid}` shape under their host-required root dir (AC1).
- [ ] No `rules/` output remains in any profile tree (`profiles/cursor/.cursor/rules/` and `profiles/antigravity/.agent/rules/` are gone).
- [ ] Codex `.agents/` is retired; Codex content is unified under `profiles/codex/.codex/{agents, skills, aid}` (FR2).
- [ ] Antigravity's agent personas render as uniform markdown under a new `profiles/antigravity/.agent/agents/`.
- [ ] The repo-root `.claude/` tree is byte-identical to `profiles/claude-code/.claude/`.
- [ ] Render-drift is clean: `git diff --exit-code -- profiles/` reports no drift after re-render + commit.
- [ ] The new emission manifest omits the retired paths (rules + the old `.agents/` split) — so delivery-002's prune has the correct target set.
- [ ] `canonical/EMISSION-MANIFEST.md` is updated (Codex split-layout column collapsed to single `.codex/`; per-emitter refs point to `render.py`).
- [ ] MIGRATE defaults: the reshape is reversible (recoverable from the committed prior trees / VCS); re-running the generator is idempotent (no further drift); data/content integrity verified (same canonical content provably present in each tree — AC1).
- [ ] All §6 quality gates pass.
