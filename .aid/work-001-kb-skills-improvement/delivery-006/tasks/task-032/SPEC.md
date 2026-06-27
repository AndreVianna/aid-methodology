# task-032: Calibration fixture corpus (transcription/hollowness/coverage + control)

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-006

**Depends on:** -- (none)

**Scope:**
- Author the hand-built, ASCII, checked-in `calibration/` fixture corpus that the AC6 suite
  (task-035) runs over, under `tests/canonical/fixtures/kb-essence/calibration/` (f012 SPEC F2):
  - `knowledge/transcription-fat.md` (CAL-1 -- too fat): body is a near-verbatim restatement of
    `src/payment-engine.ts` (high lexical overlap, no added why/how-it-relates), with a `sources:`
    frontmatter declaring that local file -- so the transcription-ratio hint reads HIGH.
  - `knowledge/hollow-thin.md` (CAL-2 -- too thin): mostly `see src/...` pointers, no synthesized
    cross-cutting content. CAL-2 hollowness is an irreducible LLM judgment (f005 SPEC L455/L474 --
    no shipped script emits a hollowness signal); this doc is planted as the RUNTIME-ANCHORED
    substrate the Calibration reviewer M5 grades, NOT a mechanical CI signal. Plant the thin shape
    so the runtime reviewer has something to assess; no floor is pinned for it.
  - `knowledge/coverage-gap.md` (CAL-3 -- coverage-vs-source): declares `sources: src/payment-engine.ts`
    but OMITS a salient/load-bearing term the source and `candidate-concepts.md` carry -- so
    f004's `closure-check.sh` **output (b)** (the per-doc `sources:`-anchored coverage table
    `term | doc | anchoring-source | present|absent`) reports that term as an `absent` row for the doc.
  - `knowledge/well-calibrated.md` (CONTROL): a summary+pointer doc at the right altitude --
    synthesizes the why, points to `sources:` for detail, covers the salient terms -- it must NOT
    flag (no coverage gap, LOW transcription ratio). This is the precision guard.
  - `src/payment-engine.ts`: the `sources:` target the fat/coverage docs reference.
  - `generated/candidate-concepts.md`: the salient-term universe f004's `closure-check.sh`
    output (b) anchors against -- carrying f004's full table schema (`## Summary` + `## Ranked
    Candidates` columns, f004 SPEC L275-289), including the salient term that `coverage-gap.md` omits.

**Boundary (f012 EXERCISES, does not RE-SPEC):** this task authors ONLY fixture files. It does NOT
author or edit `closure-check.sh` (f004, delivery-001) or the f005 Calibration rubric / CAL-N floors
(f005, delivery-001). The coverage/transcription evidence is f004's MERGED `closure-check.sh`
outputs (b)/(c) -- f005 ships no coverage script (`kb-salient-coverage.sh` was dropped). The numeric
CAL-1 transcription-ratio floor is not chosen here -- that empirical floor is measured and pinned in
task-035 ([SPIKE-V2]); this task only plants docs whose fat/control separation is measurable. CAL-2
hollowness is LLM judgment (runtime-anchored), so no hollowness floor is pinned anywhere.

**Acceptance Criteria:**
- [ ] `tests/canonical/fixtures/kb-essence/calibration/` exists with the four `knowledge/*.md` docs, `src/payment-engine.ts`, and `generated/candidate-concepts.md` enumerated in f012 SPEC F2; all ASCII, checked into git.
- [ ] `transcription-fat.md` body has high lexical overlap with `src/payment-engine.ts` and declares it via `sources:` frontmatter (a local readable file -- the only kind the offline helper scans); `well-calibrated.md` covers the same material at summary altitude with low overlap.
- [ ] `coverage-gap.md` declares `sources: src/payment-engine.ts` and omits a salient term that BOTH the source and `generated/candidate-concepts.md` carry; `well-calibrated.md` covers all salient terms (no gap).
- [ ] `hollow-thin.md` is dominated by `see src/...` pointers with minimal synthesized prose.
- [ ] `generated/candidate-concepts.md` carries f004's documented schema (`## Summary` with `Cross-source (spread >= 2)` row + `## Ranked Candidates` with the `# | Term | Class | Freq | Spread | Channels | Salience | Example source` columns) and lists the salient term `coverage-gap.md` omits.
- [ ] The corpus is constructed so the planted docs separate cleanly from the control (the fat doc's overlap is materially higher than the control's; the gap doc misses a term the control covers) -- making the empirical floor in task-035 measurable.
- [ ] All section-6 quality gates pass.
