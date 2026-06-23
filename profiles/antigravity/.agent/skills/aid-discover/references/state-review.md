# State: REVIEW

REVIEW grades all declared KB documents for accuracy, completeness, and evidence
quality; it is selected when all declared docs are populated and no grade has been
assigned yet.

**Injectable parameters** (f005-owned seam; f008's `aid-update-kb` consumes this):
- `{{SCOPE}}` — ledger scope name (default: `discovery`). All ledger paths below use
  `<scope>` as a variable resolved to this value. `aid-discover` injects `discovery`.
- `{{ARTIFACTS}}` / `{{CONTEXT}}` — the doc-set under review and the review context.
  `aid-discover` injects the full KB doc-set (`discovery.doc_set`).

---

### Step 1: Dispatch the Panel

Print: `[Review 1/3] Dispatching 5-mandate review panel...`

**Pre-dispatch: run the coverage oracle**

Before dispatching the panel, run `closure-check.sh` to produce the evidence inputs
that M3 and M5 consume:

```bash
bash .claude/aid/scripts/kb/closure-check.sh \
  --output-a .aid/.temp/review-pending/{{SCOPE}}-oracle-a.md \
  --output-b .aid/.temp/review-pending/{{SCOPE}}-oracle-b.md \
  --output-c .aid/.temp/review-pending/{{SCOPE}}-oracle-c.md
```

If `candidate-concepts.md` does not exist yet, the oracle emits empty outputs — the
panel degrades gracefully (M3 finds no evidence; M5 finds no transcription signal;
M4 falls back to the engine-narration question only). This is not an error.

Also run `kb-teachback-questions.sh` to produce the M4 question set:

```bash
bash .claude/aid/scripts/kb/kb-teachback-questions.sh \
  --output .aid/.temp/review-pending/{{SCOPE}}-teachback-questions.txt
```

If `candidate-concepts.md` does not exist, the output contains only the fixed engine
question. This is not an error.

**Brief preparation**

Render the universal brief from `references/reviewer-brief.md` ONCE, substituting:
- `{{ARTIFACTS}}` — list of declared KB doc paths under review for this cycle, resolved
  via `read-setting.sh --path discovery.doc_set` → list-filenames accessor,
  `references/doc-set-resolve.md` §2.1; default seed when unset.
- `{{CONTEXT}}` — descriptive-only (no downstream phase references; see the brief's
  CONTEXT discipline rule).

Update the brief's `DELIVERABLES` block so the ledger path reads:
  `.aid/.temp/review-pending/{{SCOPE}}-<mandate>.md`
(each mandate writes to its own scratch ledger; the brief is rendered once and the
mandate-specific ledger path is substituted per dispatch).

**Five parallel mandate dispatches**

For each mandate Mi in {Correctness, Anatomy/Coverage, Concept-closure, Teach-back,
Calibration}, prepare a dispatch package:

**M1 — Correctness:**
- Brief (rendered above) + `references/reviewer-prompt-correctness.md`
- Substitute `{{SCOPE}}` in the FOCUS body with the current scope value.
- Ledger (prompt instruction): write to `.aid/.temp/review-pending/{{SCOPE}}-correctness.md`

**M2 — Anatomy / Coverage:**
- Brief + `references/reviewer-prompt-anatomy.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline `references/document-expectations.md` contents for `{{DOCUMENT_EXPECTATIONS}}`.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-anatomy.md`

**M3 — Concept-closure:**
- Brief + `references/reviewer-prompt-concept-closure.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline `closure-check.sh` output (a) for `{{CLOSURE_CHECK_A}}`.
- Inline `closure-check.sh` output (b) for `{{CLOSURE_CHECK_B}}`.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-concept-closure.md`

**M4 — Teach-back (keystone):**
- Brief + `references/reviewer-prompt-teachback.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline `{{SCOPE}}-teachback-questions.txt` contents for `{{TEACHBACK_QUESTIONS}}`.
- **Stricter clean-context rule:** the M4 dispatch MUST NOT include project source
  files, the project-index, candidate-concepts.md, or any generation artifacts — the
  reviewer sees ONLY the KB + the question set.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md`

**M5 — Calibration:**
- Brief + `references/reviewer-prompt-calibration.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline `closure-check.sh` output (b) for `{{CLOSURE_CHECK_B}}`.
- Inline `closure-check.sh` output (c) for `{{CLOSURE_CHECK_C}}`.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-calibration.md`

**Dispatch all 5 aid-reviewer sub-agents IN PARALLEL** (one message, 5 dispatches).

**A3 capability-probe:** if parallel dispatch is unavailable in the current execution
environment, degrade to sequential — dispatch M1, wait, dispatch M2, wait, ... M5.
Record which mode was used.

Each mandate reviewer writes ONLY to its own scratch ledger (the `{{SCOPE}}-<mandate>.md`
file named in its prompt). The five scratch ledgers are short-lived transients; the
canonical `{{SCOPE}}.md` ledger (the file `grade.sh` and FIX use) is untouched
until Step 2.

**⚠️ CLEAN CONTEXT (all mandates):** Do NOT include any info about the generation
process, which agents ran, or prior state. Each reviewer evaluates purely on what
is on disk.

**⚠️ CONTAMINATION PREVENTION (all mandates, also applies in FIX mode Step 6):**
- Do NOT include previous review results in any mandate prompt
- Do NOT tell reviewers what was fixed or the previous grade
- Do NOT say "re-review" — each mandate reviewer must approach fresh

**⚠️ M4 ADDITIONAL CLEAN-CONTEXT RULE:** The Teach-back mandate reviewer MUST see
ONLY the KB (`.aid/knowledge/*.md`) and the question set. Do NOT pass project source
files, project-index, candidate-concepts.md, or any generation artifacts.

Print: `[Review 1/3] Panel dispatched (5 mandates, parallel). Waiting for all 5...`

Wait for all 5 to complete. Record per-mandate actual time.

---

### Step 2: Aggregate + Grade

Print: `[Review 2/3] Aggregating panel findings...`

**2a. Merge the 5 scratch ledgers into the single canonical ledger**

Collect all data rows from the five scratch ledgers:
- `.aid/.temp/review-pending/{{SCOPE}}-correctness.md`
- `.aid/.temp/review-pending/{{SCOPE}}-anatomy.md`
- `.aid/.temp/review-pending/{{SCOPE}}-concept-closure.md`
- `.aid/.temp/review-pending/{{SCOPE}}-teachback.md`
- `.aid/.temp/review-pending/{{SCOPE}}-calibration.md`

If `.aid/.temp/review-pending/{{SCOPE}}.md` already exists (cycle N>=2), read its
existing rows first. Each mandate reviewer's rows are identified by their `#` ID prefix
(M1-NNN, M2-NNN, M3-NNN, TB-NNN, M5-NNN) — the mandate reviewers have updated their
own rows' Status in their scratch ledgers. Merge rule:

1. For rows in the existing `{{SCOPE}}.md` that correspond to a mandate's scratch
   ledger, replace the row with the scratch ledger's version (Status updated by the
   reviewer).
