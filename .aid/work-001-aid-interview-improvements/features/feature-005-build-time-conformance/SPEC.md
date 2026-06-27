# Build-Time Conformance Lifecycle

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-4, §6 NFR-5, §8 D-4, §9 AC-6, §10 P2 | /aid-interview |
| 2026-06-27 | Technical Specification authored: conformance model (per seed element), the extract-and-diff detection mechanism (shadow extraction reusing aid-discover subagents + concern-keyed structured diff at seed altitude + divergence classifier), design->code authority + flag-never-overwrite, the aid-housekeep KB-DELTA conformance-lane hook (carving forward-authored docs OUT of KB-DELTA's update-the-doc lane), the human-gated reconciliation flow, the `source: forward-authored` marker dependency, layers/components, and DoD operationalizing AC-6/NFR-5; grounded in feature-001 findings.md sec.6 #7, feature-003 SPEC (the marker + freshness short-circuit), and the f007 on-disk facts | /aid-specify |
| 2026-06-27 | Gate cycle-1 fixes: (HIGH) made the shadow-extraction redirect concrete — the extraction subagents hard-code "write only to .aid/knowledge/", so feature-005 adds a small additive `output_root` dispatch parameter (default preserves all callers) + a keep-only-in-scope filter; "reused as-is/None" corrected to a real (small) edit, safety enforced by construction; (LOW) corrected "KB-DELTA partitions by source" → by VERDICT (source-routing is this feature's addition); (LOW) fixed the dangling "Open Question" cross-ref → DoD V5 | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-4, §6 NFR-5, §8 D-4, §9 AC-6, §10 P2

## Description

In greenfield, the forward-authored seed is the authoritative design contract (design→code), the
opposite of the brownfield default where code is the source of truth and docs describe it. As
code is later written by aid-execute, the job is to verify the code conforms to the design and to
reconcile any divergence deliberately — not to silently replace the design with as-built. This
feature builds a NEW conformance check that detects when as-built code diverges from the design and
flags it for human reconciliation. (Cross-ref: the existing f007 freshness mechanism CANNOT do this
— it is read-only and source→doc directional, detecting "a sources: file changed," not "code diverged
from this doc," and a seed has no file-sources; and nothing auto-overwrites docs today, so the new
work is the check direction + greenfield-origin marking, not riding on f007.) Authority stays
design→code until a human reconciles the drift; all reconciliation is human-gated. This is the P2
lifecycle layer that becomes meaningful only once the greenfield seed model exists.

## User Stories

- As an AID maintainer, I want a greenfield-origin doc's divergence from as-built code flagged for
  human reconciliation rather than auto-overwritten so that the authored design stays the source
  of truth until I deliberately reconcile it.
- As the work-definer (human) whose seed is the design contract, I want authority to stay
  design→code until reconciled so that code is held to conform to my design, not the reverse.
- As an AID maintainer, I want a new conformance check (code→design divergence) — which f007 cannot
  provide, being read-only and source→doc directional — so that a greenfield seed's divergence from
  later as-built code is surfaced for human reconciliation rather than going undetected.

## Priority

Must

## Acceptance Criteria

- [ ] Given a greenfield-origin doc, when its content diverges from the as-built code, then the
  divergence is flagged for human reconciliation and is not auto-overwritten. *(AC-6)*
- [ ] Given detected divergence, when reconciliation occurs, then it is human-gated and authority
  stays design→code until reconciled. *(AC-6, NFR-5)*

---

## Technical Specification

> Authored by `/aid-specify` from feature-001 `findings.md` (sec.6 risk #7 -- the unbuilt
> code->design conformance check + the D-5 review-gate note), feature-003 `SPEC.md` (the
> `source: forward-authored` marker, the seed-content model, and the freshness short-circuit),
> REQUIREMENTS.md (FR-4, NFR-5, C-1, C-4, AC-6, D-4), and the on-disk facts of f007
> (`kb-freshness-check.sh`), aid-discover extraction (`references/agent-prompts.md`,
> `references/state-generate.md`), and aid-housekeep (`references/state-kb-delta.md`). The spike
> did NOT research a conformance mechanism (it was out of scope); the mechanism below is
> **proposed here** and justified against the existing machinery it reuses.

### Scope boundary (what this feature owns vs depends on)

| Owned by feature-005 (this spec) | Depends on (not owned here) |
|----------------------------------|------------------------------|
| The **code->design conformance check** -- detection mechanism, divergence model, false-positive control | The `source: forward-authored` **marker** + the freshness short-circuit (feature-003) -- this feature *consumes* the marker to scope itself |
| The **aid-housekeep KB-DELTA carve** -- routing forward-authored docs out of the update-the-doc lane into the conformance lane | The aid-discover **extraction subagents** + harvest/closure scripts (reused as-is; no new extractor) |
| The **divergence flag + human-gated reconciliation flow** (Required Q&A, present-the-choice, never auto-edit) | The **seed-content model** (which 5 docs/concerns exist -- feature-003) |
| The **placeholder-resolved** path for TBD tech-stack versions (feature-003 explicitly handed this here) | aid-discover's **Q&A + targeted re-entry** machinery (reused to drive a human-chosen reconciliation) |

**Placement.** Per C-2 (extend, do not fork) the check is an additive **conformance lane**
inside the existing `aid-housekeep` `KB-DELTA` state (`canonical/skills/aid-housekeep/references/state-kb-delta.md`),
not a new skill. It reuses KB-DELTA's existing freshness pre-pass, scope-confirm gate, and
Required-Q&A-into-`/aid-discover` mechanics, and ADDS source-frontmatter as a new review-routing
dimension (KB-DELTA today partitions its review set by VERDICT, not by source); it adds the
forward-authored carve, the
extract-and-diff comparator, and the flag-don't-overwrite reconciliation.

### Why this is genuinely new work (not f007, not KB-DELTA-as-is)

Two existing mechanisms look adjacent but provably cannot do code->design conformance; the new
work is the **check direction** + the **flag-not-overwrite reconciliation** keyed off the marker.

| Mechanism | Direction | What it detects | Why it CANNOT do feature-005's job (confirmed on disk) |
|-----------|-----------|-----------------|--------------------------------------------------------|
| **f007 freshness** (`kb-freshness-check.sh`) | source->doc, read-only | "a `sources:` file changed in git since `approved_at_commit:`" (lines 240-276, `check_source`) | A forward-authored seed doc has `sources: []` or points at the intent record, **never at code** -- so there is nothing for f007 to drift-check against. And `check_doc()` folds an empty/absent `sources:` straight to verdict `current` (lines 303-329), which feature-003 *reinforces* with an explicit `forward-authored -> current` short-circuit. f007 is structurally blind to "the code diverged from this doc." |
| **KB-DELTA Tier-2 review** (`state-kb-delta.md` Step 2) | repo->doc, **overwrite** | "does what this doc asserts still match the repo? if not, **update the doc**" (re-discover, Step 4 targeted re-entry) | Its reconciliation **direction** is to update the doc to match the repo (overwrite from as-built). KB-DELTA's scope-confirm (Step 3) is human-gated, so this is not a *silent* overwrite -- but the gate asks the wrong question for a design-authoritative doc ("refresh this doc?" routine-drift framing), and the direction itself (doc<-code) is exactly the one **NFR-5 forbids** for a forward-authored seed. Confirming the brownfield refresh prompt would discard the design and adopt the as-built. |

**Load-bearing consequence (the central integration point).** Because KB-DELTA's existing
Tier-2 lane reviews the *entire* KB (a forward-authored doc folds to `current` and lands in
Tier 2) and its reconciliation direction is doc<-code, **feature-005 MUST carve
`source: forward-authored` docs OUT of KB-DELTA's update-the-doc lane and INTO the conformance
lane** (flag-not-overwrite). Without this carve, confirming KB-DELTA's routine scope-refresh
prompt on a greenfield seed reconciles in the NFR-5-forbidden direction (doc<-code). (This
mirrors feature-003's panel-exclusion carve -- a single shared doc-set review path disambiguated
by the `source` value.)

### Conformance model -- what "conforms" means per seed element

The in-scope docs are exactly the feature-003 seed's elements (it never authors the as-built
docs). For each, "conforms" and "divergence" are defined at the seed's **declared altitude**
(sketch / minimal-but-sufficient), NOT at full as-built granularity -- this is the primary
false-positive control:

| Seed element (feature-003) | Doc | Concern | Conforms when... | Divergence looks like... |
|----------------------------|-----|---------|------------------|--------------------------|
| Concept-spine / ubiquitous language | `domain-glossary.md` | C4 | Every declared term is used in code with the declared meaning; no load-bearing (top-ranked) as-built term is undeclared | A declared term the code uses with a **contradicting** meaning/boundary; OR a top-ranked harvested as-built term used pervasively that the glossary never declares (scope drift / undeclared concept) |
| Intended architecture | `architecture.md` | C1 | Every declared boundary + relationship + `## Invariants` holds in the as-built layout | The as-built code **violates a declared invariant/boundary**; OR a new top-level module/boundary at sketch altitude that the design never named |
| Conventions & standards | `coding-standards.md` | C3 | The declared rules are followed in code (or the doc declared "no project-specific deviations yet") | The code establishes a convention that **contradicts** a declared rule |
| Technology stack / medium | `technology-stack.md` | C0 | The chosen language/runtime/framework matches the as-built config; a TBD-until-scaffolded version is now resolvable | The code uses a **different** stack than declared (contradiction); OR a declared TBD/`latest-at-init` version is now **pinned** in config -- the benign `placeholder-resolved` path feature-003 handed here |
| Decisions & rationale | `decisions.md` | D | Each recorded decision is reflected in the as-built code | The code **reverses** a recorded decision (chose the rejected alternative) |

Three delta classes fall out, only two of which are flagged:

- **design-ahead** -- the design declares X the code has not built yet. **NOT a divergence.**
  Forward-authoring leads; the unbuilt item is expected. Not flagged.
- **placeholder-resolved** -- a declared TBD/`latest-at-init` value (tech-stack version, build
  command) now has a concrete as-built value. A **low-friction** flag: "the design left this
  TBD; the code now pins it to <X> -- adopt <X> into the design?" Still human-gated.
- **code-ahead / contradiction** -- the code contradicts a declared invariant/definition/
  boundary/decision, OR introduces a load-bearing (seed-altitude) element the design never
  declared. The real **divergence** -- flagged for human reconciliation.

### Detection mechanism -- extract-and-diff (the crux)

The chosen mechanism is **extract-and-diff**: re-derive the as-built view from the now-existing
code by **reusing aid-discover's extraction**, then run a **concern-keyed structured diff** of
the as-built view against the forward-authored design docs, and **classify** each delta. This is
recommended over inventing a bespoke semantic comparator because every input and most of the
pipeline already exists; the only genuinely new piece is the diff/classifier judgment (which is
agent-driven, exactly like KB-DELTA's existing Tier-2 content review -- see Step 4). End to end:

**Step 1 -- Scope by the marker (deterministic).** Enumerate the design-authoritative set:
every `.aid/knowledge/*.md` whose frontmatter `source: forward-authored`. This reuses the exact
`fm_scalar "$f" "source"` accessor f007 already uses (`kb-freshness-check.sh` lines 143-156,
393-396). Brownfield `hand-authored` / `generated` docs are **out of scope** -- no behavior
change for them. If the set is empty (no greenfield seed in this repo), the lane no-ops and
KB-DELTA proceeds unchanged. Read each in-scope doc's concern from its `tags:` (the `C0/C1/C3/C4/D`
ID) -- the same concern keying the doc-set uses.

**Step 2 -- Extract the as-built view into a shadow location (parameterized subagent reuse).**
Dispatch the aid-discover extraction subagents (`canonical/skills/aid-discover/references/agent-prompts.md`:
Scout + the concern-matched deep-dive among Architect / Analyst / Integrator / Quality). Those
subagents today **hard-code** their KB-doc destination as `.aid/knowledge/` (agent-prompts.md
lines 165/218/260/309/355, Scout 420) with NO configurable destination -- so reusing them verbatim
would write the as-built docs straight over the forward-authored design, the exact NFR-5/AC-6
violation this feature prevents. feature-005 therefore makes a **small additive change**: add an
**`output_root` dispatch parameter** that parameterizes ONLY the **KB-doc destination** (default
`.aid/knowledge/`), so the write rule becomes "write the KB docs to the dispatch-provided
`output_root`". Scoped this way every existing caller (/aid-discover, /aid-housekeep) is unaffected
by the default -- including the two agents (Analyst line 218, Integrator line 309) that ALSO write
`.aid/generated/`: that secondary `.aid/generated/` output is **left untouched** (the parameter
governs the KB-doc root only, not the generated-artifacts path). The conformance lane dispatches with
`output_root=.aid/.temp/conformance/as-built/`, so **`.aid/knowledge/` is never written by this
step -- the safety invariant is enforced by construction, not by convention.** (The conformance lane
ignores any `.aid/generated/` side-output; only the KB docs in the shadow root feed the diff.) Because each deep-dive
agent owns a FIXED multi-doc bundle (e.g. Analyst emits module-map[C2] + schemas[C5] +
coding-standards[C3]; Quality emits test-landscape[C6] + infrastructure[C8]), the lane (a) dispatches
only the agents whose bundle intersects the seed's declared concerns, and (b) **keeps only the
in-scope docs** (C0/C1/C3/C4/D) from the shadow tree for the diff, discarding any out-of-scope
as-built docs the bundle also produced. The kept set is the as-built `architecture.md` /
`domain-glossary.md` / `coding-standards.md` / `technology-stack.md` / `decisions.md` for the
dimensions the seed declared -- the same docs, from code, in a sandbox. For C4 specifically, the
ranked as-built term universe is the deterministic `harvest-coined-terms.sh` output
(`canonical/aid/scripts/kb/harvest-coined-terms.sh`, `--top 60`) -- it supplies both the
"undeclared load-bearing term" signal and the altitude filter (only top-ranked terms count).

**Step 3 -- Concern-keyed structured diff (agent-driven, at seed altitude).** For each in-scope
forward-authored doc, match it to its shadow as-built counterpart **by concern** (same `tags:`
ID -> same filename in the seed model), then compute an **element-level** diff -- not a textual
line diff -- against the conformance model table above. The comparator is an `aid-architect`/
`aid-reviewer`-class judgment (no new deterministic script), the same tier of judgment KB-DELTA's
Tier-2 "does this doc still match the repo?" review already performs. Its inputs per concern:
- C4: declared glossary terms vs the harvested top-N as-built terms + `closure-check.sh`
  (`canonical/aid/scripts/kb/closure-check.sh`) grounding output -- a declared term that no
  longer grounds in code is `design-ahead`; a top-ranked code term absent from the glossary is
  `code-ahead`; a term grounded with a contradicting meaning is `contradiction`.
- C1/C3/C0/D: the shadow as-built doc's named elements (boundaries, invariants, rules, stack
  versions, decisions) vs the seed doc's declared elements, classified by the table above.

