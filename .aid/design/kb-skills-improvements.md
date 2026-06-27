# Design Notes — KB-Facing Skills Improvements (pre-interview)

> **Status:** DISCUSSION / pre-interview design capture. **Not yet a tracked work** —
> no STATE.md, no work folder. This file records a design conversation so nothing is
> lost when we open the `/aid-interview` for it.
> **Captured:** 2026-06-22.
> **Originating framing:** "a few improvements to `aid-discover` and `aid-summarize`."
> Scope has since grown to the whole KB-facing skill set (discover, summarize, ask,
> housekeep + a proposed update skill).

---

## Scope items (running list — pre-interview)

> This is a **pre-interview scoping session**: we are enumerating the items that will
> become the scope of a future `/aid-interview`. The list grows as we discuss; it is
> the canonical record of agreed scope so far.

**Item 1 — KB `INDEX.md` format.** Replace the prose-`intent:` list with a generated
routing table (Objective · Summary · Tags · See-instead · Path). *(detail below)*

**Item 2 — KB document definitions, generation & lifecycle** (`aid-discover` +
KB-facing skills). Sub-threads discussed:
- **Aspect 1** — the document *set* (which docs exist): concerns-driven (not
  project-type-driven), summary+pointer layer, audience/ownership, `sources:` field.
- **Aspect 2** — research & review *quality*: capture the **essence** (ubiquitous
  language / native concepts, not generic structure); multi-mandate review **panel**
  with **teach-back closure** as the exit; deterministic-substrate engineering; and a
  recon-selected **3-path** method (Greenfield / Brownfield-Small / Brownfield-Large).
- **Freshness lifecycle** — the 3 open holes (no trigger / no precision / no capture).
- **Skill topology** — rename `aid-ask` → `aid-query-kb`; add `aid-update-kb` for
  targeted/punctual updates (housekeep KB-DELTA is too broad for an end-of-work diff).

*(More items expected — the user has further `aid-discover` / `aid-summarize`
improvements to raise.)*

A strong cross-cutting signal: **three threads converge on one new frontmatter field,
`sources:`** (see "The convergence" below).

---

## Improvement #1 — `INDEX.md` as a routing table

Replace today's prose-`intent:` list with a generated **routing table**:

| Document | Objective | Summary | Tags | See instead |
|---|---|---|---|---|
| (link = Path) | purpose / kind, as a noun-phrase | one-sentence scope | concrete keywords (entities, commands, error terms) | negative routing → which other doc to use instead |

- **Objective** = the *kind/purpose* ("Module & directory inventory"); **Summary** =
  one-sentence *scope*. Differentiated by granularity so they don't overlap.
