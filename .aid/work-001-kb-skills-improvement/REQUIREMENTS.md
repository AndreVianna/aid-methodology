# Requirements

- **Name:** Knowledge Base Skills Overhaul
- **Description:** Overhaul AID's KB-facing skills so the Knowledge Base captures a project's essence (its ubiquitous language and native concepts), routes agents and humans reliably, and stays fresh across greenfield and brownfield projects, with teach-back closure as the acceptance bar.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Initial interview started | /aid-interview |
| 2026-06-22 | §1 Objective written — comprehensive analysis, strategy, 3 paths | /aid-interview |
| 2026-06-22 | §2 Problem Statement written — full detail, P1–P8 + net impact | /aid-interview |
| 2026-06-22 | §3 Users & Stakeholders written — full detail + need matrix | /aid-interview |
| 2026-06-22 | §4 Scope written — In/Out confirmed (S1–S9, O1–O6); one work | /aid-interview |
| 2026-06-22 | §5 Functional Requirements written — FR-1…FR-29 (groups A–H) | /aid-interview |
| 2026-06-22 | §5 revised — +FR-30…FR-35 (gap-closure G1–G6); FR-17 panel scales by path; FR-23/24/25 demoted to §6 | /aid-interview |
| 2026-06-22 | §6 NFRs written — NFR-1…NFR-8 (cost/wall-clock/determinism budgets + quality) | /aid-interview |
| 2026-06-22 | §7–§10 written — Constraints C1–C8, Assumptions/Deps, AC1–AC13, Priority (MoSCoW) | /aid-interview |
| 2026-06-22 | COMPLETION — added AC14/AC15; identity set; interview complete — approved | /aid-interview |
| 2026-06-22 | Cross-ref folds — Q1 `approved_at_commit:` (FR-4/5), Q2 C2 KB-scripts, FR-6 both readers, §1.5 scout slot | /aid-interview |
| 2026-06-23 | whole-work review 2026-06-23 — Dec.A: greenfield→brownfield transition now via re-triage (§1.5, FR-22, Could-item); verifier mechanism dropped. Dec.B: essence-capture spans lexical + non-lexical synthesis (FR-12); teach-back AC1 gains the non-lexical engine-narration limb | whole-work review |
| 2026-06-23 | §1.5 matrix Greenfield cells aligned to the (already-corrected) prose — Review→`collapsed` (mini-panel removed); Exit→`teach-back closure` (invariant per FR-21/AC1); Primary-risk→`over-eager elicitation / thin intent-KB` (dropped-verifier "intent↔as-built drift" framing removed) | alignment pass |
| 2026-06-23 | greenfield de-scope — greenfield is no longer a generation path: recon **detects** it (~0 source) and `aid-discover` **signposts to /aid-interview and halts**. The two generation paths are brownfield-small/large. §1.5 matrix/prose, FR-20/21/22, §4 (O7), §9 AC7, §10 updated; forward-authored greenfield KB-seed deferred to a future interview-side work | user decision |
| 2026-06-23 | **operational-sufficiency / act-back gate added (post-detail)** — closes the **agent-actionability gap**: the existing gates (teach-back, calibration, closure, correctness) verify *comprehension* + *correctness* but none verifies *actionability* (could an agent, given only the KB, correctly DO a representative change, and where is it forced to guess / reach for source). Adds **FR-36** (the act-back mandate — a 6th panel mandate, the operational sibling of teach-back, reusing f005's panel + `grade.sh`) + **AC16** (the matching acceptance bar). KB's primary purpose is operating guidance for an AI agent, not just human onboarding; act-back certifies it. **feature-013-operational-sufficiency** (Must) extends f005/f003 | user decision |
| 2026-06-25 | **`kb.html` summary redesign added (feature-015)** — feature-014 made the KB domain-driven + diagram-free, but `/aid-summarize` (which renders `kb.html`) was never updated and still selects a software project-TYPE profile, covers 0 of 7 custom docs, cites a phantom `repo-presentation.md`, hardcodes a stale `noscript` list, and caps the grade at C+ unless N Mermaid diagrams exist. **Foundational reframing:** `kb.html` is a **different product** for a **non-technical newcomer** — visually rich, the KB no-diagrams rule does NOT apply. Adds **§5.K / FR-45–FR-51** (doc-set/domain-driven input · concept-first content components · best-format-per-fact + completeness grading · newcomer tone · page-shell consistency with home.html/index.html · data-driven deterministic generation · pre-render inline-SVG visuals + drop the 3MB Mermaid engine + a NEW visual-fidelity gate) within the C1/C2/C3/C5/C6 + page-shell guardrails. **feature-015** (Must), **two deliveries** (D-011 correctness-core → D-012 visual & engineering). Server gzip/cache = fast-follow, OUT. Source: `.aid/design/aid-summarize-redesign.md` | user decision |
| 2026-06-25 | **dual-intent KB self-evaluation + spine-keyed depth added (feature-016)** — feature-014 generalized discovery's *architecture* (the spine + the domain→doc-set matrix) but left two depth/sufficiency mechanisms **filename-keyed and software-only**: the per-doc **depth contract** (`document-expectations.md`, keyed by `### <filename>`) covers only **22** of the **58** unique filenames the matrix can emit, a **36-doc dangling-anchor gap** (58 emittable − 22 covered; incl. the shared `glossary.md`/`tooling-stack.md` + all non-software domain docs) → the GENERATE custom-doc prompt points at a **dangling anchor** (those docs get only the generic spine question); and `kb-actback-task.sh`'s task selector + `_doc_expects_class` owning-table are filename-keyed → off-software the task degrades to "add an endpoint" and the operational-class presence check is **empty** (both VERIFIED). A modest **altitude-rule signature tax** also evicted load-bearing operational contracts (field types, exit codes) behind a bare `sources:` pointer. **Unifying fix:** lift everything domain-specific **filename-keyed → spine-dimension-keyed** (the matrix already carries the spine-dimension per doc) and **derive the self-evaluation probes from the project's own source + capabilities** — yielding a **Dual-Intent KB Self-Evaluation** that measures both user intents (an agent can do quality work from the KB alone = Blind Work-Simulation; a human can reconstruct the true essence from the KB alone = Blind Reconstruction + Source Confrontation) as domain-general REVIEW keystone gates with **no external test corpus**. Adds **§5.L / FR-52–FR-56** (spine-keyed depth contracts · spine-keyed safeguard + C9-derived task generation · the dual-intent self-eval's two limbs + ledger + convergence gates · the altitude signature exception · fixture validation + AID dogfood). **feature-016** (Must), **four deliveries** (D-013 depth → D-014 safeguard → D-015 self-eval → D-016 signature exception + dogfood); D-014→D-013, D-015→(D-013,D-014), D-016→D-015; the feature depends on feature-014 (already built). Source: `.aid/design/aid-discover-dual-intent-self-eval.md` | user decision |

## 1. Objective

> This objective is intentionally **comprehensive** — it carries the full analysis,
> reasoning, and strategy developed during the pre-interview design discussion so the
> requirements are self-contained for the downstream phases. The living design note is
> `.aid/design/kb-skills-improvements.md`.

### 1.1 Goal

Overhaul AID's **KB-facing skills** (`aid-discover`, `aid-summarize`, `aid-ask`,
`aid-housekeep`, plus a new `aid-update-kb`) so the Knowledge Base:

1. **Captures a project's *essence*** — its ubiquitous language and native concepts, not
   just generic structure;
2. **Routes both agents and humans** to the right knowledge quickly and reliably;
3. **Stays fresh** over the project's whole life; and
4. **Adapts** across greenfield and brownfield projects.

The invariant acceptance bar across everything below is **teach-back closure**: a fresh
reviewer, given *only the KB*, can explain how the project works in its own language and
answer "what is X?" for the project's core native concepts.

### 1.2 Background — why this work exists (the analysis)

**The reported gap.** Discovery — *even when it passes an A+ gate* — captures the
**basic/structural** but misses the **essence**: the project's anatomy, inner engines,
internal jargon, and native concepts (its **ubiquitous language**, in the DDD sense).
Domain vocabulary and key concepts come out incomplete. **Concrete miss:** in a project
named *caprica*, discovery failed to capture the concept of **'Relative bus / Relative
ME'** — load-bearing to understanding the system, yet absent from the KB.

**Why the A+ gate doesn't catch it.** The gate grades *correctness* and
*template/intent-coverage* — and **both are satisfied by generic content**. "Layered
architecture, repository pattern, REST API" is true and fills the sections → A+. The
gate therefore **actively selects for shallow-but-true**, because coverage is measured
against the *template*, never against *what is actually in this source*. A correct-but-
generic doc and a perfectly-calibrated one receive the same grade.

**The reframe.** The target is **intrinsic** (the project's own conceptual model), **not
comparative** "distinctiveness vs other projects." Decisive principle: **a KB doc's
value is the *delta* from what a competent generalist already knows.** An agent already
knows what a layered architecture is from training; restating it is **negative value**
(tokens on the known, crowding the budget). The only content worth storing is what a
smart newcomer **cannot infer**: the custom abstraction, the native concept, the
constraint-forced workaround, the gotcha, the *why-it's-like-this*. **A generic doc has
failed even if every sentence is true.**

**Root cause.** Discovery does **structural cataloging** (a map of parts) instead of
**conceptual-model reconstruction** (a model of ideas). A concept like 'Relative bus'
isn't a module — it's an idea spread across files; a structural sweep glosses it as
noise. This is compounded by **doc-ownership partitioning**: the 4 parallel researchers
each work a lane, so **no agent owns the whole-system concept model**, and cross-cutting
concepts fall between lanes.

### 1.3 The KB model we are committing to

- **KB = a summary + pointer layer.** The KB is a *summary* of the full-size source, not
  a replacement for it. Chunks are small and digestible; when depth is needed, the chunk
  **points to the authoritative source**. This dissolves the agent-vs-human chunking
  "fork" — *both* want small chunks; depth is handled by summary+pointer (a PM stops at
  the summary; an architect follows the pointer into code/spec/ADR), **not** by
  layered-depth-within-a-doc or duplicate audience docs.
- **Documents are derived from *concerns*, not from project *types*.** The unit we
  standardize is the small, universal, stable set of **concerns** (the questions a
  newcomer must answer: how is it built? what are the parts & how do they connect? what
  conventions? what vocabulary? how is it tested? what's risky/owed? how does it ship?
  what does it do for users?). The *documents* are derived per project (split a large
  concern; add a project-specific doc), **proposed → confirmed** by the human. We do
  **not** enumerate project types (impossible to enumerate; a per-type catalog is the
  rigid-template trap in disguise).
- **Audience & ownership is a first-class dimension.** Docs target agents AND humans of
  multiple roles (junior dev, non-tech PM, senior architect, UX designer…) and must be
  *understood and updatable by both*. A document boundary should fall where three forces
  agree: **coverage** (a coherent concern), **fit** (right-sized for this project), and
  **audience & ownership** (a natural owner-role + audience who can read and maintain
  it). AID's existing `tier-model.md` ranks by *agent load-bearingness* — a different
  axis from human audience, which appears missing today.
- **New frontmatter field `sources:`** — the list of sources each chunk summarizes. It
  is required by **three threads at once** (a strong signal it is the right primitive):
  the INDEX "go-deeper" pointer (Item 1), per-doc source-keyed freshness, and the
  calibration/coverage grading.
- **The summary/source boundary (the "sweet spot").** *In the chunk:* durable,
  synthesized, cross-cutting understanding you can't cheaply re-derive (the *why*, the
  *how parts interact*, the gotchas). *Left in source (point to it):* volatile detail,
  full signatures, exhaustive enumerations. **Too thin → link farm; too fat → rotting
  duplicate.** The researcher/reviewer must calibrate this, and **the grading must
  validate it**.

