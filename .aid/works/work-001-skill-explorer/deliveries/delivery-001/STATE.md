---
delivery_state: Done
gate_tier: Large
gate_grade: A+
gate_timestamp: '2026-07-26T21:05:30Z'
ticket_ref: "--"
---

# Delivery State -- delivery-001

[!NOTE]
This is the DELIVERY-LEVEL STATE.md. It is divided into three zones:
  FRONTMATTER (single writer = this delivery's branch, machine-parsed scalars) --
      `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `ticket_ref`.
  AUTHORED (single writer = this delivery's branch, markdown body) --
      the narrative remainder of Delivery Lifecycle / Gate Block, Cross-phase Q&A.
  DERIVED (read-only, assembled at read time) --
      Tasks State (rollup from per-task STATE.md files in tasks/task-NNN/STATE.md).
Identifiers (`Delivery`/`Work` in the header blockquote below, `Branch`) are INFERRED from
the folder name and git worktree -- never authored in frontmatter.

<!-- DELIVERY LIFECYCLE ENUM (authored, not derived)
  aid-plan       creates this file with State = Pending-Spec
  aid-specify    advances to Specified
  aid-execute    advances Specified -> Executing -> Gated -> Done, or to Blocked
Enum members: Pending-Spec | Specified | Executing | Gated | Done | Blocked
This authored state is NOT a derivation of child task states. A delivery may be Pending-Spec
with ZERO tasks; the `_none yet_` rollup below is correct and expected for a new delivery.
-->

> **Delivery:** delivery-001
> **Work:** work-001-skill-explorer
> **Branch:** aid/work-001-delivery-001

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch only. The **State** scalar lives in the
     YAML frontmatter block at the top of this file (`delivery_state`). -->

- **Updated:** 2026-07-26T14:30:12Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

- **Complexity Score:** Large tier (owner-directed for every delivery gate in this work, ahead of the score)
- **Cycles:** 7 review cycles. Grades: **E+ -> C -> C+ -> C+ -> B -> B+ -> A+.**
- **Issue List:** 25 rows, all closed -- 23 Fixed, 2 Accepted, **0 Pending**.
  - [CRITICAL] 354 unspecified paths (`.cursor/` + root `AGENTS.md`) committed inside task-001,
    making the gate review surface 99.4% content no task declared -- **Fixed**. Owner confirmed
    the content belongs on the branch, so the fix was structural: the four task commits were
    rewritten to 2-3 declared paths each and the tree landed as its own commit. Recorded as E-3.
  - [HIGH] x2 -- the AC5 pipeline guard (a) covered only two Mermaid link forms, silently
    dropping every other, and (b) ran one fixed checklist against each diagram rather than
    deriving index.mdx s expectations from README. Both **Fixed**.
  - [MEDIUM] x7 -- four further lexical holes in the same parser (bidirectional/double-ended
    heads, `%%` comments, `;` separators, the `{rhombus}`/`>asymmetric]` shapes), two
    overclaiming comments, and KI-005/KI-006 still reading "Scheduled for fix". All **Fixed**.
    The parser was then rewritten to **fail closed** -- an unmodelled construct throws naming
    the text it could not read -- which closed the class rather than the fourth instance of it.
  - [LOW] x5, [MINOR] x1 -- placeholder findings blocks, empty dispatch logs, an unfilled
    BLUEPRINT task table, a global containment escape, keyword prefixes without word
    boundaries, and two wrong figures in a commit message. All **Fixed** (the last via
    `## Record Corrections`, since a commit message cannot be amended after the fact).
  - **Accepted (2, not blocking):** E-2, the same hard-coded-count class knowingly left in the
    `agents.md`/`kb.md` assertions rather than absorbed mid-delivery; and one residual parser
    limitation -- a node id exactly equal to a Mermaid statement keyword at line-leading
    position -- left open deliberately, because closing it would risk fabricating an edge,
    which is a worse failure than dropping one.
