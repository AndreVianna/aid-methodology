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

> **AC amendment (2026-07-30, at review — recorded rather than silently reworded).** The two ACs
> immediately below originally required `111` / `19 classic` / `64 verb-first`. Review showed that
> decomposition **does not sum**: `19 classic` counts three skills that are also catalog rows and
> naming `/aid-ask` separately double-counts a fourth, while the 26 work-005 collapse skills are
> omitted entirely — 19+1+1+64 = 85 for a 111-skill corpus. The delivery therefore shipped
> `17 curated + 94 catalog = 111`, which is what the rest of the site and the KB already state.
> The ACs are amended to match what shipped, and the superseded wording is kept visible so the
> change reads as a correction rather than a moved goalpost.

**Acceptance Criteria:**
- [ ] All four `index.mdx` sites state a decomposition that **sums to the derived total** —
      `111` = `17 curated` + `94` catalog (itself `64` verb-first shortcuts + `30` `repurpose`
      skills) — and the surrounding sentence still reads correctly, with `/aid-triage` placed
      inside the 17 and `/aid-ask` inside the 30. ~~`111` total, `19 classic`, `64 verb-first`~~
- [ ] `reference/overview.md` line 16 states the same decomposition.
- [ ] Neither page still carries `92 skills`, `14 classic`, or `76 verb-first` anywhere.
- [ ] `skill-counts.test.mjs`'s three page-claim assertions pass **non-vacuously** — each one
      proves it actually found and checked at least one claim, so a page that silently stopped
      stating a number cannot pass by saying nothing.
- [ ] E-1 is discharged: the home page no longer promises a roster size the site does not ship.
- [ ] The full site suite passes and the build is clean.
- [ ] No generated file is modified by this task; `reference/skills.md` and the 111 skill detail
      pages are byte-unchanged.
- [ ] All section-6 quality gates pass.
