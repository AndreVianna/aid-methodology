# Canonical Registration And Count Reconciliation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature created by splitting feature-011 three ways (owner decision). Takes the canonical-authoring and render wiring (**C-2**), the manifest-lockstep obligation (**C-3**), the registration inventory, and the count-surface reconciliation. Requirements half authored fresh from REQUIREMENTS.md §5.9, §7 C-2/C-3, and the two registration acceptance criteria feature-011 carried | /aid-specify |
| 2026-07-28 | Technical specification carved from feature-011's D1, D2, D6, L1, Feature Flow and External Integrations, then re-derived against the branch state after the three pre-existing defects were fixed | /aid-specify |
| 2026-07-28 | Final-gate finding fixed — D1's description of `render.py`'s `skills` branch completed to include the verbatim `scripts/` copy (line 594, `is_dir()`-guarded), noted as unexercised today since no canonical skill ships one | /aid-specify |

## Source

- REQUIREMENTS.md §5.9 Decision paragraph — the accepted cost of a separate skill: "one more skill
  in the canonical-to-profiles render and the install manifests"
- REQUIREMENTS.md §5.6 consequences 2 and 4 — if the rendering research adopts a third-party
  dependency, it lands in `technology-stack.md` / `infrastructure.md` / CI, and carries licence and
  update obligations
- REQUIREMENTS.md §7 Constraints — **C-2** (the skill is authored in the canonical tree and rendered
  to every host profile by the existing profile renderer; it must not be hand-maintained per
  profile), **C-3** (adding a skill touches the install and emission manifests, which the KB already
  flags as lockstep hazards — the change must keep them consistent)
- REQUIREMENTS.md §9 — the two registration criteria feature-011 carried: the skill appears in every
  host profile install tree with no hand-maintained profile copy, and every manifest accounts for
  the added file set

**Carries the known debt hazard.** `.aid/knowledge/tech-debt.md` records the install-manifest
lockstep problem as `[HIGH]`-severity item **L4**: several surfaces independently declare the shipped
file set, and a single missed update silently ships a broken install for one channel. Adding a skill
and a script area touches exactly that surface. This feature owns keeping them consistent and should
be reviewed with that debt item in hand. The Knowledge Base also records that after any canonical
edit the **full** profile generator must run, not a per-script renderer, or the render-drift gate
fails on stale emission manifests.

**Dependency position.** The earliest non-research feature. The wiring must land before the other
features have a place to put code, and the render must run before anyone can see which surfaces the
render does *not* cover. It is largely mechanical, and its blast radius is confined to generated
trees and count-bearing prose — it cannot change the behaviour of any shipped skill.

## Description

A new skill has to actually ship. It is authored once in the canonical source and rendered out to
every host profile by the existing renderer; it is never hand-maintained per profile, and the
rendered copies are never edited. Adding it touches the manifests that declare what gets installed
and what gets emitted, and those manifests have to stay in step with each other — this is a known
hazard in this project, not a theoretical one.

Most of that machinery already tracks itself. The generator rewrites every emission manifest on each
run and the installer walks whole directories rather than a per-skill list, so the manifests are not
where the risk actually lives. The risk lives in the hand-written surfaces that state how many skills
exist, and in the two hand-written rosters that name them one by one. A skill count appears in the
project readme, in four reference documents, and inside five per-profile readmes that live in
generated trees but are not themselves generated. A skill name appears in the site generator's
curated roster and in the mirror of that roster its test holds. Miss one and the repository quietly
tells a newcomer something untrue.

This feature therefore has two jobs that look different and are the same job: get the new skill into
every tree the renderer owns, and get every hand-written number and roster that describes those trees
back into agreement with what is actually on disk. It also fixes the count claims that are *already*
wrong today, because the honest way to add one to a wrong number is to correct the number first.

Finally, if the rendering research selects a third-party drawing library, its packaging lands here —
the dependency manifest, the lockfile, the update monitoring, and the licence record are all
registration surfaces, and pre-agreeing where they go is what keeps them from being discovered
mid-execution.

## User Stories

- As a **maintainer/architect**, I want the skill authored once canonically and rendered to every
  host profile, so that no profile drifts and no rendered copy needs hand-maintenance.
- As a **maintainer/architect**, I want the install and emission manifests updated together, so that
  no distribution channel silently ships a broken install.
- As a **maintainer/architect**, I want every count surface reconciled against what is on disk
  rather than against a sibling copy, so that adding the next skill does not require finding eleven
  numbers by hand.
