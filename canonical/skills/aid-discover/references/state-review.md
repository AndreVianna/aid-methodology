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

Print: `[Review 1/3] Dispatching review panel...`

**Pre-dispatch: run the coverage oracle**

Before dispatching the panel, run `closure-check.sh` to produce output (b) — the
per-doc `sources:`-anchored coverage table that the M2 Anatomy mandate consumes for its
coverage-gap and altitude judgments. (Output (a), the ungrounded-term termination
oracle, is run by the GENERATE closure loop; the panel does not re-run it as a mandate —
concept self-containment is mechanically gated there.)

```bash
bash canonical/scripts/kb/closure-check.sh \
  --output-a .aid/.temp/review-pending/{{SCOPE}}-oracle-a.md \
  --output-b .aid/.temp/review-pending/{{SCOPE}}-oracle-b.md
```

If `candidate-concepts.md` does not exist yet, the oracle emits empty outputs — the
panel degrades gracefully (M2 finds no coverage evidence; M3 falls back to the
engine-narration question only). This is not an error. (Output (a) is still emitted for
diagnostic use, but the panel mandates consume only output (b).)

Also run `kb-teachback-questions.sh` to produce the M3 question set:

```bash
bash canonical/scripts/kb/kb-teachback-questions.sh \
  --output .aid/.temp/review-pending/{{SCOPE}}-teachback-questions.txt
```

If `candidate-concepts.md` does not exist, the output contains only the fixed engine
question. This is not an error.

Also run `kb-actback-task.sh` to produce the M4 representative-task spec and
operational-structure presence check:

```bash
bash canonical/aid/scripts/kb/kb-actback-task.sh both \
  --doc-set .aid/generated/doc-set.tsv \
  --kb-dir .aid/knowledge \
  --output .aid/.temp/review-pending/{{SCOPE}}-actback-task.md
```

This emits both the representative-task spec (function 1) and the operational-structure
presence table (function 2) in a single output file. The doc-set TSV is the
`filename<TAB>owner<TAB>presence` file produced by `resolve_doc_set` during GENERATE.
If the TSV does not exist yet, `kb-actback-task.sh` will exit 1 — run GENERATE first.

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

**Branch on `review.panel`**

Read the `review.panel` parameter supplied by the orchestrator from
`references/path-config.md` (established at Step 0f triage). Two values:

- **`panel: full`** — brownfield-large default; 4 parallel mandate dispatches.
- **`panel: collapsed`** — brownfield-small only; 3 dispatches (sequential-passes
  reviewer + clean-context teach-back + clean-context act-back). Greenfield never
  reaches the panel.

---

#### `panel: full` — Four Parallel Mandate Dispatches

For each mandate Mi in {Correctness, Anatomy/Coverage, Teach-back, Act-back}, prepare a
dispatch package:

**M1 — Correctness:**
- Brief (rendered above) + `references/reviewer-prompt-correctness.md`
- Substitute `{{SCOPE}}` in the FOCUS body with the current scope value.
- Ledger (prompt instruction): write to `.aid/.temp/review-pending/{{SCOPE}}-correctness.md`

**M2 — Anatomy / Coverage (incl. altitude: hollow vs transcription):**
- Brief + `references/reviewer-prompt-anatomy.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline `references/document-expectations.md` contents for `{{DOCUMENT_EXPECTATIONS}}`.
- Inline `closure-check.sh` output (b) for `{{CLOSURE_CHECK_B}}` (the per-doc
  `sources:`-anchored coverage table that anchors M2's coverage-gap and altitude
  judgments).
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-anatomy.md`

**M3 — Teach-back (keystone):**
- Brief + `references/reviewer-prompt-teachback.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline `{{SCOPE}}-teachback-questions.txt` contents for `{{TEACHBACK_QUESTIONS}}`.
- **Stricter clean-context rule:** the M3 dispatch MUST NOT include project source
  files, the project-index, candidate-concepts.md, or any generation artifacts — the
  reviewer sees ONLY the KB + the question set.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md`

