
# Spec-Anchored Code Review

Review implementation quality against the task specification, project spec, and Knowledge Base standards. Grade the output. Tag issues by their root cause. Auto-fix what can be fixed.

## Core Principle

**Review is not "does this code look good." It's "does this code do what the spec says, the way the KB says to do it."** Generic code review catches style issues. Spec-anchored review catches specification drift, architectural violations, and convention gaps.

## Inputs

- Git diff of the implementation (against base branch).
- `TASK-{id}.md` — the acceptance criteria.
- `SPEC.md` — the architectural constraints.
- `knowledge/coding-standards.md` — the coding conventions.
- `knowledge/architecture.md` — the architectural patterns.
- `knowledge/test-landscape.md` — the testing expectations.

## Process

### Step 1: Automated Checks

Run before manual review:

```bash
# Build
dotnet build  # or npm run build, mvn compile, cargo build, etc.

# Tests
dotnet test   # or npm test, mvn test, cargo test, etc.

# Lint/Format (if configured)
dotnet format --verify-no-changes  # or eslint, prettier --check, etc.
```

Record results:
- [ ] Build: zero errors, zero warnings.
- [ ] Tests: all pass.
- [ ] Lint/Format: clean.

If automated checks fail, the review stops. Fix the build/tests first.

### Step 2: Specification Compliance

Review the diff against the TASK-{id}.md:

**For each acceptance criterion:**
- Is it implemented? (Check the code change)
- Is it tested? (Check the test additions)
- Does it handle the specified edge cases?
- Does it follow the specified error handling?

**For each interface contract in the task spec:**
- Does the implementation match the specified public API?
- Are method signatures correct?
- Are return types correct?

Mark each criterion: ✅ Met | ⚠️ Partially met | ❌ Not met.

### Step 3: Architecture Compliance

Review against SPEC.md and KB architecture:

- Does the implementation follow the patterns defined in `architecture.md`?
- Does it respect module boundaries?
- Does it use dependency injection as established?
- Are new dependencies registered correctly?
- Does the data access follow existing patterns?

### Step 4: Convention Compliance

Review against `knowledge/coding-standards.md`:

- Naming conventions (PascalCase, camelCase, etc.).
- Error handling patterns.
- Logging patterns.
- File organization.
- Comment style and documentation.

### Step 5: Issue Classification

Tag every issue found by its root cause:

| Tag | Meaning | Example | Action |
|-----|---------|---------|--------|
| `CODE` | Implementation bug or style issue | Missing null check, wrong variable name | Fix in this review cycle |
| `TASK` | Task spec was wrong or incomplete | Acceptance criterion impossible to implement as written | Update TASK.md, re-implement |
| `SPEC` | Fundamental spec issue | Feature conflicts with another feature's requirements | GAP.md → escalate |
| `KB` | Convention not captured in KB | Team uses X pattern but KB doesn't document it | Update KB |
| `ARCHITECTURE` | KB architecture description is wrong | `architecture.md` says async, but the module is sync | Trigger Discovery update |

### Step 6: Issue Severity

Rate each issue:

| Severity | Criteria | Action |
|----------|----------|--------|
| **P1** | Blocks functionality. Security vulnerability. Data corruption risk. | Must fix before merge. Auto-fix if CODE-tagged. |
| **P2** | Incorrect behavior in non-critical path. Missing edge case handling. | Should fix before merge. Auto-fix if CODE-tagged. |
| **P3** | Style issue. Minor convention violation. Non-optimal but functional. | Fix if easy, otherwise note for next cycle. |
| **P4** | Improvement suggestion. Not a bug. | Document for future consideration. |
| **P5** | Nitpick. Subjective preference. | Skip unless there's a clear standard. |

### Step 7: Auto-Fix

For P1 and P2 issues tagged as `CODE`:

1. Apply the fix directly on the branch.
2. Run build + tests to verify the fix doesn't break anything.
3. Record in the review: "Auto-fixed: {description}."

