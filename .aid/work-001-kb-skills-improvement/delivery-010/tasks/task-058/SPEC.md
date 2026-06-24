# task-058: Source-driven domain classifier in GENERATE (+ Step 0f reconciliation)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-058/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-010

**Depends on:** task-056

**Scope:**
- Add a **domain-classification sub-step** to
  `canonical/skills/aid-discover/references/state-generate.md`, run after the project index
  is built (it reads the existing source — brownfield-first).
- Behavior: read project-index + harvested signals for domain signals; **decisive ->
  classify**; **insufficient / uncertain / dubious -> write a Required Q&A** to
  `STATE.md ## Q&A (Pending)` and pause (existing Q&A gate). Never auto-final.
- Write a **`## Discovery Domain`** block to `.aid/knowledge/STATE.md` (measured / proposed /
  decision-rationale / confirmed), with **idempotent re-entry** (re-run reads the prior
  domain and re-confirms).
- **Implement the domain classifier alongside the existing Step 0f path-triage**, which
  **stays in discovery** per the **resolved** delivery-010 Q1 (a settled decision this
  IMPLEMENT task consumes, not re-decides). Document the domain/path relationship (the two
  source-measured, human-confirmed classifications) in the skill.

**Acceptance Criteria:**
- [ ] `state-generate.md` has a domain-classification step with the decisive/uncertain
  branches, the STATE `## Discovery Domain` record, and idempotent re-entry. *(FR-38)*
- [ ] Uncertainty raises a **Required Q&A** in the existing format/gate; classification is
  measured-then-confirmed (never from `project.type`). *(FR-38)*
- [ ] The classifier is implemented alongside the **unchanged** Step 0f path-triage (per the
  resolved Q1); the skill documents the domain/path relationship. *(feature-014 §7)*
- [ ] No heavy new infra; any shipped script is ASCII-only. All section-6 quality gates pass.
