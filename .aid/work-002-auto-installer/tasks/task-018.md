# task-018: Normalize root `AGENTS.md` to byte-invariant across four profiles

**Type:** IMPLEMENT

**Source:** feature-006-invariant-agents-md → delivery-005

**Depends on:** — (none)

**Scope:**
- Edit line 16 only of the four hand-maintained root files — `profiles/codex/AGENTS.md`, `profiles/cursor/AGENTS.md`, `profiles/copilot-cli/AGENTS.md`, `profiles/antigravity/AGENTS.md` — replacing the per-tool install-root prefix with the tool-agnostic form from feature-006 §3 (`` `templates/reviewer-ledger-schema.md` (under this tool's install root). Write the ledger as a single ``), so all four become byte-identical (single sha256).
- Do NOT edit `run_generator.py`, any `render_*.py`, `rewrite_install_paths`, profile TOMLs, or `verify_deterministic.py` (the root files are hand-maintained, not generated — the pipeline is unchanged).
- Leave `profiles/claude-code/CLAUDE.md` unchanged (out of scope) and leave the in-tree install-rooted consumer references (produced by `rewrite_install_paths`) unchanged.
- Verify per §4: run `python run_generator.py` and confirm no render-drift / no change to `profiles/*/emission-manifest.jsonl` or the install trees, and confirm the safety check that the normalized token is not load-bearing (§5).

**Acceptance Criteria:**
- [ ] After the edit, `sha256sum profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md | awk '{print $1}' | sort -u | wc -l` prints `1` (byte-identical root `AGENTS.md` across all four profiles).
- [ ] `python run_generator.py` produces no render-drift and no change to `profiles/*/emission-manifest.jsonl` or the install trees; `run_generator.py`/render pipeline files are not edited.
- [ ] `profiles/claude-code/CLAUDE.md` and the in-tree install-rooted consumer references are unchanged; the normalized line-16 token is confirmed not load-bearing (no tooling parses it; the schema still ships at `<install-root>/templates/reviewer-ledger-schema.md` per tool).
- [ ] All §6 quality gates pass.
