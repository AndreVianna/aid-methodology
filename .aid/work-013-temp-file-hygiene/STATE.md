# Work State -- work-013-temp-file-hygiene

> **State:** In Review (PR #123 ready)
> **Phase:** Execute
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-07-06
> **User Approved:** yes

User-approved hygiene refactor. `/aid-summarize` and `/aid-discover` write transient
scratch/build artifacts **into the Knowledge Base folder** (`.aid/knowledge/`) instead of
the dedicated gitignored scratch area (`.aid/.temp/`). This contaminates the KB directory
and risks poisoning KB scanners/grading -- the same failure class the work-010/011/012
fixes targeted. This work relocates every transient artifact to `.aid/.temp/summarize/`,
folds the durable user-confirmed term exclusions out of the KB dir into `.aid/settings.yml`
`discovery.term_exclusions` (mirroring `discovery.doc_set`), and fixes the one KB scanner
(`build-metrics.sh`) missing the hidden-dotfile guard its five siblings carry.

No behavioral change to KB content or to the generated visual summary (`.aid/dashboard/kb.html`);
only the *placement* of build/scratch inputs and the *storage* of term exclusions change.

---

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** none (direct-prompt refactor)
- **Updated:** 2026-07-06

---

## Triage

- **Path:** lite
- **Work Type:** refactor
- **Sub-path:** LITE-REFACTOR
- **Decision rationale:** Deterministic file-placement + config-schema refactor across two skills plus one scanner bug-fix; scope drawn from an aid-reviewer ledger; no change to KB content or summary output.
- **Override:** no

---

## Origin: review findings

Reviewed by `aid-reviewer` (ledger: `.aid/.temp/review-pending/temp-file-hygiene.md`, transient/gitignored).
**10 findings: 1 HIGH (real bug), 8 LOW, 1 MINOR.**

| # | Sev | Where | Issue |
|---|-----|-------|-------|
| 1 | HIGH | `build-metrics.sh:71` | Only KB scanner (of 6) missing `! -name '.*'`; ingests hidden `.term-exclusions.md` into the registered `metrics.md` inventory. |
| 2 | LOW | `spot-check-facts.sh:31` | `.spot-check-facts.txt` scratch written into KB dir. |
| 3 | LOW | `manual-checklist.sh:49` (+ `grade-summary.sh:71`) | `.manual-checklist.json` scratch written into KB dir. |
| 4 | LOW | `build-md-export.sh:64,67` | `md-export-payload.html` build intermediate in KB dir; **neither tracked nor gitignored** (accidental-commit risk). |
| 5 | LOW | `assemble.sh:43` | `summary-src/` workspace default `--src` points into KB dir. |
| 6 | LOW | `.aid/knowledge/summary-src/` | 25 git-tracked, rebuilt-every-run build files inside the KB dir. |
| 7 | LOW | `state-generate.md`, `state-manual-checklist.md`, `SKILL.md`, `state-validate.md` | Skill refs hardcode the KB-dir paths above. |
| 8 | LOW | `.aid/knowledge/.term-exclusions.md` | Tracked durable data as a hidden dotfile inside the KB dir. Owner decision: **relocate to `settings.yml discovery.term_exclusions`**. |
| 9 | MINOR | `harvest-coined-terms.sh:197` | `.coined-term-denylist.local.txt` same dotfile-in-KB smell. **Deferred** (differs: `.local` override, committed-vs-local semantics). |
| 10 | LOW | `.gitignore:53,55-57` + `cleanup-classify.sh` S3 | Dedicated maintenance surface that exists only to sweep KB-dir scratch S1 sweeps for free under `.aid/.temp/`. |

---

## Planned changes (improvements to the skills)

### Bucket 1 -- KB-scanner bug fix (HIGH; finding 1)
- `canonical/aid/scripts/kb/build-metrics.sh:71` -- add `! -name '.*'` to the KB-doc `find`, matching `build-kb-index.sh:476` and the four other scanners. Defense-in-depth (holds even after `.term-exclusions.md` leaves the KB dir).

### Bucket 2 -- `/aid-summarize` scratch -> `.aid/.temp/summarize/` (findings 2-7, 10)
- Script default output paths: `spot-check-facts.sh`, `manual-checklist.sh` (+ read in `grade-summary.sh`), `build-md-export.sh`, `assemble.sh` (`--src`) -> `.aid/.temp/summarize/` (build workspace at `.aid/.temp/summarize/summary-src/`); each `mkdir -p`s its dir.
- Skill references updated in lockstep: `state-generate.md` (SS5/SS7/SS8), `state-manual-checklist.md`, `SKILL.md`, `state-validate.md`.
- Move `.aid/knowledge/summary-src/` -> `.aid/.temp/summarize/summary-src/`; `git rm --cached` the 25 tracked files (now gitignored scratch under `.gitignore:69`).
- Delete now-dead maintenance surface: `.gitignore:55-57` and the `cleanup-classify.sh` S3 KB-scratch special-cases (S1 covers `.aid/.temp/`).
- **Fix-everywhere (found during sweep):** the installer libs `lib/aid-install-core.sh` (`_aid_gitignore_block`) and `lib/AidInstallCore.psm1` (`Get-AidGitignoreBlock`) hardcoded the two KB-dir dotfiles in the AID-managed `.gitignore` block; drop them (already covered by the `.aid/.temp/` entry) so a reinstall/update never re-adds them. Regenerate the block in the dogfood `.gitignore`.

### Bucket 3 -- term exclusions -> `settings.yml discovery.term_exclusions` (finding 8)
- Add `discovery.term_exclusions:` block-list to `.aid/settings.yml` (migrate the ~90 current terms); document as runtime-written in `canonical/aid/templates/settings.yml` (mirroring `doc_set`).
- Write path (`/aid-discover` Step 5c, `state-generate.md:903`): append confirmed terms under `discovery.term_exclusions` instead of appending to the `.md` file (mirror the `doc_set` write at `state-generate.md:404`).
- Read path (`state-closure.md:179`): `read-setting.sh --path discovery.term_exclusions --default '' | tr ',' '\n'` (comma-join is lossless -- no term contains a comma) replacing the `grep '^- '` on the file.
- Prose: `state-closure.md:52,171`, `SKILL.md:40`; delete `.aid/knowledge/.term-exclusions.md` (`git rm`).

### Propagation (CI-parity)
- `generate-profile` regenerates the 5 install trees from `canonical/`; resync repo-root dogfood `.claude/` from `profiles/claude-code/.claude/` (byte-identity gate).
- Update affected tests: `test-housekeep-classify` (retargeted), `test-kb-export` (trimmed); **remove** `test-diagram-content` and the `test-kb-export` fresh-build block (owner: remove, don't skip). Run the full affected set.

### Deferred (finding 9)
- `.coined-term-denylist.local.txt` -- handled separately; its `.local` override semantics (per-user, not committed) differ from the durable committed term exclusions, so folding it into `settings.yml` needs its own decision.

---

## Verification

- **Migration lossless:** `read-setting.sh --path discovery.term_exclusions` returns all 80 terms, byte-identical to the old `.md` read through the same downstream pipeline (`diff` empty).
- **Profiles regenerated:** `run_generator.py` re-rendered all 5 install trees; VERIFY (deterministic) PASS (byte-identical re-render + file-presence + frontmatter). No old paths remain in `profiles/`.
- **Dogfood resynced:** `test-dogfood-byte-identity.sh` — 571 passed, 0 failed.
- **Affected tests (local):** test-housekeep-classify 24/0 (Units 4/5 retargeted S3→S1), test-assemble-determinism 22/0, test-payload-size 11/0, test-kb-export (trimmed) green, test-read-setting 18/0, test-discovery-doc-ownership 13/0, test-install-provisioning 41/0, Windows Test-InstallProvisioning PASS. Removed: test-diagram-content, test-kb-export KB10-12.

## Test cleanup (owner decision: remove, don't skip)

Because `summary-src/` is now gitignored scratch, the **fresh-build re-validation** tests could
only skip in a clean CI clone (their inputs aren't committed). Per owner direction — "don't skip
quietly; remove the tests completely" — these were REMOVED, not skip-guarded:

- `test-kb-export.sh`: dropped the KB10-KB12 fresh-build block (rebuild kb.html from the real
  workspace) + its now-orphaned vars (`MANIFEST`, `SUMMARY_SRC`, `ASSEMBLE_SH`, `KB_DIR`). Kept
  KB01-08 (committed-kb.html static), KB20-24 (payload decode), KB25 (self-contained
  image-conversion fixture), KB30-31 (Playwright).
- `test-diagram-content.sh`: removed entirely — its whole purpose was validating the committed
  kb.html against the now-scratch manifest.

**Skip audit:** reviewed every skipping test in the suite. The remainder are legitimate
tool-availability gates (`pwsh` / `node` / Playwright absent) that correctly degrade on minimal
hosts — left intact (removing them would break those tests where the tool genuinely isn't present).

**Coverage note:** the removed `test-diagram-content` DC02/DC03 checks verified the diagram-content
gate FIRES on drift (stale phase label / deleted-skill token). That gate still runs at generation
time (`state-validate.md` §7 companion); only the standalone CI regression for it is gone. It can be
re-added as a fixture-based test (like KB25) if that regression is wanted back.

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-06 | Work created | -- | Direct-prompt refactor; branch `work-013-temp-file-hygiene`; scope from `aid-reviewer` ledger (10 findings) |
| 2026-07-06 | Implemented + verified | -- | Buckets 1-3 done; profiles regen + dogfood resync + tests green; pushed to PR #123 (draft) |
| 2026-07-06 | Test cleanup | -- | Removed dead fresh-build tests (test-diagram-content, test-kb-export KB10-12) per owner "remove don't skip"; skip audit done |
| 2026-07-06 | Ready for review | -- | Owner confirmed key name `discovery.term_exclusions` (underscore); PR #123 marked ready |
