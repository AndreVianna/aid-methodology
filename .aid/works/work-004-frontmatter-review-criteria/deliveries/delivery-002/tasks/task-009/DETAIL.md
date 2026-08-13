# task-009: Walk and type the canonical trees; author per-file blocks where warranted

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-002

**Depends on:** task-008

**Scope:**
- Walk the canonical-tree slice of the 290-file population: `canonical/skills/*/SKILL.md` (76),
  `canonical/skills/*/references/*.md` (110), `canonical/agents/*/AGENT.md` (9), and
  `canonical/aid/templates/**` (the in-scope templates), **excluding `reviewer-ledger-schema.md`**, whose
  existing declaration is verified by task-010 and whose key rename is done by task-011 — this task does
  not touch it.
- Resolve each file to exactly one document type via the registry (task-001).
- Write a `review-criteria:` block **only** where a file has a criterion or exclusion its type does not
  already cover. A block restating a type-level criterion is a defect, not a completion. Generator-
  refreshed `SKILL.md` and payload-carrying templates get **no** file-level block.

*Session-fit note:* this is a **mechanical pass**, not ~273 individual judgment calls — the registry
selector (task-001) is exhaustive by construction, so typing is deterministic and most files get no
block (the exceptions are few). The work is: resolve type per file, add a block only at the rare
exception, spot-check. It fits one session on that basis; if the exception set turns out large, split by
tree (`references/*.md`, then `SKILL.md`/`AGENT.md`, then templates).

**Acceptance Criteria:**
- [ ] Every walked file resolves to exactly one type; none untyped.
- [ ] No authored block restates a global or type-level criterion; every entry is derivable from the
      repo alone (NFR-5).
- [ ] Generator-refreshed `SKILL.md` and payload templates carry no file-level block.
- [ ] The count of files that gained a block is reported (an output, not a target).
- [ ] This task's canonical-tree slice reports its per-bucket counts, to feed task-010's delivery-wide
      290 reconciliation (BLUEPRINT Gate 2 / SPEC AC-1).
- [ ] All §6 quality gates pass.
