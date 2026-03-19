
# Bug Mapping & Patch Planning

Map the fix for a bug. Root cause analysis, impact assessment, patch scope. Then hand off to Implement. Correct is surgical — it doesn't re-specify or re-plan. It maps the fix and delegates.

## Core Principle

**Fix the root cause, not the symptom.** A 500 error on valid input isn't fixed by catching the exception — it's fixed by handling the null field that should have been validated. Correct traces from symptom to cause, then defines a minimal, focused patch that closes the gap. Band-aids are tech debt. Root cause fixes are engineering.

## Inputs

- `TRIAGE.md` — classified as BUG, with evidence and affected area.
- `knowledge/` directory — architecture, module map, coding standards, test landscape.
- `SPEC.md` — the expected behavior that the code violates.
- `TASK-{id}.md` files — acceptance criteria for the affected feature (if traceable).
- Source code access — for targeted investigation.

## Process

### Step 1: Root Cause Analysis

Trace from symptom to cause using the KB:

1. **Reproduce the path.** From TRIAGE.md evidence, trace the execution path that leads to the bug. Which endpoint? Which module? Which function?
2. **Identify the fault.** What specific code is wrong? Missing validation? Wrong assumption? Off-by-one? Race condition? Use `knowledge/module-map.md` and `knowledge/architecture.md` to navigate.
3. **Understand why.** Why did this happen? Was the spec ambiguous? Was an edge case missed? Was a KB assumption wrong? This context helps prevent recurrence.

The root cause should be one sentence: "The `PaymentService.Process()` method doesn't validate null `currency` field, which the spec says must default to USD."

### Step 2: Impact Mapping

Assess the blast radius:

1. **Direct impact.** What functionality is broken? How many users affected?
2. **Module consumers.** Check `knowledge/module-map.md` — who else calls this code? Could the fix affect them?
3. **Data integrity.** Has the bug corrupted stored data? Does the fix need a data migration?
4. **Related code.** Is the same pattern used elsewhere? If so, the same bug might exist in other modules.

### Step 3: Patch Scope

Define exactly what changes. Minimal surface area:

| File | Change | Reason |
|------|--------|--------|
| {file path} | {what to modify} | {why this change fixes the root cause} |

**Rules for scoping:**
- Fix the bug. Don't refactor the neighborhood.
- If the fix touches shared code, check all consumers.
- If the same bug pattern exists elsewhere, document it — but fix one at a time. Each gets its own CORRECTION.md.

### Step 4: Test Requirements

Three categories of tests:

1. **Fix verification.** A test that fails now (reproduces the bug) and passes after the fix.
2. **Regression tests.** Tests that prove existing functionality still works after the change.
3. **Coverage gap.** Tests that *should have existed* and would have caught this bug. Adding them prevents recurrence.

If the existing test suite has no coverage in the affected area (check `knowledge/test-landscape.md`), flag this as a test debt item.

### Step 5: Generate CORRECTION.md

Produce the correction document using the [template](references/correction-template.md). This is the task spec for `aid-implement` — it must contain everything the implementing agent needs:

- Root cause (so the agent understands *why*, not just *what*).
- Files to touch (so the agent knows the scope).
- Test requirements (so the agent knows what "fixed" means).
- Acceptance criteria (so review has clear pass/fail).

### Step 6: Hand Off to Implement

The CORRECTION.md goes to `aid-implement` as a task. From there, the standard pipeline applies:

```
aid-correct → aid-implement → aid-review → aid-test → aid-deploy
```

Five phases. The correction skips discover, interview, specify, plan, and detail because the spec is already correct — the code just doesn't match it.

## What Correct Is NOT

**Not re-specification.** The spec was right; the code was wrong. If the spec needs to change, that's a CR — route through `aid-discover`.

**Not re-planning.** No delivery decomposition. A bug fix is a single task, not a delivery increment.

**Not a workaround.** If the "fix" is catching an exception and logging it, that's a band-aid. Correct demands root cause resolution.

**Not a kitchen sink.** Don't expand scope. "While we're in there, let's also refactor..." — no. Fix the bug. File a separate task for the refactor.

## Output: CORRECTION.md

See [Correction Template](references/correction-template.md) for the full template.

## Triggers

### → aid-implement (Loop 8)

CORRECTION.md is handed to `aid-implement` as a task spec. The implementing agent:
1. Reads CORRECTION.md for scope and root cause context.
2. Loads relevant KB documents.
3. Implements the fix.
4. Runs the fix verification test (must pass).
5. Runs the full test suite (no regressions).

After implementation: `aid-review` → `aid-test` → `aid-deploy`. Standard quality gates apply.

## Quality Checklist

- [ ] Root cause identified (one sentence, specific).
- [ ] Impact mapped — consumers checked, data integrity assessed.
- [ ] Patch scope is minimal — only files needed for the fix.
- [ ] Fix verification test defined (fails before fix, passes after).
- [ ] Regression tests defined.
- [ ] Coverage gap identified (if applicable).
- [ ] CORRECTION.md produced with all required fields.
- [ ] No scope creep — fix the bug, nothing else.

## See Also

- [Correction Template](references/correction-template.md) — Full CORRECTION.md template.
- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.
