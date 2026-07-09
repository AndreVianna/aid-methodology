# Recipe-Catalog Removal

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.3, §4 (recipe-catalog consolidation) | /aid-define |
| 2026-07-07 | Rescoped by the 2026-07-07 scope change: consolidation -> removal. Now owns deleting `canonical/aid/recipes/` and migrating per-work-type scaffolding knowledge into the shortcut skills (§5.6 FR-14, C-4, A-3); all "profile" language dropped (collided with the spine "Profile"). Folder renamed feature-002-verb-artifact-profiles-and-recipe-consolidation -> feature-002-recipe-removal | /aid-define |

## Source

- REQUIREMENTS.md §5.6 (FR-14)
- REQUIREMENTS.md §5.3 (Artifact-type dimension — scaffolding is skill-internal)
- REQUIREMENTS.md §4 (In Scope — Remove the recipe catalog)
- REQUIREMENTS.md C-4, A-3

## Description

With `/aid-describe` reduced to full-path-only (feature-013), nothing consumes the lite recipe
catalog any more. Delete `canonical/aid/recipes/` entirely and migrate the per-work-type
scaffolding knowledge those recipes encoded **into** the shortcut skills, where it becomes
skill-internal — it is not re-introduced as a renamed catalog. Retire or update any
recipe-specific machinery (`parse-recipe.sh` and its tests). Because deleting a `canonical/` file
flows through the emission-manifest pure-mirror-deletion boundary, the generator removes the
recipes from all five profiles and the dogfood `.claude/`, so `render-drift` must be green after
the deletion. Whether the shortcut skills share a lightweight internal scaffolding reference is a
`/aid-specify` implementation detail (see A-2), not a revived catalog.

**Cutover (runs last):** this is sequenced after the shortcut skill families exist and is done
together with features 013/014, so removing the old recipe-backed lite entry never leaves a
capability gap during the switch.

## User Stories

- As an AID maintainer, I want the now-unused recipe catalog deleted and its scaffolding
  knowledge moved into the shortcut skills so the front of the pipeline is simpler and there is
  no dead, over-fragmented catalog to maintain.
- As an AID maintainer, I want recipe-specific tests retired or replaced and `render-drift` green
  after the deletion so removing the catalog leaves the test suites clean.

## Priority

Must (Cutover — sequenced last, after the shortcut families exist)

## Acceptance Criteria

- [ ] Given `/aid-describe` is full-path-only and no skill or script consumes recipes, when the
  catalog is removed, then `canonical/aid/recipes/` is deleted and no skill or script still
  references it. (AC-5 — removal + no dangling refs; FR-14)
- [ ] Given the deletion, when the canonical test suites run, then recipe-specific machinery
  (`parse-recipe.sh` and its tests) is retired or replaced and the suites stay green.
  (AC-5 — retire recipe tests)
- [ ] Given `canonical/` files are deleted, when `run_generator.py` renders, then the deletion
  flows through the emission-manifest pure-mirror-deletion boundary and `render-drift` CI is
  green. (AC-5 — render-drift green; C-4)

---

## Technical Specification

> Grounded in `research/spec-grounding.md § Q-cutover`, whose enumerated delete/retire set is
> CONFIRMED on disk (verified again here by grep). Deletion respects the emission-manifest
> **pure-mirror-deletion** boundary (C-4). This feature **owns every deletion** in the cutover,
> including the 7 `aid-describe` lite/triage reference files that **feature-013** orphans (013
> owns the state-machine rewiring that removes the pointers to them, in the same wave).

### Delete set (canonical source — auto-mirrors to all 5 profiles + dogfood)

