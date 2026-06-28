# Work State -- work-001-aid-interview-improvements

[!NOTE]
This is the WORK-LEVEL STATE.md template. It is divided into two zones:
  AUTHORED (single-writer) -- Pipeline State, Triage, Escalation Carry, Interview State, Lifecycle History,
    Deploy State.
  DERIVED (read-only, assembled at read time) -- Features State, Plan/Deliveries, Tasks State,
    Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches.
The DERIVED sections are NEVER written directly; they are union views over the per-delivery and
per-task STATE.md files. Agents that write state must target the per-unit STATE.md files instead.

<!-- SD-2 STATE ADVANCEMENT ORDERING (authoritative source; schemas.md inline copy is downstream)

Ordered from most-advanced to least-advanced:
  1. Done           -- task completed and accepted; all subtasks resolved
  2. Canceled       -- resolved terminal (explicitly abandoned); ranks just below Done
  3. In Review      -- work submitted; awaiting reviewer decision
  4. In Progress    -- actively being executed on its delivery branch
  5. Blocked        -- attempted but impeded; recoverable-in-place; more actionable than Failed
  6. Failed         -- completed attempt rejected; a parallel branch may have superseded
  7. Pending        -- not yet started

Rationale: the dashboard "most-advanced wins" reconcile answers "how far has this work
gotten across all worktree branches." Done/Canceled are terminal-resolved and rank highest.
In Review outranks In Progress (review is a later pipeline stage). Blocked outranks Failed
because a blocked task is recoverable-in-place and signals "needs attention now," whereas a
failed task represents a completed-but-rejected attempt that a parallel branch may have already
superseded -- surfacing "blocked" is the more actionable signal. Both Blocked and Failed rank
above Pending because they represent work that was attempted and surfaced information (more
informative than "not started").

Closed enum VALUES (unchanged): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled

This ordering is encoded ONCE here. Both reader twins (Python + Node) reference schemas.md for
the ordered list at runtime; schemas.md carries an inline copy derived from this source.
-->

> **State:** Interview Complete | Specifying | Planning | Detailing | Executing | Deployed
> **Phase:** Interview | Specify | Plan | Detail | Execute | Deploy
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill {phase} --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** {YYYY-MM-DD}
> **User Approved:** yes | no

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, per-task SPEC.md) keep their
inline `## Change Log` sections -- that is content history (what changed in the document),
distinct from process state (where are we in the workflow). Both are useful; they live in
different places.

---

## Pipeline State

<!-- AUTHORED -- written ONLY by `writeback-state.sh --pipeline ...` at every phase/state
     transition the pipeline performs. Never hand-edited. All values are closed enums so a
     deterministic reader needs no inference. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
> Active Skill enum: aid-{skill} | none

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-28T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

---

## Triage

<!-- AUTHORED -- populated by `aid-interview` TRIAGE state for lite-path works.
     Left empty for full-path works (aid-interview runs the full interview flow instead). -->

- **Path:** full
- **Decision rationale:** description "implement aid-interview-improvements.md" -> multi-thread methodology redesign of the aid-interview skill (3 coupled threads + debt side-tasks), no confident lite recipe match -> full

---

## Escalation Carry

<!-- AUTHORED -- written by `aid-interview` lite to full escalation (Steps 3-9 of
     `lite-to-full-escalation.md`). Present only when a work started on the lite path
     and was escalated to full. The CONTINUE state reads this section to avoid re-asking
     questions already answered during the lite-path session. See
     `references/state-continue.md # Escalation Carry`. -->

- **Escalated from:** {state name} (Sub-path: {sub-path value})
- **Escalated at:** {YYYY-MM-DDTHH:MM:SSZ}
- **Escalation rationale:** {one sentence}

### Captured Slot Values

- **{slot-name}:** {slot-value}
- (no slots captured -- escalation before CONDENSED-INTAKE)

### Artifacts at Escalation

