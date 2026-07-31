# Doorway Engine Charts

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-25 | Feature identified from REQUIREMENTS.md §5 (FR-6, FR-2), §8, §9 (AC-4) | /aid-define |
| 2026-07-25 | Technical specification added | /aid-specify |
| 2026-07-25 | Review fix round 1 — feature-003 rule renumber and V9 conformance row | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-6, FR-2, §8 Assumptions (shapes 3 and 4), §9 AC-4

## Description

The ~94 skills whose bodies only delegate carry no control flow of their own; their real flow is
the shared shortcut engine's `INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT`.

This feature derives that chart **once** from `shortcut-engine.md`, in the flow-graph model
feature-003 defines, and emits it **inline on each doorway's own detail page** with that
doorway's `{verb, artifact}` binding shown at the entry node — so the page keeps §1's promise
that a skill's own page explains that skill, with no click-through. Kind-sibling doorways
(`aid-test-security` → `aid-test`) additionally show the hop to their parent skill before the
engine flow.

With this landed, all 111 skills have a chart and FR-2's whole-corpus coverage is complete.

> ✅ **FR-6 is owner-confirmed** (cross-reference Q2, 2026-07-25). It began as an interviewer
> default after the question was skipped during `/aid-describe`, and was explicitly confirmed
> once cross-reference established that the alternatives differ in blast radius. **This feature
> is now specifiable without a pending decision.**
>
> Recorded for the future, should FR-6 ever be revisited: reversal to a **literal single
> "delegates to engine" box** would change only this SPEC, whereas reversal to a **stub page
> linking to one shared Engine page** would additionally constrain **feature-005** (a stub page
> has no chart nodes, so AC-5's "every node" has nothing to attach to on doorway pages) and
> **feature-006** (no chart means no node to select). *(The original SPEC claimed total
> isolation; cross-reference found that overstated.)*

## User Stories

- As an **adopter about to run `/aid-create-api`**, I want its page to show me the sequence it
  will actually run and where it will stop for my approval, without sending me to a shared
  engine page.
- As an **AID maintainer**, I want a change to `shortcut-engine.md` to propagate to all ~94
  doorway pages in one build, so no page can describe a stale engine.
- As an **AID maintainer**, I want `aid-test-security` to show its hop to `aid-test` rather than
  pretending it is engine-driven, because that difference is the thing I would get wrong.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-4 (remaining two fixtures) — Feature coverage per structural class.** Given
      `aid-create-api` (generated doorway → engine) and `aid-test-security` (kind-sibling →
      sibling skill), when their charts are generated, then each contains the loop, branch, and
      exit its resolved source expresses. Tested with vitest.
- [ ] Given any skill classified as a doorway shape, when its chart is generated, then it passes
      feature-003's AC-3 validator.
- [ ] Given any doorway page, when it renders, then it shows that doorway's own
      `{verb, artifact}` binding at the entry node.

---

## Technical Specification

> Grounded in: **feature-003's SPEC as amended by its KI-008 round** (the flow-graph model,
> discriminators D1–D5, the Advance-clause parser rules 1–10, validator rules V1–V9, the shared
> truncator, the sidecar, and the runtime
> `astro-mermaid` substrate with hooks H1–H5) and **feature-001's SPEC** (`SkillRecord`,
> `BODY_PROVIDERS`, the manifest and the drift guard) — both of which are **binding and reused
> unchanged**; plus direct reading of `canonical/aid/templates/shortcut-engine.md`,
> `canonical/aid/templates/work-initiation-gate.md`, `canonical/aid/templates/shortcut-catalog.yml`,
> `canonical/skills/aid-create-api/SKILL.md`, `aid-fix`, `aid-add-api`, `aid-test-security`,
> `aid-test`, `aid-create-document`, `aid-create-diagram`, `aid-document-decision`,
> `aid-add-document`, `aid-ask`, `aid-audit`, `aid-prototype-ui`, and
> `.aid/knowledge/` (`module-map.md` § Skill Structural Shapes, `architecture.md`,
> `pipeline-contracts.md`, `domain-glossary.md` § Shortcut / Shortcut Engine).
>
> **Every rule number below is against feature-003's amended list**, in which ` then ` is rule 6,
> back-reference is rule 7, re-entry is rule 8, pause-resume-target is rule 9 and the residual-text
> guard is rule 10 (V9). An earlier revision of this SPEC cited the pre-amendment numbering, where
> back-reference was rule 6.

This feature adds **the two doorway extractors** — `engine-doorway` (shape 3) and `sibling-doorway`
(shape 4) — and nothing else. It defines no model, no validator, no renderer and no substrate:
every one of those is feature-003's, consumed as published. Its whole job is to answer, for a body
that carries no flow, **"whose flow is this, and how does it attach to this page?"**

**No count is asserted anywhere below.** Per REQUIREMENTS §8 the per-shape population is an output
of feature-003's classifier and is published as `shapeCounts` in feature-001's manifest. Where this
SPEC states a population it is a **dated measurement of a named, enumerable set** (e.g. "the 19
directories whose body contains `no logic of its own`, measured 2026-07-25"), used to show that a
rule is total over the corpus — never as a contract. The `~94` in this feature's own `## Description`
predates that measurement; see KI-002.

### Data Model

**No new persisted schema, no new field on any published type.** The `FlowChart` / `FlowNode` /
`FlowEdge` / `Provenance` shapes are feature-003's exactly as specified, including `shape`'s
five-value enum (`sibling-doorway` and `engine-doorway` are already members) and
`Provenance.sourceKind`'s four-value enum (`engine` and `sibling` are already members). The
serialization contract and the sidecar location (`site/src/data/skill-flows/<skill>.flow.json`) are
unchanged, so features 005 and 006 read doorway charts through the identical interface they read
authored-flow charts through — no consumer learns that doorways exist.

Two **build-time-only, non-serialized** structures are introduced. Neither reaches disk.

#### `EngineCore` — the derive-once artifact

```js
/** Deep-frozen. Built at most once per process, from shortcut-engine.md + work-initiation-gate.md. */
{
  nodes:    FlowNode[],   // ids 'c1'…'cN', order 1…N, relative to the core
  edges:    FlowEdge[],   // from/to are core-relative ids
  exits:    string[],     // core-relative ids
  sources:  string[],     // ['canonical/aid/templates/shortcut-engine.md',
                          //  'canonical/aid/templates/work-initiation-gate.md']
  warnings: string[]
}
```

It carries **no** `skill`, `title`, `entries` or `confidence`: those are properties of a *page's*
chart, not of the shared engine, and leaving them off is what makes it impossible for one page's
values to leak into the next. `entries` in particular is computed per composed chart, never copied.

#### `DoorwayBinding` — what the entry node reads

```js
{
  kind:   'engine' | 'sibling',
  verb:      string | null,   // 'create'
  artifact:  string | null,   // 'api'   ('' for a bare verb; null when the body states none)
  aliasOf:   string | null,   // 'aid-create-document'  (pure-alias siblings)
  bound:     string | null,   // 'kind bound to security'  (the sibling's facet binding)
  parent:    string | null,   // 'aid-test'  (siblings only)
  provenance: Provenance      // the body line the binding was read from
}
```

**Every field is read from the doorway's own body — never from `shortcut-catalog.yml`.** That is
not merely consistency with feature-003's classifier rule (which forbids the catalog for
*classification*); it is what the engine's own **Invocation Contract** specifies. That table names
the source of each bound value: `{name}` is "the invoking doorway's own directory/skill name",
`{verb}` and `{artifact}` are "the doorway body's binding" (`shortcut-engine.md` 24–29). Reading the
catalog instead would report what the doorway *should* bind; reading the body reports what it
*does*, and a build/catalog drift — a case the engine explicitly handles at INTAKE Step 1, "Row not
found … This is a build defect" (`shortcut-engine.md` 228–231) — would then be invisible on the page
that has it. **Rejected: resolving `{verb, artifact}` from the catalog row keyed by directory name.**

