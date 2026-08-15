# Plan -- {Work Name}

[!NOTE]
This is the FLATTENED single-delivery `PLAN.md` template: `.aid/works/work-NNN-{name}/PLAN.md`, used
when the work has exactly one feature and one delivery (no `deliveries/`/`delivery-NNN/`
wrapper -- feature-001). It carries the plan's single `## Deliverables` entry plus a
top-level `## Execution Graph`. That single entry IS the delivery definition: its
objective, scope, and GATE CRITERIA live in it. The task listing is NOT recorded --
it is derived from each task's `**Source:**` field.

This template emits ZERO `### delivery-NNN` subsection headings BY DESIGN -- do not add one.
Both `compute-block-radius.sh` (requires `--delivery-id` once it sees `>= 2` such headings) and
`complexity-score.sh` (`grep -qE '^### delivery-'` switches it to the multi-delivery branch,
which then REQUIRES `--delivery-id`) key off that heading's absence/count to stay on their
no-`--delivery-id` path and parse this top-level `## Execution Graph` directly -- the same shape
the now-retired lite-path work-root SPEC used before feature-002 removed it. The single
delivery is carried only by each task's `**Source:** ... -> delivery-001` field in its
`tasks/task-NNN/DETAIL.md` -- never by a heading in this file.

> **Work:** work-NNN-{name}
> **Created:** {YYYY-MM-DD}

---

## Deliverables

<!-- ONE entry -- the work's single, implicit delivery (synthesized delivery-001). No
     `### delivery-NNN` subsection heading (see note above); the delivery is identified by the
     `**Delivery:**` field below instead. This entry IS the delivery definition. -->

- **Delivery:** delivery-001 -- {Name}
- **What it delivers:** {user-facing value}
- **Features:** feature-001-{name}   (the single feature; its section is `REQUIREMENTS.md § 11`)
- **Depends on:** -- (none -- single delivery)
- **Priority:** Must | Should | Could

**Objective:** {one paragraph: what this delivery achieves}

**Scope:** {what is IN scope, citing the feature's `AC-N` ids}
**Out of scope:** {anything explicitly excluded}

**Gate Criteria** -- the rubric the delivery gate evaluates; each concrete, independently
testable, and naming an observable:

- [ ] {Criterion 1 -- concrete and testable}
- [ ] All section-6 quality gates pass

---

## Execution Graph

<!-- Top-level heading (matched by both execute-graph scripts at ANY heading level: #+).
     No `### delivery-NNN` wrapper around this block -- see the note at the top of this file. -->

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
