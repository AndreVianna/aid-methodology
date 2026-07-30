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
bash .cursor/aid/scripts/kb/closure-check.sh \
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
bash .cursor/aid/scripts/kb/kb-dual-intent-probes.sh essence \
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
bash .cursor/aid/scripts/kb/kb-dual-intent-probes.sh work \
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
bash .cursor/aid/scripts/kb/kb-actback-task.sh check \
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

Declare the four mandates in the invocation manifest and CHAIN to `/aid-deep-review` in **panel mode**.
It owns the dispatch, the per-mandate scratch ledgers, the merge, the gap gate and the grade.

```yaml
depth:   deep
panel:   full
mandates:
  - id: M1                      # Correctness
    prompt:  references/reviewer-prompt-correctness.md
    rule_set: KB
    surface: [<REVIEW_SURFACE>, <project sources>]
  - id: M2                      # Anatomy / coverage / altitude
    prompt:  references/reviewer-prompt-anatomy.md
    rule_set: KB
    surface: [<REVIEW_SURFACE>, <project sources>]
    inline:
      DOCUMENT_EXPECTATIONS: references/document-expectations.md
      CLOSURE_CHECK_B:       <closure-check.sh output (b)>
  - id: M3                      # Essence gate -- keystone
    prompt:  references/reviewer-prompt-teachback.md
    rule_set: KB
    surface: [<REVIEW_SURFACE>]
    deny:    [<project sources>, <project-index>, candidate-concepts.md, .aid/generated/**]
    inline:
      TEACHBACK_QUESTIONS: <kb-dual-intent-probes.sh essence output>
  - id: M4                      # Assertiveness gate -- keystone
    prompt:  references/reviewer-prompt-actback.md
    rule_set: KB
    surface: [<REVIEW_SURFACE>]
    deny:    [<project sources>, <project-index>, candidate-concepts.md, .aid/generated/**]
    inline:
      ACTBACK_TASK_SPEC: <work-probe set + operational-structure presence check>
```

Substitute `{{SCOPE}}` in each mandate's FOCUS body. Each mandate's scratch ledger path comes from the
manifest, and each writes only its own.

**M3 and M4's `deny` lists ARE the mandate, not a precaution.** Both reconstruct meaning from the KB
alone, so a reviewer permitted to read the source is not being tested at all. `/aid-deep-review` enforces
denial **at dispatch** — an agent cannot un-see a file it was handed. Their surfaces differ from M1/M2's,
which is also precisely why they may not be collapsed into the same dispatch.

**M3** emits `[FIDELITY]` (divergence) or `[ESSENCE-GAP]` (load-bearing omission) — never `[TEACHBACK]`.
**M4** emits `[ACTBACK]`. M4 may cite a doc's `sources:` frontmatter to note *"the KB defers this to
source"* — itself an insufficiency finding — without reading the source file.

**Note on `kb.html`:** the generated visual summary is deliberately visual, so `KB-07` (no diagram
blocks) does not apply to it and M2 must not flag diagrams there. It is not a `.md` KB doc.


---

#### `panel: collapsed` — Three Dispatches (Brownfield-Small Only)

All four mandates still run. Collapsing is a **scheduling** choice for small projects, never a semantic
one: each mandate is still adjudicated on its own, and the anti-blending property is preserved.

Same manifest as `panel: full`, with `panel: collapsed` and M1/M2 sharing one dispatch:

```yaml
depth:   deep
panel:   collapsed
mandates:
  - id: [M1, M2]                # ONE dispatch, two sequential passes -- see below
    prompt:  [references/reviewer-prompt-correctness.md, references/reviewer-prompt-anatomy.md]
    rule_set: KB
    surface: [<REVIEW_SURFACE>, <project sources>]
  - id: M3
    prompt:  references/reviewer-prompt-teachback.md
    rule_set: KB
    surface: [<REVIEW_SURFACE>]
    deny:    [<project sources>, <project-index>, candidate-concepts.md, .aid/generated/**]
  - id: M4
    prompt:  references/reviewer-prompt-actback.md
    rule_set: KB
    surface: [<REVIEW_SURFACE>]
    deny:    [<project sources>, <project-index>, candidate-concepts.md, .aid/generated/**]
```

