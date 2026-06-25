# Delivery SPEC -- delivery-013: Spine-Keyed Depth Contracts

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-013/STATE.md.

> **Delivery:** delivery-013
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-25

---

## Objective

Close the **dangling-anchor gap** feature-014 left: `/aid-discover`'s per-doc depth contract
(`document-expectations.md`) is keyed by `### <filename>` and covers only **22** of the **58**
filenames the domain→doc-set matrix can emit, so the **36** uncovered docs (58 emittable − 22
covered; incl. the shared `glossary.md`/`tooling-stack.md` + all non-software domain docs) are
pointed at a missing anchor and get only the generic spine question. This delivery realizes
feature-016 **Change 1 (FR-52)**: author a **per-spine-dimension, work-actionable depth standard**
(C0–C9 + D — authored once per dimension, not once per filename) and **re-point the GENERATE
custom-doc prompt at it** (`state-generate.md` §2.6), so every doc in any resolved doc-set inherits
its dimension's depth standard, specialized to its content. It is the **shippable midpoint** — a
domain-general depth standard useful even before the dual-intent self-eval (delivery-015) lands.

## Scope

In scope (feature-016 Change 1, FR-52):

- **Per-spine-dimension depth standard** — a work-actionable depth contract authored once per spine
  dimension (the C5 doc carries shapes/fields/types/constraints + the extension procedure; the C3
  doc carries the project's actual conventions + concrete examples + red-flags; C2 = parts + how to
  add a part; C6 = how work is graded/validated + the bars; C0/C1/C4/C7/C8/C9/D similarly),
  generalizing today's best software `document-expectations.md` entries.
- **Re-point the custom-doc prompt** — `state-generate.md` §2.6 + `agent-prompts.md`
  § "Custom-Doc Runtime Extension" resolve each doc → its **spine dimension** (via the matrix's
  `spine-dimension` column / the §2.6 dimension mapping) → the dimension's depth standard, instead
  of a bare `### <filename>` anchor. No doc is left at a dangling anchor.
- **Per-filename entries become optional additive refinements** — a `### <filename>` entry, where
  present, layers on top of the dimension standard; it never replaces it.

**Out of scope:** the safeguard re-key + C9-derived task generation (Change 2 — **delivery-014**);
the dual-intent self-eval (§4 — **delivery-015**); the altitude signature exception + dogfood
(Change 3 — **delivery-016**); any change to feature-014's spine cardinality, matrix domain set,
classifier, or `synth_default_seed` (this delivery *consumes* the spine, it does not grow it).

## Gate Criteria

- [ ] **Every** doc in any resolved doc-set (software, data-ml, content, research, design, ops,
  methodology-tooling, or auto-researched) resolves to a **non-empty, work-actionable depth
  contract via its spine dimension** — no doc is pointed at a dangling `### <filename>` anchor,
  including the **36** of 58 matrix-emittable filenames that dangle today (incl. the shared
  `glossary.md`/`tooling-stack.md` + all non-software domain docs). *(FR-52)*
- [ ] The depth standard is authored **per spine dimension** (C0–C9 + D), not per filename; the
  GENERATE custom-doc prompt (`state-generate.md` §2.6 + `agent-prompts.md`) is re-pointed to
  resolve doc → dimension → standard. *(FR-52)*
- [ ] Existing per-filename `### <filename>` entries remain valid as **optional additive
  refinements** (they layer on the dimension standard; they do not regress). *(FR-52)*
- [ ] **Delivery grade gate = A+** (this work's quality bar, above the default A minimum).
- [ ] All section-6 quality gates pass: canonical→render parity (full `run_generator.py`), dogfood
  byte-identity (DBI — here the **canonical→`.claude` render-parity** check; this delivery edits
  only `canonical/` skill/template sources, **not** AID's own `.aid/knowledge/*` doc content — that
  doc-content DBI sync is delivery-016's), ASCII-only + WinPS-5.1 lint for any shipped/changed
  script, and the affected canonical suites (matrix, expectations/authoring-standard) re-run green.

## Tasks

> Authored by `/aid-detail`. Each task has a full SPEC + STATE at `tasks/task-NNN/`. The
> `Depends on` ordering and waves are in PLAN.md `### delivery-013 execution graph`.

| Task | Type | Title |
|------|------|-------|
| task-077 | DESIGN | Design the per-spine-dimension depth standard + pick the authority file |
| task-078 | IMPLEMENT | Author the dimension depth standard + re-point the GENERATE custom-doc prompt |
| task-079 | TEST | Assert every matrix doc resolves a non-empty depth contract + DBI |

## Dependencies

- **Depends on:** delivery-010 (feature-014 — the spine, the matrix's per-doc `spine-dimension`
  column, `document-expectations.md`, and `state-generate.md` §2.6 the custom-doc prompt this
  delivery re-keys)
- **Blocks:** delivery-014 (the safeguard re-key shares the dimension keying), delivery-015 (the
  depth standard the FIX loop drives toward)

## Notes

- **Consumes the spine, does not grow it:** the 11-dimension T2 cardinality contract, the matrix
  domain set, and the classifier are untouched; this delivery adds a depth standard *keyed to* the
  existing spine.
- **Design rationale** lives in
  `.aid/work-001-kb-skills-improvement/features/feature-016-discover-dual-intent-self-eval/SPEC.md`
  §1 and the design seed `.aid/design/aid-discover-dual-intent-self-eval.md` §5.1.
- **Decision (DETAIL):** author the dimension standard as a new spine-dimension-keyed section
  within `document-expectations.md` or a sibling `spine-depth-expectations.md` — pick the
  lower-churn form; either way §2.6 resolves doc → dimension → standard.
- Affected files: `canonical/skills/aid-discover/references/document-expectations.md`,
  `canonical/skills/aid-discover/references/state-generate.md`,
  `canonical/skills/aid-discover/references/agent-prompts.md`,
  `canonical/aid/templates/kb-authoring/concern-model.md`,
  `canonical/aid/templates/kb-authoring/domain-doc-matrix.md`.
