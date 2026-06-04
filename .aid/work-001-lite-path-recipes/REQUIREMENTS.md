# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-03 | Initial interview started | /aid-interview |
| 2026-06-03 | Interview restarted — escalated from lite path (LITE-FEATURE) | /aid-interview escalation |
| 2026-06-03 | KB hydration assessed — no current-state additions (taxonomy change is a deliverable; KB update deferred to execution per §9 AC) | /aid-interview |
| 2026-06-03 | Interview complete — approved | /aid-interview |
| 2026-06-03 | Cross-reference fixes — removed fictional `new-report`, named 5 install trees, context-aware AC1 grep, distributed AC6 KB ownership (grade D→A+) | /aid-interview (cross-reference) |

## 1. Objective

> Partial — seeded from lite-path escalation. To be deepened in the full interview.

Lite-path title: **add-lite-recipes**. Restructure the AID **lite-path taxonomy** and
author a broad **recipe catalog** derived from it. Escalated to full path — see
`design-notes.md` for the complete running design.

Concretely:
- Collapse the lite work-types from 4 → **3 internal ids**: `bug-fix` (unchanged value),
  `new-feature` (was `small-new-feature`), `refactor` (was `small-refactor`); eliminate
  `single-doc` (docs & reports fold into add/change).
- Make work-types **internal only** — TRIAGE infers the type from a free-form work
  description instead of a menu.
- Author a **~51-recipe** catalog (breadth-first; merge by similarity later).

## 2. Problem Statement

> Partial — captured before escalation.

The lite path's TRIAGE currently asks a fixed type menu (T3) and ships only one recipe
per work-type (5 total). This (a) forces users to self-classify their work into AID's
internal taxonomy, and (b) leaves most common small jobs falling through to the condensed
interview because no recipe matches. The taxonomy names are also imperfect: `refactor`
conventionally implies behaviour-preserving change but is used here for behaviour-changing
work, and `single-doc` is an awkward catch-all that overlaps with add/change-documentation work.

## 3. Users & Stakeholders