**M4 — Operational Sufficiency (Act-back, keystone):**
- Brief + `references/reviewer-prompt-actback.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline the full contents of `.aid/.temp/review-pending/{{SCOPE}}-actback-task.md`
  (both the representative-task spec and the operational-structure presence table, as
  produced by `kb-actback-task.sh both` in the pre-dispatch step above) for
  `{{ACTBACK_TASK_SPEC}}`.
- **Stricter clean-context rule:** the M4 dispatch MUST NOT include project source
  files, the project-index, candidate-concepts.md, or any generation artifacts — the
  reviewer sees ONLY the KB + the representative-task spec and presence-check output.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-actback.md`

**Dispatch all 4 aid-reviewer sub-agents IN PARALLEL** (one message, 4 dispatches).

**A3 capability-probe:** if parallel dispatch is unavailable in the current execution
environment, degrade to sequential — dispatch M1, wait, dispatch M2, wait, ... M4.
Record which mode was used.

Each mandate reviewer writes ONLY to its own scratch ledger (the `{{SCOPE}}-<mandate>.md`
file named in its prompt). The four scratch ledgers are short-lived transients; the
canonical `{{SCOPE}}.md` ledger (the file `grade.sh` and FIX use) is untouched
until Step 2.

Print: `[Review 1/3] Panel dispatched (4 mandates, parallel). Waiting for all 4...`

Wait for all 4 to complete. Record per-mandate actual time.

---

#### `panel: collapsed` — Three Dispatches (Brownfield-Small Only)

All four mandates still run. The two source-aware content mandates (M1/M2) run as
**separate sequential passes** within ONE reviewer to reduce parallelism cost for
small projects. The anti-P2 no-blending property is fully preserved: each mandate
is adjudicated on its own before the next begins. M3 (teach-back) and M4 (act-back)
are always separate clean-context dispatches (they cannot share context with the
source-aware passes; M3 and M4 may share a dispatch with each other only if both
are clean-context — in practice dispatch them separately to keep their scratch ledgers
independent and their verdicts un-conflated).

**Dispatch 1 — Sequential-passes reviewer (M1, M2 in order):**

Dispatch ONE `aid-reviewer` with the following prompt, driving it through both
content mandates as separate sequential passes. The reviewer MUST complete each pass
fully and write its findings to the ledger before beginning the next pass.

Prompt construction:
- Brief (rendered above) — substituting `{{SCOPE}}`, `{{ARTIFACTS}}`, `{{CONTEXT}}`.
- Append the following multi-pass instruction body:

```
You are running a COLLAPSED review panel for a brownfield-small discovery.
You will evaluate two mandates as SEPARATE SEQUENTIAL PASSES -- one at a time, in
order. Complete each mandate fully, write its findings to the ledger, then proceed
to the next. Do NOT blend findings across mandates; each mandate is an independent
evaluation.

Ledger path for both passes: .aid/.temp/review-pending/{{SCOPE}}-content.md
Use the mandate ID prefixes M1-NNN, M2-NNN for rows.

--- PASS 1: M1 Correctness ---
[Insert the full FOCUS body of references/reviewer-prompt-correctness.md here,
 with {{SCOPE}} substituted. Instruct the reviewer to write M1 findings to the
 ledger and mark them M1-NNN before continuing.]

--- PASS 2: M2 Anatomy / Coverage (incl. altitude) ---
[Insert the full FOCUS body of references/reviewer-prompt-anatomy.md here, with
 {{SCOPE}} substituted, {{DOCUMENT_EXPECTATIONS}} inlined from
 references/document-expectations.md, and {{CLOSURE_CHECK_B}} inlined from
 closure-check.sh output (b). Instruct the reviewer to append M2 findings to the
 same ledger marked M2-NNN.]
```

The reviewer writes both mandates' findings to the **single scratch ledger**
`.aid/.temp/review-pending/{{SCOPE}}-content.md` (a transient Step-2 merges and
deletes). Each pass writes its own rows before the next pass begins; the final
ledger is the concatenation of both passes' findings.

**Dispatch 2 — Clean-context teach-back reviewer (M3):**

Dispatch ONE clean-context `aid-reviewer` (identical to the `panel: full` M3 dispatch):
- Brief (rendered above) + `references/reviewer-prompt-teachback.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline `{{SCOPE}}-teachback-questions.txt` contents for `{{TEACHBACK_QUESTIONS}}`.
- **Stricter clean-context rule:** the M3 dispatch MUST NOT include project source
  files, the project-index, candidate-concepts.md, or any generation artifacts — the
  reviewer sees ONLY the KB + the question set.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md`

