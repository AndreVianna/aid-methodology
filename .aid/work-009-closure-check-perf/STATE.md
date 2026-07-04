# Work State -- work-009-closure-check-perf

> **State:** Executing — implemented + verified; ready for PR → v2.0.3
> **Phase:** Execute
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-07-04
> **User Approved:** yes

Scoped, user-approved lite bug-fix (v2.0.3): the THIRD instance of the per-item
subprocess-spawn pathology (after harvest-coined-terms v2.0.1, build-project-index
v2.0.2), this time in `closure-check.sh` — the deterministic concept-closure oracle
for /aid-discover Step 5b. Times out (>3 min) on Windows Git Bash / MSYS.

---

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** none (direct-prompt fix)
- **Updated:** 2026-07-04

---

## Triage

- **Path:** lite
- **Work Type:** bug-fix
- **Sub-path:** LITE-BUG-FIX
- **Decision rationale:** Single per-item-spawn perf defect in a shipped KB helper; no new surface.
- **Override:** no
- **Recipe:** none

---

## Root cause (exact lines, pre-change closure-check.sh)

Two per-item `grep -qiF` scan loops (each `grep -qiF` = case-insensitive, fixed-string
literal substring, per line, C locale):

1. **Output (b), main offender (`:476-531`):** per doc × per term (FULL ~500-term
   universe TERMS_FILE) × per sources: entry → `is_url` (echo|grep) + `resolve_source`
   ($()-fork) + TWO `grep -qiF` (in doc, in resolved source). O(docs × ~500 × sources)
   ≈ tens of thousands of spawns. is_url/resolve/in-doc grep are term-independent yet
   recomputed 500× per (doc,source).
2. **Output (a) (`:369-388`):** per undefined term × per doc → `basename` + `grep -qiF`
   + 4-process anchor pipeline. O(undefined × docs) spawns.

Contract preserved: same table columns for both outputs, same `grep -qiF` match
semantics, same CLI/flags, byte-identical CI-reproducible output.

---

## Fix (awk-only — NOT rg)

Build a term→file presence map (+ per-doc first-match anchors) in a SINGLE awk pass,
then derive outputs (a) and (b) from it — also in awk (a bash triple-loop, even
fork-free, is too slow on MSYS to emit the docs×terms×sources rows). One awk `index()`
per (line,term) reproduces `grep -qiF` exactly, per-term-independent (a term that is a
substring of another is never masked). Zero per-item spawns; ~fixed pipeline-spawn cost.

**rg evaluated and REJECTED here** (unlike harvest/build-index): rg.exe on Windows/MSYS
rewrites input paths `/c/x` → `C:/x` in its output, which keys presence under a
different string than the find/resolve paths the output loops use — silently breaking
the cross-OS byte-identity this oracle guarantees. (Also hit a bad `--no-color` flag en
route.) awk keys by FILENAME = the exact path; correct, dependency-free, OS-identical.
Untouched: term-universe/spine/undefined-subset extraction, extract_sources logic.

---

## Verification (all green)

- **Correctness:** `old == new` BYTE-IDENTICAL on `kb-essence/closed-kb` and
  `unclosed-kb` (exercise output-a frontmatter anchors + output-b present/absent/N-A).
- **Perf:** on the new 500-term fixture, OLD **times out >10 min**; NEW ~14s on this
  MSYS box (fixed pipeline cost; ~2s on Linux) and no longer scales with universe×docs×sources.
- **Suites:** new `test-closure-batching.sh` 7/7 (large-universe no-hang + output-a/b
  correctness + determinism); existing `test-closure-check.sh` 9/9; `test-essence-capture.sh` 8/8.
- **Propagation:** 5 profiles regenerated (VERIFY pass; render-drift = closure-check +
  manifests only); dogfood `.claude/` closure-check + `.aid` markers resynced/bumped;
  version-sync 2.0.3; `bash -n` clean on canonical + all 5 copies.

Files: `canonical/aid/scripts/kb/closure-check.sh` (+5 rendered + dogfood),
`tests/canonical/test-closure-batching.sh` + `tests/canonical/fixtures/closure-batching/`,
VERSION/npm/pypi 2.0.2→2.0.3, `.aid` markers.

---

## Related: pathology sweep (other scripts)

A general-purpose audit of all `canonical/aid/scripts/*.sh` found 7 more instances
(1 HIGH: `interview/parse-recipe.sh` per-line echo|grep; 4 MED in kb/: lint-frontmatter,
build-kb-index, kb-freshness-check, kb-actback-task; + cleanup-classify, validate-html-
output; ~7 LOW). Captured for follow-up (scope TBD with user) — NOT in v2.0.3.

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-04 | Work created | -- | Third per-item-spawn instance (closure-check); from /aid-discover Step 5b timeout on Windows |
| 2026-07-04 | Implemented + verified | -- | awk-only batched presence map + awk-derived outputs; rg rejected (Windows path-mangling breaks cross-OS byte-identity). old==new identical (closed/unclosed-kb); batching 7/7, closure-check 9/9, essence 8/8; 5 profiles + dogfood + markers synced; v2.0.3. Ready for PR. |
