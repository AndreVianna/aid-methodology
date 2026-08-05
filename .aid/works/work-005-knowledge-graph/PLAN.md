# Plan -- Knowledge Relationship Graph

## Deliverables

**One delivery, by owner decision (2026-08-05).** The previous six-delivery sequence --
Research Foundation, Relationship Table, KB Gap Ledger, Accessible View, Interactive Graph,
Ship Gate -- is retired, and its 96 tasks are discarded rather than re-parented (STATE.md Q24
items 10-11): the re-spec changed feature shapes, so re-parenting would carry stale DETAIL
content into a structure it was not written for.

### delivery-001: Knowledge Relationship Graph
- **What it delivers:** the whole of work-005 -- the `/aid-graph` skill and everything it needs
  to build, validate, report on and render a knowledge relationship graph for an AID project:
  the relation vocabulary and rendering decision, the ten-column `relationships.md` and its
  validator, source/media/external enumeration, the two extraction passes, the Knowledge-Base
  gap ledger, the `graph.html` shell with its lens/view-model layer, the interactive canvas and
  the accessible peer table, the eleven-state skill runtime with the FR-28 gate, canonical
  registration across all five host profiles, and the suites, docs and Knowledge Base updates.
- **Features:** all thirteen -- feature-001-relation-vocabulary-research,
  feature-002-graph-rendering-research, feature-003-relationship-table-schema,
  feature-004-source-enumeration, feature-005-two-pass-extraction, feature-006-kb-gap-ledger,
  feature-007-graph-view-shell, feature-008-interactive-graph-canvas,
  feature-009-accessible-table-view, feature-010-aid-graph-skill-runtime,
  feature-011-validator-parameterisation, feature-012-canonical-registration,
  feature-013-tests-and-docs
- **Depends on:** --
- **Priority:** Must

**What collapsing the sequence costs, stated rather than glossed.** The old boundaries were not
decoration: they guaranteed that a stall in the rendering research could not stop
`relationships.md` and the gap ledger from shipping, and they sequenced three criteria that are
mutual obligations between features. With one delivery those guarantees move from delivery
ordering into **task ordering**, and the affected criteria all close in this one gate:

| Was sequenced by delivery order | Now |
|---|---|
| FR-28's `R*` data checks (old delivery-002) then its `V*` view checks (old delivery-006) | The full rubric closes once, in this delivery's gate, over both artifacts |
| AC-15 across features 006 / 007 / 008 | Closes here; still needs every half evidenced, not one half plus an assumption |
| AC-9 across features 009 / 008 | Same |
| The feature-001 -> 003/005 and feature-002 -> 008/011/012 blocking edges | Task-graph edges now; see the delivery BLUEPRINT's Dependencies table |

## Cross-Cutting Risks

