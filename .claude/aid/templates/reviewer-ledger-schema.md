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
  - "8-column table is the entire ledger file (no headers, no narrative, no sections)"
  - "Three row kinds by # prefix: findings, U-NNN coverage units, G-NNN gaps; only findings grade"
  - "Rows are written by writeback-ledger.sh, never by an agent re-emitting the whole table"
  - "Severity enum: [CRITICAL] | [HIGH] | [MEDIUM] | [LOW] | [MINOR]"
  - "Status enum: Pending | Fixed | Recurred | Accepted | OOS | Invalid"
  - "Rule: a finding row MUST carry a rule ID; non-finding rows carry the -- sentinel"
  - "Grade is computed over rows where Status ∈ {Pending, Recurred}, by Severity column"
  - "File path: .aid/.temp/review-pending/<scope>.md (scope = skill or skill-task)"
  - "Persists across REVIEW→FIX cycles within one skill invocation; deleted at skill DONE"
changelog:
  - 2026-05-28: Initial schema spec
  - 2026-07-29: Added the Rule column (8 columns). Position 4, after Status, because
      grade.sh parses by position and reads cols[3]/cols[4] only.
  - 2026-07-29: Added the three row kinds (findings, U-NNN coverage, G-NNN gaps) and
      writeback-ledger.sh as the sole row writer, retiring the heredoc whole-table rewrite.
---

# Reviewer Ledger Schema

This document is the **canonical schema for every reviewer-output ledger in AID.** Every review — whether dispatched to a sub-agent, run by a script-based validator, or performed ad-hoc in response to a user prompt — MUST conform to this schema.

## File: contents

The ledger file contains **exactly one markdown table.** No frontmatter, no section headers, no narrative, no summary section, no out-of-scope section. Just the table.

**The table carries three row kinds**, distinguished by the `#` column — findings, coverage units
(`U-NNN`) and gaps (`G-NNN`). See **Row kinds** below. Only findings bear on the grade.

```markdown
| # | Severity | Status | Rule | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|---|
| 1 | [HIGH] | Pending | NAR-04 | foo.md | 42 | claim Y is wrong | doc says Y, `wc -l target = N` shows actual Z |
| 2 | [LOW] | Fixed | NAR-03 | bar.md | 100 | stale path reference | path/to/foo deleted commit abc123; cycle-4 FIX removed cite |
| 3 | [MINOR] | Accepted | NAR-06 | baz.md | — | one-sentence body | no-docs variant accepted by user cycle-1 Q10 |
| 4 | [HIGH] | Recurred | NAR-04 | qux.md | 17 | count off by 1 | claim 16 vs disk 15; was Fixed cycle-3, returned cycle-5 |
| 5 | [LOW] | OOS | NAR-08 | quux.md | 200 | inline T3 line-count violation | accurate value but P1 policy violation; methodology-refactor pending |
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
| 4 | `Rule` | yes | The ID of the rule the finding violates, from the artifact's rule set in [`.claude/aid/templates/review-rubrics/INDEX.md`](review-rubrics/INDEX.md). Format `<CLASS>-<NN>` (e.g. `CODE-03`, `NAR-04`). See **Rule values** below. |
| 5 | `Doc` | yes | Affected file path (relative to repo root). Examples: `foo.md`, `.claude/aid/scripts/bar.sh`, `tests/canonical/baz.sh`. For doc-wide issues with no specific file, use `—`. |
| 6 | `Line` | yes | Affected line number, or a line range like `42-45`, or `—` for doc-wide. |
| 7 | `Description` | yes | ONE sentence stating what's wrong. Form: "claim X is wrong: doc says Y, actual Z." Avoid hedging or explanation; explanation goes in Evidence. |
| 8 | `Evidence` | yes | The disk-truth that contradicts the doc's claim, AND/OR the source-of-truth command. Form: "`wc -l foo = 1070` (doc claims 1071)" or "`grep -c X bar = 5` (doc claims 6)". For Status=Fixed/Recurred/Accepted/OOS/Invalid, include enough context to justify the status (e.g., "Fixed in commit abc123" or "Accepted: user decision cycle-1 Q5"). |

**Pipe-character escape:** if Description or Evidence contains a `|` (pipe), escape it as `\|` so the markdown table doesn't break.

## Row kinds

One table, three kinds of row, told apart by the `#` column alone. A reader needs no other signal, and
`grade.sh` needs none at all — see **Grade inertness** below.

