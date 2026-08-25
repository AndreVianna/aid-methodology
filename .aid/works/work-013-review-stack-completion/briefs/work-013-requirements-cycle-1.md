ARTIFACTS UNDER REVIEW:
  - .aid/works/work-013-review-stack-completion/REQUIREMENTS.md

CONTEXT:
  - This is cycle 1 of the Describe-phase gate for work-013 "Review Stack Completion".
  - The work is a thin successor to a canceled review-redesign work. Its branch is based on
    master, and master's review stack is treated as law by this work: the declared
    `review-criteria:` cascade (`.aid/knowledge/authoring-conventions.md`), the 7-column ledger
    (`canonical/aid/templates/reviewer-ledger-schema.md`), VERIFY/HUNT scoped cycles and the
    cost meter (`canonical/aid/templates/reviewer-dispatch.md`, `tests/review-cost-meter.sh`),
    and one review skill (`canonical/skills/aid-review/SKILL.md`) with one reviewer agent
    (`canonical/agents/aid-reviewer/AGENT.md`).
  - The artifact under review is a REQUIREMENTS.md produced outside a live `/aid-describe`
    interview: it was authored directly from owner decisions, then revised once.
  - Descriptive only. Nothing in this CONTEXT is itself a criterion.

RUBRIC: REQUIREMENTS.md artifact conformance + factual accuracy against the repository
  Grade this artifact on:
  1. **Structural conformance** to the REQUIREMENTS.md contract:
     - `canonical/aid/templates/requirements/requirements-template.md` (template + conventions)
     - `.aid/knowledge/artifact-schemas.md § REQUIREMENTS.md` and its
       "Required-section contract" bullet.
     Includes: `# Requirements` heading with `Name` + `Description`; mandatory
     `## Change Log` table; all 10 numbered sections present in order
     (1 Objective · 2 Problem Statement · 3 Users & Stakeholders as a table · 4 Scope with
     In/Out subsections · 5 Functional Requirements · 6 Non-Functional Requirements ·
     7 Constraints · 8 Assumptions & Dependencies · 9 Acceptance Criteria · 10 Priority);
     unaddressed sections marked `*(pending)*` rather than deleted; acceptance criteria
     testable.
  2. **Factual accuracy against disk.** Every claim the document makes about the current
     repository state must be true on this working tree. Verify claims by reading the cited
     files or running the obvious command; a claim that is false, unverifiable, or that
     describes a state belonging to a different branch is a finding.
  3. **Internal consistency.** Scope vs Functional Requirements vs Acceptance Criteria must
     agree; no requirement may contradict another; no acceptance criterion may be a no-op
     against the tree it will be measured on.
  4. **Vocabulary consistency with the current stack.** Terms drawn from the abandoned
     redesign (for example rubric-catalog "kinds", an 8-column `Rule` ledger, deep/light
     review skills) are findings when used as if they were current law, unless the document
     is explicitly naming them as history.
  5. **Criteria cascade.** Resolve and apply this artifact's own review criteria per
     `.aid/knowledge/authoring-conventions.md` (global + type + any file-level block). Cite
     the criterion `id` as the `Description` prefix where a declared criterion applies. Where
     no declared criterion covers a real defect, still report it, and say plainly in Evidence
     that no criterion declares it (do not invent an id).

OUT OF SCOPE (do not grade against):
  - Every file other than the one artifact listed above. In particular, do not grade
    `canonical/**`, `.aid/knowledge/**`, `tests/**`, or the sibling work files
    (`STATE.yml`, `ORIGIN.md`) — they may be read to verify a claim or resolve criteria,
    but they are not under review.
  - Whether the owner's strategic decisions are correct (master-as-base; track order
    T1 -> T2 -> T3; migrate catalog rows into the cascade; default-delete abandoned scripts).
    Those are settled inputs. Grade only whether the document states them accurately and
    consistently.
  - The canceled predecessor work's own artifacts and grades.
  - Any proposal about how the tracks should later be decomposed into features or deliveries.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as rows with Status: OOS in the same ledger table. Record the
  routing destination (which upstream phase/skill the observation belongs to) in
  the Description/Evidence text. OOS rows do NOT count toward severity totals and
  do NOT affect the grade.

DELIVERABLES:
  - Findings ledger at `.aid/.temp/review-pending/work-013-requirements.md` per
    `canonical/aid/templates/reviewer-ledger-schema.md`
  - Output format: ONE markdown table only, no headers/narrative
  - Severity tags MUST be bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR]
  - Status enum: Pending / Fixed / Recurred / Accepted / OOS / Invalid
  - For new findings this cycle: append rows with Status: Pending
  - For existing rows from prior cycles: update Status only (Fixed if resolved, Recurred if regressed)
  - Do NOT include severity tag-strings in narrative or summary text
    (qualitative summary goes in the agent return message, not the ledger file)
  - OOS observations: append as Status: OOS rows in the same ledger table, with
    the routing destination noted in Description/Evidence (they do not count
    toward the grade)
