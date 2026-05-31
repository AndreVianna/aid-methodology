# Remove Orphaned ui-architecture Template Stub and Stragglers

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-30 | Feature drafted from approved REQUIREMENTS.md | /aid-interview FEATURE-DECOMPOSITION |
| 2026-05-30 | Cross-ref fixes: split REMOVE (orphans + stale profile READMEs) vs KEEP (/aid-summarize downstream signals) | /aid-interview (cross-reference) |
| 2026-05-31 | Technical Specification drafted | /aid-specify |

## Source

- REQUIREMENTS.md §2 (cycle-1 carve-out), §4 (P0 — Pre-work / correctness), FR-P0-3

## Description

Cycle-1 replaced `ui-architecture.md` with `repo-presentation.md`, but an orphaned
`ui-architecture.md` template stub still ships in the canonical tree
(`canonical/templates/ui-architecture.md`) and its rendered copies in all 3 profiles plus the
dogfood `.claude/` tree, along with related stragglers.

The `ui-architecture` references in the repo are of **two distinct kinds**, and this feature
treats them differently:

- **REMOVE (this repo's orphans):** the orphan template stub + its rendered copies, **and** the
  stale hand-authored profile README agent-tables (`profiles/*/README.md`) that still list
  pre-cycle-1 doc names (`data-model`, `api-contracts`, `security-model`, `ui-architecture`).
- **KEEP (generic downstream heuristics):** the `/aid-summarize` section-template
  doc-presence scoring signals (`auto-detect.md`, `web-app.md`) that detect a
  `ui-architecture.md` in arbitrary **downstream** projects — these are not orphans of this
  repo's carve-out; a downstream user project may legitimately have a `ui-architecture.md`.

The goal is that the shipped template set matches the actual standard doc-set, without breaking
/aid-summarize's downstream detection. *(Scope confirmed via cross-reference Q&A: remove orphans
+ stale READMEs; keep the summary signals.)*

## User Stories

- As an AID adopter, I want the shipped templates to reflect the real standard doc-set so that
  I am not seeded with a dead `ui-architecture.md` stub.
- As an AID meta-repo maintainer, I want the cycle-1 carve-out's leftovers cleaned up so the
  template tree is consistent with `repo-presentation.md`.

## Priority

Must

## Acceptance Criteria

- [ ] Given the orphaned `ui-architecture.md` stub exists in `canonical/templates/` and its
      rendered copies, when this feature is complete, then the stub and its rendered copies are
      removed and no dangling reference to it remains.
- [ ] Given the stale hand-authored profile README agent-tables (`profiles/*/README.md`) listing
      pre-cycle-1 doc names, when this feature is complete, then those rows are corrected to the
      current doc-set.
- [ ] Given the `/aid-summarize` section-template doc-presence signals for `ui-architecture.md`,
      when this feature is complete, then they are PRESERVED (downstream detection heuristics,
      not orphans).
- [ ] Given the removal, when the generator runs, then the emission manifest's deletion pass
      handles the removed files safely and render-drift across the 3 profiles is clean.
- [ ] Given the change, when the generator self-tests and the existing canonical suites (13 today) run, then
      they stay green (non-regression).

---

## Technical Specification

### 0. Ground-truth corrections to the brief

Two premises in the source brief were checked against the live tree and **do not hold**; the
spec is written to the verified reality:

1. **There is no `ui-architecture` entry in `canonical/EMISSION-MANIFEST.md`.** That file is the
   manifest *design spec* (prose). The real per-run manifest entries live in the three
   `profiles/<name>/emission-manifest.jsonl` files (`grep -c "EMISSION-MANIFEST.md"` for
   `ui-architecture` = 0; the `.jsonl` files each have exactly one entry —
   `profiles/claude-code/emission-manifest.jsonl:198`, `profiles/cursor/emission-manifest.jsonl:200`,
   `profiles/codex/emission-manifest.jsonl:176`). Those entries are **generated artifacts**, not
   hand-edited: re-running the generator rewrites them.
2. **The `/aid-summarize` section-templates in `canonical/` (and the 3 rendered profiles, and the
   dogfood `.claude/`) already do NOT reference `ui-architecture.md`.**
   `canonical/templates/knowledge-summary/section-templates/auto-detect.md:24,118` scores on
   `architecture.md` UI/frontend patterns, not a `ui-architecture.md` file. The only place the
   `ui-architecture.md` doc-presence signal survives is the **root dogfood install**
   (`.aid/templates/knowledge-summary/section-templates/auto-detect.md:24,33,105` and
   `web-app.md:22`) — which is the OOS "root `.claude/` dogfood install" of REQUIREMENTS §4.
   Therefore the "KEEP the `/aid-summarize` signals" instruction is satisfied **by not touching
   `.aid/` at all**; there is nothing in canonical to preserve and nothing in canonical to delete
   for the summarize signals. The KEEP guard below still applies to any future canonical signal.