### 1.4 Discovery quality — capturing the essence (research + review)

**Research side — hunt the essence, don't fill the skeleton:**
- **Mechanical anchor — salient coined-term detection.** Scan *all* sources for terms
  that are project-coined (non-standard) × recurring × cross-source → the
  candidate-concept list ("things the KB must explain"). 'Relative bus' lights up here.
  Converts "did we miss a concept?" from unknowable into a checklist. Mechanical → cheap
  + deterministic.
- **Comprehension / closure loop (the heart).** Stop cataloging; **explain how the
  system works in the project's own language** and loop: any native term reached-for but
  ungrounded = a required investigation; repeat until the explanation **closes** (no
  undefined project-specific term remains). Understanding is recursive — grounding one
  concept reveals the next.
- **The "can't-explain-it" tripwire.** Any project-specific term the researcher cannot
  confidently define from general knowledge is a **mandatory** investigation, never
  ignorable noise. (The root failure was treating 'Relative bus' as noise.)
- **Read the *why* sources, not just code** — docs, ADRs, reports, data bundles,
  commit/issue history. Code shows *what*; prose shows *why-here*, and *why-here* is the
  essence.
- **Expectations as open questions, not fill-in templates** — "Describe how this is
  structured and why" (report what's there) vs "Fill in: Layers/Components/Diagram"
  (invites bending).

**Review side — a multi-mandate review *panel* (not one blended reviewer):**

| Reviewer | Mandate | Fails when… |
|---|---|---|
| Correctness | claims true vs source | a claim contradicts the source |
| Anatomy / coverage | what in the source is *unrepresented* | a load-bearing part is missing |
| Concept-closure | every native term defined; salient-term coverage | a coined term ('Relative bus') is absent/undefined |
| Teach-back | *using only the KB*, explain the engine + answer "what is X?" | it can't explain a core concept |
| Calibration | summary vs transcription (the sweet spot) | generic / transcribed / hollow |

- **Teach-back closure is THE keystone exit criterion** — not "severity distribution ≥
  A+."
- **Calibration dimension** (added to the rubric): *transcription* (too fat),
  *hollowness* (too thin), *coverage-vs-source* (a load-bearing fact in the doc's
  `sources:` is absent), *deferral-must-point*. Operationalized via a **round-trip
  test** (forward orientation / reverse coverage / transcription scan).
- **Evidence-anchored grading** — reviewers grade against mechanically-generated
  evidence lists (salient terms, source files), not pure recall → repeatable.

**The honest limit + human escape hatch.** A purely *implicit* concept — held in heads,
never named in any artifact — cannot be recovered from sources. So the goal is not 100%:
(a) exhaustively capture every **fingerprinted** concept (anchor + closure loop), and
(b) when the researcher senses an **ungroundable** model gap, **raise it to the human**
(Q&A / `aid-query-kb` gap capture) rather than silently ship shallow. This converts
silent misses into caught concepts or explicit human questions.

### 1.5 The discovery method and the recon triage (two brownfield paths; greenfield detect+signpost)

**Governing principle** (facing a project — *not even knowing the subject*): you cannot
bring domain knowledge, so reconstruct it **bottom-up from evidence**; the deadly mistake
is starting from the concern-template and filling it. **Understand first, write second,
prove understanding third — concepts before template.**

**The method (orchestrated by `aid-orchestrator`):**
1. **RECON** (`aid-researcher` scout slot) — inventory every source type (code, docs, reports,
   data, config, history), entry points, where knowledge lives. No writing.
2. **LANGUAGE & CONCEPT HARVEST** — `aid-clerk` (mechanical coined-term scan →
   candidate-concept list) + `aid-researcher` grounds the top candidates → the **concept
   spine** (the shared backbone). *Biggest departure from today.*
3. **PARALLEL DEEP DIVES** (the 4 `aid-researcher` concern-slots) — each armed with the
   concept list, explains its area in native terms, grounds every concept it touches,
   writes summary+pointer with `sources:`, feeds new terms back to the spine.
4. **SYNTHESIS + CLOSURE LOOP** (`aid-architect`) — stitch a "how it works" narrative in
   native terms; loop on ungrounded terms / unexplained flows until it closes.
5. **REVIEW PANEL** (parallel `aid-reviewer` dispatches, the mandates above);
   `aid-orchestrator` aggregates → FIX loop, or escalate ungroundable gaps to —
6. **HUMAN GATE** (`aid-interviewer`) — questions for the un-fingerprinted concepts.

