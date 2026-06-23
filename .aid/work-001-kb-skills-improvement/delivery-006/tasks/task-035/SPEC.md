# task-035: kb-freshness-check.sh -- deterministic per-doc staleness script

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-006

**Depends on:** task-001 (delivery-001), task-002 (delivery-001)

**Scope:**
- Author `canonical/aid/scripts/kb/kb-freshness-check.sh` -- the deterministic, git-only per-doc
  staleness check (f007 SPEC "The staleness-check script"). It lives alongside the existing
  `build-kb-index.sh` / `build-metrics.sh` (same canonical dir), renders to the five host trees via
  `run_generator.py` (C3), and vendors into the install bundles like its siblings -- therefore it is a
  **shipped** script and **ASCII-only** (C2; bash, PS-5.1 N/A).
- **Invocation:** `kb-freshness-check.sh --root <kb-root> [--repo <repo-root>] [--format text|tsv]
  [--doc <relpath>]`. `--root` defaults to `.aid/knowledge/`; `--repo` defaults to the repo containing
  `--root` (`git -C <root> rev-parse --show-toplevel`) -- `sources:` paths are repo-relative per the
  f001 schema, so they resolve against `--repo`, not `--root`. `--format` is `text` (default) or `tsv`.
  Doc list is `sort`ed by path (matches `build-kb-index.sh` line 150) for deterministic ordering.
- **Doc routing:** check each `*.md` under `--root` that is a `source: hand-authored` primary/extension
  doc; skip `meta`, `source: generated`, `INDEX.md`, `README.md`, `STATE.md` (same routing as
  `build-kb-index.sh` / the f001 lint). Read `sources:` (f001 `extract_list`, task-002 d001) and
  `approved_at_commit:` (f001 `extract_field` single-line scalar, task-002 d001) from each doc's YAML.
- **Algorithm (per doc), per f007 SPEC:**
  1. Absence gate: `approved_at_commit:` absent/empty -> doc **unknown** (pre-migration; never suspect
     on a missing baseline). `sources:` absent or `[]` -> doc **current** (nothing to drift against).
  2. Per-source last-changed commit: URL (matches `^[a-z][a-z0-9+.-]*://`) -> source **unknown**
     (cannot `git log` a URL). Path/glob (repo-relative) -> `git -C <repo> log -1 --format=%H -- <entry>`
     (native git pathspec; no shell glob expansion); empty output -> source **unknown**.
  3. Compare: for each source commit `C_src`, `git -C <repo> merge-base --is-ancestor <C_src> <A>`
     (A = `approved_at_commit:`). Exit 0 = ancestor/equal = source **current**; exit 1 = NOT ancestor =
     source **suspect**; any other exit (e.g. 128, A unknown to git) -> source **unknown**, never a
     false suspect.
  4. Fold rule: **suspect** if any source suspect; else **current** if >=1 source current and no
     suspect; else **unknown**.
- **Output:** `--format tsv` = one row per doc, tab-separated, stable column order
  `<doc-relpath>\t<verdict>\t<approved_at_commit>\t<n_current>\t<n_suspect>\t<n_unknown>\t<suspect_sources_csv>`;
  `verdict` in `{current, suspect, unknown}`; `suspect_sources_csv` lists drifted entries (empty unless
  suspect). `text` = same data, human-formatted. stdout only -- **no file writes** (read-only, NFR-6/O3).
  Exit code: `0` always on a successful scan (suspect is a normal verdict, never an error); `1` arg
  error; `2` I/O error (mirrors `build-kb-index.sh`).
- Add `kb-freshness-check.sh` to the `tests/canonical/test-ascii-only.sh` allow-list (C2; it is a
  shipped KB script -- resolves f007 SPEC SPIKE-2's allow-list concern). The allow-list is
  explicit/opt-in (a hardcoded `SHIPPED_SCRIPTS=()` array); the siblings
  `build-kb-index.sh`/`build-metrics.sh` are NOT currently listed, so ADD `kb-freshness-check.sh` to it
  and verify it passes.
- Run `run_generator.py` (the FULL generator, render-drift-full-generator precedent) and commit the
  regenerated `profiles/` so render-drift / KB-hygiene CI stays green (C3/NFR-4). Never hand-edit a
  rendered copy.

**Boundary:** f007 PROVIDES the freshness signal. This task does NOT define `sources:` /
`approved_at_commit:` (f001, delivery-001 -- consumed) and does NOT build the consumers
`aid-update-kb` (f008/delivery-007) or `aid-housekeep` (f010/delivery-008) that scope work off these
verdicts. The dashboard reader surfacing is task-037/task-038, not here.

**Acceptance Criteria:**
- [ ] `canonical/aid/scripts/kb/kb-freshness-check.sh` exists, is ASCII-only, git+coreutils only (no
  LLM, no network, no new runtime), read-only (stdout only, zero file writes), and supports
  `--root` / `--repo` / `--format text|tsv` / `--doc` with the defaults above.
- [ ] Per-doc algorithm matches f007 SPEC: ancestry via `git merge-base --is-ancestor C_src A`
  (NOT timestamp), per-source last-changed via `git log -1 --format=%H -- <entry>`, and the fold rule
  (suspect if any source suspect; else current if >=1 current and no suspect; else unknown).
- [ ] Degrade matrix per f007 SPEC table: absent/empty `approved_at_commit:` -> doc **unknown**
  (never suspect); absent/`[]` `sources:` -> doc **current**; URL source -> source unknown; untracked
  source (empty `git log`) -> source unknown; `merge-base` exit 128 -> source unknown. A git failure
  can never manufacture a false **suspect**.
- [ ] `--format tsv` emits exactly the 7-column stable order above; re-run on unchanged repo state +
  frontmatter is byte-identical (deterministic, NFR-3/C5). Exit codes: `0` on a successful scan
  (suspect != error), `1` arg error, `2` I/O error.
- [ ] `kb-freshness-check.sh` is added to `tests/canonical/test-ascii-only.sh` allow-list and passes
  it; the script renders to all 5 profiles via `run_generator.py` and the regenerated `profiles/` are
  committed; render-drift / KB-hygiene CI green.
- [ ] All section-6 quality gates pass (unit/canonical coverage of new behavior, existing tests still
  pass, build/render passes).
