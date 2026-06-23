# task-029: M6 act-back mandate wired into f005's panel (state-review 5->6 + reviewer-prompt-actback + [ACTBACK] rubric tag)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-005

**Depends on:** task-027, task-028, task-014 (delivery-001)

**Scope:**
- **Additive edit to f005's panel orchestration (do NOT rewrite it)** in
  `canonical/skills/aid-discover/references/state-review.md` -- the 5->6 mandate edit, reusing f005's
  parallel-dispatch + merged-ledger + `grade.sh` + `{{SCOPE}}`/doc-set seam (task-014, delivery-001)
  **verbatim**:
  - **Step 1** mandate loop gains **M6 (act-back)** -> 6 PARALLEL `aid-reviewer` dispatches (full-panel
    default; same A3 capability-probe degrade-to-sequential). Step 1b appends M6's FOCUS body + the
    `kb-actback-task.sh` (task-027) representative-task spec + the operational-structure presence-check
    output. Step 1d adds the M6 scratch ledger `.aid/.temp/review-pending/discovery-actback.md`.
  - **Step 2** merges the 6th scratch ledger into the single `discovery.md` (M6 rows -> stable `AB-NNN`
    IDs, `[ACTBACK]` description tag), runs the **UNCHANGED** `grade.sh`; evaluates BOTH sibling
    keystones off `discovery.md` (teach-back PASS iff zero open `[TEACHBACK]` rows; act-back PASS iff
    zero open `[ACTBACK]` rows -- **no stored sentinel for either**); deletes all 6 scratch ledgers.
  - **Step 3** exit print + STATE report the **triple** `Grade: <g> | Teach-back: <v> | Act-back: <v>`.
  - Invoke `kb-actback-task.sh` (and reference its siblings) with the full `canonical/aid/scripts/kb/...`
    form + the render-token convention `state-generate.md`/`state-closure.md` use -- do NOT copy
    f005's as-built dropped-`aid/` path bug. Clean-context + contamination blocks preserved (stronger
    for M6, like M4): input = ONLY the KB + the representative-task spec; never the source/project-index.
- **`canonical/skills/aid-discover/references/reviewer-prompt-actback.md` (NEW)** -- the M6 FOCUS body:
  clean-context "given ONLY the KB + the representative task, produce the plan AND flag every
  insufficiency"; the two FAIL limbs (plan-correctness + sufficiency); the four insufficiency classes
  (convention/invariant/gotcha/contract -- matching task-028's owning-table); the binary bar; output
  redirection to its OWN scratch ledger `discovery-actback.md` (7-column ledger schema), NOT STATE.md.
  Add an M6 row to `reviewer-prompt.md`'s thin index.
- **`canonical/aid/templates/kb-authoring/review-rubric.md`** -- add the **`[ACTBACK]`** (HIGH) tag to
  the "Lint output -> severity mapping" table beside f005's `[TEACHBACK]` (L255), using the verbatim
  f013-SPEC row (carrying the inline "any open `[ACTBACK]` row forces grade <= D" clause). Category
  routing + existing rubrics + f005's mandate/calibration sections unchanged.

**Boundary (reuse, don't re-spec):** does NOT alter the 5-mandate bodies, the fan-out machinery,
`grade.sh`, the `{{SCOPE}}` seam, or the `[TEACHBACK]` encoding (all f005/task-014, delivery-001 --
reused verbatim). Does NOT author `kb-actback-task.sh` (task-027) or the doc-model rule (task-028) --
it *invokes/consumes* them. Does NOT build the act-back fixture (delivery-006/f012). `grade.sh` is
**unchanged** (no new grade computation; the keystone is the `[HIGH] [ACTBACK]` rows it already counts).
Because M6 joins the per-mandate dispatch list, f006's brownfield-small collapse folds M6 in
automatically ([SPIKE-A3]) -- no f006 edit here.

**Acceptance Criteria:**
- [ ] `state-review.md` Step 1 fans out **6** parallel `aid-reviewer` dispatches (was 5), adds M6's
  FOCUS + the `kb-actback-task.sh` representative-task spec + presence-check output, and adds the
  `discovery-actback.md` scratch ledger; Step 2 merges the 6th ledger (AB-NNN IDs, `[ACTBACK]` tag) and
  runs the UNCHANGED `grade.sh`; Step 3 reports the triple `Grade | Teach-back | Act-back`.
- [ ] Act-back PASS iff zero open `[ACTBACK]` rows; any open `[ACTBACK]` row forces grade <= D (sibling
  keystone, same mechanism as teach-back; no separate boolean, no AND/OR, no stored sentinel).
- [ ] `reviewer-prompt-actback.md` exists with the clean-context FOCUS body, the two FAIL limbs, the
  four insufficiency classes, and output redirection to `discovery-actback.md` (NOT STATE.md);
  `reviewer-prompt.md`'s thin index gains an M6 row.
- [ ] `review-rubric.md` carries the `[ACTBACK]` (HIGH) row beside `[TEACHBACK]` with the inline
  "forces grade <= D" clause; category routing + existing rubrics unchanged.
- [ ] `kb-actback-task.sh` and its siblings are invoked with the full `canonical/aid/scripts/kb/...`
  path (not f005's dropped-`aid/` bug); clean-context block forbids reading project source for M6.
- [ ] `grade.sh` is byte-unchanged; the four insufficiency classes named in the prompt match task-028's
  owning-table classes and task-027's presence-check headings (single source of truth).
- [ ] All section-6 quality gates pass; canonical edits render to all 5 trees (render-drift green via
  `run_generator.py`; verify net-new `reviewer-prompt-actback.md` reference emits to all 5 trees per
  [SPIKE-A2]).
