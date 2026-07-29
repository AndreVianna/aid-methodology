# Plan -- Knowledge Relationship Graph

## Deliverables

### delivery-001: Research Foundation
- **What it delivers:** The two decisions that unblock implementation — the closed relation
  vocabulary (FR-4–FR-6, D-1) authored as
  `canonical/aid/templates/graph/relation-vocabulary.yml`, and the rendering-approach
  recommendation (FR-18, D-2, STATE.md Q2) delivered as a decision record naming exactly one
  approach with its runtime prerequisites stated explicitly. **This deliverable is not
  standalone-functional** — it ships two decisions, not a usable capability. See the
  BLUEPRINT objective for the recorded deviation and its reason.
- **Features:** feature-001-relation-vocabulary-research, feature-002-graph-rendering-research
- **Depends on:** --
- **Priority:** Must

### delivery-002: Relationship Table
- **What it delivers:** An installed, rendered `/aid-graph` that emits a validated
  `relationships.md`. The skill is registered canonically and present in all five host profile
  trees; it refuses to run without an approved Knowledge Base, is a no-op on an unchanged
  project, never writes a Knowledge Base file, enumerates the project source by structural
  significance, and emits an eight-column table whose ids resolve, whose relation pairs are
  valid inverses, whose rows are unique and provenance-stamped, and whose deterministic
  majority is byte-identical across runs. Usable with no view at all — the table is readable
  as markdown and routable by agents (§10 deliverable 2).
- **Features:** feature-012-canonical-registration, feature-011-validator-parameterisation,
  feature-003-relationship-table-schema, feature-004-source-enumeration,
  feature-005-two-pass-extraction, feature-010-aid-graph-skill-runtime
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-003: KB Gap Ledger
- **What it delivers:** Gap detection over feature-004's enumerated node set, reported as a
  7-column reviewer ledger at `.aid/.temp/review-pending/graph-kb-gaps.md` with the offending
  `int:` node as evidence, and routed onward to `/aid-update-kb` / `/aid-housekeep`. The run
  never fails because gaps exist. This is the Knowledge-Base *quality* signal §2 item 1 exists
  to produce.
- **Features:** feature-006-kb-gap-ledger
- **Depends on:** delivery-002
- **Priority:** Must

### delivery-004: Accessible View
- **What it delivers:** The `graph.html` shell, the lens/view-model layer that both renderings
  consume, and the accessible peer table view — sortable, filterable, keyboard-navigable,
  screen-reader usable at WCAG AA. Four preset lenses over one data path, with manual controls
  live throughout. Useful on its own: for the verification work this artifact exists to
  support, a filterable list of gap rows is often the better tool than a picture.
- **Features:** feature-007-graph-view-shell, feature-009-accessible-table-view
- **Depends on:** delivery-002, delivery-003
- **Priority:** Should
- **Note on the delivery-003 edge:** this dependency is a **consequence of the owner's decision to
  create `coverage-predicate.mjs` in delivery-003** rather than here. feature-007's `GV02`, `GV04`
  and `GV08` assert against that module, and its Coverage lens verifies against the `kb_gaps` record
  feature-006 writes — so the view genuinely needs the ledger deliverable, not just the table. The
  decision traded a view→ledger edge for removing a ledger→view edge, which is the better trade
  because it unblocks the ledger from the entire view layer; and the approved order already places
  delivery-003 before delivery-004, so nothing reorders. Declared here rather than left implicit,
  since feature-006's own Dependency position names only features 004 and 005.

### delivery-005: Interactive Graph
- **What it delivers:** The interactive graph canvas mounted in delivery-004's shell and drawn
  by whatever delivery-001's rendering research recommended — layout, grouping, density, zoom
  and pan, with reduced-motion settling, keyboard equivalents, and meaning never carried by
  colour alone.
- **Features:** feature-008-interactive-graph-canvas
- **Depends on:** delivery-001, delivery-004
- **Priority:** Should

### delivery-006: Ship Gate
- **What it delivers:** Test suites, documentation surfaces, and Knowledge Base entries — the
  single place to ask "is this finished?". Discoverability across the four surfaces a newcomer
  looks at, a registration suite that compares every rendered tree to the canonical source, a
  green full canonical suite run locally, and a Knowledge Base that describes the toolkit that
  now exists.
