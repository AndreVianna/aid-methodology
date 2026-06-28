# Web-Grounded Validation — AID Greenfield Seed Authoring vs. Current Design-First Best Practice

**Scope.** Validates AID's BUILT greenfield seed-authoring (work-001 delivery-004:
`aid-describe` DESCRIBE-SEED state + coherence check, plus `aid-housekeep` KB-DELTA
Conformance Lane) against current web best practice for design-first / spec-first /
intent-first greenfield software development.
**Author:** Researcher subagent. **Date:** 2026-06-28.

---

## (a) Web access confirmation

**Mechanism used: Bash `curl`** (no WebSearch/WebFetch tool was exposed to this agent;
outbound HTTPS via curl works). General search engines (DuckDuckGo HTML + lite) returned
**bot-challenge / anomaly captcha pages** (verified: `anomaly-modal__title "Unfortunately,
bots use DuckDuckGo too"`), so search-result scraping was not viable. **Direct URL fetches
to authoritative pages returned HTTP 200 with full content** — that is how every claim below
is grounded. Each source was fetched, HTML-stripped to text, and read.

Sample of URLs actually fetched (HTTP 200, content read — full list in Sources):
- `https://github.blog/.../spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/`
- `https://raw.githubusercontent.com/github/spec-kit/main/README.md`
- `https://www.thoughtworks.com/radar/techniques/spec-driven-development`
- `https://tom.preston-werner.com/2010/08/23/readme-driven-development.html`
- `https://martinfowler.com/articles/designDead.html`, `.../bliki/UbiquitousLanguage.html`, `.../bliki/Yagni.html`
- `https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions`
- `https://agilemodeling.com/essays/agileDocumentation.htm`
- `https://swagger.io/resources/articles/adopting-an-api-first-approach/`

Nothing below is from training memory; every "current best practice" claim cites a fetched URL.

---

## (b) Sourced best-practice principles

Each principle = a real fetched source (URL + access date 2026-06-28) + a one-line note of what it says.

**P1 — Intent / spec is the source of truth (the AI-era shift).**
*GitHub Blog, "Spec-driven development with AI"* (2025; fetched 2026-06-28):
"We're moving from 'code is the source of truth' to 'intent is the source of truth.' With AI
the specification becomes the source of truth and determines what gets built." Spec = "a
contract for how your code should behave."

**P2 — Write the doc/spec FIRST, before any code (RDD / DDD).**
*Tom Preston-Werner, "Readme Driven Development"* (2010; fetched 2026-06-28): "Write your
Readme first. First. As in, before you write any code… A perfect implementation of the wrong
specification is worthless." Forces you to "think through the project without the overhead of
having to change code every time you change your mind."

**P3 — Establish the ubiquitous language / domain model up front; it is rigorous and evolves.**
*Martin Fowler, "Ubiquitous Language"* (2006; fetched 2026-06-28): a "common, rigorous
language between developers and users… based on the Domain Model," and the "language (and
model) should evolve as the team's understanding of the domain grows."

**P4 — Just-enough design; document STABLE things, not speculative ones; BDUF increases failure risk.**
*Scott Ambler, "Lean/Agile Documentation"* (agilemodeling.com; fetched 2026-06-28):
"Document stable things, not speculative things"; "Documentation should be just barely good
enough"; "Comprehensive documentation does not ensure success, in fact, it increases your
chance of failure."

**P5 — YAGNI: don't build presumptive capability now.**
*Martin Fowler, "Yagni"* (2015; fetched 2026-06-28): "some capability we presume our software
needs in the future should not be built now." A guard against speculative scope.

**P6 — Contract-first / API-first: agree the contract before code; enables parallel work, mocking, early problem-solving.**
*Swagger, "Understanding the API-First Approach"* (fetched 2026-06-28): "establish a contract
for how the API is supposed to behave… additional planning and collaboration with the
stakeholders… before any code is written"; "most problems to be solved before any code is even
written."

