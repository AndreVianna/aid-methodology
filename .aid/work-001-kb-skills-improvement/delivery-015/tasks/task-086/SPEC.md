# task-086: Wire the dual-intent ledger + convergence keystone gates into state-review.md (incl. §2c/§2d greps)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-086/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-015

**Depends on:** task-084, task-085

**Scope:**
- Realize feature-016 §3.4 — wire the two limbs into REVIEW as the **dual-intent ledger + two hard
  keystone gates** with the convergence thresholds (FR-54 + FR-55). Edit **canonical** sources only;
  the full `run_generator.py` regen + `.claude` sync is the regen step.
- **Wire `canonical/skills/aid-discover/references/state-review.md`:** REVIEW runs the assertiveness
  limb (task-084) + the essence limb (task-085) + the §3.3 spine-coverage/operational-class presence
  (consuming delivery-014's re-keyed owning-table) -> emits the **dual-intent ledger** (the 7-column
  reviewer-ledger schema with `[ACTBACK]` / `[FIDELITY]` / `[ESSENCE-GAP]` tags) -> FIX deepens the
  flagged docs -> re-REVIEW, until **both** gates pass.
- **Re-key the §2c/§2d verdict-derivation greps (the load-bearing detail).** Today §2c/§2d match the
  literal `[TEACHBACK]` / `[ACTBACK]` strings to derive the teach-back/act-back verdicts. Update the
  grade aggregation so: the **essence verdict** keys on `[FIDELITY]` / `[ESSENCE-GAP]` (no longer on
  `[TEACHBACK]` alone), and the **assertiveness verdict** picks up the spine-keyed `[ACTBACK]`
  insufficiencies. Enumerate **every** grep/string-match in `state-review.md` that references the old
  tags and re-key them all (not just §2c/§2d's first instance) — confirm no stale `[TEACHBACK]`-keyed
  derivation remains.
- **Set the concrete PASS thresholds (the DETAIL scoping deferral):** Assertiveness passes only at
  **zero `[HIGH] [ACTBACK]` + STATED-coverage >= 90% + all quality-contracts present**; Essence
  passes only at **zero `[HIGH] [FIDELITY]` + load-bearing essence-coverage >= 90%**. Start strict
  per §8; both are **hard keystone gates** (a FAIL caps the grade, as M3/M4 are today). Record the
  chosen numbers in `state-review.md` + task-086/STATE.md `## Notes` (calibrated against the AID
  dogfood + fixtures in task-087 / delivery-016; tunable there).
- Also touch `canonical/skills/aid-discover/references/state-generate.md` for the REVIEW⇄FIX loop
  framing if needed. Reuses the existing panel + `grade.sh` + the ledger schema — **no** new grading
  infra. Run the full `run_generator.py` regen -> `.claude` sync; never edit the rendered `.claude/`
  copy.

**Acceptance Criteria:**
- [ ] `state-review.md` wires the **dual-intent ledger** (7-column schema, `[ACTBACK]` /
  `[FIDELITY]` / `[ESSENCE-GAP]` tags) + the §3.3 spine-coverage presence check + the REVIEW⇄FIX
  convergence loop. *(FR-54, FR-55, §3.4)*
- [ ] **Every** §2c/§2d (and any other) verdict-derivation grep keyed on the literal
  `[TEACHBACK]` / `[ACTBACK]` strings is re-keyed: the **essence** verdict on
  `[FIDELITY]`/`[ESSENCE-GAP]` (not `[TEACHBACK]` alone), the **assertiveness** verdict on the
  spine-keyed `[ACTBACK]`; **no stale** old-tag derivation remains. *(FR-54, FR-55)*
- [ ] Both limbs are **hard keystone gates** (a FAIL caps the grade); the concrete PASS thresholds
  are set — **zero `[HIGH] [ACTBACK]`, STATED-coverage >= 90%, all quality-contracts present**
  (assertiveness) and **zero `[HIGH] [FIDELITY]`, essence-coverage >= 90%** (essence) — recorded in
  `state-review.md` + STATE. *(FR-54, FR-55, §8)*
- [ ] **No new grading infra / agent enum / verdict sentinel** — reuses the panel + `grade.sh` + the
  ledger schema. *(scope discipline)*
- [ ] Edits are `canonical/...` only; the full `run_generator.py` regen + `.claude` sync run.
- [ ] All section-6 quality gates pass.