`sources[]` on a composed chart is the ASCII-sorted union of the core's sources and the doorway's own
`SKILL.md` (plus, for siblings, every file the parent's chart cites), which feeds feature-001's
manifest and drift guard (S3) unchanged.

### Feature Flow

Derivation is **one engine derivation per process, N page emissions**, and one parent-chart
derivation per distinct parent.

```
                       canonical/aid/templates/shortcut-engine.md
                       canonical/aid/templates/work-initiation-gate.md
                                     │  (read ONCE, first engine doorway only)
                                     ▼
                          getEngineCore()  →  EngineCore   ── deep-frozen, memoized
                                     │
    canonical/skills/<doorway>/SKILL.md    │
              │                            │
              ▼                            │
    readDoorwayBinding(...) → DoorwayBinding │
              │                            │
              └──────────► composeDoorwayChart({ prefixNodes, prefixEdges, core }) ──► FlowChart
                                     │           (pure: clone + id/order offset)
                                     ▼
                          feature-003's validateChart / renderMermaid / serializeChart
                                     ▼
                     feature-001's BODY_PROVIDERS slot  →  one page + one sidecar
```

For a **sibling doorway** the `core` is not the engine but the parent's own chart:

```
    canonical/skills/<sibling>/SKILL.md
              │
              ├─ readDoorwayBinding(...)      → DoorwayBinding (verb/artifact | aliasOf, bound)
              └─ resolveSiblingParent(...)    → 'aid-test'
                                     │
                                     ▼
                    buildFlowChart({ name: parent })      ── feature-003, unmodified
                                     │  memoized per parent name  (parentChartCache)
                                     ▼
                          composeDoorwayChart(...)  ──► FlowChart
```

#### Derive once, emit many — and why it stays byte-identical (AC-6, NFR-4)

1. **One read.** `getEngineCore()` holds a module-level memo. The engine file and the gate template
   are read, parsed and shaped on the first engine doorway of the run and never again. Same for
   `parentChartCache`, keyed by parent directory name — `aid-create-document`'s chart is built once
   and reused by the ten siblings that resolve to it (measured 2026-07-25).
2. **The core is deep-frozen** (`Object.freeze` applied recursively over nodes, edges and every
   `Provenance`) **before it leaves `getEngineCore()`**. This is the load-bearing AC-6 defence: a
   shared mutable memo is exactly how page 40 ends up carrying page 39's edits, and freezing turns
   that class of bug from a silent byte difference into a `TypeError` at build time.
3. **Per-page binding is applied by construction, never by mutation.** `composeDoorwayChart` is a
   pure function that returns **new** node and edge objects, copying each core member with `id` and
   `order` shifted by the prefix length and `from`/`to` remapped through the same offset map. The
   core is read, never touched. No `structuredClone` of a frozen graph, no in-place `node.id = …`.
4. **The offset is a constant.** Every doorway prefix is **exactly one node** (the doorway itself),
   so the offset is `1` on every page and the core's `c1…cN` become `n2…nN+1` identically everywhere.
5. **Therefore the engine segment is byte-identical across pages, not merely across runs.** Concrete,
   testable invariant: for any two `engine-doorway` skills, `renderMermaid(chart)` with the two lines
   carrying the entry node's declaration and the hop edge removed is **string-equal**. (Those are the
   fence's first node line and first edge line, since node declarations follow `order` and edges
   follow `(from.order, to.order, condition)`, but the invariant is stated on the entry node and hop
   edge so it does not depend on the fence's internal layout.) That is asserted as a corpus test
   (below) and is a far sharper guard than a two-run diff, because it fails the moment anything
   per-page leaks into the shared segment.
6. Everything else is inherited: ASCII-sorted directory scan, positional ids, edge emission ordered
   by `(from.order, to.order, condition)`, fixed JSON key order, LF, no clock, no randomness
   (feature-003 § Determinism).

The engine derivation reads two files that are **not** under `canonical/skills/`. That is legitimate
and already anticipated: `Provenance.sourceKind` carries an `engine` value, and V7 requires only that
`file` be under `canonical/`. Both are (`canonical/aid/templates/…`).

### Layers & Components

Same directory, same conventions, same test runner as feature-003 — this is three new modules plus
two registry entries, not a subsystem.

| File | Owner | Purpose |
|---|---|---|
| `site/scripts/lib/flow-graph/engine-core.mjs` | feature-004 | `getEngineCore()` — the memo, the derivation, the deep-freeze. |
| `site/scripts/lib/flow-graph/compose.mjs` | feature-004 | `composeDoorwayChart()` — the pure prefix-and-offset splice, shared by both extractors. |
| `site/scripts/lib/flow-graph/extract-engine.mjs` | feature-004 | Shape 3. Named in feature-003's ownership table. |
| `site/scripts/lib/flow-graph/extract-sibling.mjs` | feature-004 | Shape 4 + `parentChartCache`. Named in feature-003's ownership table. |
| `site/scripts/lib/flow-graph/index.mjs` | feature-003 | **Two rows added** to its shape→extractor dispatch — see E-DEP-1. |
| `site/scripts/skills/body.mjs` | feature-001 (seam) | **One `BODY_PROVIDERS` entry added** — see below. |
| `site/scripts/__tests__/flow-graph-doorways.test.mjs` | feature-004 | vitest suite; a sibling file of feature-003's, not a merge into it. |

Public API (signatures only):

```js
getEngineCore()                                        -> EngineCore        // memoized, frozen
readDoorwayBinding({ body, bodyStartLine, sourcePath }) -> DoorwayBinding
resolveSiblingParent({ body })                          -> { parent, provenance } | null
composeDoorwayChart({ skill, prefixNodes, prefixEdges, core, confidence }) -> FlowChart
extractEngineDoorway(skillRecord)                       -> FlowChart
extractSiblingDoorway(skillRecord)                      -> FlowChart
renderDoorwayBody(skillRecord)                          -> string   // the BODY_PROVIDERS render()
```

`engine-core.mjs` and `compose.mjs` are additions to the directory feature-003 defined, inside the
scope feature-003's ownership table already assigns feature-004 ("`extract-engine.mjs`,
`extract-sibling.mjs` (shapes 3 + 4), doorway `{verb, artifact}` entry-node binding — feature-004, in
the same directory, reusing model/validate/render unchanged"). They exist because the memo and the
splice are needed by **both** extractors and putting them in either one would make the other import
its sibling.

Conventions follow feature-003's: `site/`-local 2-space ESM, `node:`-scheme builtins only, no new
dependency, `canonical/` read and `profiles/*` never (§7).

#### `BODY_PROVIDERS` registration and first-match-wins

```js
export const BODY_PROVIDERS = [
  { id: 'flow-chart-authored', applies: /* feature-003 */, render: /* feature-003 */ },
  { id: 'flow-chart-doorway',  applies: (s) => DOORWAY_SHAPES.has(classifySkill(s).shape),
                               render:  (s) => renderDoorwayBody(s) },
];
// DOORWAY_SHAPES = new Set(['engine-doorway', 'sibling-doorway'])
```

**Array order is not load-bearing here, and that is a deliberate property rather than luck.**
`classifySkill` returns exactly one value from a five-member enum (feature-003 D1–D5, first match
wins *inside* the classifier), feature-003's provider claims `{dispatch-table, inline-states,
residual}` and this one claims `{engine-doorway, sibling-doorway}`. The two sets **partition** the
enum, so at most one predicate can ever fire and neither provider can shadow the other. Feature-004
is registered second only to match feature-001's numbering comment.

Relying on ordering instead would be fragile in the one way that matters: the day a sixth shape is
added, an order-dependent design silently routes it to whichever provider is first, while a
partition design leaves it unclaimed. So the guard is a test, not a comment — **for every directory
under `canonical/skills/`, exactly one `BODY_PROVIDERS` entry's `applies()` returns `true`** (see
Test layer). That single assertion also discharges FR-2's "no skill left chart-less" at the page
level, complementing feature-003's classifier-level version of it.

Both providers emit the **same H2, `## Flow`**, so the page table of contents, feature-005's
`BODY_APPENDERS` output and feature-006's DOM lookup anchor identically whatever a skill's shape is.
Neither feature-003 nor feature-001 fixed the string; this SPEC fixes it, and it must be reconciled
if feature-003's implementation chooses differently (E-DEP-2).

