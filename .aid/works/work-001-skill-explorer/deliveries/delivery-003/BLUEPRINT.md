# Delivery BLUEPRINT -- delivery-003: A flow chart on every skill page

[!NOTE]
This is the IMMUTABLE DEFINITION of delivery-003. Written once by aid-plan; not a state file —
delivery-003's lifecycle, gate and Q&A live in `deliveries/delivery-003/STATE.md`.

> **Delivery:** delivery-003
> **Work:** work-001-skill-explorer
> **Created:** 2026-07-26

---

## Objective

Fill the body slot delivery-002 published, for the whole corpus. Every skill detail page gains a
flow chart derived at build time from that skill's own files — ordered steps, loops, decision
branches and exit points, each node labelled with a short derived imperative phrase. Skills that
carry their own control flow are charted from it; the delegating majority, which carry none, are
charted from the shared shortcut engine with their own `{verb, artifact}` binding at the entry
node, and kind-siblings additionally show the hop into their parent's chart spliced whole. This
is the first delivery that fulfils the objective the work was created for: a reader can state
what a skill does, step by step, without opening the source. It is scoped as one unit because
feature-003 alone would leave most pages chart-less, which is a worse published state than a
uniformly unfilled slot.

## Scope

- **feature-003** — the flow-graph model (`FlowNode`, `FlowEdge`, `Provenance`), the shape
  classifier (discriminators D1–D5, keyed on body inspection and never on the catalog's
  `repurpose` flag), the Advance-clause parser (rules 1–10, including the block-scoped scan and
  the ` then ` / `(or X …)` / ` or ` / unspaced-`/` separator set), the well-formedness validator
  (V1–V9, including the V9 anti-silence guard), the shared code-point truncator, the residual
  heuristic extractor, the `<skill>.flow.json` sidecar under `site/src/data/skill-flows/`, and the
  rendering substrate — **runtime `astro-mermaid`**, with D18/"D-012" build-time pre-render
  rejected on the evidenced ground that no Mermaid-to-SVG compiler exists in the repo.
- **feature-004** — the engine chart derived once into a deep-frozen `EngineCore` and composed
  per page, the two engine-scoped extraction rules, the kind-sibling parent-hop splice, and the
  two `BODY_PROVIDERS` dispatch rows.
- **The five seam reconciliations** listed under Notes — each a one-line contract decision, and
  each an explicit task rather than an implementer's discovery. *(The fifth, V9's enforcement
  point, was added at Detail and is already owner-answered as work Q3.)*

**Out of scope:** verbatim fragments and `canonical/` deep links (delivery-004); the interactive
panel (delivery-005). The `themeVariables` repair (KI-001) is an **owner decision**, not assumed
here — see Notes.

## Gate Criteria

- [ ] **AC-3 — Chart well-formedness.** Every generated chart has at least one entry node and at
      least one exit node, and every edge target resolves to a node in the same chart. Validator
      rules V1–V9 all enforced; any error throws rather than warns.
- [ ] **AC-4 — Feature coverage per structural class.** All four fixtures pass under vitest:
      `aid-describe` (Dispatch table), `aid-review` (inline `## State:`), `aid-create-api`
      (generated doorway → engine) and `aid-test-security` (kind-sibling → sibling skill), each
      containing the loop, branch and exit its resolved source expresses. Feature-003's third
      fixture, `aid-test`, additionally pins the ` then ` form that KI-008 exposed.
- [ ] **FR-2 — whole-corpus coverage.** Every skill in `canonical/skills/` has a chart. No skill
      falls through the classifier without one, and no page is left with an unfilled body slot.
- [ ] **V9 holds across both chart families** — authored-flow and doorway — so a dropped edge
      cannot fail silently, which is the defect class KI-008 belongs to.
- [ ] **No hard-coded corpus or per-shape count** anywhere in the shipped code or its tests. The
      classifier's `shapeCounts` manifest entry is the only authority for how many skills are of
      each shape.
- [ ] **AC-6 re-verified**, including feature-004's sharper cross-page guard: the engine segment
      is byte-identical across doorway pages, testable as `renderMermaid` minus the entry node and
      hop edge lines being string-equal for any two engine doorways.
- [ ] The **five** seam reconciliations under Notes are each **decided and recorded** — not
      silently resolved by whichever feature is implemented second. *(Seam 5, V9's enforcement
      point, was added at Detail and is already owner-answered as work Q3; recording it means
      capturing the delta against feature-003's SPEC text, which still says `validateChart`
      implements V1–V9.)*
- [ ] **V1–V9 are all enforced**, across the two modules seam 5 splits them into: V1–V8 in
      `validate.mjs` over a `FlowChart`, V9 in `advance.mjs` where the residue exists.
