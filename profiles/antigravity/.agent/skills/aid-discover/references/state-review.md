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
bash .agent/aid/scripts/kb/closure-check.sh \
  --output-a .aid/.temp/review-pending/{{SCOPE}}-oracle-a.md \
  --output-b .aid/.temp/review-pending/{{SCOPE}}-oracle-b.md
```

If `candidate-concepts.md` does not exist yet, the oracle emits empty outputs — the
panel degrades gracefully (M2 finds no coverage evidence; M3 falls back to the
engine-narration question only). This is not an error. (Output (a) is still emitted for
diagnostic use, but the panel mandates consume only output (b).)

Also run `kb-dual-intent-probes.sh essence` to produce the M3 essence probe set
(Intent 2 — Blind Reconstruction + Source Confrontation):

```bash
bash .agent/aid/scripts/kb/kb-dual-intent-probes.sh essence \
  --doc-set .aid/generated/doc-set.tsv \
  --kb-dir .aid/knowledge \
  --output .aid/.temp/review-pending/{{SCOPE}}-teachback-questions.txt
```

The essence probes are derived from the project's own C4 vocabulary doc, C9 capability
doc, and D decisions doc — they are deterministic and self-sourced (no external corpus).
If no C4/C9/D docs are present, the output contains only the fixed narrative probe. This
is not an error.

Also run `kb-dual-intent-probes.sh work` to produce the M4 derived work-probe set
(Intent 1 — Blind Work-Simulation / assertiveness gate):

```bash
bash .agent/aid/scripts/kb/kb-dual-intent-probes.sh work \
  --doc-set .aid/generated/doc-set.tsv \
  --kb-dir .aid/knowledge \
  --output .aid/.temp/review-pending/{{SCOPE}}-actback-task.md
```

The work probes are derived from the project's C9 capability doc + load-bearing spine
dimensions (C5 data/contracts, C3 conventions, C2 parts, C6 quality), keyed to this
project's doc-set. Deterministic: same doc-set + same C9 doc → byte-identical output.

Also run `kb-actback-task.sh check` to produce the operational-structure presence check
(the named first-class sections table that Step 1 in `reviewer-prompt-actback.md`
reads):

```bash
bash .agent/aid/scripts/kb/kb-actback-task.sh check \
  --doc-set .aid/generated/doc-set.tsv \
  --kb-dir .aid/knowledge \
  --output .aid/.temp/review-pending/{{SCOPE}}-actback-presence.md
```

The operational-structure presence check is spine-keyed: it fires for whatever doc
realizes each load-bearing dimension (C5 → Contracts, C3 → Conventions, C2 → Parts,
C7 → Gotchas) in this project's doc-set. If the TSV does not exist yet, both
`kb-dual-intent-probes.sh work` and `kb-actback-task.sh check` will exit 1 — run
GENERATE first.

The M4 `{{ACTBACK_TASK_SPEC}}` placeholder is populated by concatenating the work-probe
set (from `kb-dual-intent-probes.sh work`) and the operational-structure presence check
(from `kb-actback-task.sh check`):

```bash
cat .aid/.temp/review-pending/{{SCOPE}}-actback-task.md \
    .aid/.temp/review-pending/{{SCOPE}}-actback-presence.md \
  > .aid/.temp/review-pending/{{SCOPE}}-actback-task-full.md