**`classifySkill` is called more than once per skill** (once by the provider predicate, once inside
`buildFlowChart`). That is accepted: it is a pure regex scan over a body that is ~18–32 lines for
every skill this feature owns, and purity — not call count — is what AC-6 depends on. Memoizing it
is an optimization the implementer may take, not a contract. `buildFlowChart` memoization **is** a
contract, but only for the sibling parent case (`parentChartCache`), where re-deriving
`aid-create-document` ten times would be visible in build time.

#### Dependency to reconcile

Stated as requirements on modules this feature does not own, in the same spirit as feature-003's
S1–S4 on feature-001.

- **E-DEP-1 — `index.mjs` dispatch (additive, anticipated).** `buildFlowChart()`'s shape→extractor
  dispatch gains `engine-doorway → extractEngineDoorway` and `sibling-doorway → extractSiblingDoorway`.
  Feature-003's own Feature Flow already names this ("this feature: dispatch-table, inline-states,
  residual; feature-004: the two doorway shapes"), so it is the declared seam, not a new one.
- **E-DEP-2 — the body-slot heading.** Both providers emit `## Flow`. One-line agreement.
- **E-DEP-3 — `classifySkill`'s return shape.** D3 states the classifier "Captures `delegatesTo`",
  but the published signature in feature-003 § Layers returns only `{ shape, evidence }`. Preferred:
  the return type carries `delegatesTo`. Fallback, if it does not: `resolveSiblingParent()` re-derives
  it from the body with the same rule D3 uses (the single distinct `canonical/skills/<name>/SKILL.md`
  reference). Either way feature-004 is unblocked; only duplication is at stake.
- **E-DEP-4 — `advance.mjs` clause separators. ✅ DISCHARGED 2026-07-25 by feature-003's KI-008
  amendment.** *(Renumbered by the orchestrator: three wave-2 agents each minted a "KI-007"
  concurrently. This issue is **KI-008**; KI-007 is the `test-landscape.md` CI-lane defect from
  feature-005.)*
  This SPEC originally raised the ` then ` form — `**Advance:** HANDOFF (optional) then DONE.`
  (`aid-test` 102, `aid-design` 91, `aid-prototype` 91, `aid-report` 103, `aid-research` 130) — as an
  open defect in a parser that split only on ` / ` and `; `, because the branch this feature's AC-4
  fixture 2 asserts was the very edge being dropped. Feature-003 amended and now owns the fix, so
  nothing is required of anyone here; retained as a closed record because fixture 2 depends on the
  amended behaviour.

  **Feature-003's resolution is better than the one this SPEC proposed, and fixture 2 tracks
  feature-003's, not the original proposal.** This SPEC had asked for a flat rule — split on ` then `
  and kind every resulting edge `branch`. Feature-003 instead made rule 6 asymmetric on the ground
  that ` then ` is *sequential* prose, so the two clauses are not alternatives: two `branch` edges are
  emitted only when `X` carries an optionality marker (`(optional)`, a bare `optional`, a trailing
  `?`, an `if <cond>`), and an unmarked `X then Y` yields a single `sequence` edge to `X` plus a
  warning. All five measured instances are the marked form, so the observable outcome for `aid-test`
  is identical — `PRESENT → HANDOFF` (`branch`, `condition: 'optional'`) and `PRESENT → DONE`
  (`branch`, `condition: null`) — but the flat rule would have invented a branch on the unmarked form.
  Feature-003 additionally added **rule 10 / V9**, the anti-silence guard that converts exactly this
  class of dropped edge from silent into a build error; see the V9 row under Validator conformance.

#### Test layer

