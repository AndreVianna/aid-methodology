# task-026: The ship-time Knowledge Base pass

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-026/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** feature-013-tests-and-docs -> delivery-001 (Wave 5)

**Depends on:** task-024

**Scope:**
- feature-013 D3 and `AC-T8`. Part of this landed early in commit `55453fd3`
  (`capability-inventory.md`, `module-map.md`, `architecture.md`, `pipeline-contracts.md`,
  `project-structure.md`, `release-tracking.md`, `tech-debt.md` were all touched), so this task is
  **completion plus verification**, not a fresh write.
- **But verify what "touched" means before trusting it — for two of those files it does not mean the
  roster slot landed.** `git diff 55453fd3^ 55453fd3` on `architecture.md` and `pipeline-contracts.md`
  changed **numerals only** (75 → 76), and `grep -c aid-graph` on each returns **0** today. Their D3
  slot-adds are therefore outstanding, not done, and this task owns them (see AC 1).
- Complete: the `/aid-graph` capability entry; the new script area in **every** document that
  enumerates script areas; `relationships.md` in the artifact-schema set; the release-ledger entry;
  and the drafted `technology-stack.md` and `infrastructure.md` content feature-002 deferred to ship
  time (feature-002 does not write to the KB itself).
- **The D3 rows that fire and were previously unrouted — each is this task's:**
  `test-landscape.md` (SPEC `:456`, Fires **Always**) owes a row for this work's suites in
  § *The Canonical Helper Suites*, plus the canonical-suite figure refreshed at its live sites, plus
  the `:96–:97` arithmetic judgment (it states a live total **and** a historical decomposition of it,
  so bumping the total alone breaks the arithmetic — either the decomposition moves with it or the
  sentence is re-framed as a record of that work). `quality-gates.md:177–:182` (SPEC `:458`) owes the
  grade-floor drift, and its condition **fires**, because this KB pass is the next thing to touch that
  file. `domain-glossary.md` (SPEC `:462`) owes the spine-concept judgment — up to two concepts, or a
  recorded decision that none belongs.
- Refresh `kb.html` and `INDEX.md` **once, here** — they are final-state summaries, not sources, and
  mid-work staleness was correct rather than a defect.

**Acceptance Criteria:**
- [ ] **ADD the two roster slots, then re-verify the citation each already carries.** Both edits are
      required and the second does not substitute for the first. **`grep -c aid-graph` on
      `.aid/knowledge/architecture.md` and on `.aid/knowledge/pipeline-contracts.md` each returns 0
      today, so neither slot exists** — an earlier version of this criterion said the slots had
      already been added and asked only for the citation to be re-verified, which would have shipped
      D3's Always-firing slot-adds unowned.
      **(a) Add the slot.** In `architecture.md:214–:216`, one slot for `/aid-graph` in the
      *Knowledge Base Maintenance* group's on-demand list, in the shape the line already uses — a
      name plus a parenthesised role, beside `aid-housekeep`, `aid-ask`, `aid-update-kb` and
      `aid-summarize`. In `pipeline-contracts.md:94–:96`, add `/aid-graph` to the
      off-pipeline-or-optional list beside those same names, since FR-7 makes it on-demand and off
      the numbered pipeline. Both are D1 class-1 *member-of-a-skill-list* sites, so each is the same
      kind of edit as `docs/aid-methodology.md:408`, not a new kind.
      **(b) Then re-verify the citation.** Each line closes `CONFIRMED in docs/aid-methodology.md`
      (`architecture.md:217`, `pipeline-contracts.md:98–:99`), and this work's own table-A and `:408`
      edits falsify it. Read the cited file and either correct the claim or re-cite it to a source
      that actually confirms it. Neither may ship as written.
      **Oracle:** `grep -c aid-graph` on both files must return non-zero, and the slot must sit
      inside the roster line rather than anywhere else in the document — a mention elsewhere would
      satisfy the grep while leaving the roster incomplete, which is the failure this criterion is
      written to prevent
- [ ] Every document that enumerates script areas names the graph area — the enumeration is checked
      by grep across the KB, not by memory
- [ ] No KB document cites `CLAUDE.md` or `AGENTS.md` by line — those are pointers, not truth
- [ ] No KB document cites a work folder as a source; the research documents under
      `deliveries/delivery-001/research/` are not referenced (work folders are transient)
- [ ] The release ledger records the addition, with plain-text status values (glyphs are
      display-only, never machine-parsed values)
- [ ] `kb.html` and `INDEX.md` are refreshed exactly once, at the end of this task
- [ ] Any resolved tech-debt item is **removed** from `tech-debt.md`'s inventory and detail and from
      the HTML cards; the closure record lives in changelog frontmatter and git, not in a lingering
      row
- [ ] **Accuracy verified against the current codebase** (DOCUMENT type-default,
      `task-decomposition.md`:182), and specifically for the three rows this task routes: the
      `test-landscape.md` suite row and figure, the `quality-gates.md` grade-floor drift and the
      `domain-glossary.md` spine judgment are each verified first-hand against the file rather than
      against the SPEC's description of it -- the SPEC itself notes that a stated verification is what
      suppressed the scrutiny which would have caught the drift
- [ ] All section-6 quality gates pass