- As a **newcomer to the project**, I want the stated number of skills to match the number that
  exists, so that I can trust the documentation I am reading.
- As the **AID methodology owner**, I want any third-party rendering dependency to land in a
  private, pinned, monitored, licence-recorded package inside the canonical script area, so that the
  published CLI wrappers keep their empty dependency sets.

## Priority

Must

## Acceptance Criteria

- [ ] Given the new skill authored in the canonical source, when the full profile render runs, then
      the skill appears in every host profile install tree and no profile copy is hand-maintained.
- [ ] Given the new skill and its script area, when the install and emission manifests are checked,
      then all of them account for the added file set consistently — no manifest is left behind.
- [ ] Given a canonical edit for this work, when the render is verified, then the full generator has
      been run and the render-drift check passes with no stale emission manifest.
- [ ] Given the reconciled repository, when `tests/canonical/test-doc-counts.sh` runs, then every
      asserted count surface states the current derived count and the suite passes with no surface
      left behind.
- [ ] Given a count or roster assertion anywhere in the repository, when it is reviewed after this
      feature lands, then it compares a derived artifact to the source of truth rather than to a
      sibling literal — no new hardcoded total is introduced, and the pre-existing hardcoded totals
      this feature touches are replaced rather than incremented.
- [ ] Given a third-party rendering dependency, if one is adopted, when its packaging is reviewed,
      then it is private and unpublished, exactly pinned with a committed lockfile, covered by
      dependency monitoring, licence-recorded, and absent from both published wrapper manifests.

---

## Technical Specification

> Grounded in `.claude/skills/generate-profile/SKILL.md` and
> `.claude/skills/generate-profile/scripts/render.py`, `canonical/EMISSION-MANIFEST.md`,
> `canonical/aid/templates/generated-files.txt`, `canonical/aid/templates/shortcut-catalog.yml`,
> `tests/canonical/test-doc-counts.sh`, `site/scripts/gen-reference.mjs` +
> `site/scripts/.reference-manifest.json` + `site/scripts/__tests__/gen-reference.test.mjs`,
> `docs/diagram-content-reference.md`, `lib/aid-install-core.sh`, `.github/dependabot.yml`, and the
> KB docs `module-map.md`, `infrastructure.md`, `technology-stack.md`, `tech-debt.md`.

### Data Model

#### D1 — The registration inventory: what a new skill actually touches

The requirements half calls the install and emission manifests a lockstep hazard. Reading the
machinery narrows that to a precise picture, and the picture matters because it decides which tasks
`/aid-detail` produces. The registration surfaces fall into three classes: **derived** surfaces that
auto-track and need no source edit at all; hand-written **count** surfaces that a parameterised test
suite already guards; and hand-written **roster** surfaces, some guarded by a hard failure and some
by nothing at all. The manifests themselves are in the first class — the genuine hazard is narrower
and different from where the requirements half places it.

**Class A — derived; no source edit required.** Verified, not assumed:

| Surface | Why it auto-tracks |
|---|---|
| `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/emission-manifest.jsonl` | The generator emits one record per rendered file and rewrites all five manifests on every run. `canonical/EMISSION-MANIFEST.md` "Asset Kinds" maps `canonical/skills/` wholesale to each host's `skills/` root; there is no per-skill list. `render.py`'s `translate == "skills"` branch enumerates `src_dir.iterdir()` directories, requires `SKILL.md`, and emits that plus `references/*.md` **and, when present, a verbatim copy of `scripts/`** (`render.py` line 594, guarded by `scripts_dir.is_dir()`). No canonical skill currently ships a `scripts/` directory, so the branch is unexercised today — but it means a skill *may* ship one without extra wiring, which matters if `/aid-graph` later does. |
| The five `profiles/<tool>/` install trees and the dogfood `.claude/` tree | Same render. Never hand-edited — `.aid/knowledge/module-map.md` Invariants, "Edit `canonical/`, never `profiles/`". |
| `.aid/.aid-manifest.json` (the per-install manifest) | Written by the installer at install time from what it copied. `lib/aid-install-core.sh` walks whole tool-native directories (`_prune_native_dir "${target}/.cursor/skills"` and siblings); it holds no per-skill list. |
| `site/src/content/docs/reference/skills.md` | Generated by `site/scripts/gen-reference.mjs` from `canonical/skills/*/SKILL.md`, per `site/scripts/.reference-manifest.json`. Its intro count comes from `onDisk.length`, so the number is data-driven. |

