# Delivery SPEC -- delivery-014: Generalize the Safeguard (spine-keyed owning-table + C9-derived tasks)

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-014/STATE.md.

> **Delivery:** delivery-014
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-25

---

## Objective

Make feature-013's act-back **sufficiency safeguard fire off-software**. Today
`kb-actback-task.sh`'s `_doc_expects_class` owning-table and `_run_task` representative-task
selector are **filename-keyed software-only**, so on a data/design doc-set the operational-class
presence check emits **zero rows** and the task degrades to "add an endpoint" (provably inert).
This delivery realizes feature-016 **Change 2 (FR-53)**: re-key the owning-table from filenames →
**spine dimensions** (single-sourced from `concern-model.md`), carry the spine dimension into the
doc-set substrate the script reads, and replace the filename-profile heuristic with a **C9-derived,
domain-appropriate** task selector — so the safeguard works for any domain, deterministically, with
the byte-stable software seed and existing TSV-consumers preserved.

## Scope

In scope (feature-016 Change 2, FR-53):

- **Re-key `_doc_expects_class` from filenames → spine dimensions** — "the doc realizing dimension
  C<N> owns class X" (C5 → Contracts; C3 → Conventions; C2 → Conventions/Parts; C1/C4 → Invariants;
  C7 → Gotchas), single-sourced from `concern-model.md`'s "Operational guidance is first-class
  structure" owning-table re-stated in dimension terms.
- **Carry the spine dimension into the doc-set substrate** — add a filename → dimension lookup so
  the script maps each doc to its dimension (extend the TSV with a 4th `spine-dimension` field or
  resolve from a shipped map; DETAIL chooses). The presence check fires on `data-schemas.md` /
  `design-tokens.md` exactly as on `schemas.md`.
- **C9-derived, domain-appropriate task selector** — replace the filename-profile `task_type`
  heuristic (which falls to "add an endpoint") with a dimension-aware + **C9-seeded** selector:
  "add / modify / extend «a capability the project actually has»", from the resolved doc-set's C9
  doc, selected to exercise the load-bearing dimensions (C5, C3, C2, C6). Derived, not hardcoded;
  same doc-set + C9 doc → byte-identical task spec (NFR-3).
- **D-014's own minimal doc-set TSV fixtures** — the doc-set **substrate** this delivery's
  presence-check + selector gates assert against: a `data-ml.tsv` and a `design.tsv` (the
  `filename<TAB>owner<TAB>presence<TAB>spine-dimension` rows the re-keyed `_doc_expects_class` and
  the C9-derived selector fire on) under `tests/canonical/fixtures/actback-task/`. These are the
  thin substrate only — **not** the full GOOD/SHALLOW/WRONG mini-KBs (those, with their tiny source
  trees for the essence-confrontation stage, remain **delivery-015's**). D-014's gate asserts only
  the owning-table + task-selector behavior on these TSVs; full-KB PASS/FAIL assertions defer to
  D-015.

**Out of scope:** the spine-keyed depth standard (Change 1 — **delivery-013**); the dual-intent
self-eval limbs/ledger/gates (§4 — **delivery-015**, which consumes this delivery's C9-derived
selector as the work-probe seed); the **full per-domain GOOD/SHALLOW/WRONG mini-KB fixtures + their
tiny "source" trees** (**delivery-015** — D-014 ships only the minimal doc-set TSV substrate its own
gate needs); the altitude signature exception + dogfood (Change 3 — **delivery-016**).

## Gate Criteria

- [ ] On a **non-software** doc-set — this delivery's own minimal `data-ml.tsv` / `design.tsv`
  doc-set fixtures (under `tests/canonical/fixtures/actback-task/`) — `kb-actback-task.sh` emits a
  **domain-appropriate** representative task (NOT "add an endpoint") and the operational-class
  **presence check is non-empty**, firing on whatever doc realizes the owning dimension (C5 →
  Contracts, C3 → Conventions, C2 → Conventions/Parts, C7 → Gotchas). The gate asserts only the
  owning-table + task-selector behavior on these TSVs; full GOOD/SHALLOW/WRONG mini-KB PASS/FAIL
  assertions are **delivery-015's**. *(FR-53)*
- [ ] The owning-table (`_doc_expects_class`) is **keyed by spine dimension**, single-sourced from
  `concern-model.md`'s owning-table re-stated in dimension terms; the doc-set substrate carries the
  filename → dimension mapping. *(FR-53)*
- [ ] **Determinism preserved:** same doc-set + same C9 doc → byte-identical task spec; the
  byte-stable software seed and existing `kb-actback-task.sh` TSV-consumers stay green. *(FR-53,
  NFR-3)*
- [ ] **Delivery grade gate = A+**.
- [ ] All section-6 quality gates pass: canonical→render parity (full `run_generator.py`), DBI
  (here the **canonical→`.claude` render-parity** check; this delivery edits only `canonical/`
  sources + test fixtures, **not** AID's own `.aid/knowledge/*` doc content — that doc-content DBI
  sync is delivery-016's), ASCII-only + WinPS-5.1 lint for the changed script, and the affected
  canonical suites (actback-task, actback-fixtures, matrix) re-run green.

## Tasks

> Authored by `/aid-detail`. Each task has a full SPEC + STATE at `tasks/task-NNN/`. The
> `Depends on` ordering and waves are in PLAN.md `### delivery-014 execution graph`.

| Task | Type | Title |
|------|------|-------|
| task-080 | DESIGN | Restate concern-model.md's owning-table in spine-dimension terms + the substrate lookup |
| task-081 | IMPLEMENT | Re-key kb-actback-task.sh (owning-table + doc-set parse + C9 selector) + concern-model.md |
| task-082 | TEST | D-014 doc-set TSV fixtures + safeguard-fires-off-software assertions + DBI |

## Dependencies

- **Depends on:** delivery-013 (the spine-keyed depth standard whose dimension keying the
  safeguard's owning-table re-states; the dimension keying is shared)
- **Blocks:** delivery-015 (the dual-intent self-eval consumes the C9-derived task selector as its
  work-probe seed and the re-keyed owning-table for its presence check)

## Notes

- **Single source of truth:** `concern-model.md`'s "Operational guidance is first-class structure"
  owning-table is the authority the script encodes; this delivery re-states it in spine-dimension
  terms and keeps script + model in lockstep.
- **Design rationale** lives in feature-016 SPEC §2 and the design seed §5.2 + §4.3.
- Affected files: `canonical/aid/scripts/kb/kb-actback-task.sh`,
  `canonical/aid/templates/kb-authoring/concern-model.md`,
  `canonical/skills/aid-discover/references/doc-set-resolve.md`,
  `canonical/skills/aid-discover/references/reviewer-prompt-actback.md`,
  new minimal doc-set TSV fixtures `tests/canonical/fixtures/actback-task/data-ml.tsv` +
  `design.tsv` (the substrate this delivery's gate asserts against — NOT the full mini-KBs, which
  are delivery-015's), and the `tests/canonical/test-actback-task.sh` assertions that consume them.
