# Work State -- work-011-kb-gitignore

> **State:** Executing — smart scope refinement applied + verified; on work-011 branch (folds into v2.0.4)
> **Phase:** Execute
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-07-05
> **User Approved:** yes

Scoped, user-approved lite enhancement, folded into the (not-yet-tagged) v2.0.4
release alongside work-010. Extends the two KB scanners
(`harvest-coined-terms.sh` + `build-project-index.sh`) beyond the static
`SKIP_DIRS` dir-prune so the KB scan tracks *real, hand-authored target-project
source* — while preserving the deterministic, byte-reproducible, cross-OS
contract that work-010 protects (no LLM in the scanner).

---

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** none (direct-prompt enhancement)
- **Updated:** 2026-07-05

---

## Triage

- **Path:** lite
- **Work Type:** enhancement
- **Sub-path:** LITE
- **Decision rationale:** Additive, deterministic scope refinement to two shipped scanners; no schema/contract change; folded into pending v2.0.4.
- **Override:** no

---

## What shipped (both scanners, lockstep)

Three deterministic exclusion layers, all git-native + machine-neutralized so the
harvest/index stay byte-reproducible across machines/OSes/AID-updates; each only
REMOVES from the enumerated set (order-independent); each is one batched process
(no per-file spawn):

1. **Expanded `SKIP_DIRS`** (always-on floor; works on non-git projects too):
   + `bower_components .history .venv venv .mypy_cache .ruff_cache .eggs
   .ipynb_checkpoints .cache .turbo .parcel-cache .svelte-kit .angular
   .pnpm-store coverage htmlcov .nyc_output Pods .dart_tool .terraform
   logs tmp temp .tmp .temp`. (`.vscode/.idea/.vs` were already present.)
2. **`.gitignore` filter** — `git -c core.excludesFile=/dev/null check-ignore
   --stdin` drops untracked-and-ignored files. `core.excludesFile=/dev/null`
   neutralizes the machine-specific global gitignore so only the *committed*
   `.gitignore` drives exclusions (reproducibility). Tracked files are never
   reported (committed source that matches a pattern still scans). git-repo-guarded.
3. **Smart file-level detection:**
   - `.gitattributes` **linguist-generated** + **linguist-vendored** via
     `git check-attr --stdin` (project-DECLARED). NOT **linguist-documentation** —
     the harvest *docs channel* mines prose for coined terms, so pruning docs
     would break it.
   - `@generated` / `DO NOT EDIT` / `DO NOT MODIFY` header markers (first 2 lines
     only). Uses a portable full-read `awk 'FNR<=2 && /marker/'` — NOT `nextfile`,
     which macOS awk lacks and would silently no-op there, breaking cross-OS
     byte-identity.
   - Minified bundles + sourcemaps: `*.min.js`, `*.min.css`, `*.map` (git-independent).

Non-git projects: the git-dependent layers no-op; `SKIP_DIRS` + minified/map
patterns still apply. `.github` deliberately NOT pruned (copilot-cli installs
under `.github/aid/` but `.github` is a standard project dir).

Rejected: LLM/agent judgment inside the scanner — it is non-deterministic
(model/version/run/date), which would reinstate the exact cross-update drift
work-010 fixed. If model-driven exclusion is ever wanted it must live in the
/aid-discover skill (agent already in the loop) behind a human-confirm gate, as a
separate design item — never in the byte-reproducible oracle.

---

## Verification (all green)

- **Exclusion** (git fixture exercising every layer): OLD build-index 15 noise
  lines → NEW 0; OLD harvest 17 → NEW 0; zero leakage.
- **No over-prune:** NEW keeps real source (src/app.ts), docs (docs/guide.md),
  code terms (Widget/Frobnication) AND a docs-channel term (DocChannelToken).
- **No-regression:** clean project (no noise) → NEW byte-identical to OLD for
  BOTH scanners, on git AND non-git roots.
- **Reproducibility:** exclusions derive only from committed inputs
  (.gitignore/.gitattributes/file headers/paths) + machine-neutralized globals →
  stable across machines/OS/AID-update (follows from exclusion + neutralization).
- **Lockstep:** `SKIP_DIRS` arrays byte-identical; the exclusion logic mirrored in
  both; a functional test asserts both scanners drop the same noise.
- **Tests:** new `tests/canonical/test-kb-scanner-exclusions.sh` 5/5 (E01-E05);
  existing `test-kb-scanner-scope.sh` still 5/5 after the SKIP_DIRS expansion.
  No existing fixture contains the new skip-dir names / minified / @generated, so
  nothing else changes.
- 5 profiles regenerated (VERIFY PASS) + 2 dogfood copies resynced.

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-05 | Work created | -- | Follow-on to work-010: respect .gitignore + smarter deterministic exclusion in the two KB scanners. User agreed .gitignore approach + fallback; expanded SKIP_DIRS (incl. logs/temp); chose deterministic "smart" detection (.gitattributes linguist / @generated / minified), NOT LLM-in-scanner (breaks determinism). Fold into the not-yet-tagged v2.0.4. |
| 2026-07-05 | Copilot PR #121 review resolved | -- | 5 comments, all valid, all addressed (commit a0b21ad7). (1-3) Sort locale: enumeration `find\|sort`, exclude `sort -u`, and `comm` ran under ambient LC_COLLATE → cross-machine order/comm-collation hole. Forced LC_ALL=C on every output-ordering sort/comm in both scanners (enum, exclude, comm, ranking, largest-files, notable), matching the pre-existing LC_ALL=C at harvest:492. Byte-identical no-op on C/C.UTF-8 (verified NEW==OLD on clean fixture); deterministic on dictionary-collation locales. (4-5) Overclaimed ".gitignore committed rules only": git check-ignore also reads per-clone $GIT_DIR/info/exclude (no override flag; empty by default). Corrected the wording (code comment + STATE) to name it as the sole residual; not worth reimplementing git's ignore engine. Re-verified: exclusions 5/5, scope 5/5, dogfood 571/0. 5 threads replied + resolved. |
| 2026-07-05 | Implemented + verified | -- | 3 layers added to both scanners (lockstep). Exclusion verified old-vs-new (0 noise in NEW, 15-17 in OLD); no-over-prune (source+docs+terms retained); no-regression byte-identical on clean git+non-git; reproducibility via committed-inputs-only + core.excludesFile=/dev/null; @generated uses portable full-read awk (no nextfile) for cross-OS identity. New test-kb-scanner-exclusions.sh 5/5; test-kb-scanner-scope.sh 5/5. 5 profiles regenerated + dogfood resynced. Pending: full suite + dogfood byte-identity → PR → tag v2.0.4. |
