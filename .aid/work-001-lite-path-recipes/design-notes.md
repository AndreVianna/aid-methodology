# Design Notes — work-001-lite-path-recipes

> Working scratchpad captured during CONDENSED-INTAKE (lite path, LITE-FEATURE sub-path).
> Not the formal SPEC. Path (lite vs full) is still undecided — user requested more analysis.

## Goal (in progress)

Restructure the AID lite-path taxonomy and author a broad recipe catalog derived from it.
feature-title: `add-lite-recipes`.

## Decisions locked

1. **Work-type rename / collapse.** From 4 types → 3 internal types:
   - `bug-fix` (fix broken behavior)
   - `new-feature` (add new functionality)  ← rename of `small-new-feature`
   - `refactor` (change behavior of a working feature)  ← rename of `small-refactor`
   - `single-doc` / `new-report` **eliminated** — docs & reports fold into new-feature (add) / refactor (change).
2. **Type names are internal only.** The user never picks a type from a menu. TRIAGE
   infers the type from a free-form work description. `refactor`/`new-feature`/`bug-fix`
   are internal ids, not user-facing labels. (User: "change" is too broad for non-technical
   users; classify from the description, label internally as refactor.)
3. **Classification = agent infers, user confirms.** No new script (consistent with the
   `prose-over-scripts` principle). The agent reads the description, proposes type + best
   recipe, user accepts/corrects.
4. **`applies-to` enum shrinks** to `{ bug-fix, new-feature, refactor, * }`. It becomes a
   coarse filter; the agent disambiguates among recipes sharing a type.
5. **Breadth-first, merge later.** Author add-X and change-X as **separate** files now;
   consolidate by similarity in a follow-up pass (do NOT pre-merge into moded recipes).
6. **Merge axes** (criteria for the later consolidation pass):
   - A. verb (add ↔ change) — same target kind → candidate to merge with a `mode` slot.
   - B. target-kind family — near-synonyms fold together.
   - C. doc/report family.
   - D. bug-fix family (generic absorbs regression/security via optional slots).

## Authoritative catalog (user-provided) — 11 target-kind families, 20 pairs = 40 recipes

| Target kind | new-feature (add) | refactor (change) |
|---|---|---|
| Objects / Models | add-member | change-member |
| Objects / Models | add-interface | change-interface |
| API | add-api-endpoint | change-api-endpoint |
| API | add-api-middleware | change-api-middleware |
| UI | add-ui-endpoint | change-ui-endpoint |
| UI | add-ui-component | change-ui-component |
| UI | add-ui-style | change-ui-style |
| CLI command | add-cli-command | change-cli-command |
| DB / Storage | add-entity | change-schema |
| DB / Storage | add-container | change-container |
| config / feature flag | add-config-option | change-config-option |
| config / feature flag | add-feature-flag | change-feature-flag |
| job | add-job | change-job |
| event handler / consumer | add-event-handler | change-event-handler |
| event handler / consumer | add-queue | change-queue |
| event handler / consumer | add-message | change-message |
| validation / business rule | add-rule | change-rule |
| documentation / report | add-docs | change-docs |
| documentation / report | add-report | change-report |
| integration / external client | add-integration | change-integration |

## Open questions (this work)

- **OQ1 — bug-fix recipes.** bug-fix is a work-type but has NO recipes in the matrix above.
  Stay generic (no recipe, condensed-intake only), or add bug-fix recipes
  (generic + fix-regression + fix-security)?
- **OQ2 — non-symmetric refactor recipes.** improve-performance, bump-dependency,
  rename-symbol have no add-counterpart and were dropped from the symmetric matrix.
  Include them as refactor-only recipes, or out of scope?
- **OQ3 — cross-type add-test-coverage.** Old `add-unit-test` (`applies-to: *`). Keep as a
  cross-type recipe, or is testing covered elsewhere?
- **OQ4 — match-hint field.** To disambiguate ~40 recipes sharing 3-4 `applies-to` values,
  add `applies-when:` front-matter (one phrase per recipe)? (Proposed default: yes.)
- **OQ5 — existing-recipe migration.** Map the 5 current recipes onto the new catalog:
  bug-fix→(OQ1), method-refactor→change-member, add-crud-endpoint→add-api-endpoint,
  write-release-note→add-docs/add-report, add-unit-test→(OQ3).
- **OQ6 — naming consistency.** "ui-endpoint" (UI has pages/routes, not endpoints);
  add-entity vs change-schema asymmetry. Low priority — confirm before authoring.

## Path decision: UNDECIDED

Scope so far: rename types across 8+ canonical files + rewrite TRIAGE classification +
schema field + ~40 recipe files + README + re-render via aid-generate. Strongly implies
FULL path. User wants more analysis before deciding.
