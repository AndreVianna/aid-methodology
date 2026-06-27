# Rename aid-interview to aid-define

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-6, §6 NFR-6, §8 D-3, §9 AC-8, §10 P3 | /aid-interview |
| 2026-06-27 | Technical Specification authored — name-agnostic rename mechanics, blast-radius inventory, sequencing constraint, AC-8 DoD; grounded in aid-ask→aid-query-kb precedent | /aid-specify |
| 2026-06-27 | Spec revised post-review: blast radius +README.md/examples/dashboard(+vendored copy); DoD step-2 made true whole-repo; accurate whole-repo vs authored-subset counts; recon-classify path fixed; Open Questions added (dangling ref removed) | /aid-specify |
| 2026-06-27 | Spec re-review fixes: DoD step-2 closure carved to shipped/canonical surface set (matches inventory) — `.aid/knowledge/` deferred to /aid-housekeep, `.aid/work-*`+`.aid/design/` out-of-scope; count decomposition corrected (~493 generated profiles, ~99 dogfood mirror, ~26 .aid not-swept) | /aid-specify |
| 2026-06-27 | Cross-ref round-3 fix: `dashboard/` scope made symmetric to `.aid/` — home.html's paired assertion test `test_index_html.py` + `derivation.py` producer comments added to inventory; frozen `dashboard/.../fixtures/**` + `test_feature009.py` marked out-of-scope. | /aid-specify |
| 2026-06-27 | Cycle-4 re-verify (A+ gate): row 8 confirmed Fixed; one new [MINOR] (row 9) — prose count decomposition fixed: `+11`→`+13` bucket names the 2 in-scope dashboard hand-edits, added a `~6 files dashboard/ frozen test data NOT swept` bucket + reconcile disclaimer. All 9 ledger rows Fixed → **A+**. | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-6, §6 NFR-6, §8 D-3, §9 AC-8, §10 P3

## Description

The name aid-interview describes the method (interviewing) rather than the outcome (defining the
work). This feature renames the skill to a clearer name (current lean: /aid-define) with full
cross-tree propagation, following the same pattern work-001 used for aid-ask → aid-query-kb:
render the renamed skill to the 5 host trees, orphan-prune the old skill directory, update the
install manifests, update the skill-name reference surfaces (a rename leaves the skill count
unchanged), and update the docs site. The rename must stay byte-identical across the 5 host trees
(DBI) per the established render and propagation rules, and CI must stay green. **Sequencing:** this
feature must land AFTER the content features (002/003/004), which edit the skill directory in place —
a directory rename collides with concurrent content-edits.

## User Stories

- As an AID adopter, I want the skill named for what it produces (defining the work) so that its
  purpose is obvious from the command name.
- As an AID maintainer, I want the rename propagated byte-identically across all 5 host trees with
  the old directory orphan-pruned and manifests, skill-count surfaces, and docs site updated so
  that no channel ships a stale or broken reference.

## Priority

Should

## Acceptance Criteria

- [ ] Given the rename, when it ships, then the skill is renamed with byte-identical propagation
  across the 5 trees, the old directory is orphan-pruned, and the install manifests, skill-count
  surfaces, and docs site are updated. *(AC-8)*
- [ ] Given the renamed skill, when CI runs, then CI is green. *(AC-8, NFR-6)*

---

## Technical Specification

> Added by `/aid-specify`. This is an infra/tooling rename — no application data or
> runtime behavior changes. Sections are adapted to the change-type: **Data Model** →
> schema impact; **Feature Flow** → the rename execution sequence; **Layers & Components**
> → the affected-surface inventory; plus a **State Machines** note (the skill's own machine
> is renamed in place, not altered) and a **DoD / Verification** section operationalizing AC-8.

### Name decision (deferred work-time choice)

The final skill name is a **work-time decision**, not fixed by this spec. The current lean is
`aid-define` (command `/aid-define`), per REQUIREMENTS.md §1/§5 FR-6. This spec is written
**name-agnostically**: every step below refers to `<NEW-NAME>` (the new skill dir / command
token) and `<OLD-NAME>` = `aid-interview`. The chosen `<NEW-NAME>` must:
- be `aid-`-prefixed (content-isolation cornerstone) and kebab-case (matches all sibling skills);
- not collide with an existing canonical skill dir (`aid-config`, `aid-deploy`, `aid-detail`,
  `aid-discover`, `aid-execute`, `aid-housekeep`, `aid-monitor`, `aid-plan`, `aid-query-kb`,
  `aid-specify`, `aid-summarize`, `aid-update-kb`) or agent (`aid-interviewer`, etc.);