**Class B — hand-written count surfaces, guarded by `tests/canonical/test-doc-counts.sh`.** That
suite derives its counts from disk and then asserts each listed file states the current number:

```bash
SKILLS=$(find canonical/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
ROWS=$(grep -c '^  - name:' "$CATALOG")
REPURPOSE=$(grep -c '^    repurpose: true' "$CATALOG")
SHORTCUTS=$((ROWS - REPURPOSE))
```

Verified on the branch: `SKILLS=111`, `AGENTS=9`, `ROWS=94`, `REPURPOSE=30`, `SHORTCUTS=64`, and the
suite passes **31/31** today. Because `/aid-graph` is a curated hand-authored skill and not a
`shortcut-catalog.yml` row, `SKILLS` moves 111 → 112 while `AGENTS`, `ROWS`, `CANON`, `ALIAS`,
`REPURPOSE` and `SHORTCUTS` are unchanged. Of the suite's 29 surface assertions, exactly the eleven
parameterised on `${SKILLS}` go red:

| File | Needle that must state the new count |
|---|---|
| `README.md` | `112 skills` |
| `docs/repository-structure.md` | `112 skill definitions` |
| `docs/aid-methodology.md` | `112 skill directories` |
| `docs/glossary.md` | `112 skills total` |
| `docs/diagram-content-reference.md` | `112 skills` |
| `docs/install.md` | `` 112 `aid-`-prefixed skill `` |
| `profiles/claude-code/README.md` … `profiles/antigravity/README.md` (5 files) | `112 skills` |

The five `profiles/<tool>/README.md` files are the one genuinely awkward case: they live **inside**
generated trees but are **not** emitted by the generator. Verified: `README` matches zero records in
all five `emission-manifest.jsonl` files, and `render.py`'s `skills` branch emits only `SKILL.md`
plus `references/*.md`. They therefore survive the render — the pure-mirror boundary only deletes
paths a previous manifest recorded (`canonical/EMISSION-MANIFEST.md` "Safety-Boundary Semantics") —
and must be hand-edited. This is the real residue of the lockstep hazard and the concrete evidence
behind tech-debt item **L4**, whose own description cites "five install manifests plus two
installer-test lists all asserted each other and 'passed' while every one of them was missing a
shipped, security-relevant file. The tests ran; they did not bite."

The same zero-record fact settles a second question: a **skill's own `README.md` is canonical-only
maintainer documentation and never ships.** `canonical/skills/aid-summarize/README.md` exists and
appears in no install tree. `canonical/skills/aid-graph/README.md` is therefore written for
contributors reading `canonical/`, and is **not** one of the surfaces that satisfies the
discoverability requirement — those belong to feature-013.

**Class C — hand-written rosters.** Two are guarded by a hard failure; the rest by nothing:

| Surface | Required change | Guard |
|---|---|---|
| `site/scripts/gen-reference.mjs` `SKILL_GROUPS` | Add `{ name: 'aid-graph', phase: '…' }` to the **Knowledge Base Maintenance** group, beside `aid-summarize` | **Hard failure.** `generateSkillsPage()` computes `expected = curatedNames ∪ allCatalogNames` and throws `[gen-reference] skills drift` when `onDisk` differs. |
| `site/scripts/__tests__/gen-reference.test.mjs` `CURATED_SKILL_NAMES` | Gains `aid-graph` (21 → 22) | **Hard failure**, see D2 — the roster is a hand-mirror of `SKILL_GROUPS`, so the two must move together. |
| `.claude/skills/generate-profile/SKILL.md` | Two stale count claims re-anchored, not incremented (D2) | **None** |
| `site/scripts/gen-reference.mjs` header comment | A stale count claim re-anchored (D2) | **None** |
| `.aid/knowledge/module-map.md` | A `graph/` row in "Script Modules by Area", the `canonical/skills/*` count, and a `canonical/skills/aid-graph/` mention | **None** — ship time, feature-013 |
| `.aid/knowledge/capability-inventory.md`, `.aid/knowledge/release-tracking.md` | A capability entry and an `## Unreleased` `[NEW]` item | **None** — ship time, feature-013 |

#### D2 — The count surfaces after the three defect fixes: what genuinely breaks at 112

Three defects that earlier revisions of this specification routed elsewhere have been **fixed on
this branch**, all in `canonical/` with a clean re-render (1765 files, deterministic VERIFY pass,
dogfood byte-identity 711/711). Each is re-verified here rather than taken on report, because two of
them change what this feature has to do.