- **AID adopters** running the lite path — primary beneficiaries (faster, recipe-driven
  small work; no need to self-classify into AID's internal taxonomy).
- **AID maintainers** — author and maintain the recipe catalog, canonical sources, and renderer.
- **The `interviewer` agent** — consumer of the new description-first classification logic.

## 4. Scope

> Partial — seeded from escalation.

### In Scope

- Rename/collapse lite work-types to `{ bug-fix, new-feature, refactor }` across the
  **canonical** source. The 5 install trees (`antigravity`, `claude-code`, `codex`,
  `copilot-cli`, `cursor`) are re-rendered from canonical, not hand-edited.
- **Description-first TRIAGE (Option 2):** lead with a free-form work description; the agent
  infers `type + best recipe` and the user confirms. A confident single-recipe match ⇒ lite;
  ambiguous / multi-target / no match ⇒ full. T1/T2 sizing collapses into that rule.
- Add a recipe-schema **`summary:`** front-matter field (catalog listing + agent matching).
  Shrink `applies-to` enum to `{ bug-fix, new-feature, refactor, * }`.
- Author ~51 recipes breadth-first (see § Functional Requirements), migrating the 5 existing.
- Update `recipes/README.md`, recipe template, work-state template, and affected
  `aid-interview` reference docs; re-render install trees via `/aid-generate`; update KB.

### Out of Scope (provisional)

- The "merge by similarity" consolidation pass (explicitly a **follow-up** work).
- Full → lite de-escalation (not supported by the methodology).

## 5. Functional Requirements

> Partial — the recipe catalog (authoritative table in `design-notes.md`).

**Catalog (~51 recipes), breadth-first:**

- **40 add/change pairs** across 11 target-kind families: Objects/Models
  (member, interface), API (api-endpoint, api-middleware), UI (ui-endpoint, ui-component,
  ui-style), CLI (cli-command), DB/Storage (entity/schema, container), Config
  (config-option, feature-flag), Job (job), Messaging (event-handler, queue, message),
  Rules (rule), Docs/Report (docs, report), Integration (integration).
- **7 bug-fix recipes:** `fix-application`, `fix-infrastructure`, `fix-api`, `fix-ui`,
  `fix-integration`, `fix-regression`, `fix-security`.
- **3 refactor-only:** `improve-performance`, `bump-dependency`, `rename-symbol`.
- **1 cross-type (`*`):** `add-test-coverage`.

**Existing-recipe migration:** `method-refactor`→`change-member`,
`add-crud-endpoint`→`add-api-endpoint`, `write-release-note`→`add-docs`/`add-report`,
`add-unit-test`→`add-test-coverage`, `bug-fix`→`fix-application` (or generic).

## 6. Non-Functional Requirements

- Classification resolves in **one confirmation turn** for common work descriptions.
- The catalog stays **greppable and consistent** — enforce the `add-X` / `change-X` / `fix-X`
  naming convention across all ~51 recipes.
- Rendered install trees remain **byte-identical** across all hosts (existing
  `/aid-generate` guarantee).
- **No new runtime dependency and no new parsing script** — classification is prose only.

## 7. Constraints

- Source of truth is **`canonical/`** + `profiles/`; all edits go there and are rendered to
  the install trees via `/aid-generate` (never hand-edit rendered trees).
- Follow the `prose-over-scripts` principle — classification is agent inference in SKILL.md
  prose, not a new parsing script.
- **Clean break on the enum rename:** only the new work-type values
  `{bug-fix, new-feature, refactor}` are valid. No alias/read-compat for the old values
  (`small-refactor`, `small-new-feature`, `single-doc`) and no migration shim.
  Any in-flight lite work recorded under an old value must be **reset and re-triaged**.

## 8. Assumptions & Dependencies

- `parse-recipe.sh` validation can tolerate the new `summary:` front-matter field
  (may need a small tweak — dependency).
- `/aid-generate` renders `recipes/` into every install tree.
- Shipping ~51 **un-merged** recipes is an acceptable interim state — the merge-by-similarity
  consolidation is a separate follow-up work.
- No in-flight lite works currently depend on the old enum (clean break is safe at this time);
  if any exist, they are reset per §7.

## 9. Acceptance Criteria

- [ ] Work-types renamed/collapsed to `{bug-fix, new-feature, refactor}` across **all**
  canonical files (no `small-refactor`/`small-new-feature`/`single-doc` references remain
  **as enum/workType/sub-path tokens**). Verify with a context-aware search (e.g. `applies-to:`
  front-matter, workType-mapping tables, sub-path labels) — NOT a bare substring grep, which
  false-positives on benign prose such as `reviewer-ledger-schema.md` ("single-doc cosmetic issue").
- [ ] TRIAGE runs description-first: agent infers `type + recipe`, user confirms; a confident
  single-recipe match routes lite, ambiguous/multi-target/no-match routes full.
- [ ] `summary:` field added to the recipe schema + recipe template, and
  `parse-recipe.sh` validation tolerates it; `applies-to` enum updated to
  `{bug-fix, new-feature, refactor, *}`.
- [ ] ~51 recipes authored and `parse-recipe.sh --validate` passes on every one; the 5
  existing recipes migrated with **no loss** of capability.
- [ ] All 5 install trees (`antigravity`, `claude-code`, `codex`, `copilot-cli`, `cursor`)
  re-rendered via `/aid-generate` and verify byte-identical.
- [ ] KB updated for the new taxonomy — specifically the enum/sub-path references in
  `domain-glossary.md` (§§ Lite Path / Recipes), `schemas.md` (the `applies-to` enum), and
  `pipeline-contracts.md` (inline enum comment), plus the new catalog in `domain-glossary.md`.
- [ ] The canonical smoke test `tests/canonical/test-parse-recipe.sh` stays green.

## 10. Priority

- **Must:** taxonomy rename + `applies-to` enum + `summary:` field + description-first TRIAGE
  + migrate the 5 existing recipes + re-render install trees.
- **Should:** the full ~51-recipe catalog.
- **Could:** depth of bug-fix specialization (the 5 "where" fix recipes vs. a generic + slot).
- **Won't (this work):** the merge-by-similarity consolidation pass.