- be ratified by the human before the rename task runs. The aid-detail/aid-execute step that
  builds the rename task MUST resolve `<NEW-NAME>` to a literal first (Q&A to the owner if still
  open), then thread that literal through every step. **No step may run with `<NEW-NAME>`
  unresolved.**

### Data Model

**No schema changes.** This is a directory/identifier rename; it touches no KB doc schema,
no frontmatter `source:` enum, no `.aid` state shape, and no settings keys. It is therefore
orthogonal to feature-005's C-1 `forward-authored` marker work and shares no files with it.

### Feature Flow

The rename follows the **proven `aid-ask` → `aid-query-kb` precedent** (work-001 features
f008/f009; commits `cf6cb1af` rename-canonical, `5bbf3a98` site+manifest). Canonical is the
single source of truth; the 5 host trees are **generated**, never hand-edited. Execution
sequence:

1. **Rename the canonical skill dir.** `git mv canonical/skills/aid-interview
   canonical/skills/<NEW-NAME>` (preserves history). This is the only directory rename.
   Reference *filenames* inside `references/` that contain the substring "interview" (e.g.
   `interview-loop.md`, `interview-strategies.md`) are **content artifacts, not the command
   name** — they describe the interviewing *activity*, not the skill *identity* — so leave them
   as-is unless feature-002/003/004 already restructured them; do NOT sweep them in this rename
   (rationale + the lone open call in **Open Questions** below).
2. **Rewrite the skill's own identity + self-references.** In the renamed dir:
   - frontmatter `name: aid-interview` → `name: <NEW-NAME>` (SKILL.md);
   - every `/aid-interview` command token and `aid-interview` self-reference in SKILL.md
     (~24 occurrences) and across all `references/*.md` self-references (counted on disk:
     `cross-reference`, `feature-decomposition`, `kb-hydration`, `lite-to-full-escalation`,
     `recipe-to-lite-escalation`, `reviewer-brief`, and the `state-*.md` files);
   - any example file-path citation `.claude/skills/aid-interview/...` →
     `.claude/skills/<NEW-NAME>/...`.
3. **Update external skill-name reference surfaces** (callers that name the skill — a rename,
   NOT a count change; see Layers & Components for the full inventory).
4. **Render to the 5 host trees + orphan-prune the old dir.** Run the FULL generator
   `python .claude/skills/generate-profile/scripts/run_generator.py` (NOT per-script
   renderers — render-drift CI keys on the full emission manifests). The generator's deletion
   pass (manifest `diff`) prunes the now-absent `aid-interview/` dir from each profile tree and
   emits `<NEW-NAME>/` byte-identically; it rewrites each `profiles/*/emission-manifest.jsonl`.
5. **Sync the dogfood mirror.** Remove `.claude/skills/aid-interview/`, add
   `.claude/skills/<NEW-NAME>/` (byte-identical to the claude-code profile tree), and update
   the dogfood install manifest `.aid/.aid-manifest.json` (replace every
   `.claude/skills/aid-interview/...` path with `.claude/skills/<NEW-NAME>/...`).
6. **Update the docs site.** Edit `site/scripts/gen-reference.mjs` (the `SKILL_GROUPS` source
   that names the skill — rename the entry, leave the total count unchanged) and regenerate
   `site/src/content/docs/reference/skills.md` (do-not-edit generated file). Update the
   remaining hand-authored site/docs surfaces that mention the skill by name (inventory below).
7. **Verify** (DBI byte-identity, render-drift, zero stale refs, green CI) — see DoD.

### Layers & Components — affected-surface inventory (blast radius)

