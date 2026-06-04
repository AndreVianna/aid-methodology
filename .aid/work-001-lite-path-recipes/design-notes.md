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

## bug-fix recipes (RESOLVED) — 7, by architectural area + bug-nature

`fix-application`, `fix-infrastructure`, `fix-api`, `fix-ui`, `fix-integration`,
`fix-regression`, `fix-security`.
- The five "where" recipes (application/infrastructure/api/ui/integration) share the same
  interview shape (repro + observed-vs-intended + component) → expected merge candidates
  (Axis D) → likely collapse to generic bug-fix + `component`/`layer` slot.
- `fix-regression` and `fix-security` are structurally distinct (different questions) → stay separate.
- `fix-application` = broad default (domain/business-logic bugs not caught by api/ui).

## Non-symmetric recipes (RESOLVED) — include all

- refactor-only: `improve-performance`, `bump-dependency`, `rename-symbol`
- cross-type (`applies-to: *`): `add-test-coverage`

## Recipe schema change (RESOLVED)

Add a **`summary:`** front-matter field — one-line description, used BOTH for the catalog
listing and for agent description→recipe matching. (`applies-to` stays as coarse work-type
filter; `summary` disambiguates within a type.)

## Running total: ~51 recipes

| Group | Count |
|---|---|
| add/change pairs (20 × 2) | 40 |
| bug-fix | 7 |
| refactor-only | 3 |
| cross-type | 1 |
| **Total** | **~51** |

## Still-open analysis

- **OQ-A — TRIAGE/classification flow redesign.** The structural heart. How does
  description→{type + recipe} work, and how does it integrate with the existing
  T1/T2 lite-vs-full sizing? (Next thread.)
- **OQ-B — recipe slots & tasks** per recipe (esp. add/change pairs sharing slot structure).
- **OQ-C — existing-recipe migration.** method-refactor→change-member,
  add-crud-endpoint→add-api-endpoint, write-release-note→add-docs/add-report,
  add-unit-test→add-test-coverage, bug-fix→fix-application (or generic).
- **OQ-D — naming consistency** (ui-endpoint; add-entity/change-schema). Low priority.

## Path decision: UNDECIDED (leaning FULL)

Scope: rename types across 8+ canonical files + rewrite TRIAGE classification + schema
field + ~51 recipe files + README + re-render via aid-generate. Strongly implies FULL path.
