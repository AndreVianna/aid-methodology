# task-058: Stop rule 7 turning prose cross-references into loop-back arrows (closes W1-16)

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-058. It is the IMMUTABLE DEFINITION for this task.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

**Authored at the work-level final gate**, 2026-07-30, by owner decision: asked whether to ship
W1-16 disclosed or fix it first, the owner chose **fix it first**. It exists as a task rather than
as a bare gate edit because this delivery's own gate raised a `[MEDIUM]` (Q8) against a product
change that traced to no task, no requirement and no test — writing another one would repeat the
finding while closing it.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`.

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-006

**Depends on:** task-057

**Scope:**

- Change `_scanBodyEdges`'s **rule 7** in `site/scripts/lib/flow-graph/extract-inline.mjs`:212 so a
  declared state name only yields a `loop-back` edge when it is the **target of a loop or return
  phrase**, not merely mentioned. Today the rule emits an edge for *any* non-heading, non-fenced
  body line naming an earlier-ordered state, so `(model+effort from INTAKE Step 4)` becomes an
  arrow from REVIEW to INTAKE on a published chart.
- The rule must be evaluated over the **joined logical block**, not the physical line. This is
  load-bearing and was established by measurement, not assumption: **three of the six genuine
  loop-backs put the verb on the previous line** — `aid-create-document`, `aid-report` and
  `aid-test` all read `... -> loop` / `   to AUTHOR|ANALYZE|RUN ...`. A line-scoped cue test
  deletes 15 real edges. Provenance must still record the **physical line** where the state token
  matched, so deep links stay correct.
- Handle the **second trigger** as well, which W1-16's original analysis did not name: a state name
  colliding with an artifact filename. `aid-design` has a state `DESIGN` and an artifact
  `DESIGN.md`, and `TOKEN_RE` (`/[A-Za-z][A-Za-z0-9-]*/g`) matches `DESIGN` inside `DESIGN.md`, so
  every mention of the file emits an arrow — that chart draws 3 loop-backs of which **0** are real.
  A token immediately followed by a file extension is a filename reference, not a state reference.
  The cue rule alone already suppresses all three `aid-design` cases; the filename guard is added
  because it is a distinct, nameable defect that would resurface the moment someone writes "loop
  back to DESIGN.md".
- **Do not touch `advance.mjs`.** The 74 self-loop `loop-back` edges (64 `engine`, plus the
  synthesized `otherwise` self-loops) come from `advance.mjs`:330, a different code path with
  different logic. They are correct and out of scope.

**Acceptance Criteria:**

> **⚠️ AMENDED 2026-07-30, before implementation was accepted.** The first three criteria below
> were written from the gate reviewer's measurement — "`aid-design` draws 3 loop-backs of which
> **0** are real" — which I adopted without re-deriving. **It is wrong**, and so were my criteria.
> `aid-design/SKILL.md`:79-80 reads `Not clean -> loop` / `   to DESIGN.` — a genuine loop-back, the
> same wrapped-verb shape as `aid-create-document`, `aid-report` and `aid-test`. Rule 7's
> first-match-wins had attributed that real edge to the *wrong line* (`:76`, a `DESIGN.md`
> mention), which is what made it look fabricated.
>
> So `aid-design` is **3 drawn, 1 real-but-mis-sourced**, not 3-drawn-0-real; the corpus has
> **6** fabricated edges plus **1** mis-sourced one, not 7 fabricated; and the correct target is
> **26 → 20**, not 26 → 19. Criteria restated below against measurement. Recording this rather
> than silently re-reading the numbers, because building acceptance criteria on an unverified
> figure is the exact defect this gate has been closing all day — and I did it in the task that
> closes it.

- [ ] Cross-state `loop-back` edges across the 111 sidecars drop from **26 to 20**.
- [ ] Exactly **7 edge-attributions removed and 1 added**, verified by diffing the sidecars against
      `HEAD`: removed `aid-change-document WRITE->PRESENT@87`, `aid-design VERIFY->DESIGN@76`,
      `aid-design PRESENT->DESIGN@88`, `aid-design DONE->DESIGN@107`,
      `aid-research INVESTIGATE->INTAKE@79`, `aid-review REVIEW->INTAKE@132`,
      `aid-review PUBLISH->PRESENT-FINDINGS@193`; added `aid-design VERIFY->DESIGN@80`.
- [ ] The 4 affected charts are exactly `aid-change-document`, `aid-design`, `aid-research`,
      `aid-review`. `aid-design` goes from 3 loop-backs to **1** — the real one, now correctly
      sourced. **The fix must not merely delete arrows; it must recover that edge's provenance.**
- [ ] All genuine edges survive, asserted by class and count: `VERIFY->AUTHOR` ×10,
      `VERIFY->RUN` ×4, `VERIFY->BUILD` ×2, `VERIFY->ANALYZE` ×1, `VERIFY->DESIGN` ×1,
      `VERIFY->INVESTIGATE` ×1, `VERIFY->REVIEW` ×1 — 20 total. A fix that also drops a genuine
      edge fails this task.
- [ ] The **74 self-loop** edges are unchanged in count and provenance (`advance.mjs` untouched).
- [ ] A committed test drives the **real extractor** over fixtures covering both triggers and both
      wrap directions — verb-on-previous-line and target-on-next-line — and would fail if rule 7
      were reverted. It must not re-implement the rule it checks (F6).
- [ ] `gen-skills.mjs` remains **idempotent**: two consecutive runs emit identical bytes.
- [ ] The full site suite passes and the build is clean.
- [ ] Byte-identity, render-drift, count-guard, doc-counts and kb-hygiene all stay green.
- [ ] **The byte-unchanged gate criteria of deliveries 005 and 006 are AMENDED, not silently
      broken.** Both assert the 111 skill pages and sidecars are byte-unchanged; this task changes
      4 charts and their sidecars by design. Each amendment names the 4 charts and the 7 edges and
      states the bound that still holds — no other page or sidecar changes, and the change is
      reproducible by re-running the generator.
- [ ] `W1-16` is removed from `tech-debt.md` per the resolved-debt convention, with the closure in
      the `changelog:` frontmatter, and both work-level gate ledgers updated from `Pending`.
- [ ] All section-6 quality gates pass.