Scoped on disk via boundary-aware `grep -rl "aid-interview"`. A whole-repo `grep -rl` (excluding
`.git`/`node_modules`/nested worktrees) hits **≈758 files / ≈2224 occurrences**; the decomposition
below clarifies what an author rewrites vs. what is generated vs. what is NOT swept at all (the
per-bucket counts are tilde-approximate and reconcile to the whole-repo total within rounding):

- **~493 files — the 5 generated `profiles/` host trees** (every canonical mention × 5 trees):
  NOT hand-edited; the generator rewrites them in step 4.
- **~123 files / ~351 occ — the hand-edited authored canonical + source subset** (`canonical/` +
  `docs/` + `site/` + `tests/`): the files an author actually rewrites.
- **+13 files — the remaining hand-edited non-canonical surfaces:** root `README.md` (1),
  `examples/` (8), `dashboard/home.html` + its vendored `.aid/dashboard/home.html` (2), and the two
  dashboard files paired to the home.html edit — `dashboard/server/tests/test_index_html.py` (the
  assertion test) + `dashboard/reader/derivation.py` (producer comments) (2) — also authored by hand
  (see the inventory rows below).
- **~99 files — the `.claude/` dogfood skill mirror:** not individually authored — swapped
  wholesale in step 5 (old dir removed, new dir copied byte-identical from the claude-code tree).
- **~26 files — `.aid/`, NOT swept by this rename:** `.aid/knowledge/` (~11 files, ~9
  `/aid-interview` tokens) is **deferred to `/aid-housekeep`**, and `.aid/work-*/` + `.aid/design/`
  (~15 files, ~100 occ — historical changelog source-tags + the feature SPECs themselves,
  including this one) are **out of scope** (zeroing them would corrupt records). See DoD step 2.
- **~6 files — `dashboard/` frozen test data, NOT swept:** `dashboard/reader/tests/test_feature009.py`
  (1) + the 5 frozen `dashboard/server/tests/fixtures/**/.aid/work-*` sample artifacts — **out of
  scope** (rewriting frozen fixtures would invalidate them; no pytest job runs in CI). See DoD step 2.

The inventory below and the DoD step-2 sweep are defined over the **same scoped surface set**
(shipped/canonical, excluding the deferred dogfood KB and the out-of-scope work/design artifacts)
so they genuinely agree. Surfaces to update, grouped:

| Surface | Files / locus | Action |
|---------|---------------|--------|
| Canonical skill dir | `canonical/skills/aid-interview/` (SKILL.md + 20 `references/*.md`) | `git mv` + self-ref rewrite (steps 1–2) |
| Generated host trees (×5) | `profiles/{antigravity/.agent,claude-code/.claude,codex/.codex,copilot-cli/.github,cursor/.cursor}/skills/aid-interview/` | regenerated, NOT hand-edited (step 4) |
| Emission manifests (×5) | `profiles/*/emission-manifest.jsonl` | rewritten by generator (step 4) |
| Dogfood mirror + manifest | `.claude/skills/aid-interview/`, `.aid/.aid-manifest.json` | sync + path-replace (step 5) |
| Calling agents | `canonical/agents/{aid-orchestrator,aid-interviewer,aid-architect}/{AGENT,README}.md` | rewrite skill-name mentions (then re-render via generator) |
| Recipes + recipe tooling | `canonical/aid/recipes/*.md` (~55), `canonical/aid/scripts/interview/parse-recipe.sh`, `canonical/aid/scripts/kb/recon-classify.sh` | rewrite skill-name mentions (then re-render the scripts via generator) |
| Templates | `canonical/aid/templates/**` (requirements, specs, work-state, reviewer-*, recipe-template, state-machine-chaining, KB templates) | rewrite skill-name mentions |
| Other canonical skills | `aid-discover`, `aid-detail`, `aid-monitor`, `aid-config`, `aid-deploy` READMEs/SKILLs/references that name the skill | rewrite skill-name mentions |
| Repo front page | root **`README.md`** — live `/aid-interview` command refs (L31 Mermaid pipeline node, L148 quick-start command, L161 brownfield/greenfield flow, L230 TRIAGE blurb) | rewrite the `/aid-interview` command token + the pipeline-diagram label |
| Examples | **`examples/`** (8 files): `examples/README.md`, `examples/greenfield/{README.md, samples/REQUIREMENTS.md}`, `examples/brownfield-full-path/{README.md, sample-spec-excerpt.md}`, `examples/brownfield-lite-path/{README.md, sample-spec.md, sample-task-001.md}` | rewrite `/aid-interview` command refs + sample artifact mentions |
| Dashboard empty-state UI | `dashboard/home.html` **L1804** (`codeEl.textContent = '/aid-interview'`, the shipped next-step hint) **+ its vendored copy `.aid/dashboard/home.html` L1804** — keep both in **lockstep** | rewrite the literal command string in both copies |
| Dashboard home.html's paired test + producer comments | `dashboard/server/tests/test_index_html.py` (**L872/877/880 assert the exact `'/aid-interview'` string** — they go FALSE the moment home.html is edited, so they MUST track it) + `dashboard/reader/derivation.py` L19/23 (stale producer comments) | update the asserted string in the test; refresh the producer comments |
| Docs site (generated) | `site/scripts/gen-reference.mjs` (source), `site/src/content/docs/reference/skills.md` (regen) | rename entry, regen (step 6) |
| Docs site (hand-authored) | `site/src/content/docs/{index.mdx, get-started/{first-work,lite-path}.mdx, guides/pipeline.mdx, concepts/{faq,methodology}.md, reference/{glossary,agents,artifacts}.md}` | rewrite skill-name mentions |
| Legacy docs | `docs/{aid-methodology.md, faq.md, glossary.md}` | rewrite skill-name mentions |
| Tests | `tests/canonical/{test-pipeline-status-walkthrough,test-path-fixtures,test-parse-recipe,test-work-state-template}.sh` | update fixtures/expected skill-name strings |