`site/scripts/__tests__/flow-graph-doorways.test.mjs`, run by the site's existing `npm test` →
`vitest run` (and, from feature-001's Part B, actually executed in CI).

| Group | Covers |
|---|---|
| Binding extraction | Each rung of both binding ladders against inline fixture strings: `Bind **VERB=…**, **ARTIFACT=`…`**`; the bare-verb form `**ARTIFACT="" (bare verb)**`; `{verb: …, artifact: …}`; `{verb: …, artifact: ""}`; `alias_of: …`; and the no-binding fallback with its warning. |
| Engine core | `getEngineCore()` returns the identical **object reference** on the second call (memo held); the returned graph is deeply frozen (a write attempt throws in strict mode); its nine node names are the seven `## State Machine` rows in table order with each B1 node immediately after its parent state. |
| Purity of compose | Composing two different doorways leaves `getEngineCore()`'s output deep-equal to a fresh derivation; no composed chart shares a node or edge **object identity** with the core. |
| **Cross-page identity (AC-6)** | For every `engine-doorway` skill, `renderMermaid(chart)` minus its entry-node declaration and hop-edge lines is string-equal to the same slice of `aid-create-api`'s. |
| **Splice fidelity** | For every `sibling-doorway` skill, the spliced segment is deep-equal to `buildFlowChart({ name: parent })`'s own chart under the id/order offset — i.e. `/skills/aid-test/` and `/skills/aid-test-security/` cannot disagree about `aid-test`. |
| Validator (AC-3) | `validateChart(chart).ok === true` for every doorway chart; `entries.length === 1`; `exits.length >= 1`; every self-edge has `from === to` and both resolve (V4), and no `(from, to, condition)` triple repeats (V5). |
| Provider partition | For every directory under `canonical/skills/`, exactly one `BODY_PROVIDERS` entry's `applies()` returns `true`. |
| Provenance (AC-5 pre-check) | Every node's `provenance.excerpt` equals the live slice of its cited file — including nodes citing `shortcut-engine.md` and `work-initiation-gate.md`, not only `canonical/skills/`. |
| Degradation (FR-2) | The five warning classes W1–W5 each produce a `warnings` entry and a valid chart; none throws. |
| Idempotence (AC-6) | Two runs, byte comparison of `serializeChart` and `renderMermaid` for both fixtures. |
| **AC-4 fixtures** | The two tables below. |

No literal corpus count appears in any assertion (§8). Where a group says "for every …" it iterates
the live directory listing.

##### AC-4 fixture 1 — `aid-create-api` (generated doorway → engine)

Assertions are structural properties plus **named landmarks**, so prose edits in the engine do not
break the suite while a change to its state set does.

| Property | Assertion | Source |
|---|---|---|
| shape / extractor | `shape === 'engine-doorway'`, `extractor === 'extract-engine'`, `confidence === 'derived'` | `aid-create-api/SKILL.md` 16 (the `GENERATED by … build-shortcut-skills.py` comment → D4) |
| entry + binding | `entries` is exactly `[nodes[0].id]`; `nodes[0].name === 'aid-create-api'`; `nodes[0].kind === 'entry'`; `nodes[0].label` contains `VERB=create` and `ARTIFACT=api`; `nodes[0].provenance.file === 'canonical/skills/aid-create-api/SKILL.md'` and `startLine === 18` | `aid-create-api/SKILL.md` 18 |
| **the loop** | Exactly one self-edge in the chart: `from === to === <GATE id>`, `kind === 'loop-back'`, `provenance.file === 'canonical/aid/templates/shortcut-engine.md'` covering 804–805 | `shortcut-engine.md` 759 (`### Step 4: The Generic REVIEW -> GRADE -> FIX loop`), 804–805 ("Loop back / to Step 1 (REVIEW) for a fresh, clean-context reviewer pass.") |
| **the branch — INTAKE** | The `INTAKE` node has **exactly two** `branch` edges, to `CAPTURE` and to `CONTINUATION`; `INTAKE.kind === 'decision'`; the two conditions are `On new work` and `On continuation` | `shortcut-engine.md` 243–244, 251–260; `work-initiation-gate.md` 54–60, 129 |
| **the branch — GATE** | The `GATE` node has **exactly two** `branch` edges, to `APPROVAL-HALT` and to `Circuit breaker`, **plus** the `loop-back` self-edge; `GATE.kind === 'decision'`; `edges.filter(e => e.from === GATE)` has length 3 with kinds `{branch, branch, loop-back}` | `shortcut-engine.md` 794–796, 807–808, 845 |
| **the exit** | `exits` contains the `APPROVAL-HALT` id; `terminal.advanceType === 'HALT'`; `terminal.handoff` mentions `/aid-execute`. `exits` also contains `CONTINUATION` and `Circuit breaker` | `shortcut-engine.md` 95 (table `HALT`), 876–878, 895 |
| spine | Node names in `order` are exactly `['aid-create-api','INTAKE','CONTINUATION','CAPTURE','SPEC','PLAN','DETAIL','GATE','Circuit breaker','APPROVAL-HALT']` | `shortcut-engine.md` 89–95 + the two B1 nodes |

`aid-fix` is asserted as a **second, lighter** case in the same group — the same nine engine-segment
node names, its own entry node named `aid-fix` with a label containing `ARTIFACT="" (bare verb)`
(`aid-fix/SKILL.md` 18) — because the bare-verb binding is the one form the primary fixture cannot
exercise.

##### AC-4 fixture 2 — `aid-test-security` (kind-sibling → sibling skill)

| Property | Assertion | Source |
|---|---|---|
| shape / parent | `shape === 'sibling-doorway'`, `extractor === 'extract-sibling'`, resolved parent `aid-test` | `aid-test-security/SKILL.md` 18 ("It carries **no logic of its own.**" → D3), 16 and 20 (the single `canonical/skills/aid-test/SKILL.md` reference) |
| entry + binding | `nodes[0].name === 'aid-test-security'`, `kind === 'entry'`, `label` contains `verb: test` and `artifact: security`; `provenance.startLine === 17` | `aid-test-security/SKILL.md` 17 |
| the hop | Exactly one edge from `nodes[0]`, `kind === 'sequence'`, `condition === 'kind bound to security'`, `provenance` covering 20–22, `sourceKind === 'sibling'`; its target is the parent chart's own entry node (`INTAKE`) | `aid-test-security/SKILL.md` 20–22 |
| parent spliced | Node names after the entry are exactly `['INTAKE','RUN','VERIFY','PRESENT','HANDOFF','DONE']`, every one with `provenance.file === 'canonical/skills/aid-test/SKILL.md'` | `aid-test/SKILL.md` 37, 65, 81, 96, 106, 115 |
| **the loop** | A `loop-back` edge `VERIFY → RUN` (feature-003 rule 7, back-reference) | `aid-test/SKILL.md` 89–90 ("Not clean -> loop / to RUN/consolidate") |
| **the branch** | The `PRESENT` node has **exactly two** `branch` edges, to `HANDOFF` (condition `optional`) and to `DONE` (condition `null`); `PRESENT.kind === 'decision'`. Produced by feature-003 **rule 6**'s optionality-marker arm (KI-008, now landed — E-DEP-4); this is the same assertion feature-003's own `aid-test` fixture makes, so both suites pin the same edges | `aid-test/SKILL.md` 102 (`**Advance:** HANDOFF (optional) then DONE.`) |
| **the exit** | `exits` contains the `DONE` id; `DONE` is the only one of the six states with no `**Advance:**` line, so `terminal.advanceType === 'UNSPECIFIED'` (feature-003 extractor 2 step 4) | `aid-test/SKILL.md` 115–118, against the five `**Advance:**` lines at 61, 77, 92, 102, 111 |
| confidence | `confidence === 'derived'` — inherited from the parent chart, not asserted independently | — |

Both fixtures additionally assert `validateChart(chart).ok === true` and full `provenance.excerpt`
equality against disk.

### State Machines

*Activated for the same reason it was in feature-003: the substance of this feature is a model of
**other** artifacts' state machines. The difference is that here the state machine being modelled
does not live in the file the page is about — resolving that indirection **is** the feature.*

#### Reusing feature-003's dispatch extractor on the engine — yes, verbatim

`shortcut-engine.md` matches **D1** cleanly, so the engine's spine is extracted by feature-003's
`extract-dispatch.mjs` with no changes and no bespoke parser:

- Heading `## State Machine` at line 85, text **exactly** `State Machine` (D1's requirement), followed
  before the next heading by a GFM table whose header row is `| State | Detail | Worker | Advance |`
  (line 87) — carrying both a `State` and an `Advance` column.
- The seven rows at 89–95 give the seven nodes in row order, each with `provenance` = its own single
  row line, `sourceKind: 'engine'`.
- The `Advance` cells give six `CHAIN` sequence edges (`CHAIN -> CAPTURE` … `CHAIN -> APPROVAL-HALT`)
  and, on APPROVAL-HALT, the bare `HALT` — which feature-003's parser rule 4 turns into
  `terminal = { advanceType: 'HALT', … }` and an `exits` membership, with no dangling edge. **The
  exit AC-4 requires therefore falls out of the shared extractor mechanically.**
- The per-state `**Advance:**` lines (356, 444, 494, 581, 664, 845, 895) are read by the same
  extractor's refinement pass and **agree with the table**, which is a useful corroboration rather
  than new information.

Two details make the reuse safe, and both are load-bearing:

1. **D1's "exactly" saves us from the wrong table.** The engine has an earlier `## Dispatch Protocol`
   heading at line 72 whose section contains no table at all (prose, 74–83), and an
   `## Invocation Contract` table at 24–29 whose columns are `Value | Source | Notes`. A discriminator
   matching a heading *containing* `Dispatch` would select line 72 and yield zero nodes. D1 requires
   the heading text to be exactly `Dispatch` or `State Machine` **and** the following table to carry
   `State` + `Advance` columns; both clauses are needed here.
2. **The `Detail` cell says `below`, not `inline`.** Extractor 1 step 2 binds a state section when the
   `Detail` cell is `inline`; the engine writes `below` (89–95). Rather than widen feature-003's
   vocabulary, `extract-engine.mjs` calls feature-003's **shared inline-section reader** — which
   feature-003 already made "a shared helper rather than private to that extractor" — for each
   `## State: NAME` section in the engine file, and attaches it as that node's label source and
   `detail`. Zero modification to feature-003; the helper is used exactly as published.
   **Rejected: teaching `extract-dispatch.mjs` that `below` means `inline`** — a one-token change to
   an A+-graded module for a vocabulary used by one file.

With the sections bound, feature-003's label ladder produces every label with no engine-specific
tuning: candidate 1 (`Purpose:`) for INTAKE (`shortcut-engine.md` 219), candidate 3 (lead-paragraph
first sentence) for CAPTURE/SPEC/PLAN/DETAIL/GATE/APPROVAL-HALT (362, 450, 500, 587, 676, 851). Two
consequences are recorded rather than fixed: `APPROVAL-HALT`'s label resolves to
`Terminal state (FR-10 / NFR-10).` (851), which is weak but honest; and `GATE`'s label quotes the
engine's own `feature-004`, which is a **previous** work's feature-004, not this one — the same
`feature-NNN` collision feature-001 documented inside `site/`. Neither is rewritten: inventing better
prose is an interpretation on top of an interpretation (NFR-3).

The `Worker` column (`inline`, `aid-architect` (Large), `aid-reviewer` (Large)) is genuinely
informative and is **deliberately dropped**: `FlowNode` has no field for it, and adding one would
fork the model feature-005 and feature-006 both read.

#### The two engine-specific rules

The spine above has no loop and no branch, because the engine's own loop and branch are written as
prose **inside** state sections rather than as advance clauses — so feature-003's parser rules 5 and
7 never see them (rule 5 needs a `when <guard>` on an advance clause; rule 7 needs a back-reference
naming a *declared state*, and the engine's says "Loop back to Step 1 (REVIEW)", where `REVIEW` is a
step of GATE, not a state). Feature-003's amended rule 7 makes that second point explicitly, listing
`aid-config` 120's "loop back to Step 4" among the phrasings that "resolve to no declared state and so
emit nothing, which is correct: a step inside a state is not a chart node" — the engine's GATE loop is
the same shape, which is precisely why L1 below exists rather than a widening of rule 7. Two rules,
scoped to `extract-engine.mjs` and to nothing else, close that
gap. Both are additive to feature-003 rather than in tension with it: neither operates on an
`**Advance:**` clause, which is the only text feature-003's `advance.mjs` governs.

**E-rule L1 — internal loop ⇒ self-edge.** Inside a state section, an explicit loop phrasing
(`loop back to`, `loop to`) whose target resolves to **no declared state** but which is written
within that state's own section emits one `loop-back` **self-edge** on that state. Rationale: the
loop is real and internal; the chart's granularity is states, so the honest rendering of an internal
loop is a self-edge. Guard: at most one per node, and none if the node's own advance clauses already
name it. The self-edge's `provenance` is the loop-phrasing line, and its `condition` is **`null`**
unless the loop phrasing's own sentence states a guard — it does not here ("Loop back to Step 1
(REVIEW) for a fresh, clean-context reviewer pass.", 804–805). **Rejected: pairing the self-edge with
the `Otherwise` at 795–796**, ten lines away in a different rung; that pairing is an unstated
heuristic, and GATE's two `branch` conditions already tell the reader when the loop is taken. This is
the same self-edge shape feature-003's rule 5 produces, which the validator already
tolerates (V4 is satisfied because `from === to` and the node exists) and which feature-003's review
explicitly confirmed charts may contain. Measured firing sites in the engine: **GATE only**
(`shortcut-engine.md` 804–805; the enclosing `### Step 4` heading at 759 names the loop
`REVIEW -> GRADE -> FIX`).

**E-rule B1 — named early-halt arm ⇒ branch.** Inside a state section, a bolded arm lead-in whose
sentence terminates the engine run before the state's declared advance target (trigger tokens, all
verbatim in the source: `HALTS`, `STOP`, `does not run`, `instead of looping further`) emits:

1. an **`exit` node** for that arm, `name` taken **verbatim** from the arm's own name token in the
   resolved source — casing follows the source, never a normalizer, because `FlowNode.name` is
   defined as verbatim and uppercase-preserving;
2. a **`branch`** edge state → that node;
3. a re-kinding of the state's declared advance edge from `sequence` to `branch`, taking the
   continuing arm's own guard as its `condition`.

Each `condition` is the verbatim guard clause of its arm — the text from the arm's lead-in up to its
first `->`, `,` or `;` — emphasis- and backtick-stripped, then capped at 80 code points by
feature-003's **shared truncator** (`Array.from`, word boundary ≤ 79, else a hard cut at 79, then
`…`). Nothing is normalized into a predicate (REQUIREMENTS §8). At most one B1 node per state.

