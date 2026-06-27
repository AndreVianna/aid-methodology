# task-080: Restate concern-model.md's owning-table in spine-dimension terms + the substrate lookup

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-080/STATE.md.

**Type:** DESIGN

**Source:** work-001-kb-skills-improvement -> delivery-014

**Depends on:** task-078 (the spine-keyed depth standard / dimension keying the safeguard re-states;
shared dimension keying)

**Scope:**
- Produce the **design of record** for feature-016 Change 2 (FR-53) so task-081 can re-key the
  script mechanically. DESIGN only — propose + decide; no script edits here.
- **Restate `concern-model.md`'s owning-table in spine-dimension terms.** Today the "Operational
  guidance is first-class structure" owning-table is filename-keyed; define its **dimension-keyed**
  re-statement — "the doc realizing dimension C<N> owns class X" (C5 -> Contracts; C3 -> Conventions;
  C2 -> Conventions/Parts; C1/C4 -> Invariants; C7 -> Gotchas) — as the **single source of truth**
  the script will encode. (The prose edit to `concern-model.md` itself is task-081's; this task
  fixes the exact mapping + wording.)
- **The doc-set substrate dimension-lookup decision.** `kb-actback-task.sh` consumes a doc-set TSV
  `filename<TAB>owner<TAB>presence` (no dimension column). Decide how the script maps filename ->
  dimension: **extend the TSV with a 4th `spine-dimension` field** vs **resolve from a shipped
  filename->dimension map** (the matrix / §2.6 mapping is the source). Pick the lower-churn form that
  preserves the **byte-stable software seed** + existing TSV-consumers. Record the decision + the
  `doc-set-resolve.md` substrate contract change.
- **The C9-derived task-selector shape.** Specify how `_run_task`'s `task_type` heuristic is
  replaced by a **dimension-aware + C9-seeded** selector ("add/modify/extend «a capability the
  project actually has»", from the resolved doc-set's C9 doc, exercising C5/C3/C2/C6), and how
  determinism (NFR-3) is preserved: same doc-set + same C9 doc -> byte-identical task spec.
- Output is a structured proposal recorded in task-080/STATE.md `## Notes` (the dimension owning-table
  + the substrate-lookup decision + the C9-selector contract) — no report file.

**Acceptance Criteria:**
- [ ] The owning-table is **restated in spine-dimension terms** (C5 -> Contracts; C3 -> Conventions;
  C2 -> Conventions/Parts; C1/C4 -> Invariants; C7 -> Gotchas) as the single source of truth the
  script will encode, with the exact `concern-model.md` wording fixed for task-081. *(FR-53)*
- [ ] The **doc-set substrate dimension-lookup** form is decided + justified (4th TSV field vs
  shipped map), preserving the byte-stable software seed + existing TSV-consumers; the
  `doc-set-resolve.md` substrate-contract change is specified. *(FR-53, NFR-3)*
- [ ] The **C9-derived task-selector** contract is specified (dimension-aware + C9-seeded;
  domain-appropriate, not "add an endpoint"; deterministic — same doc-set + C9 doc -> byte-identical
  task). *(FR-53, NFR-3)*
- [ ] The proposal **consumes** delivery-013's dimension keying (single-sourced from
  `concern-model.md`); it does not grow the spine, change the matrix domain set, or touch
  `synth_default_seed`.
- [ ] All section-6 quality gates pass (DESIGN: proposal recorded in STATE; no canonical edits, so
  no regen/DBI here).
