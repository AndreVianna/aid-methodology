# Coherence Check

The layered procedure the seed-authoring step (feature-003) invokes after the
forward-authored seed docs are materialized and before the greenfield-mode review gate.
It validates that the seed and the gathered REQUIREMENTS describe the same work with no
contradictions, and that the seed provides vocabulary and structure for everything the
requirements name. Both layers always run -- neither is optional. (FR-3 / AC-5)

**Audience.** Two readers: the seed-authoring step that invokes this procedure, and the
analyst running it to surface conflicts before the work proceeds.

**Cross-references.**
- `.github/skills/aid-describe/references/move-playbook.md` -- Move 8
  (concrete-example probe, Family 8: Example Mapping) is the conceptual technique
  Layer A draws on; Move 10 (mediate-then-defer & scribe) records each resolved
  conflict before the check advances.
- `.github/skills/aid-describe/references/advisor-stance.md` -- the NFR-7
  question-envelope template used to surface every mismatch and orphan to the user.
- `.github/skills/aid-describe/references/elicitation-engine.md` -- gap rank 1
  (open coherence conflict) routes the adaptive loop back to conflict resolution if a
  mismatch surfaces during elicitation; this procedure is the structured gate that runs
  after elicitation completes.
- `.github/skills/aid-describe/features/feature-003-greenfield-seed-authoring/SPEC.md`
  -- the owner spec for FR-3 / AC-5, the coherence check section, and the sufficiency
  bar (RQ-A5) that consumes this procedure's output.

---

## Contents