**Dispatch 3 — Clean-context act-back reviewer (M4):**

Dispatch ONE clean-context `aid-reviewer` (identical to the `panel: full` M4 dispatch):
- Brief (rendered above) + `references/reviewer-prompt-actback.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline the full contents of `.aid/.temp/review-pending/{{SCOPE}}-actback-task.md`
  (both the representative-task spec and the operational-structure presence table) for
  `{{ACTBACK_TASK_SPEC}}`.
- **Stricter clean-context rule:** the M4 dispatch MUST NOT include project source
  files, the project-index, candidate-concepts.md, or any generation artifacts — the
  reviewer sees ONLY the KB + the representative-task spec and presence-check output.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-actback.md`

**Dispatch all three IN PARALLEL** (one message, 3 dispatches). The sequential-passes
reviewer handles M1/M2 internally; the clean-context teach-back reviewer handles
M3 concurrently; the clean-context act-back reviewer handles M4 concurrently.

**A3 capability-probe:** if parallel dispatch is unavailable, dispatch Dispatch 1 first
(wait for completion), then Dispatch 2, then Dispatch 3.

Print: `[Review 1/3] Panel dispatched (collapsed: 3 dispatches, 4 mandates). Waiting...`

Wait for all three to complete. Record actual time per dispatch.

---

**⚠️ CLEAN CONTEXT (all mandates, both panel modes):** Do NOT include any info about
the generation process, which agents ran, or prior state. Each reviewer evaluates
purely on what is on disk.

**⚠️ CONTAMINATION PREVENTION (all mandates, both panel modes; also applies in FIX
mode Step 6):**
- Do NOT include previous review results in any mandate prompt
- Do NOT tell reviewers what was fixed or the previous grade
- Do NOT say "re-review" — each mandate reviewer must approach fresh

**⚠️ M3 ADDITIONAL CLEAN-CONTEXT RULE (both panel modes):** The Teach-back mandate
reviewer MUST see ONLY the KB (`.aid/knowledge/*.md`) and the question set. Do NOT
pass project source files, project-index, candidate-concepts.md, or any generation
artifacts.

**⚠️ M4 ADDITIONAL CLEAN-CONTEXT RULE (both panel modes):** The Act-back mandate
reviewer MUST see ONLY the KB (`.aid/knowledge/*.md`) and the representative-task spec
+ operational-structure presence check output (from `kb-actback-task.sh`). Do NOT pass
project source files, project-index, candidate-concepts.md, or any generation artifacts.
The reviewer may cite a KB doc's `sources:` frontmatter to note "the KB defers this to
source" (which is itself an `[ACTBACK]` insufficiency finding), but does NOT read the
source file.

---

### Step 2: Aggregate + Grade

Print: `[Review 2/3] Aggregating panel findings...`

**2a. Merge the scratch ledgers into the single canonical ledger**

Collect all data rows from the scratch ledgers. The set of scratch ledgers depends on
the `review.panel` mode used in Step 1:

- **`panel: full`:** four scratch ledgers:
  - `.aid/.temp/review-pending/{{SCOPE}}-correctness.md`
  - `.aid/.temp/review-pending/{{SCOPE}}-anatomy.md`
  - `.aid/.temp/review-pending/{{SCOPE}}-teachback.md`
  - `.aid/.temp/review-pending/{{SCOPE}}-actback.md`
- **`panel: collapsed`:** three scratch ledgers:
  - `.aid/.temp/review-pending/{{SCOPE}}-content.md` (M1/M2 rows from both
    sequential passes — already concatenated in mandate order by the reviewer)
  - `.aid/.temp/review-pending/{{SCOPE}}-teachback.md` (M3 rows from the clean-context
    teach-back reviewer)
  - `.aid/.temp/review-pending/{{SCOPE}}-actback.md` (M4 rows from the clean-context
    act-back reviewer)

If `.aid/.temp/review-pending/{{SCOPE}}.md` already exists (cycle N>=2), read its
existing rows first. Each mandate reviewer's rows are identified by their `#` ID prefix
(M1-NNN, M2-NNN, TB-NNN, AB-NNN) — the mandate reviewers have updated
their own rows' Status in their scratch ledgers. Merge rule:

1. For rows in the existing `{{SCOPE}}.md` that correspond to a mandate's scratch
   ledger, replace the row with the scratch ledger's version (Status updated by the
   reviewer).