**Step 4 -- Classify + filter (false-positive control).** Each delta is labeled `design-ahead`
| `placeholder-resolved` | `code-ahead` | `contradiction`. Only `placeholder-resolved` (low
friction) and `code-ahead` / `contradiction` (real divergence) are carried forward.
`design-ahead` is dropped (forward-authoring leads -- expected, not a finding). The seed-altitude
filter is enforced here: an as-built detail BELOW the seed's declared altitude (an unnamed helper
module, an implementation-only identifier) is **not** a `code-ahead` divergence -- only elements
that rise to the seed's altitude (a top-ranked spine term, a top-level boundary, a declared-rule
contradiction, a pinned-but-TBD version) qualify. This is what stops the diff from flooding the
user with every implementation detail the intentionally-minimal sketch omitted.

**Concreteness verdict.** The mechanism is **concrete enough to build without a spike.** Every
input exists (the marker, the extraction subagents, the harvest/closure scripts, the Q&A/gate
machinery), and the one new piece -- the concern-keyed diff/classifier -- is an agent judgment of
the same class KB-DELTA already ships (Tier-2 content review), not a novel deterministic
algorithm. The single residual to **tune during build** (not research) is the seed-altitude
calibration of the `code-ahead` filter -- how aggressively to suppress sub-altitude as-built
detail. That is a fixture-driven threshold to settle in the IMPLEMENT/TEST tasks, not a research
unknown; see DoD V5 (the fixture-tuned acceptance item).