| # | Defect | Fix, verified on disk | Effect on this feature |
|---|---|---|---|
| 1 | Node floor split — preflight asserted ≥ 18 while the validators' `package.json` declares `>=20` | `summarize-preflight.sh` Check 5 now reads `[ "$NODE_VERSION_MAJOR" -lt 20 ]` with the message `Node.js >= 20 is required`, citing the Playwright 1.61.1 constraint; `state-preflight.md` item 5 matches; `.aid/knowledge/technology-stack.md` breaks the summarize validators' ≥ 20 out from the npm wrapper's ≥ 18 and its Version Concerns gotcha now reads **Four** Node floors | None here — it lands in feature-011's degradation section and feature-010's preflight. Recorded so no reader of this SPEC re-reports it. |
| 2 | `grade-summary.sh` did not score `NM`, so an `NM`-only failure could not reduce `kb.html`'s Machine Grade | `NM` is now in the pool loop, `WEIGHTS[NM]=2` (same as `S2`), `CHECK_NAMES[NM]="No-Mermaid-engine (D-012)"`, the grade loop and the report. **Max points moved 68 → 70.** The result is derived independently of `S2` via `grep -qE "NM\..*\[PASS\]"` against the validator log, matching the emitted `NM. No-Mermaid-engine [PASS]` line | None here; it strengthens feature-011's D3 argument. |
| 3 | `gen-reference.test.mjs` asserted hardcoded totals that were wrong | The suite is re-anchored to derived set comparisons against the skill directories and the catalog. `CURATED_SKILL_NAMES` grew 18 → **21** (it had omitted the three ticket skills) and the asserted shortcut total of 76 was itself wrong — the true catalog-emitting count is **64** | **Changes this feature's analysis.** See below. |

**The verified composition, which every count claim in this work must match.** Derived on the branch
rather than quoted: `find canonical/skills -mindepth 1 -maxdepth 1 -type d | wc -l` → **111**;
`grep -c '^  - name:' shortcut-catalog.yml` → **94**; `grep -c '^    repurpose: true'` → **30**.

> **111 skill directories = 21 curated + 64 catalog-emitted + 26 catalog-repurpose.**

Two partitions of the same set are both correct and both appear in the repository, which is worth
stating so a reviewer does not read one as a contradiction of the other. Four curated skills
(`aid-deploy`, `aid-monitor`, `aid-query-kb`, `aid-ask`) are *also* `repurpose` catalog rows, so
`21 + 64 + 26` and `docs/diagram-content-reference.md`'s `17 + 64 + 30` describe the same 111
directories. Any number this work writes must be reconcilable to one of the two; **94** and **76**
are reconcilable to neither and are dead literals.

**What actually goes red when the 112th skill lands — re-derived against the code as it now stands,
not carried forward.**

| Surface | Goes red? | Why, and what the fix costs |
|---|---|---|
| `tests/canonical/test-doc-counts.sh` | **Yes — eleven assertions** | Unchanged from the earlier analysis, and re-verified: `SKILLS` is derived, so all eleven `${SKILLS}` needles move together. Eleven one-word edits across six docs and five profile READMEs. This suite needs **no edit itself**; it is the proof that the eleven landed. |
| `site/scripts/__tests__/gen-reference.test.mjs` | **Yes — one assertion** | Not for a count reason. `expect(sections).toHaveLength(CURATED_SKILL_NAMES.length)` compares the rendered `### \`aid-…\`` sections against a hand-mirrored roster. Registering `aid-graph` in `SKILL_GROUPS` renders a 22nd section against a 21-name list. The fix is one array entry. **The derived re-anchoring did not remove this**: it made the suite immune to *catalog* growth, and the curated roster remains a hand-mirror by design, because there is nothing else on disk to derive "is this skill curated?" from. |
| `site/scripts/gen-reference.mjs` | **Yes — throws** | `expected = curatedNames ∪ allCatalogNames` must equal `onDisk`. Without the `SKILL_GROUPS` entry the generator raises `[gen-reference] skills drift`. A hard failure, not silent drift — good, and it is why the two edits above are inseparable. |
| `.claude/skills/generate-profile/SKILL.md` | **No — and that is the problem** | Nothing guards it. It is stale **twice**: VALIDATE step 1 says "The full taxonomy is **92 skill directories**" with `ls canonical/skills/ \| wc -l # expect 92`, and the completion checklist says "92 skills (14 classic + aid-triage + aid-ask + 76 shortcuts, one per non-`repurpose` catalog row)". Both the total and the composition are wrong: 92 → 111, 14 classic → 21 curated, 76 → 64. |
| `site/scripts/gen-reference.mjs` comments | **No** | Two of them. The header says it generates "94 skill directories (16 classic + aid-triage + aid-ask + 76 catalog-driven shortcuts)", and the comment immediately above `SKILL_GROUPS` says "16 classic skills" where the array holds 21. The code below both is fully dynamic and correct. Deliberately left unfixed by the defect sweep and folded into this feature's scope by owner decision — they are count claims, and this is the count-reconciliation feature. |
| `docs/diagram-content-reference.md` roster-test description | **No** | It states the `gen-reference` roster test "asserts 111 on-disk dirs = the 17 curated skill names ∪ all 94 catalog rows". After defect fix 3 the test asserts no total at all — it compares sets. The identity it describes is the *generator's*, not the test's, and the sentence needs correcting when the count moves. |
| `.aid/knowledge/kb.html` four-plane module map | **No** | Generated, hand-edit-forbidden. Corrected by a `/aid-housekeep` SUMMARY-DELTA regeneration, which `.aid/knowledge/STATE.md` Q8 already records as `**Deferred:**`. Not this feature's edit. |

