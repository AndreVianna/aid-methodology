# Delivery SPEC -- delivery-001: Elicitation Research Spike

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-001
> **Work:** work-001-aid-interview-improvements
> **Created:** 2026-06-27

---

## Objective

Produce the research foundation that features 002-005 depend on: a structured `findings.md` that
catalogues the techniques seasoned analysts use for Requirements Elicitation and Domain Discovery,
evaluates them against AID's interview context, and lands an explicit consumption contract that the
downstream "seasoned-analyst" engine, greenfield-seed authoring, guided-triage, and build-time
conformance features can build on. This is scoped as a distinct unit because it is a pure
investigation with no production-code output, and it is the P0 gate that unblocks the deferred
content features -- de-risking their design before any of them is specified.

## Scope

- feature-001-elicitation-research-spike: the RQ-A (seed content) + RQ-B (analyst conversation)
  research plan, covering the 7 elicitation/discovery technique families plus a comparative
  evaluation of the web-trending "grill-me" question-driven approach.
- The `findings.md` deliverable with its consumption contract for features 002-005.

**Out of scope:** any production-code change to the `aid-interview` skill (that is features
002-005); the rename (feature-006); the infra debt (feature-007, delivery-002). No skill behavior
is modified by this delivery -- it only produces research artifacts under `.aid/`.

## Gate Criteria

- [ ] `findings.md` exists and covers RQ-A (seed content) and RQ-B (analyst conversation) with the
  7 technique families + the grill-me comparative, each evaluated against the AID interview context.
- [ ] The consumption contract is explicit: each of features 002-005 can point to the specific
  findings it will consume (no orphaned research, no unmet downstream need).
- [ ] Findings are evidence-grounded (cited sources / reasoning), not unsupported assertion.
- [ ] All section-6 quality gates pass.

## Tasks

{Filled by aid-detail. A SPIKE delivery may resolve to one or a few RESEARCH tasks.}

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** -- (none; foundation)
- **Blocks:** the deferred features 002-005 (specified in a future pass from these findings). No
  in-plan delivery depends on it -- delivery-002 is independent.

## Notes

RESEARCH/SPIKE delivery: produces `.aid/` artifacts only, no branch-bound code change (per
aid-execute, RESEARCH/DOCUMENT tasks that produce only `.aid/` artifacts may skip branch isolation).
The findings drive a future re-specify + re-plan pass for 002-005.
