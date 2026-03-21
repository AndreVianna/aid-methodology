# Correction — {Bug ID or Title}

> **Deprecated:** The Correct phase has been merged into Triage. Root cause analysis, patch scope, and test requirements are now documented directly in TRIAGE.md. This template is retained for reference only.

## Source
**Triage:** {reference to TRIAGE.md}
**Bug:** {one-line summary of the bug}
**Severity:** {from triage: Critical | High | Medium | Low}

## Root Cause
{What went wrong and why. Trace from symptom to cause. One paragraph, specific.}

## Impact
**Affected functionality:** {what's broken for users}
**Affected modules:** {from KB module-map.md}
**Consumers of affected code:** {downstream dependencies that might be impacted}
**Data integrity:** {has data been corrupted? is a migration needed?}
**Existing test coverage:** {what should have caught this, and why it didn't}

## Related Occurrences
{Does the same bug pattern exist elsewhere in the codebase? If yes, list locations — each gets a separate CORRECTION.md.}

## Patch Scope
| File | Change | Reason |
|------|--------|--------|
| {file path} | {what to change} | {why this fixes the root cause} |

## Test Requirements

### Fix Verification
{A test that reproduces the bug (fails now) and proves it's fixed (passes after).}

### Regression Tests
{Tests that prove existing functionality isn't broken by the change.}

### Coverage Gap
{Tests that should have existed and would have prevented this bug. Add them.}

## Acceptance Criteria
- [ ] {Bug is fixed — specific, testable criterion}
- [ ] {Fix verification test passes}
- [ ] {Regression tests pass}
- [ ] {Coverage gap tests added}
- [ ] {Full test suite passes — no regressions}

## Notes
{Context the implementing agent needs. Gotchas, related modules, risk areas, things to avoid.}
