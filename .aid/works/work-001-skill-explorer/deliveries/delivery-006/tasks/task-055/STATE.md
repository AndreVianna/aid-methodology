---
state: Done
review: 'Quick-check: 1 CRITICAL + 2 HIGH, all fixed-on-spot'
elapsed: "--"
notes: "Prose corrected in index.mdx (lines 76-77, 91-92) and reference/overview.md (line 16) to 111/19/64 triple. skill-counts.test.mjs passes. Uncommitted — commit after task-054 review or together with 054."
ticket_ref: "--"
---

# Task State -- task-055

> **Task:** task-055
> **Delivery:** delivery-006
> **Work:** work-001-skill-explorer

**Title:** Correct the stale roster prose -- index.mdx (E-1) and reference/overview.md

---

## Task State

<!-- AUTHORED -- values live in the YAML frontmatter block at the top of this file
     (`state`, `review`, `elapsed`, `notes`), written ONLY by
     `writeback-state.sh --task-id NNN --field State --value VALUE`.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

---

## Quick Check Findings

- **Reviewer Tier:** Small
- **Findings:**
  - [CRITICAL] The corrected sentence contradicted the site's own reconciled taxonomy: index.mdx said '19 classic' where methodology.md, glossary.md and repository-structure.md all say '17 curated' for the identical 111-directory corpus, so two pages of one site gave a reader different decompositions -- site/src/content/docs/index.mdx:76 -- Fixed-on-spot (both pages restated as 17 curated + 94 catalog, the framing the rest of the site and the KB already use)
  - [HIGH] The corrected sentence no longer summed: '111 skills -- 19 classic + /aid-triage + /aid-ask + 64 verb-first' totals 85, a 26-skill hole, where the superseded sentence summed exactly (14+1+1+76=92). Cause: classic(19) counts 3 skills that are also catalog rows, naming /aid-ask double-counts a 4th, and the 26 work-005 collapse skills were omitted entirely -- site/src/content/docs/index.mdx:76,91 -- Fixed-on-spot (curatedOnly added to skill-counts.mjs; identity curatedOnly + catalogRows === directories now asserted)
  - [HIGH] Two pages carried stale claims that the guard did not cover -- guides/maintainer.mdx said '92 skills, 9 agents' and concepts/faq.md said '76 shortcut skills' plus 'and 73 others' -- site/src/content/docs/guides/maintainer.mdx:361 -- Fixed-on-spot (faq.md is SYNCED from docs/faq.md so the upstream was corrected and the synced copy committed with it; CLAIM_PAGES extended to all 7 claim-bearing pages and a new case walks all of docs/ to fail on any unguarded roster claim)
---

## Dispatch Log

<!-- AUTHORED -- appended by the dispatcher on subagent completion (L1+L2+L3 traceability). -->

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
