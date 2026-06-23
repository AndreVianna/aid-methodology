# Skill-Change Propagation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (ship side of FR-26/FR-27) | /aid-interview |

## Source

- REQUIREMENTS.md §5.G (FR-26, FR-27 — ship/propagation side)
- REQUIREMENTS.md §1.6/§1.9 (canonical→render ethos), C3 (canonical→render single source), C6 (content-isolation), C7 (KB-hygiene CI), NFR-4 (conventions-fit)
- §4 S7, §10 (Should)

## Description

Renaming `aid-ask → aid-query-kb` and adding `aid-update-kb` (f008) is not a
single-file edit — in AID a skill change ripples across the whole canonical→render
machinery, and this feature owns that propagation so nothing is left stale. It
covers: rendering the changed/new skill from `canonical/` into the **five host
trees** (claude-code, codex, copilot-cli, cursor, antigravity) with render-drift CI
green; **orphan-pruning** the retired `aid-ask` content by prefix from all trees;
keeping the **five install manifests in lockstep** on the new skill file set;
reconciling the **~10 KB-doc "N user-facing skills" count references** that a
skill rename/add leaves stale; and updating the **docs site** to match.

This is the ship-side counterpart to f008's author-side definitions. It exists as a
separate feature because the cross-tree/manifest/count-drift propagation is a
distinct, CI-guarded class of work (the known "adding a skill → KB count drift" and
"render-drift full generator" hazards) that must be done in lockstep or CI fails.

## User Stories

- As an **AID maintainer**, I want the skill rename/add rendered into all five host
  trees with the retired skill orphan-pruned so that render-drift CI stays green and
  no stale `aid-ask` content lingers.
- As an **AID adopter**, I want the five install manifests in lockstep on the new
  skill file set so that every install channel ships the correct skills.
- As an **AID maintainer**, I want the ~10 KB-doc skill-count references and the docs
  site reconciled so that the documented skill inventory matches reality.

## Priority

Should

## Acceptance Criteria

- [ ] Given the f008 skill rename/add, when the full generator runs, then the
  changed/new skill is rendered into all five host trees and render-drift CI is
  green. *(ship side of FR-26/FR-27, C3, NFR-4)*
- [ ] Given the retired `aid-ask`, when propagation runs, then its content is
  orphan-pruned by prefix from all trees and the five install manifests are updated
  in lockstep. *(C6, AC12 conventions)*
- [ ] Given the skill rename/add, when reconciliation runs, then the ~10 KB-doc
  "N user-facing skills" count references and the docs site are updated, and
  KB-hygiene CI passes. *(C7, AC12)*

> Cross-cutting note: this is the propagation half of AC12 (conventions &
> canonical→render with render-drift + KB-hygiene CI green). Pairs with f008.

---

## Technical Specification