### Direction + authority (D-4 / NFR-5) -- flag, never overwrite

- **Authority stays design->code.** The forward-authored doc is the contract; the code is held
  to it. The check's output is a **divergence flag**, never a doc edit.
- **The check NEVER writes `.aid/knowledge/*.md`.** It writes only to `.aid/.temp/conformance/`
  (the shadow extraction + a divergence report) and a Required Q&A entry. The design doc's bytes,
  its `source: forward-authored` marker, and its f007 `current` verdict are all unchanged by the
  check.
- **Divergence is surfaced for HUMAN reconciliation** (Step 4 below). Until the human reconciles,
  the design remains authoritative and unchanged -- this is the design->code-until-reconciled
  invariant NFR-5 / AC-6 require, and the precise contrast with f007 (read-only, source->doc) and
  with KB-DELTA's default doc<-code overwrite.

### Where / when it runs (lifecycle hook)

Primary home: **`aid-housekeep` `KB-DELTA`** (`canonical/skills/aid-housekeep/references/state-kb-delta.md`)
as a conformance lane. Rationale, grounded in the existing flow:
- KB-DELTA is already AID's "reconcile the repo against the KB" job: it runs the f007 freshness
  pre-pass and partitions its review set by VERDICT (the only `source`-frontmatter use today is
  `should_check()` skipping `generated` docs -- source-based REVIEW-routing is what this feature
  adds), already re-dispatches the aid-discover extraction subagents, is already human-gated
  (Step 3 confirm-scope), and already
  drives reconciliation via Required Q&A into `/aid-discover` (Step 4). The conformance lane is
  the forward-authored counterpart of the same machinery -- minimal new surface, maximal reuse.
