# task-055: Correct the stale roster prose — `index.mdx` (E-1) and `reference/overview.md`

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-055. It is the IMMUTABLE DEFINITION for this task.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.
Authored at execution time from `deliveries/delivery-006/BLUEPRINT.md`, per this delivery's
STATE.md Q1.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`.

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-006

**Depends on:** task-054

**Scope:**
- Correct the stale `92 / 14 classic / 76` triple in the two hand-authored pages that state it,
  to the derived `111 / 19 / 64`:
  - `site/src/content/docs/index.mdx` — **four** sites, at lines 76, 77 (the flow-chart caption)
    and 91, 92 (the "N skills deliver AID" paragraph). This absorbs delivery-001's escalation
    **E-1**, which recorded the home page as the most reader-visible instance.
  - `site/src/content/docs/reference/overview.md` line 16 — the Skills row of the section table.
- The corrected numbers are taken **from task-054's derivation**, not counted by hand. The point
  of the sequencing is that this task cannot reintroduce the KI-005 class: `skill-counts.test.mjs`
  fails the build if either page's stated triple parts company with the derivation.
- Prose only. No structural change to either page, no link-target change (that is task-056), and
  no generated file touched.

**Acceptance Criteria:**
- [ ] All four `index.mdx` sites state `111` total, `19 classic`, `64 verb-first` — and the
      surrounding sentence still reads correctly, with `/aid-triage` and `/aid-ask` still called
      out separately from the classic count.
- [ ] `reference/overview.md` line 16 states the same triple.
- [ ] Neither page still carries `92 skills`, `14 classic`, or `76 verb-first` anywhere.
- [ ] `skill-counts.test.mjs`'s three page-claim assertions pass **non-vacuously** — each one
      proves it actually found and checked at least one claim, so a page that silently stopped
      stating a number cannot pass by saying nothing.
- [ ] E-1 is discharged: the home page no longer promises a roster size the site does not ship.
- [ ] The full site suite passes and the build is clean.
- [ ] No generated file is modified by this task; `reference/skills.md` and the 111 skill detail
      pages are byte-unchanged.
- [ ] All section-6 quality gates pass.