> **Ship/propagation feature** — the cross-tree/manifest/count/docs half of the
> `aid-ask → aid-query-kb` rename + new `aid-update-kb` skill. **f008 owns the
> canonical-source behavior** (consumed here as final, not re-spec'd); **f009 is pure
> mechanical propagation**: it runs the existing generator to re-render `canonical/skills/`
> into the 5 host trees, lets the emission-manifest deletion pass orphan-prune the retired
> rendered `aid-ask/` dirs, re-bundles via the existing release/vendor machinery, reconciles
> the "N user-facing skills" count across the KB docs and the docs site, and so turns the
> f008 branch's **RED render-drift into green**. **No new infrastructure** — every surface
> reuses machinery that already exists (`run_generator.py`, the per-tree
> `emission-manifest.jsonl`, `release.sh`, `gen-reference.mjs`, `build-kb-index.sh`). Every
> surface below is grounded against a file/line on disk; genuine unknowns are flagged
> **[SPIKE]**, not guessed.

### Overview

A skill rename/add in `canonical/` is a single edit at the source, but the shipped artifact
is **rendered, bundled, counted, and documented** in many places. f009 walks every such
surface in lockstep so the repo never ships a half-renamed skill set. The net set change f009
propagates is:

- **`aid-ask` → `aid-query-kb`** (rename; net **+0** skills),
- **`aid-update-kb`** added (net **+1** skill),
- so the **user-facing skill count goes 12 → 13** (`aid-query-kb` is user-facing exactly as
  `aid-ask` was; `aid-update-kb` is a new optional off-pipeline maintenance skill — the same
  user-facing class as `aid-housekeep`). So **user-facing skills go 12 → 13**, and the
  **maintainer-inclusive total goes 13 → 14** (12 user-facing + the excluded maintainer-only
  `generate-profile`); **optional skills go 5 → 6**. The `canonical/skills/` *directory* count
  goes **12 → 13** (all 12 dirs are user-facing; `generate-profile` lives in `.claude/skills/`,
  not `canonical/`) — surfaces that count canonical dirs take **13**, not the maintainer-inclusive
  14. Every count instruction below states which population it counts (user-facing vs.
  canonical-dirs vs. maintainer-inclusive total) so no surface gets the wrong number.

f009 is driven by **one decision**: *re-render from canonical and let the existing machinery
do the rest, then hand-fix the surfaces the machinery does NOT auto-derive* (the docs-site
hard-coded map/count and the KB prose counts). The disk grounding below establishes precisely
which surfaces auto-derive (render trees, release tarballs, INDEX.md) and which are hand-listed
(`gen-reference.mjs` `SKILL_GROUPS` + intro count, the ~10 KB-doc counts).

**Confirmed grounding (verified against disk, not assumed):**

- **Skills are auto-globbed at render**, not hard-listed. `render.py:538`
  (`skill_dirs = sorted(d for d in src_dir.iterdir() if d.is_dir())`) enumerates
  `canonical/skills/*` by directory iteration — so renaming/adding a canonical skill dir is
  picked up automatically on the next `run_generator.py`.
- **The orphan-prune is real and deletes a removed skill's rendered tree.** `run_generator.py`
  lines 43-60 run a deletion pass: it diffs the current emission manifest against the previous
  one (`manifest.diff(prev_manifest)` → `removed`), `target.unlink()`s every removed `dst`, then
  prunes now-empty parent dirs (`parent.rmdir()` up to `common_parent()`). Each rendered skill
  file is a manifest record, e.g.
  `{"dst": ".claude/skills/aid-ask/SKILL.md", "src": "canonical/skills/aid-ask/SKILL.md"}`
  (`profiles/claude-code/emission-manifest.jsonl`). After the rename, `aid-ask/SKILL.md` is no
  longer emitted ⇒ it's in `removed` ⇒ unlinked ⇒ the now-empty `.../skills/aid-ask/` dir is
  rmdir'd. **This is the mechanism that retires the orphaned rendered dir — no manual `rm`.**
- **The 5 "install manifests" = the 5 per-profile release tarballs**, and their file list is
  **auto-enumerated from the rendered `profiles/<host>/` tree** (`release.sh:245-258` —
  `find "${src_path}" -type f` over each install root, excluding only `README.md` /
  `emission-manifest.jsonl`). So once the render+prune updates `profiles/`, the tarballs ship
  the new set automatically; **no hard-coded skill list exists in the packaging path.**
- **The npm/pypi `vendor.js`/`vendor.py` scripts vendor only the CLI installer**
  (`bin/`, `lib/`, `dashboard/` — `packages/npm/scripts/vendor.js:41-61`), **not the skill
  set.** The skill set ships exclusively via the per-tool release tarballs the installer
  downloads. So **npm/pypi vendor scripts are NOT a propagation surface for this change** (an
  explicit non-surface, recorded so the "5 install manifests" intuition isn't mis-aimed at the
  package vendors).
- **The docs-site skill map + intro count are hard-coded.** `gen-reference.mjs` has a
  hand-authored `SKILL_GROUPS` array naming `aid-ask` (line 126) and a hard-coded intro
  string `'AID ships **12 user-facing skills** ...'` (line 153) — neither is computed from the
  skill dirs, so both need a manual edit + regenerate.
- **`INDEX.md` regenerates cleanly.** It is keyed on per-doc frontmatter, not skill names —
  `grep aid-ask .aid/knowledge/INDEX.md` returns nothing — so `build-kb-index.sh` produces a
  correct INDEX with no skill-specific edit. (The kb-hygiene CI INDEX-fresh check is satisfied
  by regenerating it; see CI sequence.)

**Boundaries (what f009 does NOT do).**

- **f008 owns canonical-source.** The renamed `canonical/skills/aid-query-kb/SKILL.md` and the
  new `canonical/skills/aid-update-kb/` (SKILL.md + `references/state-*.md`) are **consumed
  final** by f009's render. f009 edits **no `canonical/skills/` content** — if it did, it would
  re-spec f008. The only `canonical/` thing f009 runs against canonical is the
  *render generator reading it*.
- **No new runtime, no new infra.** Every step reuses an existing tool. f009 invents no script,
  no manifest format, no CI job.
- **No behavior/state-machine work** — that is entirely f008.

---

### Part 1 — Render + orphan-prune (the RED→green core)

**One command does the render and the prune:**

```
python .claude/skills/generate-profile/scripts/run_generator.py
```

This (per `run_generator.py`) iterates the 5 profiles (`profiles/*.toml` →
claude-code, codex, cursor, copilot-cli, antigravity), and for each:

1. **Loads the previous manifest** `profiles/<host>/emission-manifest.jsonl`.
2. **Renders** `canonical/` → `profiles/<host>/<root_dir>/` (`render_profile`). Because skills
   are dir-globbed (`render.py:538`), this **emits the renamed `aid-query-kb/SKILL.md` and the
   new `aid-update-kb/SKILL.md` + `references/state-*.md`** into every tree, and **stops
   emitting `aid-ask/SKILL.md`** (its canonical dir is gone).
3. **Deletion/orphan-prune pass** (`run_generator.py:43-60`): diffs the freshly-built manifest
   against the previous one; the old `…/skills/aid-ask/SKILL.md` record is in `removed`, so the
   pass `unlink()`s it and then `rmdir()`s the emptied `…/skills/aid-ask/` directory in each of
   the 5 trees.
4. **Rewrites** `profiles/<host>/emission-manifest.jsonl` to the new set, and runs the
   deterministic + advisory verifiers.

**The 5 host trees and their rendered skill roots** (grounded — `grep aid-ask profiles/`):

| Profile | Install root | Rendered skill path (old → retired / new) |
|---------|--------------|--------------------------------------------|
| claude-code | `.claude/` | `.claude/skills/aid-ask/` → pruned; `…/aid-query-kb/`, `…/aid-update-kb/` emitted |
| codex | `.codex/` | `.codex/skills/aid-ask/` → pruned; new dirs emitted |
| cursor | `.cursor/` | `.cursor/skills/aid-ask/` → pruned; new dirs emitted |
| copilot-cli | `.github/` | `.github/skills/aid-ask/` → pruned; new dirs emitted |
| antigravity | `.agent/` | `.agent/skills/aid-ask/` → pruned; new dirs emitted |

**[SPIKE-A] Empty-parent prune climbs only to `common_parent()`.** The `while parent != common`
loop (`run_generator.py:54-60`) rmdir's `…/skills/aid-ask/` once empty (the SKILL.md was its
only child), then stops because `…/skills/` still holds the other skill dirs. This is exactly
the desired behavior for the rename (single-file skill dir). **The one thing to verify on the
actual run:** `aid-update-kb` is a **multi-file** skill (`SKILL.md` + `references/state-*.md`),
which is a *new* dir with new records — purely additive, no prune interaction. And `aid-ask`
today is **single-file** (confirmed by f008: the canonical `aid-ask/` holds only `SKILL.md`),
so its rendered dir prunes cleanly. **Verification: after the run, `find profiles -path
'*/aid-ask/*'` MUST be empty and `find profiles -path '*/aid-query-kb/*'` /
`'*/aid-update-kb/*'` MUST be present in all 5 trees.** (Treated as a verify-on-run check, not
an open design question — the mechanism is proven; the run confirms it for this specific
single→none + new-multi-file case.)

