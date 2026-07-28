# Delivery BLUEPRINT -- delivery-003: KB Gap Ledger

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-003
> **Work:** work-005-knowledge-graph
> **Created:** 2026-07-28

---

## Objective

This delivery turns the relationship table into a Knowledge-Base *quality* signal. It detects
coverage gaps over feature-004's enumerated node set — not over the table's rows, so an
enumerated `int:` artifact appearing in no row at all is caught rather than being invisible —
writes them as a 7-column reviewer ledger with the offending artifact as evidence, and routes
them onward to the skills that already own Knowledge Base repair. The run never fails because
gaps exist (FR-25), because gating on Knowledge Base completeness would fail the tool for reasons
outside its control and would create a standing incentive to loosen the significance rule until
the gaps stopped appearing — destroying the signal the artifact exists to produce.

It is scoped as a distinct unit because the reporting decision is separable from the extraction
that feeds it: delivery-002 ships a usable table with no gap detection, and this delivery adds the
detection, the ledger, and the routing on top of it without touching either. Its one feature,
feature-006, is blocked by feature-004 (the candidate set) and feature-005 (the coverage that says
which candidates are accounted for), and by neither RESEARCH feature.

## Scope

**In scope:**

- **feature-006-kb-gap-ledger** — the coverage predicate's semantics (its three conditions and
  the `COVERAGE_BEARING` selection), `canonical/aid/scripts/graph/detect-kb-gaps.mjs`, the
  `kb_gaps` generator-written frontmatter record on `relationships.md`, the ledger at
  `.aid/.temp/review-pending/graph-kb-gaps.md`, the severity mapping from feature-004's
  qualifier clauses, the `Pending` / `Fixed` / `Recurred` transitions across runs, and the
  routing message naming `/aid-update-kb` and `/aid-housekeep`.
- **`canonical/aid/scripts/graph/coverage-predicate.mjs` — created here** (see the owner decision
  below), authored to feature-007's contract: `detectKbGaps`, `kbUnbacked` and
  `COVERAGE_BEARING` exported, obeying feature-007's five boundary rules.
- The two shared-template amendments feature-006 owns:
  `canonical/aid/templates/reviewer-ledger-schema.md` (two scope rows plus the retention
  exception) and `canonical/aid/templates/kb-authoring/frontmatter-schema.md` (the `kb_gaps:`
  generator-written field).

**Out of scope:** nothing is deferred from this work. Specifically excluded from *this delivery*:
fixing any gap (FR-27 — that is `/aid-update-kb`'s and `/aid-housekeep`'s job), opening tickets
for gaps (§4 Out of Scope), anything that would make the run fail on gap count, and the view side
of AC-15 (feature-007 in delivery-004, feature-008 in delivery-005). The `kb:`-unbacked signal is
**lens-only** and emits no ledger row — AC-15's equality binds the `int:` class only.

## Owner decision recorded here: `coverage-predicate.mjs` lands in this delivery