**Why M1 and M2 may share a dispatch and M3/M4 may not.** Collapsing is legal only where the mandates'
`surface` and `deny` sets are **identical** — M1 and M2 both see the KB plus the sources, so sharing costs
nothing. M3 and M4 deny the sources, so putting them in a source-aware dispatch would hand them exactly
what they are defined by refusing. The old prose said they "cannot share context with the source-aware
passes"; stating it as surface equality makes it checkable rather than remembered.

**M1/M2 run as SEPARATE SEQUENTIAL PASSES inside their shared dispatch.** Complete one mandate fully,
write its findings, then begin the next. Do not blend findings across mandates — each is an independent
evaluation, and blending them is the failure collapsing must not introduce.

M3 and M4 stay separate dispatches even from each other, so their scratch ledgers and verdicts remain
un-conflated.

---

### Step 2: Aggregate + Grade

Print: `[Review 2/3] Aggregating panel findings...`

**2a. Merge**

The scratch set is whatever the manifest declared — four ledgers under `panel: full`, three under
`panel: collapsed` (M1/M2 share one). This skill does not enumerate the paths; enumerating them in prose
is how they drifted from the paths actually dispatched.

**Reconciliation, the gap gate and the grade are `/aid-deep-review`'s panel mode.** This skill declares
the mandates; it no longer carries the merge, the join key, the gate or the grade.

Each mandate keeps its **own** marker prefix in `Description` — M1/M2 carry `[M1]`/`[M2]` (M2
additionally its finding-type tag, e.g. `[KB-MISSING]`, `[CAL-COVERAGE]`), M3 carries `[FIDELITY]` or
`[ESSENCE-GAP]`, M4 carries `[ACTBACK]`. Verify they are present; the mandate reviewers write them.

Two properties `/aid-deep-review` guarantees, restated only because getting them wrong here is silent:

- **Findings merge on `(Doc, Rule)`, never on the row ID.** Two mandates finding the same defect produce
  `M1-007` and `M3-004`; an ID-keyed join would record it twice.
- **`U-` and `G-` rows are not merged.** They are per-mandate bookkeeping — one coverage frontier per
  mandate, not one for the panel. The gate reads across every scratch instead
  (`check-gaps.sh --ledger A --ledger B ...`), which is why gaps still reach the orchestrator without
  being copied into the canonical ledger.

One grade for the artifact, over the merged ledger — not one per mandate.

**2c. Derive the essence verdict (Intent 2 — Blind Reconstruction + Source Confrontation)**

The essence verdict is NOT a stored sentinel. Read it directly from
`.aid/.temp/review-pending/{{SCOPE}}.md`.

**Essence gate PASS conditions (both must hold):**
Both conditions count **only this mandate's rows** — those whose `#` cell begins `TB-`.
Mandate scoping is what keeps the three reported verdicts independent; § 2d states the
argument in full, and it applies symmetrically here.

1. **Zero Divergence rows open** — the KB does not contradict the source.
   Count rows whose `#` begins `TB-` AND whose `Rule` cell is exactly `NAR-05` AND whose
   Status is in {Pending, Recurred}. If count > 0: essence_verdict = FAIL.
2. **Zero Omission rows open** — no load-bearing source fact is missing from the KB
   reconstruction. Count rows whose `#` begins `TB-` AND whose Description contains
   `[ESSENCE-GAP]` AND whose Status is in {Pending, Recurred}. If count > 0:
   essence_verdict = FAIL.

`essence_verdict = PASS` iff both conditions hold, else `FAIL`.

**Why condition 1 keys on `Rule` and not on the Description.** `[FIDELITY]` is a
Description *prefix* — free text. A gate that counts a substring inside free text fails in
both directions: a reviewer who writes the prefix in prose (or quotes another row's prefix
in its Evidence) inflates the count, and one who omits it silently zeroes the gate. `Rule`
is a closed enum with a single-valued cell contract
(`review-rubrics/INDEX.md § Rule ID format`), written only by `writeback-ledger.sh`, which
rejects a row whose `Rule` is absent or malformed. `NAR-05` is the rule the finding
actually violates — *"the document does not contradict a higher-authority source"* — so
the gate now counts the rule rather than a label describing it. The prefix stays in the
Description as a human-readable marker; nothing derives a verdict from it.

