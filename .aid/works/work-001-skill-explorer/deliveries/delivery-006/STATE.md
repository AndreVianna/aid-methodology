---
delivery_state: Done
gate_tier: Large
gate_grade: "B-"
gate_timestamp: "2026-07-30T20:35:28Z"
ticket_ref: "--"
---

# Delivery State -- delivery-006

> **Delivery:** delivery-006 — unify the two skill sections
> **Work:** work-001-skill-explorer
> **Branch:** aid/work-001-delivery-005 (continued)

---

## Delivery Lifecycle

- **Updated:** 2026-07-30
- **Block Reason:** --
- **Block Artifact:** --
- **Resumed (2026-07-30, Claude Code):** the uncommitted wave-1/wave-2 work was verified,
  reviewed and committed; tasks 056 and 057 executed. **All four tasks are `Done`.** Commits on
  `aid/work-001-delivery-005`, in order: `b86aae3d` (scaffolding) → `129eba1b` (055 prose) →
  `8e02d174` (054 derivation + guard) → `8eff0803` (055 correction) → `d2f0440c` (056 links) →
  `923431a4` (057 hollowing) → `21c0f0a3` + `52e65e90` (an out-of-delivery `writeback-state.sh`
  fix, and its propagation to `canonical/` — traceability recorded at **Q8** below, and
  guarded by a test added at the work-level final gate) → `873677e6` (KI-009 closure + rollup) → the
  head-gate fixture fix → `23017900` (cycle 1's five `[HIGH]`s) → `cb1b84f1` + `65c677b1`
  (cycle 1's MEDIUM/LOW/MINOR tail) → `74b46da7` (cycle 2: red CI + the count I introduced
  while fixing counts) → `a6fad75d` (**root cause 1** — the guard was rooted at `site/`) →
  `6c5de74a` (**root cause 2** — the superseded-freeze class) → `2fd7feeb` (**root cause 3**
  — wrong-layer edits; plus KB coverage and KI persistence) → `24adf603` (cycle 3: two
  falsified records reverted) → the LOW/MINOR tail → the render propagation → `3d58d967`
  (the FIX contract, F1–F6) → `a4270dd2` (cycle 4, worked as classes).
  The chain is listed in full because an omitted commit is how this row went stale twice.
- **Commit order note.** 055's prose landed **before** 054, inverting the BLUEPRINT's declared
  dependency. Deliberate: 054 adds a guard asserting the pages 055 corrects, so landing 054 first
  leaves a commit whose own new test is red. The stated dependency is about where 055's *numbers*
  came from (054's derivation), not about commit order. This is **not** a claim that the order was
  free of consequences — the 85-for-111 sentence is exactly what a prose task landing ahead of its
  guard allows, and it was caught at review rather than by the build.
- Per-task quick-checks found **2 CRITICAL and 4 HIGH**, all fixed on the spot.
- **Delivery gate (Large tier), five cycles so far.** Cycle 1: 30 findings, **E+**. Cycle 2:
  23 Fixed / **7 Recurred** / 13 new, **D+** — its finding was that fixes addressed each row's
  Description and skipped the sibling sites its Evidence enumerated. Cycle 3: 26 Fixed / 7
  Recurred / 29 Pending, and it caught two fixes that made things WORSE — a historical
  comparative in `pipeline-contracts.md` corrected into a falsehood, and a dated audit row in
  `test-landscape.md` hand-edited (the guard had already skipped that line by shape, so the
  edit was gratuitous). Both reverted. Ledger:
  `.aid/.temp/review-pending/execute-delivery-006.md`.
- **Root causes, addressed after cycle 2 rather than patching further:** (1) the count guard
  was rooted at `site/`, leaving most of the repo unguardable — 55 wrong counts in 15 files;
  now a repo-wide guard at `tests/canonical/check-skill-counts.mjs`, 204 claims clean.
  (2) the superseded-§7-freeze class existed in 13 files, not the one a reviewer named.
  (3) wrong-layer edits: detection existed and worked, but the rendered file did not say it
  was rendered — `writeback-state.sh` now carries a banner into all 8 generated copies.
- **Browser verification — PASS (2026-07-30, `astro preview` + Playwright, on-demand not CI).**
  Static tests cannot see any of this, and work-017 shipped four broken surfaces past an A+ gate,
  so every reader-facing change this delivery made was driven in a real browser:
  - `/reference/skills/` — title and H1 `Shortcut engine`; `:::tip` renders as a real
    `starlight-aside--tip` with **no literal `:::` leaking**; narrative present (INTAKE →
    APPROVAL-HALT); **0** per-skill `h3[id^=aid-]`; no family table; **no KI-009 signature**
    (`= 0` / `typed forms` both absent); links to `/skills/`; sidebar entry reads
    `Shortcut engine`.
  - `/guides/pipeline/` — **7** anchors to `/skills/`, all rendering `All skills`; **0** stale
    `/reference/skills` links in `<main>`; `Skills reference` absent from the whole page; and all
    **13** in-content link targets fetched **200** (no 404 introduced).
  - `/skills/` — 111 skill cards; the derived note renders and its claim is **verified true in
    the DOM**: `aid-triage` really is under the `Support` H2 on this page while the note says
    Support-here / Definition-in-the-roster. No `terse family` or `frozen` text anywhere.
  - `/` — both sites state `111 skills` = `17 curated` + `94-row shortcut catalog`
    (= `64 verb-first` + `30 hand-authored repurpose`). Arithmetic checked: 17+94=111, 64+30=94.
    No stale `92 skills` / `14 classic` / `76 verb-first` / `19 classic`.
  - `/reference/overview/` — the `Skills` row points at `/skills/` and says which section it is
    in; the new `Shortcut engine` row points at `/reference/skills/` and names the sequence.
  - `/skills/aid-execute/` — **feature-006 still live**: mermaid renders, 6 `aidNode`s all
    decorated (`role=button`, `tabindex=0`, `aria-expanded=false`, `aria-controls=aid-node-panel`,
    non-empty `aria-label`); clicking a node **opens the panel** (visible, `aria-expanded` → true)
    with the fragment `<pre>` and a GitHub source link.
  - Console: the only two errors were CORS failures from the reviewer's own `fetch()` probe
    against a `github.com` URL — not page defects. No page-originated errors.
- Still to do: clear the gate to A+ (cycle 4 fixes applied; cycle 5 not yet dispatched),
  work-level gate, PR.
- **KI-022 (ELK layout) — remains DEFERRED**, per its own entry ("owner deferred the fix"). Not
  pulled into this delivery; carried forward as a known-open item and disclosed in the PR.

---

## Delivery Gate

- **Issue List:** `.aid/.temp/review-pending/execute-delivery-006.md` — 85 rows across five
  cycles. Grades: E+ → D+ → D → not-A+ → not-A+ → **B- (meets bar)**.
- **Final tally:** 75 Fixed, 10 Pending — 1 CRITICAL, 11 HIGH, 28 MEDIUM, 29 LOW and 6 MINOR
  closed; **zero CRITICAL/HIGH/MEDIUM survive**. The 10 survivors are 8 LOW + 2 MINOR (rows 62,
  69, 78–85), deferred to an end-of-work cleanup batch by owner instruction alongside stale
  `file:line` citations.
- **Why the bar moved.** Cycles 3–5 each closed ~12 findings and opened ~12; the ledger grew
  30 → 43 → 62 → 73 → 85 with no decline in the new-finding rate, so A+ ("zero issues at ANY
  severity") was not a bar being approached on a largely-prose delivery. The circuit breaker in
  `state-fix.md` fired at cycle 5, the owner lowered `minimum_grade` to B- globally, and the
  rationale is recorded at `.aid/settings.yml`:9-22. B- keeps CRITICAL/HIGH/MEDIUM fully
  blocking — nothing that misinforms a reader, breaks a build, or states a false fact was waived.
- **Verification at close:** 2765 site vitest; `check-skill-counts.mjs` 204 claims / 0
  disagreements; `test-dogfood-byte-identity.sh` 711/0; `test-doc-counts.sh` 31/0;
  `run_generator` + `git diff --exit-code -- profiles/` clean (render-parity); KB INDEX
  regeneration clean (kb-hygiene).
- **Marked from the artifact, not from intent.** The nine MEDIUM closures were confirmed by a
  separate pass that re-read each row's Evidence site before any Status cell changed (F5) —
  the discipline added after three cycles of `Recurred` rows that had been marked `Fixed` from
  the edit I meant to make rather than the bytes on disk.

---

## Cross-phase Q&A

### Q1 — this delivery was never planned by `aid-plan`

- **Category:** Process
- **Impact:** Medium
- **State:** Answered
- **Context:** work-level Q4 closes with "**Still to do:** this delivery is **not yet planned**.
  `PLAN.md` is an `aid-plan` artifact and is not edited here; the new delivery needs its own
  BLUEPRINT and task breakdown before execution." The owner then asked for the remaining items to
  be finished directly.
- **Answer:** The BLUEPRINT and task breakdown were authored at execution time, matching the
  practice used for deliveries 001–005 whose task tables the detail phase also left unfilled.
  `PLAN.md` is **not** edited — it remains an `aid-plan` artifact, and this delivery is recorded
  here instead. Every quantity in the BLUEPRINT was re-derived before planning rather than copied
  from the Q4 record, and the three that Q4 asserted are confirmed in the Scope section.
- **Applied to:** `deliveries/delivery-006/BLUEPRINT.md`.

### Q2 — no new delivery branch

- **Category:** Process
- **Impact:** Low
- **State:** Answered
- **Context:** Deliveries 001–005 each took a branch, `aid/work-001-delivery-NNN`.
- **Answer:** Continue on `aid/work-001-delivery-005`. That branch is now pushed and tracking
  upstream, the five delivery branches are linear, and the whole work is about to become one pull
  request — a sixth branch would fragment that history for no review benefit. Recorded so the
  deviation is deliberate rather than an oversight.
- **Applied to:** this delivery's commits.

### Q3 — KI-003 is stale comments, not stale output

- **Category:** Requirements (finding refines a known issue)
- **Impact:** Low
- **State:** Answered
- **Context:** KI-003 and Q4 both describe `reference/skills.md`'s header as claiming 94
  directories / 16 classic / 76 shortcuts against a real 111 / 19 / 64.
- **Answer:** Measured before acting: the **generated page is correct** — line 9 renders "111
  skill directories", "19 classic pipeline skills" and "64 engine-driven direct-entry shortcut
  skills", because `gen-reference.mjs` derives them at build time (line 398). The stale triple
  survives only in that file's **comments**, at lines 5–6, 147 and 390. So KI-003 is narrower than
  recorded: a comment defect, with no reader-visible symptom. Corrected in task-054, and the KI
  entry is updated to say so rather than leaving a future reader hunting for a rendering bug.
- **Applied to:** task-054; `known-issues.md` KI-003.

### Q4 — resume handoff to Claude Code (2026-07-30)

- **Category:** Process
- **Impact:** Low
- **State:** Answered
- **Context:** Owner pauses Cursor session; continues in Claude Code.
- **Answer:** Resume at task-054 (commit uncommitted wave-1/2 work, review, mark Done), then
  task-055 Done, task-056, task-057, delivery-006 gate, KI-022, browser checks, PR. Read
  `deliveries/delivery-006/BLUEPRINT.md` and this STATE.md first. PowerShell: use `-NoProfile`.
  Git: Windows Git Bash only — no WSL (KI-017).
- **Applied to:** session handoff.

### Q5 — hollowing out the roster falsifies two claims the BLUEPRINT did not count

- **Category:** Requirements (measured scope discovery)
- **Impact:** Medium
- **State:** Answered
- **Context:** The BLUEPRINT counted **8** hand-authored inbound links into `/reference/skills/`
  (7 in `guides/pipeline.mdx`, 1 in `reference/overview.md`). A grep before executing task-056
  found a **9th** occurrence, at `site/src/content/docs/skills/index.md`:13 — and that file is
  **generated**, so the occurrence is really in `site/scripts/skills/render-index.mjs`:139–146.
  It is not an inbound "read the roster here" link but a **divergence note about** the reference
  page: it calls it a "terse family **summary**", says it "groups `aid-triage`, `aid-deploy`, and
  `aid-monitor` under *Definition*", and explains the divergence as existing "because the older
  generator is frozen". Separately, `astro.config.mjs`:158 labels the page `Skills` inside the
  **Reference** group.
- **Answer:** The BLUEPRINT's count of 8 is **correct as a count of inbound links** and task-056
  is unchanged — repointing the note at `/skills/` would make it link to the page it is written
  on. But every clause of that note dies when task-057 sheds the roster: there is no competing
  grouping left to diverge from, and Q4 unfroze the generator the note calls frozen. Leaving it
  would ship a generated page making three false claims — the exact KI-005 class this delivery
  exists to close — so retiring/rewriting the note, updating its **AC-7** assertions in
  `skills-render-index.test.mjs`, and relabelling the sidebar entry are added to **task-057** as
  consequential edits. Recorded here because it is a scope addition discovered by measurement,
  not carried by the BLUEPRINT.
- **Applied to:** `deliveries/delivery-006/tasks/task-057/DETAIL.md` § Consequential edits.
- **CORRECTED at the delivery gate (2026-07-30).** The answer above says "there is no competing
  grouping left to diverge from". **That is false, and it caused a real regression.** The competing
  grouping was never the reference *page* — it is the curated roster itself, which still exists,
  still files `aid-triage` under Definition where `/skills/` files it under Support, and is what
  `docs/aid-methodology.md`'s inventory table publishes. Acting on the false premise deleted a
  **true** reader-facing disclosure and added assertions forbidding its restoration.
  Fixed in gate cycle 1: the note is now **derived** — it compares each skill's group against
  `curated-roster.mjs` and names whatever actually disagrees — and AC-7 checks the disclosure is
  complete and invents no divergence, instead of banning the words "authoritative"/"disagree".
  The derivation also shows the note's ORIGINAL hard-coded list was over-stated: it named three
  skills, and only `aid-triage` diverges (`aid-deploy`/`aid-monitor` agree on both sides).
  Only one clause of the old note was genuinely falsified by task-057 — "the older generator is
  frozen" — and that is the one thing AC-7 still forbids.

### Q6 — tasks 054–057 had no `DETAIL.md`

- **Category:** Process
- **Impact:** Low
- **State:** Answered
- **Context:** The Cursor session authored this delivery's BLUEPRINT and all four per-task
  `STATE.md` files, but no `task-NNN/DETAIL.md`. `aid-execute` treats `DETAIL.md` as the task's
  PRIMARY INPUT and its absence as a STOP.
- **Answer:** The four `DETAIL.md` files were authored from the BLUEPRINT at resume time, in the
  6-section task-template shape, matching Q1's execution-time-authoring practice. This
  **materialises** scope the BLUEPRINT already carries — Type, Source, dependency order, the
  measured Scope quantities and the Gate Criteria decomposed per task — rather than introducing
  any. The one genuine addition is task-057's § Consequential edits, which is Q5 above and is
  labelled as such in that file.
- **Applied to:** `deliveries/delivery-006/tasks/task-05{4,5,6,7}/DETAIL.md`.

### Q7 — the BLUEPRINT's own triple did not sum, and that is what shipped

- **Category:** Requirements (defect in this delivery's own scope statement)
- **Impact:** Medium
- **State:** Answered
- **Context:** The BLUEPRINT opened with "**The triple is 111 / 21 / 64**", re-derived before
  planning and presented as the measured fact the delivery would correct every page to. It does
  not sum: 21 counts four skills that are ALSO catalog rows (`aid-deploy`, `aid-monitor`,
  `aid-query-kb`, and the `aid-ask` alias), so pairing it with a catalog-derived count
  double-counts them. task-055 then wrote that framing onto the home page as "111 skills — 19
  classic + `/aid-triage` + `/aid-ask` + 64 verb-first", which totals **85** for a 111-skill
  corpus. The gate caught it; the BLUEPRINT did not, because a scope statement is not tested.
- **Answer:** The decomposition that sums is **111 = 17 curated + 94 catalog** (itself 64
  verb-first + 30 `repurpose`), where 17 is the curated skills that are NOT catalog rows — which
  is what `concepts/methodology.md`, `reference/glossary.md` and the KB already stated. The
  BLUEPRINT is amended with the superseded triple struck rather than deleted, `curatedOnly` joins
  `skill-counts.mjs`, and the identity `curatedOnly + catalogRows === directories` is asserted so
  a future roster change cannot quietly break it again.
- **Why it is recorded here rather than only fixed:** four gate cycles named this row, and three
  times the fix landed on one of its three remedies. Recording the Q&A entry was the third, and
  its absence is the clearest single example of the pattern the FIX contract's **F1** now
  addresses — the Description's site gets fixed, the Evidence's siblings do not.
- **Applied to:** `deliveries/delivery-006/BLUEPRINT.md` (§ Scope and Gate Criterion 2);
  `tasks/task-055/DETAIL.md` (AC amendment); `site/scripts/skills/skill-counts.mjs`;
  `site/src/content/docs/index.mdx`; `reference/overview.md`.

### Q8 — a product-code change with no task, no requirement and no test

- **Raised by:** the work-level final gate, 2026-07-30 (its row 12).
- **Question:** commits `21c0f0a3` + `52e65e90` changed shipped product code —
  `mode_append_issue`'s guard in `canonical/aid/scripts/execute/writeback-state.sh` — inside a
  delivery about the website. There is no task-NNN, no `DETAIL.md`, no acceptance criterion and no
  test. On what authority did it land, and what stops it being reverted?
- **Answer, in three parts.**
  1. **Why it was in scope at all.** It is not website work; it is *gate* work. The delivery gate
     itself calls `writeback-state.sh --append-issue`, exporting `AID_WORK_DIR` rather than
     `AID_STATE_FILE`. The old guard required `AID_STATE_FILE` to be set, so that caller skipped
     the work-dir branch and then failed against a `.aid/works/work` lock directory that does not
     exist. The delivery could not record its own findings until this was fixed. That is a
     legitimate reason to fix it here and an illegitimate reason to leave it untraced.
  2. **It was also authored at the wrong layer first** — `21c0f0a3` edited only the `.claude/`
     dogfood render; `52e65e90` back-propagated to `canonical/`. That is a recurrence of this
     delivery's cycle-1 CRITICAL class, self-corrected on-branch. All nine copies are now
     byte-identical and all five manifests sha-consistent. It is the concrete case that motivated
     the provenance banner now carried at the top of the canonical file.
  3. **The regression is now guarded.** `tests/canonical/test-writeback-state.sh` **Unit 24** was
     added at the final gate. The gap was real and total: the suite exports
     `AID_DELIVERY_ISSUES_DIR` file-wide, so no other unit can reach that branch, and
     `AID_WORK_DIR` appeared nowhere in the file — a grep under `tests/` hit only
     `test-write-control-signal.sh` and `coverage-baseline.tsv`. Unit 24 clears those exports with
     `env -u` and asserts the issues file lands under `AID_WORK_DIR`. Its discriminating power was
     **measured** by re-introducing the pre-fix condition on a scratch copy (fixed: exit 0, file
     lands; broken: exit 1, no file), and the measurement is recorded in the unit's own comment,
     including which of its four assertions does *not* discriminate.
- **Why it is recorded rather than only fixed:** a behavioural change to shipped code that traces
  to nothing is indistinguishable from an accident when read a year later, and the accident it most
  resembles — an unrelated edit swept into a delivery — is one this work already committed once
  (delivery-001's `git add -A` scope leak). The fix was right; its invisibility was the defect.
- **Applied to:** `tests/canonical/test-writeback-state.sh` (Unit 24, 4 assertions);
  this Q&A entry; the commit-list annotation above.

---

_Recorded as each task closes._

---

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| 054 | One shared skill-count derivation + drift guard; KI-003 comments | IMPLEMENT | 1 | Done | 1 CRITICAL + 2 HIGH, all fixed | -- | Commit not green in isolation; 4 more hand-counts found (2 in reader-facing output). Guard rewritten to match count SHAPES. `8e02d174` |
| 055 | Correct stale roster prose (index.mdx E-1, overview.md) | IMPLEMENT | 2 | Done | 1 CRITICAL + 2 HIGH, all fixed | -- | First correction didn't SUM (85 for a 111 corpus); restated as 17 curated + 94 catalog. 2 unguarded pages found. `129eba1b` + `8eff0803` |
| 056 | Repoint 8 inbound links to /skills/ | IMPLEMENT | 2 | Done | clean | -- | 7 LinkCards + overview row; verified in `dist/`. `d2f0440c` |
| 057 | Hollow out reference/skills.md (closes KI-009) | IMPLEMENT | 3 | Done | clean at CRITICAL/HIGH; 1 MEDIUM fixed pre-gate | -- | Narrative kept, roster + family table shed; Q5 consequential edits done. `923431a4` |