`feature-006` owns the gap predicate's **semantics** and `feature-007` owns the **file**, but the
file is a Node script under `canonical/aid/scripts/graph/` rather than view code — it sits beside
`scan-source.sh` and `detect-kb-gaps.mjs`, the two Node-side neighbours it exists to agree with —
so **the ledger deliverable creates it, authored to feature-007's contract**. feature-006's own
Migration step 1 already assumes it exists ("Add `detect-kb-gaps.mjs` to the `graph/` script area,
beside feature-007's `coverage-predicate.mjs`"), and feature-006's detector cannot run without it:
`detect-kb-gaps.mjs` does `import { detectKbGaps } from '../graph/coverage-predicate.mjs'`.

**feature-006's Dependency position names only features 004 and 005 and does not mention this**,
so the plan is where it becomes visible. The mirror note is recorded in delivery-004's BLUEPRINT.

The consequence for gating: feature-007's byte-identity assertions **GV02** (the inlined region in
a generated `graph.html` is byte-identical to the same tree's `coverage-predicate.mjs`), **GV04**
(`COVERAGE_BEARING` equals feature-006's recorded subset) and **GV08** (every rendered copy under
`profiles/` is byte-identical to the canonical file) **run later, in delivery-004**, when the view
exists to inline it. What this delivery can and must assert instead is **GV01**'s greppable
boundary rules and **GL12**'s bare-Node import.

## Gate Criteria

- [ ] **AC-14** — a run that detects one or more gaps emits one ledger row per gap carrying the
      offending source artifact as evidence, **and still completes successfully**. Verified by
      `GL07`: a fixture with many gaps yields a non-empty ledger and exit status 0.
- [ ] **AC-15 is satisfied on the ledger side only and does NOT close in this delivery.**
      feature-006 owns the criterion, but its view side is **feature-007 (delivery-004)** and its
      graph side **feature-008 (delivery-005)**, and all three SPECs state that neither owner may
      consider it met alone. What closes here is `GL09`: the `kb_gaps` id list, the ledger's `Doc`
      column, and an in-test call to `detectKbGaps` over the fixture's **full node inventory**
      plus its table are the same set — and `kbUnbacked` ids from that fixture appear in neither.
      **AC-15 closes overall in delivery-005.**
- [ ] The ledger is exactly one seven-column table at `.aid/.temp/review-pending/graph-kb-gaps.md`
      — no frontmatter, no heading, no summary section — satisfying C-6's project-wide shape with
      no bespoke findings format (`GL05`). Every `Line` cell is `—` (FR-23 fixes granularity at
      the whole artifact) and every `Doc` cell is an existing repo-relative path (`GL06`).
- [ ] The candidate set is feature-004's **enumerated node inventory**, not the table's rows:
      an enumerated `int:` node appearing in no table row yields a ledger row with the severity
      from its qualifier clause, a `kb_gaps` entry carrying both `id` and `name`, and a
      `Description` ending `; no relationships in the table`. Removing the node from `nodes.tsv`
      while leaving the table untouched makes the row disappear (`GL13`).
- [ ] Severity derives from feature-004's qualifier: entry-point → `[HIGH]`, depended-upon →
      `[MEDIUM]`, named-unit-only → `[LOW]`, and a node satisfying two clauses takes the higher
      (`GL04`). A node covered by a `COVERAGE_BEARING` edge to a `kb:` id produces no row at any
      `Provenance` value, including `inferred` (`GL01`); a node covered only through an ancestor
      path produces no row (`GL02`).
- [ ] The `no-inferred-node` seam holds: every id in feature-004's fixture inventory carries
      `evidence_provenance` of `declared` or `derived`, and no `int:` id present in
      `candidates.tsv` appears in the ledger (`GL03`). This asserts feature-004's invariant rather
      than a filter applied here, and goes red if that guarantee is ever weakened.
- [ ] **The gap rows are invisible to the gate.** `grade.sh` over `graph.md` returns `A+` while
      `graph-kb-gaps.md` holds `[HIGH]` rows (`GL08`), and the detector's exit contract is an
      unconditional `0` regardless of gap count, with `2` reserved for a usage error.
- [ ] `canonical/aid/scripts/graph/coverage-predicate.mjs` exists and obeys feature-007's boundary
      rules: no `import`/`require`, no `node:` specifier, no `document`/`window`/`globalThis`, no
      `canonical/` substring and none of the three filename placeholders in code **or** comments,
      only top-level `export function` / `export const` declarations, and plain-data inputs and
      outputs (`GV01`). Importing it in a bare Node process succeeds from the detector's own
      directory with **no** `package.json` in `canonical/aid/scripts/graph/` (`GL12`).
- [ ] The run modifies no Knowledge Base file other than writing `kb_gaps` into
      `relationships.md`'s own frontmatter — which is this skill's own artifact, on its own write
      allowlist — and opens no ticket. Output names `/aid-update-kb` and `/aid-housekeep` as the
      route onward.
- [ ] **The two ledger-lifecycle sentinels pass.** `GL10`: re-running against a previous ledger moves
      a now-covered row to `Fixed` and a re-broken row to `Recurred`, renumbering nothing. `GL11`:
      `grade.sh` over a ledger whose rows are all `Fixed` returns `A+`, confirming the `Status` enum
      is written in the form `grade.sh` actually counts. These are not optional coverage —
      feature-006's SPEC names `GL08` and `GL11` as **the two assertions that would fail if a future
      change filtered by row instead of by file**, which is precisely the regression that would
      re-conflate the graded ledger with the delivered one and undo FR-25's structural separation.
      `GL10` is what proves the Status transitions survive across runs, without which a retained
      findings ledger silently rots.
- [ ] **Q8 — FR-26 is not fully satisfiable in this delivery, and the gate records that as an
      accepted external dependency.** `reviewer-ledger-schema.md` § "Lifecycle (per skill
      invocation)" has the orchestrator delete the ledger at skill DONE, which would destroy the
      very findings FR-26 makes this feature's deliverable. feature-006 specifies the fix as a
      **named retention carve-out written into the shared schema** rather than as local skill
      behaviour, so a future orchestrator reading the schema does not delete
      `graph-kb-gaps.md`. That amendment is a methodology-level change beyond work-005's scope.
      This delivery lands the file-separation half (`graph.md` graded and deleted at DONE;
      `graph-kb-gaps.md` never graded and retained) and drafts the schema amendment, but **FR-26
      is not fully satisfied until the carve-out lands**, and the gate must not record it as
      closed.
