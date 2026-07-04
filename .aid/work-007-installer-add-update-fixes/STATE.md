# Work State -- work-007-installer-add-update-fixes

> **State:** #7 harvest perf fix complete + verified; ready to re-push to PR #117 (v2.0.1)
> **Phase:** Execute
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-07-03
> **User Approved:** yes

Single state file for **work-007** — a lite-path bug fix hardening the AID installer
(`aid add` / `aid update` / bootstrap) so an in-place upgrade over an older install
produces a correct, consistent tree.

---

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** none (direct-prompt bug fix)
- **Updated:** 2026-07-03T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

---

## Triage

- **Path:** lite
- **Work Type:** bug-fix
- **Sub-path:** LITE-BUG-FIX
- **Sub-path (auto):** LITE-BUG-FIX
- **Decision rationale:** Three related installer defects with a shared root cause (in-place upgrade over an existing install under-applies); mechanical, well-scoped, no requirements interview needed.
- **Override:** no
- **Recipe:** none

---

## Root Cause

`aid add` (and every path through `install_tool` / `Install-AidTool`) treats an
existing project as if it were pristine. Three concrete failures observed in an old
repo upgraded via `aid add claude-code cursor`:

1. **Skip-on-diff copy.** `copy_file` / `Copy-AidFile` skip any destination that
   already exists and differs, unless `--force`. Over an old install, pre-existing
   skill files (old flat-path bodies) were silently skipped while new-path files
   (relocated `.claude/aid/` scripts/templates + brand-new skills) were written
   fresh — producing a mixed tree with stale flat-path skill prose. The skip is
   never reported in non-verbose output, so the CLI reported success.
2. **No `.aid/settings.yml` seeding.** The installer never creates the required
   `.aid/settings.yml`; it only appears if `/aid-config` is run — and with a stale
   flat-path aid-config that copy itself fails.
3. **No `.gitignore` management.** The installer never ensures AID's transient
   `.aid/` dirs are excluded from version control.

Bundles themselves are correct (`profiles/*/` are 100% nested, 0 flat). The defect
is entirely install-time behavior, not bundle generation.

---

## Issues & Fixes (this work)

| # | Issue | Fix | Files |
|---|-------|-----|-------|
| 1 | Skip-on-diff leaves AID-owned files stale on upgrade | Overwrite-on-diff for AID-owned files; `CLAUDE.md`/`AGENTS.md` stay force-gated via `_copy_root_agent_file` (unchanged) | `lib/aid-install-core.sh` (`copy_file`), `lib/AidInstallCore.psm1` (`Copy-AidFile`) |
| 2 | `.aid/settings.yml` never seeded | Seed-if-missing from `<root>/aid/templates/settings.yml`; never overwrite; not manifest-tracked | `install_tool` / `Install-AidTool` (+ `_root_dir` helper) |
| 3 | `.gitignore` AID exclusions not maintained | Marker-region (`# AID:BEGIN`/`END`) create/append/update-in-place; preserve user content | `install_tool` / `Install-AidTool` |
| 4 | Stale phase-model line in bundle root files (so `--force` writes wrong CLAUDE.md/AGENTS.md) | Sync the `Follow the current …phase` line inside the AID:BEGIN/END region to the current text | `profiles/{claude-code/CLAUDE.md, cursor\|codex\|copilot-cli\|antigravity/AGENTS.md}` |

Issue #4 root cause: root files are hand-maintained (render.py does NOT generate
them — 0 in emission manifest). work-001's phase-model correction updated the
repo-root CLAUDE.md but not the 5 profile root files, so they drifted. Confirmed
canonical phase text (SHORT version) with the user. **Process gap:** nothing syncs
repo-root ↔ profile root files; a future work should make the generator emit them
from one source (tracked as tech-debt, not fixed here).

| 5 | Stale `/aid-init` references (removed skill) | Replace with `aid-config` bootstrap / reconcile lists; canonical already clean | `.claude/skills/README.md`, `.claude/skills/generate-profile/SKILL.md`, `profiles/cursor/README.md`, `profiles/codex/README.md` |

| 6 | Redundant nested `aid/**/README.md` docs drift + clutter | Deleted 4 from `canonical/aid/**/` + 20 rendered copies (5 profiles) + 20 emission-manifest entries; render self-test passes (282 files) | `canonical/aid/{recipes,templates,templates/kb-authoring,templates/knowledge-base}/README.md`, `profiles/*/…/aid/**/README.md`, `profiles/*/emission-manifest.jsonl` |

