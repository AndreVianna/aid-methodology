# task-039: reader-parity suite -- Python === Node doc_freshness

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-006

**Depends on:** task-037

**Scope:**
- Extend the existing dashboard reader-parity test harness (which serializes both readers' `RepoModel`
  and diffs them) so the new per-doc freshness field is covered (f007 SPEC "Parity verification" +
  "Single source of truth"). This is the byte-parity gate FR-6 requires: the Python
  `derive_doc_freshness` (task-037) and the Node `deriveDocFreshness` (task-037) MUST produce
  byte-identical `doc_freshness` arrays (and `suspect_count`) for the same repo state.
- Add a **parity fixture KB** (a scripted git fixture repo, so `merge-base --is-ancestor` ancestry is
  deterministic) containing at least one doc of each verdict class so the assertion exercises the full
  matrix:
  - one `current` doc (source at-or-before `approved_at_commit:`),
  - one `suspect` doc (source changed after `approved_at_commit:`, with a named drifted `suspect_sources`
    entry),
  - one `unknown` doc with a URL source,
  - one pre-migration `unknown` doc (no `approved_at_commit:`).
- Run BOTH readers over the fixture and assert their `doc_freshness` arrays + `suspect_count` are
  byte-identical (the same mechanism the existing twin tests already enforce for `git_freshness_check`,
  extended to the new field). Assert the order of `doc_freshness` entries is identical between the
  twins (deterministic, path-sorted).
- The parity suite is the agreed mechanism (SPIKE-3, settled in task-037) to keep
  script === Python-reader === Node-reader on one verdict: task-036 pins the script to a golden
  fixture; this suite pins the two readers to each other; together all three agree on one verdict.

**Isolation discipline (load-bearing acceptance criteria):** HOME-pinned to a throwaway dir before any
reader run; carry the real-HOME `.aid` canary snapshot (before/after, snapshot BEFORE per
[[ci-runs-as-root-repo-under-home]]) and assert no `.aid` appeared; always pass explicit fixture paths;
build the parity fixture git repo inside `mktemp -d` scratch with `trap ... EXIT` cleanup (never the AID
repo's own git history); never mutate a committed fixture.

**Boundary:** f007 EXERCISES the task-037 readers. This task does NOT author/edit the reader functions
(task-037), the script (task-035), or the `home.html` UI (task-038). It asserts only that the two
readers agree byte-for-byte on `doc_freshness` / `suspect_count` over the fixture.

**Acceptance Criteria:**
- [ ] The dashboard reader-parity harness is extended so `kb_state.doc_freshness` and
  `kb_state.suspect_count` are part of the Python-vs-Node diff (it fails if the twins disagree).
- [ ] A scripted git parity fixture KB contains at least one each of `current`, `suspect`
  (with a named drifted `suspect_sources` entry), URL-source `unknown`, and pre-migration `unknown`
  (no `approved_at_commit:`) docs.
- [ ] Running both readers over the fixture yields byte-identical `doc_freshness` arrays and
  `suspect_count` (the FR-6 parity gate), with identical (path-sorted, deterministic) entry ordering.
- [ ] Isolation: HOME is pinned to a throwaway dir; the real-HOME `.aid` canary snapshots before/after
  and asserts no `.aid` appeared; the parity fixture git repo lives in `mktemp -d` scratch with
  `trap EXIT` cleanup; the AID repo's git history and committed fixtures are never mutated.
- [ ] Tests are deterministic with clean setup/teardown; the FR-6 byte-parity acceptance criterion from
  feature-007 is covered; all section-6 quality gates pass.