2. For new rows (new findings) in the scratch ledgers, append them with the next
   available `MN-NNN` or `TB-NNN` ID within that mandate's namespace.
3. Assign **stable per-mandate IDs** in the `#` column: `M1-001`..`M1-NNN`,
   `M2-001`..`M2-NNN`, `M3-001`..`M3-NNN`, `TB-001`..`TB-NNN`, `M5-001`..`M5-NNN`.
   These IDs are monotonic within each mandate's namespace and never reassigned to a
   different finding.
4. Each Description must carry its mandate marker prefix (`[M1]`, `[M2]`, `[M3]`,
   `[M5]`, or `[TEACHBACK]`) — the mandate reviewers have written these; verify they
   are present.

Write the merged result to `.aid/.temp/review-pending/{{SCOPE}}.md` (the canonical
ledger, 7-column schema).

**2b. Run the existing grade.sh unchanged**

```bash
bash .claude/aid/scripts/grade.sh --explain .aid/.temp/review-pending/{{SCOPE}}.md
```

`grade.sh` counts worst-severity over Status in {Pending, Recurred} across ALL rows,
regardless of which mandate produced them. It reads only the Severity column (col 3)
and Status column (col 4) — mandate-marker text in Description/Evidence is invisible
to the grader. No `grade.sh` change.

The grade is printed to stdout; `--explain` breakdown to stderr.

**2c. Derive the teach-back verdict**

The teach-back verdict is NOT a stored sentinel. Read it directly from
`.aid/.temp/review-pending/{{SCOPE}}.md`:

