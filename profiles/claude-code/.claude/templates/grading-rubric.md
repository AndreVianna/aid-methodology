# Grading Rubric — Universal

Applies to all AID phases. Grade is **deterministic** — calculated from issue count and severity. The reviewer classifies issues; the grade follows automatically.

## Issue Severities

| Severity | Meaning |
|----------|---------|
| **Minor** | Cosmetic, style, trivial improvement. Does not affect functionality. |
| **Low** | Minor convention deviation, could be better but works correctly. |
| **Medium** | Incorrect behavior (non-critical), missing edge case, incomplete coverage. |
| **High** | Blocks functionality, security risk, data integrity concern. |
| **Critical** | System failure, data loss, security breach, fundamentally wrong approach. |

## Issue Tagging Convention

Issues must be tagged with the bracketed all-caps form so the grading script counts them correctly:

| Sentence-case (descriptive only) | Bracketed tag (counted by `grade.sh`) |
|----------------------------------|---------------------------------------|
| Minor                            | `[MINOR]`                             |
| Low                              | `[LOW]`                               |
| Medium                           | `[MEDIUM]`                            |
| High                             | `[HIGH]`                              |
| Critical                         | `[CRITICAL]`                          |

The script (`scripts/grade.sh`) counts occurrences of `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]` in the issue list — not their sentence-case names. An issue written `Minor: missing comment` will be counted as zero issues, producing a silent A+.

Always tag with brackets:
- ✅ Correct: `[MINOR] missing JSDoc on public helper | utils.ts:42`
- ❌ Wrong: `Minor: missing JSDoc on public helper | utils.ts:42`

The script ignores tags inside fenced code blocks and inline backticks (so prose that quotes the tag for documentation purposes — like this paragraph — does not inflate counts).

## Grade Calculation

Grade is determined by the **worst issue severity** present, then refined by **quantity of issues at that severity level**.

| Grade | Worst Issue | Quantity Rule |
|-------|-------------|---------------|
| **A+** | None | Zero issues |
| **A** | Minor | 1–5 minors |
| **A-** | Minor | > 5 minors |
| **B+** | Low | Exactly 1 low |
| **B** | Low | 2–5 lows |
| **B-** | Low | > 5 lows |
| **C+** | Medium | Exactly 1 medium |
| **C** | Medium | 2–5 mediums |
| **C-** | Medium | > 5 mediums |
| **D+** | High | Exactly 1 high |
| **D** | High | 2–5 highs |
| **D-** | High | > 5 highs |
| **E+** | Critical | Exactly 1 critical |
| **E** | Critical | 2–5 criticals |
| **E-** | Critical | > 5 criticals |
| **F** | Non-functional | Does not build, does not run, or produces no usable output |

**The worst issue dominates.** 3 minors + 1 medium = C+ (not A).

## Grade Ordering

A+ > A > A- > B+ > B > B- > C+ > C > C- > D+ > D > D- > E+ > E > E- > F

## Minimum Grade

Defined during `/aid-config` and stored in `.aid/settings.yml` under
`review.minimum_grade` (global default) with optional per-skill overrides
(e.g., `discover.minimum_grade`, `execute.minimum_grade`). All phases resolve
their threshold via:

```
bash .claude/scripts/config/read-setting.sh --skill <name> --key minimum_grade --default A
```

The three-tier resolution is: per-skill override → global `review.minimum_grade` →
hardcoded default. The loop continues until grade ≥ minimum grade.

## Why This Scale

- **Deterministic** — reviewer classifies issues by severity; grade is calculated, not judged
- **Progress visible** — D → C means all highs are resolved; B → A means all lows are resolved
- **Loop detection** — same grade across 3 cycles = systemic issue, not fixable by retry
- **Universal** — same rubric for KB docs, requirements, specs, code, everything