**Recon selects among three outcomes** (a triage at the front, mirroring `aid-interview`'s
lite/full triage): **greenfield → detect + signpost** (not a generation path), and the two
*generation* paths **brownfield-small** and **brownfield-large**. **Shared invariants across
the two generation paths:** concept spine first-class; summary+pointer + `sources:`; the
review *mandates* (panel size scales, mandates don't); **teach-back closure as the exit**;
human escape hatch; deterministic substrate; *KB value = delta from generalist knowledge*.

| Dimension | Greenfield (detect + signpost) | Brownfield-Small | Brownfield-Large |
|---|---|---|---|
| Recon trigger | little/no source (~0 extractable) | source < complexity threshold | source ≥ threshold |
| Outcome | **signpost + halt** — not a generation path | generation path | generation path |
| Source of truth | n/a (nothing to extract yet) | code + docs | code + docs + history/reports/data |
| Concept acquisition | none yet — **extract** begins once code lands (re-triage) | **extract**, single pass | **extract**: mechanical harvest → spine |
| Generation shape | none — `aid-discover` emits a signpost and halts | one understand-pass, no fan-out | parallel fan-out by concern, concept-aware |
| Closure | n/a | short | batched-parallel loop, capped |
| Review | n/a | collapsed: 1 reviewer, multi-mandate checklist | full parallel mandate panel |
| Starting KB | none (nothing discovered yet) | full anatomy (small) | full anatomy (large) |
| Exit | signpost shown (no closure to reach) | teach-back closure | teach-back closure |
| Cost / wall-clock | ~0 (detect + print) | low | high (justified) |
| Primary risk | mis-detecting a buildable project as empty | missing a fingerprinted concept | closure over/under-run; cost |

**The greenfield signpost.** When recon detects a from-scratch project (essentially no
source to extract), `aid-discover` does **not** run a generation engine. It emits a
**signpost and halts**: *"Nothing to discover yet — run /aid-interview to define the
project; the KB fills in as you build, via re-triage once code lands."* There is no
greenfield generation engine, no elicit-via-interview/specify discovery path, no greenfield
closure loop, and no greenfield review panel. (A future, **out-of-scope** interview-side
capability may *forward-author* a greenfield KB-seed — eliciting intended
architecture/conventions/ubiquitous-language for a from-scratch project — but that is not
this work; see §4 O7.)

**Triage = lifecycle.** The path is **measured, not declared** (recon quantifies
source-availability/complexity → thresholds propose → human confirms; do not trust a
static `project.type`). **Re-triaged every run**, so the project moves through *stages*: a
greenfield gets signposted to `/aid-interview`; as code lands, **re-triage re-routes to the
brownfield engine, which captures the now-extractable anatomy**; crossing the threshold
triggers a Brownfield-Large consolidation. The KB **comes into existence and is
progressively verified/enriched** as the project crosses from greenfield (signpost only) →
Brownfield-Small → Brownfield-Large.

### 1.6 Engineering principles — cost, wall-clock, determinism

**Unifying lever: maximize the deterministic substrate; shrink + anchor the LLM
judgment.** Most "expensive LLM" steps are actually mechanical.
- **Cost:** mechanical-first (coined-term scan, closure self-containment check, salient
  ranking are scripts, not agents); triage depth by salience; incremental re-runs via
  `sources:`; bounded closure loop.
- **Wall-clock:** batch the closure loop into parallel rounds (detect-all-gaps →
  fill-all-parallel → re-check — N sequential iterations become ~2-3 rounds); speculative
  overlap (start deep-dives on the provisional concept list); parallel concept-grounding;
  fully parallel review panel.
- **Determinism:** two-layer — a **deterministic harness** (control flow, gates,
  closure-termination, dispatch) + **stateless LLM workers** fed mechanical inputs,
  returning **schema-validated** output; evidence-anchored grading; teach-back as a
  *fixed question set* derived from the harvest. **Honest floor:** synthesis / "did it
  understand" are irreducibly judgment — shrink & anchor the surface, don't pretend to
  eliminate it.

### 1.7 INDEX routing table (Item 1)

Replace today's prose-`intent:` `INDEX.md` list with a generated **routing table**:
`Document(=link/Path) · Objective(purpose noun-phrase) · Summary(one-sentence scope) ·
Tags(concrete keywords) · See-instead(negative routing)`. Backed by new frontmatter
(`objective`, `summary`, `tags`, `see_also`), composed by `build-kb-index.sh`. Stays
deterministic, git-diffable, dependency-free. **Rejected:** a libSQL/Turso vector-router
over MCP (adds embedding model + binary + MCP server + ANN non-determinism; collides with
AID's bare-box/deterministic ethos) — revisit only at hundreds of docs, and even then
embed the INDEX *rows* and return *paths*, never chunk-RAG.

### 1.8 Skill topology and the freshness loop

- **Rename `aid-ask` → `aid-query-kb`** (read/query side; clearer name).
- **Add `aid-update-kb`** — targeted/punctual KB updates (the "second pass" for the
  precise deltas a finished work introduced), applied through the same review/calibration
  gate as `aid-discover`. `aid-housekeep`'s KB-DELTA is too broad for an end-of-work diff.
- **Topology:** `aid-discover` (bulk create/regen) · `aid-update-kb` (targeted) ·
  `aid-query-kb` (read) · `aid-summarize` (render) · `aid-housekeep` (periodic broad
  reconciliation + cleanup).
- **Freshness loop has three holes today:** (1) **no trigger** — detection is pull-only,
  human-memory-driven (evidence: this repo's KB sat stale after work-005 until housekeep
  was run by hand); (2) **no precision** — `kb_baseline` is one whole-KB tip-date, no
  per-doc/source linkage; (3) **no signal capture** — `aid-ask` discards the best free
  drift signal ("KB can't answer this" / "KB contradicts code"). **Closers:** `sources:`
  per doc → per-doc staleness; push/flag detection; query-side gap capture. **Principle:**
  auto-*detect + flag*, keep *update* human-gated.

### 1.9 Approach / verdict

**Graft, don't replace.** The current `aid-discover` has real strengths (mature/CI-tested,
bounded cost, parallel/fast, already adaptive on the doc-set, clean-context review, FIX
loop, Q&A capture). Keep those bones; add the high-value pieces — **(must-have)** the
concept-harvest front-half + concept spine, and the multi-mandate panel + teach-back
exit; **(bounded)** the closure loop, capped; and **scale depth to project complexity**
via the recon triage (two brownfield generation paths; greenfield is detect + signpost).

### 1.10 Success criteria (summary)

- Discovery reliably captures native concepts and **passes teach-back closure** (a
  'Relative bus'-type concept is not silently missed).
- The `INDEX.md` routes reliably (Objective · Summary · Tags · See-instead).
- The KB **freshness loop closes** (per-doc, source-keyed staleness + targeted
  `aid-update-kb` updates; gap capture from `aid-query-kb`).
- One method with a recon triage: **greenfield is detected and signposted to
  `/aid-interview`** (not a generation path), and the two generation paths
  (**brownfield-small**, **brownfield-large**) work correctly — with teach-back as the
  invariant bar for the generation paths.
- The whole design stays within AID's **deterministic, dependency-free, human-gated**
  ethos.

## 2. Problem Statement

> Comprehensive, per §1's treatment. These are the **current** deficiencies in AID's
> KB-facing skills that this work addresses. Solution *strategy* lives in §1; this section
> states the problems, their evidence, and their impact. Each problem is tagged `P#` for
> traceability into Functional Requirements (§5) and Acceptance Criteria (§9).

### 2.1 (P1) Discovery captures structure, not essence

**Problem.** `/aid-discover` reliably produces the *generic skeleton* of a project
(architecture style, module list, tech stack) but misses the **essence** — the project's
own inner engines, internal jargon, and native concepts (its **ubiquitous language**).
The domain glossary and key concepts come out incomplete.

**Evidence.** In project *caprica*, discovery never captured **'Relative bus / Relative
ME'** — a concept you cannot understand the system without — even though the run passed
its quality gate. This is reported across multiple projects, not a one-off.

**Impact.** The KB describes what a competent generalist *already knows* and omits the
only content with real value — what the project does *that a newcomer cannot infer*. An
agent or human cannot actually understand the project from the KB, which defeats the KB's
entire purpose (onboarding).

### 2.2 (P2) The quality gate selects for shallow-but-true

**Problem.** The review rubric grades **correctness** (claims true vs disk) and
**template/intent-coverage** — and *both are satisfied by generic content*. There is no
axis for essence, distinctiveness, or summarize-vs-transcribe calibration.

**Evidence.** "Layered architecture, repository pattern, REST API" is true, cites
resolve, and fills every section → **A+** — while saying nothing project-specific.
caprica's KB passed the gate with the core concept missing.

**Impact.** An A+ is **not** a signal that the KB is useful; it certifies "true +
template-complete," which a shallow doc trivially meets. Teams trust a green gate that
guarantees nothing about whether the KB captured the project. The gate actively rewards
the path of least resistance (generic + correct).

### 2.3 (P3) Cross-cutting concepts fall between lanes

**Problem.** Discovery is **structural cataloging** (a map of parts), not
**conceptual-model reconstruction** (a model of ideas). The four researchers are
partitioned by **doc ownership** (architecture / analyst / integrator / quality), so **no
agent owns the whole-system concept model**, and there is no shared *concept spine*.

**Evidence.** A concept like 'Relative bus' isn't a module — it's an idea spread across
many files; a per-lane structural sweep glosses it as noise, and no lane is responsible
for it.

**Impact.** Exactly the most important, cross-cutting concepts — the ones that define how
the system actually works — are nobody's job and are silently dropped. The glossary,
being just-another-doc owned by one lane, is not a backbone the other docs ground against.

### 2.4 (P4) The summary/source calibration is ungraded

**Problem.** The KB should be a *summary + pointer* layer, but nothing grades whether a
doc sits at the right altitude. **Over-summarization** (faithful transcription of the
source) and **under-summarization** (a hollow "see file X" link-farm) both pass today.
Coverage is checked only against the doc's own declared `intent:`, never against the
source.

**Evidence.** A transcribed doc is "true" and its cites resolve → clean score; a hollow
doc makes no false claims → nothing to flag. Neither failure mode is detectable under the
current rubric.

**Impact.** Docs drift toward either **rot** (fat duplicates that go stale every commit)
or **hollowness** (no understanding conveyed), with no gate pressure pulling them to the
useful middle. "The source has Y and the doc forgot it" is never caught.

### 2.5 (P5) The KB freshness loop is open

**Problem.** The skills perform every freshness *operation* (create, reconcile, render,
consume) but nothing closes the freshness *loop*. Three holes:
1. **No trigger** — drift detection is **pull-only**, driven by human memory; the
   change-makers (`aid-execute`, `aid-deploy`) never flag the KB stale.
2. **No precision** — `kb_baseline` is a single whole-KB tip-date with no per-doc/source
   linkage, so detection is an expensive whole-KB judgment sweep (which discourages
   running it).
3. **No signal capture** — `aid-ask` discards the single best free drift signal there is
   ("the KB can't answer this" / "the KB contradicts the code").

**Evidence.** **This very repository's KB sat stale** (generator count 13→7, suites
49→56) after work-005 shipped, and stayed stale until `/aid-housekeep` was run by hand.

**Impact.** Staleness accumulates silently; the KB quietly diverges from the code;
trust in it erodes; and the most informative drift signals are thrown away.

### 2.6 (P6) INDEX routing is unreliable

**Problem.** `INDEX.md` is a prose-`intent:` list. It has no structured tags, and its
negative routing ("use this doc, not that one") is at best informal prose.

**Evidence.** "Lost-in-summarization": when a task uses a specific term the prose summary
didn't surface, the agent mis-picks or misses the doc. With no explicit "see-instead," an
agent grabs one doc and misses a conflicting rule in another (the **siloed-logic trap**).

**Impact.** Agents mis-route — read the wrong or extra docs, burn context budget, or miss
load-bearing constraints — degrading every task that depends on finding the right
knowledge fast.

### 2.7 (P7) Discovery does not adapt to project shape

**Problem.** The default doc-set is a **fixed ~15-doc seed** applied largely regardless of
project shape, and discovery assumes there is **existing source to extract from**. There
is no **greenfield** (forward-authoring) mode and no right-sizing for small repos.

**Evidence.** A CLI tool, a React app, a data pipeline, and an IaC repo all get the same
seed (wrong/missing docs for the project). A greenfield project has nothing to extract, so
the extract-oriented flow has no purchase at all. A tiny repo pays for machinery sized for
a large one.

**Impact.** Wrong or missing documents for the project at hand; greenfield projects
effectively cannot be discovered; and effort is mis-scaled (over-engineering small repos,
under-serving large ones).

### 2.8 (P8) Skill-topology gaps in the KB lifecycle

**Problem.** There is no skill for **targeted, punctual KB updates**. `/aid-housekeep`'s
KB-DELTA is a broad reconciliation sweep — too coarse for applying the *precise* deltas a
just-finished work introduced. `aid-ask` is read-only and its gap signals are discarded.

**Evidence.** Concluding work-005 required either a heavy full housekeep sweep or
hand-editing — there is no clean "apply these specific, known changes to the KB through the
review gate" path.

**Impact.** The end-of-work KB update is awkward and over-broad; the cheapest, most
accurate freshness inputs (a finished work's own diff; a user's failed query) have nowhere
to go.

### 2.9 Net impact

Collectively, the KB **underdelivers on its core promise** — onboarding an agent or human
to a specific project — because it captures the *generic* and misses the *particular*
(P1–P4), certifies that gap with a gate that measures the wrong thing (P2, P4), then lets
the result **silently rot** (P5) while being **hard to navigate** (P6), **mis-shaped for
the project** (P7), and **awkward to keep current** (P8). Because every downstream AID
phase loads the KB, these deficiencies propagate into specification, planning, and
execution quality.

## 3. Users & Stakeholders

> Comprehensive. The KB is consumed by **both machines and humans of several roles**, and
> that dual, multi-role audience is itself a load-bearing design driver for this work
> (see §1.3 audience/ownership). Stakeholders are grouped by how they touch the KB.

### 3.1 Primary consumer — AI agents

The KB's first consumer is the **AI coding agent** (Claude Code, Codex, Cursor, Copilot
CLI, Antigravity) that loads `INDEX.md` + the relevant docs before doing a task.
- **Needs:** precise, low-cost routing to the right doc; and the project's **essence**
  (the *delta* from what the agent already knows — §1.2). Generic content is noise/negative
  value to this consumer.
- **Pain today:** mis-routing (P6) and shallow/generic docs (P1) — the agent gets the
  skeleton it already knew and misses the native concepts it needed.