**Render-drift CI greens only after this run is committed.** `.github/workflows/test.yml`
`render-drift` job (line 24-40) runs `run_generator.py` then fails if `git diff -- profiles/`
is non-empty. On the f008 branch, `profiles/` still has the old `aid-ask/` trees and no
`aid-query-kb`/`aid-update-kb` ⇒ the job's own generator run produces a diff ⇒ **RED by
construction**. f009 commits the regenerated `profiles/` (+ updated manifests) ⇒ the CI's
generator run is a no-op ⇒ **green**. This is the literal RED→green this feature owns.

---

### Part 2 — The 5 install manifests (release tarballs)

**No hand-listed skill set exists in the packaging path** — so this surface is **carried for
free** by Part 1's `profiles/` regeneration, but the verification belongs here.

- `release.sh` Step-4 (`build_tarball`, lines ~225-269) builds one
  `aid-<tool>-v<VER>.tar.gz` per profile by `find`-ing every file under the rendered install
  root(s) (`profiles/<host>/.claude` etc.), excluding only `README.md` /
  `emission-manifest.jsonl`. The renamed/new skill files are picked up automatically; the
  pruned `aid-ask/` files are simply absent.
- `release.sh` Step-2 (lines 158-171) **itself runs `run_generator.py` and fails the release if
  `git diff -- profiles/` is non-empty** — i.e. release.sh re-asserts the same render-drift
  guard, so a release literally cannot be cut with stale rendered trees. This is the build-time
  twin of the CI gate.
- **npm/pypi package vendors are not touched** (they ship the CLI installer, not skills — see
  Overview). Recorded as a deliberate non-surface.

**The dogfood self-install is a separate surface (Part 5).** This repo's *own* installed
`.claude/skills/aid-ask/` tree and its `.aid/.aid-manifest.json` (line 394
`".claude/skills/aid-ask/SKILL.md"`) are the AID-on-AID dogfood install, **not** a render
target and **not** gated by render-drift CI. Handled in Part 5.

---

### Part 3 — Skill-count reconciliation (the known KB-count-drift class)

