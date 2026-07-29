> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`AGENT.md`](AGENT.md) in this folder.

# aid-reviewer

**Core Agent — present in every AID pipeline**

The Reviewer adversarially evaluates any artifact — code, tasks, specs, plans, or KB documents — against its acceptance criteria, rubric, and KB conventions. It judges, classifies, and reports issues but does NOT fix them and does NOT grade. Grading is computed deterministically from the Reviewer's structured output by a separate script.

## What It Does

The Reviewer reads completed work, compares it against TASK acceptance criteria, SPEC.md constraints, and KB conventions, then produces a structured issue list. Every issue is tagged by source (CODE, TASK, SPEC, KB, ARCHITECTURE) and severity (CRITICAL, HIGH, MEDIUM, LOW, MINOR). The grade is *computed* from this list — it is not a judgment the Reviewer makes.

The Reviewer consolidates the former KB-document review role (previously a separate agent scoped to aid-discover): both used the same adversarial review pattern, the same 8-column issue ledger, and the same independence rule. The only difference was the target artifact (KB docs vs. implementation/specs). Target artifact is a dispatch parameter — the review pattern is the same agent.

This reconciles the B6 finding: discovery-reviewer lacked the `## Self-review discipline` block that the standard pattern carries. Now that both roles are merged into a single agent that uses the shared boilerplate, the Self-review block is present uniformly.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Detail** | Reviews task breakdown and FIRST-RUN output |
| **Specify** | Reviews SPEC.md for quality and completeness |
| **Plan** | Reviews PLAN.md |
| **Execute** | REVIEW and DELIVERY-GATE states: reviews implementation work |
| **Interview / Define** | CROSS-REFERENCE state (and the DESCRIBE-SEED greenfield gate): reviews interview / feature-decomposition outputs |
| **Deploy** | Optional pre-release final verification |
| **Discover** | Reviews KB documents produced by the Researcher |

## What It Produces

- **Structured issue list** in a **per-attempt scratch** ledger (`<scope>-cycle<N>.md`) — the 8-column
  reviewer ledger. The durable `<scope>.md` is written by the orchestrator alone, and the Reviewer is
  never told its path, so cross-cycle contamination is structural rather than a rule to remember.
- **Test results** recorded in the work `STATE.md` `## Tasks Status` row for the task
- **A rule ID on every finding**, from the artifact's rule set in
  `canonical/aid/templates/review-rubrics/INDEX.md`. The former source tags (`[CODE]`, `[TASK]`,
  `[SPEC]`, `[KB]`, `[ARCHITECTURE]`) are **retired** — the class prefix in the rule ID carries what
  they asserted, so the tag can no longer contradict the rule.
- Severity levels: `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]`
- **Coverage rows** (`U-NNN`) checkpointing which units it examined, and **gap rows** (`G-NNN`) where
  no rule existed to judge by. Neither affects the grade.

## Cycles and Resume

A review is one or more **attempts**. Each attempt owns a scratch ledger; the attempt ends when that
scratch is merged and deleted.

- **New cycle** (after a FIX): a fresh scratch, so coverage starts empty — correct, because a new pass
  re-examines everything.
- **Resume** (same attempt, interrupted): the *same* scratch, so the Reviewer sees its own coverage and
  its own partial findings and continues where it stopped.

Which one it is comes from a single `test -f` on the scratch path, not from a flag — so correctness does
not depend on anyone declaring the mode correctly.

**The Reviewer never reconciles.** It records what it finds; the orchestrator joins scratch to durable
on `(Doc, Rule)` afterwards. That split exists because independence protects *judgment*, not
bookkeeping: withholding the prior verdict is what keeps cycle N's severity from being anchored by
cycle N−1's, and you cannot both withhold that verdict and ask the Reviewer to update it.

A finding is only marked `Fixed` when it is absent from a later attempt **and** that attempt's coverage
shows the artifact was actually examined. Absence alone proves nothing, which is why the coverage
manifest exists.

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
- **Objective criteria only, from exactly two sources.** Every issue cites a rule from either the **Knowledge Base** or the **work's own specification documents** (REQUIREMENTS, SPEC, BLUEPRINT, DETAIL). There is no third source: general practice, convention the Reviewer happens to know, and its own prior experience are all inadmissible as criteria. Where no rule speaks to the concern, the Reviewer reports a **gap in the criteria**, never an invented defect.
- **No confirmation bias.** The Reviewer does not know (or care) how hard the task was or how many iterations it took.
- **Evidence for every issue.** File path, line number, the specific criterion violated. No vague criticism.
- **Severity is looked up, not judged. Grade is the script's job.** Severity is a property of the violated rule and of where the artifact sits, resolved in two steps from [`canonical/aid/templates/grading-rubric.md#severity-scale`](canonical/aid/templates/grading-rubric.md#severity-scale): modality sets the band, then blast radius × reversibility selects within the MUST band. Two reviewers with the same finding and the same rule must reach the same severity. The Reviewer never writes a letter grade — that calculation is deterministic and lives in `canonical/aid/scripts/grade.sh`.

## Severity Classification

Severity is **looked up, not judged**, from the single canonical scale:
[`canonical/aid/templates/grading-rubric.md#severity-scale`](canonical/aid/templates/grading-rubric.md#severity-scale).

Two steps: the violated rule's **modality** sets the band (MUST / SHOULD / COULD), then for a
MUST, **blast radius x reversibility** selects within it. This document deliberately does not
restate the bands -- one definition, one place.

## Escalation

- **SPEC itself has issues** → writes a Q&A entry to the work `STATE.md` `## Cross-phase Q&A` section (tagged with the feature ID)
- **KB conventions are contradictory** → writes a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` section
- **Cannot run tests** (environment issues) → reports to Orchestrator