**P7 — Decisions are recorded with context + rationale + rejected alternatives; immutable, superseded not edited; only "architecturally significant" ones.**
*Michael Nygard, "Documenting Architecture Decisions"* (2011; fetched 2026-06-28): an ADR is
"a short text file… Each record describes a set of forces and a single decision"; "If a
decision is reversed, we will keep the old one around, but mark [it superseded]."
*Joel Parker Henderson ADR repo README* (fetched 2026-06-28): "Immutable: Don't alter existing
information in an ADR. Instead… supersede the ADR by creating a new ADR"; "Specific: Each ADR
should be about one AD."

**P8 — Phased, human-checkpointed flow; the human verifies each AI-generated artifact before advancing.**
*GitHub Blog (2025; fetched 2026-06-28):* Specify → Plan → Tasks → Implement, "you don't move
to the next one until the current task is fully validated… The AI generates the artifacts; you
ensure they're right."

**P9 — The spec is the MAINTAINED artifact and wins on change: update the spec, then regenerate; immutable governing principles ("constitution").**
*GitHub Blog (2025; fetched 2026-06-28):* "just update the spec, regenerate the plan, and let
the coding agent handle the rest."
*Thoughtworks Technology Radar, "Spec-driven development"* (Assess; 2025, fetched 2026-06-28):
spec-kit adds "a 'constitution' defining immutable principles that must always be followed";
Tessl "takes a more radical approach in which the specification itself becomes the maintained
artifact, rather than the code."

**P10 — Greenfield specifically benefits from a small amount of upfront spec/plan so the AI builds your intent, not a generic solution.**
*GitHub Blog (2025; fetched 2026-06-28):* "Greenfield (zero-to-one)… a small amount of upfront
work to create a spec and a plan ensures the AI builds what you actually intend, not just a
generic solution based on common patterns."

### Anti-patterns / failure modes the web warns about

**A1 — BDUF / waterfall: minutely-specified systems end up being the WRONG systems specified in detail.**
*Preston-Werner (2010):* "Huge systems specified in minute detail end up being the WRONG
systems specified in minute detail." *Fowler, "Is Design Dead?"* (2004; fetched 2026-06-28):
argues for evolutionary over big up-front design, "simple design," refactoring, and
**reversibility**.

**A2 — Docs drift and lose trust: the #1 failure of doc-as-truth.**
*Ambler (fetched 2026-06-28):* "Developers rarely trust the documentation, particularly
detailed documentation because it's usually out of sync with the code."

**A3 — Over-specification doesn't scale: long specs are hard to review; hand-crafting detailed AI rules may be a "bitter lesson."**
*Thoughtworks Radar (2025; fetched 2026-06-28):* "some generate lengthy spec files that are
hard to review… We may be relearning a bitter lesson — that handcrafting detailed rules for AI
ultimately doesn't scale."

**A4 — Speculative documentation (documenting unstable things) is waste.** *Ambler (fetched
2026-06-28):* "Document stable things, not speculative things."

---

## (c) Alignment / Divergence / Gap assessment

### Alignment — where AID follows the consensus