**Design rule adopted here: anchor to the source of truth, never to a sibling literal.** This is
tech-debt L4's own measure 2, *invariant-anchoring* — "every assertion must compare a derived
artifact to the **source of truth** … never to a sibling copy that can drift in lockstep". Defect fix
3 applied that rule to the site test; this feature applies it to the two surfaces that still hold
literals:

- `generate-profile`'s VALIDATE step drops both `92` claims and asserts the identity
  `gen-reference.mjs` already enforces: the on-disk directory set equals the curated skill names
  union every `shortcut-catalog.yml` row name. A **set** comparison, which cannot go stale. Its
  checklist line loses the `(14 classic + … + 76 shortcuts)` composition and cites the derived
  command instead.
- `gen-reference.mjs`'s header comment states the identity rather than a total, so the file that
  *enforces* the identity also *describes* it, and the two cannot disagree.

Bumping `92 → 93` and `94 → 95` would leave both surfaces wrong and would hide pre-existing drift
inside this work's diff. Re-anchoring fixes the class rather than the instance, and is the reason
`test-doc-counts.sh` has stayed correct while these drifted: it derives its counts.

#### D3 — Third-party adoption gate (conditional on FR-18 / STATE.md Q2)

FR-18's option space is unrestricted, so a build step and a third-party renderer are both admissible;
neither is chosen yet. This feature fixes the **gate** any such adoption must clear, so the research
can price its options and `/aid-detail` can schedule the consequences. Every row is a consequence
REQUIREMENTS.md §5.6 already records. It lands here rather than in feature-011 because every
condition names a packaging, manifest, or monitoring surface — the C-2/C-3 registration surface —
and not a validator.

| # | Gate condition | Grounded in |
|---|---|---|
| G1 | The dependency lives in a `private: true`, not-published dev/validator package **inside the canonical script area** — never in `packages/npm/package.json` or `packages/pypi/pyproject.toml`. The precedent is `canonical/aid/scripts/summarize/package.json` (`"private": true`, Playwright as a `devDependency`). | `.aid/knowledge/technology-stack.md` Key Dependencies: both wrappers declare empty dependency sets, "so install is fast and supply-chain-light". That invariant must survive. |
| G2 | The version is pinned exactly and a lockfile is committed. | `canonical/aid/scripts/summarize/package.json` pins `"playwright": "1.61.1"` with a committed `package-lock.json`; `playwright-provisioning.md` mandates `npm ci`, never `npm install`. |
| G3 | `node_modules/` is never shipped. Already guaranteed: `render.py` declares `_EXCLUDE_DIRS = frozenset({"node_modules", ".git"})`, so it appears in no profile tree and no emission manifest; `.gitignore` covers it. | `render.py`; `playwright-provisioning.md` "Dependency isolation" |
| G4 | `.github/dependabot.yml` gains an ecosystem entry for the new manifest directory. It currently tracks **only** `package-ecosystem: "github-actions"`, so a new npm manifest would go unmonitored — directly the licence/update obligation of §5.6 consequence 4. | `.github/dependabot.yml` |
| G5 | Licence and attribution are recorded: the licence text or SPDX id and the attribution the licence requires, carried with the vendored or fetched asset. | §5.6 consequence 4 |
| G6 | `.aid/knowledge/technology-stack.md` gains rows in **Frameworks & Tooling** and **Key Dependencies**; `.aid/knowledge/infrastructure.md` gains the build step in its render/build chain. If a CI lane is needed, `.aid/knowledge/test-landscape.md`'s CI Lanes table gains it. Authored here, landed at ship time by feature-013. | §5.6 consequence 2 |
| G7 | The graph's own preflight reports the missing toolchain with an actionable message rather than failing obscurely later — the C-5 shape. **Owned by feature-010** (its P5); named here so the gate is complete, not to claim it. | C-5; feature-010 P5 |
| G8 | If CDN delivery is selected, AC-6's documented-prerequisites obligation is discharged in the artifact itself and in the `S2 [N/A]` validation line. **The validation-line half is feature-011's C1**; this row owns only the recorded prerequisite. §5.6 consequence 3 requires the research to state the non-portability cost plainly and prefer vendoring at comparable interaction quality. | AC-6; §5.6 consequence 3 |