**Critical scoping caveat — substring collision.** `aid-interview` is a **prefix of
`aid-interviewer`** (the analyst *agent* persona). The agent `aid-interviewer` is **NOT renamed
by this feature** — it is a separate component. A naive global `aid-interview` →
`<NEW-NAME>` replacement would corrupt every `aid-interviewer` token. The rename MUST use a
boundary-aware match (e.g. `aid-interview` followed by a non-`-`/non-word char, or the explicit
`/aid-interview` command token and the `skills/aid-interview/` path token), and MUST be verified
with a post-pass `grep -rn "aid-interviewer"` count that is **unchanged** before/after.

**Skill count is invariant.** A rename does NOT change "N user-facing skills" — the count
surfaces (`gen-reference.mjs` "13 skills" intro, glossary/methodology/index totals) keep their
numbers; only the *named* entry changes. (Contrast with the precedent's f009, which ALSO added
`aid-update-kb` and so bumped 12→13 — that bump is NOT part of this rename.)

### State Machines

The skill's own state machine (`FIRST-RUN → Q-AND-A → TRIAGE → {full | lite | escalated}`,
declared in SKILL.md frontmatter) is **renamed in place, not altered**. Internal state names
(`state-first-run.md`, `state-triage.md`, etc.) are unchanged. This feature is purely a
rename; any state-machine behavior changes belong to features 002–005.

### Sequencing constraint (hard ordering)

**This feature MUST land AFTER content features 002/003/004** (REQUIREMENTS.md §10 P3 +
dependency note). Those features edit `canonical/skills/aid-interview/` **in place** (C-2 —
extend, don't fork): they rewrite SKILL.md, restructure `references/` (e.g. the shared
elicitation engine, calibration, triage), and may add/remove reference files. A directory
rename run concurrently would collide with — or strand — those in-place content edits and
produce merge/render churn. Therefore the rename is gated on 002/003/004 being merged, then
operates on their final file set. (It is NOT gated by the feature-001 spike.) The aid-plan
execution graph must place feature-006 downstream of 002/003/004.

### DoD / Verification — operationalizes AC-8

