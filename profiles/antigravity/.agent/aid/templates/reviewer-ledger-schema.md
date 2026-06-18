---
kb-category: meta
source: hand-authored
intent: |
  The canonical schema for every reviewer-output ledger in AID. Applies to all
  REVIEW states across all skills (discover, execute, specify, plan, detail,
  interview, summarize, deploy), to every script-based validator, and to
  ad-hoc user-prompted reviews. Defines the table shape, severity + status
  enums, file lifecycle, and grade.sh integration. Single source of truth so
  grade.sh, agents, skills, and humans all read findings identically.
contracts:
  - "7-column table is the entire ledger file (no headers, no narrative, no sections)"
  - "Severity enum: [CRITICAL] | [HIGH] | [MEDIUM] | [LOW] | [MINOR]"
  - "Status enum: Pending | Fixed | Recurred | Accepted | OOS | Invalid"
  - "Grade is computed over rows where Status ∈ {Pending, Recurred}, by Severity column"
  - "File path: .aid/.temp/review-pending/<scope>.md (scope = skill or skill-task)"
  - "Persists across REVIEW→FIX cycles within one skill invocation; deleted at skill DONE"
changelog:
  - 2026-05-28: Initial schema spec
---

# Reviewer Ledger Schema

This document is the **canonical schema for every reviewer-output ledger in AID.** Every review — whether dispatched to a sub-agent, run by a script-based validator, or performed ad-hoc in response to a user prompt — MUST conform to this schema.

## File: contents

The ledger file contains **exactly one markdown table.** No frontmatter, no section headers, no narrative, no summary section, no out-of-scope section. Just the table — every row is one finding (or one accepted exception).

```markdown
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [HIGH] | Pending | foo.md | 42 | claim Y is wrong | doc says Y, `wc -l target = N` shows actual Z |
| 2 | [LOW] | Fixed | bar.md | 100 | stale path reference | path/to/foo deleted commit abc123; cycle-4 FIX removed cite |
| 3 | [MINOR] | Accepted | baz.md | — | one-sentence body | no-docs variant accepted by user cycle-1 Q10 |
| 4 | [HIGH] | Recurred | qux.md | 17 | count off by 1 | claim 16 vs disk 15; was Fixed cycle-3, returned cycle-5 |
| 5 | [LOW] | OOS | quux.md | 200 | inline T3 line-count violation | accurate value but P1 policy violation; methodology-refactor pending |
```

## File: location

`.aid/.temp/review-pending/<scope>.md`

Where `<scope>` identifies the skill (and optionally the work-item / task) so per-skill / per-task ledgers don't collide.

| Skill invocation | Ledger path |
|---|---|
| `/aid-discover` (whole-KB review) | `.aid/.temp/review-pending/discovery.md` |
| `/aid-execute task-NNN` | `.aid/.temp/review-pending/execute-task-NNN.md` |
| `/aid-specify <feature>` | `.aid/.temp/review-pending/specify-<feature>.md` |
| `/aid-plan` | `.aid/.temp/review-pending/plan.md` |
| `/aid-detail` | `.aid/.temp/review-pending/detail.md` |
| `/aid-interview <work>` cross-reference | `.aid/.temp/review-pending/interview-<work>-cross-ref.md` |
| `/aid-interview <work>` lite-review | `.aid/.temp/review-pending/interview-<work>-lite.md` |
| `/aid-summarize` machine validators | `.aid/.temp/review-pending/summarize.md` |
| `/aid-deploy` pre-deploy verify | `.aid/.temp/review-pending/deploy.md` |
| Ad-hoc user-prompted review | `.aid/.temp/review-pending/adhoc-<short-slug>.md` |

The `.aid/.temp/review-pending/` directory is gitignored (per `.gitignore` `.aid/.temp/` entry) — ledgers are local-only.

## Columns

| # | Column | Required | Purpose |
|---|---|---|---|
| 1 | `#` | yes | Row counter (1, 2, 3...) for cross-reference in commit messages and fix-agent dispatches. Sequential within the file; never renumbered. |
| 2 | `Severity` | yes | Bracketed severity tag (`[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]`). Brackets ensure the tag doesn't collide with bare numbers anywhere else in markdown. Drives grade computation. |
| 3 | `Status` | yes | Plain word (no brackets): `Pending`, `Fixed`, `Recurred`, `Accepted`, `OOS`, or `Invalid`. See **Status values** below. Drives grade computation. |
| 4 | `Doc` | yes | Affected file path (relative to repo root). Examples: `foo.md`, `.agent/aid/scripts/bar.sh`, `tests/canonical/baz.sh`. For doc-wide issues with no specific file, use `—`. |
| 5 | `Line` | yes | Affected line number, or a line range like `42-45`, or `—` for doc-wide. |
| 6 | `Description` | yes | ONE sentence stating what's wrong. Form: "claim X is wrong: doc says Y, actual Z." Avoid hedging or explanation; explanation goes in Evidence. |
| 7 | `Evidence` | yes | The disk-truth that contradicts the doc's claim, AND/OR the source-of-truth command. Form: "`wc -l foo = 1070` (doc claims 1071)" or "`grep -c X bar = 5` (doc claims 6)". For Status=Fixed/Recurred/Accepted/OOS/Invalid, include enough context to justify the status (e.g., "Fixed in commit abc123" or "Accepted: user decision cycle-1 Q5"). |

