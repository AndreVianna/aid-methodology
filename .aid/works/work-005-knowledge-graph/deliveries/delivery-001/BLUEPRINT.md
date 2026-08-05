# Delivery BLUEPRINT -- delivery-001: Knowledge Relationship Graph

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-001
> **Work:** work-005-knowledge-graph
> **Created:** 2026-07-28 (single-delivery restructure 2026-08-05)

---

## Objective

Deliver the whole of work-005 as **one** delivery: the `/aid-graph` skill and everything it needs
to build, validate, report on and render a knowledge relationship graph for an AID project.

**This is a single-delivery work by owner decision (2026-08-05), replacing the previous six-delivery
sequence.** The earlier structure split the work into Research Foundation, Relationship Table, KB
Gap Ledger, Accessible View, Interactive Graph and Ship Gate. That split is retired: all thirteen
features land in this one delivery, and its 96 tasks are discarded rather than re-parented, per
STATE.md Q24 items 10-11.

**Recorded deviation from `aid-plan`'s core principle, carried forward from the retired
delivery-001.** `aid-plan` wants every deliverable to be a functional MVP usable without the next
one. With a single delivery that principle is satisfied trivially at the delivery boundary — there
is no "next one" — but it is worth stating that the property no longer does any work for us
*inside* the delivery. The old sequence bought a real guarantee: a stall in the rendering research
could not stop `relationships.md` and the gap ledger from shipping. That guarantee is now gone, and
the mitigation moves into task ordering rather than delivery ordering — the dependency edges that
used to be delivery boundaries are still real and are recorded in Dependencies below.

## Scope

**In scope — all thirteen features:**

| Feature | What it contributes |
|---|---|
| feature-001-relation-vocabulary-research | The closed relation/inverse vocabulary at `canonical/aid/templates/graph/relation-vocabulary.yml` (FR-4-FR-6, D-1) |
| feature-002-graph-rendering-research | The rendering-approach decision with its runtime prerequisites stated explicitly (FR-18, D-2, Q2) |
| feature-003-relationship-table-schema | The ten-column table schema, the loaders, and `validate-relationships.sh` |
| feature-004-source-enumeration | Source, media and external-page enumeration by structural significance |
| feature-005-two-pass-extraction | The two extraction passes and `build-relationships.sh` |
| feature-006-kb-gap-ledger | Gap detection over the enumerated node set, reported as a 7-column ledger and routed onward |
| feature-007-graph-view-shell | The `graph.html` shell and the lens/view-model layer both renderings consume |
| feature-008-interactive-graph-canvas | The interactive graph canvas |
| feature-009-accessible-table-view | The accessible peer table view at WCAG AA |
| feature-010-aid-graph-skill-runtime | The eleven-state skill runtime, the FR-28 rubric and `grade-graph.sh` |
| feature-011-validator-parameterisation | The validator carve-outs the new artifacts require |
| feature-012-canonical-registration | Canonical registration and the render across all five host profiles |
| feature-013-tests-and-docs | Test suites, documentation surfaces and the Knowledge Base updates |

**Out of scope:** everything the feature SPECs place outside their own boundaries, unchanged by this
restructure. In particular the `reviewer-ledger-schema.md` retention carve-out (Cross-Cutting Risk
1) remains an external dependency raised as its own work, not absorbed here.

## Gate Criteria

The work-level acceptance criteria in `REQUIREMENTS.md` are the gate; collapsing six deliveries into
one removes the intermediate gates but not a single criterion. Three consequences are worth naming
because the retired structure used delivery boundaries to sequence them:

- [ ] **FR-28 closes once, here.** Under the old sequence its `R*` data checks closed in
      delivery-002 and its `V*` view checks in delivery-006. With one delivery the full rubric —
      data checks and view checks — closes over both artifacts in this delivery's gate.
- [ ] **AC-9 and AC-15 close once, here.** Both were mutual obligations split across delivery
      boundaries (AC-15 across features 006/007/008, AC-9 across features 009/008), and neither
      owner could consider them met alone. That hazard is dissolved by the single boundary, but each
      criterion still needs both halves evidenced, not one half plus an assumption.
- [ ] **The full canonical suite passes**, including this work's own suites, with every suite inside
      `tests/run-all.sh`'s per-suite `timeout 300`. **Known risk, measured and unresolved:** on a
      Windows dev shell `test-graph-extraction.sh` runs 783s and `test-graph-runtime-gate.sh` 318s,
      both over that budget. Linux CI spawns cost ~100x less so they may pass comfortably, but the
      margin is unmeasured and `timeout 300` is a hard kill. Settle it with a CI run, not by
      inference from a dev machine.
- [ ] Every feature's own acceptance criteria met, at the `minimum_grade: B-` floor this work
      records in STATE.md frontmatter.

## Tasks

**Populated by `aid-detail`.** The previous 96 tasks across six deliveries are discarded, not
re-parented — the re-spec changed feature shapes, so re-parenting would carry stale DETAIL content
into a structure it was not written for.

The Execution Graph in `PLAN.md` is derived mechanically from each task's `**Depends on:**` line, so
it cannot be rebuilt until this section is populated.

## Dependencies

**External to the work:** the ledger-retention schema amendment (Cross-Cutting Risk 1) — FR-26 is
not fully satisfiable until it lands.

**Internal, and still load-bearing.** These were delivery-ordering edges; with one delivery they
become task-ordering edges and must be honoured by the task graph rather than by delivery sequence:

| Edge | Why it holds |
|---|---|
| feature-001 before features 003, 005 | Neither can validate an inverse pair or type a row without the vocabulary |
| feature-002 before features 008, 011, 012 | It sizes feature-008 outright, and conditions feature-011's carve-outs and feature-012's dependency packaging |
| features 004, 005 before feature-006 | The gap ledger runs over the enumerated node set |
| feature-006 before feature-007 | feature-007's `GV02`/`GV04`/`GV08` assert against `coverage-predicate.mjs`, and its Coverage lens verifies against the `kb_gaps` record feature-006 writes |
| feature-007 before features 008, 009 | Both mount into its shell and consume its view model |
| feature-010 spans everything | It invokes features 004 and 005, writes the artifacts features 003 and 007 define, and owns the FR-28 gate — specified early, closed last |
| feature-013 last | It asserts over every artifact the other twelve produce |

## Notes

**The coverage-notes hand-off is a task, not an open question.** feature-010 assembles the section
into `.aid/.temp/graph/coverage-notes.md` (its D7) and feature-005's step 15 renders "the
`## Coverage notes` section assembled by feature-010". The SPECs agree. The implementation does not
yet: `build-relationships.sh` re-renders the section itself via `br_render_coverage()` and
references that path zero times. Fix it in this delivery by making the renderer consume the
hand-off; it is not a specification gap.

**Suite structure and run cadence.** Task authoring follows the S1-S5 and T1-T6 conventions now
recorded in `.aid/knowledge/test-landscape.md`, including the `# COVERS:` manifest that lets
`tests/canonical/select-suites.sh` run only the suites a change can affect. The mutation-harness
cost defect is tech-debt W5-4 and is deliberately not fixed inside this work.