- **All eight gate criteria PASS**, each verified by execution rather than by reading.
- **Headline outcome:** `npm test` in `site/` exits 0 for the whole suite -- 8 files, 305 tests
  -- and `docs.yml` now runs it on every pull request, between `npm ci` and `npm run build`.
  **218 of those 305 tests live in the five TypeScript suites that had never executed anywhere**
  -- not locally, not in CI, not once. KI-005 and KI-006 are both closed.
---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of aid-execute).
     The work-level ## Cross-phase Q&A is a DERIVED union of all delivery Q&A sections plus any
     work-owner-authored work-level entries. -->

### Q1 — feature-005's OQ-3: should `docs.yml`'s path filter gain `canonical/**`?

- **Category:** CI / build triggers (feature-005 OQ-3; cross-cutting risk R6)
- **Impact:** Required — task-004's scope is contingent on it
- **State:** **Answered** (2026-07-26, work owner)
- **Context:** `docs.yml` carries two path filters — `push` (`:13-17`) and `pull_request`
  (`:20-24`) — each listing `site/**`, `docs/**`, `VERSION` and the workflow file. A commit that
  edits `canonical/` without regenerating pages therefore triggers no docs build, so deployed
  deep-link anchors can sit one generation stale. feature-005's deep links pin `canonical/` line
  ranges against the `master` ref, which makes this its problem. delivery-001 owns the decision
  because `docs.yml` is already open here; deciding it at delivery-004 would reopen a shipped
  artifact.
- **Suggested:** Add it — the cost is extra builds on canonical-only commits, and the benefit is
  that R6 closes.
- **Answer:** **Yes — add `canonical/**` to BOTH path filters.** The staleness window R6
  describes is real and the remedy is two lines in a file this delivery already edits.
- **Applied to:** task-004 (the same edit that inserts the `npm test` step),
  `.github/workflows/docs.yml`:13-17 and :20-24.

---

## Gate Escalations

<!-- AUTHORED -- named escalations raised by delivery-001's tasks under the gate criterion
     "anything Part C surfaces beyond the eight known items is either fixed within this
     delivery or escalated to the owner as a gate escalation -- not absorbed as silent scope." -->

### E-1 — `index.mdx`'s prose skill counts are stale (92 / 14 / 76 vs a measured 111 / 21 / 64)

- **Raised by:** task-002 (finding F-2 of its triage record), 2026-07-26
- **Class:** real defect in published product content — **not** a test defect
- **Why escalated rather than absorbed:** task-003 is bounded to
  `site/src/**/__tests__/`; `site/src/content/docs/index.mdx` is a content page, so correcting
  it would be silent scope. No test asserts these numbers, so it neither blocks `npm test` nor
  is caught by anything this delivery adds.
- **Evidence:** `index.mdx`:76-77 and :91-92 both read "92 skills — 14 classic pipeline/on-demand
  skills … and 76 verb-first shortcut skills". Measured on the same tree: 111 directories under
  `canonical/skills/`, 21 curated by `SKILL_GROUPS`, 64 emitting catalog rows. The site's own
  generated `reference/skills.md`:9 already states 111 / 19 classic / 64.
- **Relevance to this work:** after delivery-002 ships, a reader will see 111 skill cards under a
  home page promising 92 skills.
- **Owner options:** (1) correct `index.mdx`'s two prose blocks as a ride-along, (2) file it as a
  ticket for a separate content pass, or (3) accept it. Delivery-001 touches it in no case.
- **Status:** **Open — awaiting owner decision at the delivery-001 gate.**

### E-3 — the `.cursor/` install tree and root `AGENTS.md` on this branch

- **Raised by:** the delivery-001 Large-tier gate reviewer as **[CRITICAL]**, 2026-07-26 —
  354 paths (`.cursor/`, 353 files, plus a new root `AGENTS.md`) were committed inside
  task-001's commit, in no task's Scope, making the gate's review surface 99.4% unspecified
  content.