- Its **cadence fits**: the check is meaningful only once code exists and is naturally periodic /
  post-execute (housekeep is the on-demand "once code has accumulated" sweep), not per-edit.

Concrete wiring in `state-kb-delta.md`:
- **Step 1/2 carve:** when partitioning docs, route `source: forward-authored` docs to the
  conformance lane and **exclude them from the Tier-2 update-the-doc set** (the NFR-5 carve).
- **New conformance sub-step (after Step 2, before the no-drift exit):** run extract-and-diff
  (mechanism Steps 1-4 above) over the carved set; if any `placeholder-resolved` /
  `code-ahead` / `contradiction` delta is found, enter the reconciliation flow below.

Secondary (optional) **signpost only**: `aid-execute`'s `DELIVERY-GATE`
(`canonical/skills/aid-execute/references/state-delivery-gate.md`) already routes KB issues to
`/aid-discover` via Q&A. When a delivery edited code under a forward-authored design, the gate
MAY emit a one-line signpost ("forward-authored design present -- run /aid-housekeep to check
code->design conformance"). The gate does **not** run the mechanism itself (it is per-delivery
and code-quality-scoped; conformance is global and needs the accumulated as-built code) -- it
only points at the housekeep home. This keeps a single owner for the mechanism.

### Reconciliation flow -- human-gated, design stays authoritative