- **Features:** feature-013-tests-and-docs
- **Depends on:** delivery-001, delivery-002, delivery-003, delivery-004, delivery-005
- **Priority:** Must

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **Q8 — ledger retention blocks FR-26.** `reviewer-ledger-schema.md` § "Lifecycle (per skill invocation)" has the orchestrator delete the ledger at skill DONE. FR-26 makes the gap ledger `/aid-graph`'s *deliverable*, so under the current lifecycle the skill emits its findings and then destroys them. This is not hypothetical: `/aid-define`'s DONE state deleted this work's own cross-reference ledger as designed. feature-006 D7 specifies the fix as a named retention carve-out written **into the shared schema**, which is a methodology-level change outside work-005. | H | Split the ledgers by file so the graded one and the delivered one cannot be conflated (feature-006 D7: `graph.md` graded and deleted at DONE; `graph-kb-gaps.md` never graded and retained). Record the schema amendment as an **external dependency on delivery-003** in that delivery's gate criteria: delivery-003 cannot fully satisfy FR-26 until it lands. Raise it as its own work rather than absorbing it here. |
| 2 | **feature-010 spans every deliverable.** Its Dependency position states it "should be specified early and closed last": it invokes features 004 and 005, writes the artifacts features 003 and 007 define, and owns FR-28's rubric and gate orchestration. It is assigned to delivery-002, but its `V-*` view checks have no artifact to run against until delivery-004/005, so FR-28 cannot close there — and a change in any later deliverable can reopen it. | H | Scope delivery-002's gate to the `R*` data checks (AC-1–AC-4, AC-18) plus AC-11/AC-12/AC-13, and state explicitly in delivery-002's BLUEPRINT that FR-28 does not fully close there. delivery-006's gate is where the full rubric — data checks **and** view checks — closes over both artifacts for the first time. |
| 3 | **Skill-count and lockstep residue.** Registering the 112th skill turns eleven `${SKILLS}`-parameterised assertions in `tests/canonical/test-doc-counts.sh` red (`SKILLS=111` today, verified on the branch) and touches five hand-maintained `profiles/<tool>/README.md` files that sit **inside** generated trees but are not emitted by the generator — `README` matches zero records in all five `emission-manifest.jsonl` files, so they survive the render and must be hand-edited. Concentrated in delivery-002 via feature-012. The Knowledge Base records this failure mode as tech-debt **L4** — the test-effectiveness gap whose proof case is the `io_bounds.py` incident, in which "five install manifests plus two installer-test lists all asserted each other and 'passed' while every one of them was missing a shipped, security-relevant file. The tests ran; they did not bite." That is why feature-013 exists as a feature and not a checklist. | M | feature-012 owns the reconciliation in delivery-002 and its acceptance criterion requires every count or roster assertion to compare a derived artifact to the source of truth rather than to a sibling literal — L4's own invariant-anchoring remedy. Two of the surfaces fail hard (`gen-reference.mjs`'s `[gen-reference] skills drift` throw and `gen-reference.test.mjs`'s `CURATED_SKILL_NAMES` length assertion), so they cannot be silently missed. delivery-006's registration suite then re-asserts every tree against the canonical source. |
| 4 | **Q6 — FR-22's ignore list needs a settings section that does not exist.** Neither `.aid/settings.yml` nor its template declares one. feature-004 introduces `graph.ignore` read via `read-setting.sh --path graph.ignore --default ''`. The live file declares `format_version: 3` (verified), so adding a new top-level section raises whether a version bump is required and what reconcile rule applies to installs that predate it. Lands in delivery-002 via feature-004; feature-004 Open Item 1 routes the decision to the skill-wiring feature rather than answering it. | M | Decide the bump-and-reconcile question inside delivery-002, before feature-004's implementation task, alongside feature-010's skill wiring. `--default ''` means an absent section is not an error, so enumeration degrades to "no ignore list" rather than failing — which bounds the blast radius to completeness, not correctness. `/aid-config` and `tests/canonical/test-reconcile-scenarios.sh` already cover the reconcile ground. |
| 5 | **Q7 — real-world `ext:` resolution needs an entry format that does not exist.** `.aid/knowledge/external-sources.md` has zero registered entries and states so in prose, with a placeholder `- (none)` in its `sources:` frontmatter; it carries no machine-readable entry shape. feature-003 D2c specifies a table form the resolver reads, but `/aid-graph` may not author it under FR-10, and the file's writer is `/aid-discover`'s ELICIT state. Lands in delivery-002 via feature-003. | M | Q4 is already resolved to a self-built synthetic fixture (A-6), so AC-1's `ext:` branch is proven to fire in test regardless — this is a **production-completeness** risk, not a test blocker. delivery-002's gate accepts the fixture as the AC-1 `ext:` evidence and records the upstream ELICIT change as a candidate follow-on outside this work. |
| 6 | **The rendering decision's blast radius arrives late.** feature-002 completes in delivery-001, so the recommendation is *known* before delivery-002 — but the code that exercises it is spread across three later deliveries. feature-012's dependency-packaging criterion (private, unpublished, exactly pinned, lockfiled, monitored, licence-recorded) fires in delivery-002 only if a third-party dependency is adopted; feature-011's carve-outs are contingent the same way (`S2` only under CDN packaging, `validate-visuals.mjs` T2 only for an SVG live surface — feature-007 Open Item 4) and cannot actually be exercised until `graph.html` exists in delivery-004; and feature-008's size in delivery-005 swings substantially on the answer, with its runtime prerequisites feeding back into AC-6, which delivery-004 already closed. | M | Sequence delivery-001 first so the recommendation is in hand before any packaging or validator work is scoped, and require the decision record's runtime-prerequisite statement to be written as prose AC-6 can be checked against. Do not size feature-008 before delivery-001 lands (feature-008's own Dependency position says so). Treat delivery-005's prerequisite declaration as a re-check against delivery-004's documented prerequisites rather than as new work. |
| 7 | **Three acceptance criteria are mutual obligations split across delivery boundaries.** AC-15 is owned by feature-006 in delivery-003 but its view side is feature-007 (delivery-004) and its graph side feature-008 (delivery-005), and every one of those SPECs states that neither owner may consider it met alone — so AC-15 cannot close before delivery-005. AC-9 is owned by feature-009 in delivery-004 while its reduced-motion clause is feature-008's in delivery-005, so it cannot fully close before delivery-005 either. AC-7 is shared between features 007 and 009, both in delivery-004, so it is the one that closes inside a single delivery. | M | Name the co-owner and the closing delivery in each affected BLUEPRINT's gate criteria rather than letting a gate silently pass on a half-met criterion. delivery-003 and delivery-004 record their halves as satisfied-but-not-closed; delivery-005's gate is where AC-9 and AC-15 close overall. feature-007's lens view-model is the mechanism that makes the parity checkable rather than asserted, and its `tests/canonical/test-graph-view-shell.sh` GV-series carries the assertions. |

