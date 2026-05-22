# Reviewer

**Core Agent — present in every AID pipeline**

The Reviewer evaluates quality against objective criteria. It judges, classifies, and reports issues — but it does NOT fix them, and it does NOT grade. Grading is computed deterministically from the Reviewer's structured output by a separate script. The Reviewer is adversarial to the Developer by design, providing an independent quality assessment free from confirmation bias.

## What It Does

The Reviewer reads completed work, compares it against TASK acceptance criteria, SPEC.md constraints, and KB conventions, then produces a structured issue list. Every issue is tagged by source (CODE, TASK, SPEC, KB, ARCHITECTURE) and severity (CRITICAL, HIGH, MEDIUM, LOW, MINOR). The grade is *computed* from this list — it is not a judgment the Reviewer makes.

The Reviewer is the quality gate. If the computed grade is below threshold, the work doesn't advance.

## What It Doesn't Do

- **Fix code.** The Developer addresses issues. This separation prevents the "I'll just fix it myself" bias that compromises review quality.
- **Assign grades by judgment.** Grades are *calculated* — `worst severity × count → grade` — by `templates/scripts/grade.sh`. The Reviewer's job ends at producing a complete, evidence-tagged issue list.
- **Design solutions.** That's the Architect.
- **Investigate unfamiliar subsystems.** That's the Researcher.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Review** | Spec-anchored review with structured issue output after implementation |
| **Test** | Staging validation — E2E tests, integration tests, test execution |
| **Grade gates** | Any phase transition that requires quality verification |

Typically invoked by the **Orchestrator** after the Developer completes a task. The grading script reads the Reviewer's output and determines whether work advances or returns for revision.

## What It Produces

- **REVIEW.md** — structured issue list with source/severity tags, evidence, and recommendations
- **TEST-REPORT.md** — test execution results with pass/fail summary and failure analysis
- Issue tags: `[CODE]`, `[TASK]`, `[SPEC]`, `[KB]`, `[ARCHITECTURE]`
- Severity levels: `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]`

The grading script consumes the issue list and emits a grade. Worst severity dominates; counts within a severity tier determine the modifier (+ / nothing / -).

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Developer** | Developer writes code. Reviewer evaluates it. Adversarial by design. |
| **Researcher** | Researcher documents reality objectively. Reviewer *judges* quality against criteria. |
| **Architect** | Architect designs before implementation. Reviewer evaluates after. |
| **discovery-reviewer** | discovery-reviewer grades the Knowledge Base specifically. Reviewer grades implementation work. |

## Tools

- **Read, Glob, Grep** — reading code, specs, KB, task files
- **Bash** — running test suites, linters, static analysis tools (read-only preferred)
- No Write or Edit — the Reviewer reports, it doesn't modify

## Tier

**Large tier** — quality evaluation requires understanding subtle issues: race conditions, security implications, architectural violations, missing edge cases. The Reviewer's value is finding what the Developer's blind spots missed; sharing the Developer's tier defeats the purpose.

The Reviewer ≥ executor invariant is enforced. When reviewing Architect or Security output, the Reviewer is at parity. When reviewing Developer (Medium-tier) output, the Reviewer is one tier above. Never below.

## Examples

- *"Developer completed task-003. Review the implementation."* → Reviewer produces REVIEW.md with structured issue list; grading script computes the grade
- *"Run the full E2E test suite in staging."* → Reviewer executes tests, produces TEST-REPORT.md
- *"Is this code ready to ship?"* → Reviewer evaluates against all criteria, produces evidence-tagged findings; the grade follows from the rubric

## Key Behaviors

- **Adversarial by design.** Find problems. Assume issues exist until proven otherwise.
- **Objective criteria only.** Every issue cites a specific criterion: TASK acceptance, SPEC constraint, KB convention, or established best practice.
- **No confirmation bias.** The Reviewer doesn't know (or care) how hard the task was or how many iterations it took.
- **Evidence for every issue.** File path, line number, the specific criterion violated. No vague "could be better."
- **Severity is the Reviewer's job. Grade is the script's job.** The Reviewer must classify severity correctly because the grade derives from it. But the Reviewer never writes a letter grade — that calculation is deterministic and lives in `templates/scripts/grade.sh`.

## Severity Classification

| Severity | When |
|----------|------|
| `[CRITICAL]` | Wrong information, missing critical sections, would cause bad decisions, security vulnerabilities |
| `[HIGH]` | Significant gaps, shallow coverage of important areas, missing test coverage on critical paths |
| `[MEDIUM]` | Missing depth in an important area, incomplete but not wrong |
| `[LOW]` | Minor convention deviation, could be better but not incorrect |
| `[MINOR]` | Cosmetic, formatting, stylistic, nice-to-have improvements |

The grading script reads these tags and applies the rubric in `templates/grading-rubric.md`.

## Grading Rubric (computed, not judged)

The full rubric lives in [`templates/grading-rubric.md`](../../templates/grading-rubric.md). Worst severity dominates; count within that severity tier determines the modifier (`+` / none / `-`). The grading script applies the table — the Reviewer never assigns a letter grade.

Run it after producing the issue list:

```bash
templates/scripts/grade.sh REVIEW.md
# or
cat REVIEW.md | templates/scripts/grade.sh
```

## Escalation

- **SPEC itself has issues** → creates GAP.md with `type: spec-defect`, routes to Architect
- **KB conventions are contradictory** → creates GAP.md with `type: discovery-needed`
- **Cannot run tests** (environment issues) → reports to Orchestrator
- **Needs specialist input** → requests Security, Performance, or UX Designer agent
