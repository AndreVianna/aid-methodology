# Work State -- work-009-closure-check-perf

> **State:** Executing — closure-check + full 13-script perf sweep done + verified; on PR #119 (v2.0.3)
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

## Full pathology sweep — ALL fixed in v2.0.3 (user: "fix all, grade A+")

A general-purpose audit of every `canonical/aid/scripts/*.sh` found more instances of the
same per-item subprocess-spawn pathology. Per user direction, ALL were fixed and folded
into v2.0.3 (same PR #119). 13 scripts total, each verified BYTE-IDENTICAL to its
pre-change version (old-vs-new diff on real inputs / fixtures + its existing canonical
test suite green):

| Script | Fix | Byte-identity + perf |
|--------|-----|----------------------|
| interview/parse-recipe.sh (HIGH) | per-line `echo\|grep` → bash `[[ =~ ]]`; task-num via BASH_REMATCH | render workdir identical |
| kb/lint-frontmatter.sh | 4 fm_* awk helpers → one `load_frontmatter` awk → assoc arrays | 37 fixtures+KB identical; test 57/57 |
| kb/build-kb-index.sh | 9 shell-pipe helpers → one awk (helpers as awk fns); kb-category once; basename builtin | KB identical (ts-filtered); test 40/40; 8m46s→36s |
| kb/kb-freshness-check.sh | is_url `[[ =~ ]]`; tr/basename builtins; per-doc fields once | KB+git-fixture identical; test 37/37 (kept broad URL scheme, not `https?`, to stay identical) |
| kb/kb-actback-task.sh | per-(doc×class) grep → 2 awk passes; `_dim` global | all subcmds identical; test 42/42; 59s→8.5s |
| kb/kb-citation-lint.sh | per-doc awk → single awk over doc array | KB+fixtures identical; test 8/8 |
| kb/build-metrics.sh | per-doc `wc\|tr\|basename` → one batched `wc`; builtins | pinned-date cmp identical |
| kb/kb-dual-intent-probes.sh | `_dim_of_filename` `$()` → global (no fork) | doc-set+fixtures identical; test 63/63 |
| housekeep/cleanup-classify.sh | per-line `echo\|grep`/`awk`/`sed`/`tr` → bash builtins | STATE.md identical; test 24/24; 213s→23s |
| summarize/grade-summary.sh | per-doc `grep -qiF` → one awk (index+tolower, stems via ENVIRON) | kb.html+discriminator fixture identical; test 49/49 |
| summarize/validate-html-output.sh | per-anchor full-HTML grep → one id-set scan + O(1) lookups | kb.html+fixture identical; tests pass |
| summarize/build-md-export.sh | per-doc `strip_frontmatter` awk → single awk (BEGIN getline) | KB same sha256 + 5 edge cases; test build asserts pass |
| execute/complexity-score.sh | `tr`→param-exp; N `find\|head`→1 find; `grep -m1`→in-proc read | fixtures identical; test 13/13 |

Deviations (flagged, correct): kb-freshness kept its broad `^[a-z][a-z0-9+.-]*://` URL
scheme (narrowing to `https?` would drop ftp/git+ssh/s3 → behavior change). complexity-
score SKIPPED the recursive `compute_depth` `$()`→global conversion (its subshell
isolation drives the cycle-WARN stderr; converting would NOT be byte-identical) — N is
small; left as-is. One-shot migration scripts (migrate-*) intentionally not touched
(run once; per-item spawns there aren't a recurring perf concern).

All 13 propagated to the 5 profiles (VERIFY pass; render-drift = these scripts + manifests
only) and resynced into the dogfood `.claude/`.

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-04 | Work created | -- | Third per-item-spawn instance (closure-check); from /aid-discover Step 5b timeout on Windows |
| 2026-07-04 | Implemented + verified | -- | awk-only batched presence map + awk-derived outputs; rg rejected (Windows path-mangling breaks cross-OS byte-identity). old==new identical (closed/unclosed-kb); batching 7/7, closure-check 9/9, essence 8/8; 5 profiles + dogfood + markers synced; v2.0.3. Ready for PR. |
| 2026-07-04 | Full sweep folded into v2.0.3 | -- | Per user "fix all, A+": 12 more scripts fixed (parse-recipe + lint-frontmatter/build-kb-index/kb-freshness/kb-actback/kb-citation/build-metrics/kb-dual-intent/cleanup-classify/grade-summary/validate-html/build-md-export/complexity-score). Each byte-identical (diff on real inputs/fixtures + existing test suites green; measured 5-14x speedups). 5 profiles regenerated (VERIFY pass; drift = these scripts only) + dogfood resynced. All 13 on PR #119 (v2.0.3). |
| 2026-07-04 | PR #119 CI regression caught + fixed | -- | Full-suite gate (`canonical helper suites`) failed 1/91: `test-kb-index-extract-list.sh`. Root cause: the build-kb-index refactor ported extract_field/extract_literal/extract_list into the awk pass and REMOVED the shell functions, but that unit suite sources those shell functions directly (`awk '/^extract_*()/../^}$/'`) → `command not found`. Output byte-identity held (EL11-13 end-to-end assertions passed), so only the function-sourcing unit suite broke. Fix: restored the 3 extractors as shell functions before the `# --- Begin output ---` marker, documented as the unit-tested reference spec (render path keeps the awk port; functions never called on render path → zero per-doc spawn, output unchanged). Re-verified local: test-kb-index-extract-list 39/0, test-build-kb-index 40/0. Regenerated 5 profiles (VERIFY pass) + resynced dogfood. PR #119 CI then ALL GREEN. Lesson: a refactor that removes a shell helper can pass output-byte-identity yet break a suite that unit-tests that helper by sourcing it — only the FULL 91-suite run catches it. |
| 2026-07-04 | Tier-1 hot-path polish folded into v2.0.3 | -- | Second analysis (4 agents over the ~19 untouched scripts + migrations): NO new hang-class instances remain (per-item spawn in an unbounded loop) — the 13-script sweep caught them all. Remaining opportunities are incremental fork-shaving. Per user "fold into v2.0.3 now", applied the byte-identical Tier-1 set: (1) read-setting.sh — lazy abs_path (was computed on every call, used only in 2 error branches; saves a realpath fork on the most-invoked script in the repo); (2) recon-classify.sh — removed both /tmp temp-file round-trips (awk output captured via $(...) + param-expansion split; ~6 forks + 2 /tmp writes gone); (3) assemble.sh — per-section `cat` loop → single `cat "${SECTIONS[@]}"`; (4) summarize-preflight.sh — `$(basename)` → `${f##*/}`; (5) housekeep-state.sh — mode_resume 4 read_field awk passes → 1 batched read_fields_resume. Verified: read-setting 18/0, recon-classify 37/0 + recon.md byte-identical old-vs-new, assemble-determinism 22/0, housekeep-state 43/0 + --resume byte-identical across all 6 re-entry rows (incl. empty-trailing-State), summarize-preflight 18/2 (the 2 fails are PRE-EXISTING MSYS-only: T1d chmod 000 doesn't block writes on Windows — unmodified HEAD fails identically; CI runs on ubuntu where it passes). No sourced-function removed (regression class does not recur). Regenerated 5 profiles + resynced 5 dogfood copies. DEFERRED (concrete reason, marginal reward): read-setting skill-mode 2-lookup merge (reimplements grade-resolution semantics for −1 fork), recon-classify 2-pass merge (−1 fork; double file-read is I/O not fork cost), compute-block-radius dual-output awk (−1 fork, rare task-failure path), spot-check-facts cut→param-exp (bounded-10 loop; `cut -c` vs `${:0:}` diverge on multibyte). |
