---
kb-category: primary
source: hand-authored
intent: |
  Inventory of test suites that protect the canonical helper scripts AID skills
  depend on. Currently 24 unit/integration suites under tests/canonical/, discovered by
  glob and run by the tests/run-all.sh aggregator. Most are pure bash (POSIX);
  two shell out to node (.mjs validators) and two to pwsh (PowerShell mirrors),
  each skipping if its runtime is absent. All suites source the shared
  tests/lib/assert.sh assertion library. NO methodology/orchestration/E2E tests —
  those don't exist and aren't needed (the methodology is exercised by
  dogfooding, the renderer has its own VERIFY (deterministic) gate). Read this to
  understand what changes to canonical/scripts/ are guarded by tests vs require
  manual verification.
contracts:
  - "currently 24 test suites under tests/canonical/ (glob-discovered; recount with ls tests/canonical/test-*.sh | wc -l), no skill-level tests"
  - "tests/run-all.sh is the single aggregator (glob-discovers tests/canonical/test-*.sh)"
  - "All suites source tests/lib/assert.sh (shared counters + asserts + test_summary)"
  - "Most suites are pure bash (POSIX, Git Bash on Windows); 2 need node, 2 need pwsh — each skips if absent"
changelog:
  - 2026-06-03: housekeep run-state relocation (PR #51) — updated the test-housekeep-state.sh + test-housekeep-workfolder-safety.sh descriptions: run-state now in `.aid/.temp/HOUSEKEEP_STATE_<ts>.md` (absent-file tolerance covered); the work-folder matrix is now informational (every folder offered, user-confirmed; only the current-branch folder hard-skipped — old signals (a)/(c) removed).
  - 2026-06-03: post-merge work-001-aid-housekeep (PR #49) + work-002 canonical bug-fix suites — suite count 18→24 (verified `ls tests/canonical/test-*.sh | wc -l` = 24 on disk). Documented the 5 new housekeep suites (test-housekeep-state.sh, test-housekeep-branch-commit.sh, test-housekeep-classify.sh, test-housekeep-workfolder-safety.sh, test-housekeep-deletion-split.sh) added by the /aid-housekeep skill, which guard the canonical/scripts/housekeep/ helpers (housekeep-state.sh, branch-commit.sh, cleanup-classify.sh). Also documented test-complexity-score.sh (work-002 task-001 four-fix regression suite for canonical/scripts/execute/complexity-score.sh) which was on disk but missing from this inventory. Done via /aid-housekeep targeted re-discovery.
  - 2026-06-01: post-merge work-001-add-providers (PRs #42/#43/#44) — byte-identity assertion 3→5 install-tree profiles (added GitHub Copilot CLI + Antigravity); documented new setup cases (test-setup.sh SU12-17/SU16b; test-setup-ps1.sh SPS05-08, which SKIPs without pwsh per established contract); documented the 2 new generator self-tests (test_copilot_emitter.py, test_antigravity_emitter.py) wired into the CI generator-selftests step. Canonical suite count unchanged at 18 (verified `ls tests/canonical/test-*.sh | wc -l` = 18 on disk — the new setup cases are SU/SPS additions inside the existing test-setup.sh / test-setup-ps1.sh suites, not new suite files).
  - 2026-05-31: delivery-002 — added 3 F4 doc-set suites (test-doc-set-read.sh, test-doc-set-mapping.sh, test-doc-set-propose-confirm.sh); updated suite count 15→18
  - 2026-05-31: delivery-001 — added test-discovery-doc-ownership.sh and test-expectations-single-source.sh; updated suite count 13→15 (stated as "currently N", not a hardcoded invariant); updated Suites section header accordingly.
  - 2026-05-30: Substantive refresh to current truth — 7→13 suites; documented the tests/run-all.sh aggregator (replaces the old "no aggregator, per-suite loop" claim) and tests/lib/assert.sh shared library; inverted the gaps section (the .mjs validators, PowerShell mirrors, and setup install flow are now COVERED, not gaps); recorded the node/pwsh-skip model; applied script renames (writeback-task-status→writeback-state, concatenate→assemble-3part, build-index→build-kb-index, harness.py→render_lib.py, VERIFY-4a/4b→VERIFY (deterministic)/(advisory)); converted bare line-number citations to durable anchors. Dropped invented per-suite assertion numbers in favor of qualitative coverage (suites now share one summary format and the README does not commit to counts).
  - 2026-05-29: Corrected count 5→7 suites / 235→273 assertions — added the fetch-mermaid.sh and grade.sh sections (both existed on disk but were missing from this inventory); fixed validate-diagrams.mjs line count 574→577
  - 2026-05-27: Initial generation by discovery-quality (cycle-1)
  - 2026-05-27: Full rewrite during cycle-2 FIX Phase B for accurate post-Q6-cleanup state (Q20)
---
# Test Landscape

## Scope

These tests cover the **canonical helper scripts** only — the small utilities that
AID skills invoke at runtime (writeback, BFS compute, recipe parsing, severity
grading, diagram/contrast validation, 3-part assembly, the end-user installer, the
/aid-housekeep helpers, etc.).
Most are pure bash; a few shell out to `node` or `pwsh` to exercise the `.mjs`
validators and the PowerShell mirror scripts.

What is NOT tested here:
- **Orchestration skills** (`/aid-discover`, `/aid-execute`, …) — prompt-driven; no
  scripted harness exists or is planned. The `discovery-reviewer` sub-agent acts as the
  closest adversarial integration check each cycle.
- **Renderer** (`run_generator.py`) — covered by its own VERIFY (deterministic)
  determinism gate (`verify_deterministic.py`); see `architecture.md`. The renderer also
  has **generator self-tests** (Python, NOT under `tests/canonical/`) wired into the CI
  `generator-selftests` job (`.github/workflows/test.yml`, the `--self-test` invocations):
  `test_manifest_safety.py` (pure-mirror deletion safety),
  `test_copilot_emitter.py` (Copilot agent-format emitter — real-YAML round-trip),
  and `test_antigravity_emitter.py` (Antigravity rule-format reshape). All three under
  `.claude/skills/aid-generate/scripts/`.
- **Sub-agent definitions** — no test harness; verified by dogfooding. See
  `canonical/agents/*/AGENT.md`.
- **Cross-tool consistency** (Claude Code vs Codex vs Cursor vs Copilot CLI vs Antigravity) —
  covered by the renderer's byte-identity assertion across the 5 install-tree profiles.
- **E2E pipeline** (Discover → … → Deploy → Monitor) — exercised by dogfooding this repo,
  not scripted tests.

---

## How the suites run

### Aggregator — `tests/run-all.sh`

`tests/run-all.sh` is **the** single "run all tests" entrypoint, shared by CI
(`.github/workflows/test.yml`, the `canonical-tests` job) and local development —
a contributor runs the exact same gate locally before pushing. It:

- **Glob-discovers** suites: `tests/canonical/test-*.sh`. Adding a suite needs no
  edit to the runner (find the glob at the `shopt -s nullglob` line in `run-all.sh`).
- Runs each suite **under `timeout 300`** in its own isolated `bash` process.
- `chmod +x`'s the helper + test scripts first (the repo is authored on Windows,
  committed `100644`; several suites invoke their SUT directly and need the exec bit
  on Linux). Idempotent.
- Aggregates results and **exits non-zero if any suite fails** (or if no suites are
  found). Under GitHub Actions it emits `::group::` folding and `::error::`
  annotations (gated on `GITHUB_ACTIONS`).

```bash
bash tests/run-all.sh        # run every suite, aggregate PASS/FAIL
bash tests/run-all.sh -v     # verbose — passes --verbose through to each suite
```

> **Historical note:** earlier cycles had *no* aggregator (a Q6 cycle-1 decision),
> and this doc previously told you to loop `for f in tests/canonical/*.sh; do …; done`
> by hand. That is obsolete — `run-all.sh` is the aggregator now (closed under M4).

### Shared assertion library — `tests/lib/assert.sh`

Every suite **sources** `tests/lib/assert.sh` (find each at its
`source ".../lib/assert.sh"` line). The library provides:

- **Shared counters:** `PASS`, `FAIL`, `ERRORS[]` (initialized in the lib).
- **Logging / outcomes:** `log` (VERBOSE-only), `pass "<name>"` (counts; printed only
  when `VERBOSE=1`), `fail "<name> — why"` (counts; **always** printed; recorded in
  `ERRORS`).
- **Assertion helpers:** `assert_eq`, `assert_output_contains`,
  `assert_output_not_contains`, `assert_file_contains`, `assert_file_not_contains`,
  `assert_file_exists`, `assert_dir_exists`, `assert_exit_zero`, `assert_exit_nonzero`,
  `assert_exit_eq`, `assert_line_exact`, `assert_line_count`.
- **`test_summary`** — prints `Tests passed: N` / `Tests failed: M`, lists failures,
  and returns `1` if any assertion failed. Every suite ends by calling it, so all
  suites share one uniform summary format (closed under M6 — before it, each suite
  carried its own `PASS=0`/`FAIL=0` scaffold and printed in its own format).

### Runtime skips (node / pwsh)

Most suites are pure bash. Four shell out to another runtime via a thin bash wrapper
that **skips (exit 0 with a `SKIP:` notice) if its runtime is absent**, so a host
missing one still runs the rest:

- **`node`** — `test-validate-diagrams.sh`, `test-contrast-check.sh` (the two `.mjs`
  validators).
- **`pwsh`** — `test-assemble-3part-ps1.sh`, `test-setup-ps1.sh` (the PowerShell
  mirrors).

(One additional optional-runtime guard exists in `test-housekeep-workfolder-safety.sh`,
which SKIPs the gh-PR-merge path when `gh` is absent and otherwise exercises the
offline `git merge-base --is-ancestor` ancestry fallback.)

CI does **not** tolerate a silent skip: the `canonical-tests` job pins `node` (v20)
and asserts both `node` and `pwsh` are present before running, failing loudly if
either is missing so the node/PowerShell coverage can never be silently bypassed.

---

## Suites (currently 24)

All suites live under `tests/canonical/` and target scripts under `canonical/scripts/`
(or the top-level `setup.*` installers, or the canonical agent/skill source files).
Coverage is described qualitatively — suites share one `test_summary` format and the
suite inventory in `tests/README.md` does not commit to per-suite assertion counts.

### test-read-setting.sh

**Target:** `canonical/scripts/config/read-setting.sh`

Covers the three-tier settings-resolution model: per-skill override > global category
default > hardcoded `--default`; `--path` mode for direct dotted-key lookups; missing
`settings.yml` with and without `--default`; comment/quote stripping; and error exits
(bad `--path` format, unknown flag, missing paired args).

### test-writeback-state.sh

**Target:** `canonical/scripts/execute/writeback-state.sh`
(renamed from the former `writeback-task-status.sh`)

Covers all 4 argument modes plus lock-contention safety under concurrent writers:
`--task-id --field --value` (single-field row update), `--task-id --findings` (Quick
Check block write), `--delivery-id --block` (Delivery Gate block write), and
`--delivery-id --append-issue` (`delivery-NNN-issues.md` append); idempotency of each
mode; concurrent lock contention (parallel writers on different rows); and error paths
(missing args, invalid task-id, lock timeout, missing lock dir).

### test-parse-recipe.sh

**Target:** `canonical/scripts/interview/parse-recipe.sh`

Covers all operating modes (`--list`, `--validate`, `--spec`, `--tasks`, `--render`)
plus slot substitution, `{!{` escape rewrite, unmatched-slot passthrough, multi-task
recipe emission, lock-file lifecycle, name-vs-filename mismatch warning, and error
paths (missing file, malformed front-matter, missing blocks, bad args). Also validates
each of the seed recipes in `canonical/recipes/` (dogfood). **Runtime note:** this is
the largest/slowest suite (~150 s); `run-all.sh`'s `timeout 300` covers it — do not
impose timeouts under 180 s when running it standalone.

### test-complexity-score.sh

**Target:** `canonical/scripts/execute/complexity-score.sh`

Regression suite added by **work-002 task-001** for the four correctness fixes in the
delivery-complexity scorer (find each via the `# A1`/`# A2`/`# A3`/`# A4` headers in
the suite):
- **A1 — Type matching:** both `**Type:**` (bold task-template form) and `- Type:`
  (flat recipe form) score risk.
- **A2 — portable awk:** extraction works under `mawk` (no gawk 3-arg `match`);
  leading-zero delivery-id matching is numeric (`003` == `3`).
- **A3 — lite/recipe specs:** a top-level `## Execution Graph` (no delivery wrapper)
  parses with `--delivery-id` not required and the `## Tasks` table not swallowed;
  a multi-delivery PLAN still scopes per delivery and requires `--delivery-id`.
- **A4 — cycle guard:** a cyclic / self-looping `Depends On` table terminates with
  exit 0; `— (none)` / `(none)` are treated as no-deps (lite-spec template form).

### test-compute-block-radius.sh

**Target:** `canonical/scripts/execute/compute-block-radius.sh`

Covers the BFS transitive-descendant computation used by the pool-dispatch failure
cascade: linear chains, diamonds, fan-outs, unrelated chains, mid-chain failure,
leaf-node (empty block-radius), multi-root fan graphs, end-to-end `--plan-file`
(PLAN.md parsing), a seeded-failure delivery-graph integration, error exits
(missing/conflicting args, file-not-found), whitespace normalization on
`--failed-task`, and the `state-execute.md` degradation-notice format.

### test-delivery-gate-aggregate.sh

**Target:** the delivery-gate logic in `canonical/scripts/execute/aid-execute`
(uses `writeback-state.sh` and `canonical/scripts/grade.sh` as collaborators)

Covers: AGGREGATE with an existing `delivery-NNN-issues.md` (deferred rows preserved);
AGGREGATE with no issues file (creates the empty log correctly); SCORE computation for
sample deliveries of varying complexity; grade computation via `grade.sh`
(deterministic output verification); the loopback guard (grade < min does not re-run
quick-checks; only loops review); and the FR6 interlock (the gate must not fire while
any task has status Failed or Blocked).

### test-fetch-mermaid.sh

**Target:** `canonical/scripts/summarize/fetch-mermaid.sh`

Covers the supply-chain pin + SHA-verification:
- **Scenario A** — tampered cache-hit rejection (a corrupted cached blob fails the SHA check).
- **Scenario B** — post-download bad-blob rejection via a `curl` PATH-shim returning a tampered payload.
- **Scenario C** — valid-cache fast path: no HTTP call is made when the cache is present and valid.
- **Scenario D** — `compute_sha256` unknown-fallback fails closed when neither `sha256sum` nor `shasum` is on PATH.

### test-grade.sh

**Target:** `canonical/scripts/grade.sh` (the top-level scorer — **unchanged** name)

Regression suite for the column-anchored severity-tag → letter-grade scorer: each
severity band maps to the correct letter + count modifier; only a Severity-column
`[TAG]` in a `Pending`/`Recurred` row counts (tags in Description/Evidence cells and
prose Summary lines are ignored — the cycle-7 false-positive guard); `--non-functional`
forces F; empty / zero-finding ledger → A+; and the deprecated `--from-prose` path still
parses (with fenced / inline-code stripping).

### test-validate-diagrams.sh

**Target:** `canonical/scripts/summarize/validate-diagrams.mjs` (Node). **Needs `node`.**

Covers the D1 regex sanity + invocation paths via `--fast`: no-args / `--help` /
missing-file → exit 2, zero-diagram warn-pass, valid `<pre>`/`<div>` diagrams, and D1
failures (directive-only, unrecognized type, empty block, mixed). D2 render is not
hermetic (needs jsdom/mermaid-cli) and is out of scope.

### test-contrast-check.sh

**Target:** `canonical/scripts/summarize/contrast-check.mjs` (Node). **Needs `node`.**

Covers WCAG AA contrast: usage exit 2, missing-file non-zero, hex-6 / hex-3 / `rgb()`
parse paths, low-contrast fail, unresolvable-vars skipped-not-failed, dark-theme
override extraction, and an integration check that the shipped `knowledge-summary.html`
passes.

### test-setup.sh

**Target:** `setup.sh` (the end-user installer)

Covers the installer's arg/precondition errors, interactive menu logic (Done / toggle /
invalid), per-tool installs across all **5** menu options (Claude Code=1 / Codex=2 /
Cursor=3 / GitHub Copilot CLI=4 / Antigravity=5; `[6] Done`), multi-tool install,
idempotent re-install ("Up to date"), and `--force` overwrite. New-provider cases:
**SU12** Copilot install (`.github/` tree + root `AGENTS.md`), **SU13** Antigravity
install (`.agent/skills` + `.agent/rules` + root `AGENTS.md`), **SU14** new-provider
files byte-identical to their `profiles/<tool>/` sources, **SU15** out-of-range rejected
(Done is now 6), **SU16** the Option-A AGENTS.md multi-install collision
(Codex+Copilot → `AGENTS_COLLISION=1`, last-installed/highest-numbered-block wins —
`GitHub Copilot CLI wins`, resolved non-interactively, installed `AGENTS.md`
byte-identical to Copilot's source), **SU16b** the guard does NOT fire for a single
AGENTS.md writer (no false collision), **SU17** new-provider idempotent re-install +
`--force`. The menu is driven via piped stdin; only the fresh / identical / `--force` /
non-interactive-collision (`AGENTS_COLLISION`) paths are exercised (never the
`/dev/tty` prompt). See `setup.sh` `tool_name()` / `print_menu()` and the
`AGENTS_COLLISION` collision block (the `_survivor` / `last-writer-wins` lines).

### test-assemble-3part.sh

**Target:** `canonical/scripts/summarize/assemble-3part.sh`
(renamed from the former `concatenate.sh`)

Covers byte-concat of PART1 + MERMAID + PART2 → OUTPUT: arg/input validation
(missing/empty input → exit 1), auto-created nested output dir, and byte-exact
concatenation + ordering.

### test-assemble-3part-ps1.sh

**Target:** `canonical/scripts/summarize/assemble-3part.ps1` (PowerShell mirror).
**Needs `pwsh`.**

Same contract as the `.sh` oracle, run under `pwsh`. Cross-platform (explicit paths +
byte I/O), so it runs fully on the Linux CI runner once `pwsh` is present.

### test-setup-ps1.sh

**Target:** `setup.ps1` (the Windows-host installer). **Needs `pwsh`.**

Only its platform-independent pre-install logic is exercised under `pwsh` on Linux:
target validation + the selection-menu loop. The backslash-path file copy is
Windows-only; the actual install coverage lives in `test-setup.sh`. New menu-parity
cases: **SPS05** menu lists 5 tools + `Done=6` (and names GitHub Copilot CLI +
Antigravity), **SPS06** toggle a new tool on/off (nothing installed), **SPS07**
out-of-range rejected with `Done=6`, **SPS08** collision-warning parity (Codex+Copilot →
`Note:` warning naming the AGENTS.md collision + `GitHub Copilot CLI wins`). This suite
**SKIPs (exit 0 with a `SKIP:` notice) when `pwsh` is absent** (established repo
contract; the suite's `command -v pwsh` guard) — so `setup.ps1` menu/collision parity is
code-read, not CI-executed, unless a `pwsh` runtime is present. CI's `canonical-tests`
job asserts `pwsh` IS present so this skip cannot silently fire there.

### test-housekeep-state.sh

**Target:** `canonical/scripts/housekeep/housekeep-state.sh`

Added by the **/aid-housekeep** skill. Covers the run-state I/O round-trip and the
`--resume` decision rule against the `## Housekeep Status` section of a run-state
fixture (the project-level `.aid/.temp/HOUSEKEEP_STATE_<ts>.md` file; find the scenarios
via the `Unit 1:`–`Unit 20:` header block in the suite) — including absent-file
tolerance (read→empty/exit 0; write creates the file):
`--read` on a file with no section → empty/exit 0; `--write` creates the section + field
line and is idempotent (replace, no duplicate); independent fields co-exist; all nine
C-2 fields round-trip write→read; the six `--resume` rows (PREFLIGHT → CLEANUP →
KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE) keyed on the KB/Summary/Cleanup stage
markers (stalled/running/`—`/passed/skipped); and error paths (missing `--state` →
exit 2, missing `--field` with `--read` → exit 2, missing `--value` with `--write` →
exit 2, STATE.md not found → exit 1).

### test-housekeep-branch-commit.sh

**Target:** `canonical/scripts/housekeep/branch-commit.sh`

Added by the **/aid-housekeep** skill. Exercises the branch-ensure + per-stage commit
helper against a throwaway git-repo fixture (`mktemp`, cleaned on exit), asserting the
**git safety guard** (find the scenarios via the `Unit 1:`–`Unit 9:` header block):
`--ensure-branch` on `master` creates an `aid/housekeep-<slug>` branch; re-running on an
existing `aid/housekeep-*` branch reuses it (resume); a non-master / non-housekeep
branch is **refused (exit 3)**; `--commit` on an `aid/housekeep-*` branch produces
exactly one commit; `--commit` on `master` without ensure-branch is **refused (exit 3)**;
the source file contains **no `git push`** (static assertion) and **no remote
interaction** occurs in any operation; combined `--ensure-branch` + `--commit` in one
invocation; and argument-validation errors (missing slug / message / etc.).

### test-housekeep-classify.sh

**Target:** `canonical/scripts/housekeep/cleanup-classify.sh`

Added by the **/aid-housekeep** skill. Verifies the scan + classify phase assigns
**cleanup tiers** correctly against a fixture `.aid/` tree (find the scenarios via the
`Unit 1:`–`Unit 13:` header block): S1 `.aid/.temp/**`, S2 `.aid/.heartbeat/**`,
S3 `.aid/knowledge/.cache/**` + `.manual-checklist.json` + `.spot-check-facts.txt`,
S4 stray `verify-deterministic-report.json` / `verify-advisory-report.json`, and S5
unregistered `.aid/generated/` output → **Tier-0 checked**; a registered `.aid/generated/`
output → **not emitted**; a loose hand-authored `.aid/` file → **Tier-2 unchecked**;
and protected/live files (`.aid/settings.yml`, `.aid/knowledge/*.md`) → **never emitted**;
empty `.aid/` → zero output lines.

### test-housekeep-workfolder-safety.sh

**Target:** `canonical/scripts/housekeep/cleanup-classify.sh` (work-folder safety rules)

Added by the **/aid-housekeep** skill. Tests the (i)/(ii) **work-folder safety decision
matrix** using throwaway git repos with a fake `origin/master` and `.aid/work-*/`
fixtures (find the scenarios via the `Unit 1:`–`Unit 10:` header block). Signal (i)
(merged-to-master) is exercised via the offline `git merge-base --is-ancestor` ancestry
fallback so the suite runs without network or `gh`; the gh-PR path is guarded by
`command -v gh` and SKIPs if absent. The (i)/(ii) signals are now **informational
context only** — they no longer gate whether a folder is offered. **Every** work folder
is offered (the user has the last word): (i)✓(ii)✓ → main checklist (gate=offer, default
unchecked); otherwise → gate=explicit-confirm (merged-but-not-concluded, or merge
unverified — unmerged SHA / no STATE.md / no PR-or-SHA). The single hard skip is the
work folder of the currently checked-out `aid/work-NNN-*` branch (signal (b)); the
`--active-work` caller exclusion is still honored. (Former exclusions (a) "carries
`## Housekeep Status`" and (c) "non-Deployed status" were removed.)

### test-housekeep-deletion-split.sh

**Target:** `canonical/scripts/housekeep/cleanup-classify.sh` (tracked/untracked split)

Added by the **/aid-housekeep** skill. Verifies the classify helper discriminates
**tracked vs untracked** paths via `git ls-files` / `git check-ignore` and re-asserts
the deletion-safety static guards (find the scenarios via the `Unit 1:`–`Unit 10:`
header block): a git-tracked path → `tracked`; a gitignored or uncommitted-and-not-ignored
path → `untracked`; a tracked-but-`.aid/.temp/` file → Tier-0 untracked (gitignore
precedence); the candidate `tracked` field matches the actual `git ls-files` result; a
`.aid/work-*/` directory is tracked when committed and untracked when not; and the script
source contains **no executable `rm`, `git rm`, `git commit`, or `git push`** calls
(deletion is the skill's job, not the classifier's).

### test-discovery-doc-ownership.sh

**Target:** `canonical/agents/discovery-scout/AGENT.md`, `canonical/agents/discovery-quality/AGENT.md`,
`canonical/skills/aid-discover/references/state-generate.md`.

Regression guard for discovery doc-ownership consistency. Verifies that exactly one
discovery agent "produces" each standard KB doc and that every agent's self-understanding
(Produce line + What-You-Don't-Do) agrees with the dispatch table in `state-generate.md`.
Key invariants: scout Produce line names `project-structure.md` and `external-sources.md`
(NOT `infrastructure.md`); quality Produce line names `infrastructure.md`, `test-landscape.md`,
and `tech-debt.md`; the dispatch table's `[5/5]` row assigns `infrastructure.md` to
`discovery-quality`. 14 checks (T01–T14).

### test-expectations-single-source.sh

**Target:** `canonical/skills/aid-discover/references/document-expectations.md`,
`canonical/agents/discovery-reviewer/AGENT.md`, `canonical/skills/aid-discover/references/reviewer-prompt.md`,
`canonical/skills/aid-discover/references/state-review.md`, `canonical/skills/aid-discover/references/state-fix.md`.

Guards the single-source invariant for per-doc expectations: `document-expectations.md`
is the sole file with per-doc `### *.md` blocks; `discovery-reviewer/AGENT.md` has zero
such blocks. Also guards reviewer-has-access invariant: the `{{DOCUMENT_EXPECTATIONS}}`
placeholder is present in `reviewer-prompt.md`, and `document-expectations.md` is named
in both `state-review.md` and `state-fix.md`. Verifies merge completeness (the file is
a superset containing `{reviewer_output_file}`, `project-structure.md`, and
`external-sources.md` blocks). 9 checks (T01–T09).

### test-doc-set-read.sh

**Target:** `canonical/skills/aid-discover/references/doc-set-resolve.md` (the
`resolve_doc_set` / `synth_default_seed` functions + all 4 accessors)

Covers the core doc-set resolve/accessor logic: unset `discovery.doc_set` → default seed
synthesized from templates; declared set → exact filename/owner/presence rows; all 4
accessors (`list-filenames`, `owner-of`, `owns-<agent>`, full TSV); inline `#` comment
stripping; comma-in-`when` shred behavior (fragment 1 survives as valid record; fragments
2+ with no pipe are warned and skipped); unknown owner → routes to `discovery-architect`
with a non-fatal warning; no `category` or `expectations` fields in any output; and the
dependency-free constraint (only bash+awk). 15 checks (T01–T15).

### test-doc-set-mapping.sh

**Target:** `canonical/skills/aid-discover/references/doc-set-resolve.md` + dispatch
mapping logic in `canonical/skills/aid-discover/references/state-generate.md`

Mechanical set-difference checks for the mapping-honors-declared-set invariant.
Covers: no-hang-on-omission (omitted doc excluded from owning agent's target list; declared
count lowers by 1); dispatch-on-addition (added doc in declared set → appears in owning
agent's list; count rises); carve-out-as-config (§1.4 fixture contains the renamed docs
`pipeline-contracts.md`, `schemas.md`, `repo-presentation.md` and excludes the old names
`api-contracts.md`, `data-model.md`, `ui-architecture.md`, `security-model.md`); and
non-software fixture (omission + custom addition vs default seed; user edits honored
verbatim). 15 checks (T01–T15).

### test-doc-set-propose-confirm.sh

**Target:** `canonical/skills/aid-discover/references/doc-set-resolve.md` +
`canonical/skills/aid-discover/references/state-generate.md` `### Step 0d`

Covers the propose→confirm flow behaviors per SPEC feature-004 §3.1 and §4:
default path (unset `discovery.doc_set` → resolved set equals default seed; accepting
default is a no-op — settings file remains without a `discovery.doc_set` section after
confirm); user-edit path (fixture with omission + addition → resolved set honors both
verbatim; count matches fixture entry count; omitted doc absent; added doc present).
Does not duplicate carve-out or non-software set-difference tests (those live in
`test-doc-set-mapping.sh`). 9 checks (T01–T09).

---

## Running

```bash
# Run every suite via the aggregator (from repo root; Git Bash on Windows)
bash tests/run-all.sh
bash tests/run-all.sh -v          # verbose — passes --verbose through to each suite

# Run one suite directly
bash tests/canonical/test-read-setting.sh
bash tests/canonical/test-read-setting.sh --verbose
```

**Windows note:** all suites are POSIX bash — run them from Git Bash, not PowerShell or
CMD. (The `*-ps1.sh` suites are themselves bash wrappers that *invoke* `pwsh`; they are
not run by PowerShell directly.)

Exit code: `0` = every suite passed, `1` = one or more failures (or no suites found).
Each suite prints a `FAIL:` line per failed assertion and the shared `test_summary`
(`Tests passed: N` / `Tests failed: M`) at the end.

CI is enforced: `.github/workflows/test.yml`'s `canonical-tests` job runs
`bash tests/run-all.sh` on every PR/push to `master` and is a required status check —
a PR cannot merge unless it is green. The same job pins `node` v20, pre-seeds the
SHA-verified Mermaid pin via `fetch-mermaid.sh`, and asserts both `node` and `pwsh`
are present so the node/PowerShell suites cannot silently skip.

---

## Coverage gaps and roadmap

The earlier inversion in this doc — which listed the PowerShell mirrors, the `.mjs`
validators, and the `setup.*` install flow as *untested* — is **wrong and now fixed**.
Those are all covered (closed under L2): `test-setup.sh`, `test-setup-ps1.sh`,
`test-validate-diagrams.sh`, `test-contrast-check.sh`, `test-assemble-3part.sh`,
`test-assemble-3part-ps1.sh`. The `/aid-housekeep` helpers
(`canonical/scripts/housekeep/`) are likewise covered by the five `test-housekeep-*.sh`
suites. The genuinely untested surface is the prompt-driven / orchestration layer:

- **Orchestration skills** (`/aid-discover`, `/aid-execute`, …) — prompt-driven and hard
  to test without an AI host. The `discovery-reviewer` sub-agent is the closest thing to
  integration verification, adversarially grading KB output each cycle.
- **The renderer** (`run_generator.py`) — its own VERIFY (deterministic) check runs at
  the end of every render and exits 1 on failure; not part of `tests/canonical/`. Its
  format emitters carry their own generator self-tests run by the CI `generator-selftests`
  job: `test_manifest_safety.py`, `test_copilot_emitter.py`, `test_antigravity_emitter.py`
  (all under `.claude/skills/aid-generate/scripts/`, invoked with `--self-test`).
- **Sub-agent definitions** — see `canonical/agents/*/AGENT.md`; verified by dogfooding.
- **Cross-tool consistency** (Claude Code vs Codex vs Cursor vs Copilot CLI vs Antigravity) —
  covered by the renderer's byte-identity assertion across the 5 profiles, not by a suite here.
- **End-to-end pipeline behavior** (Discover → Interview → Specify → Plan → Detail →
  Execute → Deploy → Monitor) — exercised by dogfooding (this repo IS the test suite for
  the methodology) rather than scripted E2E tests.
- **No coverage measurement** — statement/branch coverage of the canonical helpers is
  unknown.
- **bats migration** — the suites use the shared `assert.sh` counter pattern (not TAP).
  Migration to `bats-core` would enable parallel runs and standard TAP integration;
  deferred as low-priority.

---

## Adding a new suite

1. Create `tests/canonical/test-<helper-name>.sh` targeting `canonical/scripts/<path>/<helper>`.
   The `test-` prefix matters — `run-all.sh` discovers suites by the `tests/canonical/test-*.sh`
   glob, so a correctly-named suite is picked up with **no runner edit**.
2. `source` `tests/lib/assert.sh` (set `VERBOSE` first) and use its `pass`/`fail`/`assert_*`
   helpers; end with `test_summary` so the suite returns the right exit code.
3. Use `set -uo pipefail` (not `set -e`) so all failures are reported in one run.
4. Use `mktemp -d` + `trap 'rm -rf …' EXIT` for fixture cleanup.
5. If the suite shells out to `node` or `pwsh`, skip (exit 0 with a `SKIP:` notice) when
   the runtime is absent, mirroring the existing `.mjs` / `*-ps1.sh` suites.
6. Add the suite to the table in `tests/README.md`.