**Condition 2 still keys on the Description prefix. That is a recorded gap with a concrete
reason, not an oversight.** Divergence maps cleanly onto an existing rule; Omission does
not, and there are two independent obstacles:

1. **No criterion, so no rule may be authored.** Nothing in the KB declares that the
   Knowledge Base must carry the project's load-bearing source facts — the idea is stated
   only in `reviewer-prompt-teachback.md`'s own dispatch table, which is a skill prompt, not
   an authority. `review-rubrics/INDEX.md` is explicit: *"No Criterion, no row."*
2. **The IDs that *do* fit are the other gate's IDs.** An Omission row still needs a rule ID
   — `reviewer-ledger-schema.md § Rule values` says *"There is no exemption"* for a finding
   row, and `writeback-ledger.sh` refuses one with exit 4 — so in practice it carries the
   closest `KB-22`..`KB-26`. Keying this condition on that cell would therefore count
   act-back rules inside the essence gate, and one omitted fact would fail both verdicts.
   § 2d's `AB-` mandate scoping stops the leak in the other direction; keying essence on
   `Rule` would reopen it in this one.

Logged as a **Declined criteria gap** (`kb-essence/load-bearing-fact-coverage`, work
`STATE.md § Criteria Gaps`) per this work's own Q4/Q5 decision: the resolution is a human's
to make, and it is not an invented rule ID. Reopening it means declaring the standard in the
KB authoring conventions first, then re-pointing this condition at the rule that becomes
citable. Until then the marker is the honest carrier — it is at least *the thing the
reviewer was actually asked to emit*.

**Why the ≥ 90% coverage ratio is gone.** Condition 2 used to be *"load-bearing
essence-coverage ≥ 90%"*, whose denominator — the count of load-bearing facts the KB
reconstruction *did* cover — has no carrier in the ledger. It was a runtime claim by an
agent, unfalsifiable after the fact: the same class of unverifiable assertion feature-005
rejected for per-rule invalidation. What replaces it is the conservative rule already
written beside it. At an `A`-or-better floor the ratio never changed a decision anyway —
one open `[MEDIUM]` `[ESSENCE-GAP]` row fails the grade on its own — so the ratio protected a
*metric*, not a *gate*.

Divergence FAIL items are ordinary `[HIGH] [FIDELITY]` rows; load-bearing Omission FAIL
items are ordinary `[MEDIUM] [ESSENCE-GAP]` rows. Any open `[FIDELITY]` row forces grade
<= D (because `[HIGH]` rows make grade <= D in `grade.sh`) — the essence hard gate is
realized entirely through the merged rows. No separate boolean, no AND to reconcile.

**2d. Derive the assertiveness verdict (Intent 1 — Blind Work-Simulation)**

The assertiveness verdict is NOT a stored sentinel. Read it directly from
`.aid/.temp/review-pending/{{SCOPE}}.md`.

**Assertiveness gate PASS conditions (both must hold):**
1. **Zero insufficiency rows open** — no load-bearing ASSUMED/REACH step and no
   quality-contract FAIL. Count rows whose `#` cell begins `AB-` **and** whose `Rule` cell
   matches `^KB-2[0-6]$` **and** whose Status is in {Pending, Recurred}. If count > 0:
   assertiveness_verdict = FAIL.

   That regex is the act-back taxonomy exactly as
   [`review-rubrics/kb.md § Insufficiency rules`](../../../aid/templates/review-rubrics/kb.md)
   authors it — `KB-20` contradiction, `KB-21` plan-correctness, `KB-22` contract,
   `KB-23` invariant, `KB-24` gotcha, `KB-25` quality-bar, `KB-26` convention. Seven rules,
   one closed range, no substring.

   **The `AB-` scoping is not belt-and-braces — without it this gate reports failures the M4
   reviewer never found.** An essence `[ESSENCE-GAP]` row must carry a rule ID like every
   other finding row (`reviewer-ledger-schema.md § Rule values`: *"There is no exemption"*),
   and the only rules that fit an omitted fact are these same `KB-22`..`KB-26`. So a
   `Rule`-only count would let one M3 Omission fail the assertiveness verdict too, and the
   triple `Grade | Essence | Assertiveness` would report an act-back failure with no act-back
   finding behind it. The `#` prefixes (`M1-` / `M2-` / `TB-` / `AB-`, declared with the merge
   contract below) are already stable across the merge and already per-mandate, so scoping by
   mandate costs nothing and is what makes the two verdicts independently meaningful.
