# task-037: per-doc freshness in both dashboard readers (Python + Node, byte-parity)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-006

**Depends on:** task-035, task-001 (delivery-001)

**Scope:**
- Add a **per-doc freshness read** to BOTH dashboard readers in lockstep so the byte-parity contract is
  reviewable as one unit (f007 SPEC "Dashboard surfacing (both readers -- parity)"). The two readers
  re-implement the SAME algorithm as `kb-freshness-check.sh` (task-035) -- same git verbs, same fold
  rule, same degrade matrix -- because they cannot reliably shell out to the bundled script across the
  five host trees + two runtimes (the same script-free duplication FF-A2 already uses).
- **Python -- `dashboard/reader/derivation.py`:** add `derive_doc_freshness(kb_dir, repo_root) ->
  list[DocFreshness]`, beside `git_freshness_check`. It enumerates the same hand-authored docs, reads
  each doc's `sources:` + `approved_at_commit:`, and runs the same two git verbs the script uses --
  `git -C <repo> log -1 --format=%H -- <src>` and `git -C <repo> merge-base --is-ancestor <C_src> <A>`
  -- through the existing bounded-subprocess helper (`_run_git_log`, line 190). Add `merge-base` to the
  **Python-only** `_GIT_ALLOWED_VERBS` allowlist (line 101; still read-only -- `merge-base` never
  mutates). Same degrade-to-`unknown` matrix as the script (any git failure on a source -> `unknown`,
  never a false `suspect`). FF-A2 `git_freshness_check` is RETAINED (coexists -- see Coexistence).
- **Node (twin) -- `dashboard/server/reader.mjs`:** add the byte-parity twin
  `deriveDocFreshness(kbDir, repoRoot)`, beside `gitFreshnessCheck`, using `runGitCommand`
  (line 525) for the identical argv (`["-C", repo, "log", "-1", "--format=%H", "--", src]` and
  `["-C", repo, "merge-base", "--is-ancestor", cSrc, a]`). The Node `runGitCommand` carries NO verb
  allowlist (unlike Python), so it needs no parallel allowlist edit -- the parity contract is over the
  OUTPUT `doc_freshness` arrays, not over a shared allowlist.
- **Frontmatter scan (both):** add a small tolerant `sources:`/`approved_at_commit:` frontmatter scan
  -- Python in `dashboard/reader/parsers.py` (mirroring its existing tolerant line-scans), Node inline
  in `reader.mjs` -- producing identical parsed values for the same doc.
- **Model + wiring (both):**
  - Python: add a `DocFreshness` model + `KbStateRef.doc_freshness` / `KbStateRef.suspect_count` fields
    (`dashboard/reader/models.py`, line ~138; additive, default empty list / 0 -- existing fields
    untouched for back-compat). Wire: call `derive_doc_freshness` after `derive_kb_status`
    (`dashboard/reader/reader.py`, line ~402) and attach to `kb_state`.
  - Node: attach `doc_freshness` / `suspect_count` in `_buildKbStateRef` (line 3026) and the read
    pipeline (line ~1790), additive.
- **Output shape (both, identical):**
  `kb_state.doc_freshness = [{ doc, verdict, suspect_sources }, ...]` with `verdict` in
  `{current, suspect, unknown}`, plus `kb_state.suspect_count = <int>` rollup for the badge.
- The dashboard reader/HTML files live under `dashboard/` (NOT canonical-rendered -- they are the
  source tree the install bundles vendor); edit in place. No `run_generator.py` for these files
  (C3/NFR-4 -- only `canonical/` is rendered; the readers have their own CI).

**SPIKE resolutions (per f007 SPEC):** SPIKE-1/SPIKE-3 are settled as **augment-and-supersede**
(this task's design): per-doc `doc_freshness` is added additively, FF-A2 `git_freshness_check` and the
5-state `KbStatus` waterfall are RETAINED (they carry non-freshness state and gate clickability), and
the readers re-implement the scan rather than shell out -- pinned to one verdict by the task-039 parity
suite. (`merge-base --is-ancestor` per SPIKE-4 requires git >= 1.8.0, universally present.)

**Boundary:** f007 PROVIDES the freshness signal surfaced here. This task does NOT author the
`home.html` per-doc badge/marker (task-038 -- the UI that reads `doc_freshness`), does NOT author the
parity suite (task-039), and does NOT build the consumers `aid-update-kb`/`aid-housekeep`
(f008/f010, delivery-007/008). It does NOT redefine `sources:`/`approved_at_commit:` (f001, d001).

**Acceptance Criteria:**
- [ ] `dashboard/reader/derivation.py` gains `derive_doc_freshness(kb_dir, repo_root)` and
  `dashboard/server/reader.mjs` gains the twin `deriveDocFreshness(kbDir, repoRoot)`; both implement
  the same algorithm as task-035 (same `git log -1 --format=%H -- <src>` + `merge-base --is-ancestor`
  verbs, same fold rule, same degrade-to-`unknown` matrix) and emit identical `doc_freshness` arrays
  for the same repo state.
- [ ] `merge-base` is added to the Python-only `_GIT_ALLOWED_VERBS` (derivation.py line 101);
  the Node twin needs no allowlist edit; both stay read-only (no KB write, no `approved_at_commit:`
  write -- human-gated, O3/NFR-6).
- [ ] Both readers gain a tolerant `sources:`/`approved_at_commit:` frontmatter scan (Python in
  `parsers.py`, Node inline) that returns identical parsed values for the same doc.
- [ ] Additive model/wiring: Python `DocFreshness` model + `KbStateRef.doc_freshness` /
  `suspect_count` fields (default empty/0), called after `derive_kb_status` in `reader.py`; Node
  `doc_freshness`/`suspect_count` attached in `_buildKbStateRef` + read pipeline. The output shape is
  `[{doc, verdict, suspect_sources}]` + `suspect_count` int, identical across the twins. Existing
  reader fields and FF-A2 `git_freshness_check` are unchanged (coexist).
- [ ] Degrade matrix matches task-035: a git failure / URL / untracked source / missing baseline never
  manufactures a false `suspect` -- the reader degrades that source/doc to `unknown` (matching the
  existing "every failure -> safe default" posture).
- [ ] All section-6 quality gates pass (existing reader unit tests still pass; the dashboard reader CI
  green). The Python===Node byte-parity is asserted by task-039 (this task makes parity achievable;
  task-039 verifies it).
