# task-081: Re-key kb-actback-task.sh (owning-table + doc-set parse + C9 selector) + concern-model.md

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-081/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-014

**Depends on:** task-080

**Scope:**
- Realize feature-016 **Change 2 (FR-53)** per task-080's design of record. Edit **canonical**
  sources only; the full `run_generator.py` regen + `.claude` sync is the regen step (run here; the
  fixture assertions + DBI are task-082).
- **Re-key `_doc_expects_class`** in `canonical/aid/scripts/kb/kb-actback-task.sh` from filenames ->
  **spine dimensions** ("the doc realizing C<N> owns class X": C5 -> Contracts; C3 -> Conventions;
  C2 -> Conventions/Parts; C1/C4 -> Invariants; C7 -> Gotchas), single-sourced from the
  `concern-model.md` owning-table.
- **Carry the spine dimension into the doc-set parse** — implement task-080's chosen substrate
  lookup (extend the TSV parse to a 4th `spine-dimension` field, or resolve via the shipped
  filename->dimension map) so the presence check fires on `data-schemas.md` / `design-tokens.md`
  exactly as on `schemas.md`.
- **Replace the filename-profile `task_type` heuristic** in `_run_task` with the **dimension-aware +
  C9-derived** selector: "add/modify/extend «a capability the project actually has»" seeded from the
  resolved doc-set's C9 doc, exercising the load-bearing dimensions (C5, C3, C2, C6). Derived, not
  hardcoded; **same doc-set + same C9 doc -> byte-identical task spec** (NFR-3 determinism).
- **Restate `concern-model.md`'s** "Operational guidance is first-class structure" owning-table in
  spine-dimension terms (the single source the script encodes) at
  `canonical/aid/templates/kb-authoring/concern-model.md`; align the `doc-set-resolve.md` substrate
  contract (`canonical/skills/aid-discover/references/doc-set-resolve.md`) and the four-class
  table/task-spec framing in `canonical/skills/aid-discover/references/reviewer-prompt-actback.md` to
  the dimension keying.
- The script stays **ASCII-only + WinPS-5.1-safe** if a `.ps1`/cross-shell twin exists; the changed
  `kb-actback-task.sh` is lint-clean. Run the full `run_generator.py` regen -> `.claude` sync; never
  edit the rendered `.claude/` copy.

**Acceptance Criteria:**
- [ ] `_doc_expects_class` is **keyed by spine dimension**, single-sourced from `concern-model.md`'s
  dimension-restated owning-table; the doc-set parse carries the filename -> dimension mapping.
  *(FR-53)*
- [ ] `_run_task` emits a **dimension-aware, C9-derived, domain-appropriate** task (NOT the default
  "add an endpoint") seeded from the resolved doc-set's C9 doc, exercising C5/C3/C2/C6. *(FR-53)*
- [ ] **Determinism preserved:** same doc-set + same C9 doc -> byte-identical task spec; the
  byte-stable software seed + existing `kb-actback-task.sh` TSV-consumers stay green. *(FR-53,
  NFR-3)*
- [ ] `concern-model.md` owning-table is restated in dimension terms; `doc-set-resolve.md` +
  `reviewer-prompt-actback.md` follow the dimension keying. *(FR-53)*
- [ ] The changed `kb-actback-task.sh` is **ASCII-only + WinPS-5.1-safe** (cross-shell twin moves
  together if present); edits are `canonical/...` only; full `run_generator.py` regen + `.claude`
  sync run.
- [ ] All section-6 quality gates pass.