| # | Best practice (web) | AID realization (built) | Verdict |
|---|---------------------|--------------------------|---------|
| 1 | **P3** ubiquitous-language up front, rigorous, project-specific | DESCRIBE-SEED makes `domain-glossary.md` (C4) the **MANDATORY vocabulary keystone**, elicited **before** architecture (`state-describe-seed.md` Gap inventory + GAP-SELECTION rank 3: "domain-glossary.md (C4 concept-spine) first… the vocabulary keystone; elicit it before architecture"). Stop predicate requires each term "defined as this project uses it (not a generic definition)… The work is explainable using only defined native terms" (C4 closure bar). | **CONFIRMED strong** — DDD-faithful, and **enforced** by a stop predicate + `closure-check.sh`, not just aspirational. |
| 2 | **P1/P2** intent/doc is the source of truth, written first | Seed is **forward-authored from intent before any code**, stamped `source: forward-authored`, `sources: []` ("correct for a pure-intent doc — no code exists yet"); downstream `aid-specify/plan/execute` read the seed unchanged (`state-describe-seed.md` Record Sink + Advance). | **CONFIRMED** — directly matches spec-kit "intent is the source of truth." |
| 3 | **P9** spec is the maintained artifact and wins on change; flag, don't silently reconcile | KB-DELTA **Conformance Lane** inverts the normal doc←code direction: "`source: forward-authored` → Conformance Lane (code→design, flag-not-overwrite)… The design doc is never auto-overwritten" (`state-kb-delta.md` Conformance Lane table + CL-Step 2 "Invariant — flag, never overwrite"). | **CONFIRMED** — matches spec-kit "update the spec" and Tessl "spec is the maintained artifact rather than the code." See Divergence #1 (AID goes further). |
| 4 | **P4/P5/A1/A4** just-enough, minimal, exclude speculative/as-built | Stop predicate halts at "minimal-but-sufficient"; **explicit RQ-A2 exclusion table** bars as-built docs (`module-map.md`, `test-landscape.md`, `infrastructure.md`, `project-structure.md`, `feature-inventory.md`) with reason "No X exists yet"; architecture held to **"sketch altitude — not an as-built layout"**; NFR-4 "the seed carries intent, not inventory… minimal, not bloated" (`state-describe-seed.md` Step 3 Exclusions). Domain extensions only via a propose→confirm gate "ONLY when the domain warrants it." | **CONFIRMED strong** — a deliberate anti-BDUF design; excludes exactly the "speculative" docs Ambler warns against. |
| 5 | **P7** decisions = what + why + rejected alternative; conditional/significant-only | `decisions.md` is **CONDITIONAL** (added "only when rationale-bearing choices are confirmed"); fit criterion: "each decision states what was decided + why + the rejected alternative" (`state-describe-seed.md` Gap inventory row 5 + Stop predicate 5). | **CONFIRMED** — matches Nygard ADR (context + decision + consequence) and "architecturally significant only." See Gap #1 for the immutability shortfall. |
| 6 | **P8** phased, human-gated, human verifies each artifact | Flow: engine loop → **whole-picture read-back** ("Does this accurately reflect your intent?") → **coherence check [HUMAN GATE]** ("Work MUST NOT proceed… while any conflict remains open") → greenfield-mode **review gate** at minimum grade with essence/assertiveness PASS (`state-describe-seed.md` Steps 2/4/5; `coherence-check.md` Invariant 4). | **CONFIRMED** — matches spec-kit "you don't move to the next one until… validated; the AI generates the artifacts, you ensure they're right." |
| 7 | **P10** greenfield: small upfront spec so AI builds intent, not a generic solution | Whole feature exists precisely for greenfield zero-to-one (entry condition: "Greenfield: no brownfield KB on disk"); seed gives downstream AI phases the intended vocabulary/architecture/stack so they "act without KB-gap loopbacks" (`state-describe-seed.md` Entry Conditions + Step 3 extension rationale). | **CONFIRMED** — same greenfield rationale spec-kit states. |

A reinforcement with **no direct web analog** but supporting P1: the **layered coherence check**
(`coherence-check.md`) verifies the seed actually covers REQUIREMENTS — Layer A concrete-example
probe + Layer B structural cross-check producing **zero Requirement orphans** as a necessary
sufficiency condition. This is a quality guard that spec-first literature *assumes* but rarely
operationalizes.

### Divergences — better / neutral / worse

**D1 — BETTER: human-adjudicated reconciliation instead of a dogmatic "the doc always wins."**
The web leaves the directionality question contested — Tessl/spec-kit lean "spec wins"
(P9), while Ambler (A2) warns docs drift and lose trust precisely *because* reality outruns
them. AID resolves this maturely: the Conformance Lane keeps design as the **default** authority
but presents every divergence to the human with a **per-item choice** — `[1] Evolve the design`
/ `[2] Fix the code` / `[3] Accept/defer` — and "NEVER writes `.aid/knowledge/*.md`" without an
explicit human choice (`state-kb-delta.md` CL-Step 2a/2c). So AID neither blindly lets the doc
win nor lets code silently rewrite the design. This is a stronger answer to "does the doc win or
the code?" than either pole the web offers.