This is the `adding-skill-kb-count-drift` hazard (memory note; Q26/Q30 precedent): a
rename/add leaves "N user-facing skills" counts stale across ~10 KB docs, and **kb-hygiene CI
does NOT catch it** (the kb-hygiene job checks only CRLF, `.aid/.temp/` gitignore, and
INDEX-freshness — `test.yml:98-130` — never the skill count). So the count reconciliation is a
**correctness obligation enforced by this spec's enumeration**, not by CI. It must be
**exhaustive**. The net change to apply everywhere — **stated per population so no surface gets
a wrong number**: **user-facing 12 → 13**, **maintainer-inclusive total 13 → 14**,
**`canonical/skills/` dir count 12 → 13**, **optional 5 → 6**, `aid-ask` → `aid-query-kb` in
every enumeration, and `aid-update-kb` added as a new optional off-pipeline maintenance skill.
Each row below names which population the line counts (user-facing vs. canonical-dirs vs.
maintainer-inclusive total).

**Count + `aid-ask`-reference surfaces to reconcile** (grounded via
`grep -rn "user-facing skill" .aid/knowledge/` and `grep -rn aid-ask .aid/knowledge/`; the
Change-Log/history lines are append-only — add a new dated entry, do **not** rewrite past cycle
rows):

| # | File | Line(s) | What to change |
|---|------|---------|----------------|
| 1 | `.aid/knowledge/architecture.md` | 14, 42, 47, 49, 69, 174, 177, 192, 196, 442, 448 | "Twelve/12 user-facing skills"→**13 (user-facing)**; **l.69 "12 skill dirs"→13** — this line counts `canonical/skills/` *directories* (`← 12 skill dirs`), so it takes the **canonical-dir count 13, NOT the maintainer-inclusive 14**; the maintainer-inclusive "13 total"/"13th skill" framing (l.194) becomes **14 total**; "5 optional"→6; rename `aid-ask`→`aid-query-kb` in the optional list + skill-inventory table; **add `aid-update-kb`** as a new optional off-pipeline row; the `aid-ask`/`aid-housekeep` end-user-runtime note (l.442) gains `aid-query-kb`/`aid-update-kb`. |
| 2 | `.aid/knowledge/module-map.md` | 22 (history), + body module rows | bump each count to **the population that line states** — user-facing "11->12"→"12->13 (user-facing)", any maintainer-inclusive total "13->14", any `canonical/skills/` dir count "12->13"; rename the `aid-ask` module to `aid-query-kb`; add an `aid-update-kb` module row (thin-router `SKILL.md` + `references/state-*.md`). |
| 3 | `.aid/knowledge/feature-inventory.md` | 9-14 (history), 40 (`/aid-ask` row), 90 ("12 user-facing…") | "12 user-facing"→13; rename row 12 `/aid-ask`→`/aid-query-kb`; **add a new `/aid-update-kb` row** (optional, prompt-driven targeted KB update through the review gate). |
| 4 | `.aid/knowledge/pipeline-contracts.md` | 12, 15, 45, + the `/aid-ask` contract block | "12 user-facing skill…"→13; rename the `/aid-ask` slash-command contract block to `/aid-query-kb` (note added gap-capture write-scope) and **add a `/aid-update-kb` contract block**. |
| 5 | `.aid/knowledge/repo-presentation.md` | 14 (history), 80, 344 | "12 user-facing skills"→13 (two body spots); rename `aid-ask`→`aid-query-kb`; add `aid-update-kb`. |
| 6 | `.aid/knowledge/integration-map.md` | 12 (history), 213 | "12 user-facing skills"→13; rename `aid-ask`→`aid-query-kb`; add `aid-update-kb` to the skill enumeration. |
| 7 | `.aid/knowledge/coding-standards.md` | 21 (history), 460 | "all 12 user-facing skills"→13 in the thin-router-line-count assertion; rename `aid-ask`→`aid-query-kb`; confirm `aid-update-kb`'s SKILL.md fits the thin-router line threshold. |
| 8 | `.aid/knowledge/domain-glossary.md` | 13 (history), 81 | "12 user-facing skills (`aid-config`…)"→13; rename `aid-ask`→`aid-query-kb`; add `aid-update-kb` to the enumeration (+ a glossary term if f008 coined one for targeted-update). |
| 9 | `.aid/knowledge/project-structure.md` | 17 (history) + any AID-skills-dir count | "11->12"→"12->13"; rename/add in any skill-dir enumeration. |
| 10 | `.aid/knowledge/README.md` | 12-13, 20, 37, 46, 81 (cycle log + doc-status table) | **Append a new cycle entry** for the f008/f009 rename+add (12→13 user-facing); do NOT rewrite past cycle rows. |
| 11 | `.aid/knowledge/release-tracking.md` | 66 ("11 user-facing skills" historical) | Historical snapshot line — **leave as-is** (it records the v-then state); add the rename+add to the Unreleased section instead (the release-tracking append convention). |
| 12 | `.aid/knowledge/INDEX.md` | — | **Regenerate** via `canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge` (no skill-name edit needed — keyed on doc frontmatter). Required for the kb-hygiene INDEX-fresh CI check after any KB doc edit. |
| 13 | `.aid/knowledge/STATE.md` | 206-214, 432 (Q&A history / cycle table) | History/Q&A entries — **append**, don't rewrite. A new Q&A or cycle row noting the f008/f009 rename+add reconciliation; the dashboard reads this. Also flag the f008 RED→f009 green hand-off here per tracking discipline. |
| 14 | `.aid/dashboard/kb.html` (committed built KB-summary artifact) | `aid-ask` at l.792/812/984/1176; "12 skills" at l.1160 (slash-command-contracts `<h3>`) + l.1723 (the documentation-surface "Mermaid flowchart + 12 skills" line, mirroring `summary-src/sections/12`) | **Regenerated, NOT hand-edited.** This is the built artifact `aid-summarize` writes (`canonical/skills/aid-summarize/references/state-writeback.md:19` → `.aid/dashboard/kb.html`; meta `generator="aid-summarize"`). Its **source of truth is `summary-src/sections/*.html`** (Part 4 / S9). Fix the `summary-src` sections first, then **re-run the `aid-summarize` render path** so `kb.html` regenerates with `aid-query-kb`/`aid-update-kb` and "13 skills" — do not edit `kb.html` by hand. Then **Playwright-visual-validate the regenerated `kb.html`** per the web-review gate. |