| Column | Finding | Coverage unit | Gap |
|---|---|---|---|
| `#` | `NNN` or `<NS>-NNN` | `U-NNN` or `U-<NS>-NNN` | `G-NNN` or `G-<NS>-NNN` |
| `Severity` | one of the five bracketed tokens | `--` | `--` |
| `Status` | `Pending` \| `Fixed` \| `Recurred` \| `Accepted` \| `OOS` \| `Invalid` | `Unexamined` \| `In Progress` \| `Examined` \| `Skipped` | `Open` \| `Resolved` |
| `Rule` | a catalog rule ID; **mandatory** (one exemption below) | `--` | `--` |
| `Doc` | the artifact the finding is about | the unit's artifact | the artifact whose review stalled |
| `Line` | line, range, or `--` | `--` | `--` |
| `Description` | one sentence: what is wrong | `rule-set: <name>`, plus a skip reason when `Skipped` | which criterion is missing |
| `Evidence` | disk truth, or the command producing it | UTC stamp `; art=<digest>; rs=<rule-set>@<digest>` | the resolution command, `gap-key=<key>`, `resume=N` |

**ID grammar — one regex for all three kinds:**

```
^(U-|G-)?([A-Z][A-Z0-9]{0,3}-)?[0-9]{1,4}$
```

