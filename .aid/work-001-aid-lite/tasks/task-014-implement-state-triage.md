# task-014: Implement State TRIAGE in aid-interview + T3 prose→workType kebab mapping

**Type:** IMPLEMENT

**Source:** feature-005-lite-path → delivery-002

**Depends on:** task-005, task-013

**Scope:**
- Insert a new State TRIAGE entry into aid-interview's `## Dispatch` table (post-thin-router shape, after task-005), positioned between State 1 (FIRST RUN) and State 2 (Q&A). aid-interview is State-keyed, but post-refactor the router has NO per-state H2 blocks in SKILL.md — per-state body lives in `references/state-{name}.md`. So this task creates `references/state-triage.md` containing the TRIAGE body, and adds the matching row to the dispatch table.
- Implement the 2-3 deterministic triage questions in the new reference file: (a) breadth, (b) size, (c) type-of-work.
- Implement T3 prose → workType kebab mapping (`bug fix` → `bug-fix`; `small refactor` → `small-refactor`; `single document/artifact` → `single-doc`; `new feature or system` → `small-new-feature`).
- Emit two signals: Path (lite/full) and Work Type (kebab enum). For full-route: emit Path=full + omit Sub-path (no n/a placeholder — the field is absent).
- For lite-route only: compute Sub-path (LITE-BUG-FIX/LITE-DOC/LITE-REFACTOR/LITE-FEATURE) via 1:1 mapping from Work Type.
- Write the `## Triage` block (Path / Work Type / Sub-path / Decision rationale) to work-area `STATE.md` per the schema task-013 defined.

**Acceptance Criteria:**
- [ ] State TRIAGE fires before State 2 on first run.
- [ ] Triage emits Path and Work Type for every triage case; for lite-route also emits Sub-path; for full-route Sub-path field is absent (not "n/a").
- [ ] T3 prose answers map to kebab values deterministically; non-matching values fall back to Path=full.
- [ ] Decision rationale recorded (templated form `T1=... + T2=... + T3=... → ...` or natural prose).
- [ ] Unit tests for the mapping function and the path-decision rule.
- [ ] Re-running `/aid-interview` on an in-flight workspace with `## Triage` already populated does not re-ask (idempotent).
- [ ] All §6 quality gates pass.