> **Convention reminders.** (a) Change-Log/history/cycle-log lines are **append-only** — add a
> dated entry, never edit a past cycle's recorded count. (b) `INDEX.md` is **generated** — edit
> via `build-kb-index.sh`, never by hand (the `index-md-canonical-regen` memory: use the
> `canonical/` script path, not the `.claude/` copy, or kb-hygiene fails on the embedded path).
> (c) The `### Skill inventory` table in `architecture.md` (l.177) and the enumerated optional
> lists are the *prose* counts — each must gain an `aid-update-kb` row and the `aid-ask`→
> `aid-query-kb` rename, not just a number bump.

---

### Part 4 — Docs site

Two files; one is hand-authored, one is generated from it.

| Surface | File | Change | Verification |
|---------|------|--------|--------------|
| Reference generator (hand-authored map + count) | `site/scripts/gen-reference.mjs` | **(a)** In `SKILL_GROUPS` (l.83-): rename `{ name: 'aid-ask', phase: 'on demand · read-only Q&A' }` (l.126) → `aid-query-kb`, and **add** `{ name: 'aid-update-kb', phase: 'on demand · targeted KB update' }` to the same on-demand group (alongside `aid-housekeep`). **(b)** Bump the hard-coded intro string (l.153) `'AID ships **12 user-facing skills** ... plus two off-pipeline on-demand skills'` → **13** and **"plus three off-pipeline on-demand skills"** (`aid-query-kb` read + `aid-housekeep` + `aid-update-kb`). | `node site/scripts/gen-reference.mjs` runs clean; the emitted `skills.md` lists both new skills and no `aid-ask`. |
| Generated reference page | `site/src/content/docs/reference/skills.md` | **Regenerated** by running `gen-reference.mjs` (the per-skill table is built by `generateSkillsPage()` reading `canonical/skills/*/SKILL.md`, so `aid-query-kb`/`aid-update-kb` entries appear and the `aid-ask` entry at l.115-121 disappears automatically; the intro count comes from the bumped string). **Do not hand-edit** (`<!-- generated — do not edit -->`, l.7). | `git diff site/src/content/docs/reference/skills.md` shows the rename+add+count; no stray `aid-ask`. |
| Summary HTML sections | `.aid/knowledge/summary-src/sections/02-the-pipeline.html` (l.29 mermaid `ASK` node, l.49 caption), `03-phases-and-skills.html` (l.163 `/aid-ask` card), `06-pipeline-contracts.html` (l.8 `<h3>… (12 skills)</h3>`, l.24 `/aid-ask` contract row), **`12-documentation-surface.html` (l.12 "Mermaid flowchart + 12 skills" — a count-only surface with NO `aid-ask` token, so a `grep aid-ask` alone misses it)** | Rename `aid-ask`→`aid-query-kb` (mermaid node id + label + caption + card + contract row); bump **both** "12 skills" counts (`06` l.8 `(12 skills)`→`(13 skills)` **and `12` l.12 "12 skills"→"13 skills"**); **add** an `aid-update-kb` card (03) + contract row (06) + optional mermaid node (02). These edits are the **source of truth** for the built `.aid/dashboard/kb.html` (Part 3 row 14) — regenerate `kb.html` from them, do not hand-edit it. | `grep -rn "aid-ask" summary-src/sections/` empty **and** `grep -rn "12 skills" summary-src/sections/` empty (catches the no-`aid-ask` section 12); after regenerating the summary (the `aid-summarize` render path), Playwright visual check of the rendered `kb.html` per the web-review gate. |

