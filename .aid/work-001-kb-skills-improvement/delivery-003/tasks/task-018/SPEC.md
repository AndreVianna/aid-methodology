# task-018: migrate-kb-frontmatter.sh -- propose/apply/dry-run/rollback migration script

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-003

**Depends on:** task-001 (delivery-001), task-003 (delivery-001), task-015 (delivery-002)

**Scope:**
- Create the shipped migration script `canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh`
  (ASCII-only bash; pure coreutils `awk`/`grep`/`sed`/`git` -- no LLM, no new runtime per NFR-8/C1).
  It mirrors the sibling `migrate-work-hierarchy.sh` flag shape: positional KB root `$1` plus
  `--propose` / `--apply` / `--dry-run` / `--rollback`.
- **Scope selection (SD-6 discipline).** Operate ONLY on the path passed as `$1` -- never scan
  `$HOME` or other works ([[aid-scan-tests-must-pin-home]]). In-scope docs = `kb-category:` in
  `{primary, extension}` AND `source:` **!= generated** (the widened predicate -- this covers the
  `host-tool-capabilities.md` `promoted from ...` edge so the corpus is total). Skip `meta` docs
  (`README.md`/`STATE.md`/`release-tracking.md`) and `source: generated` docs (`INDEX.md`/
  `project-structure.md`).
