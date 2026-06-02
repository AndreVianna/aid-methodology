# task-004: `detect-delta.sh` — SHA-anchored delta detection engine

**Type:** IMPLEMENT

**Source:** feature-002-kb-delta-refresh → delivery-001

**Depends on:** task-001

**Scope:**
- Implement `canonical/scripts/housekeep/detect-delta.sh` (feature-002 SPEC § Detection Engine,
  § Components / Scripts). Pure git + grep; no `yq`/`python` dependency.
- CLI: `detect-delta.sh [--state-file <path>] [--offline-ok]` (default `--state-file
  .aid/knowledge/STATE.md`). Behavior in order (feature-002 SPEC § Detection Engine "Behavior"):
  1. Read baseline SHA via `grep -m1 '\*\*Approved-At-Commit:\*\*'`; if absent → bootstrap mode.
  2. Online-first `git fetch origin master 2>/dev/null`; on success resolve compare ref via
     `git rev-parse origin/master`.
  3. Offline gate (C2/AC3): fetch non-zero WITHOUT `--offline-ok` → print offline-permission
     prompt to stderr and **exit 3** (no diff); WITH `--offline-ok` → compare against local
     `master` (`git rev-parse master`). Script never prompts interactively.
  4. Delta: `git diff --name-only <baseline-sha>..<compare-ref>` (changed paths, one per line
     to stdout) + `git log --oneline <baseline-sha>..<compare-ref>` (human commit list). Exit
     **0** if paths exist, **10** if range empty.
  5. Bootstrap (AC2): no baseline → read date from `**Last KB Review:**` (fallback
     `**User Approved:** yes (YYYY-MM-DD…)`), then `git log --since=<date> --name-only
     --pretty=format: <compare-ref>` (still online-first / offline-gated); same path list +
     exit 0/10.
- Exit-code contract: `0` delta · `10` no delta · `3` fetch failed without `--offline-ok` ·
  `2` arg/usage error (feature-002 SPEC § Detection Engine "Exit-code contract").

**Acceptance Criteria:**
- [ ] SHA-anchored range produces the correct changed-path set (AC1).
- [ ] Empty range → exit 10 (AC5).
- [ ] Missing `**Approved-At-Commit:**` → bootstrap date path (AC2).
- [ ] Simulated fetch failure without `--offline-ok` → exit 3 and no diff (AC3); with
  `--offline-ok` → diffs against local `master`.
- [ ] Arg/usage error → exit 2.
- [ ] A canonical unit suite `tests/canonical/test-housekeep-detect-delta.sh` (auto-discovered
  by the `tests/canonical/test-*.sh` glob, sourcing `tests/lib/assert.sh`) drives the above
  against a throwaway fixtured git repo with a bare-clone `origin` (feature-002 SPEC § Testing
  `test-housekeep-detect-delta.sh`).
- [ ] All §6 quality gates pass (NFR3/NFR5); build/render passes; all existing tests pass.