> **Web-review gate (global rule).** The summary-src sections render to a web summary page; per
> the machine-global hard gate, **any review of that rendered web output MUST use Playwright to
> visually validate** (load page, screenshot, confirm the mermaid pipeline figure + skill cards
> + contract table render with the new skills). Source-only inspection is an automatic FAIL.

---

### Part 5 — Dogfood self-install (this repo's own AID install)

This repo dogfoods AID, so it carries an installed `.claude/skills/aid-ask/SKILL.md` and a
runtime install manifest `.aid/.aid-manifest.json` (l.394). These are **not** render targets
and **not** render-drift-gated, but they go stale on the rename and are visible to anyone
reading the repo's own AID surface.

| Surface | Change | Verification |
|---------|--------|--------------|
| `.claude/skills/aid-ask/` (dogfood install) | Replace with the rendered `aid-query-kb/` + `aid-update-kb/` (copy from `profiles/claude-code/.claude/skills/` after Part 1, or re-run the dogfood install/migration), and remove the orphaned `aid-ask/` dir. | `find .claude/skills -path '*aid-ask*'` empty; `aid-query-kb`/`aid-update-kb` present. |
| `.aid/.aid-manifest.json` | Update the claude-code tool's path list (l.394 `".claude/skills/aid-ask/SKILL.md"` → `aid-query-kb`; add `aid-update-kb` paths). | `grep aid-ask .aid/.aid-manifest.json` empty; new skill paths present. |

> **[SPIKE-B] Dogfood-update mechanism.** Whether the dogfood `.claude/` + `.aid-manifest.json`
> are refreshed by (a) a manual copy from the freshly rendered `profiles/claude-code/` tree, or
> (b) re-running the AID migration/install against this repo (the work-005 `/CLAUDE.md` dogfood
> precedent), is a small mechanism choice for PLAN. Either yields the same end state; (b) is
> more faithful to "ship it the way a user gets it". Flag for PLAN — not a blocker.

---

### Propagation surface table (master)

| # | Surface | File(s) | Auto/Manual | Change | Verification command |
|---|---------|---------|-------------|--------|----------------------|
| S1 | Render to 5 trees + orphan-prune | `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/<root>/skills/` + the 5 `emission-manifest.jsonl` | **Auto** (one run) | Re-render (emit `aid-query-kb`+`aid-update-kb`); deletion pass prunes `aid-ask/` | `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/` (after commit: clean) |
| S2 | Orphan-prune assertion | (all 5 trees) | **Auto, verify** | old skill gone, new present | `! find profiles -path '*/aid-ask/*' \| grep .` and `find profiles -path '*/aid-query-kb/*' -path '*/aid-update-kb/*'` present in 5 trees |
| S3 | 5 release tarballs | (built by `release.sh` from `profiles/`) | **Auto** | new file list, no `aid-ask` | `bash release.sh` Step-2/Step-4 succeed (re-runs render guard); inspect a built `aid-claude-code-v*.tar.gz` for `aid-query-kb`/`aid-update-kb`, no `aid-ask` |
| S4 | npm/pypi vendors | `packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py` | **Non-surface** | none (vendor CLI installer, not skills) | n/a — recorded as out-of-scope |
| S5 | KB count + `aid-ask` refs | the 14 files in Part 3 (incl. the built `.aid/dashboard/kb.html`; plus the doc-narrative surfaces in S11) | **Manual** (CI does not catch) | user-facing 12→13 / maintainer-inclusive total 13→14 / canonical-dirs 12→13 / 5→6 optional; rename+add in every enumeration | grep **both roots** — `grep -rn "aid-ask" .aid/knowledge/ .aid/dashboard/` returns only append-only history lines (the `.aid/dashboard/kb.html` built artifact lives under `.aid/` but NOT `.aid/knowledge/`, so the `.aid/knowledge/`-only root would miss it); `grep -rn "user-facing skill" .aid/knowledge/` shows 13 (no stale 12) |
| S6 | INDEX.md | `.aid/knowledge/INDEX.md` | **Auto (regen)** | regenerate | `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output /tmp/INDEX.regen.md && diff` (matches committed) |
| S7 | Docs-site generator | `site/scripts/gen-reference.mjs` | **Manual** | `SKILL_GROUPS` rename+add; intro count 12→13, two→three off-pipeline | code review of l.126/l.153 |
| S8 | Docs-site reference page | `site/src/content/docs/reference/skills.md` | **Auto (regen)** | regenerate from S7 | `node site/scripts/gen-reference.mjs`; `grep aid-ask` empty; `grep aid-query-kb` + `aid-update-kb` present |
| S9 | Summary HTML (source of truth for S12 `kb.html`) | `.aid/knowledge/summary-src/sections/{02,03,06}-*.html` (rename + count) **and `12-documentation-surface.html`** (count-only, no `aid-ask` token) | **Manual + regen** | rename+add+count in mermaid/cards/contracts; bump both "12 skills" counts (06 + section 12); re-render summary | `grep -rn "aid-ask" summary-src/sections/` empty **and** `grep -rn "12 skills" summary-src/sections/` empty (the section-12 count carries no `aid-ask`, so it needs its own grep); Playwright visual check of the rendered summary |
| S12 | Built KB-summary artifact | `.aid/dashboard/kb.html` (committed; `generator="aid-summarize"`) | **Auto (regen from S9)** | regenerate from the edited `summary-src` via the `aid-summarize` render path — **not hand-edited**; `aid-query-kb`/`aid-update-kb` + "13 skills" appear, no `aid-ask`/"12 skills" | `grep -n "aid-ask\|12 skills" .aid/dashboard/kb.html` empty; **Playwright visual re-validation** of the regenerated `kb.html` (pipeline mermaid + skill cards + contract table render the new set) per the web-review gate |
| S10 | Dogfood install | `.claude/skills/`, `.aid/.aid-manifest.json` | **Manual** | replace `aid-ask` install with new skills | `find .claude/skills -path '*aid-ask*'` empty; `grep aid-ask .aid/.aid-manifest.json` empty |
| S11 | Doc-narrative surfaces (non-KB, non-generated) | `README.md` (l.58 `*12 skills*`, l.157, l.194 `/aid-ask`), `docs/aid-methodology.md` (l.71, 85, 100, 842), `docs/glossary.md` (l.9, 70 "12th user-facing skill"), and their site mirrors `site/src/content/docs/concepts/methodology.md` (l.75, 89, 104, 846) + `site/src/content/docs/reference/glossary.md` (l.13, 74) | **Manual** | 12→13 / "Twelve"→"Thirteen"; rename `aid-ask`→`aid-query-kb`; add `aid-update-kb` to the skill tables/glossary; the "12th user-facing skill" glossary def becomes `aid-query-kb` + add a new `aid-update-kb` def | `grep -rn "aid-ask\|12 user-facing\|12 skills\|Twelve" README.md docs/ site/src/content/` returns no stale count and no `aid-ask` (except append-only history) |

