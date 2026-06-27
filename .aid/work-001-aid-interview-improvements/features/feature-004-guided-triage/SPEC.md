# Guided Triage

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-5, §6 NFR-2, §9 AC-7/AC-10, §10 P1 | /aid-interview |
| 2026-06-27 | Technical Specification authored: triage = thin consumer of the f002 engine (gap inventory / stop predicate / record sink instantiated); engine-driven draw-out replaces Step 1 free-form description, Steps 2-4 routing rule retained; 5-signal triage gap inventory (backbone-first sizing primary); KB-context detection (full/seed/no KB) + gap-targeting; recipe tooling + recon reused unchanged; RESOLVED the 002/004 opener seam -- D1 opener fires once in TRIAGE, carried forward via STATE.md ## Triage **Opener:** so CONTINUE skips it (f002 state-continue.md made conditional -- flagged); AI+human-review DoD | /aid-specify |
| 2026-06-27 | Gate cycle-1 fixes: (MEDIUM) the f002-reconciliation note updated to "DONE" (feature-002 already made the state-continue.md opener conditional — no stale "should reconcile" request, both specs agree); (LOW) seed-KB detection de-counted ("only forward-authored docs", ~4-6, marker-based not a fixed 5 — matches feature-003); (MINOR) lite-route locator Step 5a→Step 2b (recipe summary-match) | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-5, §6 NFR-2, §9 AC-7 / AC-10, §10 P1

## Description

Triage today leaves the user to self-describe the work with no guidance, so the description is
often insufficient to route correctly. This feature replaces that with analyst-driven triage:
using the same seasoned-analyst elicitation engine, the skill actively draws out from the user
the information needed to choose the right path (full vs lite) and the right recipe, instead of
relying on a raw free-form description. It is KB-context-aware and works in both contexts — when
the project already has a full KB (brownfield, after aid-discover) and when it has only a seed KB
(greenfield) — leveraging whatever KB exists to ask sharper, gap-targeted questions. The existing
brownfield path (aid-discover KB plus the standard interview) must keep working unchanged;
guided triage is additive.

## User Stories

- As the work-definer (human), I want the analyst to draw out the path- and recipe-deciding
  details rather than making me self-describe so that my work is routed to the right path and
  recipe.
- As the work-definer on a project that already has a KB (full or seed), I want triage to use
  that KB as context so that it asks sharper, gap-targeted questions.
- As an AID adopter on an existing brownfield project, I want the established aid-discover plus
  standard interview path to keep working so that the new guided triage is purely additive.

## Priority

Must

## Acceptance Criteria

- [ ] Given a user describing a new work, when triage runs, then the analyst draws out the
  path-deciding information and routes to the right path and recipe. *(AC-7)*
- [ ] Given a project with a full KB or only a seed KB, when triage runs, then it works in both
  contexts and leverages the available KB as context. *(AC-7)*
- [ ] Given the existing brownfield path, when this feature ships, then aid-discover plus the
  standard interview path still passes its tests. *(AC-10, NFR-2)*

---

## Technical Specification

> Authored by `/aid-specify` from feature-001 `findings.md` (Rec B, RQ-B3 + the Family-4
> backbone-first/walking-skeleton sizing move; Section 3 grill-me stopping-rule contrast), the
> feature-002 engine SPEC (Engine Overview, Next-Move Selection, Consumption Contract, the
> 002/004 seam note), the feature-003 SPEC (the seed-KB context triage operates in), the
> owner-ratified decisions D1/D2/D3 in `STATE.md ## Cross-phase Q&A`, and the on-disk triage
> machine `canonical/skills/aid-interview/references/state-triage.md` + the recipe tooling.
> Authoritative requirements: REQUIREMENTS.md FR-5, NFR-2, AC-7, AC-10.

### Scope boundary (what this feature owns vs consumes)

feature-004 **consumes** the feature-002 seasoned-analyst engine; it does NOT re-implement or
re-spec it. Per the f002 Consumption Contract, a consumer supplies exactly three parameters
(gap inventory / stop predicate / record sink) and the engine returns control to the host state
when its stop check fires.

