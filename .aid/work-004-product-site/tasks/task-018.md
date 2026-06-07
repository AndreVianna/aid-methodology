# task-018: Verify Concepts & Reference — render, reference drift-check, links

**Type:** TEST

**Source:** feature-006-concepts-and-reference → delivery-003

**Depends on:** task-017

**Scope:**
- Verify the Concepts section renders the full methodology (all themes) + FAQ and the Reference section renders CLI, settings keys, artifacts, repository structure, glossary, and the generated Skills/Agents/KB roster pages (FR8/FR9, AC3, AC6).
- Verify the generated roster is accurate to source: counts and names match `canonical/skills/`, `canonical/agents/`, `canonical/templates/knowledge-base/`, and `.aid/settings.yml` keys (AC6).
- Verify the reference drift-check: run `npm run gen:reference` then `git diff --exit-code` over the four generated reference pages + `.reference-manifest.json` yields no diff.
- Run the internal link/anchor checker over the new authored + generated pages and confirm all internal links resolve, including `reference/cli` → `guides/installation` (AC5).

**Acceptance Criteria:**
- [ ] Concepts (methodology + FAQ) and Reference (CLI, settings, artifacts, repo-structure, glossary, skills/agents/kb) all present and navigable (AC3, FR8/FR9).
- [ ] Generated roster counts/names match source (11/9/14 + current settings keys) (AC6).
- [ ] Fresh `gen:reference` + `git diff --exit-code` yields no diff.
- [ ] Internal link/anchor check passes for all new pages.
- [ ] Tests are deterministic with clean setup/teardown; all feature-006 acceptance criteria covered.
- [ ] All §6 quality gates pass.
