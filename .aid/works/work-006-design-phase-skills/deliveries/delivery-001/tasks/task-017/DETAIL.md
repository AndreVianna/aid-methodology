# task-017: The three `document-expectations.md` blocks and the adopter drain paragraph

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-017/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-007, task-018

**Scope:**
- Source spec: `features/feature-001-kb-doc-set-restructure/SPEC.md` §1b surface 3, §3e,
  AC-9, AC-11, and §6 **step 5** -- the step that sits **downstream of feature-003 creating
  the documents**, because parts 1-3 of two of its three blocks are feature-003's to supply.
  feature-003 §9 carries the matching outbound edge (*"Hands to feature-001 -- the
  `document-expectations.md` block text"*). This is the interleave that makes the two
  features share a delivery.
- **The `task-018` edge is a read/write serialisation edge, and it is the last writer that
  matters.** Parts 1-3 of two of these blocks must agree with `.aid/knowledge/roadmap.md`
  and `.aid/knowledge/backlog.md` **as they stand on disk** -- which makes this task a
  *reader* of two documents other tasks write. Their writers, in order: task-015 creates
  `roadmap.md`, task-021 creates `backlog.md`, task-022 mutates and restores `roadmap.md`,
  task-023 mutates and restores both, and **task-018 migrates the `## Unreleased` items into
  `backlog.md`** -- the last write of all. Depending on task-018 (which itself depends on
  task-023) puts this task strictly after every one of them, so the blocks describe the
  documents' final state rather than a mid-run one. An earlier draft depended on task-023
  and called it "the last such writer"; that was false, and it left this task concurrent with
  task-018 in the same wave.
- Append three blocks to `canonical/skills/aid-discover/references/document-expectations.md`
  after `### decisions.md`, the current last block, preserving the `---`-separated block form
  the file uses throughout: `### roadmap.md`, `### backlog.md`, `### release-tracking.md`.
- Each block carries the **full four-part anatomy** the existing blocks use: (1) a bold
  what-is-this-document paragraph phrased as the question the doc answers; (2) an italic
  `*(Investigate: ...)*` clause naming what to ground it in; (3) an
  `**Operational open question:**` line naming a `##` section to surface; (4) a
  `**Red flags:**` line whose first clause names the boundary against the nearest neighbour.
- **Parts 1-3 of `### roadmap.md` and `### backlog.md` are shape**, taken from feature-003
  §3a/§3b as authored in task-011 and task-012 and as instantiated in task-015
  (`roadmap.md`) and task-021 (`backlog.md`) -- the field list, the entry/item schema, and
  the D and C7 depth floors each document must meet.
- **Part 4 for all three is feature-001's**, because red flags are boundary statements and
  boundaries are membership: `roadmap.md` vs `backlog.md` (direction vs items),
  `backlog.md` vs `tech-debt.md` (accepted vs merely observed), `backlog.md` vs
  `release-tracking.md` (pending vs shipped), and `roadmap.md` § MVP vs the rest of
  `roadmap.md` (CC-5).
- `### backlog.md` additionally carries **the item-flow sentence** (how an item enters, from
  `tech-debt.md` on acceptance into the plan, and how it leaves, at tag time) and **AC-9's
  manual drain paragraph**: at release time the committed items move out of `backlog.md`
  into a new `release-tracking.md` version section; AID ships **no adopter-facing skill**
  that does this (`release-aid` is repo-local and absent from `canonical/skills/`); it is
  therefore a **manual step**. This file is the right home because it renders to all five
  profiles, whereas `.aid/knowledge/authoring-conventions.md` has no template and no profile
  copy, so an adopter never receives its text.
- **All four parts of `### release-tracking.md`** are feature-001's outright -- that
  document's shape is already settled and no other feature owns it.
- **The whole file is edited by this one task, and that absorbs a step-2 obligation.**
  feature-001 §6 **step 2** assigns `### release-tracking.md` *"in full"* alongside the four
  registration surfaces -- i.e. ahead of feature-003's step 4 -- while §6 **step 5** assigns
  the other two blocks. This task takes all three. The relocation is disclosed rather than
  silent, and it is free: nothing in this delivery gates on the `### release-tracking.md`
  block landing early, AC-11 is evaluated once, and three edits to one file across two waves
  is precisely the collision the sequencing exists to prevent. task-007's Scope names the
  same hand-off from the step-2 side.
- **Write the delivery's two tech-debt rows into `.aid/knowledge/tech-debt.md`'s inventory,
  because "routed to tech-debt" is a transfer only if a task performs it.** Two obligations
  are deferred work-wide, and both land here as inventory rows with an `ID` minted in the
  form the live inventory already uses, a `Type`, `Description`, `Location`, `Risk`, `Effort`
  and `Priority`:
  The `ID` follows the same three constraints task-018 states, because "the next unused
  ordinal" is not single-valued here: the live file carries **two** families -- `L4` and a
  `W<series>-<ordinal>` family spanning `W1-1..W1-17`, `W4-3`, `W4-5`, `W5-1..W5-19`. Use
  `W<series>-<ordinal>` (feature-003 §3b names it as this repository's form); never extend
  `L<n>`; and check uniqueness across the **whole** file, inventory table and Detailed Debt
  Items alike, plus `backlog.md`.
  1. **Automating the adopter-facing release drain as a canonical skill** -- out of scope
     work-wide (feature-001 §7; BLUEPRINT § Scope). `Location` is this file's `### backlog.md`
     block, whose manual-step paragraph is the interim answer; `Risk` is that the adopter
     item flow stalls at `backlog.md` with no shipped skill to drain it.
  2. **The 36-of-58 matrix documents with no `### <filename>` block** in this file -- a
     pre-existing gap this work neither created nor widens (feature-001 §7, computed not
     sampled). `Location` is this file; `Risk` is that the matrix schema's declared join
     target is incomplete for two thirds of the documents it indexes.
  This task is the right owner for both: it is the task that raises the second deferral, it
  is a DOCUMENT task already writing KB-adjacent prose, and it is ordered after task-021 --
  the only other writer of `tech-debt.md` in this delivery -- so the two never collide.
- Out of scope: actually closing either deferred item; and the five profile renders of this
  file, which are delivery-003's (AC-9's render half is evaluated there).

**Acceptance Criteria:**
- [ ] AC-11 oracle:
      `grep -cE '^### (roadmap|backlog|release-tracking)\.md' canonical/skills/aid-discover/references/document-expectations.md`
      -> `3`, **and** for each of the three, the lines between the heading and the next `---`
      include a `**Red flags:**` line -- no block is a bare heading
- [ ] Each of the three blocks carries all four anatomy parts, matching the form of
      `### decisions.md`, `### quality-gates.md` and `### capability-inventory.md`
- [ ] AC-9 oracle, canonical half:
      `grep -c drain canonical/skills/aid-discover/references/document-expectations.md`
      -> `>= 1` (it is `0` today) with the hit **inside** the `### backlog.md` block. The
      five-render half is delivery-003's and is named here rather than dropped
- [ ] The drain paragraph states all three facts AC-9 requires: what moves, that AID ships no
      adopter-facing skill that does it, and that it is therefore manual
- [ ] Parts 1-3 of the roadmap and backlog blocks agree with the documents on disk **in
      their final state** -- after task-018's migration, which this task's edge places
      strictly before it. Any claim a block makes that `.aid/knowledge/roadmap.md` or
      `.aid/knowledge/backlog.md` does not satisfy is a defect of this task
- [ ] **Both deferred obligations exist as rows in `.aid/knowledge/tech-debt.md`'s inventory
      table** -- the adopter-facing drain skill and the 36-of-58 expectations-block gap --
      each with an `ID` in the live inventory's own form, a durable `Location` (never
      `path:LINE`) and a stated `Risk`: `grep -c drain .aid/knowledge/tech-debt.md` -> `>= 1`
      and `grep -c document-expectations .aid/knowledge/tech-debt.md` -> `>= 1`. A deferral
      that names "tech-debt" without a row in that file is a drop, not a transfer, and fails
      this criterion
- [ ] Neither new tech-debt row reuses an id: each is in the `W<series>-<ordinal>` family
      (never `L<n>`) and `grep -c '<id>'` over the whole of `.aid/knowledge/tech-debt.md`
      -- inventory table **and** Detailed Debt Items -- and over `.aid/knowledge/backlog.md`
      shows it exactly once. `comm -12` over the id column of the two files is still empty
- [ ] `test-spine-depth-coverage.sh` passes **unmodified** (this file is one of its inputs)
      and `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` is clean
- [ ] **The commit stages explicit paths only.** This task commits inside the window in which
      task-024's render sits uncommitted in `profiles/`, `.claude/` and `.cursor/`, so
      `git diff --cached --name-only` immediately before the commit lists exactly
      `canonical/skills/aid-discover/references/document-expectations.md` and
      `.aid/knowledge/tech-debt.md`, and no wildcard staging form (`git add -A`, `git add .`,
      `git add -u`, `git commit -a`) is used (task-024 § Scope states the rule; the same bound
      binds every task that commits while the render is live)
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` reports **exactly** what task-024
      left, before and after this task -- it neither renders nor reverts, and a wildcard add
      would show up here as the render's entries disappearing from the output
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
