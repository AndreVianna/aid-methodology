# task-007: `cleanup-classify.sh` — scan + tiered classification + work-folder safety matrix + tracked/untracked split

**Type:** IMPLEMENT

**Source:** feature-004-aid-cleanup → delivery-003

**Depends on:** —

**Scope:**
- Implement `canonical/scripts/housekeep/cleanup-classify.sh` (feature-004 SPEC § "Testing —
  classification + safety test suite": "the scan/classify/matrix/split MUST be implemented as a
  scriptable helper … sibling to `housekeep-state.sh`/`branch-commit.sh`"), the deterministic
  scan + classify phase of CLEANUP. Pure logic, no deletions, no UI, no commit — it only **emits
  the candidate list** the `state-cleanup.md` body (task-009) consumes.
- **Scan (S1–S6)** — inspect only the fixed conservative `.aid/` roots in feature-004 SPEC §
  "Scan — the inspected paths": S1 `.aid/.temp/**`, S2 `.aid/.heartbeat/**`, S3
  `.aid/knowledge/.cache/**` + `.manual-checklist.json` + `.spot-check-facts.txt`, S4 stray
  `verify-deterministic-report.json` / `verify-advisory-report.json` under `.aid/`, S5
  unregistered `.aid/generated/**` outputs (a file IS a candidate only if absent from
  `canonical/templates/generated-files.txt`), S6 `.aid/work-*/` folders (globbed at runtime).
  NEVER touch `.aid/settings.yml`, `.aid/knowledge/*.md` (live KB), `.aid/templates/`, or
  anything outside `.aid/`.
- **Candidate record** — emit one record per candidate `{ path, tier, tracked, default_checked,
  reason, gate? }` (feature-004 SPEC § "Candidate record") in a stable, parseable line format
  the body reads.
- **Tier assignment** (feature-004 SPEC § "Tier assignment"): Tier-0 clearly-safe (S1/S2/S3 +
  S4 stray reports + S5 unregistered outputs) → `default_checked=true`; Tier-1 work folders that
  pass the safety matrix → `default_checked=false`, label `review`; Tier-2 loose `.aid/` files
  matching none of S1–S5 → `default_checked=false`, label `review — confirm intent`; registered
  `.aid/generated/**` outputs are NOT emitted as candidates.
- **Work-folder safety matrix (S6)** (feature-004 SPEC § "Work-Folder Safety Rules"): exclude the
  currently-active folder FIRST (union of checks (a)/(b)/(c) below); then compute signal (i)
  merged-to-`master` and signal (ii) STATE.md-concluded, and assign per the decision matrix —
  (i)✓(ii)✓ → offer unchecked (Tier-1); (i)✓(ii)✗ → emit with `gate=explicit-confirm` carrying
  the discrepancy reason; (i)✗ (incl. every unevaluable case) → NOT emitted; active → NOT emitted.
  - **Signal (i)** priority order: (1) PR-merge via `gh pr view <N> --json state -q .state`
    requiring `MERGED` (read the PR number(s) from the folder's `STATE.md ## Deploy Status` `PR`
    column); guard the `gh` path `command -v gh` and fall back if absent. (2) Ancestry fallback —
    `git fetch origin` then `git merge-base --is-ancestor <recorded-sha> origin/master`. If
    neither is evaluable (no PR, no SHA, no `STATE.md`), signal (i) = **unknown → fail** → not
    offered (conservative default; feature-004 SPEC § Signal (i) blockquote). A `work-*` folder
    with no `STATE.md` (e.g. a stray `work-002-canonical-generator`) → (i) fail → not offered as a
    Tier-1 folder (its matching S1–S5 contents may still surface as individual Tier-0/Tier-2 items).
  - **Signal (ii)** passes iff the folder's `STATE.md` top `> **Status:** Deployed` AND ≥1
    `## Deploy Status` row is terminal (non-empty `PR` + a merged/Deployed `State`); else fail.
  - **Active-folder exclusion** (feature-004 SPEC § "currently active work folder", union — offered
    only if NONE match): (a) the folder whose `STATE.md` carries this run's `## Housekeep Status`
    block; (b) the folder matching the current branch (`aid/work-<NNN>-*` or no-merged-PR);
    (c) any folder whose `STATE.md > **Status:**` ≠ `Deployed`.
- **Tracked/untracked discriminator** (feature-004 SPEC § "Deletion Mechanism") — per candidate
  path, deterministically classify `tracked` iff `git ls-files --error-unmatch <path>` succeeds
  (or `git ls-files <path>` non-empty); else `untracked` (`git check-ignore -q <path>` succeeds OR
  `git ls-files <path>` empty). The discriminator only **classifies**; it does NOT run `git rm`/`rm`
  (that is task-009's deletion sequence). Computed at scan time, per path.
- This helper performs **no deletion, no UI, no commit, no push** — it is read-only over the
  filesystem + git + (optionally) `gh`. Bash style per `.aid/knowledge/coding-standards.md`;
  sibling to `housekeep-state.sh`/`branch-commit.sh` under `canonical/scripts/housekeep/`.
- **No new design** — every rule (scan roots, tier table, (i)/(ii) matrix, active-folder union,
  tracked/untracked test) is dictated verbatim by feature-004 SPEC; this task slices it into the
  tested helper.

**Acceptance Criteria:**
- [ ] AC7 (classification half): given a fixture `.aid/` tree, Tier-0 items (S1/S2/S3 gitignored
  scratch, S4 stray reports, S5 unregistered outputs) are emitted `default_checked=true`; work
  folders and loose hand-authored files are emitted `default_checked=false`; a *registered*
  `.aid/generated/**` file is NOT emitted.
- [ ] The (i)/(ii) decision matrix is honored exactly: (i)✓(ii)✓ → offered unchecked (Tier-1);
  (i)✓(ii)✗ → emitted with `gate=explicit-confirm` + a discrepancy reason; (i)✗ (and every
  unevaluable/no-`STATE.md` case) → NOT emitted; the currently-active folder → NEVER emitted.
- [ ] Signal (i) defaults to **fail** (folder not offered) when no PR is recorded, no SHA is
  recorded, or fetch cannot be evaluated (NFR1 conservative default — cleanup never guesses a
  folder is mergeable).
- [ ] The tracked/untracked discriminator classifies a git-tracked path `tracked` (→ later
  `git rm`) and a gitignored/never-committed path `untracked` (→ later `rm`), computed per path
  via `git ls-files`/`git check-ignore`; the helper itself runs no `rm`/`git rm` and no `git push`.
- [ ] The `gh`-PR path is guarded by `command -v gh` and SKIPs gracefully (ancestry fallback)
  when `gh` is absent (the established node/pwsh-skip model — `test-landscape.md`).
- [ ] **NFR5 classification suite** (the IMPLEMENT type-default unit tests for this helper) lands
  here, auto-discovered by the `tests/canonical/test-*.sh` glob in `tests/run-all.sh` (no edit to
  `run-all.sh`), sourcing `tests/lib/assert.sh`, runs under `timeout 300`:
  `tests/canonical/test-housekeep-classify.sh` (tier assignment vs fixture tree),
  `test-housekeep-workfolder-safety.sh` (the four (i)/(ii) matrix rows via the `git
  merge-base --is-ancestor` ancestry fallback so it runs without network/`gh`; `gh`-path
  `command -v gh` → SKIP), and `test-housekeep-deletion-split.sh` (tracked→`git rm`,
  ignored→`rm`, and assert no `git push`/remote interaction) — per feature-004 SPEC § Testing.
- [ ] All §6 quality gates pass; build/render passes; all existing tests pass.
