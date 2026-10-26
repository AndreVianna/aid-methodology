# task-031: Copied and generated pages made hand-written, manifest rows removed

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** feature-005-machinery-cut -> delivery-003 -> AC-1, AC-6

**Depends on:** task-030

**Scope:**
- Feature 005 § Feature Flow step 4, page bullets (all under `site/src/content/docs/`):
  - Remove the `sourceDoc:` frontmatter line from the four pages `sync-docs.mjs` copied from `docs/`:
    `concepts/methodology.mdx`, `concepts/faq.md`, `reference/repository-structure.md`,
    `reference/glossary.md`. Nothing else in them changes; the `docs/` originals stay untouched.
  - In `reference/kb.md`, remove the `generatedFrom:` frontmatter line and the comment line
    `<!-- generated — do not edit; ... -->`; the page is hand-written from now on.
  - In `reference/artifacts.md`, delete the "Sync manifest" and "Reference manifest" table rows (they name
    `site/scripts/.synced-manifest.json` and `site/scripts/.reference-manifest.json`, deleted by task-030). If no
    row is left in that table, its `## Generator artifacts (manifests)` heading, its intro sentence and its table
    header go with them, since an empty table states nothing true (Feature 001 rule P5: describe what is true
    now); any link to that section's anchor is updated in the same change.
- In `.aid/works/work-005-site-rework/site-audit.md` § Pages, update the rows of these six pages in the same
  change (PLAN.md delivery-003 Notes, item 4; Feature 001 § Data Model, "Verdict"): one sentence per change in
  the Correction cell, naming the source that proved it (for `reference/artifacts.md`: the two manifest files no
  longer exist under `site/scripts/`; for `reference/kb.md`: it is now hand-written); a verdict of `ok` becomes
  `corrected`.
- Not touched: any other page; generated pages (Feature 002); `src/content.config.ts` (task-030); the page text
  beyond the named lines.
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/` or `docs/`; no change to any path
  outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than the six pages and `site-audit.md`.

**Acceptance Criteria:**

Run from `site/` unless stated. Let `D=src/content/docs`.

- [ ] FR-7 (delivery-003 gate): `grep -rln "sourceDoc\|generatedFrom\|release-data\|skill-flows" src astro.config.mjs`
  prints nothing.
- [ ] `kb.md` hand-written: `grep -c 'generated — do not edit\|generatedFrom' $D/reference/kb.md` prints `0`.
- [ ] Manifest rows gone: `grep -c 'Sync manifest\|Reference manifest\|synced-manifest\|reference-manifest' $D/reference/artifacts.md`
  prints `0`; `grep -rn 'generator-artifacts' src` prints nothing unless the section still has rows.
- [ ] Only the named lines changed (accuracy verified against the current tree, DOCUMENT default): before this
  task's commit, from the repo root,
  `git diff -U0 -- site/src/content/docs | grep -E '^[-+][^-+]'` shows only removed lines (each a `sourceDoc:`,
  `generatedFrom:` or `generated — do not edit` line, or a line of the manifest table/section) and, if a link to
  the removed anchor existed, its replacement; `git diff --name-only -- docs` prints nothing.
- [ ] Build (AC-1): `npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] Links (AC-6, by command): after the build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing.
- [ ] Audit rows (in the patterns, each `.` around a path stands for the backtick the audit row puts there):
  `A=../.aid/works/work-005-site-rework/site-audit.md; for p in concepts/methodology.mdx concepts/faq.md reference/repository-structure.md reference/glossary.md reference/kb.md reference/artifacts.md; do grep -E "^\| .src/content/docs/$p. " "$A" | grep -cE '\| (corrected|new) \|'; done`
  prints `1` six times; `grep -E '^\| .src/content/docs/reference/artifacts\.md. ' "$A" | grep -ci 'manifest'` prints
  `1`; the AC-3 completeness check of Feature 001 § Data Model prints nothing for these six paths.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical docs` prints nothing; before this task's
  commit, `git status --porcelain --untracked-files=all site .aid/works/work-005-site-rework/site-audit.md`
  lists only the six pages and `site-audit.md`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