- Count rows where Description contains `[TEACHBACK]` AND Status is in {Pending, Recurred}.
- `teach_back_verdict = PASS` iff count == 0, else `FAIL`.

Both per-term FAIL items and engine-narration FAIL items are ordinary `[HIGH]`
`[TEACHBACK]` rows. Any open `[TEACHBACK]` row forces grade <= D (because `[HIGH]`
rows make grade <= D in `grade.sh`) — the teach-back hard gate is realized entirely
through the merged rows. No separate boolean, no AND to reconcile.

**2d. Delete the 5 transient scratch ledgers**

After merging, delete the 5 per-mandate scratch files and the oracle/question-set
transients:

```bash
rm -f \
  .aid/.temp/review-pending/{{SCOPE}}-correctness.md \
  .aid/.temp/review-pending/{{SCOPE}}-anatomy.md \
  .aid/.temp/review-pending/{{SCOPE}}-concept-closure.md \
  .aid/.temp/review-pending/{{SCOPE}}-teachback.md \
  .aid/.temp/review-pending/{{SCOPE}}-calibration.md \
  .aid/.temp/review-pending/{{SCOPE}}-oracle-a.md \
  .aid/.temp/review-pending/{{SCOPE}}-oracle-b.md \
  .aid/.temp/review-pending/{{SCOPE}}-oracle-c.md \
  .aid/.temp/review-pending/{{SCOPE}}-teachback-questions.txt
```

`{{SCOPE}}.md` is now the single source FIX reads, exactly as before.

---

### Step 3: Post-Process and Report

Print: `[Review 3/3] Review complete.`

Resolve the minimum grade:

```bash
bash .claude/aid/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A
```

Compute:
- `ready = (grade >= minimum_grade)`
- `teach_back_display = PASS` or `FAIL` (from Step 2c)
- If `ready` and `teach_back_verdict == PASS`: `outcome = "Ready"`
- Otherwise: `outcome = "NOT Ready"`

Update `.aid/knowledge/STATE.md` `## Review History` with the new entry. Record the
grade computed by `grade.sh`, not any grade mentioned in the mandate reviewers' prose.

If `--grade` provided, update `.aid/settings.yml` `discover.minimum_grade` (via
`/aid-config` or direct YAML edit).

Print:
```
Grade: {grade} | Teach-back: {PASS|FAIL} -> {Ready|NOT Ready}
[Review 3/3] Grade: {grade}. Minimum: {min}. Run /aid-discover again to {fix issues|proceed}.
```

Print: `[State: REVIEW] complete.`

**Advance:** **CHAIN** → [State: Q-AND-A] if Pending Q&A entries with Impact: Required
exist; **CHAIN** → [State: FIX] otherwise. Both continue inline.

---

### Grade Aggregation Summary

```
1. Five mandate reviewers (M1..M5) run in parallel, each writing to their own
   scratch ledger. M4 writes one [HIGH] [TEACHBACK] row per FAIL item (per-term
   AND engine-narration FAILs alike — no separate verdict sentinel).

2. Orchestrator MERGES all 5 scratch ledgers into {{SCOPE}}.md (stable per-mandate
   IDs M1-NNN/M2-NNN/M3-NNN/TB-NNN/M5-NNN; [M1]/[M2]/[M3]/[M5]/[TEACHBACK]
   description prefixes), then DELETES the 5 transient scratch ledgers.

3. grade = grade.sh {{SCOPE}}.md    # EXISTING grader, unchanged. Worst-severity
                                    # dominates, counts Status in {Pending,Recurred}.
                                    # Any open [TEACHBACK] row forces grade <= D.

4. READY iff grade >= minimum_grade # Single gate. An open teach-back gap is a
                                    # [HIGH] row -> grade <= D -> not Ready.
                                    # No second boolean, no AND to reconcile.

5. verdict (for reporting) = FAIL iff any open [TEACHBACK] row, else PASS.

6. STATE + print report the PAIR: "Grade: <g> | Teach-back: <verdict>"
```

**Why merge rather than keep five ledgers:** FIX (`state-fix.md`) and `grade.sh` are
built around ONE `<scope>.md` per skill invocation. Merging to the single ledger keeps
FIX, `grade.sh`, and the schema unchanged — the panel is an input-side fan-out that
collapses back to the existing single-ledger contract before grading.
