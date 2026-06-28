# `grill-me` Comparative (task-002 research note)

> **What this is.** A standalone research note comparing the web-trending `grill-me`
> question-driven elicitation pattern (and its near variants) against AID's
> seasoned-analyst elicitation, for **general** requirements gathering (not only
> greenfield). It is an INPUT consumed by task-003 (which assembles `findings.md`
> section 3). Per **C-6**, `grill-me` is treated as **inspiration-only**: no prompt
> or code is copied here; its license and source URLs are captured below. Every
> claim is sourced (see [Sources](#sources)). Access date for all web sources:
> **2026-06-27**.

## Contents

- [1. What it is and how it works](#1-what-it-is-and-how-it-works)
- [2. Strengths and weaknesses](#2-strengths-and-weaknesses)
- [3. Head-to-head vs AID's seasoned-analyst elicitation](#3-head-to-head-vs-aids-seasoned-analyst-elicitation)
- [4. Adopt-vs-avoid list](#4-adopt-vs-avoid-list)
- [5. License and attribution](#5-license-and-attribution)
- [A-1 fallback disclosure](#a-1-fallback-disclosure)
- [Sources](#sources)

---

## 1. What it is and how it works

`grill-me` is an agent **skill** (a reusable prompt + behavior contract for a coding
agent) authored by **Matt Pocock** and published in his public `mattpocock/skills`
GitHub repository. It went viral in the AI-coding community in 2026 and has been
mirrored, re-described, and turned into a named "design pattern" by several
third-party sites. [S1][S2][S3][S6][S8]

**The core move.** `grill-me` **inverts** the normal developer-to-agent flow. Instead
of the human writing a plan and the agent executing it, the human states a rough plan
or topic and the **agent interrogates the human** with question after question until
the two reach a shared understanding, then the agent emits a summary/session log of
what was settled. [S2][S4][S8] The author frames it as a modern, agent-driven form of
**"rubber ducking"** (thinking a problem through out loud). [S2]

**The actual instruction is tiny** -- roughly three sentences. As reported by an
independent walkthrough, the directive is essentially: *ask questions about every
aspect of this plan until we reach shared understanding; follow every branch of the
design tree and resolve dependencies between decisions one by one; for each question
include your recommended answer; ask one question at a time; if a question can be
answered by inspecting the codebase, inspect the codebase.* [S8] (Quoted here only to
describe the technique's contract -- not copied into AID; see C-6.)

**Operating constraints** (the three load-bearing rules, consistently reported across
sources): [S1][S4][S8]

1. **One question at a time** -- prevents the session collapsing into a questionnaire
   the human answers superficially.
2. **A recommended answer per question** -- the agent proposes a default so the human
   can confirm or correct quickly, reducing "interrogation fatigue."
3. **Codebase-first resolution** -- if the answer already exists in the code, the agent
   reads it instead of asking, keeping questions focused on genuine unknowns.

**What it probes.** The underlying problem, success criteria, edge cases and failure
modes, dependencies and constraints, risks and trade-offs, and prioritization / MVP
scope. [S1] In practice an agent asks roughly **10-50 questions** for a typical topic.
[S8]

**Output.** Not a raw transcript but a distilled **session log**: Intent, Constraints,
Key decisions, Surfaced assumptions, Open questions, and Out-of-scope. [S1] An evolved
variant, **`/grill-with-docs`**, validates the emerging plan against existing project
documentation and updates artifacts such as `CONTEXT.md` and Architecture Decision
Records (ADRs) as each decision is finalized. [S2][S8]

**Where it shows up.** The canonical implementation is `mattpocock/skills` (installable
via `npx skills add mattpocock/skills --skill grill-me`). [S6] It has been re-listed and
re-described by skill directories and third-party mirrors (e.g. `eliteai.tools`,
`aiuxplayground.com`, `explainx.ai`, and the `satya-janghu/agent-skills` mirror), and
abstracted into a named pattern, **"Grill Me / Developer-Initiated Plan Interrogation,"**
by `agentpatterns.ai`. [S1][S3][S4][S5] The same idea -- a structured pre-implementation
**interview** skill -- is being requested and reinvented elsewhere in the ecosystem
(e.g. a "Deep Interview skill" feature request on the `oh-my-codex` project), confirming
this is a small *family* of question-driven elicitation skills, not a single tool. [S7]

### Similar variants (the family)

`agentpatterns.ai` situates `grill-me` against two reactive cousins, which is useful for
AID because AID's analyst blends all three: [S4]

| Pattern | Who triggers it | Scope | Purpose |
|---------|-----------------|-------|---------|
| **Grill Me** | Developer-initiated | Exhaustive | Walk the entire decision tree up front |
| **Agent Pushback Protocol** | Agent-detected | Targeted | Surface a specific concern when noticed |
| **Interactive Clarification** | Agent-detected | Gap-specific | Resolve the minimal missing information |

`grill-me` is the *proactive, exhaustive* member; the other two are *reactive, narrow*.

---

## 2. Strengths and weaknesses

**Strengths** (sourced): [S1][S2][S4][S8]

- **Surfaces hidden assumptions before implementation.** Exhaustively walking the
  decision tree forces edge cases, failure modes, and dependencies into the open while
  they are still cheap to change.
- **Keeps the human in control via Q&A dynamics.** It is a two-way dialogue, not a
  one-way design dump; the human confirms or overrides every step. [S8]
- **Low instruction overhead.** The whole technique is ~3 sentences, so it is trivially
  portable across agents and projects. [S4]
- **Produces a durable artifact.** The session log / spec persists context across
  stateless agent sessions, which is what makes the up-front cost pay off later. [S4]
- **Domain-agnostic.** The author notes it works for non-coding ideas too, from fully
  formed to vague. [S2]
- **Recommended-answers cut fatigue.** Proposing a default per question keeps a long
  session moving. [S1][S8]

**Weaknesses** (sourced): [S4][S8]

- **Time cost and mental load.** It is explicitly "much more time and more mentally
  demanding for the human" than just letting the agent plan. [S8]
- **Passive-user failure mode.** If the human rubber-stamps the recommended answers
  without engaging, the value collapses; one reported extreme saw **540+ questions** and
  drift into low-importance detail when the user stayed passive. [S8] This is the
  technique's signature risk: the recommended-answer convenience can become an
  auto-accept trap.
- **No natural stopping criterion / unbounded breadth.** "Every branch of the design
  tree" has no built-in budget; broad scopes can **exceed the context window**, causing
  information loss or degraded judgment unless the human decomposes the task first. [S8]
- **Weak on high-fidelity questions.** Questions that really need a prototype (e.g.
  exact layout) can't be answered in dialogue; the human must pause, build, and resume.
  [S8]
- **Poor fit when the solution is externally determined.** If requirements are fixed by
  outside constraints, grilling becomes confirmation theater rather than discovery. [S4]
- **Statelessness erases findings if not written down.** Value is lost unless the
  session is captured to a downstream doc -- the gap `/grill-with-docs` exists to close.
  [S4][S2]

---

## 3. Head-to-head vs AID's seasoned-analyst elicitation

AID's target elicitation behavior is defined by REQUIREMENTS.md **NFR-1** (a genuinely
conversational *expert advisor* -- guides, recommends, explains trade-offs, cordially
disagrees, but always defers the call to the human and advances one **confirmed**
decision at a time, with visible state-tracking) and **NFR-7** (**every** question must
carry a concrete suggested answer **plus its rationale** -- never a bare question). The
comparison below holds for **general** requirements gathering, brownfield and greenfield
alike. (AID side: REQUIREMENTS.md NFR-1, NFR-7.)

| Dimension | `grill-me` | AID seasoned-analyst (NFR-1 / NFR-7) |
|-----------|------------|--------------------------------------|
| **Initiative** | Developer-initiated, agent-driven interrogation. [S2] | Analyst-driven but advisory; engages as an expert peer, not just an interrogator. (NFR-1) |
| **One question at a time** | Core rule. [S1][S8] | Same discipline -- advances one *confirmed* decision at a time, tracked visibly. (NFR-1) |
| **Suggested answer per question** | Yes -- a *recommended answer* per question. [S1][S8] | Yes, and **strengthened**: suggested answer **+ explicit rationale** on EVERY question, no exceptions. (NFR-7) |
| **Rationale with the suggestion** | Not a stated requirement; the recommendation can stand bare. [S8] | **Mandatory** -- the *why* is required so the user can knowingly agree or disagree. (NFR-7) |
| **Codebase grounding** | Codebase-first: read code before asking. [S1] | Equivalent and broader: cross-references the **KB + codebase + in-flight work**, not just code. (AID KB-grounded elicitation) |
| **Expert latitude** | Asks and recommends; does not emphasize teaching, pros/cons depth, or disagreeing. | Explicitly **guides / teaches / explains pros-cons / cordially disagrees**, adapting depth to the user's level. (NFR-1) |
| **Handling "I don't know"** | Not addressed; relies on the user supplying or accepting answers. | First-class: must gracefully support "I don't know / what do you recommend / explain like I'm a junior." (NFR-1) |
| **Stopping criterion** | Unbounded ("every branch"); risk of 540+ questions / context blow-out. [S8] | Bounded by **minimal-but-sufficient** -- sufficiency for downstream phases is the bar, not completeness. (NFR-4) |
| **Decision authority** | Human confirms; passive-accept is a known failure. [S8] | Human always decides; "propose-don't-assume" + "defer to the user" are invariants, with visible recording so silent assumption is structurally prevented. (NFR-1, NFR-7) |
| **Persistence of result** | A session log; stateless unless saved (hence `/grill-with-docs`). [S2][S4] | Writes to tracked pipeline artifacts (REQUIREMENTS / SPEC) and a quality-gated KB seed -- persistence is built in, not bolted on. (NFR-3) |
| **Quality gate** | None inherent; quality depends on user engagement. | The seed / output passes the same **>= A KB review gate** before work proceeds. (NFR-3) |

**Net.** `grill-me` and AID's analyst **converge** on the two best ideas -
one-question-at-a-time and a recommended answer per question -- which is strong external
validation that AID's existing NFR-7 instinct is right. They **diverge** on three axes
where AID is deliberately stronger: (1) AID *requires the rationale*, not just the
recommendation; (2) AID is an *expert advisor* (teaches, explains, disagrees), not only
an interrogator; and (3) AID has a *sufficiency-bounded stopping rule and a quality
gate*, where `grill-me`'s open-ended breadth is its main failure mode. Conversely,
`grill-me` is *leaner and more portable* (a 3-sentence contract) and its inverted,
developer-states-then-agent-grills framing is a clean conversational on-ramp AID can
borrow as a stance.

---

## 4. Adopt-vs-avoid list

All "adopt" items are **inspiration-only** (C-6): re-expressed in AID's own state-machine
idiom and NFR vocabulary; no `grill-me` prompt or code is copied.

### Adopt (reimplement in AID's idiom)

| Idea | Why adopt | AID idiom it maps to |
|------|-----------|----------------------|
| **One question at a time** | Prevents superficial questionnaire answers; already an AID instinct -- `grill-me` confirms it. [S1][S8] | Reinforces NFR-1's "one confirmed decision at a time." |
| **A recommended answer accompanies every question** | Cuts interrogation fatigue; keeps long sessions productive. [S1][S8] | Already AID's NFR-7 -- adopt as external validation, keep AID's stricter form. |
| **Codebase-first resolution (don't ask what you can read)** | Eliminates noise; focuses dialogue on genuine unknowns. [S1] | Generalize to **KB-first + codebase-first + in-flight-work-first**: the analyst resolves what existing context already answers before asking. |
| **Inverted on-ramp: user states a rough plan, analyst interrogates it** | A natural, low-friction way to *start* a session from vague intent. [S2] | A conversational entry stance for the elicitation engine (esp. greenfield, where intent precedes any code). |
| **Distilled session log (Intent / Constraints / Decisions / Assumptions / Open Qs / Out-of-scope), not a transcript** | A clean, reusable output shape that survives statelessness. [S1] | Maps onto AID's tracked artifacts (REQUIREMENTS / SPEC / KB seed); reinforces "record every resolved point." |
| **`/grill-with-docs` idea: update docs as decisions finalize** | Closes the statelessness gap; keeps documentation live. [S2][S8] | Aligns with AID's forward-authored, quality-gated KB seed (NFR-3) and human-gated reconciliation (NFR-5). |

### Avoid (consciously reject)

| Idea / property | Why reject | AID's stronger choice |
|-----------------|------------|------------------------|
| **Unbounded "ask about every branch" with no budget** | Causes 540+ question runs, context-window blow-out, drift into trivia. [S8] | AID's **minimal-but-sufficient** stopping rule (NFR-4): stop when downstream phases have enough, not when the tree is exhausted. |
| **Bare recommended answer (no rationale)** | Invites passive rubber-stamping -- the documented failure mode. [S8] | NFR-7: suggested answer **+ rationale** on every question, so agreement is *informed*. |
| **Pure interrogator stance** | Doesn't teach, explain trade-offs, or push back; weak for unsure users. | NFR-1's expert-advisor latitude: guide, explain pros/cons, cordially disagree, adapt depth. |
| **No quality gate / quality hinges on user engagement** | Output quality is unmanaged; nothing catches a thin result. | NFR-3's >= A review/calibration gate on the seed/output. |
| **Copying the prompt or skill code verbatim** | C-6 (inspiration-only) and the MIT attribution obligation; AID must own its idiom. | Re-author every adopted idea in AID's state-machine prose; cite, don't copy. |

---

## 5. License and attribution

- **Implementation:** `grill-me` skill, by **Matt Pocock**, in the
  `mattpocock/skills` GitHub repository.
- **License:** **MIT** (repository-level `LICENSE`, SPDX `MIT`), confirmed via the
  GitHub API for `mattpocock/skills`. [S6][S9] MIT permits reuse with attribution; AID
  nonetheless treats it as **inspiration-only** per C-6 (no prompt/code copied into this
  note or into AID), so the obligation here is to **credit the source**, captured in
  [Sources](#sources).
- **Third-party descriptions** used for analysis (aihero.dev, azukiazusa.dev,
  agentpatterns.ai, eliteai.tools, etc.) are cited as secondary sources; their site
  content is referenced, not reproduced.

---

## A-1 fallback disclosure

**A-1 fallback status: did NOT fire (sources were sufficient).** The task's A-1 rule
says: if solid public material on `grill-me` is thin, lean on the established
RE/elicitation literature and mark the gap. In this case public material was **adequate**
for a head-to-head:

- **What was searched.** Web searches for the `grill-me` skill, its prompt/contract,
  spec-driven-development framing, and requirements-gathering variants; the canonical
  repo's license via the GitHub API; and direct fetches of the author's announcement, a
  detailed independent walkthrough, and a pattern-catalog write-up.
- **What was found (good coverage).** The canonical authorship and repo (Matt Pocock,
  `mattpocock/skills`, MIT) [S6][S9]; the technique's three operating rules and the
  ~3-sentence contract [S1][S4][S8]; the author's "rubber-ducking" framing [S2]; the
  `/grill-with-docs` evolution [S2][S8]; concrete strengths, weaknesses, and the
  passive-user / unbounded-breadth failure modes with a real 540+-question example [S8];
  and a pattern-catalog comparison to two reactive cousins [S4].
- **What was NOT found (the visible gap).** There is **no peer-reviewed or empirical
  study** of `grill-me` specifically -- all sources are practitioner blogs, skill
  directories, and one pattern catalog, i.e. **secondary/anecdotal** evidence, not
  controlled measurement. Failure-mode claims (e.g. the 540+-question run) are single
  anecdotes, not data. Quantitative effectiveness (does it actually reduce defects or
  rework?) is **unverified**. The canonical repo's per-skill README could not be fetched
  directly (the `tree/main/grill-me` URL returned 404 at access time); the technique's
  contract is therefore characterized from the author's announcement and an independent
  walkthrough quoting it, not from the raw skill file.
- **How the gap is handled.** Because the comparative is a *design-inspiration* exercise
  (C-6), anecdotal practitioner evidence is fit-for-purpose: the head-to-head and
  adopt/avoid calls turn on the technique's **described mechanics**, which are
  consistently reported across independent sources, not on contested effectiveness
  numbers. Where a claim is anecdotal (failure modes), it is labeled as such above.
  Downstream features should treat the adopt/avoid verdicts as **grounded
  recommendations**, not measured guarantees.

---

## Sources

All web sources accessed **2026-06-27**.

- **[S1]** "grill-me - AI Agent skill," eliteai.tools.
  <https://eliteai.tools/agent-skills/grill-me-2>
- **[S2]** Matt Pocock, "My 'Grill Me' Skill Has Gone Viral," aihero.dev.
  <https://www.aihero.dev/my-grill-me-skill-has-gone-viral>
- **[S3]** "Grill Me - Career Agent Skill," AI UX Playground.
  <https://aiuxplayground.com/skills/grill-me/>
- **[S4]** "Grill Me: Developer-Initiated Plan Interrogation," AgentPatterns.ai.
  <https://www.agentpatterns.ai/agent-design/grill-me-technique/>
- **[S5]** "grill-me - skills" (mattpocock mirror), explainx.ai.
  <https://explainx.ai/skills/mattpocock/skills/grill-me>
- **[S6]** `mattpocock/skills` (canonical repository; install source). GitHub.
  <https://github.com/mattpocock/skills>
- **[S7]** "[Feature] Deep Interview skill -- standalone structured requirements
  gathering," Issue #484, `Yeachan-Heo/oh-my-codex`. GitHub.
  <https://github.com/Yeachan-Heo/oh-my-codex/issues/484>
- **[S8]** "The /grill-me Skill for Thoroughly Interviewing a Design and Clarifying
  Requirements Before Implementation," azukiazusa.dev.
  <https://azukiazusa.dev/en/blog/before-implementation-interview-design-requirements-grill-me/>
- **[S9]** License confirmation: GitHub API `repos/mattpocock/skills` -> `license.spdx_id
  = MIT` (LICENSE: <https://github.com/mattpocock/skills/blob/main/LICENSE>). Accessed
  2026-06-27 via `gh api`.

**AID-internal references** (not web sources): REQUIREMENTS.md NFR-1 (conversational
expert advisor), NFR-3 (seed quality-gated), NFR-4 (minimal-but-sufficient), NFR-5
(human-gated reconciliation), NFR-7 (suggested-answer-plus-rationale on every question);
feature-001 SPEC.md "Comparative - `grill-me` and variants," constraint C-6
(inspiration-only), fallback A-1.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-27 | task-002 (RESEARCH) | Initial `grill-me` comparative note; A-1 fallback assessed (did not fire). |
