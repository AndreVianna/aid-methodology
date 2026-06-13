# task-060: aid-summarize output relocation — .aid/knowledge/knowledge-summary.html → <repo>/.aid/dashboard/kb.html (9 verified files)

**Type:** IMPLEMENT

**Source:** feature-007-kb-dashboard → delivery-009

**Depends on:** —

**Scope:**
- Relocate the `aid-summarize` output (FR31, LC-A4, PR-A) from `.aid/knowledge/knowledge-summary.html` to **`<repo>/.aid/dashboard/kb.html`** — the path d008's multi-repo server already routes at `/r/<id>/kb.html` (SEC-A2; the `kb.html` leaf is one of feature-010's fixed `{home.html, kb.html}` static-leaf allowlist). The summary's **content / visual family is unchanged** (NFR8) — only the path moves. `.aid/dashboard/` is created if absent.
- Edit the **9 verified files that name `knowledge-summary.html`** (PR-A exact list): `canonical/skills/aid-summarize/SKILL.md`, `canonical/skills/aid-summarize/README.md`, and the **7 references** `canonical/skills/aid-summarize/references/{state-done,state-writeback,state-validate,state-approval,state-generate,state-stale-check,state-manual-checklist}.md`.
- Three reference-classes to repoint in those files:
  1. the **output path** itself (`.aid/knowledge/knowledge-summary.html` → `.aid/dashboard/kb.html`) at every occurrence;
  2. the **"open … in a browser" hand-off** (`state-done.md:21`) → point at the new location;
  3. the **STATE writeback `**Output:**` path** (`state-writeback.md:19`) and any committed-path / `branch-commit.sh --add` reference → the new location.
- **No phase / gate / decision change** beyond the output path + the hand-off/STATE-writeback text (LC-A4 MUST NOT): the summarize state machine (PREFLIGHT → … → APPROVAL(V1) → WRITEBACK → DONE) and its V1 visual-approval gate are untouched.
- Edits are **canonical/-authored** (rendered by task-063's FULL `run_generator.py` — NOT per-script, NOT vendor-refresh). **ASCII-only** (the path string is ASCII). Behavior-additive at the contract level (path move only). Edits `canonical/**` only; do NOT edit `.claude/**` here.

**Acceptance Criteria:**
- [ ] All **9** named files repoint `knowledge-summary.html` → `kb.html` at every occurrence of the output path, the browser hand-off (`state-done.md:21`), and the STATE writeback `**Output:**` line (`state-writeback.md:19`); a grep for `knowledge-summary.html` across `canonical/skills/aid-summarize/**` returns **zero** hits.
- [ ] The new path is exactly `<repo>/.aid/dashboard/kb.html` (the d008-served `/r/<id>/kb.html` leaf); `.aid/dashboard/` is created if absent at write time.
- [ ] The summary content / visual family (Mermaid inlining, self-contained HTML, NFR8 style) is unchanged — only the output path and its references move; no summarize phase, gate (incl. V1), or decision changes (LC-A4).
- [ ] All touched canonical files are ASCII-only; the edit changes the output path/references only (behavior-additive at the contract level).
- [ ] All §6 quality gates pass; the canonical edit is left to be dogfood-rendered by task-063 (this task does not run `run_generator.py` and does not modify `.claude/**`).
