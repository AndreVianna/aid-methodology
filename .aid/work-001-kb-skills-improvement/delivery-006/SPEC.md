# Delivery SPEC -- delivery-006: Freshness Primitive

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-006/STATE.md.

> **Delivery:** delivery-006
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Close the KB freshness loop at per-document granularity. Building on the `sources:` primitive
(delivery-001, f001), add a deterministic per-doc staleness check that compares each doc's
`sources:` last-changed commit against that doc's `approved_at_commit:` baseline and marks drifted
docs *suspect* -- replacing today's single coarse whole-KB tip-date judgment sweep that nobody runs.
Source changes trigger per-doc suspect flagging, and the dashboard surfaces per-doc freshness in
both readers (replacing the single coarse whole-KB badge) so a doc owner gets an actionable signal:
which doc their change made suspect. The governing principle is auto-detect/flag, never auto-apply --
detection is deterministic, but every change to KB content stays human-gated.

## Scope

In scope:

- **feature-007 -- per-doc freshness loop.** A new canonical KB staleness script
  (`kb-freshness-check.sh`) that, per doc, compares each `sources:` entry's last-changed commit
  against the doc's `approved_at_commit:` and emits a per-doc suspect/fresh/unknown verdict
  (deterministic, git-based); the surfacing of that per-doc verdict in **both** dashboard readers
  (Python + Node), replacing the coarse whole-KB badge; the canonical test suite + CI wiring. An
  un-stamped doc (no `approved_at_commit:`) degrades to verdict `unknown`, never an error.

**Out of scope:** the `sources:`/`approved_at_commit:` schema (delivery-001, f001 -- consumed); the
production of the `approved_at_commit:` stamps for AID's own docs (delivery-003, f011); the
housekeep<->update-kb boundary that *uses* this per-doc staleness as its shared scoping signal
(delivery-008, f010).

## Gate Criteria

- [ ] Given a doc with `sources:`, the staleness check compares each source's last-changed commit
  against the doc's approval commit and marks drifted docs suspect (deterministic). *(f007, AC5)*
- [ ] Given a source change, per-doc suspect flagging is triggered and the dashboard surfaces per-doc
  freshness (replacing the coarse whole-KB badge) in both readers. *(f007, AC5)*
- [ ] Given a suspect doc, freshness auto-detects/flags but never auto-applies -- the update remains
  human-gated. *(f007)*
- [ ] An un-stamped doc degrades to verdict `unknown` (never an error); the check is deterministic
  and CI-asserted; render-drift / KB-hygiene CI green. *(f007)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-007, delivery-008

## Notes

Consumes delivery-001's f001 `sources:` + `approved_at_commit:` schema. The per-doc staleness verdict
this delivery produces is the **shared signal** that delivery-008's f010 uses to scope the
`aid-housekeep` sweep and to distinguish housekeep (global) from update-kb (targeted). It reads the
`approved_at_commit:` stamps delivery-003 produces for AID's own docs, but does not hard-depend on
delivery-003: an un-stamped doc degrades to `unknown`. Both dashboard readers (the Python + Node
twins) must be updated in lockstep for the per-doc surfacing.
