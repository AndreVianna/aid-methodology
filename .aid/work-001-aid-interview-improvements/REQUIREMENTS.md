# Requirements

- **Name:** AID-Interview Improvements
- **Description:** Evolve the aid-interview skill into a seasoned-analyst elicitation that supports greenfield projects (forward-authoring a minimal KB seed) and guides full-vs-lite triage, with a rename and infra-debt side-tasks riding along.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Initial interview started | /aid-interview |
| 2026-06-27 | §1 Objective captured (greenfield + triage primary; rename + debt minor) | /aid-interview |
| 2026-06-27 | §2 Problem Statement — common thread: skill as "seasoned system analyst" that elicits, not transcribes | /aid-interview |
| 2026-06-27 | §3 Users — assume nothing; analyst calibrates by asking the user's knowledge level/type | /aid-interview |
| 2026-06-27 | §4 Scope — both interview-time coherence AND build-time conformance lifecycle in scope | /aid-interview |
| 2026-06-27 | §5 FR-1 — greenfield seed elicitation grounded in a RESEARCH spike (deliverable 1) on elicitation/domain-discovery techniques | /aid-interview |
| 2026-06-27 | §5 FR-2..FR-7 — shared seasoned-analyst elicitation (FR-1/2/5); triage analyst-driven + KB-context-aware (full or seed KB); coherence + conformance; rename; debt | /aid-interview |
| 2026-06-27 | §5 FR-1 spike — added comparative research of "grill-me" + variants (question-driven elicitation), general requirements gathering not only greenfield | /aid-interview |
| 2026-06-27 | §6 NFR-1 — conversational expert advisor (guides/recommends/explains/disagrees), latitude in dialogue + discipline in process; NFR-2..6 | /aid-interview |
| 2026-06-27 | §6 NFR-7 — every question MUST carry a suggested answer + rationale (reinforced from current skill) | /aid-interview |
| 2026-06-27 | §7 Constraints C-1..C-6 (KB contract, extend-not-fork, authoring rules, human gates, work-001 foundations, grill-me inspiration-only) | /aid-interview |
| 2026-06-27 | §8 Assumptions & Dependencies (D-1..D-4, A-1..A-3 incl. grill-me-research fallback) | /aid-interview |
| 2026-06-27 | §9 Acceptance Criteria AC-1..AC-10 (mapped to FR/NFR; AC-2/AC-4 measurable bars) | /aid-interview |
| 2026-06-27 | §10 Priority — overall High; MoSCoW P0 spike → P1 greenfield+triage → P2 conformance → P3 rename → P4 debt | /aid-interview |
| 2026-06-27 | Interview complete — approved | /aid-interview |
| 2026-06-27 | 7 features decomposed; §10 dependency note — F1 gates 002–005, F6/F7 independent (F7 wholly orthogonal) | /aid-interview |
| 2026-06-27 | Cross-reference (grade C) resolved: F6 sequenced after content (not parallel); FR-4 owns a new conformance check (not f007); C-1 allows the forward-authored marker; +D-5; FR-6 wording | /aid-interview |

## 1. Objective

Evolve the `aid-interview` skill to better serve two **primary drivers**, with two **minor**
follow-on changes riding along.

**Primary drivers**

1. **Greenfield support** — when a project has no code yet, `aid-interview` forward-authors a
   minimal Knowledge-Base seed from the stakeholder's intent. In greenfield the authored design
   docs ARE the source of truth and code is built to conform to them (the inverse of the
   brownfield extraction model that `aid-discover` uses).
2. **Better full-vs-lite triage** — a more reliable mechanism to route a work to the full vs
   lite/short path than today's free-form-description inference.

**Minor extra tasks** (lower priority; ride along)

3. **Rename** `aid-interview` to a clearer name for the "define the work" act (current lean:
   `/aid-define`).
4. **Infra tech-debt side-tasks** — H1, M3, M4, M1 from `tech-debt.md`, paid down opportunistically.

Source seed: `.aid/design/aid-interview-improvements.md`.

## 2. Problem Statement

1. **Greenfield is unsupported — and needs intelligent elicitation.** `aid-discover` *extracts*
   a KB from existing code; a from-scratch project has no code, so there is no KB — yet
   `aid-specify` / `aid-plan` / `aid-execute` all read it. The skill must instead **elicit** the
   KB from the user: guide the stakeholder to provide enough information to generate a
   **minimal-but-sufficient KB** to execute the work. Crucially, the skill must be **clever** —
   actively helping the user surface the right information the way a **seasoned system analyst**
   would (asking the right follow-ups, filling gaps, proposing structure), not passively
   transcribing what the user happens to volunteer.