Measured firing sites in the engine, exhaustively:

| State | Early-halt node | Node name source | Branch conditions |
|---|---|---|---|
| INTAKE | `CONTINUATION` | `work-initiation-gate.md` 129, `### 3b. CONTINUATION -> route to the chosen work's resume entry point, then STOP` (`sourceKind: 'engine'`) | `On continuation` (`shortcut-engine.md` 254) / `On new work` (259–260) |
| GATE | `Circuit breaker` | `shortcut-engine.md` 807, `**Circuit breaker.**` | `If the pass's grade has not improved across 3 consecutive cycles` (807–808) / `If the pass's grade >= {floor}` (794) |

`CONTINUATION` legitimately cites the gate template because INTAKE Step 3 does: "**First, consult the
shared Work Initiation Gate** (`canonical/aid/templates/work-initiation-gate.md`)"
(`shortcut-engine.md` 243–244). The gate names both arms itself — `NEW` (82) and `CONTINUATION`
(129) — so the node name is read, not coined.

**Why B1 exists at all.** FR-4 requires the chart to represent decision branches and AC-4 requires
the doorway chart to contain "the branch its resolved source expresses". The engine expresses exactly
two state-level branches and both are early halts. **Rejected: leaving them to feature-003's rule 4**,
which would record each as a `terminal` field on INTAKE/GATE and add them to `exits` — valid,
AC-3-passing, and invisible in the diagram, which is the one place FR-4 says the branch must appear.
B1 is scoped to `extract-engine.mjs`; generalizing it to feature-003's extractors is a separate
question this feature does not open (`aid-test`'s INTAKE carries the same gate arm at
`aid-test/SKILL.md` 55 and is deliberately left as feature-003 draws it — see the splice invariant).