> **S11 mirror pairs (grounded).** `docs/aid-methodology.md` ↔
> `site/src/content/docs/concepts/methodology.md` and `docs/glossary.md` ↔
> `site/src/content/docs/reference/glossary.md` carry **byte-identical** narrative lines —
> edit both halves of each pair in lockstep (or confirm at DETAIL which is the source and which
> the mirror, and whether a copy step regenerates the mirror). These are **hand-authored prose**
> (not generated by `gen-reference.mjs`), so they need manual edits — they are exactly the
> "stale README version vs version-sync" blind-spot class from memory: a count bumped in the
> KB/skills.md but left stale in the marketing/docs narrative.

---

### CI greening sequence

The order that takes the f008 branch from RED to all-green:

1. **f008 lands** (canonical rename + new skill). On this state: `render-drift` = **RED**
   (profiles stale), `kb-hygiene` = green-ish (it does not check skill counts), the
   ASCII/test suites unaffected.
2. **f009 Part 1** — run `run_generator.py`, commit the regenerated `profiles/` + 5 manifests.
   → `render-drift` (re-runs the generator, expects no diff) goes **green**.
3. **f009 Part 3 + S6** — reconcile the KB counts, regenerate `INDEX.md`. → `kb-hygiene`
   INDEX-fresh check stays green (INDEX regenerated to match); the count fix is correctness, not
   a CI gate, but is asserted by the S5 grep verifications.
4. **f009 Part 4 + S12** — edit `gen-reference.mjs`, regenerate `skills.md`; edit the `summary-src`
   sections (incl. section 12); **re-run the `aid-summarize` render path to regenerate the committed
   `.aid/dashboard/kb.html` (S12)**; rebuild the docs site. → the docs build (`site` astro build,
   runs on master) stays green; the generated `skills.md` and `kb.html` match their generators (no
   drift). Playwright-visual-validate the regenerated `kb.html`.