Issue #6 notes (user decision "B"): `README.md` files are NEVER shipped (`release.sh`
excludes all `README.md` by basename; adopter installs never receive them, and
`_prune_tool_dirs` rule (c) auto-removes any legacy orphan under `aid/` on update).
So there was no adopter-facing staleness — only repo/dogfood doc drift. Removing the
4 nested READMEs from canonical eliminates the drift surface and makes the user's
working-tree deletions stick (render no longer re-emits them). Top-level
`profiles/<tool>/README.md` kept (repo-browsing docs, also unshipped).

Issue #5 notes: `.aid/.aid-manifest.json` match is a false positive (`mermaid-init.js`
contains the substring "aid-init"). Same hand-maintenance drift as #4 — only cursor
& codex READMEs had it; claude-code/antigravity/copilot-cli did not. **Broader
staleness flagged (NOT fixed here):** `.claude/skills/README.md` + the profile READMEs
still use old phase names (Init/Implement/Test/Track, duplicate "8.") and an outdated
skill taxonomy; a doc-reconciliation pass is warranted but is out of scope for this
installer bug-fix.

`install.sh` sources `aid-install-core.sh` and `install.ps1` imports
`AidInstallCore.psm1`, so all four entry points inherit the fixes from the two libs.

### Confirmed design decisions
- **Copy semantics:** AID-owned files always update on diff. Only `CLAUDE.md`/`AGENTS.md`
  (root-agent region-merge path) remain protected/force-gated.
- **settings.yml:** seed-if-missing, never overwrite, idempotent across multi-tool add,
  not recorded in the manifest (survives `remove`/prune; user data).
- **.gitignore managed set** (the AID region):
  `.aid/.temp/`, `.aid/.trash/`, `.aid/.heartbeat/`, `.aid/generated/`,
  `.aid/knowledge/.cache/`, `.aid/knowledge/.manual-checklist.json`,
  `.aid/knowledge/.spot-check-facts.txt`.
  NOT ignored (committed): `.aid/settings.yml`, `.aid/knowledge/`, `.aid/work-*/`,
  `.aid/.aid-manifest.json`.

---

## Open Questions

- **OQ-1 (gitignore borderline):** include tool-local settings
  (`.claude/settings.local.json` and `.cursor`/`.codex` equivalents) and/or
  `.aid/dashboard/` in the managed region? Default for now: NO (scoped to `.aid/`
  transient dirs per the request). Revisit if confirmed.

---

## Settings-seed detail (issue #2 refinement)