2. For new rows (new findings) in the scratch ledgers, append them with the next
   available `MN-NNN`, `TB-NNN`, or `AB-NNN` ID within that mandate's namespace.
3. Assign **stable per-mandate IDs** in the `#` column: `M1-001`..`M1-NNN`,
   `M2-001`..`M2-NNN`, `TB-001`..`TB-NNN`, `AB-001`..`AB-NNN`. These IDs are
   monotonic within each mandate's namespace and never reassigned to a different
   finding.
4. Each Description must carry its mandate marker prefix (`[M1]`, `[M2]`,
   `[TEACHBACK]`, or `[ACTBACK]`) — the mandate reviewers have written these;
   verify they are present. (The M2 Anatomy rows additionally carry their finding-type
   tag, e.g. `[KB-MISSING]`, `[CAL-COVERAGE]`, `[CAL-HOLLOW]`, `[CAL-TRANSCRIPTION]`,
   `[CAL-DEFERRAL]`, after the `[M2]` prefix.)

Write the merged result to `.aid/.temp/review-pending/{{SCOPE}}.md` (the canonical
ledger, 7-column schema).

**2b. Run the existing grade.sh unchanged**

```bash
bash canonical/scripts/grade.sh --explain .aid/.temp/review-pending/{{SCOPE}}.md
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

**2d. Derive the act-back verdict**

The act-back verdict is NOT a stored sentinel. Read it directly from
`.aid/.temp/review-pending/{{SCOPE}}.md`:

- Count rows where Description contains `[ACTBACK]` AND Status is in {Pending, Recurred}.
- `act_back_verdict = PASS` iff count == 0, else `FAIL`.

Both plan-correctness FAIL items and sufficiency FAIL items (convention / invariant /
gotcha / contract) are ordinary `[HIGH]` `[ACTBACK]` rows. Any open `[ACTBACK]` row
forces grade <= D (because `[HIGH]` rows make grade <= D in `grade.sh`) — the act-back
hard gate is realized entirely through the merged rows, the sibling-keystone mechanism.
No separate boolean, no AND to reconcile.

**2e. Delete the transient scratch ledgers**

After merging, delete the per-mandate scratch files and the oracle/question-set
transients. The set of scratch files deleted depends on the `review.panel` mode used:

For **`panel: full`**:
```bash
rm -f \
  .aid/.temp/review-pending/{{SCOPE}}-correctness.md \
  .aid/.temp/review-pending/{{SCOPE}}-anatomy.md \
  .aid/.temp/review-pending/{{SCOPE}}-teachback.md \
  .aid/.temp/review-pending/{{SCOPE}}-actback.md \
  .aid/.temp/review-pending/{{SCOPE}}-oracle-a.md \
  .aid/.temp/review-pending/{{SCOPE}}-oracle-b.md \
  .aid/.temp/review-pending/{{SCOPE}}-teachback-questions.txt \
  .aid/.temp/review-pending/{{SCOPE}}-actback-task.md
```

For **`panel: collapsed`**:
```bash
rm -f \
  .aid/.temp/review-pending/{{SCOPE}}-content.md \
  .aid/.temp/review-pending/{{SCOPE}}-teachback.md \
  .aid/.temp/review-pending/{{SCOPE}}-actback.md \
  .aid/.temp/review-pending/{{SCOPE}}-oracle-a.md \
  .aid/.temp/review-pending/{{SCOPE}}-oracle-b.md \
  .aid/.temp/review-pending/{{SCOPE}}-teachback-questions.txt \
  .aid/.temp/review-pending/{{SCOPE}}-actback-task.md
```

`{{SCOPE}}.md` is now the single source FIX reads, exactly as before.

---

### Step 3: Post-Process and Report

Print: `[Review 3/3] Review complete.`

Resolve the minimum grade:

```bash
bash canonical/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A
```

Compute:
- `ready = (grade >= minimum_grade)`
- `teach_back_display = PASS` or `FAIL` (from Step 2c)
- `act_back_display = PASS` or `FAIL` (from Step 2d)
- If `ready` and `teach_back_verdict == PASS` and `act_back_verdict == PASS`: `outcome = "Ready"`
- Otherwise: `outcome = "NOT Ready"`

Update `.aid/knowledge/STATE.md` `## Review History` with the new entry. Record the
grade computed by `grade.sh`, not any grade mentioned in the mandate reviewers' prose.