| Path (grep-confirmed) | Action | Notes |
|---|---|---|
| `canonical/aid/recipes/` (**51** `.md` files) | delete directory | on-disk count is 51 (the KB's "52"/"51" prose is stale drift) |
| `canonical/aid/scripts/interview/parse-recipe.sh` | delete (retire) | the recipe parser; no surviving consumer after feature-013 |
| `canonical/aid/templates/recipe-template.md` | delete (retire) | recipe-authoring template |
| `canonical/aid/templates/specs/lite-spec-template.md` | delete (retire) | superseded by feature-001's flattened `SPEC.md` + `PLAN.md` shapes |
| `canonical/skills/aid-describe/references/state-triage.md` | delete | (feature-014 extracts its reflect-back turn first) |
| `canonical/skills/aid-describe/references/state-condensed-intake.md` | delete | lite path L1 |
| `canonical/skills/aid-describe/references/state-task-breakdown.md` | delete | lite path L2 |
| `canonical/skills/aid-describe/references/state-lite-review.md` | delete | lite path L3 |
| `canonical/skills/aid-describe/references/state-lite-done.md` | delete | lite path L4 |
| `canonical/skills/aid-describe/references/recipe-to-lite-escalation.md` | delete | recipe escalation |
| `canonical/skills/aid-describe/references/lite-to-full-escalation.md` | delete | lite→full escalation |

### Edit set (canonical source — surfaces that reference the deleted assets)

| File (durable anchor) | Edit |
|---|---|
| `canonical/aid/templates/work-state-template.md` | remove the `## Triage` block (`Path`/`Work Type`/`Sub-path`/`Sub-path (auto)`/`Override`/`Recipe` fields) and the `## Escalation Carry` block (incl. `### Captured Slot Values` / `### Artifacts at Escalation`); drop "Triage, Escalation Carry" from the AUTHORED-zone header note. (feature-001 **adds** `## Delivery Lifecycle` + `## Delivery Gate` to this same template — coordinate the single edit.) |
| `canonical/aid/scripts/execute/complexity-score.sh` | the task-shape parser matches both the bold `**Type:**` form and the flat `- Type:` recipe form and cites `recipes/*.md` in its comment (`grep "flat recipe"`); retire the flat-form branch (feature-001 standardizes on the bold `**Type:**` shape) and remove the `recipes/*.md` comment reference |
| `canonical/aid/scripts/execute/compute-block-radius.sh` | comments say "lite/recipe SPEC" (4 occurrences); reword to "flattened single-delivery SPEC" (feature-001's term) — behavior unchanged; these parse the *graph shape*, not recipe files |
| `canonical/agents/aid-reviewer/AGENT.md` | drop `recipes/` from the illustrative AID-own-dir list `(scripts/, templates/, recipes/)` (the check itself is unchanged) |
| `canonical/EMISSION-MANIFEST.md` | remove the `### Recipes asset kind` section, the `canonical/aid/recipes/ -> …/aid/recipes/` render-table row, and the recipe worked-example line. This is a design-spec **doc**; the actual mirror-deletion runs from render.py's per-profile `emission-manifest.jsonl` diff independent of it, but the doc goes stale |
| `canonical/skills/aid-discover/references/state-generate.md` | reword the line citing *"mirroring `state-triage.md`'s override record"* to drop the deleted-file reference. `aid-discover` is outside §5.6, but this cutover **orphans** the citation — it MUST be scrubbed here (or `state-triage.md` dangles as a dead reference in shipped canonical source). Found by the broadened no-dangling test below |

### Test / registry edits (`tests/`)

| File | Edit |
|---|---|
| `tests/canonical/test-parse-recipe.sh` | delete (retire the 111-assertion `parse-recipe.sh` harness) |
| `tests/README.md` | de-register the `test-parse-recipe.sh` row |
| `tests/canonical/test-multitool-isolation.sh` | re-point the 4 byte-identical recipe **fixtures** (`aid/recipes/add-api-endpoint.md`, `add-entity.md`, `fix-api.md`, `add-feature-flag.md`, `grep "aid/recipes/"`) to surviving passthrough canonical assets (e.g. `aid/templates/*.md` that carry no per-tool substitution) |
| `tests/canonical/test-install.sh` | update the `{scripts,templates,recipes}` comment (line ~1037) to `{scripts,templates}`; the assertion ("at least one of recipes/scripts/templates present") still passes because `scripts/` + `templates/` remain |

### Deletion / mirroring mechanics (C-4)

`render.py` copies the `canonical/aid/` subtree verbatim (`translate="none"`, `copy_tree`), and
each profile's `emission-manifest.jsonl` records every emitted path. Removing a `canonical/`
source file and re-running the **full** `run_generator.py` yields a manifest diff whose
`removed_dst` set is the *only* set the generator deletes — so the 51 recipe files,
`parse-recipe.sh`, and the two retired templates are removed from all five profiles **and** the
dogfood `.claude/` automatically, with **no manual profile edits** (C-4). The manifest is the
authoritative safety boundary; nothing outside it is touched. `render-drift` is green post-render.

**Watch-outs (grounded):** the execute-graph scripts parse the *task-spec shape* recipes
emitted, not recipe files — align the retirement of the flat `- Type:` branch with feature-001's
choice of the bold `**Type:**` shape. The `test-install.sh` smoke check survives (scripts/templates
remain). KB prose that names recipes (`architecture.md § Doc-vs-Code Discrepancies`,
`artifact-schemas.md § Triage` STATE schema row, `capability-inventory.md`, `docs/*.md` "51
recipes") is a **flagged KB/tech-writer follow-up**, out of `/aid-specify` code scope.

### Coupling

- **feature-002 deletes what feature-013 orphans:** the 7 `aid-describe` lite/triage reference
  files. feature-013 removes the SKILL.md `## Dispatch`/`## State Detection`/`## Scripts` pointers
  to them in the same wave — neither half is safe alone.
- **feature-014 before deletion:** feature-014 extracts `state-triage.md`'s reflect-back turn
  into `/aid-triage` before this feature deletes `state-triage.md`.
- **lite-spec-template.md → feature-001:** the retired `lite-spec-template.md` is superseded by
  feature-001's flattened `SPEC.md`/`PLAN.md` shapes; the work-state-template edit here shares a
  file with feature-001's Delivery-block addition.

### Testing strategy

- **No-dangling-reference (canonical grep test, AC-5):** no surviving file under **all of
  `canonical/`** references `recipes/`, `parse-recipe`, the `## Triage` STATE block, the
  `## Escalation Carry` block, **or the filename of any of the 7 deleted `aid-describe` reference
  docs** (`state-triage.md`, `state-condensed-intake.md`, `state-task-breakdown.md`,
  `state-lite-review.md`, `state-lite-done.md`, `recipe-to-lite-escalation.md`,
  `lite-to-full-escalation.md`). Scope is intentionally **all of `canonical/`** — not just
  skills/scripts/templates — because the dangling `state-triage.md` cite lived in
  `aid-discover/references/state-generate.md`, which a narrower scope missed.
- **Mirror-deletion (AC-5 / C-4):** after `run_generator.py`, none of the five profiles nor the
  dogfood `.claude/` contains `aid/recipes/`, `aid/scripts/interview/parse-recipe.sh`,
  `recipe-template.md`, or `specs/lite-spec-template.md`; `render-drift` green; dogfood
  byte-identical.
- **Suite green (AC-5 / AC-9):** `test-parse-recipe.sh` de-registered; `test-multitool-isolation.sh`
  passes on the re-pointed fixtures; `test-install.sh` passes; `tests/run-all.sh` green.