### 1. Inventory of targets (verified paths)

#### REMOVE — the orphan template + its generated artifacts

| # | Path : line | Kind | How removed |
|---|-------------|------|-------------|
| R1 | `canonical/templates/ui-architecture.md` (5-line stub, `# UI Architecture` / `> ❌ Pending Discovery`) | canonical source (orphan) | **hand-delete** (`git rm`) |
| R2 | `profiles/claude-code/.claude/templates/ui-architecture.md` | rendered copy | **generator deletion pass** (auto) |
| R3 | `profiles/codex/.agents/templates/ui-architecture.md` | rendered copy | **generator deletion pass** (auto) |
| R4 | `profiles/cursor/.cursor/templates/ui-architecture.md` | rendered copy | **generator deletion pass** (auto) |
| R5 | `profiles/claude-code/emission-manifest.jsonl:198` (the `ui-architecture.md` record) | generated manifest entry | **generator rewrites manifest** (auto) |
| R6 | `profiles/codex/emission-manifest.jsonl:176` | generated manifest entry | **generator rewrites manifest** (auto) |
| R7 | `profiles/cursor/emission-manifest.jsonl:200` | generated manifest entry | **generator rewrites manifest** (auto) |

#### CORRECT — stale hand-authored profile READMEs (pre-cycle-1 doc names)

| # | Path : line | Current (stale) cell | Correct to |
|---|-------------|----------------------|-----------|
| C1 | `profiles/claude-code/README.md:51` | architect → `architecture.md, technology-stack.md, ui-architecture.md` | `architecture.md, technology-stack.md` |
| C2 | `profiles/claude-code/README.md:52` | analyst → `module-map.md, coding-standards.md, data-model.md` | `module-map.md, coding-standards.md, schemas.md` |
| C3 | `profiles/claude-code/README.md:53` | integrator → `api-contracts.md, integration-map.md, domain-glossary.md` | `pipeline-contracts.md, integration-map.md, domain-glossary.md` |
| C4 | `profiles/claude-code/README.md:54` | quality → `test-landscape.md, security-model.md, tech-debt.md` | `test-landscape.md, tech-debt.md, infrastructure.md` |
| C5 | `profiles/cursor/README.md:54` | architect → `…, ui-architecture.md` | `architecture.md, technology-stack.md` |
| C6 | `profiles/cursor/README.md:55` | analyst → `…, data-model.md` | `module-map.md, coding-standards.md, schemas.md` |
| C7 | `profiles/cursor/README.md:56` | integrator → `api-contracts.md, …` | `pipeline-contracts.md, integration-map.md, domain-glossary.md` |
| C8 | `profiles/cursor/README.md:57` | quality → `…, security-model.md, …` | `test-landscape.md, tech-debt.md, infrastructure.md` |

The "correct to" doc-set is taken from the operational source of truth
`canonical/skills/aid-discover/references/state-generate.md:69–72` (plus scout `:41,61–62` →
`project-structure.md, external-sources.md`, which is already correct in both READMEs and needs
no edit). These eight rows are **hand-authored** (not in any `emission-manifest.jsonl`; they live
at `profiles/<name>/README.md`, above the generator's output roots `profiles/<name>/.claude` /
`.cursor` / `.agents`), so the generator never rewrites them — they must be edited by hand.

#### KEEP — do not touch

| # | Path : line | Why KEEP |
|---|-------------|----------|
| K1 | `.aid/templates/knowledge-summary/section-templates/auto-detect.md:24,33,105` | Downstream doc-presence heuristic; lives in the OOS root dogfood install (REQUIREMENTS §4) |
| K2 | `.aid/templates/knowledge-summary/section-templates/web-app.md:22` | Same — generic downstream signal, not an orphan of this repo's carve-out |
| K3 | `canonical/.../section-templates/auto-detect.md`, `web-app.md` | Already migrated to `architecture.md` UI signal; nothing to remove (the KEEP guard still protects any future canonical ui-architecture signal) |
| K4 | `canonical/EMISSION-MANIFEST.md` | Design spec; contains no `ui-architecture` reference |
| K5 | `profiles/codex/README.md` | Uses prose columns ("Tests, security, tech debt"), no `ui-architecture.md`/`data-model.md` filename rows. Its prose staleness + the "16 documents" literal (`:104`) belong to FR-P0-4 / feature-004 (doc-count), NOT this orphan-stub feature. **Flagged, not edited here** (see Known Issues). |