2. **Triage is unclear to the user.** The problem is *not* that the routing algorithm is
   unreliable — it is that the triage does not **help the user explain their work** in a way that
   lets the skill choose the right **path** (full vs lite) *and* the right **recipe**. The user is
   left to self-describe with no guidance, so the description is often insufficient for correct
   routing.

3. *(minor)* The name `aid-interview` names the *method* (interviewing), not the *outcome*
   (defining the work).

4. *(minor)* Accumulated infra debt (H1 / M3 / M4 / M1 from `tech-debt.md`) is unpaid.

**Common thread (the heart of the work):** problems 1 and 2 are the same problem — the skill
should behave like a **seasoned system analyst** that *intelligently draws out* the information it
needs (for a KB seed, or for path/recipe routing), guiding and gap-filling, rather than passively
recording free-form input.

## 3. Users & Stakeholders

**Primary user — the work-definer (human).** The person running the skill to define a new work.
Their expertise is **unknown and variable** — the skill **assumes nothing** about it. Instead the
"seasoned analyst" **calibrates**: early on it asks the user about their **level and type of
knowledge** (e.g. familiarity with the problem domain, with software / requirements practice, and
with AID itself) and then **shapes its subsequent questions** to match — lighter confirmation for an
expert, heavier drawing-out for a novice. (Aligns with the project's standing "no assumptions —
defer to the user" principle.)

**Downstream consumers (AI agents).** `aid-specify` / `aid-plan` / `aid-execute` consume the
REQUIREMENTS *and* the new forward-authored KB seed; the seed must be sufficient for them to act.

**Other stakeholders.** AID maintainers (own the skill + methodology); AID adopters (benefit from
greenfield support + clearer, guided triage).

## 4. Scope

### In Scope

- **Greenfield KB-seed elicitation.** When a project has no code, the skill guides the user to
  forward-author a **minimal-but-sufficient** KB seed (and decides *what* the seed produces —
  which docs/concerns). The seed is the source of truth (design→code authority).
- **Interview-time coherence.** The analyst ensures the forward-authored KB seed and the gathered
  requirements are **mutually coherent** — they describe the same work and make sense together —
  before the work proceeds.
- **Build-time conformance lifecycle.** As code is later written (by `aid-execute`), keep the code
  **conforming to the seed**: detect divergence and **reconcile it deliberately** (human-gated),
  authority staying design→code until reconciled. Touches the freshness mechanism (f007) /
  `aid-housekeep` — a greenfield-origin doc's divergence is **flagged for human reconciliation,
  not auto-overwritten** with as-built.
- **User-level calibration.** Assume nothing about the user's expertise; the analyst asks the
  user's knowledge level/type early and shapes its questioning accordingly.
- **Guided triage.** Help the user describe the work clearly enough for the skill to choose the
  right **path** (full vs lite) and **recipe**.
- **Rename** `aid-interview` → a clearer name (lean: `/aid-define`). *(minor)*
- **Debt side-tasks** H1 / M3 / M4 / M1 from `tech-debt.md`. *(minor)*

### Out of Scope

- **Rewriting `aid-discover`'s brownfield extraction** — it stays as-is; greenfield is the
  interview-side counterpart. The two coexist (brownfield extracts a KB from code; greenfield
  elicits a seed from intent).
- Net-new downstream-skill capabilities beyond what the build-time conformance lifecycle requires
  — `aid-specify` / `aid-plan` read the seed via the existing KB contract unchanged.

## 5. Functional Requirements

### FR-1 — Greenfield KB-seed elicitation, grounded in proven analyst techniques

The skill forward-authors a **minimal-but-sufficient** KB seed by **eliciting** it from the user as
a seasoned analyst would. The elicitation approach and the exact seed content are **not guessed** —
they are grounded in established **Requirements Elicitation** and **Domain Discovery** techniques,
determined by an early **RESEARCH spike** (the work's first deliverable).

- **Spike scope (deliverable 1):** survey proven analyst techniques — candidates to investigate:
  Domain-Driven Design / ubiquitous language, Event Storming, User-Story Mapping, the
  Volere / requirements-engineering process, context & domain modeling, JAD-style facilitation,
  "five whys" / laddering — and map them to **(a)** *what the minimal KB seed should contain* and
  **(b)** *how the analyst should drive the conversation* to extract it.
- **Comparative analysis — existing question-driven elicitation skills:** research **"grill-me"**
  and similar variants (a web-trending approach to gathering requirements through questioning,
  similar in principle to ours). Assess its **strengths + weaknesses** and **compare with our
  seasoned-analyst elicitation** — for **general requirements gathering, not only greenfield** —
  and distill what to **adopt vs avoid**.
- **Candidate seed content (to validate/revise via the spike):** declared **concept-spine /
  ubiquitous language** (keystone) + **intended architecture** + **conventions & standards** +
  **technology stack** — explicitly *not* the full `aid-discover` doc-set (no module-map /
  test-landscape, since there is no code yet).
- **Domain-adaptive:** like `aid-discover`'s domain-driven doc-set, the seed's exact shape adapts to
  the project's domain rather than being a fixed list.
- **Sufficiency bar:** the seed contains the *minimum* needed for `aid-specify` / `aid-plan` /
  `aid-execute` to act — no more.
- **Spike reach:** its findings also ground the elicitation behavior in FR-2 (calibration) and FR-5
  (guided triage) — both are "help the user articulate" problems.

### FR-2 — Adaptive elicitation (calibration)

Assume nothing about the user; the analyst asks the user's knowledge level/type early and shapes
question depth + style accordingly. *(grounded by the FR-1 spike)*

### FR-3 — Interview-time coherence check

Before the work proceeds, the analyst validates that the forward-authored KB seed and the gathered
requirements are **mutually coherent** (same work, no contradictions) and surfaces any gaps /
conflicts to the user for resolution.

### FR-4 — Seed as source-of-truth + build-time conformance

The greenfield seed is authoritative (design→code). Feature-005 builds a **new conformance check**
that detects when **as-built code diverges from the design** and flags it for **human
reconciliation**, authority staying design→code until reconciled. *(Cross-ref correction: the existing
f007 freshness mechanism CANNOT do this — it is read-only and source→doc directional, detecting "a
`sources:` file changed," not "code diverged from this doc," and a seed has no file-sources. And
nothing auto-overwrites docs today — housekeep/update-kb are already human-gated — so the new work is
the **check direction + greenfield-origin marking**, not "preventing an auto-overwrite" or "riding on
f007.")*

### FR-5 — Guided triage (analyst-driven, KB-context-aware)

Triage uses the **same seasoned-analyst elicitation** (FR-1) to actively *draw out* from the user
the information needed to choose the right **path** (full vs lite) **and recipe** — instead of
relying on a raw free-form description. It works in **both** contexts: when the project already has a
**full KB** (brownfield, post-`aid-discover`) and when it has only a **seed KB** (greenfield),
leveraging whatever KB exists as context to ask sharper, gap-targeted questions.

> **Emergent design note:** the "seasoned-analyst elicitation" is a **shared capability** used by
> FR-1 (build the seed), FR-2 (calibrate), and FR-5 (triage). Treat it as one reusable component,
> not three separate behaviors.

### FR-6 — Rename `aid-interview` *(minor)*

Rename to a clearer name (lean: `/aid-define`) with full cross-tree propagation — render to the 5
host trees, orphan-prune the old skill dir, update the install manifests, the **skill-name reference
surfaces** (a rename leaves the skill *count* unchanged), and the docs site (same pattern as work-001's
`aid-ask`→`aid-query-kb`). **Sequenced AFTER the content features (002/003/004)** — they edit the skill
dir in place, so the rename must follow to avoid a directory-rename vs content-edit collision.

### FR-7 — Debt side-tasks *(minor)*

H1 (install file-list lockstep check), M3 (refresh `docs/repository-structure.md`), M4
(multi-viewport visual gate / T4), M1 (npm/PyPI publish enablement — owner-gated / external).

## 6. Non-Functional Requirements

### NFR-1 — Conversational expert advisor (latitude in dialogue, discipline in process)

The analyst is a **genuinely conversational, advisory** interlocutor — not a rigid one-question
machine. Because it assumes no knowledge level, it must gracefully **support** responses like
*"I don't know,"* *"what's your recommendation?,"* *"explain the pros and cons,"* *"explain it like
I'm a junior."* Specifically it:

- **Guides** an unsure user toward the best answer (scaffolds, teaches).
- **Recommends** as a real expert when asked — gives the correct expert answer, not a
  non-committal punt.
- **Explains** trade-offs / pros-cons and **adapts the explanation depth** to the user's level.
- **Cordially disagrees** when the user is mistaken — pushes back with reasons, like a seasoned
  analyst, rather than yes-manning.
- **Still defers the decision to the user** — recommendations are surfaced for the user to accept
  or override; the analyst never silently assumes an answer or hides a decision.

The remaining discipline is in the **process**, not the dialogue: state is tracked visibly, every
resolved point is recorded, and the work advances one **confirmed** decision at a time. *(Reconciles
AID's "predictable / no-silent-assumptions" product principle with the richer dialogue — latitude in
how well it helps the user think; discipline in transparency, recording, and deferring the call.)*

### NFR-2 — Brownfield unchanged

The existing brownfield path (`aid-discover` KB + the standard interview) keeps working; greenfield
support is purely additive.

### NFR-3 — Seed is quality-gated

The forward-authored KB seed passes the **same KB review / calibration gate (≥ A)** as an
`aid-discover` KB before the work proceeds.

### NFR-4 — Minimal, not bloated

The seed is the *minimum sufficient* — sufficiency for `aid-specify`/`aid-plan`/`aid-execute` is the
bar, not completeness.

### NFR-5 — Human-gated reconciliation

All design↔code divergence reconciliation is human-gated; never auto-overwrite a greenfield-origin
doc with as-built.

### NFR-6 — Cross-tool parity

The rename stays byte-identical across the 5 host trees (DBI), per the established render /
propagation rules.

### NFR-7 — Suggested answer + rationale on EVERY question (reinforced)

**Every** question the analyst asks MUST carry **(a)** a concrete **suggested answer** and **(b)**
the **rationale** behind it — so the user understands *why* it is suggested and can knowingly
**agree or disagree**. This behavior already exists in `aid-interview`; the redesign must
**preserve and strengthen** it. It is the mechanism that operationalizes "propose-don't-assume" +
"defer to the user": the user always decides, but never from a blank prompt. (No bare,
suggestion-less questions — ever.)

## 7. Constraints

- **C-1 — Conform to the existing KB contract (one foreseen exception).** The forward-authored seed
  uses the existing KB doc schema (f001 frontmatter, concern-model, `INDEX` routing) so downstream
  skills read it unchanged — EXCEPT for **one additive marker**: a new `source:` value (e.g.
  `forward-authored`) to mark greenfield-origin docs (already anticipated by the design seed; required
  by FR-4's origin-marking). This minimal extension touches `lint-frontmatter.sh` / `build-kb-index.sh`
  / `kb-freshness-check.sh` and is the **only** permitted schema change.
- **C-2 — Extend the skill, don't fork it.** Changes extend the existing `aid-interview` state
  machine; greenfield lives *inside* the skill (no new parallel skill) — the design doc's explicit
  decision.
- **C-3 — AID authoring / rendering rules.** Canonical → 5 profiles, DBI byte-identity,
  prose-over-scripts, ASCII-only shipped scripts, WinPS-5.1 compat for any PowerShell (all
  CI-enforced).
- **C-4 — Human gates preserved.** Seed approval and divergence reconciliation stay human-gated.
- **C-5 — Build on work-001 foundations.** Reuse f001 (frontmatter/sources), f003 (concern-model),
  f004 (concept-spine / essence engine), f007 (freshness) — now merged to master.
- **C-6 — `grill-me` adoption is inspiration-only.** Ideas learned from `grill-me` (and variants)
  are **reimplemented in AID's own idiom** / state machine; no copying of its prompts or code, and
  respect its license / attribution.

## 8. Assumptions & Dependencies

**Dependencies**

- **D-1 — work-001 (merged).** Builds on f001 / f003 / f004 / f007 + the `aid-interview` state
  machine, now on master.
- **D-2 — The FR-1 spike precedes the elicitation design.** Seed content + analyst behavior are
  finalized only after the spike.
- **D-3 — Render / propagation tooling (`generate-profile`)** for the rename (FR-6).
- **D-4 — The build-time conformance lifecycle (FR-4) needs a NEW conformance check** (code→design
  divergence) — NOT a special-case on f007, which is read-only + source→doc directional (cross-ref).
- **D-5 — NFR-3's "same KB review gate" depends on `aid-discover`'s review subsystem**
  (`aid-discover/references/{state-review,reviewer-brief,document-expectations}.md`) — reusable
  (doc-set-parameterized), but a real integration dependency to surface (cross-ref).

**Assumptions**

- **A-1 — `grill-me` (and variants) are publicly researchable** for the comparative spike. If the
  spike cannot find solid public material, the fallback is to lean on the established elicitation /
  domain-discovery literature and treat grill-me as best-effort.
- **A-2 — The existing KB schema can express a greenfield seed** (a minimal subset of the doc-set);
  if not, the spike / specify surfaces the gap.
- **A-3 — Greenfield users generally need real guidance**, so the conversational-advisor latitude
  pays off.

## 9. Acceptance Criteria

- **AC-1 — Spike delivered.** The FR-1 RESEARCH spike produces a findings report: classic
  elicitation / domain-discovery techniques + the `grill-me` comparative (strengths / weaknesses /
  adopt-vs-avoid) + a recommended **seed-content set and analyst conversation design**. *(FR-1)*
- **AC-2 — Greenfield seed works.** Running the skill on a code-less project yields a forward-authored
  KB seed that **passes the KB review gate (≥ A)** and is **sufficient for `aid-specify` to proceed**
  — measured by a clean `aid-specify` run with **zero KB-gap loopbacks**. *(FR-1, NFR-3, NFR-4)*
- **AC-3 — No bare questions.** Every question the skill asks carries a **suggested answer +
  rationale**. *(NFR-7)*
- **AC-4 — Calibration works.** The skill asks the user's knowledge level/type and demonstrably
  adapts — handling "I don't know," "what do you recommend?," "explain like a junior," and
  *cordially disagreeing* when warranted. *(FR-2, NFR-1)*
- **AC-5 — Coherence checked.** The skill validates seed ↔ requirements coherence and surfaces
  conflicts before proceeding. *(FR-3)*
- **AC-6 — Conformance flagged.** A greenfield-origin doc's divergence from as-built code is
  **flagged for human reconciliation, not auto-overwritten**. *(FR-4, NFR-5)*
- **AC-7 — Guided triage routes.** Triage draws out path-deciding info via the analyst, works with a
  **full *or* seed KB**, and routes to the right path + recipe. *(FR-5)*
- **AC-8 — Rename shipped.** Renamed with byte-identical propagation across the 5 trees, old dir
  orphan-pruned, manifests + skill-count surfaces + docs site updated; **CI green**. *(FR-6, NFR-6)*
- **AC-9 — Debt closed.** H1 / M3 / M4 / M1 closed (or explicitly deferred with rationale). *(FR-7)*
- **AC-10 — Brownfield intact.** The existing `aid-discover` + standard interview path still passes
  its tests. *(NFR-2)*

## 10. Priority

**Overall: High** — greenfield support unblocks an entire class of from-scratch projects, and the
elicitation-quality lift improves every interview.

**Internal sequencing (MoSCoW):**

- **P0 — Must, FIRST:** the FR-1 RESEARCH spike (feature-001) — gates the **elicitation** features
  (002–005); F6 (rename) and F7 (debt) are NOT gated by it.
- **P1 — Must (primary):** greenfield elicitation core (FR-1 impl, FR-2 calibration, FR-3 coherence,
  NFR-1 + NFR-7 dialogue contract) AND FR-5 guided triage (shares the elicitation engine).
- **P2 — Must (primary, after the seed model exists):** FR-4 build-time conformance lifecycle.
- **P3 — Should (minor):** FR-6 rename → `/aid-define`.
- **P4 — Could (minor):** FR-7 debt side-tasks (H1 / M3 / M4 / M1) — ride along.

**Dependency / parallelism (drives the PLAN execution graph):**

- **feature-001 (spike)** gates **features 002–005** (the elicitation design).
- **feature-002 (engine)** → **003** and **004** depend on it; **003**'s seed model → **005**.
  003 and 004 are parallelizable once 002 lands.
- **feature-007 (debt)** has **no predecessor** — **wholly independent** (orthogonal infra; not even
  gated by the spike), fully parallelizable from the start.
- **feature-006 (rename) must be sequenced AFTER the content features (002/003/004)** — it renames
  `canonical/skills/aid-interview/`, which those features edit *in place* (C-2), so a directory-rename
  would collide with concurrent content-edits. Not gated by the F1 spike, but ordered after the content
  work. *(cross-ref correction — it is NOT fully parallel as first recorded.)*