**Pipe-character escape:** if Description or Evidence contains a `|` (pipe), escape it as `\|` so the markdown table doesn't break.

## Severity values

| Tag | Meaning | Grade impact |
|---|---|---|
| `[CRITICAL]` | Factual error that will mislead downstream phases or break tooling. Build-broken, data-loss, security-broken category. | Drives grade to E (severity dominates) |
| `[HIGH]` | Wrong claim, dead reference, broken citation, or missing post-merge content. | Drives grade to D |
| `[MEDIUM]` | Internal inconsistency, off-by-1 in counts, or contract drift between docs. | Drives grade to C |
| `[LOW]` | Stale narrative, minor process violation (e.g., P1 inline-T3 with accurate value), or single-doc cosmetic issue. | Drives grade to B |
| `[MINOR]` | Cosmetic, wording drift, formatting nit. | Drives grade to A (or A- if >5) |

Worst severity dominates; count within that severity determines the modifier (1 → `+`, 2-5 → none, 6+ → `-`).

## Status values

| Status | Meaning | Counts toward grade? | Set by |
|---|---|---|---|
| `Pending` | Issue exists; needs fixing | **Yes** | Reviewer at first discovery |
| `Fixed` | Was Pending; reviewer confirmed resolved this cycle | No (kept for audit history) | Reviewer in a subsequent cycle |
| `Recurred` | Was Fixed in an earlier cycle but came back. Effectively pending again. | **Yes** (counts as Pending) | Reviewer in a subsequent cycle |
| `Accepted` | Pending but decided not to fix (e.g., acceptable carryover, no-docs variant). Description and Evidence must include the rationale + who decided. | No | Orchestrator with user authorization |
| `OOS` | Out of scope per the review rubric (e.g., inline-T3 violations with accurate values when methodology-refactor is tech-debt). | No | Reviewer or orchestrator |
| `Invalid` | Reviewer was wrong; the original claim was actually correct on disk. Description must explain the misread. | No | Reviewer in a subsequent cycle, or orchestrator with evidence |

**Workflow:**

1. **REVIEW (cycle 1):** create file; append rows as `Status: Pending` for every finding. Existing-file case: NO (cycle 1 is the first).
2. **REVIEW (cycle N≥2):** read existing file. For each existing `Pending` row: verify on disk → if resolved, change Status to `Fixed`; if still wrong, leave as `Pending`. For each existing `Fixed` row: verify still resolved → if regressed, change Status to `Recurred`. Append new rows as `Pending` for newly-found issues.
3. **FIX:** read Pending + Recurred rows. Address each. Do NOT mark rows `Fixed` during FIX — that's the next reviewer's job (separation of concerns: fixer fixes, reviewer verifies).
4. **Orchestrator (any phase):** may mark a row `Accepted` with user authorization (record rationale in Description). May mark `Invalid` if reviewer was wrong, with evidence.
5. **Skill reaches DONE:** orchestrator deletes the ledger file. If `.aid/.temp/review-pending/` is then empty, the directory is also removed.

## grade.sh integration

`.agent/aid/scripts/grade.sh` reads the ledger as a markdown table and counts findings by Severity, filtered to Status ∈ {`Pending`, `Recurred`}.

```bash
# Conceptual algorithm — actual implementation in grade.sh
for each row in ledger.md:
  if row.Severity matches "\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]":
    if row.Status in (Pending, Recurred):
      counts[severity]++

# Apply universal rubric: worst severity dominates, count determines modifier
if counts.CRITICAL > 0: grade = "E" + modifier(counts.CRITICAL)
elif counts.HIGH > 0:   grade = "D" + modifier(counts.HIGH)
elif counts.MEDIUM > 0: grade = "C" + modifier(counts.MEDIUM)
elif counts.LOW > 0:    grade = "B" + modifier(counts.LOW)
elif counts.MINOR > 0:  grade = "A" if counts.MINOR <= 5 else "A-"
else: grade = "A+"
```

`grade.sh` never greps prose; the table is the only source of severity tags counted. This eliminates the cycle-7 bug where a summary line "0 [CRITICAL] / 0 [HIGH]" was over-counted.

**Empty ledger (no rows at all) = A+** (artifact has zero findings).