### 2. Files & edits

**Removals (one canonical delete + a generator re-run):**

1. `git rm canonical/templates/ui-architecture.md` (R1).
2. `python run_generator.py`. The deletion pass (`run_generator.py:47–64`) then handles R2–R7
   automatically per profile:
   - The renderer no longer emits `…/templates/ui-architecture.md` for any profile, so the path
     is absent from the current in-memory manifest.
   - `manifest.diff(prev_manifest)` (`:50`) puts each profile's `…/ui-architecture.md` `dst` into
     `removed`.
   - Each `removed` path that exists on disk is `unlink()`-ed (`:51–55`) and empty parent dirs are
     pruned (`:56–64`).
   - `manifest.write(...)` (`:67`) rewrites each `emission-manifest.jsonl` without the entry
     (records sorted by `dst`, version sentinel preserved).
   This is the **preferred** mechanism (matches the "Mirror-deletion" contract in
   `canonical/EMISSION-MANIFEST.md:79,128–129`). Hand-deleting the rendered copies or editing the
   `.jsonl` files is unnecessary and would be reverted/re-detected on the next run.

**Corrections (hand-edits, no generator involvement):**

3. Edit the eight README rows C1–C8 to the current doc-set (table in §1). These files are not
   generator outputs, so they are committed directly and never round-trip through `run_generator.py`.

**Manifest deletion-pass behavior (precise):** the manifest is the *only* authority for what the
generator may delete (`canonical/EMISSION-MANIFEST.md:9–12,69–83`). Files outside any manifest are
never touched — which is exactly why the root `.aid/` / `.claude/` dogfood copies and the
hand-authored profile READMEs are safe from the generator, and why R2–R7 (which *are* in the
profile manifests) are cleaned safely. No new "deletion handling" code is needed; the existing pass
already covers single-file canonical removal (the recipes back-port exercised the same path).

### 3. Flow impact

- **Nothing real consumes the orphan template.** `ui-architecture.md` is not referenced by any
  canonical agent prompt, skill, state file, or the `state-generate.md` agent→file mapping (which
  lists `architecture.md, technology-stack.md` for the architect — `:69`). The 5-line stub is a
  pure leftover of the cycle-1 `ui-architecture → repo-presentation` rename; it is generated into
  the install trees but never read by discovery (which copies KB templates from
  `templates/knowledge-base/`, not the loose top-level `templates/ui-architecture.md`).
- **The `/aid-summarize` doc-presence detection is downstream-only and untouched.** The canonical
  signal already keys on `architecture.md`; the surviving `ui-architecture.md` signal exists solely
  in the OOS `.aid/` dogfood install. Downstream user projects that genuinely ship a
  `ui-architecture.md` keep being detected by their own installed copy of those heuristics.
- **Profile READMEs are documentation only**; correcting the agent-output column has no runtime
  effect — it removes a misleading reference to deleted docs.

### 4. Test plan

Run from repo root after edits 1–3:

1. **Orphan + stale refs gone, KEEP signals intact:**
   `grep -rl ui-architecture --include='*.md' .` and
   `find . -name ui-architecture.md` MUST return **only**:
   `.aid/templates/knowledge-summary/section-templates/auto-detect.md`,
   `.aid/templates/knowledge-summary/section-templates/web-app.md` (the KEEP signals, K1/K2),
   plus **prose-only** mentions in the OOS `.aid/` tree and work-001 docs that *describe* the
   cleanup — namely the work-001 SPEC/REQUIREMENTS docs (this SPEC,
   `feature-002-expectations-consolidation/SPEC.md`, `feature-004-declared-doc-set/SPEC.md`,
   `REQUIREMENTS.md`), the dogfood KB docs that narrate the cycle-1 rename
   (`.aid/knowledge/repo-presentation.md`, `INDEX.md`, `README.md`, `STATE.md`,
   `coding-standards.md`, `domain-glossary.md`, `project-structure.md`, `schemas.md`,
   `tech-debt.md`), and the auto-generated `.aid/generated/project-index.md` inventory (which drops
   the deleted-canonical row on its next regen). **No `…/templates/ui-architecture.md` file
   (canonical or any `profiles/*` render) and no `profiles/*/README.md` row may remain** — those
   are the only entries the present `find`/`grep` removes vs. the baseline above.
