# task-003: Consolidate per-doc expectations + wire reviewer load-at-dispatch (both sites)

**Type:** IMPLEMENT

**Source:** feature-002-expectations-consolidation → delivery-001

**Depends on:** — (none)

**Scope:**
- Edit `canonical/` only, then re-render with `python run_generator.py`.
- **Edit 1** — `canonical/skills/aid-discover/references/document-expectations.md`: port the `### {reviewer_output_file}` block from `discovery-reviewer/AGENT.md` (~L269–277); keep the existing `### project-structure.md` / `### external-sources.md` blocks; no wording changes elsewhere; the canonical whitespace for `### {project_context_file}` wins (don't reintroduce the reviewer-side contiguous variant). This file becomes the single canonical superset.
- **Edit 2** — `canonical/agents/discovery-reviewer/AGENT.md`: delete the `## Document Expectations` section + per-doc blocks (~L196–290); replace with a short **count-agnostic** pointer (no "14"/"16") naming `document-expectations.md` and the dispatch-load mechanism; retarget the Completeness-Check pointer (~L106).
- **Edit 3** — `canonical/skills/aid-discover/references/reviewer-prompt.md`: add a `{{DOCUMENT_EXPECTATIONS}}` placeholder block (same paste model as `{{ARTIFACTS}}`).
- **Edit 4** — `canonical/skills/aid-discover/references/state-review.md` Step 1 (~L9–24): add the read-`document-expectations.md` + substitute-`{{DOCUMENT_EXPECTATIONS}}` instruction.
- **Edit 5 (REQUIRED)** — `canonical/skills/aid-discover/references/state-fix.md` Step 6 (~L102–112, after the L108 reviewer-prompt reuse): add the identical read+substitute instruction (FIX-mode re-review must also receive the expectations).

**Acceptance Criteria:**
- [ ] Per-doc `### *.md` blocks exist in exactly one canonical file (`document-expectations.md`); `discovery-reviewer/AGENT.md` keeps the heading but has 0 per-doc blocks; renders (incl. the codex `.toml`) dropped them.
- [ ] `document-expectations.md` is a superset: contains `### {reviewer_output_file}` AND retains `### project-structure.md` / `### external-sources.md`.
- [ ] `{{DOCUMENT_EXPECTATIONS}}` placeholder present in `reviewer-prompt.md`; the read+substitute instruction naming `document-expectations.md` is present in BOTH `state-review.md` and `state-fix.md`.
- [ ] The replacement pointer carries no "14"/"16" count literal.
- [ ] All §6 quality gates pass (generator self-tests, render-drift clean, 13 suites green).