## Execution Graphs

> Derived mechanically from each task's `**Depends on:**` line by
> `.aid/.temp/build-graphs.py`, per
> `aid-detail/references/execution-graph-generation.md`. Waves are computed over
> **intra-delivery** edges only — a dependency on an earlier delivery's task is satisfied by
> delivery ordering and does not inflate the wave number. Cross-delivery edges are listed in
> the Depends On column for traceability.

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | — |
| task-004 | task-003 |
| task-005 | task-004 |

| Can Be Done In Parallel |
|------------------------|
| task-001, task-003 |
| task-002, task-004 |

```wave-map
delivery: 001
wave 1: task-001, task-003
wave 2: task-002, task-004
wave 3: task-005
```

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-006 | — |
| task-007 | — |
| task-008 | task-007 |
| task-009 | task-007 |
| task-010 | task-007 |
| task-011 | task-010 |
| task-012 | task-007 |
| task-013 | task-006 |
| task-014 | — |
| task-015 | task-002, task-014 |
| task-016 | task-014, task-015 |
| task-017 | — |
| task-018 | task-017 |
| task-019 | task-018 |
| task-020 | task-015 |
| task-021 | task-014, task-020 |
| task-022 | task-019, task-020 |
| task-023 | task-014, task-016, task-021, task-022 |
| task-024 | task-023 |
| task-025 | task-007, task-024 |
| task-026 | task-007 |
| task-027 | task-019 |
| task-028 | — |
| task-029 | task-016 |
| task-030 | task-007, task-026, task-027, task-029 |
| task-031 | task-007, task-019, task-023, task-024 |
| task-032 | task-019 |
| task-033 | task-019, task-021, task-032 |
| task-034 | task-015 |
| task-035 | task-016 |
| task-036 | task-021 |
| task-037 | task-022 |
| task-038 | task-023, task-024 |
| task-039 | task-024 |
| task-040 | task-026 |
| task-041 | task-027 |
| task-042 | task-028 |
| task-043 | task-029, task-040 |
| task-044 | task-008, task-009, task-013, task-016, task-019, task-024, task-025, task-028, task-029, task-030, task-031 |

| Can Be Done In Parallel |
|------------------------|
| task-006, task-007, task-014, task-017, task-028 |
| task-008, task-009, task-010, task-012, task-013, task-015, task-018, task-026, task-042 |
| task-011, task-016, task-019, task-020, task-034, task-040 |
| task-021, task-022, task-027, task-029, task-032, task-035 |
| task-023, task-030, task-033, task-036, task-037, task-041, task-043 |
| task-025, task-031, task-038, task-039 |