The raw template ships UNSTAMPED (no `format_version:`), and the settings-format
gate warns on every command without it (the bug T48's era-b synthesis fixed). So
the seed must STAMP `format_version` as the first line. Implemented: seed = template
copy + `format_version: ${AID_SUPPORTED_FORMAT:-1}` prepend (bash) / raw-byte prepend
(PS, for byte-identity). Create-if-missing; never clobbers. Verified bash↔PS output
byte-identical (settings.yml 69B, .gitignore 253B) so `test-install-parity.sh diff -r`
holds.

## Harvest performance fix (issue #7 — added to this PR, still v2.0.1)

User-reported: `/aid-discover` is unusable on Windows Git Bash / MSYS (~15-40 min or
hangs) on real brownfield repos (~1,400 files). Root cause diagnosed + measured in a
cygwin/MSYS bash here (same expensive `fork` class as Windows Git Bash):

1. **Subprocess-spawn explosion (CONFIRMED, dominant)** in
   `canonical/aid/scripts/kb/harvest-coined-terms.sh`. The main scan loop (`:422-527`)
   spawns ~10 grep/sed per file PLUS **per-token/per-match** shell subprocess loops:
   E2 CamelCase runs `split_camel` (`echo|sed`, def `:243`) + `echo|awk` capitalize
   (`:458`) per camel token; E4/E5 run `echo|wc -w` per match (`:473`,`:497`). AND the
   ranking loop (`:654-690`) spawns ~6-10 procs **per unique term** (class-detect greps,
   `word_in_denylist` grep, `split_camel`). Net: O(tokens + unique-terms) spawns.
   Measured: a per-match `echo|sed`+`echo|wc` loop over 2,000 matches **timed out > 2 min**.
2. **"Exponential regex backtracking" — NOT reproduced as stated.** E4 pattern via
   `grep -oE` ran 0.6 s on a 284 KB single line (GNU grep -E is DFA/linear). The prose-.md
   stall is root cause 1 (spawn storm on a match-dense long line). Kept as a DEFENSIVE
   requirement (linear matcher + no-hang test).
3. **`build-project-index.sh` — no change needed (ticket premise false).** Its only
   per-file spawn (`get_mtime`, `:212-215`) is in the BSD/macOS fallback. Windows Git
   Bash takes the GNU `find -printf` fast path (`:202`, already batched: single find +
   `xargs wc`); the remaining loops are pure-bash builtins (no spawns). The BSD per-file
   path runs ONLY on macOS, where `fork()` is cheap (~µs) — so the anti-pattern never
   lands on a slow-fork platform. Batching it would mean an UNTESTABLE change (no BSD
   `stat` here) to a working, non-bottleneck macOS path → regression risk for zero
   confirmed benefit. Left unchanged; rationale recorded (validate-the-premise).

**Fix (Design A, user-approved):** batched extraction — `find|sort` once; classify in one
awk pass; per-(channel,class) extraction via `rg` when available (fed the explicit file
list, so it scans exactly the `find` set), `xargs`-batched `grep` fallback; ALL
split/count/filter + denylist/salience/ranking moved into awk (zero per-token/per-term
spawns). rg's engine is linear (no backtracking). `split_camel` awk port verified
byte-identical to the sed impl on 926 real+synthetic tokens.

**Determinism guardrail:** rg and the fallback share identical awk post-processing +
identical file set → byte-identical output regardless of engine (protects "same repo on
Windows-with-rg vs Linux-without-rg"). `AID_HARVEST_NO_RG=1` forces the fallback; a CI
equivalence test asserts rg-on == rg-off byte-identical.

**Contract preserved:** `closure-check.sh:177-188` table parse (`| # | Source | Term | …`,
Source∈{harvest,synthesis}); 9-column table; `test-essence-capture` Spread/phrase/T06
byte-identical re-run. Scripts stay `set -euo pipefail` / ASCII / coreutils-first / rg optional.

Files: `canonical/aid/scripts/kb/harvest-coined-terms.sh` (+ renderer propagation to 5
profiles), `tests/canonical/test-harvest-batching.sh` (rg==grep equivalence + pathological
long-line no-hang) + `tests/canonical/fixtures/harvest-coined-terms/pathological-longline/`.
`build-project-index.sh` unchanged (see RC3). closure-check.sh unchanged (consumer).

**Verification (all green, measured on this cygwin/MSYS box — same slow-fork class as
Windows Git Bash):**
- Correctness — NEW output byte-identical to the ORIGINAL script (excl. Generated date):
  ultra-mini fixture + a git-repo fixture (exercises the history channel too). ✅
- Determinism — rg path == grep fallback, byte-identical, on ultra-mini + relative-bus +
  pathological long-line. The rg path was genuinely exercised with a REAL ripgrep 13.0.0
  binary (note: on this box `rg` is only a Claude Code shell *function*, so a naive run
  silently uses grep — validated by shimming the real @vscode/ripgrep binary onto PATH). ✅
- No hang on the pathological single-long-line fixture (both engines exit 0). ✅
- Contract — `test-essence-capture.sh` 8/8 (Relative Bus spread>=2, phrase class, closure
  closed/unclosed, T06 byte-identical re-run, isolation canary). `test-harvest-batching.sh`
  5/5. ✅  (Full `test-harvest-coined-terms.sh` is env-slow here — ~1s/spawn fork tax × 10
  harvest runs > 300s — but passes on CI's fast-fork Linux; byte-identity to the original
  proves its assertions hold.)
- Perf — the ORIGINAL took 138s on a 2-FILE fixture (fork storm); NEW ~27s, and NEW is
  O(fixed ~50 spawns) regardless of repo size (extraction is per-channel-class, not
  per-file; ranking + emit batched into awk). On a 1,400-file repo: minutes/hang -> ~tens of seconds.
- Propagation — `run_generator.py` re-rendered all 5 profiles; VERIFY (byte-identical
  re-render + file-presence + frontmatter) PASS; render-drift = ONLY the harvest script
  (+ its manifest sha) across the 5 trees; `bash -n` clean on canonical + all 5 copies.

## Testing & Verification

- **New fast regression tests** (source the lib directly; avoid the env-slow 282-file
  install path): `tests/canonical/test-install-provisioning.sh` (bash, 36 asserts) and
  `tests/windows/Test-InstallProvisioning.ps1` (PS parity). Both PASS. PS test wired
  into `installer-tests.yml` (pwsh + Windows PowerShell 5.1 lanes).
- **Updated integration assertions** for the new behavior: IN13i/IN13i2
  (`test-install.sh`), IN13i/IN13i2 (`test-install-ps1.sh`), T16c/T16c2
  (`Test-AidInstaller.ps1`) — `.aid/` + settings.yml PRESERVED across uninstall.
- render self-test PASS (282 files after README removal). `bash -n` + PS parse clean.
- Full install suites (test-install.sh etc.) are env-slow on this Windows box
  (~1.3s/file git-bash+Defender tax → 5-min timeout); they run fast on CI. Logic
  validated via the focused tests + static assertion review.

## Flagged (NOT fixed here — follow-ups)

- **Uninstall now PRESERVES `.aid/settings.yml`** (user config; standard npm/apt-style).
  If a "purge" (remove config too) is wanted, that's a separate change.
- **Settings-synthesis duplication:** era-b synth exists in `bin/aid` + `bin/aid.ps1`
  (from-scratch, minimal) AND now the lib seed (template+stamp). Both gate-valid;
  the lib seed runs first on add/update so era-b is the rare fallback. Consolidate later.
- **aid-config skill copies the raw (unstamped) template** → would reintroduce the
  format-gate warning if it seeds settings.yml before any install. Pre-existing; out of scope.
- **Uninstall leaves the `.gitignore` AID region** (harmless dangling patterns). Symmetric
  strip-on-uninstall is a possible follow-up.
- **Broader doc drift** in `.claude/skills/README.md` (now deleted by user) + profile
  READMEs (old phase names/taxonomy) — needs a doc-reconciliation pass.
- **Root-file sync gap:** nothing regenerates `profiles/*/{CLAUDE,AGENTS}.md` from a
  single source (root of issue #4).

## Release-hardening audit (v2.0.1 patch) — 3 parallel audits, findings verified

Scope approved by user: "Everything found." MONITOR-STATE.md left OUT (separate
design decision — deferred-vs-live contradiction, still pending).

Installer-correctness (bash+PS parity, all fixed + regression-tested):
- C1 is_aid_heading / Test-AidHeadingStem: added `Workflow` stem — fixes duplicate
  `## Workflow` on C2 (no-marker) migration. Regression: C1/C1b/C1c.
- C2 bash `manifest_write` rc now checked → aborts loudly (parity with PS throw).
- C3 gitignore CRLF divergence: bash now normalizes before compare → idempotent on
  CRLF, matches PS. Regression: GI5/GI5b.
- C4 copy_file/Copy-AidFile: copy failures counted + surfaced; install_tool aborts
  (no more partial-install-as-success). `_COPY_COUNT_FAILED` counter.
- C5 settings-seed: template-missing / temp-fail now WARN (no silent skip).
- C6 format-stamp: cross-reference comments across all 4 carriers (bin/aid,
  bin/aid.ps1, lib bash seed, psm1) so a future bump can't skew.
- C7 root-agent region awk: backslash-doubled before `-v` → escape-safe (PS already
  literal). No-op for today's backslash-free region.

Docs / dangling-references (same class as aid-init; all fixed):
- `setup.sh`/`setup.ps1` → `aid` CLI (`install.sh` bootstrap + `aid add <tool>`) in
  all 3 profile READMEs + Usage step.
- `render_agents/skills/templates.py` → `run_generator.py` in generate-profile/SKILL.md
  (RENDER mode rewritten) + site/maintainer.mdx (2 spots).
- `aid-README.md` dangling links removed from 3 READMEs.
- line-13 manual-copy paths given the `profiles/` prefix.
- Additional stale paths found+fixed: `.claude/templates/` → `.claude/aid/templates/`,
  `templates/scripts/*.sh` → `.claude/aid/scripts/*` (grade.sh, kb/build-project-index.sh).
- cursor README: stale phase-flow + Implement/Track/Discovery labels + state machine
  corrected to current model; contested `MONITOR-STATE.md` softened out.
- Created missing top-level READMEs for copilot-cli + antigravity (3/5 → 5/5).

Version: VERSION + package.json + pyproject.toml bumped 2.0.0 → 2.0.1 (tag v2.0.1).

Verification (all green): version-sync gate PASS; render-drift = run_generator +
git diff shows ONLY intended changes (no rendered-file drift); bash provisioning
41/41; PS provisioning all pass; render self-test PASS; bash -n + PS parse clean;
dangling-ref source sweep = 0 (remaining hits are gitignored build artifacts).

## MONITOR-STATE.md — resolved: DEFERRED (user decision 2026-07-03)

`aid-monitor` is still deferred; `MONITOR-STATE.md` is a planned/future artifact, not
live. aid-monitor currently uses an in-memory monitor context (SKILL.md:54) + the work
`STATE.md ## Calibration Log` (:162). Reconciled all SOURCE references to match:
- Canonical (shipped → regenerated into 5 profile mirrors): `aid-monitor/references/
  state-route.md` (record in the in-memory context, not the file), `aid-monitor/README.md`
  (marked deferred), `aid-describe/references/state-first-run.md`, `aid-orchestrator/
  AGENT.md` + `README.md`, `aid-developer/AGENT.md` (→ "aid-monitor finding").
- Docs/site: `docs/aid-methodology.md` (×5: table, Output, feedback-loops, artifact
  table, template header) + `docs/glossary.md`; same in `site/src/.../methodology.md`
  + `reference/glossary.md`.
- Verified: 0 live (non-deferred) `MONITOR-STATE` refs remain in canonical/docs/site or
  the profile mirrors; render-drift clean (only the 4 intended skill/agent areas changed).
- **KB NOT hand-edited:** `.aid/knowledge/pipeline-contracts.md` (5 refs) is flagged for
  the `/aid-update-kb` gate rather than edited directly (KB governance). Follow-up.

## Windows-local gate quirks (NOT regressions; pass on CI)

Two release gates report failure when run on THIS Windows/git-bash box but pass on
CI (Linux). Confirmed environment-only:
- **render self-test** — `T7 *.sh lost executable bit`: Windows filesystems carry no
  Unix exec bit; Linux CI preserves it. (render_profile itself PASSes T1-T6, T8.)
- **check-version-sync.sh** — `set -euo pipefail` + `node -p "require('/c/…')"`: node
  can't resolve a git-bash path in require(), throws, set -e exits. On Linux the path
  is native. Carriers verified equal directly: VERSION = package.json = pyproject = 2.0.1.
  (Pre-existing release-tooling quirk; a dev running the gate locally on Windows sees a
  false fail. Flagged; not fixed here — release runs on CI/Linux.)

Release-relevant checks that DO run green here: bash provisioning 41/41, PS provisioning
all pass, render-drift (run_generator + git diff) clean, bash -n + PS parse clean.

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-03 | Work created | -- | Lite bug-fix; scoped from diagnosis of old-repo upgrade |
| 2026-07-03 | Execute — 3 installer fixes + phase-line + aid-init + README cleanup | -- | copy overwrite-on-diff, settings seed (stamped), gitignore region; all validated (bash 36 / PS parity / byte-identical) |
| 2026-07-03 | PR #117 opened (work-007 → master) | -- | AndreVianna account; both Copilot inline comments answered (.aid/.aid-version + .aid-manifest.json bumped to 2.0.1 in f860cb44) |
| 2026-07-03 | CI fully green on PR #117 | -- | All gates pass: GitGuardian, KB+repo hygiene, build, generator self-tests, render-drift, visual-fidelity, installer/CLI (ubuntu 8m19s + windows 5m21s), canonical helper suites (12m11s). Only `deploy (Pages)` skips (merge-only). Ready to merge + tag v2.0.1. |
| 2026-07-03 | Issue #7 added to PR (harvest perf) | -- | Windows /aid-discover unusable (spawn-storm); root cause confirmed + RC2 corrected via measurement; Design A batched refactor approved. Same branch/PR #117, still v2.0.1 per user. |
| 2026-07-03 | Issue #7 implemented + verified | -- | Batched awk extraction (rg-optional, byte-identical grep fallback); new==orig + rg==grep byte-identical (incl history + pathological long-line, real ripgrep shimmed); essence 8/8, batching 5/5; 5 profiles re-rendered (VERIFY pass, drift = harvest only). build-project-index left unchanged (RC3). |
| 2026-07-04 | Issue #7 CI break (88b2c7ec) fixed | -- | canonical-suites failed on TWO of MY gaps (not the harvest logic; mawk was a wrong guess — read the log): (1) forgot to resync the dogfood repo-root `.claude/` after run_generator (test-dogfood-byte-identity DBI-FWD sha mismatch) → resynced from profiles/claude-code (f860cb44 precedent); (2) my new test-harvest-batching T03 asserted 'Relative Bus' which only surfaced via the AID repo's git history — CI's SHALLOW clone has ~none, so it dropped → rewrote T03 to harvest a scratch copy (no ambient history, like essence-capture) and assert on 'Quorum Pulse' (fixture-intrinsic, denylist-surviving, deterministic). Root lesson: verify under CI conditions (shallow clone + dogfood sync), not just local. |
