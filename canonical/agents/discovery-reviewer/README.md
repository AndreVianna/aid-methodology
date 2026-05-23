> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# Discovery Reviewer

**Sub-agent in the `/aid-discover` pipeline — the quality gate. Runs AFTER all 5 analyst agents complete, with clean context.**

The Reviewer reads the Knowledge Base on disk and grades it against reality. The Reviewer never fixes anything — only finds and reports.

## What It Does

1. **Reads every populated KB document** — all 16 plus INDEX, README, CLAUDE.md placeholders.
2. **Cross-references claims against the codebase** — spot-checks file paths, line numbers, version pins, schema claims.
3. **Identifies severity-tagged issues** — CRITICAL / HIGH / MEDIUM / MINOR.
4. **Performs verification spot-checks** — minimum 10 per review pass.
5. **Computes per-document grades and overall grade** — using the rubric in `grading-rubric.md`.

## When It Is Invoked

| Phase | Purpose |
|---|---|
| `aid-discover` Step 6 (Review) | First grading pass after all analysts complete. |
| `aid-discover` Step 9 (Re-review) | After FIX mode applies fixes — re-grades with clean context. |

## What It Produces

- **Updates to `.aid/knowledge/STATE.md`** — Issues section, per-doc grades, overall grade, verification spot-checks, review history entries, new Q&A entries when findings reveal information gaps. (Discovery area state, post-FR2 consolidation.)

## Tools

Read, Glob, Grep, Bash, Write. Runs with `permissionMode: bypassPermissions` (background).

## Tier

**Large** — judgment-heavy: severity assignment, evidence weighing, grade computation.

## Reviewer is Not the Author

The Reviewer never also wrote what it is reviewing. The orchestrator gives it clean context — no knowledge of which agent produced which document, no view of the generation process. This prevents review-of-own-work bias.

## Key Behaviors

- **Evidence-required.** Every finding cites a file path or KB section.
- **Severity-disciplined.** A HIGH finding actually blocks the grade; does not get used for taste.
- **Q&A-additive.** When a review finding reveals a question only the human can answer, the Reviewer writes it as a Q&A entry — does not invent an answer.
- **Grade-deterministic.** Uses the rubric mechanically. Worst issue dominates per the formula. No "B+ feels right" judgments.