```wave-map
delivery: 002
wave 1: task-006, task-007, task-014, task-017, task-028
wave 2: task-008, task-009, task-010, task-012, task-013, task-015, task-018, task-026, task-042
wave 3: task-011, task-016, task-019, task-020, task-034, task-040
wave 4: task-021, task-022, task-027, task-029, task-032, task-035
wave 5: task-023, task-030, task-033, task-036, task-037, task-041, task-043
wave 6: task-024
wave 7: task-025, task-031, task-038, task-039
wave 8: task-044
```

### delivery-003 execution graph

| Task | Depends On |
|------|-----------|
| task-045 | task-002, task-015 |
| task-046 | task-019, task-023, task-045 |
| task-047 | task-046 |
| task-048 | — |
| task-049 | task-048 |
| task-050 | task-007, task-047 |
| task-051 | task-007, task-008, task-050 |
| task-052 | task-047 |
| task-053 | task-052 |
| task-054 | task-045 |
| task-055 | task-045, task-047, task-048, task-050, task-051 |

| Can Be Done In Parallel |
|------------------------|
| task-045, task-048 |
| task-046, task-049, task-054 |
| task-050, task-052 |
| task-051, task-053 |

```wave-map
delivery: 003
wave 1: task-045, task-048
wave 2: task-046, task-049, task-054
wave 3: task-047
wave 4: task-050, task-052
wave 5: task-051, task-053
wave 6: task-055
```

### delivery-004 execution graph

| Task | Depends On |
|------|-----------|
| task-056 | — |
| task-057 | task-056 |
| task-058 | task-056 |
| task-059 | task-014 |
| task-060 | task-059 |
| task-061 | task-045, task-060 |
| task-062 | task-057, task-060 |
| task-063 | task-058, task-060 |
| task-064 | task-061, task-063 |
| task-065 | task-045, task-057, task-058, task-062, task-064 |
| task-066 | task-007, task-065 |
| task-067 | task-007, task-051, task-066 |
| task-068 | task-060 |
| task-069 | task-057, task-058, task-061, task-062, task-064, task-065, task-066, task-067, task-068 |
| task-070 | task-054, task-069 |
| task-071 | task-070 |
| task-072 | task-063, task-064 |
| task-073 | task-069 |
| task-074 | task-069 |
| task-075 | task-069 |
| task-076 | task-075 |
| task-077 | task-076 |

| Can Be Done In Parallel |
|------------------------|
| task-056, task-059 |
| task-057, task-058, task-060 |
| task-061, task-062, task-063, task-068 |
| task-065, task-072 |
| task-070, task-073, task-074, task-075 |
| task-071, task-076 |

```wave-map
delivery: 004
wave 1: task-056, task-059
wave 2: task-057, task-058, task-060
wave 3: task-061, task-062, task-063, task-068
wave 4: task-064
wave 5: task-065, task-072
wave 6: task-066
wave 7: task-067
wave 8: task-069
wave 9: task-070, task-073, task-074, task-075
wave 10: task-071, task-076
wave 11: task-077
```

### delivery-005 execution graph

| Task | Depends On |
|------|-----------|
| task-078 | task-005, task-056 |
| task-079 | task-061, task-069 |
| task-080 | task-078, task-079 |
| task-081 | task-078, task-080 |
| task-082 | task-081 |
| task-083 | task-005, task-079 |
| task-084 | task-082, task-086 |
| task-085 | task-084 |
| task-086 | task-082, task-083 |
| task-087 | task-086 |
| task-088 | task-073, task-086 |
| task-089 | task-053, task-071, task-086 |

| Can Be Done In Parallel |
|------------------------|
| task-078, task-079 |
| task-080, task-083 |
| task-084, task-087, task-088, task-089 |

```wave-map
delivery: 005
wave 1: task-078, task-079
wave 2: task-080, task-083
wave 3: task-081
wave 4: task-082
wave 5: task-086
wave 6: task-084, task-087, task-088, task-089
wave 7: task-085
```

### delivery-006 execution graph

| Task | Depends On |
|------|-----------|
| task-090 | task-069, task-086 |
| task-091 | task-086 |
| task-092 | task-090, task-091 |
| task-093 | task-084, task-086 |
| task-094 | task-091, task-093 |
| task-095 | task-094 |
| task-096 | task-090, task-091, task-092, task-093, task-094, task-095 |

| Can Be Done In Parallel |
|------------------------|
| task-090, task-091, task-093 |
| task-092, task-094 |

```wave-map
delivery: 006
wave 1: task-090, task-091, task-093
wave 2: task-092, task-094
wave 3: task-095
wave 4: task-096
```