### 3.2 Human consumers — multiple roles, multiple altitudes

Humans read the KB to onboard and to make decisions. They are **not one audience**:
- **Junior developer** — needs orientation + where to go deeper.
- **Senior architect** — needs the conceptual model + the *why*, then follows pointers to
  source.
- **Non-technical PM** — needs the capabilities/vocabulary level, must not drown in
  internals.
- **UX designer** — needs the user-flow / interaction slice.
- **Common need:** small, digestible chunks they can both **understand at their level**
  and **keep updatable** (the summary+pointer model serves all of them; audience decides
  *which* chunks exist).
- **Pain today:** no audience dimension; docs aren't shaped or filtered by role.

### 3.3 Doc owners / maintainers (freshness accountability)

Each KB doc should have a **natural owner-role** responsible for keeping it current
(§1.3). Owners are the humans who can detect and fix drift in their area.
- **Needs:** per-doc, source-keyed staleness signals (know *which* doc their change made
  suspect); a targeted, low-friction way to apply updates (`aid-update-kb`).
- **Pain today:** whole-KB coarse staleness + no targeted update path (P5, P8) → ownership
  has no actionable signal, so docs rot.

### 3.4 AID adopters / teams (the customers)

Teams adopting AID who run these skills on their own projects — including **greenfield**
teams (authoring forward) and **brownfield** teams (extracting from existing code).
- **Needs:** discovery that fits *their* project shape and actually captures *their*
  domain; a KB they can trust over time.
- **Critical sub-segment — AI-skeptical adopters:** AID is positioned for adopters who
  distrust AI "slop." For them, **deterministic, visible, predictable** behavior *is the
  product*. Any non-determinism or hidden magic (e.g., an opaque vector router) erodes the
  sale. This constrains the solution (§1.6, §1.7).
- **Pain today:** one-size discovery (P7); a quality gate that certifies nothing about
  usefulness (P2).

### 3.5 AID maintainers (this project's developers)

The people who build and maintain the KB-facing skills (us).
- **Needs:** the design must fit AID's conventions — canonical→render pipeline,
  deterministic substrate + CI-ability, the human-gated state-machine ethos, the
  bare-box/dependency-free stance — so it's maintainable and testable.
- **Pain today:** the freshness loop and review rigor are spread across skills with gaps
  (P3, P5, P8); changes are hard to reason about.

### 3.6 Downstream AID phases (indirect stakeholders)

`/aid-specify`, `/aid-plan`, `/aid-detail`, `/aid-execute` all **load the KB** as input.
They are indirect consumers whose output quality is bounded by KB quality.
- **Need:** a KB that is accurate, essence-bearing, and fresh.
- **Pain today:** KB deficiencies (P1–P8) propagate into every downstream artifact (§2.9).

### 3.7 Stakeholder → need → what this work delivers

| Stakeholder | Primary need | Delivered by |
|---|---|---|
| AI agents | precise routing + essence | INDEX routing table (Item 1); essence capture (§1.4) |
| Human roles (jr/architect/PM/UX) | right-altitude, digestible, updatable slice | summary+pointer + audience/ownership (§1.3) |
| Doc owners | actionable per-doc staleness + targeted update | `sources:` freshness + `aid-update-kb` (§1.8) |
| AID adopters (incl. skeptics) | project-fit discovery; trustworthy, deterministic KB | recon triage (greenfield detect/signpost + 2 brownfield paths) + teach-back gate + deterministic substrate (§1.5–§1.6) |
| AID maintainers | conventions-fit, testable design | deterministic harness + canonical/render fit (§1.6) |
| Downstream phases | accurate, fresh, essence-bearing KB | the whole work |

## 4. Scope

> Confirmed boundary (user, 2026-06-22). The full In-Scope set is **one work**; `/aid-plan`
> will sequence it into deliveries. **Nothing is deferred** to a follow-up work. Scope items
> are tagged `S#` for traceability.

### In Scope

- **S1 — INDEX routing table (Item 1).** Replace the prose-`intent:` `INDEX.md` with a
  generated routing table (Objective · Summary · Tags · See-instead · Path); add frontmatter
  `objective`/`summary`/`tags`/`see_also`; update `build-kb-index.sh`; update the
  INDEX-fresh / KB-hygiene CI expectations. *(addresses P6)*
