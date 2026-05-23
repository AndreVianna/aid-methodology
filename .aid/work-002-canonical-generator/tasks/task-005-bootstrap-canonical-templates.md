# task-005: Bootstrap `canonical/templates/` from the root `templates/` tree

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/templates/` at the repo root.
- Promote the existing root `templates/` tree into `canonical/templates/`. The root `templates/` directory is already format-agnostic (SPEC Migration Plan §1; module-map.md Module 4); the three install trees today carry hand-maintained copies of it (the 4-way duplication that produces the ~17,600-line H4 duplication count).
- Preserve the existing internal structure verbatim:
  - `canonical/templates/knowledge-base/*.md` (the 16 KB templates).
  - `canonical/templates/requirements/`, `canonical/templates/specs/`, `canonical/templates/delivery-plans/`, `canonical/templates/reports/`, `canonical/templates/feedback-artifacts/`, `canonical/templates/scripts/`, `canonical/templates/knowledge-summary/` (the latter is the asset bundle for `aid-summarize`).
  - Top-level `canonical/templates/README.md`, `canonical/templates/grading-rubric.md`, etc.
- Use `git mv` so the file history is preserved for downstream `git log --follow` queries.
- Do NOT touch the duplicated copies inside `claude-code/.claude/templates/`, `codex/.agents/templates/`, `cursor/.cursor/templates/` in this task. The template renderer (task-021) will eventually re-emit them from `canonical/templates/`; this task only authors the canonical source.
- Cross-check that the move preserves byte-identity: a `diff -r templates/ canonical/templates/` after the move should be empty (or the move itself trivially confirms it).
- If any KB template carries a tool-specific assumption (e.g. mentions `CLAUDE.md` vs `AGENTS.md` literally), flag it for the renderer to substitute — these go through the same `filename_map` mechanism declared in task-004. Spot-check at least `templates/knowledge-base/INDEX.md`, `templates/requirements/requirements-template.md`, `templates/delivery-plans/task-template.md` for such literals; substitute placeholders where found.

**Acceptance Criteria:**
- [ ] `canonical/templates/` exists with the same subtree as the current root `templates/` (file count and total LOC match within ±1% — any tiny delta justified in the task's execution record).
- [ ] `git log --follow canonical/templates/knowledge-base/module-map.md` shows the history continuous with the previous `templates/knowledge-base/module-map.md` location (preserving `git mv`).
- [ ] Any literal `CLAUDE.md` / `AGENTS.md` / `DISCOVERY-STATE.md` substrings inside KB templates have been replaced with `{project_context_file}` / `{reviewer_output_file}` placeholders where they refer to the per-tool file (NOT where they refer to the methodology artifact's own canonical name).
- [ ] No production install tree is touched in this task — the three `*/templates/` duplicates remain on disk for now (the renderer in task-021 will re-emit them).
