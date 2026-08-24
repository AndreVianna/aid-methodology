---
kb-category: meta
source: hand-authored
objective: The canonical schema for every reviewer-output ledger in AID.
summary: Defines the 7-column table shape, the Severity and Status enums, the file lifecycle, and how grade.sh reads it.
review-criteria:
  - id: F-01
    kind: validate
    criterion: "The 7-column table is the entire ledger file -- no title, no section headings, no narrative, no scratch space"
    severity: HIGH
    why: "grade.sh parses the file as a table; anything else in it is either ignored or misparsed as a row"
  - id: F-02
    kind: validate
    criterion: "Severity enum, bracketed all-caps: CRITICAL, HIGH, MEDIUM, LOW, MINOR"
    severity: HIGH
    why: "grade.sh counts the bracketed tag and nothing else, so a sentence-case severity counts as zero findings and silently yields A+"
  - id: F-03
    kind: validate
    criterion: "Status enum: Pending, Fixed, Recurred, Accepted, OOS, Invalid"
    severity: HIGH
    why: "Status decides whether a row counts toward the grade; a value outside the enum is not counted and the finding disappears"
  - id: F-04
    kind: validate
    criterion: "The grade is computed over rows whose Status is Pending or Recurred, read from the Severity column"
    severity: MEDIUM
    why: "This is the contract grade.sh implements; a doc that describes it differently teaches a reviewer to write an ungradeable ledger"
  - id: F-05
    kind: validate
    criterion: "The ledger lives at .aid/.temp/review-pending/<scope>.md, where scope names the skill or the skill and task"
    severity: MEDIUM
    why: "Two skills writing one path collide; a scope-less name is what makes that happen"
  - id: F-06
    kind: validate
    criterion: "The file persists across REVIEW and FIX cycles within one skill invocation and is deleted when the skill reaches DONE"
    severity: LOW
    why: "A ledger left behind is read as a live finding list by the next run"
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
| `/aid-define <work>` cross-reference | `.aid/.temp/review-pending/interview-<work>-cross-ref.md` |
| `/aid-describe <work>` lite-review | `.aid/.temp/review-pending/interview-<work>-lite.md` |
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
| 4 | `Doc` | yes | Affected file path (relative to repo root). Examples: `foo.md`, `.github/aid/scripts/bar.sh`, `tests/canonical/baz.sh`. For doc-wide issues with no specific file, use `—`. |
| 5 | `Line` | yes | Affected line number, or a line range like `42-45`, or `—` for doc-wide. |
| 6 | `Description` | yes | The criterion `id` violated, then ONE sentence stating what's wrong, then a **why-line**: a short clause naming the consequence. Form: "`SK-01` — dispatch table names a non-existent agent, so a dispatch resolves to nothing at run time." The consequence clause is the one explanation this column admits, and it is required: a severity asserted without one cannot be argued with, because there is nothing to disagree about except the reviewer's judgement. Everything else that would explain rather than state still goes in Evidence, and hedging goes nowhere. See **Citing the criterion** below. |
| 7 | `Evidence` | yes | The disk-truth that contradicts the doc's claim, AND/OR the source-of-truth command. Form: "`wc -l foo = 1070` (doc claims 1071)" or "`grep -c X bar = 5` (doc claims 6)". For Status=Fixed/Recurred/Accepted/OOS/Invalid, include enough context to justify the status (e.g., "Fixed in commit abc123" or "Accepted: user decision cycle-1 Q5"). When the severity came from a file-level **override** of a declared criterion, record the resolved severity and the overriding file's `why` here. **Severity provenance** is recorded with one of three tokens, so a band can be traced without re-reading the cascade: `severity: declared` — taken unchanged from the cited criterion's `severity:`; `severity: override <level>` — the criterion declares one band and a more specific level declares another; `<level>` names **where the winning band came from** (`file`, `file-class`, or `type`), not the band itself, which is already in the Severity column; `severity: judged` — no criterion declares a severity for this, so the reviewer set it. A row whose band differs from its cited criterion's declared `severity:` and carries no token is a defect in the review: the divergence is the interesting part and it has been silently dropped. |

**Pipe-character escape:** if Description or Evidence contains a `|` (pipe), escape it as `\|` so the markdown table doesn't break.

## Citing the criterion

**A task acceptance criterion is cited as `task-NNN AC-N`.** A task's `DETAIL.md` carries its
criteria as a checkbox list with no `id:` field, so neither of the two forms below reaches them: a
scope-prefixed id resolves in the criteria table, an `F-` id resolves in a file's frontmatter, and
a task AC lives in neither. Without this form a task-gate reviewer cannot cite a resolvable id for
the thing it was actually asked to check, which makes every task-gate ledger defective by this
schema's own rule.

`task-037 AC-3` resolves by reading that task's `DETAIL.md` and counting the checkboxes under
`**Acceptance Criteria:**`. The ordinal is the citation; the ACs are not renumbered once a task is
executing.

**Every finding names the criterion it violates, as an `id` prefix inside the `Description`
cell.** No eighth column: the shape stays 7 columns and `grade.sh` keeps its positional parse
(it reads `cols[3]` and `cols[4]` from the left and ignores `cols[5..8]`).

```markdown
| 3 | [HIGH] | Pending | .github/skills/aid-plan/SKILL.md | 42 | SK-01 — dispatch table names a non-existent agent | ls .github/agents/ |
```

- A **scope-prefixed** id (`G-`, `KB-`, `SK-`, ...) resolves in the project's criteria table
  (`.aid/knowledge/authoring-conventions.md`).
- An **`F-`** id resolves in the `review-criteria:` frontmatter of the file named in `Doc`.
- **A finding citing no id, or an id that resolves nowhere, is itself a defect** — it means the
  reviewer invented a criterion.