The optional middle segment is the *writer namespace*, used only when one logical review has several
writers (`aid-discover`'s parallel mandates: `U-M1-004`). Absent in the common single-writer case.

**Worked rows:**

```markdown
| # | Severity | Status | Rule | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|---|
| U-001 | -- | Examined | -- | foo.md | -- | rule-set: NAR | 2026-07-29T10:00:04Z; art=f75d45bea4ae; rs=NAR@d247034 |
| 1 | [HIGH] | Pending | NAR-04 | foo.md | 42 | claim wrong: doc says 7, disk shows 9 | `ls \| wc -l = 9` |
| G-001 | -- | Open | -- | baz.sh | -- | no shell coding standard declared for this class | /aid-update-kb coding-standards; gap-key=no-shell-std; resume=1 |
| U-002 | -- | Skipped | -- | qux.md | -- | rule-set: SPEC; blocked by G-001 | 2026-07-29T10:09:02Z; art=a91c02; rs=SPEC@77b3e1 |
```

**Why coverage rows exist.** A review that is interrupted leaves no trace of *what it had already
looked at*. A `U-` row per unit makes progress legible, so a resumed review need not re-examine
everything — and the `art=`/`rs=` digests say whether the artifact or its rule set changed underneath,
which is what makes skipping safe rather than merely cheap.

**Why gap rows exist.** When the review's own preconditions are missing — no coding standard for the
language in hand — that is not a defect in the artifact and must not be graded as one. A `G-` row
records the missing criterion and the command that would supply it.

### Grade inertness

Non-finding rows are ignored **by construction, not by convention.** `grade.sh` counts a row only when
`Severity` is *exactly* one of the five bracketed tokens **and** `Status` is *exactly* `Pending` or
`Recurred`. A `--` in `Severity` fails the severity match, so the status value is never even reached.

That is why the coverage vocabulary can safely contain words that look grade-bearing: a row reading
`Status: In Progress` cannot be counted, because its `Severity` is `--`.

Adding, removing or re-statusing any number of `U-` or `G-` rows therefore leaves both the grade and
`--explain`'s breakdown unchanged. `writeback-ledger.sh` **verifies this at write time by default** —
it grades the pre-image and the post-image and refuses the write if they differ.

### The `--` sentinel

Non-applicable cells carry `--`, matching the `Rule` sentinel and the STATE templates' null sentinel —
not the em-dash `—` that this schema's older `Line` examples used. `grade.sh` ignores both, so existing
`—` cells are **not** migrated; the rule binds new rows only.

## Rule values

**A finding row MUST carry a rule ID.** A finding is by definition the assertion that some declared
rule is false here, so a finding with no rule has no criterion — which the catalog's admission rule
(*no `Criterion`, no row*) makes inexpressible. If nothing in either authority ladder speaks to the
concern, the correct output is a **criteria gap**, not a finding with an empty `Rule` cell.

| Row kind | `Rule` cell |
|---|---|
| A finding (any Severity) | the rule ID, e.g. `CODE-03` |
| A non-finding row | `--` (the sentinel) |

**One rule per row.** A defect violating two rules produces two rows. No comma-separated lists — the
cell stays single-valued, greppable, and countable.

**The class prefix is the source.** `CODE-*`, `SPEC-*`, `KB-*` and the rest carry what the retired
`[CODE]` / `[SPEC]` / `[ARCHITECTURE]` source tags used to assert, so the tag can no longer contradict
the rule. Do not add source tags to any column.

**Enforcement.** `grade.sh` does **not** enforce this: it reads `cols[3]` and `cols[4]` only and is
byte-unchanged apart from comments (NFR-1), so it cannot see the `Rule` column at all. The writer that
enforces a present, well-formed `Rule` cell is **`writeback-ledger.sh`** — and since it is the *only*
writer of rows, the requirement is mechanical rather than merely stated. A finding whose `Rule` is
empty, `--`, or malformed is refused with exit 4.

**There is no exemption.** A finding row requires a rule ID at *every* status. An earlier revision let
a `Status: OOS` row carry `--` as an interim carrier for "no rule set covers this artifact class";
that carrier is **retired**, because the gap protocol now gives that outcome its own row kind. An
unmatched class is a `[GAP:CRITERIA]` gap row — not a finding nobody can trace to a rule.

See [`criteria-gap-protocol.md`](criteria-gap-protocol.md).

### Mixed shapes: the header decides

A ledger is read according to **its own header row** — 7-column ledgers written before this change
remain readable, and are not rewritten. Two consequences:

- **Never mix shapes inside one file.** Every data row must match that file's header.
- **A 7-column ledger continues to grade correctly**, because `Severity` and `Status` sit at positions
  2 and 3 in both shapes. That is the reason the `Rule` column was inserted *after* `Status` rather
  than anywhere earlier.

## Severity values

The five tags are `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]`. **What each one means
is defined once**, at [`.claude/aid/templates/grading-rubric.md#severity-scale`](.claude/aid/templates/grading-rubric.md#severity-scale) --
modality sets the band, then blast radius and reversibility select within the MUST band. This
schema governs the ledger's *shape*, not the severity vocabulary's *meaning*.

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

`.claude/aid/scripts/grade.sh` reads the ledger as a markdown table and counts findings by Severity, filtered to Status ∈ {`Pending`, `Recurred`}.

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

**Why the `Rule` column sits at position 4.** `grade.sh` parses by column *position*: after
`split($0, cols, "|")` it reads `cols[3]` for Severity and `cols[4]` for Status, and looks at nothing
beyond. Inserting a column at or before position 3 would shift Severity or Status and break the
grader. Inserting after Status is invisible to it. So the position is **constrained, not chosen** —
and it is also where a reader asking *"why is this HIGH?"* looks, right beside the severity it
justifies.

The shape groups into three readable bands: *classification* (`#`, Severity, Status, Rule),
*location* (Doc, Line), *content* (Description, Evidence).

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

## How rows are written

**Rows are written by `.claude/aid/scripts/review/writeback-ledger.sh`, one call per row.** Do not
re-emit the table.

```bash
writeback-ledger.sh --ledger .aid/.temp/review-pending/<scope>.md --append-finding \
    --severity '[HIGH]' --rule NAR-04 --doc foo.md --line 42 \
    --description 'claim wrong: doc says 7, disk shows 9' --evidence '`ls | wc -l` = 9'

writeback-ledger.sh --ledger ... --append-unit --unit foo.md --rule-set NAR --status Examined
writeback-ledger.sh --ledger ... --append-gap  --gap-key no-shell-std --doc baz.sh \
    --description 'no shell coding standard declared' --resolution '/aid-update-kb coding-standards'
writeback-ledger.sh --ledger ... --set-status --row-id U-002 --status Examined
writeback-ledger.sh --ledger ... --row-id U-002 --get-status
```

**Why this replaced the heredoc.** The previous contract had the reviewer read the whole ledger and
re-emit every row inside a `cat >`. A 30-row ledger is 3.3–10 KB of table, so each checkpoint cost
roughly 0.9–2.5k output tokens plus a comparable read — and each one was an opportunity to silently
truncate every prior finding. One helper call carries a single row's cells, needs no read, and cuts
per-checkpoint output by 20–30×.

The truncation surface is **zero**, because the model never emits a row it did not author in that
call. The script still rewrites the file (awk to a temp file, then `mv`), exactly as
`writeback-state.sh` does for a state field — what went to zero is *agent-authored whole-table
re-emission*.

**What the script guarantees, so you do not have to:**

- **`#` is script-assigned.** Next free integer for findings, next free `U-NNN`/`G-NNN` within the kind
  and namespace. Existing rows are never renumbered.
- **`--set-status` rewrites exactly one cell.** Every other cell of that row, and every other row, is
  byte-identical afterwards. Status is validated against the target row's *kind*, so
  `--row-id U-002 --status Recurred` is refused.
- **A finding with no rule ID is rejected** (exit 4). The one exemption: a `Status: OOS` row may carry
  `--` in `Rule`, for an artifact class no rule set covers.
- **`--append-gap` is idempotent on `--gap-key`** — a repeated key appends nothing and increments
  `resume=N` on the existing row.
- **Pipes are escaped** (`|` → `\|`) in `--description` and `--evidence`; raw newlines are rejected.
- **CRLF and trailing-newline invariance** hold, so a ledger written on Windows stays byte-stable.
- **Grade inertness is verified on every non-finding write** and the write is refused if the grade
  moves.

## Authoring rules for the reviewer

**Always:**
- Write rows with `writeback-ledger.sh`, one call per row. Never re-emit the table by hand.
- Let the script assign `#`; do NOT renumber existing rows.
- **Carry a rule ID in `Rule` on every finding row.** If no rule speaks to the concern, raise a criteria gap instead of writing a finding.
- Cite the disk-truth in Evidence with a runnable command or specific file:line reference.
- Read the existing ledger BEFORE appending — use the existing Status patterns to identify Recurred regressions.
- Match the shape of the file's own header row; if it is a 7-column ledger, keep writing 7 columns.

**Never:**
- Add a `## Summary` section with severity tag-strings (the cycle-7 bug — those tag strings get over-counted by simpler graders).
- Modify existing rows' Severity, `Rule` or Description (they're append-only history); only Status may change across cycles.
- Put more than one rule ID in a `Rule` cell, or add a retired source tag (`[CODE]`, `[SPEC]`, `[ARCHITECTURE]`) to any column.
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

- `.claude/aid/scripts/review/writeback-ledger.sh` — the sole writer of ledger rows
- `.claude/aid/scripts/grade.sh` — the grader that parses this ledger
- `.claude/aid/templates/review-rubrics/INDEX.md` — the rule sets the `Rule` column cites
- `.claude/agents/aid-reviewer/AGENT.md` — sub-agent output contract (references this schema)
- `.claude/aid/templates/reviewer-dispatch.md` — universal reviewer dispatch brief (references this schema)
- `CLAUDE.md` / `AGENTS.md` — global short rule (points at this schema)
- Per-skill `references/state-review.md` and `state-done.md` — lifecycle hooks