- [ ] All section-6 quality gates pass: the delivery gate's `grade.sh` run over
      `.aid/.temp/review-pending/graph.md` (never `graph-kb-gaps.md`) reaches this repository's
      resolved `minimum_grade` of **A+** (`review.minimum_grade` in `.aid/settings.yml`; this
      work's `minimum_grade: "A+"`), i.e. zero findings with Status `Pending` or `Recurred`.

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-002 (feature-004's enumerated node set, feature-005's coverage,
  feature-003's table)
- **Blocks:** delivery-004 and delivery-005 for AC-15's closure (both consume
  `coverage-predicate.mjs` and the `kb_gaps` record); delivery-006
- **External dependency:** the reviewer-ledger retention carve-out (STATE.md Q8), a
  methodology-level change outside work-005

## Notes

- **`COVERAGE_BEARING` has two copies by design, and one test binds them.** feature-006 owns the
  *selection* and records it as a named subset beside feature-001's vocabulary artifact, where a
  reviewer reads the two together; `coverage-predicate.mjs` carries the *executable* copy, because
  the module may not import anything. **GV04** asserts the two sets are equal — the same doc↔code
  lockstep the project already uses for render drift — and runs in delivery-004.
- **Membership of `COVERAGE_BEARING` depends on delivery-001.** feature-006 fixes the *meaning* of
  the subset ("the pairs that mean 'this KB concept describes / is derived from this artifact'")
  but cannot enumerate its members until the relation vocabulary lands. If feature-001's research
  produces a category that already means exactly this, the subset is that category and nothing
  further is declared.
- **`kb_gaps` is a recorded result, not a second source of truth.** The ledger emits one row per
  entry in list order from the same call the rows are built from, so the two cannot diverge within
  a run. The Coverage lens does not read `kb_gaps` as input — it recomputes and *verifies* against
  the record, which is what keeps FR-3 and AC-10 true (the view still reads exactly one artifact,
  because `kb_gaps` lives in `relationships.md`'s own frontmatter).
- **Two shapes satisfy the Node boundary and feature-006 may pick either** — `detect-kb-gaps.sh`
  as a thin CLI over an `.mjs`, or `.mjs` outright. The module's contract is identical under both;
  feature-006's Layers section names `detect-kb-gaps.mjs`.
