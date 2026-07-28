# Delivery BLUEPRINT -- delivery-011: aid-reviewer rewrite

> **Delivery:** delivery-011
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Rewrite the reviewer's body for a two-agent world and confirm that the six upstream deliveries left
it in its intended state. Sequenced last on the spine because it is the only delivery that must see
every prior edit to that file already landed.

## Scope

- The residual body edits: the opening role statement, the `## Tasks State` write-target defect, the
  source-authority and cross-reference lines re-anchored to the catalog, the severity-tagging
  instruction that still says the reviewer assigns severity, and a new depth-and-division-of-labour
  section.
- `README.md`: the tier claim that contradicts the canonical frontmatter, and the assertion that the
  discipline block is present uniformly.
- The nine-item verify-do-not-redo conformance check, asserted against content anchors rather than
  line numbers.

**Out of scope:** anything the six upstream spine deliveries own -- this delivery verifies those,
it does not redo them.

## Gate Criteria

- [ ] All nine verify-do-not-redo assertions hold; a failure is reported against the upstream
      delivery that owns it, not fixed here
- [ ] No local severity table, no "established best practice", no `## File Writing`, no heredoc
      write, no phantom `content-isolation.md` citation
- [ ] The body names the deep/screen division and states that a screening result never substitutes
      for a graded pass
- [ ] The README tier matches the canonical frontmatter
- [ ] Five-profile render parity re-verified
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-009, delivery-010
- **Blocks:** -- (none)

## Notes

**Spine delivery, and its terminus.** The conformance check is the work's proof that the
region-ownership arithmetic held across seven deliveries.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | The FR-A10 residual rewrite |
| task-002 | DOCUMENT | 1 | README corrections |
| task-003 | TEST | 2 | The conformance check |
