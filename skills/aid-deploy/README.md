
# Package & Ship

Final verification, PR creation, delivery summary, and documentation updates. The last development phase before production monitoring.

## Core Principle

**Nothing ships without final verification.** Even if each task passed its own review and testing, the combined delivery must pass as a whole. Integration issues only surface when all pieces come together.

## Inputs

- Feature branch with all completed, reviewed, and tested tasks.
- `DELIVERY-{id}.md` — delivery scope and success criteria.
- `REVIEW.md` files — review results for each task.
- `TEST-REPORT.md` — test results from staging validation.
- `SPEC.md` + `knowledge/` — for documentation updates.

## Prerequisites

Before starting deployment:

- [ ] All tasks in the delivery are status "Complete."
- [ ] All tasks passed review with grade A- or above.
- [ ] Testing phase (aid-test) passed — TEST-REPORT.md is green.
- [ ] No open IMPEDIMENT.md files blocking this delivery.
- [ ] No open GAP.md files blocking this delivery.

If any prerequisite fails, do not proceed. Resolve the blocking issue first.

## Process

### Step 1: Final Verification

Run the complete verification suite — not just the tests added in this delivery.

```bash
# Full build (all projects, not just changed ones)
dotnet build --no-incremental  # or npm run build, mvn clean compile

# Full test suite
dotnet test  # or npm test, mvn test

# Lint/format check
dotnet format --verify-no-changes  # or eslint, prettier --check
```

**All tests must pass.** Zero failures, zero errors, zero warnings.

If final verification fails:
1. Identify the failing test(s).
2. Determine if it's a regression (existing test broke) or integration issue (tasks conflict).
3. Fix on the feature branch.
4. Re-run full verification.
5. If the fix is non-trivial, loop back to aid-review for the fix.

### Step 2: Delivery Summary

Generate a summary of what this delivery contains:

```markdown
# Delivery Summary — {Delivery ID}: {Name}

## Scope
{One paragraph: what this delivery adds}

## Tasks Completed
| Task | Description | Complexity | Review Grade |
|------|-------------|-----------|-------------|
| TASK-F1 | Data model for recordings | S | A |
| TASK-F2 | Repository layer | M | A- |
| TASK-F3 | API endpoints | L | A |

## Changes
- Files changed: {count}
- Lines added: {count}
- Lines removed: {count}
- Tests added: {count}
- Total test count: {before → after}

## Spec Revisions During Delivery
| Rev | Source | Description |
|-----|--------|-------------|
| 1.1 | GAP-001 | Added latency requirements |

## KB Updates During Delivery
| Document | Change | Source |
|----------|--------|--------|
| coding-standards.md | Added FluentValidation convention | aid-review |

## Known Issues
{Any P3+ issues deferred to next delivery}
```

### Step 3: PR Creation

Create a Pull Request with a structured description:

```markdown
## Delivery {id}: {Name}

### What
{Delivery scope — what this PR adds}

### Tasks
- [x] TASK-F1: {name} (Grade: A)
- [x] TASK-F2: {name} (Grade: A-)
- [x] TASK-F3: {name} (Grade: A)

### Verification
- Build: ✅ zero errors, zero warnings
- Tests: ✅ {count} pass ({new} new)
- Lint: ✅ clean
- Staging: ✅ TEST-REPORT.md passed

### Review Notes
{Any notable decisions, trade-offs, or deferred issues}

### References
- DELIVERY-{id}.md
- SPEC.md rev {version}
- TEST-REPORT.md
```

### Step 4: Documentation Updates

Check if implementation revealed anything that should update the KB:

1. **New conventions discovered** → update `knowledge/coding-standards.md`.
2. **Architecture changed** → update `knowledge/architecture.md`.
3. **New integrations added** → update `knowledge/integration-map.md`.
4. **Tech debt created or resolved** → update `knowledge/tech-debt.md`.
5. **Data model changed** → update `knowledge/data-model.md`.

Add entries to `knowledge/revision-log.md` for any KB changes.

### Step 5: Artifact Status Updates

1. Update `DELIVERY-{id}.md`:
   - Status: Complete
   - Completion date
   - Final test count
   - Any deferred issues

2. Update each `TASK-{id}.md`:
   - Status: Complete

3. Update `SPEC.md` revision history if any revisions occurred during this delivery.

4. Update `knowledge/README.md` if any KB documents were updated.

## Output

- Pull Request ready for merge.
- Delivery summary document.
- Updated DELIVERY-{id}.md (status: Complete).
- Updated TASK-{id}.md files (status: Complete).
- Updated KB documents (if applicable).
- Updated revision-log.md (if applicable).

## Post-Deploy

After the PR is merged:

1. **Verify CI/CD** — ensure the main branch build passes.
2. **Tag/release** — if this delivery is a release milestone.
3. **Notify stakeholders** — share the delivery summary.
4. **Plan next delivery** — if more deliveries remain in the spec.
5. **Trigger aid-track** — begin production monitoring.

## Quality Checklist

- [ ] All tasks complete and reviewed (A- or above).
- [ ] Testing phase passed (TEST-REPORT.md green).
- [ ] Full build passes (not incremental).
- [ ] Full test suite passes (not just new tests).
- [ ] Lint/format clean.
- [ ] PR created with structured description.
- [ ] Delivery summary generated.
- [ ] DELIVERY and TASK statuses updated.
- [ ] KB updated with any new discoveries.
- [ ] Revision log entries added for all KB changes.
- [ ] No open GAPs or IMPEDIMENTs blocking this delivery.

## See Also

- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.
