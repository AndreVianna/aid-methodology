# Design Note — `aid-interview` Improvements (pre-interview scoping)

**Status:** Pre-interview scoping — NOT yet a tracked work. Captured 2026-06-23 while the thinking
is fresh (during work-001 execution prep). **Do not start the pipeline for this until
`work-001-kb-skills-improvement` is at least executing / stabilized** — this work builds directly on
work-001's `f001`/`f003`/`f004`/`f007` and on the `aid-interview` state machine itself, so
interviewing it earlier risks specifying against a moving foundation.

**Motivation:** three accumulated improvements to `aid-interview` (the skill that gathers intent from
a human to define a work). They are one coherent work because all three reshape the same skill.

---

## Thread 1 — Greenfield support: forward-authoring the KB, INSIDE `aid-interview`

**Problem.** A from-scratch (greenfield) project has no code, so `aid-discover` (a brownfield
*extraction* skill) cannot build a KB. But `aid-specify`/`aid-plan`/`aid-execute` all read the KB, and
`aid-interview` today produces only REQUIREMENTS, not a KB. Gap: a greenfield project needs a KB
**forward-authored from intent** before code exists. (work-001 already makes `aid-discover` *signpost*
greenfield → `/aid-interview` and halt; this work makes the interview actually produce the seed.)

**Decided — it lives INSIDE `aid-interview`, not a new skill.** Reasons (user): (1) it is the *same
act* — gather intent from the human to define the work; (2) a second skill just pushes a "which one do
I call?" decision onto the user. So this is an `aid-interview` capability, not `aid-charter`/`aid-seed`.

**Key framing — greenfield docs ARE the source of truth (the inversion).** In brownfield, code is the
source of truth and the KB *describes* it (extract). In greenfield, **the design is authored first and
IS the source of truth — the code is built to CONFORM to it.** So the forward-authored KB is the
**authoritative design contract**, NOT a provisional seed that extraction later overwrites. One of the
*objectives* of a greenfield project is precisely to produce the docs that become the source of truth.
- Consequence for the lifecycle: as code lands, the job is to **verify the code conforms** to the
  design (and reconcile divergence *deliberately*), NOT to silently replace the design with as-built.
- Consequence for `aid-housekeep`/freshness (f007): a greenfield-origin doc must have divergence
  **flagged for human reconciliation**, not auto-overwritten with whatever the code happens to be.
  (Authority direction is design→code until reconciled — the opposite of the brownfield default.)

**Lifecycle sketch.** Forward-authored (an `f001` `source:` value such as `intent`/`forward-authored`)
→ as code lands, re-triage flips greenfield→brownfield and the freshness loop verifies conformance →
authority stays design→code until a human reconciles drift.

**Open — discuss properly when the work starts:** what the minimal KB seed actually PRODUCES (which
docs/concerns). Likely keystone = the **declared concept-spine / ubiquitous language** (work-001's
"capture the essence" thesis, but *declared* up front instead of harvested), plus intended
architecture, conventions/standards, tech stack — NOT the full discover doc-set. **Deferred.**

---

## Thread 2 — Rename `aid-interview`

**Problem.** User feedback: the name `aid-interview` is too vague — it names the *method* (interviewing)
rather than the *outcome* (defining the work).

**Candidates:** `/aid-define` (it *defines the work* — requirements + features; current lean) ·
`/aid-describe` (sounds more passive). **Final name = a work-time decision.**

**Cost note.** A skill rename carries the same cross-tree propagation cost handled in work-001 (the
`aid-ask`→`aid-query-kb` f008/f009 pattern: render to the 5 host trees + orphan-prune the old dir + the
install manifests + the "N user-facing skills" count surfaces + the docs site). Budget for it.

---

## Thread 3 — Better full-vs-lite triage

**Problem.** The current TRIAGE (free-form description → infer type + recipe → confirm *lite* / escalate
*full*) is "still not good." We need a better mechanism to identify the full vs lite/short path.

**Status: topic noted for the work — specifics deferred.** (Directions to explore then: targeted
sizing questions · a clearer decision tree / complexity heuristic · or redefining the lite/full
boundary itself. The precise weakness — misclassification vs reliance-on-user-self-description vs a
fuzzy boundary — is a work-time discussion.)

---

## Dependencies & sequencing

- **Builds on work-001:** `f001` (frontmatter/`sources:` schema, incl. a forward-authored `source:`
  marker) · `f003` (concern-model / doc-set — what a seed includes) · `f004` (concept-spine structure —
  declared, not harvested) · `f007` (freshness — the verify/converge mechanism) · and the
  `aid-interview` state machine being renamed/retriaged.
- **Sequencing:** do this AFTER work-001 is executing/stabilized. Its foundation is exactly what
  work-001 builds; specifying earlier risks drift.
- Relates to work-001's `REQUIREMENTS.md` **O7** (the forward-authored greenfield KB-seed, logged there
  as out-of-scope/future) and the `.aid/design/kb-skills-improvements.md` note.