5. **f009 Part 5** — refresh the dogfood `.claude/` + `.aid-manifest.json`.
6. **All-green gate:** `render-drift` green, `kb-hygiene` green, the canonical test suites
   (`tests/run-all.sh`) green, and the S2/S5/S8/S9/S10/**S12** grep+visual verifications all clean.
   Per the memory note, **rely on remote CI for the heavy gates** (canonical suites + astro
   build run only on master/PR-to-master) rather than per-change local runs.

---

### Constraints

- **C3 / NFR-4 — render-drift (this feature's primary obligation).** The whole point of f009 is
  to make `git diff -- profiles/` empty after `run_generator.py`. Part 1 + the commit of
  regenerated `profiles/` satisfy it. No `canonical/skills/` content is edited here (that would
  be re-spec'ing f008); f009 only *runs the generator over* f008's canonical.
- **C2 — ASCII-only (shipped scripts).** f009 **adds no new shipped script** and edits none of
  the ASCII-gated files (`test-ascii-only.sh` scopes `lib/aid-install-core.sh`, `bin/aid.ps1`,
  `install.sh/ps1`, the migrate scripts, the Windows installer test — none touched by f009).
  The rendered skill markdown is not ASCII-gated, but the canonical source it renders from is
  f008's (already ASCII per the sibling convention). **No PS-5.1 surface** (no PowerShell
  touched). So C2 is satisfied by construction — but if any KB/docs edit pastes a non-ASCII
  glyph, keep it ASCII for sibling consistency.
- **C6 — content-isolation.** The `aid-` prefix is preserved by both new skill names; the
  orphan-prune is prefix/manifest-driven (the emission-manifest diff, not a blind glob delete),
  so it removes only AID-emitted files. The dogfood `.aid-manifest.json` keeps the
  per-tool path inventory accurate (S10) — the isolation manifest stays truthful.
- **C7 — KB-hygiene CI.** INDEX.md is regenerated (S6) so the INDEX-fresh check passes; the
  `.aid/.temp/` and CRLF checks are unaffected. **Note the gap:** kb-hygiene does **not** assert
  the skill count, so S5 is a manual-correctness obligation this spec enumerates exhaustively to
  cover.
- **No new runtime / no new infra.** Every surface reuses `run_generator.py`, `release.sh`,
  `gen-reference.mjs`, `build-kb-index.sh`, the `aid-summarize` render path, and the dogfood
  install/migration. f009 introduces no script, manifest format, or CI job.

---

### Coupling constraint (a PLAN obligation)

**f009 must ship in the SAME delivery as f008 — no half-renamed release.** f008's branch leaves
`render-drift` RED and the skill set half-renamed by construction; f009 is what makes it green
and complete. Therefore:

- The PLAN must **sequence f008 → f009 and gate the hand-off** so the two land together (the
  f008 SPEC's SPIKE-4 / the `render-drift-full-generator` + `adding-skill-kb-count-drift`
  memory hazards). **No release tag may be cut between f008 and f009** — a release in between
  would publish a tree with `aid-ask` removed from canonical but still present in the rendered
  trees/tarballs (or vice-versa), and stale KB counts.
- Concretely: **f008 and f009 share one delivery branch / one PR**, or f009 immediately
  follows f008 with no intervening `release.sh` run. Recorded in `STATE.md` per tracking
  discipline.

---

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-A] Orphan-prune on the actual run (verify, not redesign).** The mechanism is proven
  on disk (`run_generator.py:43-60` diff→unlink→rmdir; the `aid-ask` manifest record exists in
  all 5 trees). The only thing to confirm *on the run* is that `aid-ask`'s rendered dir, being
  single-file, prunes empty in all 5 trees and that `aid-update-kb`'s multi-file new dir emits
  cleanly. **Resolution = run `run_generator.py` and assert S2's grep.** If (unexpectedly) a
  tree leaves an empty `aid-ask/` dir behind, the `rmdir` loop's `common_parent` bound is the
  thing to inspect — but the code path indicates clean prune. *Low risk; verify-on-run.*
- **[SPIKE-B] Dogfood-update mechanism** (Part 5): manual copy from the rendered
  `profiles/claude-code/` vs. re-running the AID install/migration against this repo. Same end
  state; PLAN picks the mechanism. *Low risk.*
- **[SPIKE-C — RESOLVED → S12] Built summary artifact is committed.** Resolved against disk: the
  `.aid/knowledge/summary-src/sections/*.html` hand-authored sections are the **source of truth**,
  and the committed built artifact is **`.aid/dashboard/kb.html`** (meta `generator="aid-summarize"`;
  written per `canonical/skills/aid-summarize/references/state-writeback.md:19`; relocated to
  `.aid/dashboard/kb.html` in delivery-009 — the earlier `knowledge-summary.html` name no longer
  exists). It carries the stale `aid-ask` refs (l.792/812/984/1176) and two "12 skills" counts
  (l.1160/1723), so it IS a committed surface that must be regenerated in lockstep — now enumerated
  as **S12** / Part 3 row 14: edit the `summary-src` sections (S9), re-run the `aid-summarize`
  render path to regenerate `kb.html` (never hand-edit it), then Playwright-visual-validate the
  regenerated page. No longer an open unknown.
- **[SPIKE-D — RESOLVED → S11] doc-narrative count surfaces enumerated.** The wider grep was
  run; the non-KB, non-generated narrative surfaces are now an enumerated surface **S11**
  (README.md, docs/aid-methodology.md, docs/glossary.md + their two site mirrors), with exact
  lines and the mirror-pair note. No longer an open unknown — the only residual DETAIL task is
  confirming the source/mirror direction of each pair. *Was medium; now enumerated.*