#### The resulting engine chart

Ten nodes, ten edges. `order` is the doorway prefix, then engine table-row order, with each B1
node inserted immediately after its parent state (deterministic).

```
  n1 ([<doorway>              ])   entry     canonical/skills/<doorway>/SKILL.md:18
       │  (sequence)
  n2  {INTAKE                  }   decision  shortcut-engine.md:89
       ├─ branch "On continuation" ─► n3 ([CONTINUATION])  exit  work-initiation-gate.md:129
       └─ branch "On new work"     ─► n4
  n4  [CAPTURE]  ─►  n5 [SPEC]  ─►  n6 [PLAN]  ─►  n7 [DETAIL]      shortcut-engine.md:90-93
       │  (sequence, CHAIN)
  n8  {GATE                    }   decision  shortcut-engine.md:94
       ├─ loop-back  (self, no condition)                           shortcut-engine.md:804-805
       ├─ branch "If the pass's grade has not improved across 3 consecutive cycles"
       │                          ─► n9 ([Circuit breaker])  exit   shortcut-engine.md:807-808
       └─ branch "If the pass's grade >= {floor}"
                                  ─► n10 ([APPROVAL-HALT])   exit   shortcut-engine.md:95, 895
```

#### The kind-sibling hop — the parent's chart is **inlined**, spliced whole