**D2 — BETTER: AID actively *detects and de-noises* drift; the web mostly only laments it.**
Ambler's central complaint (A2) is drift and lost trust. AID operationalizes detection:
`kb-freshness-check.sh` short-circuits forward-authored docs to a `current` verdict, then the
Conformance Lane runs a **shadow extraction** of as-built code and a **concern-keyed structured
diff** classifying each delta as `design-ahead` / `placeholder-resolved` / `code-ahead` /
`contradiction`, **dropping `design-ahead`** ("Forward-authoring leads; unbuilt items are the
normal and expected state… NOT a finding") and applying a tunable **seed-altitude filter** to
suppress sub-altitude false positives (`state-kb-delta.md` CL-Step 1 Sub-steps 3–4). Dropping
`design-ahead` is exactly the right reading of P5/YAGNI — unbuilt design is expected in
forward-authoring, not drift. This is more rigorous than the radar-surveyed tools.

**D3 — NEUTRAL→watch: the gate stack is heavier than spec-kit's lightweight checkpoints.**
A completed seed must clear the **full review panel** (M1–M4) at the configured minimum grade
(this repo: A+) with essence PASS and assertiveness PASS, plus two coherence layers, plus a
whole-picture read-back (`state-describe-seed.md` Step 5; NFR-3 "FULL panel"). For the
AI-skeptic audience this rigor is a feature. But it sits in tension with Thoughtworks' A3
warning ("lengthy spec files that are hard to review… detailed rules… don't scale"). Mitigated
because the **mandatory core is only 2 docs** (glossary + architecture); conventions, stack, and
decisions are DEFERRABLE/CONDITIONAL — so the floor stays small. Net: defensible, but the
machinery-to-payload ratio is high for "minimal" greenfield and worth calibration vigilance.

**D4 — NEUTRAL: forward-authoring inversion vs. the BDUF caution.** AID's design-authoritative
stance could *look* like the BDUF trap Fowler/Preston-Werner reject (A1). It largely escapes it
via P4-aligned guardrails — sketch-altitude only, the RQ-A2 exclusion table, minimal-but-
sufficient stop, domain-adaptive (no fixed heavy template). The residual risk is elicitation
**over-probing** a long glossary/architecture before code exists. The stop predicate +
exclusions are the brake; whether they hold is a calibration question, not a design flaw.

### Gaps — what the web values that AID's seed does not (yet) do

**G1 — No ADR-style immutability / supersession history for `decisions.md`.** P7 (Nygard / JPH)
is emphatic: decision records are **immutable — superseded by a new record, not edited**, to
preserve "why we did it that way" for future readers. AID's `decisions.md` captures *what + why +
rejected alternative* (good), but it is a forward-authored doc that is **edited in place** via
the `[1] Evolve the design` path; there is no superseded-decision chain or temporal record. A
future reader sees the current decision, not the reversed one and its rationale. Minor but real
against decision-record best practice.

**G2 — The seed is read by downstream phases but is not itself an *executable*/test-linked
contract.** The leading edge of P1/P9 (spec-kit "specifications become executable"; Tessl)
emphasizes the spec generating/validating code and tests. AID's coherence check binds seed↔
REQUIREMENTS, but nothing binds the seed↔acceptance-tests at seed time (acceptance lives later
in REQUIREMENTS/specify). Arguably correct separation of concerns, but the spec→test
traceability the AI-era trend prizes is absent from the seed step.

**G3 — No explicit conciseness/length budget on seed docs.** Against A3 (radar: long specs are
hard to review) and Ambler ("concise: overviews/roadmaps generally preferred over detailed
documentation"), AID states "minimal-but-sufficient" and excludes whole doc types, but applies
**no length cap or conciseness budget** to the docs it *does* author. The whole-picture
read-back helps, but a reviewer facing an over-grown glossary has no explicit altitude ceiling on
prose length (only on *which* docs and *which* terms). A soft length budget would harden the
anti-A3 posture.

**G4 — Seed evolution is human-gated/heavier vs. Evans' "the language should evolve."** P3
explicitly says the ubiquitous language "should evolve as the team's understanding grows," and
Fowler prizes **reversibility** (A1). AID *does* provide an evolution path (`[1] Evolve the
design` → `/aid-discover` targeted re-entry), but it routes through a full REVIEW→APPROVAL cycle.
That is appropriate for a design contract, yet slightly heavier than the cheap, continuous
language evolution DDD assumes. Not wrong — a deliberate authority/rigor trade — but worth naming.

---

## (d) Net verdict

**AID's greenfield seed authoring is strongly aligned with current web best practice for
design-first / spec-first / intent-first greenfield work — and on two points it is ahead of the
field.**

- **Strongest alignment:** the **concept-spine / ubiquitous-language-first keystone** (DDD — P3)
  combined with **minimal-but-sufficient, anti-BDUF exclusions** (P4/P5/A1/A4). AID elicits the
  project vocabulary *before* architecture, enforces it with a closure bar, and structurally
  excludes the speculative as-built docs the agile-documentation literature warns against. This is
  textbook design-first done in the *just-enough* spirit, not the BDUF spirit.

- **Ahead of the field (two ways):** (1) It implements the AI-era "intent is the source of
  truth" inversion (spec-kit / Tessl — P1/P9) but answers the **contested directionality
  question more maturely** than either pole: design is the *default* authority, yet every code↔
  design divergence is **human-adjudicated per item** (Evolve / Fix / Accept) and never silently
  reconciled in either direction (D1). (2) It **actively detects and de-noises drift** — the
  failure mode (A2) the literature mostly only laments — via the freshness check + shadow-extract
  conformance diff + `design-ahead` drop + altitude filter (D2).

- **Most important divergence / gap to watch:** the **machinery-to-payload tension** (D3) — a
  full A+ review panel + two coherence layers + read-back is heavy relative to a "minimal"
  greenfield seed, brushing against Thoughtworks' "lengthy specs / detailed rules don't scale"
  warning (A3); it is bounded by the 2-doc mandatory core but deserves calibration vigilance, and
  is unsupported by any explicit conciseness budget (G3). The cleanest concrete gap is **G1** —
  `decisions.md` lacks the ADR immutability/supersession history that decision-record best
  practice (Nygard / JPH) treats as essential.

**Bottom line:** Not a rubber stamp and not manufactured problems — AID's built greenfield seed
authoring genuinely embodies the modern design-first consensus and improves on the AI-era spec
tools in drift handling and reconciliation directionality. The honest weak spots are
over-machinery risk for a "minimal" artifact (D3/G3) and the absence of ADR-style decision
immutability (G1); G2 (executable/test-linked spec) and G4 (cheaper language evolution) are
trend-aligned nice-to-haves rather than defects.

---

## (e) Sources (every URL + access date)

All fetched via `curl` on **2026-06-28**, HTTP 200, content read.

1. GitHub Blog — *Spec-driven development with AI: Get started with a new open source toolkit* (2025).
   `https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/`
2. GitHub — *Spec Kit* README (github/spec-kit, main).
   `https://raw.githubusercontent.com/github/spec-kit/main/README.md`
3. Thoughtworks Technology Radar — *Spec-driven development* (Assess; 2025).
   `https://www.thoughtworks.com/radar/techniques/spec-driven-development`
4. Tom Preston-Werner — *Readme Driven Development* (2010-08-23).
   `https://tom.preston-werner.com/2010/08/23/readme-driven-development.html`
5. Martin Fowler — *Is Design Dead?* (XP 2000 / May 2004).
   `https://martinfowler.com/articles/designDead.html`
6. Martin Fowler — *Ubiquitous Language* (2006-10-31).
   `https://martinfowler.com/bliki/UbiquitousLanguage.html`
7. Martin Fowler — *Yagni* (2015-05-26).
   `https://martinfowler.com/bliki/Yagni.html`
8. Michael Nygard — *Documenting Architecture Decisions* (2011-11-15).
   `https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions`
9. Joel Parker Henderson — *Architecture Decision Record (ADR)* repo README.
   `https://raw.githubusercontent.com/joelparkerhenderson/architecture-decision-record/main/README.md`
10. Scott Ambler — *Lean/Agile Documentation: Strategies for Agile Teams* (agilemodeling.com).
    `https://agilemodeling.com/essays/agileDocumentation.htm`
11. Swagger (SmartBear) — *Understanding the API-First Approach to Building Products*.
    `https://swagger.io/resources/articles/adopting-an-api-first-approach/`

*Non-productive attempts (recorded for transparency):* DuckDuckGo HTML & lite search endpoints
(`html.duckduckgo.com`, `lite.duckduckgo.com`) returned bot-challenge/anomaly captcha pages and
were not usable for result scraping; Bing search HTML returned no parseable result block;
`adr.github.io` returned a JS-rendered shell with no server-side text (substituted with sources
8 and 9 for ADR grounding).