Do NOT auto-fix:
- Issues tagged TASK, SPEC, KB, or ARCHITECTURE (these need upstream revision).
- P3+ issues (not worth the risk of unintended side effects).
- Issues where the correct fix is ambiguous.

### Step 8: Grade

Based on the aggregate findings:

| Grade | Criteria |
|-------|----------|
| **A+** | All criteria met. No issues. Clean code. Exemplary. |
| **A** | All criteria met. Minor P3-P5 issues only. |
| **A-** | All criteria met. A few P3 issues. Ship-ready. |
| **B+** | All criteria met after P1/P2 auto-fix. Minor issues remain. |
| **B** | Mostly correct. 1-2 P2 issues that need manual fix. One review cycle. |
| **B-** | Functional but messy. Several P3 issues. Cleanup needed. |
| **C+** | Significant gaps. Missing acceptance criteria. Partial re-implementation. |
| **C** | Multiple P1/P2 issues. Major rework needed. |
| **C-** | Barely functional. Most acceptance criteria not met. |
| **D** | Fundamental problems. Wrong approach entirely. |
| **F** | Doesn't build, doesn't pass tests, or completely off-spec. Re-implement. |

### Step 9: Recommendation

Based on the grade:

| Grade Range | Recommendation |
|-------------|---------------|
| A+ to A- | **Test.** Proceed to aid-test for staging validation. |
| B+ to B | **Rework (minor).** Fix identified issues, re-review. |
| B- to C+ | **Rework (major).** Significant cleanup needed. |
| C to D | **Re-implement.** Start the task over with corrected context. |
| F | **Re-implement from scratch.** Investigate why the agent failed so badly. |

## Output: REVIEW.md

```markdown
# Review — TASK-{id}: {Name}

## Automated Checks
- [x] Build: zero errors, zero warnings
- [x] Tests: 47 pass, 0 fail (12 new)
- [x] Lint: clean

## Specification Compliance
- [x] AC1: File import supports .wav format
- [x] AC2: Files added to recent recordings list
- [ ] AC3: Error shown for unsupported formats ← P2, CODE

## Issues Found
| # | Sev | Tag | Description | Location | Status |
|---|-----|-----|-------------|----------|--------|
| 1 | P2 | CODE | Missing error handling for unsupported file formats | ImportService.cs:42 | Auto-fixed |
| 2 | P3 | CODE | Method name doesn't follow convention | ImportService.cs:67 | Noted |
| 3 | P2 | KB | Team uses FluentValidation but KB doesn't document it | — | KB update needed |

## Grade: A-

## Recommendation: Ship
After auto-fix of issue #1, all acceptance criteria are met.
Update KB coding-standards.md to document FluentValidation usage (issue #3).
```

## Feedback Loops

### → Any Upstream Phase (Loop 6)

Issues tagged by source trigger upstream action:

- **CODE** → fix in this review cycle (auto-fix for P1/P2).
- **TASK** → update TASK.md, flag for re-implementation of affected scope.
- **SPEC** → generate GAP.md, trigger aid-specify revision.
- **KB** → update the relevant KB document. No pipeline pause needed.
- **ARCHITECTURE** → trigger targeted aid-discover to correct KB architecture.md.

For SPEC and ARCHITECTURE issues: pause the delivery pipeline and escalate to human.

## Quality Checklist

- [ ] All automated checks ran (build, tests, lint).
- [ ] Every acceptance criterion checked individually.
- [ ] Every issue tagged by source (CODE/TASK/SPEC/KB/ARCHITECTURE).
- [ ] Every issue rated by severity (P1-P5).
- [ ] P1/P2 CODE issues auto-fixed (or justified why not).
- [ ] Grade assigned based on criteria.
- [ ] Recommendation given.

## See Also

- [Review Template](references/review-template.md) — Full REVIEW.md template.
- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.