- [ ] Delivery-002's guarantees still hold: AC-1, AC-2 and AC-8 pass unchanged, and
      `gen-reference.mjs` remains byte-unmodified.
- [ ] **UI review checkpoint — NON-BLOCKING.** After **task-029**, the site is built and browsed,
      and a verdict is recorded in `deliveries/delivery-003/STATE.md`. This is the **first point at
      which real charts render**, and deliberately on a partial corpus: the authored-flow provider
      claims exactly `{dispatch-table, inline-states, residual}`, so roughly 27 skills are charted
      while the delegating majority keeps the placeholder comment until task-037. The subset is the
      interesting one — `aid-describe` (a fat Dispatch chart with loops and branches), `aid-review`
      (inline states), `aid-test` (the ` then ` branch), `aid-config` (a residual approximation).
      Judge node shapes, the 60-code-point label truncation, dark-theme legibility, and chart
      sizing on a long flow — against real content, at roughly 55% of the work rather than 100%.
      A Fail files a ticket; it does **not** block this gate.
- [ ] All section-6 quality gates pass

## Tasks

_none yet_ — `aid-detail` fills this table.

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-002 (body slot, `SkillRecord`, manifest, slug identity, drift guard)
- **Blocks:** delivery-004 (the `Provenance` interface and `buildFlowChart`), delivery-005 (the
  sidecar and DOM hooks H1–H5)

## Notes

**The four unreconciled seams — explicit work, not discoveries.** Specify hardened each feature's
contracts independently, and four seams between them do not yet line up. Each is a one-line
decision, but collectively they mean this delivery **reopens contract text delivery-002 froze**.
Feature-001 anticipates exactly this, framing the harness as "a published interface those SPECs
are written against; changing it is a cross-feature change, not a local one."

1. **Seam S3 is unmet.** Feature-003 requires that both a page and its sidecar be recorded in
   feature-001's manifest, so AC-1's drift guard covers sidecars too. Feature-001's manifest
   records pages only, its guard compares `*.md` under `src/content/docs/skills/`, and its
   exhaustive touch list says "nothing else". Decide whether the guard extends to sidecars.
2. **The manifest gains a fourth key nobody's contract admits.** Feature-003 writes `shapeCounts`
   into a manifest feature-001 specifies as "the same three-key shape" as
   `.reference-manifest.json`. Not a behavioural conflict — feature-001's assertions still pass —
   but the contract text needs one line of reconciliation.
3. **The body-slot heading.** Feature-004 fixes it to `## Flow`; feature-003 only requires "an
   H2". Pick one and state it once.
4. **`delegatesTo`.** Feature-003's D3 says the classifier captures it, while its published
   signature returns `{shape, evidence}`. Feature-004 has a fallback, so only duplicated work is
   at stake — but the signature should say what it returns.
5. **Where validator rule V9 is enforced** *(added at Detail; owner-answered as work Q3)*.
   feature-003 declares `validateChart(chart)` as a pure function over a `FlowChart`, but no
   `FlowChart` field carries the **residue** V9 tests — residue is leftover source text that
   exists only during parsing. As specified, V9 is unevaluable. **Owner decision: enforce V9 at
   extraction, in `advance.mjs`, where the residue still exists; `validate.mjs` implements V1–V8
   and documents that V9 lives in the parser.** Rejected: a residue carrier in the model, which
   would flow into the sidecar and require exclusion from feature-006's projection. feature-003's
   SPEC text should be corrected to match when next opened.

**Internal ordering.** feature-003 before feature-004, and **not concurrently**: 004 edits
`flow-graph/index.mjs` (two dispatch rows) and `body.mjs` (one provider entry), both created by
003. The two providers *partition* the shape enum, so array order is not load-bearing, and
feature-004 guards that with a test asserting exactly one `applies()` fires per directory.

**Owner decision, not assumed: KI-001.** `astro-mermaid` silently drops the site's custom
`themeVariables` palette because the integration forwards only `theme` and `mermaidConfig`, so
the site's existing diagrams render with the stock theme. Feature-003's charts emit their own
`classDef` block and are correct either way, so this is optional. If taken, it touches
`site/astro.config.mjs` — which delivery-002 also edits and delivery-005 will edit, so it must be
sequenced, never applied concurrently (risk R1).

**Accepted, not open:** KI-004 (charts degrade to raw diagram source without JavaScript —
delivery-004's static list is the stated mitigation) and KI-011 / KI-014 (the substrate's
failed-render and re-entrancy behaviours — delivery-005 designs around both).
