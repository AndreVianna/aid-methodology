# task-021: glossary->spine content migration of AID's domain-glossary.md

**Type:** MIGRATE

**Source:** work-001-kb-skills-improvement -> delivery-003

**Depends on:** task-010 (delivery-001), task-018

**Scope:**
- Migrate AID's own existing `.aid/knowledge/domain-glossary.md` **content** into the f004
  concept-spine SHAPE (task-010 defines the spine STRUCTURE -- the concept-entries part with
  Term / Definition-as-used-here / Relates-to / per-concept `sources:`, plus retained lexicon
  tables). f004/task-010 owns the structure; this task moves AID's existing glossary content INTO it
  ([SPIKE-M4]: f003+f004 / task-010 land before this glossary step -- the spine structure must exist
  first; this dep is satisfied via `Depends on: task-010`).
- This is a **content migration, judgment-bearing, human-gated** -- NOT a mechanical field seed.
  Drive it as an `aid-update-kb`/`aid-discover` step through the review gate (the spine-shaping of the
  body is a human-confirmed authoring step; the script only seeds the doc-level frontmatter):
  1. **Promote load-bearing native concepts to concept entries.** The terms that are load-bearing
     native concepts (e.g. Phase Gate, Two-Tier Review, Pool Dispatch, canonical->render, Thin-Router)
     become structured concept entries (Term / Definition-as-used-here / Relates-to / per-concept
     `sources:`). Which terms are "load-bearing native concepts" is the same calibration f005 grades.
  2. **Retain the rest as lexicon tables** (f004's "term/definition tables (retained)") -- the
     vocabulary-but-not-load-bearing terms stay as scoped tables. **No term is lost** (f004's additive
     guarantee).
  3. **Seed the doc-level frontmatter via the same `migrate-kb-frontmatter.sh` pass** as every other
     doc (`objective`/`summary` from `intent:`; doc-level `sources:` = the union of the concept-level
     `sources:`, human-confirmed). This frontmatter run is folded into the dogfood corpus run
     (task-022) so `domain-glossary.md` is migrated like the other 15 docs; THIS task owns the BODY
     spine-shaping + the per-concept `sources:` anchors.
- **Backward-compat / no-loss check.** Every term present in the pre-migration glossary must be
  findable in the migrated doc (as a concept entry OR a lexicon-table row); no definition is dropped.
- **Boundary:** this task OWNS the BODY content migration (concept-promotion + lexicon retention +
  per-concept `sources:`) of AID's `domain-glossary.md`. It does NOT author the spine STRUCTURE / the
  template (f004, task-010), the migration script (task-018), the doc-level frontmatter seed mechanics
  (task-018; the corpus run that stamps it is task-022), the lint widen / AID-CI assertion (task-020),
  or the INDEX regen (task-022).

**Acceptance Criteria:**
- [ ] AID's `.aid/knowledge/domain-glossary.md` body is migrated into the f004 concept-spine shape:
  load-bearing native concepts are concept entries (Term / Definition-as-used-here / Relates-to /
  per-concept `sources:`); the remaining terms are retained as lexicon tables.
- [ ] No term from the pre-migration glossary is lost -- every prior term is present as a concept
  entry or a lexicon-table row (additive upgrade verified).
- [ ] Each promoted concept entry carries Definition-as-used-here (the AID-specific meaning, not a
  generic gloss), a Relates-to linkage, and per-concept `sources:` anchors.
- [ ] The migration is human-gated through the review gate (driven as an `aid-update-kb`/`aid-discover`
  step), not an unattended script edit -- the concept/lexicon split is human-confirmed.
- [ ] The doc-level `sources:` (set during the task-022 corpus run) equals the union of the
  concept-level `sources:` this task authors.
- [ ] Migration is reversible (the task-018 backup/`--rollback` covers the frontmatter; the body
  change is a tracked, reviewable commit), idempotent (re-running the corpus pass over the migrated
  doc is a no-op), and data integrity (no-term-lost) is verified.
- [ ] All section-6 quality gates pass.