- **PROPOSE pass** (`--propose`, the default; writes nothing to docs): emit the worksheet
  `.aid/.temp/kb-migration-proposal.md` -- one section per in-scope doc with the mechanically-seeded
  `objective:` (collapsed `intent:`), `summary:` (first sentence of the collapsed `intent:`), and the
  **proposed `sources:` candidate list**, each candidate annotated by derivation ("from intent path
  ref" / "external URL" / "pure-synthesis -> sources: []"). Reuse f002's EXACT transforms from
  task-015's `build-kb-index.sh`: the `extract_literal` collapse (join-on-spaces + squeeze-whitespace)
  for `objective:`, and the bounded first-sentence predicate `[.!?](?=[ \t]+[A-Z]|$)` (whole line when
  no boundary; cut at first newline then 200-char cap with ASCII `...`) for `summary:`. Mechanical
  `sources:` candidates: (a) repo path refs grepped from the doc's `intent:`/`contracts:`
  (`[\w./-]+\.(sh|py|md|js|mjs|ts|yml|...)` + bare dir refs), (b) external URLs the doc cites, (c) a
  `sources: []` proposal for a genuine pure-synthesis doc.
- **APPLY pass** (`--apply`): read the (human-confirmed) `.aid/.temp/kb-migration-proposal.md` and
  write the confirmed `objective:`/`summary:`/`sources:` into each doc's frontmatter in f001 canonical
  order (`objective`/`summary`/`sources`/optional/`approved_at_commit`) above the retained legacy
  `contracts:`/`changelog:` block. Stamp `approved_at_commit:` = `git rev-parse --short HEAD` (7-40
  lowercase hex). **Retire `intent:`** (remove the literal block) ONLY after `objective:`+`summary:`
  are confirmed-present -- refuse to retire if either is empty (degrade-safe). Append a `changelog:`
  row recording the migration. Do NOT auto-populate `tags:`/`see_also:`/`owner:`/`audience:` (absence
  valid). If the worksheet is absent, APPLY refuses with a distinct exit code and directs the user to
  run `--propose` first (human confirmation is a HARD precondition of finalization, NFR-6/C4).
- **Idempotency.** Skip any doc that already carries `objective:` AND `summary:` AND a `sources:`
  **KEY** -- key on key-presence, INCLUDING the empty-list form `sources: []` (NOT on a non-empty
  value), so a correctly-migrated pure-synthesis doc (`external-sources.md`) is not re-seeded /
  re-stamped / double-`changelog:`-rowed every pass. A re-run over a fully-migrated KB is a clean
  no-op; a re-run over a partially-migrated KB migrates only the remainder.
- **`--dry-run`** (on `--propose` or `--apply`): print every action it would take, write nothing
  (the `migrate-work-hierarchy.sh` "DRY-RUN: would ..." pattern).
- **Backup + `--rollback`** (the NFR-7 safe/reversible exit; f011-NOVEL because the edit is in-place).
  Before APPLY modifies any doc, copy it to `.aid/.temp/kb-migration-backup-<UTC-timestamp>/<doc>.md`
  (gitignored transient tree). `--rollback` restores every doc from the most recent backup tree then
  removes that tree.
- **Verification pass before declaring success** (the precedent's Pass-4 analogue): re-read each
  migrated doc and shell out to `lint-frontmatter.sh` on it; fail loud (non-zero exit) pointing at the
  backup if any doc is not lint-clean. The migration and the lint share ONE definition of "migrated
  correctly."
- **Exit-code discipline.** Distinct non-zero codes for: bad/absent KB root; no in-scope docs;
  `--apply` with no confirmed worksheet; verification failure.
- Edit canonical only; re-run `python .claude/skills/generate-profile/scripts/run_generator.py`
  (the script must render to the 5 host trees + the repo `.claude/` copy, like its sibling) and commit
  the regenerated `profiles/` (render-drift green; [[render-drift-full-generator]]). If an emission
  manifest pins the `scripts/migrate/` list, update canonical + regen -- never hand-place ([SPIKE-M7]).
- **Boundary:** this task OWNS the migration script body. It does NOT author the frontmatter schema /
  soft-skip lint (f001, task-001), the INDEX format / collapse+first-sentence rules it reuses (f002,
  task-015 -- it consumes them), the spine STRUCTURE (f004, task-010), the canonical test suite
  (task-019), the lint scope-predicate widening / ASCII-guard wiring / AID-CI strict assertion
  (task-020), the glossary content migration (task-021), or the dogfood corpus run (task-022).

**Acceptance Criteria:**
- [ ] `migrate-kb-frontmatter.sh` exists under `canonical/aid/scripts/migrate/`, is ASCII-only bash,
  uses only coreutils (`awk`/`grep`/`sed`/`git`), and accepts positional KB root `$1` plus
  `--propose`/`--apply`/`--dry-run`/`--rollback`.
- [ ] In-scope selection is `kb-category in {primary, extension} AND source != generated`; `meta` and
  `source: generated` docs are skipped; it runs ONLY on `$1` and never scans `$HOME`.
- [ ] `--propose` writes `.aid/.temp/kb-migration-proposal.md` (one section per in-scope doc) with
  seeded `objective:` (collapsed `intent:`), `summary:` (first-sentence predicate), and annotated
  `sources:` candidates; it changes NO doc on disk.
- [ ] `objective:`/`summary:` are seeded with f002's EXACT collapse + `[.!?](?=[ \t]+[A-Z]|$)`
  first-sentence transforms (200-char cap, ASCII `...`) -- byte-consistent with task-015's render.
- [ ] `--apply` writes confirmed `objective:`/`summary:`/`sources:` in f001 canonical field order,
  stamps `approved_at_commit:` (`git rev-parse --short HEAD`), retires `intent:` ONLY when
  `objective:`+`summary:` are present, appends a `changelog:` row, and leaves optional fields absent.
- [ ] `--apply` refuses (distinct exit code) when the confirmed worksheet is absent.
- [ ] A doc carrying `objective:` AND `summary:` AND a `sources:` key (presence -- INCLUDING
  `sources: []`) is skipped; a re-run over a fully-migrated KB is a byte-identical no-op (no re-stamp,
  no double `changelog:` row), incl. a pure-synthesis `sources: []` doc.
- [ ] `--dry-run` on either pass writes nothing and prints the actions it would take.
- [ ] APPLY backs up each doc to `.aid/.temp/kb-migration-backup-<timestamp>/` before editing;
  `--rollback` restores byte-identity from the most recent backup tree and removes it.
- [ ] The verification pass shells out to `lint-frontmatter.sh` per migrated doc and exits non-zero
  (pointing at the backup) if any doc is not lint-clean.
- [ ] Distinct exit codes for bad KB root / no in-scope docs / unconfirmed worksheet / verify failure.
- [ ] Edit canonical only; `run_generator.py` re-run and regenerated `profiles/` committed
  (render-drift green); no rendered copy hand-edited.
- [ ] All section-6 quality gates pass.