- **Tags** = the genuinely new, high-value add — fixes the "lost-in-summarization"
  miss (agent matches an exact term the prose summary didn't surface).
- **See instead** = negative routing ("pipeline → architecture.md; API → script
  header"). Highest-value signal; prevents the "siloed-logic trap" (agent grabs one
  doc, misses the conflicting rule in another). AID's current `intent:` prose already
  does this informally; promote it to a column so it's reliable.
- Keep cells **tight**; depth lives in the doc, not the index. The index is the map,
  not the territory.
- **Frontmatter to support it:** `objective:` (one line), `summary:` (one sentence),
  `tags:` (list), `see_also:` (optional). Generator (`build-kb-index.sh`) composes the
  table. Stays deterministic, git-diffable, dependency-free.
- **Cost:** schema (`kb-authoring/frontmatter-schema.md`) + generator + backfill ~13
  docs + INDEX-fresh/KB-hygiene CI expectations. No new runtime.
- Optional: an **Audience** column (see aspect 1) so a human filters to "docs for me,"
  not just agent routing.

**Decision against:** a libSQL/Turso vector-router over MCP. It adds an embedding
model + binary + MCP server + non-determinism (ANN can silently drop a relevant doc)
and collides with AID's bare-box / dependency-free / deterministic ethos. Revisit only
if the KB grows to hundreds of docs — and even then, embed the INDEX *rows* (keeping
the index as source of truth) and return *paths*, never chunk-RAG.

---

## Improvement #2, Aspect 1 — the document *set*

### Current behavior
The doc set lives in `.aid/settings.yml` as `discovery.doc_set`
(`filename | owner | presence`). When unset (common), `aid-discover` falls back to a
**fixed ~15-doc default seed** — **project-type-agnostic**. The only adaptivity is
`presence: conditional:<when>` (a *human hint at confirm time, never machine-evaluated*)
and hand-curating `discovery.doc_set`. A CLI, a React app, a data pipeline, and an
IaC repo all get the same seed.

### The trade-off (the core tension)
- **Fix the doc list** → over-fitting (procrustean bed): the agent conforms the
  project to the doc structure, or *bends facts* to fill predefined sections.
- **Fix nothing** → under-fitting: forgotten concerns; unrelated things bundled into
  one doc.
- **You cannot enumerate all project types** → this *kills the per-project-type doc
  catalog* (it's the fixed-list horn in disguise).

### Resolution — fix the *concerns*, derive the *documents*
The unit to standardize is **not the document** (a packaging decision) but the
**concerns** — the universal, small, stable set of *questions a newcomer must be able
to answer* (how is it built? what are the parts & how do they connect? what
conventions? what vocabulary? how is it tested? what's risky/owed? how does it ship?
what does it do for users?). Concerns are enumerable because they're about
software-in-general, not about any one domain; the *answers* differ wildly, the
*questions* don't.

- **Cover every concern** → guarantees nothing is forgotten.
- **Derive the documents** from what the project actually has: usually one concern →
  one doc, but **split** a large concern and **add** a project-specific doc for a
  concern the universal set didn't anticipate.
- **Propose → confirm** the resulting table of contents; the human is the backstop
  against both over-fitting and gaps. No project-type enumeration anywhere.

Supporting levers:
- **Expectations phrased as open questions, not fill-in templates** — *"Describe how
  this is structured and why"* (agent reports what's there) vs *"Fill in:
  Layers/Components/Diagram"* (invites bending). Strongest guard against "bend the
  info to fit the pattern."
- **Packaging rule:** one concern per doc; split when large; never merge unrelated
  concerns. (Kills the "bundle two things into one doc" failure.)
- **Coverage critic** at the end: an agent whose only job is *"what in this repo is
  NOT represented in any KB doc?"*

### Third force — humans, audience, ownership
Docs target **agents AND humans of multiple roles** (junior dev, non-tech PM, senior
architect, UX designer…) and must be **understood and updatable by both**. "All
concerns in one doc" proves it: an agent wouldn't mind, but a PM drowns, a UX designer
can't find their slice, and — worst — *no single human can own/maintain it*.

So a document boundary should fall where **three forces agree**:
1. **Coverage** (a coherent concern) — correctness / agent.
2. **Fit** (right-sized for *this* project) — adaptivity.
3. **Audience & ownership** (a natural owner-role + target audience who can read AND
   maintain it) — ergonomics + freshness.

This adds an **abstraction-level / audience** dimension: the doc set is closer to a
grid of **(concern) × (audience level)**; which cells exist depends on the project.
Note: AID's existing `tier-model.md` ranks by *agent load-bearingness* (primary/
secondary) — a **different axis** from human audience, which appears to be **missing
today** and may be part of the reported user gaps. *(To confirm against
`principles.md` + `tier-model.md`.)*

### The unifying principle — KB = summary + pointer layer
> **The KB is a *summary* of the full-size source, not a replacement for it. Chunks are
> small and digestible; when depth is needed, the chunk points to the authoritative
> source.**

This dissolves the agent-vs-human chunking "fork": **both** want small chunks. Depth is
handled by **summary + pointer**, not by layered depth-within-a-doc or duplicate
audience-docs:
- A PM reads the summary and stops.
- An architect reads the same summary and **follows the pointer** into code / spec /
  ADR for the detail.
- Audience decides *which chunks exist*; summary+pointer handles *depth*.

Hierarchy:
```
INDEX.md      ← router: which chunk for what (summary of summaries)
  └─ KB chunk ← digestible summary of ONE concern + pointers
       └─ Source ← authoritative full detail (code / spec / ADR / external doc)
```

⇒ **Every chunk carries an explicit `sources:` pointer list** (files/dirs/external
docs it summarizes). Feeds "go deeper" navigation, freshness, and grading (below).

### The summary/source boundary — the "sweet spot"
- **In the chunk:** durable, synthesized, cross-cutting understanding you can't cheaply
  re-derive (the *why*, the *how these parts interact*, the gotchas).
- **Left in source (point to it):** volatile detail, full signatures, exhaustive
  enumerations.
- **Too thin** → link farm (no understanding). **Too fat** → rotting duplicate.
- The researcher/reviewer must be **smart enough to calibrate** this — and the
  **grading methodology must validate it** (see next).

### Grading the sweet spot (bridges into Aspect 2)
Today's `kb-authoring/review-rubric.md` (Full Primary) grades:
- **Truth** — contracts vs disk, T1 concept correctness, T2 cardinality/schema,
  cross-doc consistency, citations resolve.
- **Rot-resistance** — no inline counts (T3), no inline dates (T4), no bare `file:LINE`
  cites (P1(d)).

It does **not** grade **altitude**. Three things slip through:
1. **Over-summarization (too fat)** passes — a faithful transcription is "true," cites
   resolve, scores clean.
2. **Under-summarization (too thin)** passes — a hollow link-farm makes no false claims.
3. **Coverage is checked against the doc's own `intent:`, not against the source** —
   catches "promised X, didn't deliver," never "the source has Y, you forgot it."

**Proposed addition — a `Calibration` rubric dimension** (catches the two failure modes
+ coverage, all observable):
- **Transcription finding (too fat):** restates a source with no synthesis → "should be
  a `sources:` pointer." Severity scales with volume.
- **Hollowness finding (too thin):** defers everything with no orienting synthesis.
- **Coverage-vs-source finding:** a load-bearing fact in the doc's `sources:` is absent
  — the completeness critic, **scoped by `sources:`** so it's tractable.
- **Deferral-must-point:** every "detail is elsewhere" must have a resolvable pointer.

Operationalize as a **round-trip test** the reviewer can run:
- **Forward (orientation):** fresh agent given *only the doc* must state the mental
  model + pick the right source → fails if too thin.
- **Reverse (coverage):** agent given the *source* surfaces a load-bearing omission →
  fails on coverage gaps.
- **Transcription scan:** flag copy-not-synthesis passages → fails if too fat.

Not foreign to the rubric: it already has judgment criteria (#2 intent-alignment, #4
concept correctness). "Computed not judged" governs the *severity→grade* mapping, not
whether a finding requires judgment.

---

## Improvement #2, Aspect 2 — research & review quality

> Aspect 2 is about *quality*: how well `aid-discover` **researches** a source to
> produce each doc's content, and how well it **reviews/grades** it. The *calibration
> grading* (Aspect 1 above) is one mandate within this; the rest follows.

### The reported problem
Discovery — *even with an A+ gate* — captures the **basic/structural** but misses the
**essence**: the project's anatomy, its inner engines, its internal jargon and native
concepts — its **ubiquitous language** (DDD sense). Domain vocabulary and key concepts
come out incomplete. **Concrete miss:** in a project named *caprica*, discovery failed
to capture the concept of **'Relative bus / Relative ME'** — load-bearing to
understanding the system, absent from the KB.

**Why the A+ gate doesn't catch it:** the gate grades *correctness* and
*template/intent-coverage* — and **both are satisfied by generic content**. "Layered
architecture, repository pattern, REST API" is true and fills the sections → A+. The
gate **actively selects for shallow-but-true**, because coverage is measured against
the *template*, never against *what is actually in this source*.

### The reframe — capture the *essence*, not generic structure
- It is **intrinsic** (the project's own conceptual model / ubiquitous language), **not
  comparative** "distinctiveness vs other projects." The target: *can we explain how
  THIS project understands itself, in its own words?*
- **KB value = the delta from what a competent generalist already knows.** An agent
  already knows what a layered architecture is from training; restating it is **negative
  value** (tokens on the known, crowding the budget). The only content worth storing is
  what a smart newcomer **cannot infer**: the custom abstraction, the native concept,
  the constraint-forced workaround, the gotcha, the *why-it's-like-this*. **A generic
  doc has failed even if every sentence is true.**
- **Root cause of the miss:** discovery does **structural cataloging** (a map of parts)
  instead of **conceptual-model reconstruction** (a model of ideas). 'Relative bus'
  isn't a module — it's an idea spread across files; a structural sweep glosses it as
  noise. Compounded by **doc-ownership partitioning**: the 4 parallel researchers each
  work a lane, so **no agent owns the whole-system concept model** and cross-cutting
  concepts fall between lanes.

### Pursuing the essence — the research side
- **Mechanical anchor — salient coined-term detection.** Scan *all* sources for terms
  that are project-coined (non-standard) × recurring × cross-source → the
  **candidate-concept list** ("things the KB must explain"). 'Relative bus' lights up
  here. Converts "did we miss a concept?" from unknowable → a checklist. Mechanical →
  cheap + deterministic.
- **Comprehension / closure loop — the heart.** Stop cataloging; **explain how the
  system works in the project's own language**, and loop: any native term reached-for
  but ungrounded = a required investigation; repeat until the explanation **closes** (no
  undefined project-specific term remains). Understanding is recursive — grounding one
  concept reveals the next. Stop when the system is explainable using only defined
  native concepts + general knowledge.
- **The "can't-explain-it" tripwire.** Forbid glossing: any project-specific term the
  researcher cannot confidently define from general knowledge is a **mandatory**
  investigation, never ignorable noise. (The root failure was treating 'Relative bus' as
  noise.)
- **Read the *why* sources, not just code.** Rationale and particularity live in docs,
  ADRs, reports, data bundles, commit/issue history — the sources the user listed. Code
  shows *what*; prose shows *why-here*, and *why-here* is the essence.

### Validating it — a multi-mandate review *panel* (not one blended reviewer)
Today: **one** `aid-reviewer`, blended mandate. Replace with a **panel**, each with a
distinct mandate (runs in parallel — low wall-clock):

| Reviewer | Mandate | Fails when… |
|---|---|---|
| Correctness | claims true vs source | a claim contradicts the source |
| Anatomy / coverage | what in the source is *unrepresented* | a load-bearing part is missing |
| Concept-closure | every native term defined; salient-term coverage | a coined term ('Relative bus') is absent/undefined |
| Teach-back | *using only the KB*, explain the engine + answer "what is X?" | it can't explain a core concept |
| Calibration | summary vs transcription (the sweet spot — see Aspect 1) | generic / transcribed / hollow |

- **Teach-back closure is the keystone exit criterion** — not "severity distribution ≥
  A+." Done = a fresh reviewer, given *only the KB*, can explain how the project works in
  its own language and answer "what is a Relative bus?", AND every mandate passes.
- **Evidence-anchored grading:** reviewers grade against mechanically-generated evidence
  lists (salient terms, source files), not pure recall → repeatable.

### The honest limit + human escape hatch
A purely **implicit** concept — held in heads, never named in any artifact — **cannot**
be recovered from sources. So the goal isn't 100%: (a) exhaustively capture every
**fingerprinted** concept (anchor + closure loop — 'Relative bus' is fingerprinted, so
catchable), and (b) when the researcher senses an **ungroundable** model gap, **raise it
to the human** (Q&A / `aid-query-kb` gap capture) rather than silently ship shallow.
Converts silent misses into caught concepts or explicit human questions.

### The discovery method (the analyst's plan)
Governing principle (facing a project — *not even knowing the subject*): you cannot bring
domain knowledge, so reconstruct it **bottom-up from evidence**; the deadly mistake is
starting from the concern-template and filling it. **Understand first, write second,
prove understanding third — concepts before template.** Orchestrated by
`aid-orchestrator`:

1. **RECON** (`aid-researcher-scout`) — inventory every source type (code, docs, reports,
   data, config, history), entry points, where knowledge lives. No writing.
2. **LANGUAGE & CONCEPT HARVEST** — `aid-clerk` (mechanical coined-term scan →
   candidate-concept list) + `aid-researcher` grounds the top candidates → the **concept
   spine** (shared backbone). *(The biggest departure from today.)*
3. **PARALLEL DEEP DIVES** (the 4 `aid-researcher` concern-slots) — each **armed with the
   concept list**, explains its area in native terms, grounds every concept it touches,
   writes summary+pointer with `sources:`, feeds new terms back to the spine.
4. **SYNTHESIS + CLOSURE LOOP** (`aid-architect`) — stitch a "how it works" narrative in
   native terms; loop on ungrounded terms / unexplained flows until it **closes**.
5. **REVIEW PANEL** (parallel `aid-reviewer` dispatches, the mandates above);
   `aid-orchestrator` aggregates → FIX loop, or escalate ungroundable gaps to —
6. **HUMAN GATE** (`aid-interviewer`) — questions for the un-fingerprinted concepts.

### Current vs proposed — comparative verdict
The current process has real strengths (mature/CI-tested, bounded cost, parallel/fast,
already adaptive on the doc-set, clean-context review, FIX loop, Q&A capture). Its
weaknesses map 1:1 to the gaps: **structural (not conceptual) recon**, **doc-ownership
partitioning fragments cross-cutting concepts**, **glossary is just-another-doc not a
spine**, **single-pass (no closure)**, **one blended reviewer grading correctness +
template** (exactly what generic-shallow docs pass).

The proposed method **wins decisively on essence + review rigor** and **loses on cost,
wall-clock, determinism, complexity**. **Verdict: graft, don't replace.** Keep the
current bones; add the high-value pieces — **(must-have)** the concept-harvest front-half
+ concept spine, and the multi-mandate panel + teach-back exit; **(bounded)** the closure
loop, capped. Scale depth to project complexity.

### Engineering the weak axes — cost / wall-clock / determinism
**Unifying lever: maximize the deterministic substrate; shrink + anchor the LLM
judgment.** Most "expensive LLM" steps are actually mechanical.
- **Cost:** mechanical-first (coined-term scan, closure self-containment check, salient
  ranking are scripts, not agents); **triage depth by salience**; **incremental re-runs**
  via `sources:`; **bounded closure loop**.
- **Wall-clock:** **batch the closure loop into parallel rounds** (detect-all-gaps →
  fill-all-parallel → re-check — N sequential iterations become ~2-3 rounds);
  **speculative overlap** (start deep-dives on the provisional concept list); **parallel
  concept-grounding**; **fully parallel review panel**.
- **Determinism:** two-layer — **deterministic harness** (control flow, gates,
  closure-termination, dispatch) + **stateless LLM workers** fed mechanical inputs,
  returning **schema-validated** output; **evidence-anchored grading**; **teach-back as a
  fixed question set** derived from the harvest (repeatable in *what* it tests). **Honest
  floor:** synthesis / "did it understand" are irreducibly judgment — shrink & anchor the
  surface, don't pretend to eliminate it.

### The three paths (recon-selected; shared invariants)
A **recon-driven triage** at the front selects one of three paths (mirrors
`aid-interview`'s lite/full triage). One method, three configurations.

**Invariants across all paths:** ubiquitous-language/concept spine is first-class;
summary+pointer + `sources:`; the review *mandates* (panel size scales, mandates don't);
**teach-back closure is THE exit criterion**; human escape hatch; deterministic
substrate; *KB value = delta from generalist knowledge*.

| Dimension | Greenfield | Brownfield-Small | Brownfield-Large |
|---|---|---|---|
| Recon trigger | little/no source | source < complexity threshold | source ≥ threshold |
| Source of truth | human intent + requirements/design | code + docs | code + docs + history/reports/data |
| Concept acquisition | **elicit** (co-author; ties to interview/specify) | **extract**, single pass | **extract**: mechanical harvest → spine |
| Generation shape | forward-authored, thin | one understand-pass, no fan-out | parallel fan-out by concern, concept-aware |
| Closure | "intent coherent + specified + vocab set" | short | batched-parallel loop, capped |
| Review | intent-graded mini-panel | collapsed: 1 reviewer, multi-mandate checklist | full parallel mandate panel |
| Starting KB | thin (intent+vocab+design) | full anatomy (small) | full anatomy (large) |
| Exit | teach-back **vs intent** | teach-back closure | teach-back closure |
| Cost / wall-clock | low tokens, human-paced | low | high (justified) |
| Primary risk | drift intent ↔ as-built | missing a fingerprinted concept | closure over/under-run; cost |

- **Greenfield** inverts the premise: nothing to extract → author **forward** from
  intent; spine is **elicited**, not scanned; the human's confirmed vocabulary is ground
  truth (high determinism); KB starts thin.
- **Brownfield-Small**: the full method collapsed — phases merge, no fan-out, single
  multi-mandate reviewer. Mechanical harvest still runs; **teach-back bar unchanged**.
- **Brownfield-Large**: the full engine; where the cost/wall-clock/determinism
  engineering earns its keep.

**Triage = lifecycle.** The path is **measured, not declared** (recon quantifies
source-availability/complexity → thresholds propose → human confirms; do **not** trust a
static `project.type`). **Re-triaged every run**, so the paths are *stages a project
passes through*: a greenfield's thin intent-KB becomes the spec the code is built
against; as code lands, `aid-update-kb` **verifies intent vs as-built + fills anatomy**;
crossing the threshold triggers a Brownfield-Large consolidation. The KB **persists and
is progressively verified/enriched** across Greenfield → Brownfield-Small →
Brownfield-Large.

---

## Freshness lifecycle + skill topology

### The KB-facing skills today
| Stage | Skill | Note |
|---|---|---|
| Create content | `aid-discover` | generates + reviews + approves; stamps `kb_baseline` on approval |
| Reconcile drift | `aid-housekeep` (KB-DELTA) | freshness workhorse, but detection is **agent judgment** (git-delta hint + full content re-review); **pull/manual** |
| Re-render view | `aid-summarize` | keeps `kb.html` current; re-stamps `kb_baseline` |
| Consume | `aid-ask` | **read-only**; states gaps then exits (gap discarded) |

### Three holes in the freshness *loop* (operations exist; the loop is open)
1. **No trigger** — detection is pull-only, driven by human memory. The change-makers
   (`aid-execute`, `aid-deploy`) never flag the KB stale. **Evidence: this repo's KB
   sat stale (13→7, 49→56) after work-005 until housekeep was run by hand.**
2. **No precision** — `kb_baseline` is one whole-KB tip-date; no per-doc/source
   linkage. So detection is an expensive whole-KB sweep, which discourages frequency.
3. **No signal capture** — `aid-ask` discards the best free drift signal there is
   ("the KB can't answer this" / "the KB contradicts the code").

### Loop-closers (likely no monolithic new skill needed)
- **`sources:` per doc** → cheap, deterministic, per-doc staleness (compare each doc's
  sources' last-changed commit vs the doc's approval commit). Fixes hole 2; dashboard
  flips from one coarse badge to per-doc "suspect" markers.
- **Push/flag detection** → source change flags the *specific* suspect docs
  automatically. Fixes hole 1.
- **Gap capture** → query side appends gaps to a KB-gap queue consumed downstream.
  Fixes hole 3.
- **Principle:** auto-**detect + flag**, keep **update human-gated** (fully automatic
  KB rewriting would violate AID's predictable/gated ethos).

### NEW (this session's addition) — split the KB read/write skills
`aid-housekeep`'s KB-DELTA is **too broad for the end-of-a-work KB diff** — it does a
full reconciliation sweep when, at a work's end, the precise deltas are already known
and want a *targeted* application. So:

- **Rename `aid-ask` → `aid-query-kb`** — the read/query side (unchanged behavior,
  clearer name; pairs with the write side).
- **Add `aid-update-kb`** — a **targeted/punctual** KB-update skill: a "second pass"
  that takes specific, scoped changes (e.g., the deltas a just-finished work
  introduced) and gets them **analyzed and applied properly** — i.e., through the same
  review/calibration gate as `aid-discover`, not a broad sweep.

Resulting topology (clean separation of concerns):
| Skill | Role | Breadth |
|---|---|---|
| `aid-discover` | bulk create / regenerate the KB | broad, generative |
| `aid-update-kb` | **targeted** KB update (NEW) | narrow, punctual |
| `aid-query-kb` | read / answer (renamed from `aid-ask`) | read-only |
| `aid-summarize` | render `kb.html` | presentation |
| `aid-housekeep` | periodic broad reconciliation + cleanup | broad, periodic |

`aid-update-kb` is naturally the **human-gated UPDATE half** of the freshness loop:
it consumes `aid-query-kb`'s gap signals and the per-doc "suspect" flags, and applies
fixes precisely (vs housekeep's whole-KB sweep).

---

## The convergence — one field, three threads

`sources:` (the list of sources a doc summarizes) is required by **all** of:
- **#1 INDEX** — the "go deeper" / source pointer.
- **Freshness** — per-doc, source-keyed staleness.
- **Calibration grading** — coverage-vs-source + transcription detection need to know
  *which* source a doc summarizes.

Strong signal it's the right primitive to introduce.

---

## Open questions (for the interview)

- **Audience fork** — resolved: small chunks + pointer (NOT layered-depth or duplicate
  audience docs). Audience decides *which* chunks; summary+pointer handles depth.
- **Summary/source line** — researcher/reviewer calibrate; grading validates. Still
  open: is the floor *orientation-only* or *orientation + synthesis-you-can't-rederive*?
  (sets chunk granularity + research depth.)
- **Project-type → concern selection** — one axis (web/CLI/library/service/data/…) or a
  small matrix (domain × architecture-style × deployment)? Decides lookup-table vs
  matrix.
- **Path thresholds** — what recon metrics + cutoffs define Greenfield vs
  Brownfield-Small vs Brownfield-Large (file/subsystem/concept counts)? Plus the exact
  hand-off mechanics of the Greenfield→Brownfield transition (`aid-update-kb` verifying
  intent vs as-built).
- **Closure-loop bound** — resolved in principle (capped: K-consecutive-clean or token
  budget); exact cap still to set.
- **Freshness: push vs pull** — better per-doc housekeep you choose to run, vs an
  auto-detect/flag layer (updates still gated)?
- **Skill boundaries** — where exactly is the line between `aid-update-kb`,
  `aid-discover`'s targeted re-discovery, and `aid-housekeep`'s KB-DELTA? (Avoid three
  overlapping "update the KB" paths.)
- **Grounding TODO** — confirm against `kb-authoring/principles.md` + `tier-model.md`
  how much of the concern/audience model already exists before designing.

---

## Still to discuss
- The remaining improvements to `aid-discover` / `aid-summarize` the user has in mind
  (Items 1 and 2 are captured; more items expected).
