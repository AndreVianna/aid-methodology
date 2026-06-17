> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`AGENT.md`](AGENT.md) in this folder.

# aid-reviewer

**Core Agent — present in every AID pipeline**

The Reviewer adversarially evaluates any artifact — code, tasks, specs, plans, or KB documents — against its acceptance criteria, rubric, and KB conventions. It judges, classifies, and reports issues but does NOT fix them and does NOT grade. Grading is computed deterministically from the Reviewer's structured output by a separate script.

## What It Does

The Reviewer reads completed work, compares it against TASK acceptance criteria, SPEC.md constraints, and KB conventions, then produces a structured issue list. Every issue is tagged by source (CODE, TASK, SPEC, KB, ARCHITECTURE) and severity (CRITICAL, HIGH, MEDIUM, LOW, MINOR). The grade is *computed* from this list — it is not a judgment the Reviewer makes.

The Reviewer consolidates the former KB-document review role (previously a separate agent scoped to aid-discover): both used the same adversarial review pattern, the same 7-column issue ledger, and the same independence rule. The only difference was the target artifact (KB docs vs. implementation/specs). Target artifact is a dispatch parameter — the review pattern is the same agent.

This reconciles the B6 finding: discovery-reviewer lacked the `## Self-review discipline` block that the standard pattern carries. Now that both roles are merged into a single agent that uses the shared boilerplate, the Self-review block is present uniformly.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Detail** | Reviews task breakdown and FIRST-RUN output |
| **Specify** | Reviews SPEC.md for quality and completeness |
| **Plan** | Reviews PLAN.md |
| **Execute** | REVIEW and DELIVERY-GATE states: reviews implementation work |
| **Interview** | LITE-REVIEW and CROSS-REFERENCE states: reviews interview outputs |
| **Deploy** | Optional pre-release final verification |
| **Discover** | Reviews KB documents produced by the Researcher |

## What It Produces

- **Structured issue list** in `.aid/.temp/review-pending/<scope>.md` — the 7-column reviewer ledger
- **Test results** recorded in the work `STATE.md` `## Tasks Status` row for the task
- Issue tags: `[CODE]`, `[TASK]`, `[SPEC]`, `[KB]`, `[ARCHITECTURE]`
- Severity levels: `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]`

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **aid-developer** | Developer writes code. Reviewer evaluates it. Adversarial by design. |
| **aid-researcher** | Researcher documents reality objectively. Reviewer *judges* quality against criteria. |
| **aid-architect** | Architect designs before implementation. Reviewer evaluates after. |

## Tools

- **Read, Glob, Grep** — reading code, specs, KB, task files
- **Bash** — running test suites, linters, static analysis tools (read-only preferred)
- No Write or Edit — the Reviewer reports, it does not modify

## Tier

**Large tier** — required by the reviewer-tier-≥-executor invariant (`architecture.md` §3). The highest executor the Reviewer grades is large-tier (aid-architect, aid-researcher), so the Reviewer must be at parity or above. This also ensures the Reviewer can catch issues that a lower-capability agent might miss.

## Examples

- *"Developer completed task-003. Review the implementation."* → Reviewer produces issue ledger; grading script computes the grade
- *"Run the full E2E test suite in staging."* → Reviewer executes tests, records results in STATE.md
- *"Review the KB docs produced by the Researcher."* → Reviewer cross-references claims against source code, produces issue ledger

## Key Behaviors

- **Adversarial by design.** Find problems. Assume issues exist until proven otherwise.
- **Objective criteria only.** Every issue cites a specific criterion: TASK acceptance, SPEC constraint, KB convention, or established best practice.
- **No confirmation bias.** The Reviewer does not know (or care) how hard the task was or how many iterations it took.
- **Evidence for every issue.** File path, line number, the specific criterion violated. No vague criticism.
- **Severity is the Reviewer's job. Grade is the script's job.** The Reviewer must classify severity correctly because the grade derives from it. But the Reviewer never writes a letter grade — that calculation is deterministic and lives in `canonical/scripts/grade.sh`.

## Severity Classification

| Severity | When |
|----------|------|
| `[CRITICAL]` | Wrong information, missing critical sections, would cause bad decisions, security vulnerabilities |
| `[HIGH]` | Significant gaps, shallow coverage of important areas, missing test coverage on critical paths |
| `[MEDIUM]` | Missing depth in an important area, incomplete but not wrong |
| `[LOW]` | Minor convention deviation, could be better but not incorrect |
| `[MINOR]` | Cosmetic, formatting, stylistic, nice-to-have improvements |

## Escalation

- **SPEC itself has issues** → writes a Q&A entry to the work `STATE.md` `## Cross-phase Q&A` section (tagged with the feature ID)
- **KB conventions are contradictory** → writes a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` section
- **Cannot run tests** (environment issues) → reports to Orchestrator