> **Read every `delivery-00N` below as a reference to the RETIRED six-delivery sequence.** These
> seven risks were analysed against it and their substance is unchanged, so they are preserved
> verbatim rather than reworded — mechanically substituting "this delivery" 34 times would have
> distorted claims that turn on *relative order* ("the approved order already places delivery-003
> before delivery-004"), and a distorted risk is worse than a dated one. **Only the sequencing
> vocabulary is historical.** Every mitigation that was to be enforced by a delivery boundary is now
> enforced by **task ordering inside delivery-001**, against the edges listed in
> `deliveries/delivery-001/BLUEPRINT.md` § Dependencies; and every gate that a boundary used to
> place — FR-28's split rubric, AC-9, AC-15 — now closes in this delivery's single gate, as the
> table above records. Risk 2's premise is the sharpest case: it warns that FR-28 "cannot close" in
> the delivery holding feature-010 because the view artifacts arrive later. With one delivery that
> particular hazard is dissolved, but its underlying obligation is not — the `V*` checks still need
> the view artifacts to exist before the gate runs, which is now a task-order constraint.

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **Q8 — ledger retention blocks FR-26.** `reviewer-ledger-schema.md` § "Lifecycle (per skill invocation)" has the orchestrator delete the ledger at skill DONE. FR-26 makes the gap ledger `/aid-graph`'s *deliverable*, so under the current lifecycle the skill emits its findings and then destroys them. This is not hypothetical: `/aid-define`'s DONE state deleted this work's own cross-reference ledger as designed. feature-006 D7 specifies the fix as a named retention carve-out written **into the shared schema**, which is a methodology-level change outside work-005. | H | Split the ledgers by file so the graded one and the delivered one cannot be conflated (feature-006 D7: `graph.md` graded and deleted at DONE; `graph-kb-gaps.md` never graded and retained). Record the schema amendment as an **external dependency on delivery-003** in that delivery's gate criteria: delivery-003 cannot fully satisfy FR-26 until it lands. Raise it as its own work rather than absorbing it here. |
| 2 | **feature-010 spans every deliverable.** Its Dependency position states it "should be specified early and closed last": it invokes features 004 and 005, writes the artifacts features 003 and 007 define, and owns FR-28's rubric and gate orchestration. It is assigned to delivery-002, but its `V-*` view checks have no artifact to run against until delivery-004/005, so FR-28 cannot close there — and a change in any later deliverable can reopen it. | H | Scope delivery-002's gate to the `R*` data checks (AC-1–AC-4, AC-18) plus AC-11/AC-12/AC-13, and state explicitly in delivery-002's BLUEPRINT that FR-28 does not fully close there. delivery-006's gate is where the full rubric — data checks **and** view checks — closes over both artifacts for the first time. |
| 3 | **Skill-count and lockstep residue.** Registering the **77th** skill turns eleven `${SKILLS}`-parameterised assertions in `tests/canonical/test-doc-counts.sh` red — and the mechanism is worth stating correctly, because the obvious reading is wrong: `SKILLS` is **derived** at `:44` (`find canonical/skills -mindepth 1 -maxdepth 1 -type d | wc -l`), not a literal, so what goes stale is the eleven **documentation phrases** it is compared against at `:66–:93`, never the derivation. Re-measured on this branch after work-004's alias retirement landed: **76** skill directories, so this row's original "112th skill / `SKILLS=111`" figures are pre-merge and were replaced rather than bumped. The eleven-assertion count and the five-README split both re-verified and unchanged. It also touches five hand-maintained `profiles/<tool>/README.md` files that sit **inside** generated trees but are not emitted by the generator — `README` matches zero records in all five `emission-manifest.jsonl` files, so they survive the render and must be hand-edited. Concentrated in delivery-002 via feature-012. The Knowledge Base records this failure mode as tech-debt **L4** — the test-effectiveness gap whose proof case is the `io_bounds.py` incident, in which "five install manifests plus two installer-test lists all asserted each other and 'passed' while every one of them was missing a shipped, security-relevant file. The tests ran; they did not bite." That is why feature-013 exists as a feature and not a checklist. | M | feature-012 owns the reconciliation in delivery-002 and its acceptance criterion requires every count or roster assertion to compare a derived artifact to the source of truth rather than to a sibling literal — L4's own invariant-anchoring remedy. Two of the surfaces fail hard (`gen-reference.mjs`'s `[gen-reference] skills drift` throw and `gen-reference.test.mjs`'s `CURATED_SKILL_NAMES` length assertion), so they cannot be silently missed. delivery-006's registration suite then re-asserts every tree against the canonical source. |
| 4 | **Q6 — FR-22's ignore list needs a settings section that does not exist.** Neither `.aid/settings.yml` nor its template declares one. feature-004 introduces `graph.ignore` read via `read-setting.sh --path graph.ignore --default ''`. The live file declares `format_version: 3` (verified), so adding a new top-level section raises whether a version bump is required and what reconcile rule applies to installs that predate it. Lands in delivery-002 via feature-004; feature-004 Open Item 1 routes the decision to the skill-wiring feature rather than answering it. | M | Decide the bump-and-reconcile question inside delivery-002, before feature-004's implementation task, alongside feature-010's skill wiring. `--default ''` means an absent section is not an error, so enumeration degrades to "no ignore list" rather than failing — which bounds the blast radius to completeness, not correctness. `/aid-config` and `tests/canonical/test-reconcile-scenarios.sh` already cover the reconcile ground. |
| 5 | **Q7 — real-world `ext:` resolution needs an entry format that does not exist.** `.aid/knowledge/external-sources.md` has zero registered entries and states so in prose, with a placeholder `- (none)` in its `sources:` frontmatter; it carries no machine-readable entry shape. feature-003 D2c specifies a table form the resolver reads, but `/aid-graph` may not author it under FR-10, and the file's writer is `/aid-discover`'s ELICIT state. Lands in delivery-002 via feature-003. | M | Q4 is already resolved to a self-built synthetic fixture (A-6), so AC-1's `ext:` branch is proven to fire in test regardless — this is a **production-completeness** risk, not a test blocker. delivery-002's gate accepts the fixture as the AC-1 `ext:` evidence and records the upstream ELICIT change as a candidate follow-on outside this work. |
| 6 | **The rendering decision's blast radius arrives late.** feature-002 completes in delivery-001, so the recommendation is *known* before delivery-002 — but the code that exercises it is spread across three later deliveries. feature-012's dependency-packaging criterion (private, unpublished, exactly pinned, lockfiled, monitored, licence-recorded) fires in delivery-002 only if a third-party dependency is adopted; feature-011's carve-outs are contingent the same way (`S2` only under CDN packaging, `validate-visuals.mjs` T2 only for an SVG live surface — feature-007 Open Item 4) and cannot actually be exercised until `graph.html` exists in delivery-004; and feature-008's size in delivery-005 swings substantially on the answer, with its runtime prerequisites feeding back into AC-6, which delivery-004 already closed. | M | Sequence delivery-001 first so the recommendation is in hand before any packaging or validator work is scoped, and require the decision record's runtime-prerequisite statement to be written as prose AC-6 can be checked against. Do not size feature-008 before delivery-001 lands (feature-008's own Dependency position says so). Treat delivery-005's prerequisite declaration as a re-check against delivery-004's documented prerequisites rather than as new work. |
| 7 | **Three acceptance criteria are mutual obligations split across delivery boundaries.** AC-15 is owned by feature-006 in delivery-003 but its view side is feature-007 (delivery-004) and its graph side feature-008 (delivery-005), and every one of those SPECs states that neither owner may consider it met alone — so AC-15 cannot close before delivery-005. AC-9 is owned by feature-009 in delivery-004 while its reduced-motion clause is feature-008's in delivery-005, so it cannot fully close before delivery-005 either. AC-7 is shared between features 007 and 009, both in delivery-004, so it is the one that closes inside a single delivery. | M | Name the co-owner and the closing delivery in each affected BLUEPRINT's gate criteria rather than letting a gate silently pass on a half-met criterion. delivery-003 and delivery-004 record their halves as satisfied-but-not-closed; delivery-005's gate is where AC-9 and AC-15 close overall. feature-007's lens view-model is the mechanism that makes the parity checkable rather than asserted, and its `tests/canonical/test-graph-view-shell.sh` GV-series carries the assertions. |

## Execution Graph

> Derived mechanically from each task's `**Depends on:**` line by
> `.aid/.temp/build-graphs.py`, per
> `aid-detail/references/execution-graph-generation.md`.

**Empty until `aid-detail` populates the task set.** The six per-delivery graphs that stood here
were derived from the 96 discarded tasks and are removed rather than left to describe a structure
that no longer exists -- a stale graph is worse than an absent one, because it reads as authority.

With a single delivery every dependency edge is intra-delivery, so wave numbers are computed over
the whole task set and nothing is satisfied implicitly by delivery ordering. The edges that used
to be delivery boundaries are listed in `deliveries/delivery-001/BLUEPRINT.md` § Dependencies and
must appear as real `**Depends on:**` lines in the regenerated tasks.