If the research selects a vendored, no-build option, G1/G2/G3/G4/G6 collapse to nothing and only G5
and G8 remain. That asymmetry is worth surfacing to whoever weighs the options: **the cheapest
packaging for this repository is still vendoring**, not because FR-16 requires it — it no longer does
— but because five of the eight gate conditions exist only to contain a build chain.

### Feature Flow

The canonical-authoring-then-render wiring (C-2), in the order a contributor must perform it. Every
step is a real command from `.aid/knowledge/technology-stack.md` Build/Test Commands or
`.aid/knowledge/test-landscape.md` Test Commands.

1. **Author canonically.** Create the skill directory — `SKILL.md`, `README.md`, and the eleven
   `references/state-*.md` files feature-010's state machine declares — the six-file `graph/` script
   area, and the `knowledge-graph/` template set (see L1). Nothing is written into `profiles/` or
   `.claude/` by hand. This feature owns that the directory exists and is complete; it authors none
   of the bodies.
2. **Amend the shared templates.** feature-006's two contract amendments
   (`reviewer-ledger-schema.md`, `kb-authoring/frontmatter-schema.md`).
3. **Run the FULL generator** — never a per-script renderer:
   ```bash
   python .claude/skills/generate-profile/scripts/run_generator.py
   ```
   This renders all five trees, rewrites all five emission manifests, performs the manifest
   diff/deletion pass, and runs the verify spine. `.aid/knowledge/tech-debt.md` Gotchas is explicit:
   "Render-drift needs the FULL generator … otherwise the render-drift gate fails on stale
   `profiles/` emission manifests."
4. **Confirm no render drift.** The documented check re-runs the generator and then diffs, which is
   deliberate: a second render over an already-rendered tree must produce byte-identical output, so
   the command proves both that `profiles/` matches `canonical/` and that the render is stable.
   ```bash
   python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/
   ```
5. **Reconcile the count surfaces.** Update the eleven Class-B files, add the `SKILL_GROUPS` roster
   entry with its `CURATED_SKILL_NAMES` mirror, and re-anchor the two literal-holding surfaces of D2.
   Then:
   ```bash
   bash tests/canonical/test-doc-counts.sh
   ```
   `SKILLS` is derived from disk, so this suite is the mechanical proof that no count surface was
   left behind — it is the closest thing the repository has to a documentation manifest.
6. **Regenerate the site reference and run its tests:**
   ```bash
   cd site && node scripts/gen-reference.mjs && npm test
   ```
   Step 5's `SKILL_GROUPS` edit is a precondition: without it `gen-reference.mjs` throws
   `[gen-reference] skills drift`, and without the matching `CURATED_SKILL_NAMES` entry the section
   count assertion fails (D2).

Steps 3 and 4 are ordered before step 5 deliberately: the render is what makes
`profiles/<tool>/README.md` visible as a hand-maintained exception, and doing the count reconcile
first would invite a second render and a second reconcile.

The ship-time surfaces — the four discoverability documents, the Knowledge Base entries, and the
full HOME-pinned canonical suite — are **feature-013's**, and run after this sequence completes.

### Layers & Components

#### L1 — New canonical files

