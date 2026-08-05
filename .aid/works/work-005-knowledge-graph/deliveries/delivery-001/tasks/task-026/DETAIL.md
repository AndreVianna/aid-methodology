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
- Complete: the `/aid-graph` capability entry; the new script area in **every** document that
  enumerates script areas; `relationships.md` in the artifact-schema set; the release-ledger entry;
  and the drafted `technology-stack.md` and `infrastructure.md` content feature-002 deferred to ship
  time (feature-002 does not write to the KB itself).
- Refresh `kb.html` and `INDEX.md` **once, here** — they are final-state summaries, not sources, and
  mid-work staleness was correct rather than a defect.

**Acceptance Criteria:**
- [ ] **The two roster slots I added carry a falsified citation and it must be re-verified:**
      `architecture.md:214-216` and `pipeline-contracts.md:94-96` each assert
      `CONFIRMED in docs/aid-methodology.md`. Read the cited file, and for each slot either correct
      the claim or re-cite it to a source that actually confirms it. Neither may ship as written
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
- [ ] All section-6 quality gates pass
