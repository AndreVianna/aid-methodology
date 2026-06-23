# task-050: KB-doc skill-count reconciliation + INDEX regen + doc-narrative surfaces

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-008

**Depends on:** task-049

**Scope:**
- f009 Part 3 (S5/S6/S11, AC12, C7) -- the `adding-skill-kb-count-drift` hazard (Q26/Q30
  precedent). kb-hygiene CI does NOT assert the skill count, so this is a **correctness obligation
  enforced by exhaustive enumeration**, not a CI gate. Net change, **per population so no surface
  gets a wrong number**: **user-facing 12 -> 13**, **maintainer-inclusive total 13 -> 14**,
  **`canonical/skills/` dir count 12 -> 13**, **optional 5 -> 6**; rename `aid-ask` ->
  `aid-query-kb` in every enumeration; add `aid-update-kb` as a new optional off-pipeline
  maintenance skill. Change-Log/history/cycle-log lines are **append-only** (add a dated entry;
  never rewrite a past cycle's recorded count).
- **KB docs (Part 3 rows 1-9, exact lines in the f009 SPEC):**
  `architecture.md` (note l.69 "12 skill dirs" takes the **canonical-dir 13**, NOT 14; l.194
  maintainer-inclusive becomes 14; rename + add `aid-update-kb` rows in the optional list + the
  `### Skill inventory` table; l.442 end-user-runtime note gains the new skills),
  `module-map.md` (per-population bumps; rename the `aid-ask` module; add an `aid-update-kb`
  thin-router module row), `feature-inventory.md` (rename row 12; add a `/aid-update-kb` row),
  `pipeline-contracts.md` (rename the `/aid-ask` contract block noting gap-capture write-scope; add
  a `/aid-update-kb` contract block), `repo-presentation.md`, `integration-map.md`,
  `coding-standards.md` (l.460 thin-router-line-count assertion -> 13; confirm
  `aid-update-kb`'s SKILL.md fits the thin-router line threshold), `domain-glossary.md` (add
  `aid-update-kb` + a glossary term if f008 coined one for targeted-update), `project-structure.md`.
- **Append-only history rows (Part 3 rows 10, 11, 13):** `README.md` (KB) -- append a new cycle
  entry for the f008/f009 rename+add (12->13 user-facing), do NOT rewrite past rows;
  `release-tracking.md` l.66 -- leave the historical "11 user-facing skills" snapshot as-is, add
  the rename+add to the Unreleased section; `.aid/knowledge/STATE.md` -- append a Q&A/cycle row
  noting the reconciliation + the f008-RED -> f009-green hand-off (tracking discipline).
- **INDEX regen (Part 3 row 12, S6):** regenerate via
  `canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge` (the `index-md-canonical-regen`
  memory: use the `canonical/` script path, NOT the `.claude/` copy, or kb-hygiene fails on the
  embedded path). No skill-name edit -- INDEX is keyed on doc frontmatter.
- **Doc-narrative surfaces (S11) -- non-KB, non-generated prose:** `README.md` (root, l.58 `*12
  skills*`, l.157, l.194 `/aid-ask`), `docs/aid-methodology.md` (l.71/85/100/842),
  `docs/glossary.md` (l.9, l.70 "12th user-facing skill") and their site mirrors
  `site/src/content/docs/concepts/methodology.md` (l.75/89/104/846) +
  `site/src/content/docs/reference/glossary.md` (l.13/74): 12->13 / "Twelve"->"Thirteen"; rename
  `aid-ask`->`aid-query-kb`; add `aid-update-kb` to the tables/glossary; the "12th user-facing
  skill" def becomes `aid-query-kb` + add a new `aid-update-kb` def. **Edit both halves of each
  mirror pair in lockstep** (or confirm source-vs-mirror direction; the residual SPIKE-D detail) --
  the `stale-version-vs-version-sync` blind-spot class.
- **Out of scope here:** the built `.aid/dashboard/kb.html` + `summary-src/sections/*.html`
  (task-051); the docs-site `gen-reference.mjs` + `skills.md` + dogfood (task-052).

**Acceptance Criteria:**
- [ ] `grep -rn 'aid-ask' .aid/knowledge/` returns only append-only history lines (no live
  reference); `grep -rn 'user-facing skill' .aid/knowledge/` shows 13 everywhere (no stale 12).
- [ ] `grep -rniE 'five optional|5 optional' .aid/knowledge/` returns no stale live count (the
  optional-skill count was bumped 5 -> 6 with `aid-update-kb` added; live surfaces in
  `architecture.md`/`repo-presentation.md` now read "six optional"/"6 optional", append-only history
  excepted) -- a count-only surface that carries no `aid-ask`/`12 skills` token, so neither the
  `aid-ask` nor the `user-facing skill` grep catches it.
- [ ] Each Part-3 KB doc (rows 1-9) carries the correct count for ITS population (user-facing 13 /
  canonical-dir 13 / maintainer-inclusive 14 / optional 6), the `aid-ask`->`aid-query-kb` rename,
  AND a new `aid-update-kb` row in every prose enumeration/inventory table (not just a number bump).
- [ ] Change-Log/history/cycle-log lines are appended (dated), never rewritten; `README.md` (KB)
  gains a new cycle entry; `release-tracking.md` Unreleased gains the rename+add with its l.66
  historical snapshot untouched; `.aid/knowledge/STATE.md` records the reconciliation + RED->green
  hand-off.
- [ ] `INDEX.md` regenerated via `canonical/aid/scripts/kb/build-kb-index.sh` and matches committed
  (kb-hygiene INDEX-fresh check passes); regenerated with the `canonical/` script path, not `.claude/`.
- [ ] All S11 narrative surfaces reconciled (root README, docs/*, both site mirrors): no stale
  `12 user-facing`/`12 skills`/`Twelve`, no live `aid-ask`, `aid-update-kb` added; each mirror pair
  edited in lockstep (or source/mirror direction confirmed and applied).
- [ ] `grep -rn "aid-ask\|12 user-facing\|12 skills\|Twelve" README.md docs/ site/src/content/`
  returns no stale count and no live `aid-ask` (append-only history excepted).
- [ ] All section-6 quality gates pass.
