# task-016: Reference generator — `gen-reference.mjs` + generated reference pages

**Type:** IMPLEMENT

**Source:** feature-006-concepts-and-reference → delivery-003

**Depends on:** task-014

**Scope:**
- Author `site/scripts/gen-reference.mjs` (Node stdlib ESM, manifest-driven, deterministic, D4/D5/D7) generating four committed pages under `site/src/content/docs/reference/`:
  - `skills.md` from `canonical/skills/*/SKILL.md` (frontmatter `name` + `description` + source path; 11 rows).
  - `agents.md` from `canonical/agents/*/AGENT.md` (`name`/`description`/`tier`/`tools` + source path; 9 rows).
  - `kb.md` from `canonical/templates/knowledge-base/*.md` (excl. `README.md`; filename + leading H1/first line; 14 rows).
  - `settings.md` from `.aid/settings.yml` (key path, value, inline `#`-comment description).
- Each page gets injected frontmatter (`title`/`description`/`generatedFrom`) and a deterministic Markdown table; ship full tables, not stubs (D6).
- Emit `site/scripts/.reference-manifest.json` (outside the collection root).
- Add `gen:reference` to `package.json` and CHAIN the pre-step with feature-005's `sync:docs` into one `predev`/`prebuild` line (`sync:docs && gen:reference`, A4). Commit the generated pages + manifest.

**Acceptance Criteria:**
- [ ] `gen-reference.mjs` is deterministic and manifest-driven; re-run yields byte-identical output.
- [ ] `skills.md`/`agents.md`/`kb.md`/`settings.md` are generated as full tables with `generatedFrom` frontmatter; counts match source (11 skills, 9 agents, 14 KB doc-types).
- [ ] `.reference-manifest.json` is emitted outside the collection root; generated pages + manifest are committed.
- [ ] `predev`/`prebuild` is a single chained `sync:docs && gen:reference` line (no conflicting key definitions).
- [ ] Unit tests cover field extraction for each source type and table determinism; build passes; existing tests still pass.
- [ ] All §6 quality gates pass.
