# task-008: closure-check.sh 3-output coverage oracle

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-002, task-006

**Scope:**
- Author `canonical/aid/scripts/kb/closure-check.sh`: the SINGLE deterministic (no LLM,
  coreutils+git only) coverage oracle the whole work consumes -- f004 owns it; f005 ships NO coverage
  script. Inputs: `.aid/generated/candidate-concepts.md` (term universe = BOTH `harvest` and
  `synthesis` rows) + the spine (`domain-glossary.md`) + the KB docs + each KB doc's resolved
  `sources:` frontmatter (f001's field). Emit THREE separately-parsable outputs:
  - (a) ungrounded / un-closed concept set: `term | used-in-doc | anchor` -- a row IS the finding
    (closed => zero rows); the loop's termination oracle.
  - (b) per-doc `sources:`-anchored coverage: `term | doc | anchoring-source | present|absent` --
    `absent` IS the finding; a local-readable-file `sources:` entry is scanned (literal,
    case-normalized); a URL (or unresolvable) entry is N/A -- skipped, NEVER a finding.
  - (c) transcription-ratio hint: `doc | source-file | overlap-ratio` -- per (doc, local-source)
    deterministic `[0.0,1.0]` salient-token overlap (denylist-filtered, same denylist as the
    harvest), integer-arithmetic in awk with fixed rounding; URL source -> N/A (no numeric ratio).
  - All scanning is literal/lexical, case-normalized, no fetch, no network.
- Dep note (f004 SPEC L834 SPIKE-H5 provide-before-consume seam): hard-depends on **task-006**
  because this oracle consumes two task-006 deliverables -- the shipped `coined-term-denylist.txt`
  (the salient-token filter for output (c)'s transcription-ratio, "same denylist as the harvest")
  and the `harvest`/`synthesis` `Source`-column schema of `candidate-concepts.md` (the term
  universe). task-002 (`extract_list`) provides neither, so task-002 alone is insufficient.
- Add `closure-check.sh` to the `test-ascii-only.sh` allow-list.
- Edit canonical only; re-run `run_generator.py`; commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `closure-check.sh` is deterministic ASCII bash (coreutils + git only; no LLM, no
  python3/pwsh) and emits all three outputs (a)/(b)/(c) as separately-parsable sections/files.
- [ ] Output (a) reports each candidate/relates-to term used-but-undefined (`term|used-in-doc|anchor`,
  a row IS the finding); a fully closed input yields zero rows.
- [ ] Output (b) emits `present` for a term in a doc whose local-file `sources:` contains it,
  `absent` (the finding) for a term anchored via local-file `sources:` but missing from the doc body,
  and `anchoring-source = N/A` with NO `absent` finding for a URL-only-sourced doc.
- [ ] Output (c) emits a high `overlap-ratio` for a near-verbatim local source and `N/A` for a
  URL-only source; the ratio is deterministic with fixed precision/rounding.
- [ ] The term universe includes BOTH `harvest` and `synthesis` rows of `candidate-concepts.md` plus
  spine relates-to terms.
- [ ] A re-run is byte-identical across all three outputs regardless of any URL `sources:`
  (determinism independent of the network).
- [ ] `closure-check.sh` is on the `test-ascii-only.sh` allow-list and passes the ASCII guard.
- [ ] `run_generator.py` re-run; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
