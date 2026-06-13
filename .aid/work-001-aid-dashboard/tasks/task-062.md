# task-062: aid-housekeep resolve `outdated` — re-stamp kb_baseline + repoint committed kb.html path (FR36)

**Type:** IMPLEMENT

**Source:** feature-007-kb-dashboard → delivery-009

**Depends on:** task-059, task-060

**Scope:**
- Land the FR36 housekeep portion (FF-A4, LC-A6, PR-A) in `canonical/skills/aid-housekeep/references/state-summary-delta.md` (+ the KB-DELTA / SUMMARY-DELTA commit `--add` paths). The SUMMARY-DELTA delegation **already** re-discovers + regenerates the summary; this task **adds** the baseline re-stamp + the committed-path repoint — **without** altering the existing KB-DELTA/SUMMARY-DELTA gates beyond that (LC-A6 MUST NOT).
- **Re-stamp `kb_baseline` (resolve `outdated`):** on a passed/refreshed KB, re-stamp `.aid/settings.yml kb_baseline.tip_date` to the current default-branch tip (DD-A4) so the card flips `outdated` → `approved` on the next reader poll (FF-A4). A re-stamp of `tip_date` **within an existing** `kb_baseline` block is the single-line **"Save in place"** replace (`aid-config SKILL.md:124`); if the block is absent (KB generated before task-061 ran) it **falls back** to the append-block path (`SKILL.md:126-132`) — same R13 idiom selection task-059 documents.
- **Repoint committed artifact path:** update `.aid/knowledge/knowledge-summary.html` → `<repo>/.aid/dashboard/kb.html` in the `branch-commit.sh --add` lists (and any other committed-path reference) so housekeep commits the relocated summary task-060 now produces (depends on task-060 for path consistency — different file, contract-coupled).
- Edits are **canonical/-authored** (rendered by task-063's FULL `run_generator.py` — NOT per-script, NOT vendor-refresh). **ASCII-only.** Behavior-additive (re-stamp + path repoint only). Edits `canonical/**` only; do NOT edit `.claude/**` here.

**Acceptance Criteria:**
- [ ] On a passed/refreshed KB, `aid-housekeep` re-stamps `.aid/settings.yml kb_baseline.tip_date` to the current default-branch tip (FF-A4) so a previously-`outdated` card resolves to `approved` on the next poll; the existing KB-DELTA/SUMMARY-DELTA gates are otherwise unchanged (LC-A6).
- [ ] The re-stamp uses the single-line "Save in place" replace inside an existing `kb_baseline` block (`aid-config SKILL.md:124`), falling back to the append-block path (`:126-132`) when the block is absent (R13) — consistent with task-059's documented selection.
- [ ] The committed-artifact path `.aid/knowledge/knowledge-summary.html` → `.aid/dashboard/kb.html` is repointed in the `branch-commit.sh --add` lists (consistent with task-060's relocation); a grep for `knowledge-summary.html` across `canonical/skills/aid-housekeep/**` returns zero hits.
- [ ] All touched canonical files are ASCII-only; no housekeep gate/decision beyond the documented re-stamp + path repoint is altered (behavior-additive).
- [ ] All §6 quality gates pass; the canonical edit is left to be dogfood-rendered by task-063 (this task does not run `run_generator.py` and does not modify `.claude/**`).
