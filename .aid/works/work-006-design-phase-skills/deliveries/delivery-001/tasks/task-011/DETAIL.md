# task-011: `/aid-create-roadmap`, the `roadmap.md` shape, and the second `doc_set` producer

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-011/STATE.md.
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

**Depends on:** task-007, task-008, task-010

**Scope:**
- Source spec: `features/feature-003-planning-artifact-skills/SPEC.md` §3a, §3c (the
  `## Contents` forward entry), §4, §6b (its `/aid-create-roadmap` row and the registration
  surfaces), §6d; REQUIREMENTS CC-1, CC-2; BLUEPRINT § Gate Criteria, criterion 10.
- Author `canonical/skills/aid-create-roadmap/SKILL.md` plus its catalog row (`verb: create`,
  `artifact: roadmap`, `default_type: DOCUMENT`, `group: G4`, `alias_of: null`,
  `repurpose: true`, §1's `intent` verbatim).
- **The body fixes `roadmap.md`'s shape**, because no template exists anywhere under
  `canonical/` and that absence is the mechanism keeping the seed at 14 -- so an unstated
  shape is a shape the skill invents. It states: §3a's frontmatter field set **and values**
  (`kb-category: primary`, `source: hand-authored`, `sources: []`, `objective:`, `summary:`,
  `tags`, `see_also`, `owner: architect`, `audience`); the `# Roadmap` title; the
  one-paragraph preamble saying what the document holds and what it does not (no items live
  here); `## Contents` in the house link form (`- [MVP](#mvp)`, `- [Now](#now)`,
  `- [Next](#next)`, `- [Later](#later)`, one per line, in heading order); and `## Now`,
  `## Next`, `## Later`. The level-3 entry schema is `### <Direction, as a noun phrase>` with
  `**What:** / **Why:** / **Rejected:** / **Status:**`, `Status` carrying a durable evidence
  anchor (path plus a grep-recoverable heading or search string) or the literal `intent`.
  **No summary table** and **no item ids anywhere**.
- Class-1 `create` behavior per feature-002 §3a and §3c: refuse while the seed's
  `## Open questions` is non-empty unless the user overrides, naming the unresolved
  content **and** the override; create the document when absent (it owns the whole
  document); fill the horizon sections when the document is present; route to
  `/aid-update-roadmap` when its own owned region already carries committed content, leaving
  the seed in place for that run (CC-3); delete the seed on the realizing path; and
  **never create or touch `## MVP`** -- only the `MVP` index entry.
- **Registration on creation, in the same run** (CC-2), at the presence value CC-1 fixes:
  one `.aid/settings.yml` `knowledge.doc_set` line `roadmap.md|skill-self|required`
  appended by the R13 append-block idiom (never rewriting the block, never touching
  `term_exclusions`), and one `.aid/knowledge/README.md` Completeness row -- `Concern` `D`,
  `Owner` `skill-self`, `Status` the literal `Created (skill-self)` -- with the
  `**Doc-set:** N documents` line incremented.
- **The `canonical/skills/aid-config/SKILL.md` amendment lands here** (BLUEPRINT criterion
  10, assigned to feature-003 rather than to whichever feature lands first): the line that
  today reads *"`knowledge.doc_set` and `knowledge.term_exclusions` are runtime-written by
  `aid-discover`"* also names the `create` skills as a **second** runtime producer of
  `knowledge.doc_set` -- written once, naming **both** producers, so feature-004 in
  delivery-002 verifies rather than repeats.
- Out of scope: creating this repository's own `.aid/knowledge/roadmap.md` instance, which is
  an effect of *running* the skill (task-015); `## MVP` itself (task-013); the `update`
  counterpart (task-014); and the catalog's three stale count comments (delivery-003).

**Acceptance Criteria:**
- [ ] V1/V3 for this row: the directory exists, the row exists with all eight fields,
      `default_type: DOCUMENT` (the value the catalog already assigns to every
      document-producing row) and `group: G4`
- [ ] V2: `build-shortcut-skills.py` overwrites no body
- [ ] AC-6's premise holds: a reviewer can reconstruct `roadmap.md`'s frontmatter values,
      heading set, `## Contents` link form and entry schema **from the body alone**, with
      nothing left to the author's invention
- [ ] The body writes `- [MVP](#mvp)` into `## Contents` at creation and never writes a
      `## MVP` heading -- V10's precondition, and what makes REQUIREMENTS AC-6a ("`/aid-*-mvp`
      writes only that section") literally true
- [ ] The registration step writes **exactly one** `doc_set` line, byte-equal to
      `    - roadmap.md|skill-self|required`, and **exactly one** README Completeness row
      with `Status` = `Created (skill-self)`; a body that writes `conditional` fails (CC-1)
- [ ] BLUEPRINT criterion 10's oracle: `grep -n 'aid-discover' canonical/skills/aid-config/SKILL.md`
      at that row also matches a `create`-skill mention **on the same line**
- [ ] V25 for this skill: the `description` names `/aid-create-mvp` and `/aid-update-roadmap`
- [ ] The body states `source: hand-authored` with the reason recorded (no as-built
      counterpart exists for the Conformance Lane to compare a direction entry against), so
      the divergence from feature-004's `forward-authored` reads as a decision
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