**Empty file (zero bytes) = A+** (same as no ledger).

**No file at all = A+ for the artifact being reviewed** (no review = no findings). However, the orchestrator should not advance past REVIEW state without a ledger — the reviewer must create it.

## Lifecycle (per skill invocation)

```
First REVIEW
  └─ Reviewer reads existing ledger (none on first invocation → empty start)
  └─ Reviewer appends new findings as Pending rows
  └─ Reviewer commits the ledger file (via orchestrator)
  └─ Orchestrator runs grade.sh on the ledger to compute the grade
  └─ State machine advances (Q-AND-A or FIX)

FIX
  └─ Fixer reads ledger; addresses all Pending and Recurred rows
  └─ Fixer does NOT modify the ledger Status column (that's the next reviewer's job)
  └─ State machine advances back to REVIEW

Subsequent REVIEW (cycle N)
  └─ Reviewer reads existing ledger
  └─ For each existing row: re-verify against disk, update Status:
       - Pending and still wrong  → leave Pending
       - Pending and now resolved → Fixed
       - Fixed and still resolved → leave Fixed (audit history)
       - Fixed and regressed       → Recurred
  └─ Append new rows as Pending for newly-found issues
  └─ Orchestrator re-runs grade.sh

DONE (skill completion, e.g., /aid-discover APPROVAL granted)
  └─ Orchestrator deletes the ledger file: rm .aid/.temp/review-pending/<scope>.md
  └─ If .aid/.temp/review-pending/ is empty: rmdir .aid/.temp/review-pending/
```

## Authoring rules for the reviewer

**Always:**
- Emit the table as the ENTIRE file content. No frontmatter, no headers, no narrative.
- For new rows: assign the next sequential `#`; do NOT renumber existing rows.
- Cite the disk-truth in Evidence with a runnable command or specific file:line reference.
- Read the existing ledger BEFORE appending — use the existing Status patterns to identify Recurred regressions.

**Never:**
- Add a `## Summary` section with severity tag-strings (the cycle-7 bug — those tag strings get over-counted by simpler graders).
- Modify existing rows' Severity or Description (they're append-only history); only Status may change across cycles.
- Include narrative analysis in the file — that goes in the agent's return-message to the orchestrator, not in the ledger.
- Renumber rows when Fixed rows accumulate — they stay for the audit trail until DONE.

## Authoring rules for the fixer

**Always:**
- Read the ledger; address each `Pending` and `Recurred` row.
- Cite the row `#` in commit messages: "fix row #2 (LOW tech-debt PR snapshot stale)".

**Never:**
- Modify the ledger to mark a row `Fixed` — that's the next reviewer's job. The fixer addresses; the reviewer confirms.
- Change Severity of existing rows.
- Delete rows. Status updates handle resolution.

## Authoring rules for the orchestrator

**Always:**
- After REVIEW completes, run `grade.sh .aid/.temp/review-pending/<scope>.md` to compute the grade.
- After FIX completes, advance state to REVIEW (which re-verifies and updates Statuses).
- At skill DONE: delete the ledger file.
- For `Accepted` and `Invalid` Status changes: record the user authorization (which Q&A, which cycle, what rationale) in the Evidence column.

**Never:**
- Perform the review inline (always dispatch a reviewer sub-agent or invoke a validator script — the orchestrator only orchestrates).
- Hand-edit Severity or Description in the ledger (those are the reviewer's authorial domain).
- Carry a ledger past skill DONE (clean up on completion).

## Ad-hoc user-prompted reviews

When the user types a request like "review X for me" directly at the prompt (not inside a skill state machine), the orchestrator:

1. Identifies the artifact under review (the X) and chooses a scope slug (e.g., `adhoc-myfile`).
2. Creates `.aid/.temp/review-pending/adhoc-<slug>.md` if it doesn't exist.
3. Dispatches a reviewer sub-agent (`aid-reviewer`) with this schema as the output contract.
4. After sub-agent return: runs `grade.sh` on the ledger; reports findings + grade to the user.
5. Asks the user: "Apply fixes now (Status: Pending → Fixed flow), or leave the ledger for later?"
6. If the user is done with the ad-hoc review: delete the ledger.

The `CLAUDE.md` / `AGENTS.md` short rule (always loaded) is the trigger for ad-hoc compliance.

## See also

- `.agent/aid/scripts/grade.sh` — the grader that parses this ledger
- `.agent/agents/aid-reviewer/AGENT.md` — sub-agent output contract (references this schema)
- `.agent/aid/templates/reviewer-dispatch.md` — universal reviewer dispatch brief (references this schema)
- `CLAUDE.md` / `AGENTS.md` — global short rule (points at this schema)
- Per-skill `references/state-review.md` and `state-done.md` — lifecycle hooks