- **Status: RESOLVED, 2026-07-26.** Two separate questions, answered differently:
  - **Does the content belong on the branch? YES — owner-confirmed.** These are not IDE noise.
    The owner added the rendered cursor profile tree and its root context file deliberately and
    confirmed they are intended to travel with the branch and be pushed with it.
  - **Did they belong inside a task commit? NO.** The reviewer's process objection stands and is
    what was actually fixed. All four task commits were rewritten to contain only their declared
    paths, and the tree was landed as its own labelled commit (`085bf962`). Each task commit is
    now reviewable against its own Scope, and `git diff --name-only` over the four task commits
    lists exactly 12 in-scope paths.
- **Why it is recorded rather than closed silently:** the tree ships with no task, no acceptance
  criteria and no review of its 353 files. That is an owner decision, not a delivery-001
  deliverable, and it should be visible as such at the gate rather than inferred from a diff.

### E-2 — the same hard-coded-count defect class survives in the `agents.md` / `kb.md` assertions

- **Raised by:** the delivery-001 Large-tier gate reviewer, 2026-07-26
- **Class:** pre-existing defect of KI-005's class, four lines below the region task-001 fixed
- **Decision: knowingly left as-is, NOT absorbed.** Recorded here so it is a stated boundary
  rather than an oversight.
- **Evidence:** in the same `describe('gen-reference: roster counts')` block,
  `gen-reference.test.mjs` still asserts `expect(agentDirs).toHaveLength(9)` /
  `expect(sections).toHaveLength(9)` and `expect(kbFiles).toHaveLength(14)` /
  `expect(rows).toHaveLength(14)`, with both counts also written into the `it` titles. These are
  literal corpus counts of exactly the kind §8 forbids and KI-005 records.
- **Why not fixed here:** task-001's Scope is bounded to the eight items at `:101-141`, and
  delivery-001's first gate criterion is scoped to those eight. Widening a task mid-delivery to
  sweep in adjacent defects is the failure this delivery has already been penalised for once
  (the `.cursor/` scope leak, [CRITICAL] at this gate). The disciplined move is to name it, not
  to absorb it.
- **Why it is lower risk than KI-005 was:** both counts are currently correct (9 agent
  directories, 14 KB doc types), and unlike the skill corpus neither has drifted. The remedy is
  also trivial when it is taken: assert `sections.length === agentDirs.length` and
  `rows.length === kbFiles.length`, which removes the literal and strengthens the check.
- **Recommendation:** a one-task follow-up alongside the eventual `gen-reference.mjs` unfreeze
  (which already owns KI-003, KI-009 and KI-010), or a two-line ride-along on the next edit to
  this test file.

_(End of gate escalations — E-1, E-2, E-3. Anything added below is not an escalation.)_

---

## Record Corrections

<!-- AUTHORED -- corrections to statements already committed to this delivery's history.
     Commit messages are immutable once written; a correction lives here instead.
     Deliberately placed BELOW the last gate escalation: an earlier revision put this
     heading between E-3 and E-2, which filed an escalation outside the section an
     owner reads at the gate. -->

- **`cd06848b`'s closing line is wrong twice.** It reads *"110 AC5 fixtures; suite at 302."*
  Both figures are wrong as stated: the whole `site/` suite stood at **293** tests at that
  commit, not 302, and **110** was the total test count of `ac13-version-injection.test.ts`
  as a whole — the tests under AC5-titled `describe` blocks numbered **68**. Raised by the
  delivery-001 gate reviewer as [MINOR]; recorded rather than amended, since rewriting a
  commit purely to correct prose is not worth the history churn. The delivery's authoritative
  metrics are the ones in this file and in the gate block above.

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The Tasks State section below is assembled at READ TIME from per-task STATE.md files
     (tasks/task-NNN/STATE.md within this delivery folder). NEVER written directly.
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup assembled from tasks/task-NNN/STATE.md mutable cells.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
