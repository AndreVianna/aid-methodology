# task-088: Altitude-rule signature exception in principles.md (+ concern-model.md cross-ref)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-088/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-016

**Depends on:** task-086 (the assertiveness gate that enforces the signature exception must exist
before the exception is stated + enforced)

**Scope:**
- Realize feature-016 **Change 3 (FR-56)** — amend the KB authoring altitude rule with the
  **signature exception**. Edit **canonical** sources only; the full `run_generator.py` regen +
  `.claude` sync is the regen step.
- **Amend `canonical/aid/templates/kb-authoring/principles.md`** P1(d) + the altitude/summary+pointer
  rule: **load-bearing operational contracts an agent must honor to ACT** — field types, exit codes,
  the args/modes/invariants — are stated **INLINE or with a precise grep-recoverable anchor** (the
  P1(d) durable-anchor form), **never** a bare `sources:` file pointer. The altitude rule **keeps**
  de-bloating *narrative* volatility; it does **not** apply to *work-critical contracts*.
- **Cross-reference** the exception from `canonical/aid/templates/kb-authoring/concern-model.md`'s
  "Operational guidance is first-class structure" section, and from
  `canonical/aid/templates/kb-authoring/tier-model.md` (the T-tier "what stays inline" guidance) if
  touched.
- This is the **prose rule only** — re-injecting AID's own evicted depth into its KB docs is
  task-089; running the dogfood gate is task-090. Run the full `run_generator.py` regen -> `.claude`
  sync; never edit the rendered `.claude/` copy.

**Acceptance Criteria:**
- [ ] `principles.md` P1(d) + the altitude/summary+pointer rule carry the **signature exception**:
  work-critical operational contracts (field types, exit codes, args/modes/invariants) are stated
  **inline or with a precise grep-recoverable anchor**, **never** a bare `sources:` file pointer.
  *(FR-56)*
- [ ] The rule **still de-bloats narrative volatility** — the exception is scoped to work-critical
  contracts, not all volatile detail. *(FR-56)*
- [ ] `concern-model.md` (and `tier-model.md` if touched) **cross-reference** the exception. *(FR-56)*
- [ ] Edits are `canonical/...` only; the full `run_generator.py` regen + `.claude` sync run; the
  spine/matrix/classifier are untouched.
- [ ] All section-6 quality gates pass.
