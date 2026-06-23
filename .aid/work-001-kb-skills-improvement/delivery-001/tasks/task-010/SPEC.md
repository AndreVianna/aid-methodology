# task-010: concept-spine upgrade of domain-glossary.md + discovery.closure settings block

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-001, task-004

**Scope:**
- Upgrade `canonical/aid/templates/knowledge-base/domain-glossary.md` from a flat glossary into the
  concept spine (the C4-Vocabulary concern doc f003 designates as the spine; the FR-31 persisted,
  first-class artifact). Add the concept-entries part: per native concept, an entry with Term /
  Definition-as-used-here (the project-specific meaning, NOT generic) / Relates-to (cross-concept
  linkage -- the backbone) / per-concept `sources:` (inline path+symbol anchors). RETAIN the existing
  term/definition lexicon tables (no term lost; the upgrade is additive). The doc-level frontmatter
  carries f001's fields (`objective`/`summary`/`sources`/`tags`); its `sources:` is the union of the
  concept-level sources. (f001 owns the schema; f011 migrates AID's own glossary.)
- Add the new TOP-LEVEL `discovery:` block to `canonical/aid/templates/settings.yml` (the template
  has no `discovery:` key today) with its `closure:` child: `max_clean_passes: 2`, `max_rounds: 4`,
  `token_budget: 0`, with defaults + comments. `doc_set` is NOT added (it stays a conditional
  runtime-written sibling written by Step 0d).
- Edit canonical only; re-run `run_generator.py`; commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `domain-glossary.md` carries the concept-entries structure (Term / Definition-as-used-here /
  Relates-to / per-concept `sources:`) AND retains the existing lexicon tables; no term is lost.
- [ ] The doc-level frontmatter carries `objective`/`summary`/`sources`/`tags`; the doc-level
  `sources:` is the union of the concept-level sources.
- [ ] `settings.yml` gains a new top-level `discovery:` block with a `closure:` child
  (`max_clean_passes: 2` / `max_rounds: 4` / `token_budget: 0`) plus defaults and comments;
  `doc_set` is NOT added.
- [ ] `read-setting.sh` 2-level resolution is not relied upon for the 3-level closure keys (the
  block is documented as defaults consumed via the Step 5b cap-override interface, task-011).
- [ ] `run_generator.py` re-run; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