| Owned by feature-004 (this spec) | Consumed from feature-002 (engine) |
|----------------------------------|-------------------------------------|
| The **triage gap inventory** (the path/recipe-deciding signals), **stop predicate** (route-with-confidence), and **record sink** (the `## Triage` block) -- the three Consumption-Contract parameters, instantiated for triage | The conversation itself: the single fixed D1 opener, the adaptive next-move loop, the move playbook (esp. moves 1/4/5/8), calibration, and the NFR-7 envelope |
| The **routing decision + confirmation turn** (`state-triage.md` Steps 2-4) -- workType inference, recipe match, the route-with-confidence rule, escalate-lite->full | The stopping rule's conversational enforcement (engine halts at minimal-but-sufficient -- here, route-with-confidence) |
| **KB-context awareness** (FR-5 / AC-7): detecting full-KB vs seed-KB vs no-KB, and gap-targeting from it | -- |
| The **002/004 opener seam** -- de-dup of the D1 opener across TRIAGE and CONTINUE (resolved below) | The opener's *content* and NFR-7-by-construction property (f002 owns the opener text) |

The recipe set (`canonical/aid/recipes/`), `parse-recipe.sh`, and `recon-classify.sh` are
**reused unchanged** (no script edit); guided triage is additive (NFR-2 / AC-10).

### The 002/004 opener seam -- resolution (CRITICAL; deferred to feature-004 by f002)

feature-002 set the single D1 what+why opener as shared, re-pointed `state-triage.md` Step 1 at
it, and replaced `state-continue.md`'s bare opener with it -- but left the exact TRIAGE->CONTINUE
turn-ordering to feature-004 so the opener is **not asked twice**. Resolution:

**The D1 opener fires exactly ONCE, in TRIAGE (the engine's fixed turn 1).** Its answer is used
for two things at once: (a) **read for routing** -- the first path/recipe signal + the seed
calibration read; and (b) **carried forward as the first captured intent** into the elicitation
loop (CONTINUE on the full path; the recipe/condensed-intake seed on the lite path) so it is
never re-asked. This is exactly the f002 loop diagram split across two host states: the
`EMIT D1 OPENER -> READ answer -> capture first vocabulary + seed calibration` head runs in
TRIAGE; the `ADAPTIVE LOOP` body runs in CONTINUE (full path).

**De-dup mechanics (state machine):**

1. **TRIAGE Step 1 (engine turn 1).** Emit the D1 opener ONCE; read the answer; record it
   verbatim as the captured opener intent (first vocabulary capture per D1; seed calibration
   signal per RQ-B2).
2. **TRIAGE Step 6 persists it.** The opener answer is written to `STATE.md ## Triage` as a new
   grep-recoverable `**Opener:**` field, alongside the existing routing fields. (It is the same
   value the current machine records internally as `{description}` -- now persisted, not
   transient.)
3. **Full route -> CHAIN to CONTINUE.** CONTINUE already reads `STATE.md` on entry. It checks for
   `## Triage **Opener:**`: when present, the engine's turn 1 already fired in TRIAGE, so CONTINUE
   **does NOT re-emit the D1 opener**. It seeds the adaptive loop with the opener answer as the
   first captured intent (vocabulary + calibration state already read) and enters at the loop's
   STOP-CHECK / GAP-SELECTION step (f002 loop, the post-opener body).
4. **Fallback (defensive).** If `**Opener:**` is absent -- a legacy direct-CONTINUE entry, a
   pre-TRIAGE in-flight work (the backward-compat case named in the `SKILL.md` State Detection section),
   or a loopback with no triage record -- CONTINUE emits the D1 opener itself. This is f002's
   replacement, now made **conditional**.
5. **Lite route.** The opener answer is already the `{description}` the lite states consume
   (recipe summary-match in Step 2b / the CONDENSED-INTAKE seed); no re-ask. This composes
   cleanly with the existing `## Escalation Carry` path -- CONTINUE skips the opener when EITHER
   an Escalation Carry block OR an `**Opener:**` capture is present.

**f002 reconciliation (DONE).** feature-004 makes the `state-continue.md` D1-opener emission
**conditional** (CONTINUE emits it ONLY when no `## Triage **Opener:**` capture exists). feature-002
SPEC has been reconciled to match -- its `state-continue.md` Layers row + flow note now read
"conditional D1 opener -- skipped when TRIAGE already captured it (feature-004 de-dup)", with the
opener's *content* still owned by f002. The two specs agree; no further action needed.

### Triage flow / state model (where it plugs in)

Guided triage replaces `state-triage.md` **Step 1's free-form self-description** with an
engine-driven draw-out, while **preserving Steps 2-4's routing computation** (the input changes,
the routing rule does not). The state position is unchanged: `FIRST-RUN -> TRIAGE -> {full:
CONTINUE | lite: CONDENSED-INTAKE / recipe}` (the `SKILL.md` State Detection section). The State Detection
table, the dispatch rows, and the `Path:` sentinel semantics are untouched.

