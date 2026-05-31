# task-011: Custom-doc owner resolution + agent-prompt extension + expectations entry

**Type:** IMPLEMENT

**Source:** feature-004-declared-doc-set → delivery-002 (DERIVATION wave)

**Depends on:** task-010, task-003

**Scope:**
- Implement custom-doc ownership: owner resolved via `owner-of <filename>`; if the owner is one of the 5 discovery agents, extend that agent's prompt in `references/agent-prompts.md` at runtime with "also produce `<filename>` per its expectations entry"; if no specialist fits ⇒ `discovery-architect` fallback (NO new agent).
- Add a `### repo-presentation.md` custom-doc section to `canonical/skills/aid-discover/references/document-expectations.md` (this repo's own custom doc) so the custom doc is reviewable — this consumes the F2 consolidated source (task-003).
- Confirm a custom doc appears in `list-filenames` (so the REVIEW artifact list includes it) and is generated AND reviewed end-to-end.
- Re-render with `python run_generator.py`.

**Acceptance Criteria:**
- [ ] A custom doc resolves to an existing agent (architect fallback when no specialist fits); that agent's prompt is extended to produce it; no new agent is added.
- [ ] A `### repo-presentation.md` expectations entry is present in `document-expectations.md`; the custom doc appears in `list-filenames` (generated AND reviewed).
- [ ] All §6 quality gates pass (render-drift clean, 13 suites green, generator self-tests).
