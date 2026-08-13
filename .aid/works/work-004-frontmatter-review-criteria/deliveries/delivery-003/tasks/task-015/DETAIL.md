# task-015: The single render — both chains, once, plus byte-identity verify

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-003

**Depends on:** task-013, task-014

**Scope:**
- Run the **single render** of both derived chains **exactly once** (C-2 / NFR-4), after all source
  edits across the whole work are complete (delivery-001, delivery-002, task-013, task-014):
  - `canonical/` → `profiles/` → the two tracked dogfood trees, via
    `.claude/skills/generate-profile/scripts/run_generator.py` (full run, never a partial render), then
    resync the dogfood trees;
  - the site chain — `site/src/content/docs` and `site/src/data/skill-flows/*.flow.json` (76,
    incl. `aid-execute.flow.json` which now embeds the corrected `state-execute.md` pointer),
    **regenerated**, never hand-edited.
- Verify `tests/canonical/test-dogfood-byte-identity.sh` passes against the result.

**Acceptance Criteria:**
- [ ] Both chains refreshed exactly once; the generator is run in full, not partially.
- [ ] `test-dogfood-byte-identity.sh` passes against the rendered trees.
- [ ] `render.py`'s `review-criteria` carry-through is visible in the rendered `profiles/` agent files.
- [ ] The site flow sidecars are regenerated (not hand-edited); `aid-execute.flow.json` reflects the
      relocated `aid-clerk` contract.
- [ ] All §6 quality gates pass.