If `--grade` provided, update `.aid/settings.yml` `discover.minimum_grade` (via
`/aid-config` or direct YAML edit).

Print:
```
Grade: {grade} | Teach-back: {PASS|FAIL} | Act-back: {PASS|FAIL} -> {Ready|NOT Ready}
[Review 3/3] Grade: {grade}. Minimum: {min}. Run /aid-discover again to {fix issues|proceed}.
```

Print: `[State: REVIEW] complete.`

**Advance:** **CHAIN** → [State: Q-AND-A] if Pending Q&A entries with Impact: Required
exist; **CHAIN** → [State: FIX] otherwise. Both continue inline.

---

### Grade Aggregation Summary

The merge-and-grade logic is the same regardless of `review.panel` mode. All four
mandates produce rows in the merged `{{SCOPE}}.md`; the grader, teach-back gate,
and act-back gate are mode-agnostic.

```
panel: full  (brownfield-large)
  1. Four mandate reviewers run in parallel (M1..M4), each writing to its own
     scratch ledger. M3 writes one [HIGH] [TEACHBACK] row per FAIL item (per-term
     AND engine-narration FAILs alike -- no separate verdict sentinel). M4 writes
     one [HIGH] [ACTBACK] row per FAIL item (plan-correctness AND sufficiency FAILs
     alike -- no separate verdict sentinel).
  2. Orchestrator MERGES all 4 scratch ledgers into {{SCOPE}}.md (stable per-mandate
     IDs M1-NNN/M2-NNN/TB-NNN/AB-NNN; [M1]/[M2]/[TEACHBACK]/[ACTBACK] description
     prefixes), then DELETES the 4 transient scratch ledgers.

panel: collapsed  (brownfield-small only)
  1. ONE reviewer runs M1/M2 as separate sequential passes in one agent,
     writing both passes' findings to {{SCOPE}}-content.md (mandate rows
     M1-NNN/M2-NNN). ONE clean-context reviewer handles M3, writing
     [HIGH] [TEACHBACK] rows to {{SCOPE}}-teachback.md. ONE clean-context reviewer
     handles M4, writing [HIGH] [ACTBACK] rows to {{SCOPE}}-actback.md. All three
     dispatches run in parallel with each other (M1-M2 sequential WITHIN dispatch 1
     only).
  2. Orchestrator MERGES the 3 scratch ledgers ({{SCOPE}}-content.md +
     {{SCOPE}}-teachback.md + {{SCOPE}}-actback.md) into {{SCOPE}}.md (same stable
     per-mandate IDs and [Mi]/[TEACHBACK]/[ACTBACK] description prefixes as full
     mode), then DELETES all three transient scratch ledgers. The merged {{SCOPE}}.md
     is structurally identical to the full-mode output -- same 7-column schema, same
     mandate ID namespaces.

Both modes:
  3. grade = grade.sh {{SCOPE}}.md    # EXISTING grader, unchanged. Worst-severity
                                      # dominates, counts Status in {Pending,Recurred}.
                                      # Any open [TEACHBACK] OR [ACTBACK] row forces
                                      # grade <= D.

  4. READY iff grade >= minimum_grade # Single gate. An open teach-back OR act-back
                                      # gap is a [HIGH] row -> grade <= D -> not Ready.
                                      # No second boolean, no AND/OR to reconcile.

  5. teach_back verdict = FAIL iff any open [TEACHBACK] row, else PASS.
     act_back verdict   = FAIL iff any open [ACTBACK] row,   else PASS.

  6. STATE + print report the TRIPLE: "Grade: <g> | Teach-back: <v> | Act-back: <v>"
```

**Why merge rather than keep four ledgers:** FIX (`state-fix.md`) and `grade.sh` are
built around ONE `<scope>.md` per skill invocation. Merging to the single ledger keeps
FIX, `grade.sh`, and the schema unchanged — the panel is an input-side fan-out that
collapses back to the existing single-ledger contract before grading. The collapsed
mode produces the same merged output — `{{SCOPE}}.md` with the same schema and the
same per-mandate ID namespaces — so FIX, `grade.sh`, the teach-back gate, and the
act-back gate are entirely unaware of which panel mode was used.