- **S2 — `sources:` field + per-doc freshness.** New `sources:` frontmatter (the sources a
  doc summarizes); per-doc, source-keyed staleness detection (each doc's sources'
  last-changed commit vs the doc's approval commit). *(P5)*
- **S3 — Aspect 1, KB document model.** Concerns-driven doc-set (propose→confirm; not
  project-type-enumerated); the summary+pointer principle; the audience/ownership dimension
  (+ `owner`/`audience` frontmatter); expectations phrased as open questions. *(P1, P3, P7)*
- **S4 — Aspect 2, discovery quality.** Essence capture (mechanical coined-term anchor,
  comprehension/closure loop, can't-explain tripwire, read the why-sources); the
  **multi-mandate review panel**; the **teach-back-closure exit**; the **Calibration**
  rubric dimension (transcription / hollowness / coverage-vs-source / deferral-must-point).
  *(P1, P2, P3, P4)*
- **S5 — Recon triage + two brownfield generation paths (+ greenfield detect/signpost).**
  One method with a recon triage: **greenfield is detected** (~0 extractable source) and
  drives a **signpost to /aid-interview + halt** (not a generation path); the two
  **generation** paths are **brownfield-small** and **brownfield-large**. Path **measured,
  not declared**; re-triaged each run (lifecycle: greenfield-signpost → brownfield). *(P7)*
- **S6 — Deterministic-substrate engineering.** Mechanical scans/checks (coined-term,
  closure self-containment, salience ranking); batched-parallel closure rounds; the
  two-layer harness (deterministic control flow + schema-validated LLM workers);
  evidence-anchored grading; teach-back as a fixed question set. *(cost / wall-clock /
  determinism)*
- **S7 — Skill topology.** Rename `aid-ask` → `aid-query-kb`; add `aid-update-kb` (targeted
  end-of-work updates through the review/calibration gate); query-side **gap capture** into
  a KB-gap queue. *(P8)*
- **S8 — Freshness-loop closers.** Change-triggered per-doc "suspect" flagging; minimal
  dashboard surfacing of per-doc freshness; **auto-detect/flag, not auto-apply**. *(P5)*
- **S9 — `aid-summarize` alignment.** Update the visual-summary rendering to the new KB
  model (summary+pointer, concept spine, audience).

### Out of Scope

- **O1 — Vector-DB / MCP semantic router.** Explicitly rejected (embedding model + binary +
  MCP server + ANN non-determinism; collides with the bare-box / deterministic ethos).
  Revisit only at hundreds of docs — and even then embed INDEX *rows* and return *paths*,
  never chunk-RAG.
- **O2 — Fully-automatic KB rewriting.** Updates stay **human-gated**; the system
  auto-detects and flags, but a human approves the change.
- **O3 — Auto-running discovery/updates** from `aid-execute` / `aid-deploy`. Auto-*detect /
  flag* is in scope (S8); auto-*apply* is not.
- **O4 — Non-KB pipeline changes.** No re-architecting of `aid-specify` / `aid-plan` /
  `aid-detail` / `aid-execute` / `aid-deploy` (beyond their consuming the improved KB) or
  other non-KB skills.
- **O5 — Dashboard work beyond** surfacing the per-doc freshness flag (no broader dashboard
  overhaul).
- **O6 — No follow-up deferral (of the In-Scope generation set).** The full In-Scope set is
  this one work, sequenced into deliveries by `/aid-plan`. *(The one explicit deferral is
  O7's forward-authored greenfield KB-seed, which was never part of the In-Scope generation
  work — greenfield here is detect + signpost only.)*
- **O7 — Forward-authored greenfield KB-seed.** Eliciting a from-scratch project's
  **intended** architecture, conventions, and ubiquitous-language to seed the KB *before any
  code exists* (a co-authoring "elicit" discovery mode) is **out of scope** — it is a future
  **interview-side** capability, not this work. This work's greenfield behavior is strictly
  **detect + signpost to /aid-interview + halt** (S5, FR-20/FR-21). *(supersedes the earlier
  greenfield generation-path framing; see Change Log 2026-06-23 greenfield de-scope)*

## 5. Functional Requirements

> Comprehensive. FRs are grouped by scope area and tagged `FR-N`, each tracing to the
> scope item(s) `S#` and problem(s) `P#` it satisfies. These are the *what*, not the
> *how* — implementation detail belongs to `/aid-specify`.

### A. INDEX routing (S1 · P6)

- **FR-1.** `INDEX.md` MUST be a generated **routing table** with columns
  *Document (link = path) · Objective · Summary · Tags · See-instead · Audience*
  (Audience lets a human filter to docs for their role).
- **FR-2.** KB-doc frontmatter MUST gain `objective:` (one-line purpose), `summary:`
  (one-sentence scope), `tags:` (list of concrete project terms), `see_also:` (optional
  negative-routing pointers).
- **FR-3.** `build-kb-index.sh` MUST compose the table deterministically from frontmatter
  (no LLM); the INDEX-fresh / KB-hygiene CI checks MUST be updated to the new format.

### B. `sources:` field + freshness (S2, S8 · P5)

- **FR-4.** Every KB doc MUST declare `sources:` — the files/dirs/external docs it summarizes — and an **`approved_at_commit:`** stamp (the commit at which the doc was last approved), written on approval by `aid-discover`/`aid-update-kb`. *(Q1 — the freshness baseline primitive.)*
- **FR-5.** A **deterministic per-doc staleness check** MUST compare each doc's `sources:`
  last-changed commit against that doc's **`approved_at_commit:`** stamp (FR-4) and mark drifted docs *suspect*.
- **FR-6.** Source changes MUST **trigger** per-doc suspect flagging; the dashboard MUST
  surface per-doc freshness (replacing the single coarse whole-KB badge) in **both** the Python (`dashboard/reader/`) and Node (`dashboard/server/reader.mjs`) readers, for parity.
- **FR-7.** Freshness MUST **auto-detect/flag but never auto-apply** — updates remain
  human-gated.

### C. KB document model — Aspect 1 (S3 · P1, P3, P7)

- **FR-8.** The doc set MUST be derived from a fixed, universal set of **concerns** (not a
  project-type enumeration) and **proposed → confirmed** with the user; a concern may
  split into multiple docs or add a project-specific doc.
- **FR-9.** KB docs MUST follow the **summary + pointer** model — synthesize the durable
  cross-cutting understanding, point to `sources:` for volatile detail.
- **FR-10.** KB docs MUST carry `owner:` (owner-role) and `audience:` frontmatter; the
  audience/ownership dimension informs document boundaries and the INDEX (audience filter).
- **FR-11.** Per-doc research **expectations MUST be phrased as open questions**, not
  fill-in templates.

### D. Discovery quality — Aspect 2 (S4 · P1, P2, P3, P4)

- **FR-12.** A **mechanical coined-term / salient-concept harvest** MUST scan all source
  types and emit a candidate-concept list (project-coined × recurring × cross-source).
  The harvest is the **lexical** channel; essence-capture additionally MUST cover
  **non-lexical, load-bearing concepts** (those with no recurring token) via a
  conceptual-synthesis channel, each **evidence-anchored to cited source spans**.
- **FR-13.** A **concept spine** (the grounded native concepts) MUST be built *before* the
  per-concern docs and shared with every researcher.
- **FR-14.** A **comprehension / closure loop** MUST iterate until the system is
  explainable using only defined native concepts + general knowledge (closure reached).
- **FR-15.** A **can't-explain-it tripwire** MUST treat any ungrounded project-specific
  term as a mandatory investigation (never ignorable noise).
- **FR-16.** Research MUST read **all source types** — code, docs/ADRs, reports, data
  bundles, commit/issue history — not just code.
- **FR-17.** Review MUST apply the **multi-mandate set** — Correctness, Anatomy/Coverage,
  Concept-closure, Teach-back, Calibration. The mandates are **invariant across paths**;
  the **panel size scales by path** (full parallel panel for brownfield-large; collapsed
  onto fewer reviewers — down to one running the checklist — for brownfield-small /
  greenfield).
- **FR-18.** **Teach-back closure MUST be the keystone exit criterion** — a reviewer, given
  only the KB, explains the engine and answers "what is X?" for the native concepts.
- **FR-19.** The rubric MUST gain a **Calibration** dimension (transcription / hollowness /
  coverage-vs-source / deferral-must-point), graded against mechanically-generated evidence
  lists (evidence-anchored).
- **FR-36 (operational sufficiency / act-back).** Review MUST verify the KB is **sufficient
  to act on**, not only to comprehend: an **act-back mandate** — the operational sibling of
  teach-back (FR-18) — MUST give a **clean-context agent** ONLY the KB **+ a representative
  project task** (drawn from the project's own domain) and require it to **(a)** produce a
  correct plan/outline for that change AND **(b)** flag **every point where the KB was
  insufficient** (every convention it had to assume, invariant it had to guess, gotcha it
  could not anticipate, or contract it had to reach for source to find). Each insufficiency
  is a finding at a severity that feeds the existing grader; **enough flags fail the gate**
  (act-back is a **sibling keystone** to teach-back — either open gap holds REVIEW open). To
  make the KB act-on-able, **operational guidance — conventions, invariants, gotchas,
  contracts — MUST be first-class structure** (named, greppable sections per the FR-8/FR-9
  doc model), not buried in prose, and the act-back mandate MUST check for that structure.
  The mandate is **invariant across paths** (the panel *size* scales — FR-17); it reuses the
  existing review panel + grader (no new grading infrastructure). *(extends FR-17/FR-18;
  sharpens FR-9/FR-11.)*

### E. Recon triage + two brownfield paths (+ greenfield detect/signpost) (S5 · P7)

- **FR-20.** A **recon pre-pass** MUST measure source-availability/complexity and classify
  the project as **greenfield / brownfield-small / brownfield-large**, human-confirmed —
  measured, not declared from a static `project.type`. **Greenfield detection** (essentially
  no extractable source) MUST drive the signpost (FR-21); brownfield-small/large are the two
  **generation** paths proposed for confirmation.
- **FR-21.** On **greenfield** detection, `aid-discover` MUST **emit a signpost and halt**
  ("Nothing to discover yet — run /aid-interview to define the project; the KB fills in via
  re-triage once code lands") — greenfield is **not** a generation path: no greenfield
  generation engine, no elicit-via-interview/specify discovery path, no greenfield closure
  loop, no greenfield review panel. The two **generation** paths (brownfield-small,
  brownfield-large) MUST each configure the method (generation shape, closure depth, panel
  size, source-of-truth, exit) per the agreed matrix; **teach-back closure is the invariant
  exit** for both generation paths. *(Forward-authored greenfield KB-seed is a future
  interview-side capability, out of scope — §4 O7.)*
- **FR-22.** The path MUST be **re-triaged every run**; the **greenfield→brownfield
  transition** MUST be handled (as code lands, re-triage re-routes from the signpost to the
  brownfield engine, which captures the now-extractable anatomy).

### F. Engineering targets (S6 · cost/wall-clock/determinism)

- **FR-23.** The method MUST meet the **§6 NFR budgets** for cost, wall-clock, and
  determinism. The **intended approach** is to maximize the deterministic/mechanical
  substrate and minimize + anchor LLM judgment (see §1.6); the **specific mechanisms**
  (scripted scans, batched-parallel closure, two-layer harness, etc.) are **design choices
  for `/aid-specify`**, not fixed here.
  *(FR-24 and FR-25 — the prescriptive "batched-parallel rounds" and "two-layer harness"
  mechanisms — were demoted from FRs to NFR targets in §6 + the §1.6 approach, to avoid
  locking implementation into the requirements.)*

### G. Skill topology (S7 · P8)

- **FR-26.** `aid-ask` MUST be **renamed `aid-query-kb`** (read-only Q&A; behavior
  preserved).
- **FR-27.** A new **`aid-update-kb`** skill MUST apply **targeted/punctual** KB updates
  (e.g., a finished work's deltas) through the same review/calibration gate as
  `aid-discover`.
- **FR-28.** `aid-query-kb` MUST **capture gaps** ("KB can't answer" / "KB contradicts
  code") into a KB-gap queue consumed by `aid-update-kb` / `aid-housekeep`.

### H. `aid-summarize` alignment (S9)

- **FR-29.** `aid-summarize` MUST render the **new KB model** (concept spine, summary +
  pointer, audience) in the visual summary.

### I. Adoption, escalation & integrity (gap-closure FRs)

- **FR-30 (migration / backward-compat · G1).** Existing KBs — including AID's own and
  adopters' — MUST be **migratable** to the new frontmatter schema and INDEX format. The
  generator and skills MUST handle the transition (upgrade-in-place or a migration step),
  following AID's existing migration precedent. No KB is stranded on the old format.
- **FR-31 (concept model persisted · G2).** The concept spine MUST be **persisted as a
  first-class KB document** (the ubiquitous-language / glossary doc, upgraded) that other
  docs reference and the INDEX routes to — a durable artifact, not in-process scratch.
- **FR-32 (human escalation · G3).** When a project-specific concept **cannot be grounded
  from the artifacts**, discovery MUST **escalate it as a Q&A to the human** rather than
  silently drop it — converting silent misses into explicit questions.
- **FR-33 (housekeep ↔ update-kb boundary · G4).** `aid-housekeep` (KB-DELTA) is
  **source-driven and global** (whole-KB reconcile against current source state — merge to
  master / major change / periodic; uses FR-5 per-doc staleness to scope). `aid-update-kb`
  is **prompt-driven and targeted** (a prompt specifies what to update; it analyzes how
  best to fold that into the KB via the review/calibration gate). The two MUST NOT overlap;
  per-doc staleness (FR-5) is the shared signal.
- **FR-34 (closure as a standing invariant · G6).** Concept-closure (FR-14) MUST be a
  **maintained invariant**, not a discovery-only check: `aid-update-kb` and `aid-housekeep`
  MUST **re-verify closure** after they change the KB.
- **FR-35 (validation against the failure case · G5).** The method MUST be **validated
  against a known-missed-concept fixture** (a 'Relative bus'-style concept it is required
  to capture), proving the essence-capture gap is closed and guarding against regression.

### J. Domain-driven discovery + dual-audience authoring (feature-014)

> AID targets **any kind of digital work**, not only software. Discovery's start must adapt
> the KB doc-set to the **project's domain** instead of forcing a fixed software taxonomy,
> and must derive everything it can from the **existing source** (brownfield-first), using
> the human only to resolve what the source cannot settle. The docs it produces serve **two
> audiences at once** — junior humans and AI agents.

- **FR-37 (generic core dimension spine).** The doc-set MUST derive from a **domain-agnostic
  dimension/concern spine** — the universal questions any digital deliverable must answer
  about itself (what it is/does, what it is made of, how the parts connect, what it is built
  with, conventions, vocabulary, deliverables/data/contracts, quality, risk, shipping/
  operation, decisions; plus the cross-cutting **stakeholders/concerns** meta that informs the
  spine but is captured **interview-side, not as a KB doc**) — grounded in established
  documentation standards (arc42, C4, IEEE 1016, ISO/IEC/IEEE 42010, ADR). The current concern model (C0–C9) is the
  **software rendering** of this spine; the spine itself is project-type-agnostic. Project-
  management frameworks (PMBOK, PRINCE2, Scrum) document **governance**, which maps to AID's
  **pipeline artifacts** (REQUIREMENTS/SPEC/PLAN/tracking), **not** the KB. *(generalizes
  FR-13; extends the concern model in `concern-model.md`.)*
- **FR-38 (domain classification from source).** Discovery MUST **establish the project's
  domain by analyzing the existing source** (project-index + repository content). When the
  source is **decisive**, classify; when it is **insufficient, uncertain, or dubious**,
  **query the user**. Domain is **measured-then-confirmed**, never declared from a static
  `project.type`. *(distinct from the full-vs-lite triage, which is interview-side.)*
- **FR-39 (doc-set = matrix-or-research, anchored + composable).** The confirmed domain MUST
  resolve to a doc-set two ways: **fast path** — a shipped, curated **domain→doc-set matrix**
  supplies the set; **fallback** — on a matrix miss (novel/hybrid), discovery **researches the
  domain's documentation practices** and **synthesizes** a doc-set. Either way the set is
  **anchored to the FR-37 spine** (every spine dimension covered or explicitly marked
  conditional), doc-sets are **composable** (a hybrid project = the union of relevant
  domain profiles over one spine — never mutually-exclusive buckets), and the result is
  **proposed→confirmed** with the user. The legacy 15-doc seed becomes simply the **software
  row** of the matrix. *(generalizes FR-17's path-scaling to domain-scaling; replaces the
  hardcoded default seed with a matrix lookup.)*
- **FR-40 (matrix lifecycle — no automatic cross-install propagation).** The matrix is a
  **shipped, version-controlled `canonical/` artifact**, updated only through AID's normal
  **release / human-curation** process. A project's confirmed/researched doc-set **persists
  locally** (`.aid/settings.yml → discovery.doc_set`). Discovery MAY **emit a contribution-
  candidate artifact** (a proposed matrix row + provenance) the user can choose to PR
  upstream; promotion to the global matrix is a maintainer action. There MUST be **no
  automatic install→canonical feedback** (no telemetry/phone-home). *(the install boundary is
  one-directional: canonical → user.)*
- **FR-41 (self-bootstrap discovery start).** `/aid-discover` MUST **self-create
  `.aid/knowledge/STATE.md`** from its template when absent, rather than hard-failing on a
  missing `/aid-config` init scaffold. Discovery becomes self-starting; init coupling is
  removed. *(removes the `discover-preflight.sh` STATE-precondition hard-stop.)*
- **FR-42 (source-first fill, user-as-gap-filler).** Discovery MUST **fill each document from
  the existing source** first; the human is consulted **only** to fill gaps, resolve
  uncertainties, answer questions, clarify, and confirm. *(reaffirms the brownfield + Q&A
  doctrine for the domain-driven flow.)*
- **FR-43 (dual-audience doc granularity, clarity & format).** KB documents MUST be **one
  concern per document with minimal overlap** — big generic documents are **split into small,
  focused ones** (small-and-focused is the default bias). Language MUST be **simple and clear,
  targeting a junior professional** (clarity and comprehension over jargon/complexity). Format
  MUST prefer **tables and bullet points and AVOID diagrams** in the KB `.md` documents (the
  visual summary `kb.html` remains a separate, deliberately-visual artifact). *(strengthens
  the three-force boundary rule in `concern-model.md`; sets an explicit reading-level + format
  standard.)*
- **FR-44 (dual-audience classification & layout).** Every KB document MUST be **classified
  and formatted so an AI agent can consume it in-context** as well as a human: machine-parseable
  **frontmatter** (concern/dimension, tier, audience, owner, tags), **named greppable sections**
  for operational guidance, and **summary+pointer** chunks loadable selectively via `INDEX.md`.
  Document **layout MUST be: frontmatter → index → content → change log (always last)**.
  *(extends the f001 frontmatter/audience axis + `tier-model.md` + the named-operational-section
  model into an enforced standard checked by the review panel's Anatomy mandate.)*

### K. Domain-driven `kb.html` summary redesign (feature-015)

> Feature-014 made the KB **domain-driven** and **diagram-free** (FR-37–FR-44), but
> `/aid-summarize` — which renders the KB into `.aid/dashboard/kb.html` — was never updated and
> is still bound to the old fixed-software model. The **foundational reframing** is that `kb.html`
> is a **different product from the KB**: its audience is a **non-technical newcomer**, so it is
> easy-to-read and **visually rich**, and the KB's no-diagrams authoring rule does **NOT** apply
> to it. Completeness for the summary = ALL project-relevant information is represented, with the
> **format of each piece chosen to fit that piece** (diagram, infographic, table, card, pill, or
> prose). The redesign keeps the production-grade visual language + the dashboard self-containment
> contract + page-shell consistency with `home.html`/`index.html`; it changes the information
> architecture, content components, and generation. Source of record: the design seed at
> `.aid/design/aid-summarize-redesign.md`.

- **FR-45 (doc-set/domain-driven input).** `/aid-summarize` MUST derive its sections from the
  **resolved doc-set** (`.aid/settings.yml → discovery.doc_set`) and the `## Discovery Domain`,
  rendering **one section per resolved doc / `kb-category`** from each doc's frontmatter — NOT
  by selecting a software project-TYPE profile. The **phantom `repo-presentation.md`** reference
  MUST be removed and the `noscript` doc list MUST be **derived from the resolved doc-set**, not
  hardcoded. *(consumes FR-39's `discovery.doc_set`; retires the fixed software-seed input.)*
- **FR-46 (concept-first content components).** The summary MUST render the **Concept Spine**
  (`domain-glossary.md`) and **`decisions.md`** (the ADRs) and the **capability inventory** as
  **first-class content components** (glossary/definition, decision/ADR card, capability entry)
  — **rendered as content, not linked**. *(consumes feature-014's custom docs + the f004 concept
  spine.)*
- **FR-47 (best-format-per-fact + completeness grading).** The summary's grade MUST reward
  **clarity, completeness (coverage of all project-relevant information), and visual
  communication for a newcomer**, with **no diagram-count floor and no diagram-count ceiling**.
  The previous "cap at C+ unless N diagrams" gate MUST be removed and the KB no-diagrams rule
  MUST NOT be applied to the summary. *(replaces the diagram-quantity proxy with a clarity +
  coverage rubric.)*
- **FR-48 (non-technical newcomer tone).** Summary prose MUST target a **non-technical
  newcomer** — friendly, plain-language, explaining the *what* and *why* accessibly — and MUST
  drop the KB's dual-audience / agent-frontmatter framing; "At a Glance" MUST NOT lead with
  software metrics. *(the summary is a different product from the dual-audience KB.)*
- **FR-49 (page-shell consistency, inner-content freedom).** The summary's OUTER shell (top bar,
  side panel, search, nav chrome) MUST stay **consistent/aligned with `home.html` and the CLI
  `index.html`** for seamless dashboard navigation; only the **inner content area**
  (illustrations, graphics, tables, pills, cards, diagrams) is redesigned. *(the chrome is not
  reinvented.)*
- **FR-50 (data-driven deterministic generation).** The summary MUST be generated
  **data-drivenly and deterministically** from the resolved doc-set (reproducible + auditable),
  **not** freehand-LLM HTML. *(narrows the LLM's role to per-component content authoring;
  assembly/ordering/shell/inlining are mechanical.)*
- **FR-51 (pre-render visuals; drop Mermaid; visual-fidelity gate).** Visuals MUST be
  **pre-rendered to inline SVG / HTML+CSS at build time** and the **~3MB runtime Mermaid engine
  MUST be removed** (page 3.4MB → tens of KB; no runtime diagram engine). Because Mermaid's
  automatic layout guarantee is lost, the VALIDATE state MUST add a **visual-fidelity gate**:
  **every pre-rendered visual is validated** by **Playwright render** (preferred) or explicit
  **visual inspection**, asserting **readable text**, **minimal/zero element overlap**, and a
  **correct basic layout**; a failing visual is a generation defect fixed before DONE. This
  **replaces** Mermaid's render-correctness check. The page MUST remain a **single
  self-contained file** (no CDN / split assets / framework fetch). *(server-side gzip/cache of
  the dashboard leaf is an explicit fast-follow — OUT of this work.)*

> **Guardrails (must not break — apply to all of FR-45–FR-51):** **C1** output path exactly
> `<repo>/.aid/dashboard/kb.html`; **C2/C3** single self-contained file, no CDN/split assets;
> **C5** approval signal stays `## Knowledge Summary Status` → `**User Approved:** yes (YYYY-MM-DD)`
> in `.aid/knowledge/STATE.md`; **C6** keep the `README.md ## Completeness` rows +
> `.aid/settings.yml kb_baseline:` shape. The keep-list (design tokens, light/dark theming,
> focus-trapped lightbox, a11y baseline, responsive layout, single-file self-containment) is
> preserved — the redesign is information architecture + content + generation, not visual language.

### L. Dual-intent KB self-evaluation + spine-keyed domain-general depth (feature-016)

> feature-014 made discovery domain-general in **architecture** (the spine + the domain→doc-set
> matrix), but two mechanisms that make a KB *useful* were left **filename-keyed and
> software-only**: the per-doc **depth contract** (`document-expectations.md`, keyed by
> `### <filename>`) and the **sufficiency safeguard** (`kb-actback-task.sh` + the M4 act-back
> gate). For **36** of the **58** filenames the matrix can emit (58 emittable − 22 covered;
> incl. the shared `glossary.md`/`tooling-stack.md` + all non-software domain docs), the depth
> contract is a **dangling anchor** and the safeguard is **provably inert** (both VERIFIED). The fix is one
> principle — **lift everything domain-specific from FILENAME-keyed → SPINE-DIMENSION-keyed** (the
> matrix already records each doc's spine dimension) **and derive the self-evaluation probes from
> the project's own source + capabilities** — and one mechanism: a **Dual-Intent KB
> Self-Evaluation** that turns the two user intents into measurable, self-run REVIEW keystone
> gates with **no external test corpus** (the project *is* the test). Source of record: the design
> seed at `.aid/design/aid-discover-dual-intent-self-eval.md`.

- **FR-52 (spine-keyed depth contracts).** The per-doc depth contract MUST be **keyed by spine
  dimension, not by filename**: a **work-actionable depth standard authored once per spine
  dimension** (C0–C9 + D) — e.g. the **C5** doc carries the data shapes/fields/types/constraints
  **+ the extension procedure**; the **C3** doc carries the project's **actual conventions +
  concrete examples + red-flags**; etc. — that **every** doc in any resolved doc-set (software,
  data-ml, content, research, design, ops, methodology-tooling, or auto-researched) inherits via
  its spine dimension. The GENERATE custom-doc prompt MUST be re-pointed at this dimension-keyed
  standard so **no doc is left at a dangling `### <filename>` anchor**. Per-filename entries, where
  present, become **optional additive refinements**, never the sole source of depth.
  *(closes the dangling-anchor gap; generalizes today's software-only `document-expectations.md`.)*
- **FR-53 (spine-keyed safeguard + C9-derived task generation).** `kb-actback-task.sh`'s
  operational-class **owning-table** (`_doc_expects_class`) and its **representative-task selector**
  MUST be re-keyed from filenames → **spine dimensions** (single-sourced from `concern-model.md`'s
  "Operational guidance is first-class structure" owning-table, re-stated in dimension terms), so
  the presence check fires on whatever doc realizes the owning dimension (`data-schemas.md` /
  `design-tokens.md` exactly as `schemas.md`). The representative task MUST be **C9-derived and
  domain-appropriate** — "add / modify / extend «a capability the project actually has»", seeded
  from the **C9** capability/what-it-does doc — **not** a hardcoded "add an endpoint" fallback.
  Determinism (NFR-3) is preserved (same doc-set + C9 doc → byte-identical task spec); the
  byte-stable software seed and existing TSV-consumers stay green.
  *(makes the f013 act-back safeguard fire off-software; the dangling-safeguard fix.)*
- **FR-54 (Blind Work-Simulation — the assertiveness gate, Intent 1).** The REVIEW state MUST run a
  domain-general **Blind Work-Simulation** limb (generalizing the M4 act-back keystone): a
  clean-context, **KB-only** agent plans each derived **work probe** step-by-step in the project's
  **own conventions**, tagging each step **STATED / ASSUMED / REACH**. Any **load-bearing
  ASSUMED/REACH** is a `[HIGH] [ACTBACK]` insufficiency (FAIL → FIX target). The check is **quality,
  not just functional**: a plan that would "work" but violates the project's conventions (C3),
  invariants/gotchas, or quality bars (C6) is a **quality FAIL**. PASS = a complete, correct,
  convention-honoring plan with **zero load-bearing insufficiencies**; this is a **hard keystone
  gate** (a FAIL caps the grade). *(generalizes FR-36's act-back from one task to a derived probe
  set with STATED/ASSUMED/REACH + a quality dimension.)*
- **FR-55 (Blind Reconstruction + Source Confrontation — the essence gate, Intent 2).** The REVIEW
  state MUST run a domain-general **essence** limb (generalizing the M3 teach-back keystone) in two
  stages: (1) a clean-context **KB-only** agent reconstructs the project's what/why/how essence over
  **essence probes** derived from the C4 vocabulary + C9 capabilities + D decisions + high-salience
  source facts; (2) a second **source-grounded** agent **confronts** the reconstruction against the
  actual project — a **Divergence** (KB-only answer WRONG vs source) is a `[HIGH] [FIDELITY]` FIX
  target; a load-bearing **Omission** is a `[MED] [ESSENCE-GAP]` FIX target. PASS = **no divergence**
  + load-bearing essence-coverage ≥ threshold; this is a **hard keystone gate**. The probes are
  **derived from the project itself** (its source = ground truth; its capabilities = task seeds), so
  the gates run for **any** domain with **no external test corpus**. *(generalizes FR-18's teach-back
  with an explicit source-confrontation stage catching divergence, not just omission.)*
- **FR-56 (altitude-rule signature exception).** The KB authoring altitude/summary+pointer rule
  (`principles.md` P1(d)) MUST be amended so that **load-bearing operational contracts an agent must
  honor to ACT** — field types, exit codes, the args/modes/invariants — are stated **INLINE or with
  a precise grep-recoverable anchor**, **never** a bare `sources:` file pointer. The altitude rule
  continues to de-bloat *narrative* volatility but MUST NOT evict *work-critical contracts*; the
  Blind Work-Simulation limb (FR-54) enforces this automatically (if the agent must REACH for a
  contract, it FAILs). AID's own KB re-injects the contracts the over-broad rule evicted (host-tool
  matrix, exit-codes) as the first beneficiary. *(repairs the signature tax the two critique rounds
  measured.)*

> **Validation (must, applies to all of FR-52–FR-56) — fixtures + dogfood, no external corpus.**
> Because there are **no in-the-wild non-software projects** to test on, the mechanism's generality
> is proven with **fixtures**: per non-software domain (data-ml, design, content) a **GOOD** mini-KB
> (must PASS both gates) and a **SHALLOW/WRONG** mini-KB (omits field types / diverges from a tiny
> fixture "source" → must FAIL the right limb), extending the existing in-suite `actback-task`
> fixture pattern. The tests assert the probe derivation is domain-appropriate (not "add an
> endpoint"), the owning-table presence check fires on the domain's C5/C3 doc, the assertiveness
> limb FAILs the SHALLOW KB, and the essence limb FAILs the WRONG KB. AID itself (software +
> methodology) is the **live regression dogfood**. The concrete PASS thresholds the FR-54/FR-55
> "≥ threshold" clauses reference (assertiveness % STATED, essence-coverage %) are a **deliberate
> scoping deferral — calibrated in DETAIL / delivery-015** against the AID dogfood + the fixtures
> (start strict: zero HIGH, ≥90% STATED), not an omission. The spine cardinality (the 11-dimension T2
> contract), the matrix's domain set, the classifier, and `synth_default_seed`'s byte-stable
> software seed are **untouched** — this feature *consumes* feature-014's spine, it does not grow it;
> it reuses the existing `aid-reviewer` parallel panel + `grade.sh` + the 7-column ledger schema
> (no new grading infra, no new agent enum value), consistent with feature-013.

## 6. Non-Functional Requirements

> Quality attributes and **the budgets FR-23 references** (the cost/wall-clock/determinism
> targets demoted from former FR-24/FR-25). Stated as *budgets and direction*, not
> false-precision numbers; the §1.6 approach is the intended means, mechanism chosen at
> `/aid-specify`.

### Performance & cost

- **NFR-1 (cost scales with project).** Discovery cost MUST scale with project
  size/complexity via the triage (FR-20): **greenfield and brownfield-small are cheap**;
  brownfield-large spends more, justified by complexity. Mechanical operations MUST run as
  scripts, not LLM dispatches. For an equivalent brownfield project, total discovery cost
  SHOULD stay **within the same order of magnitude as today's `aid-discover`**, not a
  multiple of it.
- **NFR-2 (wall-clock / critical path).** The method MUST keep the **sequential critical
  path short** — parallel fan-out (deep dives), batched-parallel closure rounds, fully
  parallel review panel. The closure loop MUST be **bounded** (K-consecutive-clean or token
  budget) so wall-clock cannot run away.
- **NFR-3 (determinism / repeatability).** Control flow, gates, closure-termination, and
  all mechanical checks MUST be **deterministic and CI-able**. The LLM-judgment surface
  MUST be **minimized and anchored** (fixed teach-back question sets; schema-validated
  worker outputs; evidence-anchored grading). **Honest floor:** synthesis / "did it
  understand" are irreducibly judgment — shrink & anchor the surface, don't eliminate it.

### Quality attributes

- **NFR-4 (maintainability / conventions-fit).** All changes MUST fit AID's
  **canonical→render** pipeline and deterministic-helper conventions, and MUST be
  **CI-guarded** (lints, render-drift, KB-hygiene, INDEX-fresh updated to the new format).
- **NFR-5 (dual-audience usability).** Each KB doc MUST be **digestible by its target human
  role** *and* **machine-routable**; the `INDEX.md` table MUST be scannable in one pass.
- **NFR-6 (trust / visibility).** Behavior MUST be **predictable and visible** (the
  AI-skeptic product promise). No hidden non-determinism, no opaque retrieval. Detection may
  be automatic; **changes to the KB remain human-gated** (cross-ref O2).
- **NFR-7 (backward-compatibility during migration).** The migration (FR-30) MUST NOT break
  existing pipelines: an un-migrated old-format KB MUST keep functioning (degrade
  gracefully) until upgraded, and the migration MUST be safe/reversible per AID precedent.
- **NFR-8 (no new runtime dependency).** The solution MUST stay within AID's
  **bare-box / dependency-free** stance — no embedding model, binary, MCP server, or
  `python3`/`pwsh`-version escalation for the core path (cross-ref O1, O2).

## 7. Constraints

> Hard boundaries the solution MUST respect (distinct from NFR targets: these are
> non-negotiable platform/process rules).

- **C1 — Bare-box / dependency-free.** No new runtime for the core path: no embedding
  model, no extra binary, no MCP server, no `python3`/`pwsh`-version escalation. (Enforces
  O1, NFR-8.)
- **C2 — ASCII-only + Windows-PowerShell-5.1-compatible** for any shipped installer/CLI
  scripts touched (CI-guarded: `test-ascii-only.sh`, `test-ps51-compat.sh`, the 5.1 lane). This **includes the new mechanical KB scripts** (coined-term scan, closure check, salience) — they vendor into the install bundles and are therefore 'shipped' → ASCII-only applies (bash, so PS-5.1 is N/A). *(Q2)*
- **C3 — canonical→render single source.** All skill / agent / template / script content
  is authored in `canonical/` and rendered to the five host trees; **render-drift CI must
  stay green** (no hand-edited rendered copies).
- **C4 — Human-gated changes.** Detection/flagging may be automatic, but **every change to
  KB content requires human approval** (the gated state-machine ethos; enforces O2/O3).
- **C5 — Deterministic, CI-testable mechanical layer.** Every mechanical operation must be
  a script runnable and assertable in CI (the canonical helper-suite pattern).
- **C6 — Content-isolation cornerstone.** AID-delivered content stays namespaced/isolated
  from user content (e.g. `aid-` prefixes, manifests); the new `aid-query-kb`/`aid-update-kb`
  and any new templates/scripts follow it.
- **C7 — KB-hygiene & INDEX-fresh CI must pass** under the new frontmatter/INDEX format
  (the checks are updated, not bypassed).
- **C8 — AID skill conventions.** New/changed skills follow the **thin-router `SKILL.md` +
  `references/` state-machine** pattern and the one-step-per-turn, visible-discipline
  contract.

## 8. Assumptions & Dependencies

### Assumptions

- **A1.** Most **load-bearing concepts leave a textual fingerprint** (identifiers,
  comments, tests, docs, commits) that the mechanical harvest can surface. Purely implicit
  concepts are handled by the human escape hatch (FR-32), not assumed away.
- **A2.** Agents can perform **teach-back / closure judgment** reliably **when anchored** to
  a fixed question set + evidence list (NFR-3); unanchored free judgment is not assumed.
- **A3.** The host agent runtime **supports parallel sub-agent dispatch** for the panel and
  deep-dive fan-out; where it does not, the method **degrades gracefully to sequential**
  (the `aid-execute` capability-probe precedent).
- **A4.** A project's source-of-truth is reachable (repo, docs, history) for the brownfield
  generation paths; a greenfield project has no extractable source yet, so discovery only
  **signposts to `/aid-interview`** (the human defines the project there) and the KB is built
  later via re-triage as code lands.

### Dependencies

- **D1.** The AID **agent roster** — `aid-researcher` (scout/architecture/analyst/
  integrator/quality), `aid-architect`, `aid-reviewer`, `aid-clerk`, `aid-orchestrator`,
  `aid-interviewer`.
- **D2.** The **canonical→render generator**, `build-kb-index.sh`, `read-setting.sh`,
  `grade.sh`, and the `kb-authoring/` templates (frontmatter-schema, rubric, tier-model,
  principles).
- **D3.** The **dashboard reader** (`reader.py` / `reader.mjs`, `parsers.py`,
  `derivation.py`) for surfacing per-doc freshness.
- **D4.** AID's **migration precedent** (`migrate-work-hierarchy`, the content-isolation
  migration) for FR-30.
- **D5.** `.aid/settings.yml` keys — `discovery.doc_set`, `kb_baseline`, `*.minimum_grade`.
- **D6.** **CI** — `test.yml` canonical suites, render-drift, KB-hygiene, INDEX-fresh,
  installer/CLI lanes.

## 9. Acceptance Criteria

> The testable bar. Each AC names the FR/NFR it verifies. **Teach-back closure (AC1) is the
> keystone**; AC2 is the regression guard for the original complaint.

- **AC1 — Teach-back closure (keystone).** A fresh agent, given **only the KB**, can
  correctly answer "what is X?" for the project's core native concepts (per-term limb)
  **and** narrate how the project works end-to-end in its own language (the non-lexical
  engine-narration limb — its own FAIL even when every term is defined). *(FR-18)*
- **AC2 — Known-missed-concept fixture.** On a fixture project containing a planted
  'Relative bus'-style coined concept, the method **captures and defines it**; a regression
  test guards it. *(FR-35, FR-12)*
- **AC3 — Concept closure / self-containment.** No project-specific term used anywhere in
  the KB is left undefined (the deterministic self-containment check passes). *(FR-14, FR-34)*
- **AC4 — INDEX routing table.** `INDEX.md` is the generated table (Objective · Summary ·
  Tags · See-instead · Audience); the generator is deterministic; INDEX-fresh CI is green.
  *(FR-1, FR-3)*
- **AC5 — `sources:` + per-doc freshness.** Every KB doc declares `sources:`; the per-doc
  staleness check flags drifted docs; the dashboard surfaces per-doc freshness. *(FR-4,
  FR-5, FR-6)*
- **AC6 — Calibration grading.** On planted fixtures, the rubric flags **transcription**
  (too fat), **hollowness** (too thin), and **coverage-vs-source** gaps. *(FR-19)*
- **AC7 — Triage: two brownfield paths + greenfield detect/signpost.** The recon triage
  proposes the correct **generation** path on **brownfield-small** and **brownfield-large**
  fixtures, and each runs and reaches **teach-back closure**; on a **greenfield** fixture
  (~0 extractable source) the triage **detects greenfield** and `aid-discover` **emits the
  signpost and halts** (a detection/signpost test — NOT a greenfield path-runs-to-closure
  fixture). *(FR-20, FR-21)*
- **AC8 — Skill topology.** `aid-ask`→`aid-query-kb` (behavior preserved); `aid-update-kb`
  applies a prompt-driven targeted update through the review/calibration gate; a failed
  `aid-query-kb` query **enqueues a gap**. *(FR-26, FR-27, FR-28)*
- **AC9 — Migration.** AID's own KB (and a fixture old-format KB) migrates to the new
  schema; an un-migrated KB **degrades gracefully** until upgraded. *(FR-30, NFR-7)*
- **AC10 — Housekeep ↔ update-kb boundary.** `aid-housekeep` performs whole-KB source-driven
  reconcile; `aid-update-kb` performs prompt-driven targeted update; no overlap. *(FR-33)*
- **AC11 — Determinism / cost / wall-clock.** Mechanical checks are deterministic in CI;
  the closure loop is bounded; equivalent-project cost stays within the same order of
  magnitude as today's discover. *(NFR-1, NFR-2, NFR-3)*
- **AC12 — Conventions & no new dependency.** No new runtime dependency; ASCII/5.1 honored;
  canonical→render with render-drift + KB-hygiene CI green. *(NFR-4, NFR-8, C1–C3, C7)*
- **AC13 — Human-gated.** KB content changes require human approval; only detection/flagging
  is automatic. *(NFR-6, O2, C4)*
- **AC14 — Concept model persisted.** The concept spine exists as a **first-class KB doc**
  that other docs reference and the INDEX routes to (not in-process scratch). *(FR-31)*
- **AC15 — Human escalation.** An ungroundable project-specific concept produces a **human
  Q&A entry** (surfaced, not silently dropped). *(FR-32)*
- **AC16 — Operational sufficiency (act-back).** A fresh agent, given **only the KB + a
  representative project task**, can produce a correct plan/outline for the change (the
  plan-correctness limb) **and** every point where the KB was insufficient — a convention it
  had to assume, an invariant it had to guess, a gotcha it could not anticipate, or a
  contract it had to reach for source to find — is **flagged** (the sufficiency limb); enough
  flags fail the gate. Operational guidance (conventions / invariants / gotchas / contracts)
  is **first-class greppable structure** in the relevant docs (the mechanical anchor the
  mandate checks). Act-back is a **sibling keystone** to teach-back (AC1) — either an
  explain-gap or an act-gap holds REVIEW open. The mechanical substrate (the representative
  task is well-formed + deterministic; the named operational sections are present/absent) is
  CI-asserted; the judgment half (does the plan succeed; are the flags well-founded) is
  runtime-anchored (the same mechanical-vs-judgment boundary AC1/AC6 honor). *(FR-36)*

## 10. Priority

> All items are **in this one work** (§4: nothing deferred to a follow-up). This MoSCoW is
> **relative priority to guide `/aid-plan`'s delivery sequencing**, not a scope cut.

- **Must (fix the reported pain — the essence + its proof):** Aspect-2 essence capture
  (FR-12–FR-16), the multi-mandate panel + teach-back exit (FR-17, FR-18), the Calibration
  dimension (FR-19), the INDEX routing table (FR-1–FR-3), `sources:` (FR-4),
  concept-model persisted (FR-31), human escalation (FR-32), **migration** (FR-30), the
  validation fixture (FR-35), the **operational-sufficiency / act-back gate** (FR-36 — the
  operational sibling of teach-back: a 6th panel mandate + operational guidance as
  first-class doc structure), and the recon triage with the **brownfield-small +
  brownfield-large** generation paths **plus greenfield detection + signpost** (FR-20/FR-21:
  greenfield detect/signpost and the two brownfield generation paths are all Must).
- **Must (feature-014 — domain-driven discovery + dual-audience authoring):** the
  domain-agnostic generic core spine (FR-37), source-driven domain classification with
  user-on-uncertainty (FR-38), the matrix-or-research doc-set anchored + composable (FR-39),
  the matrix lifecycle with no auto cross-install propagation (FR-40), self-bootstrap
  discovery start (FR-41), source-first fill (FR-42), and the dual-audience authoring
  standard — single-concern small docs, junior-clear language, tables/bullets-no-diagrams,
  machine-consumable classification, frontmatter→index→content→changelog layout (FR-43, FR-44).
- **Must (feature-015 — domain-driven `kb.html` summary redesign):** realign `/aid-summarize`
  to the domain-driven KB and reframe `kb.html` as a **non-technical-newcomer, visually-rich**
  product (the KB no-diagrams rule does not apply) — doc-set/domain-driven sections (FR-45),
  concept-first content components rendering the Concept Spine + `decisions.md` + capabilities
  (FR-46), best-format-per-fact + completeness grading with the diagram-count cap removed
  (FR-47), non-technical newcomer tone (FR-48), page-shell consistency with `home.html`/
  `index.html` + inner-content freedom (FR-49), data-driven deterministic generation (FR-50),
  and pre-rendered inline-SVG visuals + drop the 3MB Mermaid engine + the visual-fidelity gate
  (FR-51) — within the C1/C2/C3/C5/C6 + page-shell guardrails. **Two deliveries:** D-011
  correctness-core then D-012 visual & engineering. *(Server-side gzip/cache = fast-follow, OUT.)*
- **Must (feature-016 — dual-intent KB self-evaluation + spine-keyed domain-general depth):** make
  `/aid-discover` produce *useful* KBs off-software, not only on the two domains AID dogfooded, by
  lifting everything domain-specific **filename-keyed → spine-dimension-keyed** and deriving the
  self-eval probes from the project's own source + capabilities — spine-keyed depth contracts that
  close the dangling-anchor gap (FR-52), the spine-keyed safeguard + C9-derived task generation that
  makes the act-back gate fire off-software (FR-53), the **Dual-Intent KB Self-Evaluation** — Blind
  Work-Simulation (assertiveness gate, Intent 1, FR-54) + Blind Reconstruction & Source Confrontation
  (essence gate, Intent 2, FR-55), both domain-general REVIEW keystone gates with no external test
  corpus — and the altitude-rule signature exception that keeps work-critical contracts inline
  (FR-56). Proven by per-domain GOOD/SHALLOW fixtures + the AID dogfood. **Four deliveries:** D-013
  depth → D-014 safeguard → D-015 self-eval → D-016 signature exception + dogfood; the feature
  depends on feature-014 (already built). *(Consumes the spine; does not grow it. No new grading
  infra / agent enum.)*
- **Should (keep it fresh + clean):** per-doc staleness + change-triggered flagging (FR-5,
  FR-6, FR-7, FR-8), `aid-update-kb` + gap capture (FR-27, FR-28), `aid-ask` rename (FR-26),
  housekeep↔update-kb boundary (FR-33), closure-as-standing-invariant (FR-34),
  `aid-summarize` alignment (FR-29).
- **Could (completeness, highest-risk / most speculative):** the greenfield→brownfield
  transition handled by re-triage (FR-22, beyond the Must detect/signpost); audience-column
  polish; dashboard per-doc surfacing niceties. *(The former "greenfield path" Could item is
  removed — there is no greenfield generation path; greenfield is detect + signpost, part of
  the Must recon, FR-20/FR-21.)*
- **Won't (this work):** O1–O5 (vector router, auto-apply, auto-run from execute/deploy,
  non-KB pipeline changes, broader dashboard work); **O7** — forward-authored greenfield
  KB-seed (a future interview-side capability, not this work).