- [Overview](#overview)
- [Inputs](#inputs)
- [Layer A -- Concrete-Example Probe](#layer-a----concrete-example-probe)
- [Layer B -- Structural Cross-Check](#layer-b----structural-cross-check)
- [Conflict Surfacing and Human Gate](#conflict-surfacing-and-human-gate)
- [Re-Run Protocol](#re-run-protocol)
- [Sufficiency-Bar Output](#sufficiency-bar-output)
- [Invariants](#invariants)
- [Change Log](#change-log)

---

## Overview

The coherence check is a two-layer quality gate on the relationship between the
forward-authored seed and the gathered REQUIREMENTS. Both layers run every time the
check is invoked -- either on the first pass or after a seed or REQUIREMENTS amendment.

| Layer | Kind | What it catches |
|-------|------|-----------------|
| A -- Concrete-example probe | Conversational | A requirement the seed cannot express; a requirement that contradicts a declared term, boundary, or stack element |
| B -- Structural cross-check | Deterministic | Requirement orphans (REQUIREMENTS terms with no seed concept); Seed orphans (seed concepts no requirement references) |

Any finding from either layer is a conflict. Every conflict is surfaced to the user as
an NFR-7 question and is a [HUMAN GATE] that blocks the work from proceeding until the
user resolves it.

---

## Inputs

| Input | What it is |
|-------|-----------|
| Seed docs (the 5 elements) | The just-authored forward-authored seed: `domain-glossary.md`, `architecture.md`, `coding-standards.md`, `technology-stack.md`, and `decisions.md` (if present) |
| REQUIREMENTS | The gathered requirements document from the current session |

The check reads both inputs as materialized at invocation time. It does not modify
either input directly; amendments flow from user-confirmed resolutions.

---

## Layer A -- Concrete-Example Probe

**What it is.** The analyst picks one or more concrete requirements and walks each one
through the seed -- testing whether the seed's declared vocabulary, boundaries, and stack
can fully express the requirement. This technique draws on the concrete-example probe
(move-playbook.md Move 8 / Example Mapping, Family 8): the requirement is the concrete
example; the seed is the structure under test. A requirement the seed cannot express, or
that contradicts a declared term or boundary, is a flagged mismatch. Mismatches are
surfaced in dialogue, not listed silently.

**When it runs.** After both seed docs and REQUIREMENTS are materialized. Both layers
run before any conflict is surfaced; the analyst completes both passes and then surfaces
findings one at a time.

**Selection heuristic.** Pick requirements that exercise the most terms and
architecture boundaries -- typically the core functional requirements. One well-chosen
requirement can surface multiple mismatches. The analyst selects until they are
confident the walk-through covers the REQUIREMENTS' domain range.

**How to run it.** For each selected requirement, apply a three-pass walk-through:

**Pass 1 -- Term coverage.** Read the requirement. Identify every domain-specific noun,
verb, or concept it uses. For each one: is it defined in `domain-glossary.md` with a
meaning consistent with how the requirement uses it? A term with no glossary entry, or
whose glossary entry conflicts with how the requirement uses it, is a mismatch.

**Pass 2 -- Architecture fit.** Does the intended architecture in `architecture.md`
accommodate the structure this requirement implies? Are the components, boundaries, and
relationships the requirement implies named in `architecture.md`? A requirement that
implies a component not in the architecture, or that contradicts a declared boundary, is
a mismatch.

**Pass 3 -- Stack support.** Does the technology stack in `technology-stack.md` support
the implied technology needs of this requirement? A requirement that implies a language,
framework, or runtime not in the declared stack, or that contradicts the declared stack,
is a mismatch.

**Output.** A list of flagged mismatches. Each mismatch names the requirement that
exposed it and identifies the specific term, boundary, or stack element where the
walk-through failed.

---

## Layer B -- Structural Cross-Check

**What it is.** A deterministic mapping between the load-bearing terms in REQUIREMENTS
and the declared concepts in the seed. The check runs in two directions:
requirements-to-seed (finds Requirement orphans) and seed-to-requirements (finds Seed
orphans). Unlike Layer A, this layer is not conversational -- it is a systematic
enumeration.

**Defining load-bearing terms.** A load-bearing term is any domain-specific noun, verb,
or concept in REQUIREMENTS that carries project-specific meaning -- the project
vocabulary the concept-spine is expected to define. Generic words used in isolation
(system, data, user, file, error, output) are not load-bearing unless the project
assigns them project-specific meaning in context. The analyst identifies load-bearing
terms by reading REQUIREMENTS and extracting the vocabulary that would be candidates
for `domain-glossary.md` entries.

**Defining seed concepts.** A seed concept is:
- Any term defined as an entry in `domain-glossary.md`, OR
- Any named part, boundary, or relationship in `architecture.md`.

**Direction 1 -- Requirements-to-seed (Requirement orphan check).**

For each load-bearing term T in REQUIREMENTS: does T (or a synonym confirmed in the
glossary) appear either as a `domain-glossary.md` entry OR as a named component,
boundary, or relationship in `architecture.md`?

If T has no match in either seed doc, T is a **Requirement orphan**: the seed is
under-pinned for this term. A downstream phase reading only the seed cannot find a
definition for a term the requirements use.

**Direction 2 -- Seed-to-requirements (Seed orphan check).**

For each seed concept C (every `domain-glossary.md` entry and every named architecture
part): does C appear in at least one REQUIREMENTS statement?

If C has no match in any REQUIREMENTS statement, C is a **Seed orphan**: the seed
declares a concept that no stated requirement references. This signals either scope
drift (the seed speculates beyond what is required) or an unstated requirement (a
requirement that should be added to REQUIREMENTS).

**Outputs.**

| Output set | Meaning | Root cause |
|------------|---------|------------|
| Requirement orphan set | REQUIREMENTS load-bearing terms with no seed concept; one entry per orphan term | Seed gap: seed is under-pinned; downstream phases lack the concept |
| Seed orphan set | Seed concepts no requirement references; one entry per orphan concept | Scope drift, OR an unstated requirement that should be made explicit |

Both output sets may be empty. An empty Requirement orphan set is a necessary condition
of the sufficiency bar (see Sufficiency-Bar Output).

---

## Conflict Surfacing and Human Gate

**Every mismatch (Layer A) and every orphan (Layer B) is a conflict.** After both
layers complete, the analyst surfaces each conflict to the user one at a time using the
NFR-7 question-envelope template
(`.github/skills/aid-describe/references/advisor-stance.md`). Every surfaced conflict
carries a suggested resolution and a rationale -- a bare statement of the problem
without a suggestion is a malformed emission.

**Conflict surfacing template.**

```
[1-2 sentences describing the conflict: what was found, which requirement or concept
surfaced it, and what the effect on the downstream phases would be]

[The question: what does the user want to do about it?]

Suggested: [a concrete proposed resolution -- e.g., add a glossary entry, clarify or
            remove the REQUIREMENTS term, remove the orphan seed concept, or add a
            missing requirement]
Why: [the rationale: why this conflict matters for the downstream phases, and why the
     suggested resolution is the right direction]

[1] Accept the suggested resolution
[2] Alternative: ___
[3] Your answer: ___
```

**[HUMAN GATE].** Work MUST NOT proceed to the greenfield-mode review gate while any
conflict remains open. The analyst holds the flow at each conflict until the user
resolves it. This is not a warning; it is a blocking gate.

**Ordering.** Surface Requirement orphans before Seed orphans; within each set, surface
mismatches in the order they were found. The ordering is a default, not a rule -- the
analyst may surface a more critical conflict first when the context warrants it.

**Recording the resolution.** After the user confirms a resolution, the analyst records
it using Move 10 (mediate-then-defer & scribe) from move-playbook.md:

```
Got it: recording "[resolution]" in [the relevant seed doc or REQUIREMENTS section].
```

If the resolution requires amending the seed (for example, adding a glossary entry to
close a Requirement orphan), the amendment is made to the seed doc before the check
re-runs. If the resolution requires amending REQUIREMENTS (for example, adding a missing
requirement to account for a Seed orphan), the amendment is recorded in REQUIREMENTS
before the check re-runs.

---

## Re-Run Protocol

After any seed amendment or REQUIREMENTS amendment resolving a mismatch or orphan,
BOTH layers of the check re-run in full -- not just the layer that surfaced the
resolved conflict. A seed amendment can close one Requirement orphan while creating a
new Seed orphan; a REQUIREMENTS amendment can close a Seed orphan while uncovering a
new Requirement orphan. A full re-run catches cascades.

The check exits when both layers produce zero conflicts: no mismatches (Layer A), no
Requirement orphans, and no Seed orphans (Layer B).

---

## Sufficiency-Bar Output

The zero-Requirement-orphan condition is the structural component of the sufficiency
bar (feature-003 RQ-A5). The seed-authoring step's stopping check reads this output:

- **Zero Requirement orphans** (every REQUIREMENTS load-bearing term maps to a seed
  concept) is a NECESSARY condition for the seed to be minimal-but-sufficient. A
  non-empty Requirement orphan set means the seed is under-pinned: at least one
  requirement term has no seed concept, and the downstream phases cannot act on it. The
  stopping check MUST NOT fire while any Requirement orphan remains.

- A zero-Seed-orphan set is NOT a stopping condition by itself. The analyst may retain
  a seed concept that anticipates a near-term requirement when the user has confirmed
  it. Each Seed orphan is surfaced and explicitly confirmed by the user before the
  check exits, but confirmed retention of a Seed orphan concept does not block the
  sufficiency bar.

The seed-authoring step's stopping check combines this structural output with the
per-element fit criteria from the seed-content model (feature-003 SPEC, Data Model
table): the seed is minimal-but-sufficient when every kept element passes its fit
criterion AND the Requirement orphan set is empty.

---

## Invariants

| # | Invariant | Source |
|---|-----------|--------|
| 1 | Both layers always run. Neither can be skipped, even if Layer A finds no mismatches. | FR-3 / AC-5; feature-003 SPEC |
| 2 | Both layers complete before any conflict is surfaced. The analyst does not interleave surfacing with the walk-through. | Process discipline: surfacing mid-walk risks missing a cascade |
| 3 | Every conflict is surfaced as an NFR-7 question with a concrete Suggested resolution and a grounded Why rationale -- never as a bare list or a bare statement. | NFR-7; advisor-stance.md |
| 4 | The check BLOCKS the flow [HUMAN GATE] until all conflicts are resolved. Work does not proceed to the greenfield-mode review gate while any conflict remains open. | AC-5; feature-003 SPEC flow step 4 |
| 5 | After any seed or REQUIREMENTS amendment, both layers re-run in full. | Re-Run Protocol |
| 6 | Each resolved conflict is recorded by the analyst (Move 10 scribe) before the session moves to the next conflict. | move-playbook.md Move 10; NFR-1 process discipline |
| 7 | Zero Requirement orphans is a NECESSARY condition of the sufficiency bar; the seed-authoring step's stopping check reads this output and MUST NOT fire while any Requirement orphan remains. | RQ-A5; feature-003 SPEC Sufficiency bar |

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-27 | work-001-aid-describe-improvements delivery-004 task-024 | Initial authoring: layered seed<->requirements coherence check -- Layer A concrete-example probe (conversational, three-pass walk-through against terms/architecture/stack) + Layer B structural cross-check (Requirement orphan set + Seed orphan set, deterministic mapping), conflict surfacing with NFR-7 envelope and [HUMAN GATE], re-run protocol, and zero-Requirement-orphan sufficiency-bar output. (FR-3 / AC-5) |