```
FIRST-RUN 1a reads .aid/knowledge/INDEX.md (if any)  -- KB-context available to TRIAGE
        |
        v
TRIAGE Step 1  (engine turn 1)  -- EMIT D1 opener ONCE -> READ -> capture opener intent
        |                          (replaces the free-form "Describe the work..." prompt)
        v
TRIAGE Step 1b  (engine TRIAGE-mode loop)  -- draw out the path/recipe signals still open,
        |        gap inventory below; stop predicate = route-with-confidence; KB-gap-targeted.
        |        Common case: the opener alone is sufficient -> stop check fires immediately
        |        (preserves the one-turn-common-case NFR); ambiguous/sprawling work draws out more.
        v
TRIAGE Step 2  (routing computation -- UNCHANGED rule)  -- 2a workType heuristic + 2b recipe
        |        summary-match + confidence judgment, now fed by the DRAWN-OUT signals not a raw line.
        v
TRIAGE Step 3  (engine route-confirmation turn)  -- the NFR-7 straw-man reflect-back
        |        ("looks like a lite work -- the backbone is a single end-to-end slice; agree?"),
        |        which IS the existing single confirmation turn, reframed as an engine emission.
        v
TRIAGE Step 4  (routing decision -- UNCHANGED table)  -> lite (+recipe) | full | escalated
        |
        v
TRIAGE Step 6 writes ## Triage (+ the new **Opener:** field) ; Step 7 advances (CHAIN).
```

Steps 5a (recipe slot-fill), 5b, 6, and 7 are unchanged in mechanism. Step 1b is the new
engine-loop wrapper; Steps 1 and 3 are the engine's opener and confirmation emissions (NFR-7).

### The triage gap inventory (the route-deciding signals)

The gap inventory feature-004 supplies to the engine -- the signals the loop must draw out to
pick full-vs-lite and select a recipe. Traceable to findings RQ-B3 and the existing
`state-triage.md` Step 2 logic:

| # | Signal (gap) | Decides | Playbook move (f002) | Source |
|---|--------------|---------|----------------------|--------|
| 1 | **Scope size / shape** -- is the work a single end-to-end slice, or a sprawling multi-activity backbone? | **full vs lite** (primary) | Backbone-first + walking-skeleton (move 5) | RQ-B3 primary signal; User-Story Mapping (Family 4) |
| 2 | **Work-type** -- bug-fix / new-feature / refactor | lite **Sub-path** | (workType heuristic; no new move) | `state-triage.md` Step 2a |
| 3 | **Target artifact identity** -- the concrete thing touched (endpoint, entity, class, rule, doc...) | **recipe match** | Concrete-example probe (move 8) feeding the summary-match | `state-triage.md` Step 2b; Example Mapping (Family 8) |
| 4 | **Behavior/flow span** (process-heavy work) -- event-timeline length | scope size (secondary) | Event-first, propose-timeline-back (move 4) | RQ-B3 secondary signal; Event Storming (Family 3) |
| 5 | **KB anchoring** -- does the work map to a named KB module/concept? | sharper sizing; skip-what-KB-answers | KB-gap-targeting (calibration + straw-man) | RQ-B3 KB-context-aware; FR-5 |

**Stop predicate (route-with-confidence).** The loop halts as soon as (a) full-vs-lite is
decided AND (b) recipe confidence resolves to one of `single clear winner | several plausible |
none` (the existing Step 2b confidence judgment). This is the consumer's instantiation of the
engine's minimal-but-sufficient stop check -- the discipline grill-me lacks (findings Section 3): triage
stops at "enough to route," it does not interrogate every branch.