The feature is **Done** when ALL hold (the rename task's acceptance gate):

1. **Canonical renamed + self-clean.** `canonical/skills/<NEW-NAME>/` exists (history-preserved);
   `grep -rn "aid-interview\b" canonical/skills/<NEW-NAME>/` returns **zero** stale command/name
   self-references.
2. **Zero stale references — scoped sweep matching the inventory.** A boundary-aware
   `grep -rn "aid-interview"` over the **shipped/canonical surface set** — `canonical/`, the 5
   `profiles/` trees, the `.claude/` dogfood skill mirror, the install manifests (5
   `emission-manifest.jsonl` + `.aid/.aid-manifest.json`), `site/`, `docs/`, `tests/`, root
   `README.md`, `examples/`, and `dashboard/home.html` + `.aid/dashboard/home.html` — returns
   **zero** live `/aid-interview` command tokens and `skills/aid-interview/` path tokens. The
   **only** permitted remaining `aid-interview`-prefixed matches in that set are the **protected
   `aid-interviewer` agent** (its `grep -rn "aid-interviewer"` count is **unchanged** vs.
   pre-rename) and the **deliberately-kept reference *filenames*** (`interview-loop.md` /
   `interview-strategies.md` and any like content artifacts). **Explicitly NOT in this sweep
   (consistent with the inventory, and with the precedent commit `cf6cb1af`, which touched 0
   `.aid/knowledge` files):**
   - **`.aid/knowledge/`** (the dogfood KB, ~9 `/aid-interview` tokens) — its drift is reconciled
     **separately by `/aid-housekeep`**, NOT by this rename's gate;
   - **`.aid/work-*/` + `.aid/design/`** (~100 occ — historical `| /aid-interview |` changelog
     source-tags and the feature SPECs themselves) — **out of scope**; sweeping them would corrupt
     records.
   - **`dashboard/server/tests/fixtures/**/.aid/work-*`** (frozen sample work-dir artifacts) +
     **`dashboard/reader/tests/test_feature009.py`** — **out of scope** (frozen test sample data;
     rewriting it would invalidate the fixtures). No pytest job runs in CI (verified — none in
     `.github/workflows` or `run-all.sh`), so AC-8 "CI green" is unaffected. *(The `dashboard/home.html`
     command string AND its paired assertion test `test_index_html.py` ARE in scope — see inventory.)*
   The acceptance sweep and the blast-radius inventory are defined over this same scoped surface
   set — they MUST agree (a literal whole-repo zero is neither required nor achievable).
3. **5 trees rendered + old dir pruned.** Each `profiles/*/skills/<NEW-NAME>/` exists, each
   `profiles/*/skills/aid-interview/` is gone, and each `emission-manifest.jsonl` reflects the
   swap (generator full run, clean).
4. **DBI byte-identity.** The DBI test passes — `<NEW-NAME>/` is byte-identical across the 5
   host trees and the dogfood mirror.
5. **Manifests + docs site current.** `.aid/.aid-manifest.json` paths updated;
   `gen-reference.mjs` entry renamed (count unchanged); `skills.md` regenerated; Astro build
   passes; `grep aid-interview site/` returns zero live refs.
6. **CI green.** render-drift, DBI, ASCII-only, installer (incl. Windows lane), and docs/Astro
   gates all pass on the PR — the master-only heavy gates included (run `tests/run-all.sh` with
   HOME pinned + the `site` Astro build locally before claiming green, per the
   master-CI-only-on-master constraint).

Maps directly to SPEC AC-8 (byte-identical propagation across 5 trees + old dir orphan-pruned +
manifests/skill-count-surfaces/docs-site updated + CI green) and NFR-6 (DBI cross-tool parity).

### Open Questions

- **Final skill name.** `<NEW-NAME>` (lean `aid-define`) is a deferred work-time choice — must be
  ratified by the owner and resolved to a literal before the rename task runs (see *Name decision*).
- **Reference-filename rename (deliberately deferred — recommend NO).** `references/interview-loop.md`
  and `interview-strategies.md` carry the substring "interview". This spec leaves them **unrenamed**:
  they name the interviewing *activity* (content), not the skill *command*, and renaming them is
  cosmetic churn with no functional effect — the precedent (`aid-ask`→`aid-query-kb`, single
  `SKILL.md`) offers no guidance. Two caveats for aid-plan/aid-detail to confirm: (a) features
  002/003/004 may already restructure/remove these files in place, so the rename operates on their
  *final* `references/` set; (b) if a future naming-coherence pass does rename them, it is a
  separate content change, not part of this rename, and must update each file's own self-references
  + the `.aid/.aid-manifest.json` path entries accordingly.