When divergences are found, the lane reuses KB-DELTA's existing present-scope gate (Step 3) and
Required-Q&A pattern (Step 4), with the action inverted from overwrite to choose-and-flag:

1. **Present the divergence set** (PAUSE-FOR-USER-DECISION), grouped by class, e.g.:
   ```
   Code<->design conformance: as-built code diverges from the forward-authored design.
     [contradiction] architecture.md  -- code violates declared invariant "<inv>" (as-built: <X>)
     [code-ahead]    domain-glossary.md -- term "<T>" is load-bearing in code, not in the spine
     [placeholder-resolved] technology-stack.md -- version was TBD; code pins it to <X>
   The design stays authoritative until you reconcile. For each, choose:
     [1] Evolve the design  -- update the forward-authored doc to match the code (deliberate)
     [2] Fix the code       -- raise a code task; the design is held; doc untouched
     [3] Accept / defer      -- record as a known divergence; revisit later
   ```
2. **Write a Required Q&A entry** to `.aid/knowledge/STATE.md ## Q&A (Pending)` (Style A, the
   exact format KB-DELTA Step 4 uses) recording the divergence set + the user's per-item choice.
   The entry carries the reconciliation, never an auto-applied edit.
3. **Apply the human choice (human-gated):**
   - **Evolve the design** -> the human approves; the forward-authored doc is updated via
     `/aid-discover` targeted re-entry (the same `Impact: Required` -> targeted-re-entry path
     KB-DELTA already drives) naming that doc. This is now a deliberate, approved design change --
     the only path by which a forward-authored doc is ever edited from as-built, and only with
     explicit human approval. (Whether the doc then sheds `forward-authored` for `hand-authored`
     is a separate human call, out of this check's scope.)
   - **Fix the code** -> a code task is raised (surfaced to the user / pipeline); the design doc
     is untouched; authority stays design->code.
   - **Accept / defer** -> the divergence is recorded as known; the doc is untouched.
4. **Until step 3 is chosen, the design is unchanged** -- the conformance check has only flagged,
   never reconciled. This is the NFR-5 / AC-6 guarantee made operational.

### Marker dependency (feature-003)

The check is scoped **entirely** by `source: forward-authored` (the feature-003 marker, C-1's one
permitted schema addition). It reads the value with the existing `fm_scalar` accessor; it adds no
new schema, enum, or frontmatter field. Consequences:
- **Brownfield is untouched (NFR-2).** `hand-authored` / `generated` docs never enter the
  conformance lane; their KB-DELTA behavior (source->doc freshness + Tier-2 update-the-doc) is
  byte-unchanged. Code-is-truth docs *should* be overwritten from code -- that is correct and
  stays.
- **The marker is the design-authority signal.** A doc is design-authoritative iff
  `source: forward-authored`. The check needs no other configuration to know which docs lead.
- **Dependency, not duplication.** feature-005 consumes the marker feature-003 ships; it does not
  re-define it. If feature-003 has not landed the marker, this lane has nothing to scope and
  no-ops (graceful degradation, no error).

### Layers & Components -- files touched / reused (real on-disk paths)

| Layer | File (real on-disk path) | Change |
|-------|--------------------------|--------|
| Hook (primary) | `canonical/skills/aid-housekeep/references/state-kb-delta.md` | Add the forward-authored **carve** (Step 1/2: route `source: forward-authored` out of the Tier-2 update-the-doc set) + the new **conformance sub-step** (extract-and-diff + flag-not-overwrite reconciliation). Reuses the existing Step 3 confirm-gate and Step 4 Required-Q&A-into-`/aid-discover` mechanics. |
| Hook (optional signpost) | `canonical/skills/aid-execute/references/state-delivery-gate.md` | One-line signpost when a delivery touched code under a forward-authored design; no mechanism here. |
| Marker accessor (reuse) | `canonical/aid/scripts/kb/kb-freshness-check.sh` | None -- reuse its `fm_scalar`/`source` read pattern (lines 143-156, 393-396). The freshness short-circuit for `forward-authored -> current` is **feature-003's** edit, consumed here. |
| Extraction (parameterize + reuse) | `canonical/skills/aid-discover/references/agent-prompts.md`, `references/state-generate.md` | **Small additive edit:** add an `output_root` dispatch parameter governing ONLY the KB-doc destination (default `.aid/knowledge/`; agent-prompts.md 165/218/260/309/355/420) -- the `.aid/generated/` side-output of Analyst (218)/Integrator (309) is left untouched, so every existing caller is unaffected by the default. feature-005 dispatches with `output_root=.aid/.temp/conformance/as-built/` + a keep-only-in-scope (C0/C1/C3/C4/D) filter on the shadow output. NOT a zero-edit reuse; but no NEW extractor agent. |
| Term universe (reuse) | `canonical/aid/scripts/kb/harvest-coined-terms.sh`, `canonical/aid/scripts/kb/closure-check.sh` | None -- reuse for the C4 ranked as-built term universe + grounding diff (same scripts KB-DELTA Step 6 already calls). |
| Marker (depend) | `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | None here -- the `forward-authored` enum row is feature-003's edit; feature-005 only reads it. |
| Concern model (reference) | `canonical/aid/templates/kb-authoring/concern-model.md` | None -- supplies the C0/C1/C3/C4/D classification used to concern-match. |

> Script paths are the **canonical source** form (`canonical/aid/scripts/kb/...`); the skill prose
> references the rendered profile form (`canonical/scripts/kb/...` / `.claude/aid/scripts/kb/...`)
> per the render rules in C-3. No new script is shipped by this feature; the genuinely new
> artifacts are (1) the agent-driven diff/classifier prose inside the KB-DELTA conformance sub-step
> and (2) the small additive `output_root` dispatch parameter on the extraction subagents (default
> preserves all existing callers).

### Definition of Done / Verification

| DoD | Operationalization | Source AC |
|-----|--------------------|-----------|
| **V1 -- Divergence flagged, not auto-overwritten** | On a fixture greenfield seed + as-built code that **contradicts** a declared invariant, /aid-housekeep flags the divergence (Required Q&A + present-the-choice) and the `.aid/knowledge/*.md` forward-authored doc is **byte-unchanged** after the run (no auto edit). | AC-6, FR-4 |
| **V2 -- Human-gated, design->code until reconciled** | The flag pauses for the user's per-item choice; with no choice made, the design doc stays authoritative and unchanged; only an explicit "evolve the design" choice edits it (via `/aid-discover` targeted re-entry). | AC-6, NFR-5, C-4 |
| **V3 -- Marker scoping** | A `hand-authored` doc with the same filename never enters the conformance lane (it stays in KB-DELTA's source->doc / update-the-doc lane); only `source: forward-authored` docs are checked. Verified by a mixed-source fixture. | C-1, NFR-2 |
| **V4 -- The NFR-5 carve holds** | Running /aid-housekeep on a greenfield seed does **not** overwrite the seed via KB-DELTA's Tier-2 update-the-doc path -- the carve routes it to flag-not-overwrite. Regression-verified against the pre-carve behavior. | NFR-5, AC-6 |
| **V5 -- Mechanism degrades + altitude filter** | With no code yet, the lane no-ops. With code, a `code-ahead` top-ranked term and a `placeholder-resolved` TBD version are flagged, while a sub-altitude implementation-only identifier is **not** flagged (false-positive control). Fixture-tuned. | FR-4 |
| **V6 -- Brownfield intact** | f007, KB-DELTA brownfield (`hand-authored` source->doc), and the aid-discover extraction path pass their existing tests; the carve + lane are purely additive. | NFR-2, AC-10 |