- **SPEC.md:** present | absent -- {notes on content available for seeding}
- **tasks/:** {N} task files present | absent

---

## Interview State

<!-- AUTHORED -- updated by `aid-interview` as each section is completed. -->

**State:** Approved  **Grade:** Pending  (User-approved 2026-06-27)

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-06-27 |
| 2 | Problem Statement | Complete | 2026-06-27 |
| 3 | Users & Stakeholders | Complete | 2026-06-27 |
| 4 | Scope | Complete | 2026-06-27 |
| 5 | Functional Requirements | Complete | 2026-06-27 |
| 6 | Non-Functional Requirements | Complete | 2026-06-27 |
| 7 | Constraints | Complete | 2026-06-27 |
| 8 | Assumptions & Dependencies | Complete | 2026-06-27 |
| 9 | Acceptance Criteria | Complete | 2026-06-27 |
| 10 | Priority | Complete | 2026-06-27 |

### Review History

| # | Date | Grade | Stage | Notes |
|---|------|-------|-------|-------|
| 1 | 2026-06-27 | — | Feature Decomposition | 7 features created |
| 2 | 2026-06-27 | C → resolved | Cross-Reference | 4 MEDIUM + 1 MINOR resolved into REQUIREMENTS + feature-005/006 SPECs |
| 3 | 2026-06-27 | C+ → A+ | Cross-Reference (re-validation, A+ gate) | independent re-verify caught a residual feature-005 US3 contradiction my reframe missed; fixed + re-verified → genuinely A+ |

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-27 | Work created | -- | Initial scaffold by aid-interview (FIRST-RUN) |
| 2026-06-27 | Plan complete (3 specified features) | A+ | delivery-001 (spike/feature-001) + delivery-002 (debt/feature-007); feature-006 deferred (hard-gated after 002/003/004). A+ gate: 2 MEDIUM (priority + M1 misframe) fixed → TOTAL 0. |
| 2026-06-27 | Detail complete (8 tasks, 2 deliveries) | A+ | d001: task-001/002 (parallel surveys) → task-003 synthesis. d002: task-004 H1[TEST], task-005 M3[DOCUMENT], task-006 M4[IMPLEMENT] → task-007 M4[TEST], task-008 M1[DOCUMENT]. Exec graphs + wave-maps in PLAN.md. A+ gate: 7 findings (2 HIGH incl. wrong M3 path + dropped tech-debt row; 2 MEDIUM M4 widths/caveat; 3 lower) fixed → TOTAL 0. |
| 2026-06-27 | Execute delivery-001 (spike) done + A+ delivery gate | A+ | task-001/002 (web-capable executors, parallel) → task-003 synthesis. findings.md (551 lines, 8 families surveyed + grill-me MIT comparative, all 9 RQs justified+actionable, Rec A seed-set + Rec B conversation design downstream-consumable, A-2 `forward-authored` gap + D-5 note). Gate TOTAL 0; faithfulness verified vs disk. Fixed feature-001 D-1 wording (forward-authored not-yet-on-master). |
| 2026-06-27 | Execute delivery-002 (infra debt) done + A+ delivery gate (×2) | A+ | 6 tasks: H1 lockstep test (task-004), M3 repo-structure refresh (task-005), M4 T4 multi-viewport IMPLEMENT+TEST (task-006/007, Playwright-render-proven), M1 deferral (task-008), R1 aid-researcher web tools (task-009, added mid-execute per owner). Full canonical suite 83/83 green (HOME-pinned). Owner design decisions D1/D2/D3 captured (first-question + engine-not-form + aid-describe/aid-define split). |
| 2026-06-27 | Specify spike-dependent features 002-005 | A+ (each) | From findings.md + D1/D2/D3: feature-003 seed model (forward-authored marker, greenfield-mode gate, layered coherence) → feature-002 engine (1 fixed opener + 5-step adaptive selector, calibration, NFR-7 envelope) → feature-004 guided-triage (consumes engine, resolves the 002/004 opener seam) → feature-005 conformance (extract-and-diff, KB-DELTA carve). Each A+ (TOTAL 0) after 1-2 gate cycles. feature-006 rename spec SUPERSEDED by D3 (re-spec to split, deferred after content). |
| 2026-06-27 | Re-specify feature-006: rename → SPLIT (D3) | A+ | aid-interview → aid-describe + aid-define; 20-ref state partition, inter-skill pause-resume seam (HIGH catch: COMPLETION already PAUSEs, not a chain), skill count +1 (13→14), propagation machinery carried fwd, aid-interviewer guard, sequenced after content. 2 gate cycles → TOTAL 0. **ALL features 001-007 now spec-complete at A+; ready for /aid-plan re-plan.** |
| 2026-06-27 | Re-plan (pass 2): added deliveries 003-006 | A+ | On top of executed delivery-001/002: d003 Engine+Triage (002+004), d004 Greenfield Seed (003), d005 Conformance (005), d006 Split (006). Linear chain d003→d004→d005→d006 (gate MEDIUM catch: d005×d006 share aid-discover/state-generate.md → added d006→d005 sequencing edge). All 4 delivery folders at Pending-Spec; Deferred cleared. **NEXT: /aid-detail (delivery-003 first).** |
| 2026-06-27 | Detail deliveries 003-006 (A+ each) | A+ | 31 new tasks (task-010..040) across 4 deliveries: d003 = 010-018 (engine refs → driver → wiring → triage → de-dup → render → verify); d004 = 019-027 (marker 4-file + greenfield gate + coherence + seed-state → render → verify); d005 = 028-035 (output_root + KB-DELTA carve + diff/classifier + reconcile + signpost[owner-added task-035] → render → 2 TEST); d006 = 036-040 (inventory → carve+seam → sweep+count → render+prune → verify). Exec graphs + wave-maps in PLAN.md; shared-file sequencing honored throughout. Gates caught real defects (d005 agent-misattribution traced to feature-005 source; d006 stray PLAN paragraph). **ALL 40 tasks across 6 deliveries detailed; work is execution-ready. NEXT: /aid-execute (delivery-003 first).** |
| 2026-06-27 | Execute delivery-003 (engine+triage) + A+ gate | A+ | 9 tasks (010-018): 4 engine reference docs (advisor-stance/move-playbook/calibration/elicitation-engine) authored + wired into the aid-interview spine in place (SKILL.md + interview-loop/strategies + state-continue/triage); engine-driven guided triage (5-signal gap inventory + Opener: de-dup) → full render to 5 profiles + .claude mirror (DBI, idempotent, generator self-tests pass) → verification (ALL 83 canonical suites GREEN + Astro build; brownfield byte-untouched; dogfood AC-3/AC-4/engine-not-form/triage PASS). Gate TOTAL 0; 2 observations adjudicated Accepted. |
| 2026-06-28 | Merged origin/master (23 commits) into branch | -- | work-002 dashboard-export + housekeep + dependabot + summarize changes + the new test-kb-export suite. Only the 5 emission-manifest.jsonl conflicted → resolved by regenerating from merged canonical; test-visual-fidelity.sh auto-merged (master PW-fix + my VF cases). Merge 2cc674b7; post-merge run-all ALL 84 GREEN. Branch caught up (ahead 14 / behind 0). |
| 2026-06-28 | delivery-003 hardening (task-041, web-validation) + A+ re-gate | A+ | After an architect intent-review + a WEB best-practice validation (web-grounded; surfaced G1 anchoring / G2 read-back / G3 verbatim gaps), added task-041: calibration-GATED open-first anti-anchoring rule (NFR-7 NOT weakened — order/framing only, both Suggested+Why retained) + re-confirmable assumptions + restate-not-replace + whole-picture read-back (Invariant 8 + state-completion hook) + preserve-verbatim-wording (Move 2), across 5 engine docs → render (DBI, idempotent) → re-gate TOTAL 0. Brownfield green (test-install IN11d flaked once under run-all but passes 194/0 standalone — timing flake, unrelated to engine prose). |
| 2026-06-28 | Execute delivery-004 (greenfield seed) + A+ gate | A+ | 9 tasks (019-027): the `source: forward-authored` marker (kb-freshness-check.sh folds to `current` + schema enum row + lint/index pass-through + a 38-assertion test suite that PROVES the short-circuit via a hand-authored control reading `suspect`) · the greenfield-mode review gate (document-expectations.md `## Greenfield Mode` flag-not-fork + reviewer-brief.md `{{GREENFIELD_BLOCK}}` + state-review.md panel-exclusion two-case carve [discovery-skip retained / seed-review full-panel added per NFR-3]) · the layered coherence-check.md (example-probe + structural cross-check, HUMAN GATE, zero-Requirement-orphan sufficiency) · the new `state-describe-seed.md` seed-authoring state (5-element model authored by CONSUMING the delivery-003 engine's 3-param contract — not forked; domain-adaptive; writes `.aid/knowledge/` forward-authored) + SKILL.md State-GS wiring → render (DBI, idempotent, 284/profile) → verification (ALL 85 canonical suites GREEN + Astro build; brownfield byte-untouched). Gate caught 1 MINOR (stale should_check comment) → Fixed → TOTAL 0. **NEXT: /aid-execute delivery-005 (conformance).** |

---

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy` at each delivery deploy (single writer; one row
     per delivery). Never derived from child files; aid-deploy is the sole author. Future work
     may migrate this to a per-delivery hierarchy view, but until then it is AUTHORED here.
     One row per delivery from /aid-deploy. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The sections below are assembled at READ TIME from per-delivery and per-task STATE.md files.
     They are NEVER written directly. Agents MUST target the per-unit STATE.md files instead.
     Dashboard readers union the child contributions; no agent writes to these sections.
     ============================================================ -->

## Features State

<!-- DERIVED -- read-only view assembled from features/{feature}/SPEC.md progress.
     Never written here; feature progress is tracked via /aid-specify per-feature.
     One row per feature. Tracks /aid-specify progress per feature. -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 1 | feature-001-elicitation-research-spike | Ready | A+ | 0 | Spike plan specified; gates 002–005 |
| 2 | feature-002-seasoned-analyst-engine | Ready | A+ | 0 | Engine: 1 fixed opener + deterministic 5-step next-move selector (stop→gap→move→calibrate→envelope), calibration read+ask (AC-4/D1 reconciled), expert-advisor stance, NFR-7 envelope contract, 3-param consumption contract. 2 cycles (MINOR locator); 002/004 opener seam → feature-004. |
| 3 | feature-003-greenfield-seed-authoring | Ready | A+ | 0 | Seed-content model (5 elements + forward-authored marker + schema/lint/index/freshness), greenfield-mode review gate, layered coherence check, sufficiency bar. 2 gate cycles (C→A+); forks resolved (flag-not-fork, TBD-versions, layered coherence, fold-to-current freshness). |
| 4 | feature-004-guided-triage | Ready | A+ | 0 | Analyst-driven triage: thin consumer of the f002 engine (TRIAGE-specific gap inventory), engine-driven draw-out replaces free-form Step 1, routing rule + recipe tooling reused unchanged, KB-context-aware (full/seed/no-KB), brownfield intact. RESOLVED the 002/004 opener seam (## Triage **Opener:** de-dup). 2 gate cycles. |
| 5 | feature-005-build-time-conformance | Ready | A+ | 0 | NEW code→design conformance check: extract-and-diff (output_root-parameterized shadow extraction + concern-keyed diff at seed altitude + classifier), aid-housekeep KB-DELTA conformance lane carving forward-authored docs OUT of the doc←code lane (NFR-5), human-gated. 2 cycles (HIGH shadow-extract redirect made concrete-by-construction). |
| 6 | feature-006-rename-aid-define | Ready | A+ | 0 | RE-SPEC'd rename→SPLIT (D3): aid-interview → aid-describe + aid-define. 20-ref state partition; inter-skill seam = redirect COMPLETION's existing pause-resume signpost to /aid-define (it already PAUSEs, not a chain); skill count +1 (13→14, incl. spelled-out); DBI/render/orphan-prune/manifests×2/docs×2 carried fwd; aid-interviewer guard; sequenced after 002/003/004. 2 gate cycles (HIGH seam-mischaracterization). |
| 7 | feature-007-infra-debt-paydown | Ready | A+ | 0 | H1/M3/M4/M1 sub-specs; 3 gate cycles (prose→ASCII-tree) → A+ |

## Plan / Deliveries

<!-- DERIVED -- read-only view assembled from delivery-NNN/STATE.md lifecycle fields.
     Never written here; the delivery-level STATE.md is the authoritative source.
     One row per delivery from PLAN.md. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files
     (delivery-NNN/tasks/task-NNN/STATE.md). Never written directly into this file.
     The state reader unions all delivery branches using the SD-2 ordering (most-advanced wins).
     One row per task from PLAN.md execution graph.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Delivery Gate section.
     The per-delivery gate block is the authoritative source (single writer per delivery branch).
     Never written here. -->

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- DERIVED -- read-only union of:
       (a) each delivery-NNN/STATE.md ## Cross-phase Q&A section (delivery-gate Q&A), and
       (b) any work-owner-authored Q&A entries in this work's active branch (written below
           this comment by the work owner only; the work owner is the single writer here).
     Delivery branches write Q&A into their OWN delivery-NNN/STATE.md, not here (SD-5).
     The dashboard reader unions all delivery contributions plus (b) into this view.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch). -->

### D1 — First question of the redesigned interview (work-owner decision)

- **Category:** Design / Elicitation
- **Impact:** High
- **State:** Answered (owner-ratified 2026-06-27)
- **Applies to:** feature-002 (analyst conversation engine) + feature-004 (guided triage) — specify these to match when they leave Spike-Needed.
- **Decision:** The interview opens with a single **open, example-anchored "what + why"** question — NOT a classification question. Proposed phrasing: *"In a sentence or two — what do you want to build or change, and what's the outcome you're after?"* with a baked-in concrete example and the cue "describe the pieces the way you'd naturally name them — I'll work from your words."
- **Rationale (grounds in findings.md):** (1) §1 finding-1 — the shared vocabulary / ubiquitous language is the seed keystone, harvested by getting the user to describe the work in their own words, so the opener IS the first vocabulary capture; (2) §5 Rec B + JAD straw-man-first + NFR-7 — never a blank page; the example models the answer and lands suggested-answer-with-rationale on turn 1; (3) RQ-B2 calibration + triage are INFERRED from how the user answers and then **reflected back in plain language** ("sounds like a small single-purpose tool — that match?"), never asked as a cold self-classification.
- **Explicitly rejected openers:** "full or lite?" (jargon; the current triage-unclarity complaint), "how experienced are you?" (backwards — calibrate by reading the answer), bare "what are your requirements?" (violates straw-man-first).

### D2 — The opener is the ONLY fixed question; everything after is engine-guided (work-owner decision)

- **Category:** Architecture / Elicitation
- **Impact:** High
- **State:** Answered (owner-ratified 2026-06-27)
- **Applies to:** feature-002 (analyst conversation engine) — primary; also feature-004 (triage) + feature-003 (seed authoring).
- **Decision:** The D1 "what + why" opener is the **single fixed question** in the interview. Every subsequent turn is **NOT scripted** — it is chosen adaptively by the engine. The rest of the skill's design is **guidance for next-move selection**, not a predetermined question list. feature-002 must be built as an **adaptive elicitation engine, NOT an intake form / fixed questionnaire**.
- **Next-move selection inputs (what drives each turn after the opener):** (1) **seed-gap** — what is still missing from the minimal-but-sufficient seed (findings.md Rec A); (2) the **move playbook** — pick from term-capture / boundary-elicitation / event-first / bounded-why / concrete-example / capture-and-defer (findings.md §5 Rec B), not a fixed order; (3) **calibration state** read from prior answers (RQ-B2); (4) the **NFR-7 invariant** applied to whatever question it emits.
- **Stopping rule:** the engine halts at **minimal-but-sufficient** (NFR-4 / RQ-A5 — "aid-specify runs with zero KB-gap loopbacks"), NOT at the end of a list. This is the discipline grill-me lacks (findings.md §3).
- **Why it matters:** preserves the "seasoned analyst, not transcriber" intent and keeps the existing aid-interview "adaptive one-question-at-a-time" spine; a fixed multi-question form would regress to exactly the rigid intake the work is trying to replace.

### D3 — feature-006 reshaped: SPLIT the interview into two skills (work-owner decision)

- **Category:** Architecture / Skill topology
- **Impact:** High
- **State:** Answered (owner-ratified 2026-06-27)
- **Applies to:** feature-006 (was "rename aid-interview -> aid-define"; now a SPLIT) + REQUIREMENTS §5 FR-6. Re-opens FR-6.
- **Decision:** Split `aid-interview` into **two user-facing skills at the approval gate** (owner-chosen names `aid-describe` -> `aid-define`):
  - **`aid-describe`** = TRIAGE + interview (CONTINUE) + COMPLETION -> approved `REQUIREMENTS.md`; **the entire LITE path stays here** (lite is full-path-independent).
  - **`aid-define`** = FEATURE-DECOMPOSITION + CROSS-REFERENCE (approved REQUIREMENTS -> graded feature folders); feeds `aid-specify`.
- **Naming rule (informal -> formal progression):** the user **describes** the need in their own words (`aid-describe` — ties directly to the [[D1]] opener "describe the pieces the way you'd naturally name them"; the conversational, intent-gathering half), then that loose description is given **definite shape** as the concrete feature set (`aid-define` — decomposition + cross-reference). Rejected `aid-start` (names a position in the flow, not an outcome — repeats the flaw the rename was meant to fix).
- **Consequences feature-006 MUST absorb at specify time:** (1) skill count is **+1, NOT rename-neutral** — the count surfaces must INCREMENT (contrast the prior rename spec which held the count fixed); (2) two skill dirs, split `references/` between them, two install-manifest entries, two docs-site entries; (3) the pipeline "Interview" phase now maps to TWO skills (aid-describe -> aid-define -> aid-specify); (4) the `aid-interviewer` substring-collision guard still applies; (5) the split must reconcile with the FINAL file set after content features 002/003/004 (which edit the interview skill in place) — so feature-006 stays sequenced AFTER them.
- **Status:** spec-only now (feature-006 is deferred behind content features). Logged here for adoption when feature-006 leaves Spike-Needed; REQUIREMENTS FR-6 + the feature-006 SPEC get rewritten to this shape at that point (the current A+-gated rename SPEC is superseded by this decision).
- **Builds on:** [[D1]] + [[D2]] (the elicitation engine lives wholly in **aid-describe** — the interview/CONTINUE half — consistent with the split definition above; aid-define is only decomposition + cross-reference).

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries from
     delivery-NNN/tasks/task-NNN/STATE.md files.
     Appended by dispatchers at subagent completion (L1+L2+L3 traceability; always-on).
     One row per dispatch. Never written directly here; assemble from per-task logs at read time. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs assembled from
     delivery-NNN/tasks/task-NNN/STATE.md ## Dispatch Log sections.
     Never written here; one sub-section per task that triggered at least one dispatch.
     Updated by the dispatcher on subagent completion alongside the Calibration Log row. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._