2. **All quality-contracts present** — the operational-structure presence check (inlined
   as part of `{{ACTBACK_TASK_SPEC}}`) confirms the named first-class sections
   (`## Conventions`, `## Invariants`, `## Gotchas`, `## Contracts`) are present in the
   docs that own them (per the spine-keyed owning-table). An absent required section is
   itself a `KB-22`/`KB-23`/`KB-24`/`KB-25` row in the M4 ledger, so condition 1 already
   catches it; this condition is stated separately because the presence check runs even
   when the M4 reviewer produced no rows at all.

`assertiveness_verdict = PASS` iff both conditions hold, else `FAIL`.

**Why the ≥ 90% STATED-coverage condition is gone.** It read *"at least 90% of plan steps
across all work probes must be tagged STATED"*, sourced from the M4 reviewer's own
STATED/ASSUMED/REACH tagging — and it already carried its own admission of failure: *"if
the reviewer did not record step counts, apply the conservative rule: any open
`[ACTBACK]` row implies the threshold is violated."* That conservative rule is condition 1.
The ratio therefore only ever did something when the reviewer volunteered a denominator
that nothing in the ledger records or checks, which makes it an unfalsifiable claim rather
than a gate. Retired for the same reason as the essence ratio; the conservative rule beside
it is kept.

All FAIL items (plan-correctness, sufficiency, quality) are ordinary `[HIGH] [ACTBACK]`
rows. Any open `[ACTBACK]` row forces grade <= D (because `[HIGH]` rows make grade <= D
in `grade.sh`) — the assertiveness hard gate is realized entirely through the merged rows,
the sibling-keystone mechanism. No separate boolean, no AND to reconcile.

**2e. Delete the transients**

`/aid-deep-review` deletes the mandate scratch ledgers it created — **after** promoting any `G-` keys to
the criteria-gap register, since the register is what outlives the ledger.

This skill deletes only its **own** pre-dispatch transients, which `/aid-deep-review` knows nothing about:
the `closure-check.sh` oracle outputs, the essence probe set, and the act-back task and presence files.
They live under the same directory but are this skill's *inputs*, not review output.

`{{SCOPE}}.md` remains the single source FIX reads, exactly as before.

---

### Step 3: Post-Process and Report

Print: `[Review 3/3] Review complete.`

Resolve the minimum grade:

```bash
bash .cursor/aid/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A
```

Compute:
- `ready = (grade >= minimum_grade)`
- `essence_display = PASS` or `FAIL` (from Step 2c — essence verdict)
- `assertiveness_display = PASS` or `FAIL` (from Step 2d — assertiveness verdict)
- If `ready` and `essence_verdict == PASS` and `assertiveness_verdict == PASS`: `outcome = "Ready"`
- Otherwise: `outcome = "NOT Ready"`

Update `.aid/knowledge/STATE.md` `## Review History` with the new entry. Record the
grade computed by `grade.sh`, not any grade mentioned in the mandate reviewers' prose.

Also record this cycle's grade + review date in the KB run-state frontmatter (the
`kb_grade`/`last_kb_review` scalars, relocated from the old header-blockquote
`**Current Grade:**`/`**Last KB Review:**` lines by work-003-state-schema task-001/004
— surgical frontmatter rewrite, `## Review History` and the rest of the body untouched):

```bash
bash .cursor/aid/scripts/summarize/writeback-state.sh --set kb_grade "{grade}" --set last_kb_review "$(date -u +%Y-%m-%d)"
```

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

