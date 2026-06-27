# task-085: Blind Reconstruction + Source-Confrontation limb (generalize reviewer-prompt-teachback.md)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-085/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-015

**Depends on:** task-083

**Scope:**
- Realize feature-016 §3.2 / §4.2 — the **Blind Reconstruction + Source Confrontation** limb
  (Intent 2, the essence gate, FR-55), generalizing the M3 teach-back mandate. Edit **canonical**
  sources only; the full `run_generator.py` regen + `.claude` sync is the regen step.
- **Generalize `canonical/skills/aid-discover/references/reviewer-prompt-teachback.md`** into two
  stages:
  1. **Reconstruct (KB-only):** a clean-context agent answers the **essence probes** (from task-083's
     helper) + writes a short what/why/how project narrative, using **ONLY the KB** (no source).
  2. **Confront (source-grounded):** add the **source-grounded confronter** role-shape — a second
     agent **with source access** checks the reconstruction against the actual project. Two failure
     classes: **Divergence** (KB-only answer WRONG vs source) = `[HIGH] [FIDELITY]` -> FIX (the KB
     misrepresents reality); load-bearing **Omission** (a source fact the reconstruction could not
     supply) = `[MED] [ESSENCE-GAP]` -> FIX (the KB omits essence).
- **PASS = no divergence + load-bearing essence-coverage >= threshold.** Emit the
  `[FIDELITY]` / `[ESSENCE-GAP]` tags into the dual-intent ledger (the ledger + gate wiring +
  threshold number is task-086; this task authors the two-stage limb body + its emission contract).
- The source-grounded confronter is the **only new role-shape**; it reuses the existing `aid-reviewer`
  panel + the 7-column ledger schema — **no** new agent enum value, **no** new grading infra,
  **no** separate verdict sentinel. Run the full `run_generator.py` regen -> `.claude` sync; never
  edit the rendered `.claude/` copy.

**Acceptance Criteria:**
- [ ] `reviewer-prompt-teachback.md` is generalized to **stage 1 KB-only reconstruction** (essence
  probes + a what/why/how narrative, no source access). *(FR-55, §3.2)*
- [ ] A **source-grounded confronter** stage 2 is added: **Divergence** = `[HIGH] [FIDELITY]`,
  load-bearing **Omission** = `[MED] [ESSENCE-GAP]`. *(FR-55, §3.2)*
- [ ] PASS contract = **no divergence + load-bearing essence-coverage >= threshold**; the limb emits
  the `[FIDELITY]` / `[ESSENCE-GAP]` tags into the 7-column ledger. *(FR-55)*
- [ ] The source-grounded confronter is the **only** new role-shape; reuses the existing panel +
  ledger; **no** new agent enum / verdict sentinel / grading infra. *(scope discipline)*
- [ ] Edits are `canonical/...` only; the full `run_generator.py` regen + `.claude` sync run.
- [ ] All section-6 quality gates pass.
