# task-037: Teach-back pass/fail fixture corpus (AC1 substrate)

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-006

**Depends on:** -- (none)

**Scope:**
- Author the hand-built, ASCII, checked-in `teachback/` fixture corpus that the AC1 teach-back
  suite (task-038) runs over, under `tests/canonical/fixtures/kb-essence/teachback/` (f012 SPEC F3) --
  two minimal KBs, each a `generated/candidate-concepts.md` (the term universe
  `kb-teachback-questions.sh` derives the question set from) + a `knowledge/domain-glossary.md` spine:
  - `pass-kb/generated/candidate-concepts.md` + `pass-kb/knowledge/domain-glossary.md` (the PASS
    shape): every cross-source candidate concept (every emitted Spread `>= 2` `Term`) has a
    definition-as-used-here concept entry in the spine, so the question set generated from the
    candidates is fully answerable from the KB alone (closure passes -- zero ungrounded).
  - `fail-kb/generated/candidate-concepts.md` + `fail-kb/knowledge/domain-glossary.md` (the FAIL
    shape): an identical candidate list, but the spine OMITS the definition of one core concept (it
    is named/used in the KB but never defined), so the question set contains a "what is X?" the KB
    cannot answer (closure reports the one undefined concept).
- The fail-KB ALSO carries the **runtime-judgment engine-narration shape**: plant the fail-KB so it
  is un-narratable as an engine (the fixed engine question -- "narrate how this project works as a
  running engine" -- is unsupportable by the spine) **even when every coined term is lexically
  defined**. This shape is the RUNTIME-ANCHORED substrate the clean-context teach-back reviewer (M4)
  attempts the engine narration over -- the **engine-narration limb is irreducibly LLM judgment**
  (f005 SPEC L434-435: "there is no mechanical check"; no shipped script returns this verdict), so it
  is NOT a mechanical CI assertion in task-038. (The MECHANICAL FAIL task-038 asserts is the LEXICAL
  term-undefined FAIL from the omitted core-concept definition above -- detectable via
  `closure-check.sh` output (a).) The un-narratable shape is planted so the runtime reviewer has it
  to assess; it is not scored by CI.
- Every `generated/candidate-concepts.md` MUST replicate f004's emitted table schema verbatim (f004
  SPEC L275-289): a `## Summary` block carrying the `Cross-source (spread >= 2)` count row, and a
  `## Ranked Candidates` table with the `# | Term | Class | Freq | Spread | Channels | Salience |
  Example source` columns -- so `kb-teachback-questions.sh` extracts the Spread `>= 2` `Term` rows
  against a real schema (a fixture missing the `Spread` column or the `## Ranked Candidates` table
  yields an empty question set; f012 SPEC "Fixture schema fidelity").

**Boundary (f012 EXERCISES, does not RE-SPEC):** this task authors ONLY fixture files. It does NOT
author or edit `kb-teachback-questions.sh` (f005, shipped by delivery-001 task-012), `closure-check.sh`
(f004, delivery-001), the teach-back exit gate, or the engine-narration question itself. The teach-back
fixture is **engine-validation** (it exercises f005's teach-back keystone gate); the path fixtures
(greenfield-detection + brownfield) are authored by sibling task-033, OUT of scope for THIS task. No
numeric floor is chosen here; this task only plants the pass/fail KBs whose PASS/FAIL separation is
mechanically checkable in task-038.

**Acceptance Criteria:**
- [ ] `tests/canonical/fixtures/kb-essence/teachback/` exists with `pass-kb/` and `fail-kb/`, each carrying `generated/candidate-concepts.md` and `knowledge/domain-glossary.md` per f012 SPEC F3; all files are ASCII and checked into git (no generation step).
- [ ] `pass-kb`: every Spread `>= 2` `Term` in `pass-kb/generated/candidate-concepts.md` has a definition-as-used-here concept entry in `pass-kb/knowledge/domain-glossary.md` (the KB can answer every generated "what is X?"; closure passes with zero ungrounded).
- [ ] `fail-kb`: the candidate list is identical to `pass-kb`, but `fail-kb/knowledge/domain-glossary.md` OMITS the definition of exactly one core concept that is named/used in the KB (closure reports that one undefined concept).
- [ ] The fail-KB also carries the runtime-judgment engine-narration shape: it is planted so the fixed engine-narration question is unsupportable by the spine **even when every coined term is lexically defined**. This is the RUNTIME-ANCHORED substrate the M4 reviewer assesses (the engine-narration limb is irreducible LLM judgment, NOT a mechanical CI assertion); it is planted for the runtime reviewer to grade, not to feed a mechanical engine-narration FAIL assertion.
- [ ] Both `generated/candidate-concepts.md` carry f004's documented schema: a `## Summary` block with a `Cross-source (spread >= 2)` count row AND a `## Ranked Candidates` table with the exact `# | Term | Class | Freq | Spread | Channels | Salience | Example source` columns (f004 SPEC L275-289), so the Spread `>= 2` `Term` filter has its columns to read.
- [ ] The pass-KB and fail-KB share an identical candidate list, so the only difference task-038 mechanically measures is the spine's LEXICAL term-coverage (term defined vs omitted), not a candidate-set diff. (The engine-narratability difference is the runtime-judgment limb the M4 reviewer assesses, not a mechanical task-038 assertion.)
- [ ] No fixture file is written or harvested at authoring time -- the trees are static read-only inputs (task-038 runs scripts over a `mktemp -d` copy, never these committed files).
- [ ] All section-6 quality gates pass.