| Intent | Gate | `#` scope | Description marker | `Rule` the gate counts | Severity | FAIL condition |
|--------|------|-----------|--------------------|------------------------|----------|----------------|
| Intent 2 -- Essence (M3) | Essence Gate | `TB-` | `[FIDELITY]` (Divergence) | `NAR-05` | `[HIGH]` | Any open `TB-` row with `Rule` = `NAR-05` |
| Intent 2 -- Essence (M3) | Essence Gate | `TB-` | `[ESSENCE-GAP]` (Omission) | _(gate keys on the marker -- criteria gap, § 2c)_ | `[MEDIUM]` | Any open `TB-` row marked `[ESSENCE-GAP]` |
| Intent 1 -- Assertiveness (M4) | Assertiveness Gate | `AB-` | `[ACTBACK]` (all FAIL classes) | `^KB-2[0-6]$` | `[HIGH]` | Any open `AB-` row with a `KB-20`..`KB-26` rule, or a quality-contract absent |

Two things to read off this table. **No row carries a coverage percentage** — both ratios were
retired; see the two "Why the ... ratio is gone" notes in § 2c and § 2d. And **every row is
scoped by `#` prefix**, because a rule ID alone does not say which mandate found the defect:
`NAR-05` and `KB-20`..`KB-26` are legitimately available to the correctness and anatomy
mandates too, so an unscoped count would report a gate failure that its own reviewer never
raised.

```
panel: full  (brownfield-large)
  1. Four mandate reviewers run in parallel (M1..M4), each writing to its own
     scratch ledger. M3 writes [HIGH] [FIDELITY] rows for Divergence FAILs and
     [MEDIUM] [ESSENCE-GAP] rows for load-bearing Omission FAILs (no separate
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
     [HIGH] [FIDELITY] and [MEDIUM] [ESSENCE-GAP] rows to {{SCOPE}}-teachback.md.
     ONE clean-context reviewer handles M4, writing [HIGH] [ACTBACK] rows to
     {{SCOPE}}-actback.md. All three dispatches run in parallel with each other
     (M1-M2 sequential WITHIN dispatch 1 only).
  2. Orchestrator MERGES the 3 scratch ledgers ({{SCOPE}}-content.md +
     {{SCOPE}}-teachback.md + {{SCOPE}}-actback.md) into {{SCOPE}}.md (same stable
     per-mandate IDs and [M1]/[M2]/[FIDELITY] or [ESSENCE-GAP]/[ACTBACK] description
     prefixes as full mode), then DELETES all three transient scratch ledgers. The
     merged {{SCOPE}}.md is structurally identical to the full-mode output -- same
     8-column schema, same mandate ID namespaces.

Both modes:
  3. grade = grade.sh {{SCOPE}}.md    # EXISTING grader, unchanged. Worst-severity
                                      # dominates, counts Status in {Pending,Recurred}.
                                      # Any open [FIDELITY] OR [ACTBACK] row forces
                                      # grade <= D.

  4. READY iff grade >= minimum_grade # Single gate. An open essence OR assertiveness
                                      # gap is a [HIGH] row -> grade <= D -> not Ready.
                                      # No second boolean, no AND/OR to reconcile.

  5. essence_verdict = FAIL iff any open TB- row with Rule == NAR-05, OR
                                any open TB- [ESSENCE-GAP] row, else PASS.
     assertiveness_verdict = FAIL iff any open AB- row with Rule matching ^KB-2[0-6]$,
                                OR any quality-contract absent, else PASS.
     # No coverage ratio in either. Both denominators were runtime claims by an
     # agent with no ledger carrier; the conservative rules beside them are kept.
     # The AB- scoping keeps an M3 Omission (which carries a KB-2x rule of its own)
     # from failing the M4 verdict as well -- see § 2d.

  6. STATE + print report the TRIPLE: "Grade: <g> | Essence: <v> | Assertiveness: <v>"
```

**Why merge rather than keep four ledgers:** FIX (`state-fix.md`) and `grade.sh` are
built around ONE `<scope>.md` per skill invocation. Merging to the single ledger keeps
FIX, `grade.sh`, and the schema unchanged — the panel is an input-side fan-out that
collapses back to the existing single-ledger contract before grading. The collapsed
mode produces the same merged output — `{{SCOPE}}.md` with the same schema and the
same per-mandate ID namespaces — so FIX, `grade.sh`, the essence gate, and the
assertiveness gate are entirely unaware of which panel mode was used.