2. **Manifests clean:** `grep -l ui-architecture profiles/*/emission-manifest.jsonl` returns
   nothing.
3. **Generator runs clean:** `python run_generator.py` exits 0; reports `Deleted: 1` on the first
   post-removal run for each profile (claude-code, codex, cursor), `Deleted: 0` on an immediate
   second run (idempotent); VERIFY (deterministic) byte-identical re-render = PASS.
4. **Render-drift clean (CI gate):** `git diff --exit-code -- profiles/` is empty after the
   generator run + committing (mirrors `.github/workflows/test.yml:36–42`, which gates `profiles/`
   only).
5. **Canonical suites green:** `bash tests/run-all.sh` → all **13** suites PASS (auto-discovered by
   glob; no suite touches `ui-architecture.md`, so this is non-regression).
6. **Generator self-tests green** (`.github/workflows/test.yml:92–96`):
   `render_lib.py --self-test`, `test_manifest_safety.py --self-test`,
   `render_canonical_scripts.py --self-test`, `verify_deterministic.py --self-test`,
   `verify_advisory.py --self-test` all exit 0.
7. **KB / repo hygiene green** (`test.yml:98+`): CRLF / gitignore / INDEX checks unaffected.

### 5. Backward compatibility & risks

- **Downstream projects keep working.** The `/aid-summarize` `ui-architecture.md` detection
  heuristic is preserved in the only place it lives (the installed dogfood `.aid/` copy and any
  downstream user's installed templates). Removing the *template stub* does not remove the
  *detection signal* — they are different artifacts in different trees.
- **Risk: an over-broad `grep -rl ui-architecture … | xargs rm/sed` would clobber the KEEP signals
  (K1/K2) and prose references.** **Guard:** never delete by grep. Delete exactly one canonical
  file by name (`git rm canonical/templates/ui-architecture.md`) and let the generator handle the
  renders/manifests; correct the README rows by targeted line edits (C1–C8). The grep in Test 1 is
  a *post-condition assertion*, not a deletion command, and its expected output explicitly includes
  the KEEP files.
- **Risk: editing the wrong README cell / desyncing from the real doc-set.** **Guard:** the
  "correct to" values are pinned to `state-generate.md:69–72` (the operational mapping the pipeline
  actually uses), not invented.
- **Risk: re-introducing drift by hand-editing `.jsonl` or rendered copies.** **Guard:** treat
  R2–R7 as generator-owned; the only manual canonical action is R1.

### 6. Cross-feature dependencies & Known Issues

- **KI-1 (cross-feature, FR-P0-1 / feature-001):** the canonical agent frontmatter and
  `state-generate.md` disagree on scout/quality ownership — `discovery-scout/AGENT.md`'s
  description claims it produces `infrastructure.md`/`project-structure.md`, while
  `state-generate.md:41,72` assigns `external-sources.md` to scout and `infrastructure.md` to
  quality. This feature's README correction (C4/C8) follows the `state-generate.md` truth
  (quality → `…, infrastructure.md`). When FR-P0-1 finalizes the single ownership truth, the
  README rows should be re-verified against it — they are correct under today's operational mapping.
- **KI-2 (scope boundary):** `profiles/codex/README.md` has *prose* staleness ("Tests, security,
  tech debt" at `:71`; "Infrastructure, open questions" at `:72`; "16 documents" literal at
  `:104`). The filename-row staleness this feature targets does not exist there (codex README uses
  a prose column). The "16 documents" literal is FR-P0-4 / feature-004 (doc-count) scope; the prose
  is a softer doc refresh. **Left untouched here** to avoid silent scope creep — flagged for
  feature-004 or a doc-refresh follow-up.
- **KI-3 (OOS, by design):** the root dogfood `.claude/templates/ui-architecture.md` and the
  `.aid/` summarize signals are NOT cleaned by this feature (the root dogfood refresh is OOS per
  REQUIREMENTS §4, and the `.aid/` signals are KEEP). After this feature, `find . -name
  ui-architecture.md` still shows the root `.claude/` copy until the separate dogfood-refresh task
  runs; this is expected, not a regression. (If a future maintainer wants it gone too, that is the
  dogfood-refresh task, outside FR-P0-3.)