How criteria resolve (global → type → file, most specific wins) is defined in
`.github/aid/templates/kb-authoring/review-rubric.md § Resolving review criteria`; this schema
does not restate it.

**Overrides are recorded in `Evidence`.** When the severity used came from a file-level override
rather than the global or type level, the `Evidence` cell carries the resolved severity and the
overriding file's `why`, so a reader can see which level won and on what grounds:

```markdown
| 7 | [LOW] | Pending | .github/aid/templates/foo.md | 12 | G-01 — inline count not measured at authoring time | resolved LOW via file-level override of G-01 (MINOR global); why: "this count gates a downstream parse" |
```

The `Evidence` cell is inert to grading, so an override is visible without any change to the
grade machinery.

## Severity values

The enum is `[CRITICAL]` | `[HIGH]` | `[MEDIUM]` | `[LOW]` | `[MINOR]`, always in the bracketed
all-caps form — that is the form `grade.sh` counts.

**What each level means, and the severity-to-letter-grade mapping, are defined once in
`.github/aid/templates/grading-rubric.md`** (`§ Issue Severities` and `§ Grade Calculation`).
This schema owns the ledger's *shape*, not the scale: a level restated here becomes a second
definition that drifts from the one the grade is computed against, which is what happened to the
per-level "grade impact" notes this section used to carry.

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
2. **REVIEW (cycle N≥2):** read existing file. **Verification is FULL; the hunt for new findings is SCOPED.** See *Two sets from cycle 2* below.
   - *Verify — over the full verification set:* for each existing `Pending` row, check on disk → if resolved, change Status to `Fixed`; if still wrong, leave as `Pending`. For each existing `Fixed` row, check it is still resolved → if regressed, change Status to `Recurred`.
   - *Hunt — over the scoped hunt set only:* append new rows as `Pending` for newly-found issues.
3. **FIX:** read Pending + Recurred rows. Address each. Do NOT mark rows `Fixed` during FIX — that's the next reviewer's job (separation of concerns: fixer fixes, reviewer verifies).
4. **Orchestrator (any phase):** may mark a row `Accepted` with user authorization (record rationale in Description). May mark `Invalid` if reviewer was wrong, with evidence.
5. **Skill reaches DONE:** orchestrator deletes the ledger file. If `.aid/.temp/review-pending/` is then empty, the directory is also removed.

### Two sets from cycle 2

Cycle 1 reads the whole artifact and is unchanged. From cycle 2 a review does two
different jobs, and only one of them is expensive:

| Set | Contents | Scope |
|---|---|---|
| **Verification set** | every file named in an existing ledger row's `Doc` column, **plus the full cycle-1 artifact set whenever any row's `Doc` is `—`** | **FULL — never scoped** |
| **Hunt set** | what the previous FIX changed, plus the sections that reference it | **SCOPED** |

**Verification is never scoped, and that is what protects `Recurred`.** Checking a
`Pending` row against disk is a targeted lookup that was always cheap; scoping it would
break regression detection, which is the backstop the whole design leans on. The `Doc: —`
widening exists because a doc-wide row names no file: a verification set built only by
collecting `Doc` values would contain nothing for it, so the row could never be
re-verified and would sit `Pending` forever or, worse, be treated as verified because
nothing contradicted it.

**Only the hunt is scoped**, because "find NEW issues" is the clause that forced a full
re-scan every cycle. It is what made a five-cycle gate re-read the whole artifact five
times to keep finding roughly as many new issues as it closed.

The hunt set is derived, never judged:

```
changed   := git diff --name-only <previous-cycle-commit>..HEAD
             | filter_reviewable_artifacts
referrers := files containing a literal reference to any changed path,
             or to a changed section's heading anchor
hunt      := changed ∪ referrers
```

`referrers` is a **grep, not a judgment call**: a fix in one section can break another
that references it, and the expansion that catches this must be reproducible rather than
a model's guess about what "might be affected" — a guess that varies between cycles is
the non-determinism this change exists to remove.

**Where no previous-cycle commit is recorded, the cycle is UNSCOPED** — it reads
everything, exactly as today. Degrading to current behaviour is always the safe direction,
and it is chosen deliberately over inferring a base.

**Two limits, stated rather than left to be discovered:**

- A reference expressed in prose without naming the path ("the ledger schema says…") is
  not found by grep. The mechanical expansion is the cheap catch; the final full pass is
  the complete one. Widening the grep to prose synonyms would reintroduce exactly the
  judgment the guard exists to eliminate.
- **A scoped cycle never approves.** One full pass runs before approval as the backstop,
  and `Recurred` already exists in the Status enum for anything a scoped cycle missed and
  a later one re-finds.

**The cross-document contradiction pass is kept, and moves to once per phase** — run on
cycle 1 of any review whose artifact list spans more than one artifact, rather than once
per cycle inside each single-artifact gate. It gets *better* rather than merely cheaper: a
contradiction between two sibling documents is invisible to a gate that only ever reads
one of them.

## grade.sh integration

`.github/aid/scripts/grade.sh` reads the ledger as a markdown table and counts findings by Severity, filtered to Status ∈ {`Pending`, `Recurred`}.

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

- `.github/aid/scripts/grade.sh` — the grader that parses this ledger
- `.github/agents/aid-reviewer/AGENT.md` — sub-agent output contract (references this schema)
- `.github/aid/templates/reviewer-dispatch.md` — universal reviewer dispatch brief (references this schema)
- `CLAUDE.md` / `AGENTS.md` — global short rule (points at this schema)
- Per-skill `references/state-review.md` and `state-done.md` — lifecycle hooks
