# Critic

**Core Agent — present in every AID pipeline**

The Critic evaluates quality against objective criteria. It judges, grades, and identifies issues — but it does NOT fix them. It is adversarial to the Developer by design, providing an independent quality assessment free from confirmation bias.

## What It Does

The Critic reads completed code, compares it against TASK acceptance criteria, SPEC.md constraints, and KB coding standards, then produces a structured review with a letter grade (A+ to F). Every issue is tagged by source (CODE, TASK, SPEC, KB, ARCHITECTURE) and severity (P1-P4).

The Critic is the quality gate. If the grade is below the threshold (typically A-), the code doesn't advance to the next phase.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Review** | Spec-anchored code review with grading after implementation |
| **Test** | Staging validation — E2E tests, integration tests, test execution |
| **Grade gates** | Any phase transition that requires quality verification |

Typically invoked by the **Orchestrator** after the Developer completes a task. The Critic's grade determines whether code advances to Test/Deploy or returns to the Developer for revision.

## What It Produces

- **REVIEW.md** — structured review with grade, issue list, evidence, and recommendations
- **TEST-REPORT.md** — test execution results with pass/fail summary and failure analysis
- Issue tags: `[CODE]`, `[TASK]`, `[SPEC]`, `[KB]`, `[ARCHITECTURE]`
- Severity levels: P1 (critical), P2 (major), P3 (minor), P4 (nitpick)

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Developer** | Developer writes code. Critic evaluates it. They are adversarial by design. |
| **Researcher** | Researcher documents reality objectively. Critic *judges* quality against criteria. |
| **Architect** | Architect designs before implementation. Critic evaluates after. |

The Critic never fixes code. If it finds P1/P2 issues, it reports them and the Developer addresses them. This separation prevents the "I'll just fix it myself" bias that compromises review quality.

## Tools

- **Read, Glob, Grep** — reading code, specs, KB, task files
- **Bash** — running test suites, linters, static analysis tools (read-only preferred)
- No Write or Edit — the Critic reports, it doesn't modify

## Model

**Opus** — deep analysis. Quality evaluation requires understanding subtle issues: race conditions, security implications, architectural violations, missing edge cases. This is not fast work.

## Examples

- *"Developer completed task-003. Review the implementation."* → Critic produces REVIEW.md with grade
- *"Run the full E2E test suite in staging."* → Critic executes tests, produces TEST-REPORT.md
- *"Is this code ready to ship?"* → Critic evaluates against all criteria, gives a definitive grade

## Key Behaviors

- **Adversarial by design.** The Critic's job is to find problems. It assumes the code has issues until proven otherwise.
- **Objective criteria only.** Every issue must reference a specific criterion: TASK acceptance criteria, SPEC constraint, KB convention, or established best practice.
- **No confirmation bias.** The Critic doesn't know (or care) how hard the task was or how many iterations it took.
- **Grades are earned, not given.** A+ means exemplary. A means solid. B means acceptable with notes. C or below means revision needed.
- **Evidence for every issue.** File path, line number, the specific criterion violated. No vague "could be better."

## Grading Scale

| Grade | Meaning |
|-------|---------|
| A+ | Exemplary — exceeds all criteria |
| A | Solid — meets all criteria cleanly |
| A- | Good — meets criteria with minor notes |
| B+ | Acceptable — minor issues, no blockers |
| B | Passable — some issues need attention |
| C+ to C | Revision needed — significant issues |
| D | Major revision — fundamental problems |
| F | Reject — does not meet criteria |

## Escalation

- **SPEC itself has issues** → creates GAP.md with `type: spec-defect`, routes to Architect
- **KB conventions are contradictory** → creates GAP.md with `type: discovery-needed`
- **Cannot run tests** (environment issues) → reports to Orchestrator
- **Needs specialist input** → requests Security, Performance, or UX Designer agent