Following `.aid/knowledge/module-map.md` Conventions ("Where a new skill goes: create
`canonical/skills/aid-<name>/SKILL.md` (+ a `references/` subdir for state files)") and the Skill
contract in that doc's Contracts section (valid `name` / `description` / `allowed-tools` /
`argument-hint` frontmatter; any REVIEW state emits a reviewer ledger graded by `grade.sh`).
`aid-summarize` is the shape precedent: `SKILL.md` + `README.md` + ten `references/state-*.md`.

| Path | Owner |
|---|---|
| `canonical/skills/aid-graph/SKILL.md` | feature-010 (all sections but `## References`); **this feature** owns `## References` |
| `canonical/skills/aid-graph/README.md` | **this feature** — canonical-only; not rendered into any profile tree (D1) |
| `canonical/skills/aid-graph/references/state-{preflight,stale-check,validate,visual-gate,fix,done}.md` | feature-010 |
| `canonical/skills/aid-graph/references/state-{enumerate,extract,emit}.md` | feature-004 / feature-005 / feature-003 |
| `canonical/skills/aid-graph/references/state-gap-report.md` | feature-006 |
| `canonical/skills/aid-graph/references/state-render.md` | feature-007 |
| `canonical/aid/scripts/graph/{graph-preflight,graph-stale-check,kb-write-fence,grade-graph}.sh` | feature-010 |
| `canonical/aid/scripts/graph/detect-kb-gaps.mjs` | feature-006 |
| `canonical/aid/scripts/graph/coverage-predicate.mjs` — the shared coverage predicate, imported by the detector under Node and inlined into `graph.html` for the browser | feature-007 |
| `canonical/aid/templates/knowledge-graph/*` — the graph template set | feature-007 |

Two render consequences, verified against `render.py` and `canonical/EMISSION-MANIFEST.md`. First,
the template directory renders as a template set exactly as `knowledge-summary/` does. Second, and
the one with a real constraint attached: `.mjs` is in `render.py`'s `_TEXT_EXTENSIONS`, so both
`.mjs` files pass through `substitute_filenames` and `rewrite_install_paths` on the way into each
tree. Neither may contain a `canonical/…` path or a filename placeholder, or the rendered copies
diverge from canonical and feature-007's `GV02` byte-identity check between `graph.html`'s inlined
region and the module file fails in the profile trees while passing in `canonical/`. The detector
imports its neighbour by relative sibling specifier, which survives the rewrite untouched.
feature-013's `GR05` is the assertion that pins the pair.

**No `package.json` accompanies either file.** An earlier revision carried a
`canonical/aid/templates/knowledge-graph/package.json` ESM marker for feature-006; the owner
repointed the shared module to `.mjs`, which needs no marker, and the requirement is withdrawn. That
is the better outcome for this feature specifically: a `package.json` inside a *template* directory
would render into all five profile trees, adding manifest surface and putting a stray manifest into
every adopter's install where their own tooling could misread it.

This feature does **not** author any of those bodies. Its obligation is that everything shippable
ships: that the directory exists canonically, and that `SKILL.md` and every `references/*.md` render
into all five profile trees plus the dogfood `.claude/` tree.

#### L2 — The three seams this feature sits on

Stated identically in the sibling SPECs so the four cannot drift.

| Boundary | This feature (012) | The other side |
|---|---|---|
| **012 / 010** | Owns `## References` in `SKILL.md`, the directory's existence, and the render | feature-010 owns every other `SKILL.md` section and every `graph/` bash script's body |
| **012 / 011** | Owns the packaging and manifest surface of any adopted dependency (D3) | feature-011 owns every edit to `canonical/aid/scripts/summarize/*` and whether its two contingencies fire |
| **012 / 013** | Owns a documentation edit whose reason is **a number**: the eleven `${SKILLS}` needles, and the literal-holding surfaces of D2 | feature-013 owns a documentation edit whose reason is **a roster entry or prose**: the skill-inventory tables, the Mermaid group boxes, the site catalogue placement, and the Knowledge Base entries |

The 012/013 seam is the only one where the two features edit the same *file*, and the rule above is
what keeps them from editing the same *line*. `README.md`, `docs/aid-methodology.md` and
`docs/diagram-content-reference.md` each take a count edit from this feature and a roster edit from
feature-013. `/aid-detail` should sequence them in that order — count first, roster second — because
`test-doc-counts.sh` is the cheaper gate and gives a clean signal before prose changes land on top.

#### L3 — What this feature does **not** test

No new test suite is introduced here. The proof of this feature is entirely existing machinery:

