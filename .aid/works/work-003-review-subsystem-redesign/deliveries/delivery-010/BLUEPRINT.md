# Delivery BLUEPRINT -- delivery-010: Boilerplate split and aid-screener

> **Delivery:** delivery-010
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Split the shared agent boilerplate so a new cheap screening agent does not inherit an
exhaustiveness mandate, and add that agent. Kept as its own delivery because its success criterion
is an **empty diff** -- uniquely cheap to verify and uniquely dangerous to bundle with anything else.

## Scope

- `agent-discipline-boilerplate.md` carrying the self-review discipline block; `agent-boilerplate.md`
  reduced to the heartbeat protocol.
- Two `{{include:}}` tokens in each of the nine existing agents, rendering byte-identically.
- The new `aid-screener` agent: small tier, `Read, Glob, Grep`, no `Bash`, and a
  counter-instruction body rather than a subset of the reviewer's.
- Roster growth 9 -> 10: the tiering table row, and the 21 count assertions the CI doc-count gate
  enforces across 13 surfaces.

**Out of scope:** the two review skills (delivery-012); the `aid-reviewer` body rewrite
(delivery-011).

## Gate Criteria

- [ ] Re-rendering all seven trees produces **only** `aid-screener` additions -- any other diff
      means the split changed a rendered body
- [ ] The screener's rendered body grants `Read, Glob, Grep` and not `Bash`, in every tree
- [ ] The screener does **not** carry the exhaustiveness mandate, while `aid-reviewer` does -- a
      difference that must exist in every tree
- [ ] The doc-count gate still passes, with the agent count at 10
- [ ] The Codex TOML render of the new agent parses
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-011, delivery-012

## Notes

**Enabling, not standalone-functional.** The split's byte-identity was proven at Specify by
round-tripping the renderer's own concatenation, which is why the gate is a diff assertion rather
than a behavioural test.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | REFACTOR | 1 | The boilerplate split, alone |
| task-002 | IMPLEMENT | 2 | aid-screener |
| task-003 | CONFIGURE | 3 | Roster nine to ten |