```

Use `{{SCOPE}}-actback-task-full.md` as the content for `{{ACTBACK_TASK_SPEC}}`.

**Compute the reviewed knowledge surface (keystone gates M3/M4)**

The M3 (Essence) and M4 (Assertiveness) keystone gates MUST read only *hand-authored
project knowledge* — never the process/ledger docs (`STATE.md`, `README.md`) or generated
docs (`INDEX.md`), which would poison the reconstruction/work-simulation and (because these
gates force grade ≤ D) the grade itself. Compute the surface deterministically with the
`list_reviewable` accessor (defined in `references/doc-set-resolve.md`):

```bash
# Inline list_reviewable from references/doc-set-resolve.md, then:
REVIEW_SURFACE="$(list_reviewable .aid/knowledge)"
```

`REVIEW_SURFACE` is the newline-separated list of `.aid/knowledge/*.md` docs whose
frontmatter is `kb-category != meta` AND `source != generated`. Pass THIS explicit list to
the M3 and M4 dispatches as their KB scope — do NOT hand them a raw `.aid/knowledge/*.md`
glob (which sweeps in the meta ledgers + INDEX). M1/M2 already route by `kb-category` (meta →
Spot-Check only), so this closes the remaining gap at the two keystone gates.

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
  reviewer + clean-context teach-back + clean-context act-back).

**Greenfield -- two distinct cases (not the same path):**

- **Discovery-triage greenfield (Step 0f):** A project *classified* greenfield during
  aid-discover's brownfield-discovery triage (Step 0f) has no extracted KB to deeply
  review. Its `panel:` branch collapses and the review panel is skipped entirely.
  This skip applies ONLY to the discovery-triage path and is NOT triggered by a seed
  review.
- **Seed-review greenfield (`greenfield: true`):** A `greenfield: true` review
  invocation (from the aid-describe seed-authoring step, flow step 5) is a DISTINCT
  entry point -- it is NOT entered via Step 0f triage. Per NFR-3, the seed review MUST
  traverse the FULL panel (`panel: full`): same four mandates (M1-M4), same dimension
  floors, intent-evidence substituted for code/config evidence, named as-built red flags
  relaxed -- per `document-expectations.md` `## Greenfield Mode`. The reviewer brief
  carries `{{GREENFIELD_BLOCK}}` (rendered to the greenfield instruction when invoked
  this way) to communicate the mode to each mandate reviewer.

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

**M2 Authoring Standard Checks (dual-audience standard, principles.md P10)**

The M2 Anatomy mandate MUST additionally check every Full Primary doc for compliance
with the dual-audience authoring standard. These checks extend the Anatomy checklist:

*Mechanical checks* (flag as `[HIGH]` `[AUTHORING-LAYOUT]` or `[AUTHORING-FM]`):

| Check | Severity | Tag |
|-------|----------|-----|
| Frontmatter is the first block (before any content) | `[HIGH]` | `[AUTHORING-LAYOUT]` |
| A `## Contents` or equivalent index/TOC section is present near the top (required for docs with more than 3 sections) | `[MEDIUM]` | `[AUTHORING-LAYOUT]` |
| `## Change Log` (or equivalent change-log heading) is the **last** section in the document -- no content follows it | `[HIGH]` | `[AUTHORING-LAYOUT]` |
| Core frontmatter fields are present: `objective:`, `summary:`, `sources:` | `[HIGH]` | `[AUTHORING-FM]` |
| Classification fields are present: `audience:`, `owner:`, `tags:` | `[MEDIUM]` | `[AUTHORING-FM]` |
| `tags:` includes a concern ID (C0-C9 or D) mapping the doc to a spine dimension (orientation/meta docs `external-sources`, `README` are exempt -- no concern) | `[MEDIUM]` | `[AUTHORING-FM]` |
| Document body contains no Mermaid blocks (` ```mermaid `) or ER diagram blocks (` ```erDiagram `) | `[MEDIUM]` | `[AUTHORING-DIAGRAM]` |

*Judgment checks* (flag as `[MEDIUM]` with description tag `[AUTHORING-CLARITY]` or `[AUTHORING-SCOPE]`):

| Check | Severity | Tag |
|-------|----------|-----|
| **Reading level**: does the prose use plain, clear, concrete language a junior professional can follow? Flag jargon-dense paragraphs with no plain-language alternative. | `[MEDIUM]` | `[AUTHORING-CLARITY]` |
| **Single-concern coherence**: does the document answer exactly ONE concern question (C0-C9 / D) without mixing in material from an orthogonal concern? Flag boundary smells (content that belongs in a different concern doc). | `[MEDIUM]` | `[AUTHORING-SCOPE]` |

**Scope of the M2 authoring checks:** apply them ONLY to **Full Primary docs** (per the
`kb-category` routing below) — the hand-authored `primary` knowledge docs. Do NOT apply the
authoring checklist to `kb-category: meta` process/ledger docs (`STATE.md`, `README.md` —
they route to Spot-Check Snapshot, not the full checklist), nor to non-`.md` files.

**Note on `kb.html`:** the visual summary generated by `aid-summarize` (`kb.html`) is
a deliberately-visual artifact designed for browser rendering. The no-diagram rule
(`[AUTHORING-DIAGRAM]`) does **not** apply to `kb.html` and the M2 mandate MUST NOT flag
diagrams in the `kb.html` file (it is not a `.md` KB doc and is out of the authoring-check
scope above).

These checks use the same ledger row format as other M2 findings:
```
| M2-NNN | [MEDIUM] | Pending | module-map.md | — | [M2] [AUTHORING-DIAGRAM] Mermaid block found in KB .md doc | grep -n "mermaid" .aid/knowledge/module-map.md |
| M2-NNN | [HIGH]   | Pending | schemas.md    | — | [M2] [AUTHORING-LAYOUT] Change Log section is not the last section -- content follows it | Line 147: "## Contracts" appears after "## Change Log" |
```

**M3 — Essence Gate (keystone; Blind Reconstruction + Source Confrontation):**
- Brief + `references/reviewer-prompt-teachback.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline `{{SCOPE}}-teachback-questions.txt` contents for `{{TEACHBACK_QUESTIONS}}`
  (the essence probe set produced by `kb-dual-intent-probes.sh essence` above).
- **Stricter clean-context rule:** the M3 dispatch MUST NOT include project source
  files, the project-index, candidate-concepts.md, or any generation artifacts — the
  reviewer sees ONLY the KB + the essence probe set for Stage 1 (Reconstruct). Source
  access is permitted only in Stage 2 (Confront).
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md`
  (rows prefixed `[FIDELITY]` or `[ESSENCE-GAP]`)

**M4 — Assertiveness Gate (keystone; Blind Work-Simulation):**
- Brief + `references/reviewer-prompt-actback.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline the full contents of `.aid/.temp/review-pending/{{SCOPE}}-actback-task-full.md`
  (the derived work-probe set from `kb-dual-intent-probes.sh work` + the
  operational-structure presence check from `kb-actback-task.sh check`, as produced
  and concatenated in the pre-dispatch step above) for `{{ACTBACK_TASK_SPEC}}`.
- **Stricter clean-context rule:** the M4 dispatch MUST NOT include project source
  files, the project-index, candidate-concepts.md, or any generation artifacts — the
  reviewer sees ONLY the KB + the derived work-probe set and presence-check output.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-actback.md`
  (rows prefixed `[ACTBACK]`)

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

**Dispatch 2 — Clean-context essence reviewer (M3):**

Dispatch ONE clean-context `aid-reviewer` (identical to the `panel: full` M3 dispatch):
- Brief (rendered above) + `references/reviewer-prompt-teachback.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline `{{SCOPE}}-teachback-questions.txt` contents for `{{TEACHBACK_QUESTIONS}}`
  (the essence probe set produced by `kb-dual-intent-probes.sh essence` above).
- **Stricter clean-context rule:** the M3 dispatch MUST NOT include project source
  files, the project-index, candidate-concepts.md, or any generation artifacts — the
  reviewer sees ONLY the KB + the essence probe set for Stage 1 (Reconstruct). Source
  access is permitted only in Stage 2 (Confront).
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-teachback.md`
  (rows prefixed `[FIDELITY]` or `[ESSENCE-GAP]`)

**Dispatch 3 — Clean-context assertiveness reviewer (M4):**

Dispatch ONE clean-context `aid-reviewer` (identical to the `panel: full` M4 dispatch):
- Brief (rendered above) + `references/reviewer-prompt-actback.md`
- Substitute `{{SCOPE}}` in the FOCUS body.
- Inline the full contents of `.aid/.temp/review-pending/{{SCOPE}}-actback-task-full.md`
  (the derived work-probe set from `kb-dual-intent-probes.sh work` + the
  operational-structure presence check from `kb-actback-task.sh check`, concatenated
  in the pre-dispatch step above) for `{{ACTBACK_TASK_SPEC}}`.
- **Stricter clean-context rule:** the M4 dispatch MUST NOT include project source
  files, the project-index, candidate-concepts.md, or any generation artifacts — the
  reviewer sees ONLY the KB + the derived work-probe set and presence-check output.
- Ledger: write to `.aid/.temp/review-pending/{{SCOPE}}-actback.md`
  (rows prefixed `[ACTBACK]`)

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

**⚠️ M3 ADDITIONAL CLEAN-CONTEXT RULE (both panel modes):** The Essence Gate mandate
reviewer MUST see ONLY the **reviewed knowledge surface** (`REVIEW_SURFACE` — the
hand-authored `primary`/`extension` KB docs from `list_reviewable`; the meta process/ledger
docs `STATE.md`/`README.md` and the generated `INDEX.md` are NOT part of it) and the essence
probe set for Stage 1 (Reconstruct). Do NOT pass project source files, project-index,
candidate-concepts.md, generation artifacts, or the excluded meta/generated KB files during
Stage 1. Source access is
permitted ONLY in Stage 2 (Confront). Findings are tagged `[FIDELITY]` (Divergence)
or `[ESSENCE-GAP]` (load-bearing Omission) — NOT `[TEACHBACK]`.

**⚠️ M4 ADDITIONAL CLEAN-CONTEXT RULE (both panel modes):** The Assertiveness Gate
mandate reviewer MUST see ONLY the **reviewed knowledge surface** (`REVIEW_SURFACE` — the
hand-authored `primary`/`extension` KB docs from `list_reviewable`; the meta process/ledger
docs `STATE.md`/`README.md` and the generated `INDEX.md` are excluded) and the derived
work-probe set + operational-structure presence check output (from
`kb-dual-intent-probes.sh work` + `kb-actback-task.sh check`). Do NOT pass project
source files, project-index, candidate-concepts.md, or any generation artifacts.
The reviewer may cite a KB doc's `sources:` frontmatter to note "the KB defers this to
source" (which is itself an `[ACTBACK]` insufficiency finding), but does NOT read the
source file. Findings are tagged `[ACTBACK]`.

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
   `[FIDELITY]`, `[ESSENCE-GAP]`, or `[ACTBACK]`) — the mandate reviewers have
   written these; verify they are present. M3 rows carry `[FIDELITY]` (Divergence)
   or `[ESSENCE-GAP]` (load-bearing Omission); M4 rows carry `[ACTBACK]`. (The M2
   Anatomy rows additionally carry their finding-type tag, e.g. `[KB-MISSING]`,
   `[CAL-COVERAGE]`, `[CAL-HOLLOW]`, `[CAL-TRANSCRIPTION]`, `[CAL-DEFERRAL]`, after
   the `[M2]` prefix.)

Write the merged result to `.aid/.temp/review-pending/{{SCOPE}}.md` (the canonical
ledger, 7-column schema).

**2b. Run the existing grade.sh unchanged**

```bash
bash .agent/aid/scripts/grade.sh --explain .aid/.temp/review-pending/{{SCOPE}}.md
```

`grade.sh` counts worst-severity over Status in {Pending, Recurred} across ALL rows,
regardless of which mandate produced them. It reads only the Severity column (col 3)
and Status column (col 4) — mandate-marker text in Description/Evidence is invisible
to the grader. No `grade.sh` change.

The grade is printed to stdout; `--explain` breakdown to stderr.

**2c. Derive the essence verdict (Intent 2 — Blind Reconstruction + Source Confrontation)**

The essence verdict is NOT a stored sentinel. Read it directly from
`.aid/.temp/review-pending/{{SCOPE}}.md`.

**Essence gate PASS thresholds (both conditions must hold):**
1. **Zero `[HIGH] [FIDELITY]` rows open** — no Divergence (KB contradicts source).
   Count rows where Description contains `[FIDELITY]` AND Status is in {Pending, Recurred}.
   If count > 0: essence_verdict = FAIL (Divergence threshold violated).
2. **Load-bearing essence-coverage >= 90%** — at most 10% of load-bearing source facts
   missing from the KB reconstruction.
   Count rows where Description contains `[ESSENCE-GAP]` AND Status is in {Pending, Recurred}.
   Let total_load_bearing = (open `[ESSENCE-GAP]` count) + (load-bearing facts covered by
   the KB reconstruction, per the M3 reviewer's Stage 2 evidence). If the open gap count
   exceeds 10% of total_load_bearing: essence_verdict = FAIL (coverage threshold violated).
   If total_load_bearing cannot be derived from the ledger alone, apply the conservative
   rule: any open `[ESSENCE-GAP]` row with `[HIGH]` or `[MED]` severity caps the verdict
   at FAIL until the M3 reviewer confirms the coverage ratio.

`essence_verdict = PASS` iff both conditions hold, else `FAIL`.

Divergence FAIL items are ordinary `[HIGH] [FIDELITY]` rows; load-bearing Omission FAIL
items are ordinary `[MED] [ESSENCE-GAP]` rows. Any open `[FIDELITY]` row forces grade
<= D (because `[HIGH]` rows make grade <= D in `grade.sh`) — the essence hard gate is
realized entirely through the merged rows. No separate boolean, no AND to reconcile.

**2d. Derive the assertiveness verdict (Intent 1 — Blind Work-Simulation)**

The assertiveness verdict is NOT a stored sentinel. Read it directly from
`.aid/.temp/review-pending/{{SCOPE}}.md`.

**Assertiveness gate PASS thresholds (all three conditions must hold):**
1. **Zero `[HIGH] [ACTBACK]` rows open** — no load-bearing ASSUMED/REACH step and no
   quality-contract FAIL.
   Count rows where Description contains `[ACTBACK]` AND Status is in {Pending, Recurred}.
   If count > 0: assertiveness_verdict = FAIL.
2. **STATED-coverage >= 90%** — at least 90% of plan steps across all work probes must
   be tagged STATED (KB explicitly gave the contract, convention, invariant, or schema
   shape needed). The M4 reviewer's STATED/ASSUMED/REACH tagging in the ledger evidence
   is the source; if the reviewer did not record step counts, apply the conservative rule:
   any open `[ACTBACK]` row implies the threshold is violated.
3. **All quality-contracts present** — the operational-structure presence check (inlined
   as part of `{{ACTBACK_TASK_SPEC}}`) confirms the named first-class sections
   (`## Conventions`, `## Invariants`, `## Gotchas`, `## Contracts`) are present in the
   docs that own them (per the spine-keyed owning-table). An absent required section is
   itself an `[ACTBACK]` row in the M4 ledger; if any such row is open, this condition
   fails automatically.

`assertiveness_verdict = PASS` iff all three conditions hold, else `FAIL`.

All FAIL items (plan-correctness, sufficiency, quality) are ordinary `[HIGH] [ACTBACK]`
rows. Any open `[ACTBACK]` row forces grade <= D (because `[HIGH]` rows make grade <= D
in `grade.sh`) — the assertiveness hard gate is realized entirely through the merged rows,
the sibling-keystone mechanism. No separate boolean, no AND to reconcile.

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
  .aid/.temp/review-pending/{{SCOPE}}-actback-task.md \
  .aid/.temp/review-pending/{{SCOPE}}-actback-presence.md \
  .aid/.temp/review-pending/{{SCOPE}}-actback-task-full.md
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
  .aid/.temp/review-pending/{{SCOPE}}-actback-task.md \
  .aid/.temp/review-pending/{{SCOPE}}-actback-presence.md \
  .aid/.temp/review-pending/{{SCOPE}}-actback-task-full.md
```

`{{SCOPE}}.md` is now the single source FIX reads, exactly as before.

---

### Step 3: Post-Process and Report

Print: `[Review 3/3] Review complete.`

Resolve the minimum grade:

```bash
bash .agent/aid/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A
```

Compute:
- `ready = (grade >= minimum_grade)`
- `essence_display = PASS` or `FAIL` (from Step 2c — essence verdict)
- `assertiveness_display = PASS` or `FAIL` (from Step 2d — assertiveness verdict)
- If `ready` and `essence_verdict == PASS` and `assertiveness_verdict == PASS`: `outcome = "Ready"`
- Otherwise: `outcome = "NOT Ready"`

Update `.aid/knowledge/STATE.md` `## Review History` with the new entry. Record the
grade computed by `grade.sh`, not any grade mentioned in the mandate reviewers' prose.

If `--grade` provided, update `.aid/settings.yml` `discover.minimum_grade` (via
`/aid-config` or direct YAML edit).

Print:
```
Grade: {grade} | Essence: {PASS|FAIL} | Assertiveness: {PASS|FAIL} -> {Ready|NOT Ready}
[Review 3/3] Grade: {grade}. Minimum: {min}. Run /aid-discover again to {fix issues|proceed}.
```

Print: `[State: REVIEW] complete.`

**Advance:** **CHAIN** → [State: Q-AND-A] if Pending Q&A entries with Impact: Required
exist; **CHAIN** → [State: FIX] otherwise. Both continue inline.

---

### Grade Aggregation Summary

The merge-and-grade logic is the same regardless of `review.panel` mode. All four
mandates produce rows in the merged `{{SCOPE}}.md`; the grader, essence gate,
and assertiveness gate are mode-agnostic.

**Dual-intent gate tag reference:**

| Intent | Gate | Tags | Severity | Threshold |
|--------|------|------|----------|-----------|
| Intent 2 -- Essence (M3) | Essence Gate | `[FIDELITY]` (Divergence) | `[HIGH]` | Zero open `[FIDELITY]` rows |
| Intent 2 -- Essence (M3) | Essence Gate | `[ESSENCE-GAP]` (Omission) | `[MED]` | Load-bearing coverage >= 90% |
| Intent 1 -- Assertiveness (M4) | Assertiveness Gate | `[ACTBACK]` (all FAIL classes) | `[HIGH]` | Zero open `[ACTBACK]` rows + STATED >= 90% + all quality-contracts present |

```
panel: full  (brownfield-large)
  1. Four mandate reviewers run in parallel (M1..M4), each writing to its own
     scratch ledger. M3 writes [HIGH] [FIDELITY] rows for Divergence FAILs and
     [MED] [ESSENCE-GAP] rows for load-bearing Omission FAILs (no separate
     verdict sentinel). M4 writes one [HIGH] [ACTBACK] row per FAIL item
     (plan-correctness, sufficiency, AND quality FAILs alike -- no separate
     verdict sentinel).
  2. Orchestrator MERGES all 4 scratch ledgers into {{SCOPE}}.md (stable per-mandate
     IDs M1-NNN/M2-NNN/TB-NNN/AB-NNN; [M1]/[M2]/[FIDELITY] or [ESSENCE-GAP]/[ACTBACK]
     description prefixes), then DELETES the 4 transient scratch ledgers.

panel: collapsed  (brownfield-small only)
  1. ONE reviewer runs M1/M2 as separate sequential passes in one agent,
     writing both passes' findings to {{SCOPE}}-content.md (mandate rows
     M1-NNN/M2-NNN). ONE clean-context reviewer handles M3, writing
     [HIGH] [FIDELITY] and [MED] [ESSENCE-GAP] rows to {{SCOPE}}-teachback.md.
     ONE clean-context reviewer handles M4, writing [HIGH] [ACTBACK] rows to
     {{SCOPE}}-actback.md. All three dispatches run in parallel with each other
     (M1-M2 sequential WITHIN dispatch 1 only).
  2. Orchestrator MERGES the 3 scratch ledgers ({{SCOPE}}-content.md +
     {{SCOPE}}-teachback.md + {{SCOPE}}-actback.md) into {{SCOPE}}.md (same stable
     per-mandate IDs and [M1]/[M2]/[FIDELITY] or [ESSENCE-GAP]/[ACTBACK] description
     prefixes as full mode), then DELETES all three transient scratch ledgers. The
     merged {{SCOPE}}.md is structurally identical to the full-mode output -- same
     7-column schema, same mandate ID namespaces.

Both modes:
  3. grade = grade.sh {{SCOPE}}.md    # EXISTING grader, unchanged. Worst-severity
                                      # dominates, counts Status in {Pending,Recurred}.
                                      # Any open [FIDELITY] OR [ACTBACK] row forces
                                      # grade <= D.

  4. READY iff grade >= minimum_grade # Single gate. An open essence OR assertiveness
                                      # gap is a [HIGH] row -> grade <= D -> not Ready.
                                      # No second boolean, no AND/OR to reconcile.

  5. essence_verdict = FAIL iff any open [FIDELITY] row, OR
                                load-bearing essence-coverage < 90%, else PASS.
     assertiveness_verdict = FAIL iff any open [ACTBACK] row, OR
                                STATED-coverage < 90%, OR
                                any quality-contract absent, else PASS.

  6. STATE + print report the TRIPLE: "Grade: <g> | Essence: <v> | Assertiveness: <v>"
```

**Why merge rather than keep four ledgers:** FIX (`state-fix.md`) and `grade.sh` are
built around ONE `<scope>.md` per skill invocation. Merging to the single ledger keeps
FIX, `grade.sh`, and the schema unchanged — the panel is an input-side fan-out that
collapses back to the existing single-ledger contract before grading. The collapsed
mode produces the same merged output — `{{SCOPE}}.md` with the same schema and the
same per-mandate ID namespaces — so FIX, `grade.sh`, the essence gate, and the
assertiveness gate are entirely unaware of which panel mode was used.