| Proof | Suite |
|---|---|
| Every count surface reconciled | `tests/canonical/test-doc-counts.sh`, **unmodified** — its derived `SKILLS` count makes it the gate, and it needs no edit because it is parameterised (D1 Class B) |
| The render is complete and stable | `run_generator.py && git diff --exit-code -- profiles/` (Feature Flow step 4) |
| The site roster is consistent | `cd site && npm test` after the `SKILL_GROUPS` + `CURATED_SKILL_NAMES` pair lands |

The suite that asserts the *shipped* result across all five trees —
`tests/canonical/test-graph-skill-registration.sh` — is **feature-013's**, because it can only run
after this feature's render and it asserts the same thing feature-013's documentation surfaces claim.

### External Integrations

**Conditional and currently empty.** No third-party dependency is introduced by this feature as
specified. D3 defines the eight-condition gate any FR-18 adoption must clear, and names the exact
files each condition touches. Until STATE.md Q2 resolves, the integration surface is unchanged:
`.aid/knowledge/technology-stack.md` Key Dependencies stays accurate, `packages/npm` and
`packages/pypi` keep their empty dependency sets, and `.github/dependabot.yml` keeps its single
`github-actions` ecosystem.

This section exists rather than being omitted because the decision is live and its landing point must
be pre-agreed: if the research recommends a bundled renderer, the work lands **here**, under D3, and
not as an unplanned discovery during execution.

### Migration Plan

Nothing this feature touches changes any skill's runtime behaviour. Two surfaces holding stale
literals are re-anchored; eleven count needles move; the render runs.

| # | Change | Blast radius | Verification |
|---|---|---|---|
| M1 | `generate-profile`'s VALIDATE step and completion checklist re-anchored from `expect 92` / `92 skills (14 classic + … + 76 shortcuts)` to a set identity (D2) | Maintainer tooling only; not shipped | Run the skill's VALIDATE step against the live tree and confirm it passes at 112 |
| M2 | `gen-reference.mjs`'s header comment re-anchored from `94 … 76 catalog-driven shortcuts`, and its `SKILL_GROUPS` comment from `16 classic skills`, to the identity the file enforces (D2) | Comments only; the code is already dynamic | Read-back; no behavioural test applies |
| M3 | `SKILL_GROUPS` gains `aid-graph` and `CURATED_SKILL_NAMES` gains the mirror entry (D1 Class C) | Site generator + its test; inseparable pair | `cd site && node scripts/gen-reference.mjs && npm test` |
| M4 | Eleven count surfaces reconciled 111 → 112 (D1 Class B) | User-facing docs + five hand-maintained profile READMEs | `bash tests/canonical/test-doc-counts.sh` |
| M5 | Full generator run + render-drift confirmation | All five profile trees + `.claude/` | `run_generator.py && git diff --exit-code -- profiles/` |

M1 and M2 are the only rows that touch something already broken. Both are in scope here because this
feature is the one that trips them, and because incrementing a stale literal would ship a known-wrong
number inside a change whose whole purpose is keeping the count surfaces honest.

#### Reported for separate resolution — not fixed here

Two count-adjacent findings, carried over from feature-011 with the count-reconciliation scope and
keeping their original identifiers so the ledger reads continuously across the split. The findings
earlier revisions listed as `U1` and `U2`, and the site-test literal drift, are **gone because they
are fixed** (D2). `U3`, `U4` and `U5` stayed with feature-011, because each is about
`/aid-summarize`'s scripts or its grading prose rather than a count surface. `U8` is no longer a
report — the owner folded it into this feature's scope, so it is `M2` above.

| # | Finding |
|---|---|
| U6 | `.aid/knowledge/module-map.md` "Script Modules by Area" lists eight areas; `canonical/aid/scripts/` holds nine on disk (`works` is missing from the table). This work adds a tenth (`graph`), so the table needs both rows at ship time — **feature-013 D3** carries it. |
| U7 | `docs/diagram-content-reference.md` states the `gen-reference` roster test "asserts 111 on-disk dirs"; after the defect fix the test asserts no total at all, only set membership and a section count against the curated roster (D2). The identity it describes belongs to the generator, not the test, and the sentence needs correcting when the count moves. |

**Deliberately left open.** Whether an FR-18 build step is adopted, and therefore whether D3's
G1–G4 and G6 apply at all. The gate is specified; the trigger is not this feature's to pull.
`/aid-detail` should schedule D3's consequences as conditional work behind D-2 and FR-18 rather than
as committed tasks.