**Record sink.** Each confirmed signal is written to `STATE.md ## Triage` (the existing Step 6
schema: `Path` / `Work Type` / `Sub-path` / `Recipe` / `Decision rationale`) plus the new
`**Opener:**` capture. The record sink is the `## Triage` block, not REQUIREMENTS.md.

### KB-context awareness (AC-7 / FR-5)

**Context detection.** TRIAGE reads `.aid/knowledge/INDEX.md` (already loaded by `FIRST-RUN`
Step 1a) and classifies the context it is in:

| Context | Detection signal | Anchor the analyst uses |
|---------|------------------|--------------------------|
| **Full brownfield KB** (post-`aid-discover`) | INDEX.md present AND as-built docs exist (`module-map.md`, `test-landscape.md`, etc.) / `source: generated`; corroborated by `.aid/generated/recon.md` proposing `BROWNFIELD-*` | The real module map + named bounded contexts |
| **Seed KB** (greenfield, feature-003) | INDEX.md present with only forward-authored docs (`source: forward-authored`; the seed's 4 core + conditional `decisions.md` + any domain-promoted extensions per feature-003, i.e. ~4-6 docs — count-independent: detection keys on the marker / absence of `source: generated`, not a fixed count); corroborated by `recon.md` proposing `GREENFIELD` | The declared concept-spine + intended architecture |
| **No KB** (bare greenfield) | INDEX.md absent | The opener answer alone; the engine draws everything out |

**Gap-targeting (the AC-7 "sharper questions" bar).** In gap selection, the engine skips any
inventory signal the KB already answers and converts it into a confirm-not-elicit straw-man. With
a full KB the analyst names the targeted module/context from the KB and proposes the sizing
directly ("this touches `OrderSvc`, which the KB describes as a single module -- looks like a lite
refactor; agree?"); with a seed KB it anchors on the declared spine + intended architecture; with
no KB it draws the signals out from scratch. Either way NFR-7 holds (every question carries a
suggested answer + rationale), and the same gap inventory + stop predicate apply -- only the
*evidence the questions are anchored in* changes. This is feature-004's parameterization of the
gap inventory, exactly as the f002 Consumption Contract notes.

### Routing decision (reuse the existing machinery)

The route is computed by the **unchanged** Step 2-4 logic, now fed by the drawn-out signals:

- **Step 2a workType** -- the bug-fix / new-feature / refactor heuristic and the workType->Sub-path
  map (`LITE-BUG-FIX` / `LITE-REFACTOR` / `LITE-FEATURE`) are unchanged.
- **Step 2b recipe match** -- scan the recipe set (the skill resolves it at runtime as
  `canonical/recipes/` relative to the install root; source-of-truth `canonical/aid/recipes/`),
  read each `applies-to` + `summary:`, build the candidate set (`applies-to == workType` OR
  wildcard `'*'`, e.g. `add-test-coverage`), pick the best summary match + a confidence judgment.
  Front-matter parsing and the wildcard rule are unchanged; `parse-recipe.sh --validate` /
  `--list` / `--render` are reused verbatim for the slot-fill + emit path (Step 5a).
- **Step 4 routing table** -- unchanged and intentionally conservative: anything short of one
  confident, user-confirmed single recipe routes to **full** (or lite-no-recipe for the empty-set
  edge). The full-vs-lite split now leans primarily on signal #1 (backbone sizing) rather than a
  raw description string, but the deterministic table is byte-unchanged.
- **Escalate-lite->full -- PRESERVED.** The `[2]` reject / escalation-phrase -> full route, the
  `recipe-to-lite-escalation.md` (Trigger A/B) slot-fill escape, and the `lite-to-full-escalation.md`
  carry path are untouched; `Path: escalated` sentinel semantics and the `## Escalation Carry`
  hand-off into CONTINUE are unchanged (and compose with the opener de-dup, above).

`recon-classify.sh` is **read, not changed**: its `GREENFIELD / BROWNFIELD-SMALL / BROWNFIELD-LARGE`
classification (upstream of `aid-interview`) is a corroborating context signal only; triage adds no
threshold and writes no `recon.md`.

### Layers & Components -- files touched (real on-disk paths)

All under `canonical/skills/aid-interview/` (migrates to `aid-describe/` under feature-006, D3).
No script and no schema change is introduced by feature-004.

| File | Change |
|------|--------|
| `canonical/skills/aid-interview/references/state-triage.md` | Step 1 becomes the engine turn-1 opener (already re-pointed by f002) wrapped by a new **Step 1b** TRIAGE-mode engine loop over the gap inventory; Steps 2-4 retained as the routing computation (now fed by drawn-out signals); Step 6 gains the `**Opener:**` capture field; KB-context detection added at state entry |
| `canonical/skills/aid-interview/references/state-continue.md` | The D1 opener emission (set by f002) is made **conditional** -- skipped when `## Triage **Opener:**` is present; emitted only on the legacy/direct-entry fallback (the f002 reconciliation flagged above) |
| `canonical/skills/aid-interview/references/elicitation-engine.md` (f002) | No edit to the engine; feature-004 supplies the TRIAGE consumer-parameterization (gap inventory / stop predicate / record sink) as documented in the f002 Consumption Contract |

**Reused unchanged (reference, no edit):** `canonical/aid/recipes/` (the recipe set),
`canonical/aid/scripts/interview/parse-recipe.sh`, `canonical/aid/scripts/kb/recon-classify.sh`,
`references/recipe-to-lite-escalation.md`, `references/lite-to-full-escalation.md`, and the
`state-triage.md` "Unit-testable mapping rules" routing/override/recipe-offer tables (task-014 /
015 / 028 / 029 scope) -- the routing rule they pin is unchanged.

### Consumption-contract instantiation (the three engine parameters)

| Parameter | feature-004 value |
|-----------|-------------------|
| **gap inventory** | The 5 route-deciding signals above (scope size, work-type, target identity, behavior span, KB anchoring) |
| **stop predicate** | route-with-confidence: full-vs-lite decided AND recipe confidence in `{single clear winner, several plausible, none}` |
| **record sink** | `STATE.md ## Triage` (existing Step 6 schema + the new `**Opener:**` carry field) |

### Out of scope (referenced, not re-specified here)

- The engine itself -- the opener, the adaptive loop, the move playbook, calibration, the NFR-7
  envelope -- **feature-002**.
- The greenfield seed content model + the `source: forward-authored` marker + the seed gate --
  **feature-003** (triage only *reads* the seed KB it produces).
- The `aid-describe` / `aid-define` skill split -- **feature-006** (D3; sequenced after 002-004).

### Definition of Done / Verification

Skills are prose-executed, not unit-tested; verification follows the AID **AI + human-review**
path (the `references/reviewer-brief.md` checklist + the `>= A` work review gate), supplemented by
**dogfood transcripts**. feature-004 adds no script, so the recipe + recon harnesses are unaffected.

| DoD | Operationalization | Source AC |
|-----|--------------------|-----------|
| **D1 -- Analyst draws out + routes, both KB contexts** | Two triage dogfood transcripts -- one on a **full brownfield KB**, one on a **seed KB** -- each showing (a) the D1 opener fired ONCE, (b) the engine drew out the path/recipe signals with NFR-7 envelopes, (c) gap-targeted questions that skip what the KB already answers, (d) a correct route. Plus one transcript where a single end-to-end slice -> **lite + recipe** and one where a sprawling backbone -> **full**. | AC-7, FR-5 |
| **D2 -- Opener de-dup holds** | In a TRIAGE->CONTINUE transcript the D1 opener appears **exactly once**; CONTINUE enters the adaptive loop with the opener answer as the first captured intent (no re-ask); the fallback path (no `**Opener:**`) emits it. Reviewer confirms `state-continue.md`'s opener is conditional. | AC-7 (de-dup), D1/D2 |
| **D3 -- Routing rule unchanged** | The `state-triage.md` "Unit-testable mapping rules" routing/override/recipe-offer tables still hold (the route is computed by the unchanged Steps 2-4); reviewer confirms the conservative full-vs-lite rule and the escalate paths are byte-unchanged. | AC-10, NFR-2 |
| **D4 -- Brownfield intact** | `tests/canonical/test-parse-recipe.sh` (19 units) and `tests/canonical/test-recon-classify.sh` still pass; `parse-recipe.sh`, `recon-classify.sh`, the recipe set, and `aid-discover` are untouched; the existing brownfield full-path interview completes unchanged (the only CONTINUE change is the additive, conditional opener skip). | AC-10, NFR-2 |
