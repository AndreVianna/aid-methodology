# Lite-Skill Refactor — Classification (refined)

> **Status:** the authoritative map for work-005. Supersedes the initial mismatch
> analysis (which mis-binned `aid-experiment` and left a gray zone). Agreed with the user
> 2026-07-15.

---

## The discriminator (refined — two axes + a third outcome)

Initial cut used one axis ("does it mutate production code?"). `aid-experiment` exposed
that as too blunt. The real test — **keep the plan → approve → execute cycle if EITHER
holds:**

- **(A) Side-effect axis** — executing produces a durable / external / costly /
  **irreversible** effect a human should approve *before* it happens.
- **(B) Validity axis** — the work needs up-front rigor *before* the doing to be valid or
  safe: pre-registered acceptance criteria, a design, guardrails.

If **neither** holds → **collapse to produce-now** (the planning package is red-tape; the
deliverable itself is what the user asked for).

**Third outcome:** a skill may correctly **keep the cycle yet still need its content
specialized** (e.g. `aid-experiment`) — distinct from "collapse" and from
"correct-as-is / no change."

---

## A. Collapse to single-shot (mismatch → produce the deliverable now)

Neither axis holds: read-only analysis, a document, or a throwaway artifact — nothing
costly/irreversible to gate, no pre-registration needed.

| Skill(s) | Deliverable produced now | Spec |
|---|---|---|
| `aid-review` / `aid-audit` | findings + grade | ✅ `specs/aid-review.md` |
| `aid-research` / `aid-investigate` / `aid-spike` | curated verified answer | ✅ `specs/aid-research.md` |
| `aid-report` | insight report | ✅ `specs/aid-report.md` |
| `document` family → **restructured** into `aid-create-document` / `aid-change-document` (+ `add`/`update` aliases); the 8 old `aid-document*` + `aid-create-diagram` become hint-aliases | the document (format + genre by intelligence) | ✅ `specs/aid-document.md` |
| `aid-prototype` / `aid-prototype-ui` | throwaway/isolated model (spike-shaped) | ⏳ task-006 |
| `aid-test` (run) + `aid-test-security`/`-performance`/`-data-quality` (hint-aliases) | consolidated test/verification findings | ⏳ task-007 |

## B. Keep the cycle

Axis (A) and/or (B) holds — the plan → approve → execute gate is a feature.

| Skill(s) | Why keep the cycle | Change needed | Spec |
|---|---|---|---|
| `aid-experiment` | (B) pre-registered design/AC before a costly run | content-only: rigor→REQUIREMENTS, validation→SPEC, +3 capture slots (engine-driven, no `repurpose`) | ✅ `specs/aid-experiment.md` |
| **`aid-create-test`** (+ `aid-add-test` alias) *(new)* | (A) authoring test code is a committed mutation | new create-family rows + scaffolding | ⏳ task-007 |
| **`aid-change-test`** (+ `aid-update-test` alias) *(new)* | (A) changing test code is a committed mutation | new change-family rows + scaffolding | ⏳ task-007 |

## C. Correct-as-is (no change)

Axis (A) plainly holds (genuine production/infra mutation); the cycle is already right.

`aid-create*` (12 + 12 `add` aliases) · `aid-change*` (12 + 12 `update` aliases) ·
`aid-refactor` · `aid-fix` · `aid-remove`/`aid-delete` · `aid-deprecate` · `aid-migrate` ·
`aid-show-dashboard`. **Test removal/deprecate/migrate use the bare `aid-remove` /
`aid-deprecate` / `aid-migrate`** — no per-artifact remover exists anywhere in the
catalog, so no `aid-remove-test`.

---

## Test-family restructure (folds the old gray zone)

The G7 test family was split-identity (author vs. run) because authoring test code had no
create-family home. Resolution:

| Skill | Behavior | Category |
|---|---|---|
| `aid-create-test` (+ `aid-add-test` alias) | author tests | B (keep-cycle) |
| `aid-change-test` (+ `aid-update-test` alias) | change tests | B (keep-cycle) |
| `aid-test` | run **any** requested suite/verification + consolidate results | A (collapse, review-shaped) |
| `aid-test-security` / `-performance` / `-data-quality` | **hint-aliases** → `aid-test` (backward-compatible; option (b)) | A (collapse) |
| test removal | bare `aid-remove` / `aid-delete` | C (correct-as-is) |

Notes:
- **Naming convention (shipped):** `create`/`change` are canonical, `add`/`update` are
  the aliases. So `aid-create-test`+`aid-add-test` and `aid-change-test`+`aid-update-test`.
- **Domain knowledge is preserved, not dropped:** the specialized capture guidance
  (security SAST/DAST/fuzz/audit; performance workload/threshold/environment; data-quality
  schema/freshness/completeness/uniqueness) moves *into* `aid-test` as conditional prompts
  the generic skill uses when the request is of that kind — the "defer to agent
  intelligence, don't enumerate" principle from `aid-review`.
- **Grouping:** the new authoring skills are create/change *behavior* but test *domain* —
  keep them thematically under G7 (test) for discoverability; verb drives behavior, group
  drives triage.
- `aid-test`'s two-mode scaffolding (functional author+run / model-eval) narrows: authoring
  moves to `aid-create-test`; `aid-test` becomes run-and-consolidate only.

---

## Net effect on the catalog

- **New skills (+9):**
  - test: `aid-create-test`, `aid-add-test`, `aid-change-test`, `aid-update-test` (+4).
  - document: `aid-create-document`, `aid-add-document`, `aid-change-document`,
    `aid-update-document`, `aid-create-diagram` (+5).
- **0 removed:** the three `aid-test-*` and the 8 `aid-document*` all stay as
  backward-compatible hint-aliases.
- **Behavior changed:** the collapse families (review, research, report, document,
  prototype) + the `aid-test` run consolidation; 1 keep-cycle content-specialization
  (`aid-experiment`); test authoring split into create/change-test.
- **Recurring principle:** *defer to agent intelligence, don't enumerate* — applied to
  review targets, test suites, and now document format/genre (one generic skill + thin
  hint-aliases each time).
- **55+ correct-as-is untouched.**
