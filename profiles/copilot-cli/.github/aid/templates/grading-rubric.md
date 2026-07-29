# Grading Rubric — Universal

Applies to all AID phases. Grade is **deterministic** — calculated from issue count and severity. The reviewer classifies issues; the grade follows automatically.

<!-- AID:SEVERITY-SCALE:BEGIN -->
## Severity Scale

**This is the single definition of severity in AID.** Every other document that needs one
points here; none restates it. The five bracketed tokens are unchanged — only their meanings
are, which is what keeps `grade.sh` and every existing ledger valid.

Severity is **looked up, never felt.** It is a property of the rule that was violated and of
where the artifact sits — not of the reviewer's confidence, effort, or opinion. Two reviewers
with the same finding and the same rule must reach the same severity. If they do not, the rule
is underspecified; raise that instead.

Assignment is two steps. Neither is a judgment call.

**Step 1 — the violated rule's modality sets the band.**

Every criterion comes from exactly one of two sources: the Knowledge Base, or the work's own
specification documents (REQUIREMENTS, SPEC, BLUEPRINT, DETAIL). Each carries an explicit
modality.

| Modality of the violated rule | Severity |
|---|---|
| **MUST** | Continue to Step 2 — one of `[CRITICAL]`, `[HIGH]`, `[MEDIUM]` |
| **SHOULD** | `[LOW]`, or `[MEDIUM]` when the blast radius has escaped |
| **COULD** | `[MINOR]` |

**Step 2 — blast radius and reversibility select within the MUST band.**

| | Correction is **local** — editing this artifact restores correctness, and nothing that already consumed it must change | Correction is **non-local** — restoring correctness requires redoing, discarding, or migrating work that already consumed this artifact |
|---|---|---|
| **Blast radius confined** — nothing downstream depends on the defective element yet | `[MEDIUM]` | `[HIGH]` |
| **Blast radius escaped** — at least one downstream artifact, execution, or stored state already depends on it | `[HIGH]` | `[CRITICAL]` |

**The two axes, defined.**

- **Blast radius** — the set of things whose correctness depends on the defective element.
  *Confined* means only a reader of this artifact is affected. *Escaped* means at least one
  downstream artifact, execution, release, or stored state already rests on it. This is a fact
  about the dependency graph at review time, and it is checkable: **name the dependent, or the
  radius is confined.**
- **Reversibility** — what correcting the defect requires. *Local* means editing this artifact
  restores correctness and nothing else must change. *Non-local* means correction requires
  undoing work: re-running a consumer and discarding its output, migrating data, amending a
  published artifact, or reversing an effect outside this repository. This is a fact about what
  the correction requires, **not about how long it would take**.

**The five bands in plain terms.**

| Token | Meaning |
|---|---|
| `[CRITICAL]` | A MUST is violated, the defect has already escaped into things built on this artifact, and correcting it means undoing that downstream work. |
| `[HIGH]` | A MUST is violated, and either it has escaped into a dependent (correctable locally) or it is still confined but correcting it forces downstream rework. |
| `[MEDIUM]` | A MUST is violated, still confined, and a local edit fully corrects it. Also: a violated SHOULD whose effect has escaped into a dependent. |
| `[LOW]` | A SHOULD is violated. A consumer still reaches the right outcome but pays a cost — looking elsewhere, inferring a detail, working around. |
| `[MINOR]` | A COULD is violated. No consumer's outcome or cost changes. |

**Three rules that hold in every band.**

1. **No evidence, no finding.** A finding must cite the disk truth that contradicts the
   artifact's claim, or the command that produces it. A finding that cannot be evidenced is
   **inadmissible** — not recorded at a lower severity, not recorded at all.
2. **Confidence never modifies severity.** Uncertainty about whether a rule applies is a
   question for the user, not a reason to soften a band.
3. **No criterion, no finding.** If no rule in the Knowledge Base or the work's specification
   documents speaks to the concern, you have found a gap in the criteria, not a defect in the
   artifact. Report the gap. Do not invent the rule, and do not substitute general practice for
   it.

`F` remains outside this scale. It is not a severity but a whole-artifact verdict — does not
build, does not run, produces no usable output — set via `grade.sh --non-functional`.
<!-- AID:SEVERITY-SCALE:END -->

## Issue Tagging Convention

Issues must be tagged with the bracketed all-caps form so the grading script counts them correctly:

| Sentence-case (descriptive only) | Bracketed tag (counted by `grade.sh`) |
|----------------------------------|---------------------------------------|
| Minor                            | `[MINOR]`                             |
| Low                              | `[LOW]`                               |
| Medium                           | `[MEDIUM]`                            |
| High                             | `[HIGH]`                              |
| Critical                         | `[CRITICAL]`                          |

The script (`.github/aid/scripts/grade.sh`) counts occurrences of `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]` in the issue list — not their sentence-case names. An issue written `Minor: missing comment` will be counted as zero issues, producing a silent A+.

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
bash .github/aid/scripts/config/read-setting.sh --skill <name> --key minimum_grade --default A
```

The three-tier resolution is: per-skill override → global `review.minimum_grade` →
hardcoded default. The loop continues until grade ≥ minimum grade.

## Why This Scale

- **Deterministic** — reviewer classifies issues by severity; grade is calculated, not judged
- **Progress visible** — D → C means all highs are resolved; B → A means all lows are resolved
- **Loop detection** — same grade across 3 cycles = systemic issue, not fixable by retry
- **Universal** — same rubric for KB docs, requirements, specs, code, everything
