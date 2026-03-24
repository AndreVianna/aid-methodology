---
name: aid-review
description: >
  Spec-anchored code review with A+ to F grading. Tags issues by source
  (CODE/TASK/SPEC/KB/ARCHITECTURE). Auto-fixes P1/P2 CODE issues. Use when
  implementation is complete and needs quality gate.
metadata:
  short-description: Spec-anchored code review with grading
---

# Spec-Anchored Code Review

Review implementation against task spec, project spec, and KB standards. Grade. Tag. Auto-fix.

## Inputs

- Git diff (against base branch)
- `TASK-{id}.md` — acceptance criteria
- `SPEC.md` — architectural constraints
- `aid-workspace/knowledge/`: coding-standards.md, architecture.md, test-landscape.md

## Process

### 1. Automated Checks
Build (zero errors/warnings), tests (all pass), lint/format (clean). If any fail → stop. Fix first.

### 2. Specification Compliance
Per acceptance criterion: implemented? tested? edge cases handled? error handling correct? Interface contracts match? Mark: ✅ Met | ⚠️ Partial | ❌ Not met.

### 3. Architecture Compliance
Patterns match architecture.md? Module boundaries respected? DI correct? Data access follows patterns?

### 4. Convention Compliance
Naming, error handling, logging, file organization, comments — all against coding-standards.md.

### 5. Issue Classification
Tag by source:
| Tag | Meaning | Action |
|-----|---------|--------|
| CODE | Implementation bug/style | Fix this cycle |
| TASK | Task spec wrong | Update TASK, re-implement |
| SPEC | Fundamental spec issue | GAP.md → escalate |
| KB | Convention not in KB | Update KB |
| ARCHITECTURE | KB architecture wrong | Trigger discovery update |

### 6. Issue Severity
P1 (blocks functionality, security) → must fix. P2 (incorrect non-critical) → should fix. P3 (style, minor) → fix if easy. P4 (suggestion) → document. P5 (nitpick) → skip.

### 7. Auto-Fix
P1/P2 CODE issues only. Apply fix → verify build+tests → document. Do NOT auto-fix TASK/SPEC/KB/ARCHITECTURE or P3+.

### 8. Grade
A+ (exemplary) → A (minor P3-P5 only) → A- (few P3, ship-ready) → B+ (after auto-fix) → B (1-2 P2 manual fix) → B- (messy, cleanup needed) → C+ (missing criteria) → C (major rework) → C- (barely functional) → D (wrong approach) → F (doesn't build/test)

### 9. Recommendation
A+ to A-: **Test** (proceed to staging). B+ to B: **Rework minor**. B- to C+: **Rework major**. C to D: **Re-implement**. F: **Re-implement from scratch**.

## Output

`REVIEW.md` with: automated check results, specification compliance per criterion, issues table (severity, tag, description, location, status), grade, recommendation.

## Quality Checklist

- [ ] All automated checks ran
- [ ] Every acceptance criterion checked individually
- [ ] Every issue tagged by source
- [ ] Every issue rated by severity
- [ ] P1/P2 CODE issues auto-fixed
- [ ] Grade assigned
- [ ] Recommendation given
