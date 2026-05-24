# task-014: Implement State TRIAGE in aid-interview + T3 prose→workType kebab mapping

**Type:** IMPLEMENT

**Source:** feature-005-lite-path → delivery-002

**Depends on:** task-005, task-013

**Scope:**
- Insert new `## Mode: TRIAGE` between current State 1 (FIRST RUN / Q&A) and State 2 in aid-interview's dispatch table.
- Implement the 2-3 deterministic triage questions: (a) breadth, (b) size, (c) type-of-work.
- Implement T3 prose → workType kebab mapping (`bug fix` → `bug-fix`; `small refactor` → `small-refactor`; `single document/artifact` → `single-doc`; `new feature or system` → `small-new-feature`).
- Emit two signals: Path (lite/full) and Work Type (kebab enum).
- Compute Sub-path (LITE-BUG-FIX/LITE-DOC/LITE-REFACTOR/LITE-FEATURE) via 1:1 mapping from Work Type.
- Write the `## Triage` block (Path / Work Type / Sub-path / Decision rationale) to work-area `STATE.md`.

**Acceptance Criteria:**
- [ ] State TRIAGE fires before State 2 on first run.
- [ ] Triage emits Path and Work Type for every lite-route case; emits Path=full + n/a Sub-path for full-route.
- [ ] T3 prose answers map to kebab values deterministically; non-matching values fall back to Path=full.
- [ ] Decision rationale recorded (templated form `T1=... + T2=... + T3=... → ...` or natural prose).
- [ ] Unit tests for the mapping function and the path-decision rule.
- [ ] Re-running `/aid-interview` on an in-flight workspace with `## Triage` already populated does not re-ask (idempotent).
- [ ] All §6 quality gates pass.