This is the feature's sharpest design question, and the requirement has already answered its two
nearest neighbours. FR-6's owner-confirmed decision (REQUIREMENTS 173–192) rejected, for the engine
case, both **a stub page linking to one shared page** ("breaks the standalone promise **and** forces
re-scoping of features 005 and 006, since a stub page has no chart nodes for AC-5 to attach to or
feature-006 to interact with") and **a single "delegates to X" box** ("truthful but useless"). A
kind-sibling's parent is a six-state skill; the engine is a 926-line shared template. If inlining is
right for the harder case it is right for the easier one, and choosing differently would make two
adjacent doorway pages behave differently for no reason a reader could name.

**Decision: inline the parent's chart, spliced whole, after the hop.** Rejected in one line each:
*link to the parent page* — FR-6's rejected stub, and it strands AC-5/feature-006 on every
kind-sibling page;
*summarise the parent in one box* — FR-6's rejected literal box, and it discards the loop, branch
and exit AC-4 names.

Mechanics:

1. **Resolve the parent** from the body with D3's own rule: the single distinct
   `canonical/skills/<name>/SKILL.md` reference (`aid-test-security` 16, 20). Two or more distinct
   references contradicts D3 and cannot occur for a skill the classifier routed here.
2. **Build the parent's chart** with feature-003's `buildFlowChart({ name: parent })`, memoized.
3. **Splice it verbatim** through `composeDoorwayChart`, offsetting ids and `order` by the prefix
   length. **No feature-004 rule — not L1, not B1 — is applied to the spliced segment.** This is an
   invariant, not an omission: a reader who opens `/skills/aid-test/` and `/skills/aid-test-security/`
   must see the same `aid-test` flow, and the splice-fidelity test asserts exactly that. It is also
   why `aid-test`'s own early-halt gate arm (`aid-test/SKILL.md` 55) is not drawn on either page.
4. **Recompute, never copy:** `entries` becomes `[n1]` by construction (the parent's entry nodes gain
   the hop's in-edge, so their in-degree is no longer 0); `exits` is the parent's exits, offset;
   `sources` is the sorted union; `warnings` is concatenated.
5. **`confidence` is the weaker of the two** — `approximate` if the parent's chart is, `derived`
   otherwise. Today this matters for exactly one skill: `aid-ask → aid-query-kb`, whose parent is a
   residual-shape skill (feature-003 R3), so `aid-ask`'s page correctly renders feature-003's
   approximate notice.
6. **Depth and cycles.** Resolution is capped at **4 hops** with a visited-set cycle guard. On
   exceeding either, the hop terminates in an `exit` node naming the unresolved parent and a warning
   is recorded — never a throw (FR-2). Measured 2026-07-25, every one of the 19 parents is a
   non-doorway skill (`aid-create-document` ×10, `aid-test` ×3, `aid-research` ×2, `aid-review`,
   `aid-prototype`, `aid-change-document`, `aid-query-kb`), so **no chain deeper than one hop exists
   today**; the cap is durability, and the classifier — not this list — stays the authority.

#### The entry node and the hop edge

Both ladders are deterministic, total over the measured corpus, and read only the doorway's own body.

**Engine doorways** — one form, generated by `build-shortcut-skills.py`:

| Field | Source |
|---|---|
| `name` | the directory name (`shortcut-engine.md` 26: `{name}` is "the invoking doorway's own directory/skill name") |
| `label` | the doorway's own Bind clause: `Bind **VERB=`create`**, **ARTIFACT=`api`**` → `Bind VERB=create, ARTIFACT=api` (`aid-create-api` 18). The bare-verb form `**ARTIFACT="" (bare verb)**` (`aid-fix` 18) is carried through as written. Truncated by the shared truncator; V8-safe unconditionally. |
| `provenance` | that single body line, `sourceKind: 'skill'` |
| hop edge | `sequence`, `condition: null` — a generated doorway binds and runs; nothing is conditional |

**Sibling doorways** — the D3 population splits cleanly into two sub-forms (a sub-form of one shape,
**not** a sixth classifier shape: forking the enum would break the provider partition and every
consumer of `FlowChart.shape`):

| Sub-form | `label` ladder | hop `condition` |
|---|---|---|
| Kind-sibling — body carries `{verb: v, artifact: a}` | `verb: test, artifact: security` verbatim from the braced group (`aid-test-security` 17; `aid-document` 19 shows the `artifact: ""` form) | the bolded facet binding `**<facet> bound to <value>**` → `kind bound to security` (`aid-test-security` 21), `format bound to diagram` (`aid-create-diagram` 24), `genre bound to ADR` (`aid-document-decision` 24), `target bound to ui` (`aid-prototype-ui` 23) |
| Pure alias — body carries `alias_of: <parent>` and no facet binding | `alias of aid-create-document` (`aid-add-document` 22; also `aid-audit` 21, `aid-ask` 27, `aid-investigate` 20, `aid-spike` 20, `aid-update-document` 22) | `null` — an alias binds nothing, and an unconditional arrow is the truthful rendering |
| Neither (none today) | `Delegates to <parent>` | `null`, plus warning **W1** |

The two sub-forms **partition** the D3 population exactly: measured 2026-07-25, all 19 directories
whose body contains `no logic of its own` carry either a `{verb, artifact}` group (13) or an
`alias_of` (6), never both and never neither. FR-6's "`{verb, artifact}` binding shown at the entry
node" is therefore satisfied literally wherever the source states one, and by the alias declaration —
which *is* that skill's binding — where it does not.

#### Warnings — the FR-2 boundary

Every one is a `chart.warnings` entry and a still-valid chart. None throws; `validateChart` errors
remain the only throw, exactly as feature-003 specified.

| # | Condition | Effect |
|---|---|---|
| W1 | No binding form matched in the body | Entry label falls back to `Delegates to <parent-or-engine>` |
| W2 | A sibling body carries H2 sections beyond the hop prose | Those sections are **not** drawn; the warning names them. Measured: `aid-ask` is the only such skill (`## Pre-flight`, `## Execution`, `aid-ask/SKILL.md` 46, 59). See OQ-2 |
| W3 | Parent depth cap exceeded, or a resolution cycle | Hop terminates in an `exit` node naming the unresolved parent |
| W4 | Parent chart is `approximate` | Composed `confidence` becomes `approximate`; feature-003's notice renders |
| W5 | The engine's `## State Machine` rows disagree with its own Maintenance note's declared order (`shortcut-engine.md` 12–16) | Warning only — a cheap drift detector on the file this feature depends on most |

#### Validator conformance (AC-3)

Feature-003's `validateChart` is used **unchanged**; no rule is relaxed, added or parameterized.
Conformance is by construction, not by a repair pass:

| Rule | How a doorway chart satisfies it |
|---|---|
| V1 | Ids are `n1…nN` assigned by composition order, unique, pattern-conforming |
| V2 | `entries` is exactly `[n1]`: the doorway node is the only in-degree-0 node, since the hop feeds every spliced entry |
| V3 | `exits` is non-empty — engine: `APPROVAL-HALT` (from the table's own `HALT`), `CONTINUATION`, `Circuit breaker`; sibling: the parent's exits, which feature-003 already guarantees non-empty |
| V4 | Every edge target is in-chart. The two engine early-halt arms are **nodes**, so no dangling handoff; **self-edges satisfy V4 trivially** (`from === to`, and that node exists), which is why the GATE loop needs no tolerance beyond what the rule already gives |
| V5 | No `(from, to, condition)` repeats: L1 emits at most one self-edge per node and B1 at most one early-halt node per state |
| V6 | Every node is reachable from `n1` — verified by walk on the engine chart (n1→INTAKE→{CONTINUATION, CAPTURE}→…→GATE→{self, Circuit breaker, APPROVAL-HALT}) and inherited for the spliced segment, which was already V6-clean on its own page |
| V7 | Every node has provenance under `canonical/` with a matching excerpt — including the engine and gate templates |
| V8 | Every label is non-empty and ≤ 60 code points, because every label goes through feature-003's shared truncator, whose character-level fallback makes the bound unconditional |
| V9 | No advance block leaves residue naming a declared state that is neither an edge target from that node nor in its `terminal.handoff`. Silent on both doorway kinds — see below |

**V9 in detail, since it is the one rule added after this SPEC was first written.** V9 inspects
**advance blocks only** — what rule 10 leaves over after clause extraction — so it is worth being
exact about which blocks a doorway chart actually contains.

*Engine doorways.* Thirteen of the engine's fourteen advance blocks are consumed whole and leave no
residue at all: the seven `Advance` cells at 89–95 are single-clause `CHAIN -> <state>` or a bare
`HALT`, and six of the seven per-state `**Advance:**` lines are the same (356, 444, 494, 581, 664,
845). **The one exception is APPROVAL-HALT's block** (895–897), where `HALT.` is followed by prose:
"No branch is created; no `### Tasks lifecycle` row advances past `Pending` (the halt-proof fixture
in feature-004's testing strategy asserts both)." That residue names **no declared state** — not
under the narrow reading (the seven `## State:` sections) and not under the wide one (the composed
chart's ten nodes, including the two B1 nodes), since `Pending` and `Tasks lifecycle` are neither.
**V9 is therefore silent, and the engine chart is V9-clean.** Whether rule 10's *W-1 warning* also
stays silent depends on whether feature-003's advance-type keyword scan matches `halt-proof`
case-insensitively; either way that is a warning and never a throw (FR-2), and the derive-once memo
means it is computed once per run rather than once per doorway page.

Two corollaries worth stating because they are easy to assume the other way. First, **L1 and B1 add
nothing V9 inspects**: both read state-section prose, not advance blocks, so the GATE self-edge and
the two early-halt branches leave the residue picture untouched. Second, **adding the B1 nodes cannot
wake V9 up** even though it widens the declared-state set the residue is tested against — neither
`CONTINUATION` nor `Circuit breaker` appears in APPROVAL-HALT's residue, the only residue there is.

*Sibling doorways.* A sibling body carries **no `**Advance:**` block at all** — it declares it carries
no logic of its own — so every advance block in a composed sibling chart belongs to the parent, and
V9 conformance is **inherited rather than re-argued**: `buildFlowChart` throws on a V9 error, so no
V9-dirty parent chart can reach the splice. The splice adds one node and one edge and changes no
block. It does widen the declared-state set by the doorway's own name, but a skill directory name
(`aid-test-security`) is not a state token in any parent advance block, so no residue can newly match
— and for this feature's own fixture the question is moot, because feature-003 records that
post-amendment "the five ` then ` blocks leave no residue at all" and `aid-test`'s other four blocks
are bare targets.

### UI Specs

*Activated because a doorway page renders a chart whose nodes cite a file that is **not** the skill
the page is about. Making that legible is a presentation contract, and features 005 and 006 both
consume it.*

Everything about the substrate is feature-003's and is inherited without change: the runtime
`astro-mermaid` path, `flowchart TB`, the per-chart self-contained `classDef` block (KI-001), the node
shapes by `kind` (`entry`/`exit` stadium, `decision` rhombus, `step`/`loop-back` rectangle), the
`"NAME<br/>label"` two-line node text, `-->` / `-->|"condition"|` / `-. "condition" .->` edge forms,
and hooks H1–H5. Feature-006 needs nothing new: node ids follow the same
`^[A-Za-z][A-Za-z0-9_]{0,31}$` contract and the same `class … aidNode` statement (H3), and it resolves
a clicked node through the same sidecar `nodes[]` (H4).

Three additions, all small:

1. **The `## Flow` heading** — the same H2 feature-003's provider emits (E-DEP-2), so
   `tableOfContents` anchoring and feature-005's appended list are shape-independent.
2. **A one-line resolution notice above the fence**, because a reader must not conclude that
   `aid-create-api` contains an `APPROVAL-HALT` state:
   - engine: *Derived from the shared shortcut engine (`canonical/aid/templates/shortcut-engine.md`),
     which this doorway binds and runs.*
   - sibling: *Derived from `/aid-test` (`canonical/skills/aid-test/SKILL.md`), which this
     kind-sibling executes as written, with the kind bound to security.*

   The notice carries a `canonical/` link on the same `GITHUB_BLOB_BASE` feature-001 declares — so the
   page gains the *link* that the rejected stub-page option would have offered, at no cost to §1's
   standalone promise, and NFR-3's interpretation risk is acknowledged where the interpretation is
   largest. It is prose above the fence, not a chart node, so it costs feature-006 nothing.
3. **The self-edge renders as an unlabelled dotted loop** — `n8 -.-> n8`, matching feature-003's
   `loop-back` form with a null condition. Mermaid draws a self-referencing edge as a loop above the
   node; this is the same construct feature-003's `aid-describe` fixture already produces (its rule-5
   self-edge on `CONTINUE`), so no new rendering risk is taken.

Escaping is feature-003's (`&` `<` `>` `"` → entities; residual backtick or pipe → space), which
matters concretely here: the GATE branch condition contains `>=` and `{floor}`, and the entry label
for a bare verb contains `""`.

**Cost accepted, restated for this feature:** every doorway page ships the same engine diagram, and
each of the ten `aid-create-document` siblings ships the same six-state diagram. That is FR-6's
already-booked cost ("~N pages share a chart shape, which is truthful — they differ only in binding"),
and the binding is exactly what the entry node and hop edge make visible. KI-004's
no-JavaScript degradation applies here as it does to every chart.

### Open Questions

**One open — OQ-2.** OQ-1 was resolved by feature-003's KI-008 amendment on the same day and is
retained below as a closed record, because fixture 2 depends on the behaviour it settled.

- **OQ-1 — Where does the ` then ` advance-clause fix land? ✅ RESOLVED 2026-07-25 — routing (a).**
  The question was whether E-DEP-4 / **KI-008** — a defect in feature-003's `advance.mjs` that drops
  the `PRESENT → DONE` edge in five inline-states skills, including this feature's fixture-2 parent —
  should be fixed by **(a)** amending feature-003's SPEC, **(b)** landing it inside feature-004's
  delivery as a cross-feature change, or **(c)** deferring it and re-scoping fixture 2's assertion.
  Feature-003 amended the same day (its Change Log: "KI-008: advance-clause separator set closed,
  residual-text guard added, ` then `-form fixture added"), so **(a)** is what happened and nothing is
  owed by this feature. Feature-003 went further than the question asked in two ways worth recording:
  it replaced the literal separator list with a measured-then-validated derivation rather than
  appending one more token, and it added rule 10 / **V9** so that a future unrecognised connective
  fails the build instead of silently dropping an edge — which retires the "silently" clause that made
  this question urgent. Retained as a closed record because fixture 2 asserts the amended behaviour;
  see E-DEP-4 for why feature-003's asymmetric rule 6 is the better resolution.
- **OQ-2 — `aid-ask`'s own `## Pre-flight` guard is not drawn.** `aid-ask` is the only D3 skill whose
  body carries H2 sections of its own (`## Pre-flight` 46, `## Execution` 59, measured 2026-07-25),
  and its Pre-flight is a genuine control-flow arm: "If `/aid-ask` is invoked with no argument, print
  … Then exit without answering" (49–57). W2 records the loss; the chart shows the hop to
  `aid-query-kb` without it. **Rejected: promoting a sibling's own H2 sections to pre-hop nodes** — a
  rule tuned to a single file, and `aid-ask`'s `## Execution` section only restates the delegation the
  hop already draws. **Owner decision:** accept the recorded loss, or spend the rule.
