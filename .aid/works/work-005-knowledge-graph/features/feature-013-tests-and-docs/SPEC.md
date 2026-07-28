# Skill Discoverability And Ship-Time Verification

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature created by splitting feature-011 three ways (owner decision). Takes the documentation surfaces, the ship-time Knowledge Base updates, the registration test suite, and the aggregate test gate. Requirements half authored fresh from REQUIREMENTS.md §5.9 and the two discoverability/coverage acceptance criteria feature-011 carried | /aid-specify |
| 2026-07-28 | Technical specification carved from feature-011's L3 (registration suite), L4 (documentation surfacing) and the ship-time steps of its Feature Flow | /aid-specify |

## Source

- REQUIREMENTS.md §5.9 Decision paragraph — the accepted cost of a separate skill includes "some
  duplicated preflight/writeback prose", which is a documentation obligation, and the skill must be
  findable where the other skills are
- REQUIREMENTS.md §9 — the two criteria feature-011 carried that are neither reuse nor registration:
  the new skill is listed in the reference documentation, the site's skill catalogue and the project
  readme; and automated suites exercise its preflight, its staleness behaviour, and its artifact
  validation, consistent with how `/aid-summarize` is covered

**Dependency position.** Last. Every surface here describes something another feature built, so each
one can only be written truthfully once that feature has landed. This is the ship gate, and its
value is that it is the single place a reviewer can stand to ask "is this actually finished?"

**Why it is a feature and not a checklist.** The Knowledge Base records the failure this feature
exists to prevent: tech-debt item **L4** describes a cycle in which "five install manifests plus two
installer-test lists all asserted each other" while every one of them was stale. Documentation
surfaces that nothing derives and nothing tests are exactly that failure mode, and treating them as
an afterthought at the end of another feature is how they got that way.

## Description

A skill that ships but cannot be found has not really shipped. A newcomer looks for skills in four
places — the reference documents under `docs/`, the site's generated skill catalogue, the project
readme, and the diagrams that map the toolkit — and the new skill has to appear in all of them, in
the group a reader would look for it in, described the way the other skills are described.

Only one of those four is generated. The rest are hand-authored prose and hand-drawn diagrams, and
the repository has already learned once that hand-authored inventories drift. So the work here is not
only to add a name in four places; it is to add it in the places the project's own maintenance
contract says must move together when a skill is added, and to leave the Knowledge Base describing
the toolkit that now exists rather than the one that existed before.

The other half is verification. Each feature in this work brings the tests that prove its own
mechanism, but two things can only be checked at the end: that the skill genuinely arrived in all
five host profile trees and the dogfood tree, byte-for-byte, and that the whole canonical suite is
still green when run the way the project requires it to be run. Neither can be asserted from inside
the feature that built the thing; both belong to the last feature that touches the branch.

## User Stories

- As a **newcomer to the project**, I want the new skill listed where the other skills are
  documented, so that I can discover it without reading the source tree.
- As a **newcomer to the project**, I want the skill to appear in the toolkit diagrams alongside its
  siblings, so that I can see where it fits in the pipeline rather than only that it exists.
- As a **maintainer/architect**, I want a suite that asserts the skill actually arrived in every
  rendered tree, so that a missed render is caught mechanically rather than by a reader noticing.
- As a **maintainer/architect**, I want the Knowledge Base to describe the toolkit as it now stands
  at the moment the work ships, so that the next feature starts from an accurate map.
- As the **AID methodology owner**, I want the new skill's automated coverage to be as good as
  `/aid-summarize`'s before the work is called done, so that the newer skill is not the weaker one.

## Priority

Must

## Acceptance Criteria

- [ ] Given the shipped skill, when the reference documentation, the site's skill catalogue, and the
      project readme are checked, then the new skill is listed in each.
- [ ] Given the shipped skill, when the toolkit diagrams and their maintenance reference are
      checked, then the skill appears in the diagrams that the maintenance contract names as
      skill-addition triggers, and the reference itself is updated in the same change.
- [ ] Given the new skill, when its test coverage is checked, then automated suites exercise its
      preflight, its staleness behaviour, and its artifact validation, consistent with how the
      existing summary skill is covered.
- [ ] Given the completed render, when the registration suite runs, then it confirms the skill's
      canonical definition and every rendered copy exist across all five host profiles and the
      dogfood tree, and that assertion compares each tree to the canonical source rather than to
      another tree.
- [ ] Given the branch immediately before it ships, when the full canonical suite is run the way the
      project documents it, then it passes — and the run is performed locally, because this gate does
      not run on feature branches.
- [ ] Given the shipped work, when the Knowledge Base is checked, then the new skill has a capability
      entry, the new script area appears in the module map, and the release-tracking document records
      the addition.

---

## Technical Specification

> Grounded in `docs/repository-structure.md`, `docs/aid-methodology.md`, `docs/glossary.md`,
> `docs/install.md`, `docs/diagram-content-reference.md`, `README.md`,
> `site/scripts/gen-reference.mjs` + `site/scripts/sync-docs.mjs` +
> `site/scripts/.synced-manifest.json`, `tests/run-all.sh`, `tests/coverage-parity.sh`,
> `tests/canonical/test-guardrails-d012.sh` (assertion-label precedent), `.github/workflows/test.yml`,
> and the KB docs `test-landscape.md`, `module-map.md`, `capability-inventory.md`,
> `release-tracking.md`, `tech-debt.md`.

### Data Model

#### D1 — The four discoverability surfaces

The requirement is that a newcomer finds the skill where the others are listed. Four surfaces carry
it, and only one of them is generated:

| Surface | Mechanism | This feature's edit |
|---|---|---|
| Reference documentation | `docs/repository-structure.md`, `docs/aid-methodology.md` (skill-inventory tables A/B/C + the G1 Mermaid group box), `docs/glossary.md`, `docs/install.md` — hand-edited | The **roster** entries: `aid-graph` in the inventory tables and the G1 group box. The **count** needles in the same files belong to feature-012 (L2). |
| The site's skill catalogue | `site/src/content/docs/reference/skills.md`, **generated** from `canonical/skills/*/SKILL.md`, then `node site/scripts/gen-reference.mjs` | None directly. The generator's `SKILL_GROUPS` entry is feature-012's; this feature verifies the rendered page carries the skill in the right group with a usable description. |
| The project readme | `README.md` — the on-demand skill list beside `/aid-summarize`. Its `R1` Mermaid diagram is hand-authored with no sync step (`docs/diagram-content-reference.md` §R1, "Edit at the source") | The list entry and the `R1` diagram node |
| `docs/aid-methodology.md`'s synced copy | `site/src/content/docs/concepts/methodology.md`, regenerated by `node site/scripts/sync-docs.mjs` per `site/scripts/.synced-manifest.json`. **Never hand-edit the site copy.** | None — it follows from the source edit plus the sync command |

**The site catalogue's quality depends on a file this feature does not own, and that is worth saying
once.** `gen-reference.mjs` reads each skill's `description` straight from its own frontmatter, so
the catalogue entry is only as good as `SKILL.md`'s `description` field — which feature-010 authors.
This feature's obligation is to *check* that the rendered entry reads as a complete one-paragraph
summary next to its siblings, and to raise it against feature-010 if it does not, rather than to
edit the generated page.

**`docs/diagram-content-reference.md` is a contract, not just a document.** Its maintenance rule says
"if you add, remove, or relabel a diagram, update this reference in the same change", and its Update
triggers index already names a skill add/remove as a trigger touching the kb.html **Four-plane module
map**, the site methodology skill diagrams, the README **R1**, and the `gen-reference` roster test.
All of those are updated as part of this feature except the count needle, which is feature-012's, and
`kb.html`, which is generated.

`.aid/knowledge/kb.html` shows the skill count in its four-plane module map. It is generated and
hand-edit-forbidden; the correction is a `/aid-housekeep` SUMMARY-DELTA regeneration, which is the
same handling `.aid/knowledge/STATE.md` Q8 records as `**Deferred:**` for its own count drift. Not
this feature's edit, and listed so nobody adds it to the diff.

#### D2 — Test coverage: who owns which suite, and what is left for the end

`.aid/knowledge/test-landscape.md` records prompt-driven skill state machines as "State machines not
machine-tested … Accepted (by design)", covered by dogfooding and review. So no suite drives
`/aid-graph` end to end, and the coverage obligation is discharged over the deterministic machinery
around it. That machinery is spread across six features, and the rule this work adopts is **a suite
lives with the mechanism it proves** — a test authored anywhere else goes stale the moment its
subject changes, because its author is not the person editing the subject.

That leaves this feature two suites nobody else can own, and a census obligation.

| Suite | Owner | Why there |
|---|---|---|
| `test-graph-preflight.sh`, `test-graph-stale-check.sh`, `test-graph-read-only.sh` | feature-010 | They assert the skill's own runtime behaviour |
| `test-graph-gap-ledger.sh` | feature-006 | Asserts the ledger and the shared predicate |
| `test-validate-html-profiles.sh`, `test-validate-visuals-profiles.sh` (both contingent) | feature-011 | They *are* that feature's proof that `kb.html` is unchanged; separating a carve-out from its guard is exactly the failure the carve-out design exists to prevent |
| `test-guardrails-d012.sh` (existing, unmodified) | feature-011 | The standing pin on `kb.html`'s `S2`/`NM` behaviour |
| `test-doc-counts.sh` (existing, unmodified) | feature-012 | The count-surface gate |
| **`test-graph-skill-registration.sh` (new)** | **this feature** | It can only run after every other feature has rendered, and it asserts the same thing D1 claims in prose |
| **The aggregate gate** | **this feature** | Below |

**The census.** The third acceptance criterion is about coverage *parity* with `/aid-summarize`, not
about any one suite, so this feature's discharge of it is a check performed at ship time: preflight,
staleness, and artifact validation each have at least one suite that fails when that behaviour breaks.
If one does not, the gap is raised against the owning feature rather than patched here — writing a
missing test for someone else's mechanism is how a test ends up asserting the wrong invariant.

**The aggregate gate, and why it must be run locally.** `.aid/knowledge/test-landscape.md` records
that `.github/workflows/test.yml` runs on **push + PR to `master` only** — confirmed in the workflow's
own `branches: [master]` triggers — and names the consequence as a known gap: "Full `run-all.sh` runs
on master/tag only … Run `bash tests/run-all.sh` + `site` build locally before merge." A green feature
branch therefore proves nothing about the canonical suite. The gate is:

```bash
HOME="$(mktemp -d)" bash tests/run-all.sh
```

HOME-pinning is not optional and not stylistic: `test-landscape.md`'s HOME-pinning hazard states the
migration scan defaults its root to `$HOME`, so an unpinned run migrates the developer's real
repositories. The suite is discovered by the `tests/canonical/test-*.sh` glob, so the four new suites
this work adds need **no edit to `tests/run-all.sh`** — that is a stated contract of the runner.

One runner-adjacent obligation comes with adding suites: `tests/coverage-parity.sh` maintains a
before/after multiset inventory of executed assertion IDs and "fails mechanically on any un-excused
net-removed/reduced assertion". Adding assertions is safe by construction; the gate matters here only
because feature-011's contingent suites may *not* be added, and a plan that assumed them must not
leave a removal behind.

#### D3 — The ship-time Knowledge Base updates

The work's KB-update-at-ship decision puts these last, after the artifacts they describe exist:

| Document | Update |
|---|---|
| `.aid/knowledge/module-map.md` | A `graph/` row in "Script Modules by Area", the `canonical/skills/*` count, and a `canonical/skills/aid-graph/` mention. **Two rows, not one**: the table lists eight areas while `canonical/aid/scripts/` holds nine on disk — `works` is missing — so `graph` makes ten and the pre-existing omission is corrected in the same edit rather than inherited. |
| `.aid/knowledge/capability-inventory.md` | One capability entry for `/aid-graph`. |
| `.aid/knowledge/release-tracking.md` | An `## Unreleased` `[NEW]` item. |
| `.aid/knowledge/test-landscape.md` | The canonical-suite count (currently 133, `ls tests/canonical/test-*.sh \| wc -l`) and a row for the graph suites. Derived, so it is stated as the live figure at ship time rather than predicted here. |
| `.aid/knowledge/technology-stack.md`, `.aid/knowledge/infrastructure.md` | **Only** if feature-012's D3 gate fired and a third-party dependency was adopted. |

The Knowledge Base is deliberately **not** covered by `tests/canonical/test-doc-counts.sh` — that
suite's own header scopes it to "the public-facing docs a reader trusts (README + docs/ + profile
READMEs)" and excludes `.aid/knowledge/` because it "carries heavy version-history sections and is
reconciled by `/aid-housekeep`". So nothing mechanical will catch a missed row here. That is the
reason these updates are a named acceptance criterion rather than a step in a list.

### Feature Flow

Runs after feature-012's render and reconcile sequence completes, and after every other feature's
suites are green.

1. **Add the roster entries.** `docs/aid-methodology.md` inventory tables and G1 group box,
   `docs/repository-structure.md`, `docs/glossary.md`, `docs/install.md`, and `README.md`'s
   on-demand list and `R1` diagram (D1). Update `docs/diagram-content-reference.md`'s update-triggers
   entry in the same change, per its own maintenance rule.
2. **Sync the site copy** of the methodology document — never hand-edit it:
   ```bash
   node site/scripts/sync-docs.mjs
   ```
3. **Read back the generated catalogue.** Confirm `site/src/content/docs/reference/skills.md` places
   `aid-graph` in the Knowledge Base Maintenance group with a description that reads as a complete
   summary beside `aid-summarize`'s. Raise a defect against feature-010's `SKILL.md` frontmatter if
   it does not; do not edit the generated page.
4. **Run the registration suite** (L1):
   ```bash
   bash tests/canonical/test-graph-skill-registration.sh
   ```
5. **Run the coverage census** of D2 and raise any gap against its owning feature.
6. **Run the aggregate gate, HOME-pinned:**
   ```bash
   HOME="$(mktemp -d)" bash tests/run-all.sh
   ```
7. **Update the Knowledge Base** (D3).

Steps 1 and 2 are inseparable — a source edit without the sync leaves the site showing the previous
toolkit — and step 3 is deliberately a *read-back* rather than an edit, because the page is
generated and editing it would be reverted by the next build.

### Layers & Components

#### L1 — The registration suite

`tests/canonical/test-graph-skill-registration.sh`, discovered by the `tests/canonical/test-*.sh`
glob with no edit to `tests/run-all.sh`. It sources `tests/lib/assert.sh` and uses the
`ID + description` assertion-label convention of `tests/canonical/test-guardrails-d012.sh`.

| ID | Assertion |
|---|---|
| `GR01` | `canonical/skills/aid-graph/SKILL.md` exists with all four required frontmatter keys (`name`, `description`, `allowed-tools`, `argument-hint`) |
| `GR02` | Every one of the five `emission-manifest.jsonl` files contains a record whose `dst` ends `skills/aid-graph/SKILL.md` |
| `GR03` | The corresponding file exists in each `profiles/<tool>/` tree |
| `GR04` | `.claude/skills/aid-graph/SKILL.md` exists (dogfood parity) |
| `GR05` | Each rendered tree contains both `aid/scripts/graph/coverage-predicate.mjs` and `aid/scripts/graph/detect-kb-gaps.mjs`; `node --input-type=module -e "import('<tree>/aid/scripts/graph/coverage-predicate.mjs')"` resolves with no `package.json` anywhere above it in that tree; and the rendered `coverage-predicate.mjs` is byte-identical to the canonical one — proving the shared predicate is importable where the rendered detector runs and that the text transforms found nothing to rewrite in it |
| `GR06` | Every `references/state-*.md` file present canonically is present in each rendered tree — a set comparison, not a count, so adding a state file later cannot leave the assertion trivially true |

`GR02` is the assertion that would have caught the class of bug tech-debt **L4** describes: it
compares the manifests to the **canonical source of truth** rather than to each other. `GR06`
generalises it from one file to the whole directory, which is where a partial render would actually
show up.

**This suite asserts the tree, not the branch.** It is deliberately free of any `.aid/works/` path,
so it satisfies A-6 and keeps working after the work folder is pruned. It reads `canonical/` and
`profiles/` directly rather than building a fixture, because the thing under test *is* the rendered
repository — a `mktemp -d` fixture could not observe a missed render.

#### L2 — The 012 / 013 seam

Stated identically in feature-012's L2 so the two cannot drift.

| Boundary | feature-012 | This feature (013) |
|---|---|---|
| A documentation edit | Owns it when the reason is **a number** — the eleven `${SKILLS}` count needles and the two surfaces still holding stale literals | Owns it when the reason is **a roster entry or prose** — inventory tables, Mermaid group boxes, the readme list, the diagram-reference triggers entry |
| The site catalogue | Owns `SKILL_GROUPS` and its `CURATED_SKILL_NAMES` mirror | Owns the read-back of the rendered page |
| Tests | Owns no new suite; leans on `test-doc-counts.sh` | Owns `test-graph-skill-registration.sh` and the aggregate gate |
| The Knowledge Base | Drafts the `technology-stack.md` / `infrastructure.md` rows if a dependency is adopted | Lands every KB edit at ship time |

`README.md`, `docs/aid-methodology.md` and `docs/diagram-content-reference.md` each take one edit
from each feature. `/aid-detail` should sequence feature-012's count edit first, because
`test-doc-counts.sh` gives a clean mechanical signal before prose lands on top of it.

### Migration Plan

Nothing changes shape. Every row adds a name to a list or a row to a table.

| # | Change | Blast radius | Verification |
|---|---|---|---|
| M1 | Roster entries in four `docs/` files and `README.md`, plus the `R1` diagram node (D1) | User-facing documentation | Read-back; `test-doc-counts.sh` still green (it asserts counts, which feature-012 already moved) |
| M2 | `docs/diagram-content-reference.md` update-triggers entry, in the same change as M1 per its own maintenance rule | The diagram maintenance contract | Read-back |
| M3 | `node site/scripts/sync-docs.mjs` | `site/src/content/docs/concepts/methodology.md` | `git diff` shows the synced copy moved with its source and nothing else |
| M4 | New `tests/canonical/test-graph-skill-registration.sh` (L1) | Additive; new suite | `bash tests/canonical/test-graph-skill-registration.sh` |
| M5 | Four KB documents updated at ship time (D3), including the pre-existing `works` omission in the module map | The Knowledge Base | The KB's own review gate; no mechanical guard exists (D3) |

**Deliberately left open.**

- **Which group `aid-graph` belongs to in `docs/aid-methodology.md`'s inventory tables.** The site
  generator places it in Knowledge Base Maintenance beside `aid-summarize` (feature-012's
  `SKILL_GROUPS` entry), and this feature follows that placement — but the methodology document's
  tables A/B/C use their own partition, and which of the three it lands in should be settled when the
  entry is written rather than guessed here.
- **Whether feature-011's two contingent suites exist at all.** If neither contingency fires, the
  suite census in D2 covers five suites rather than seven. Both outcomes are correct; the census
  reports what is there rather than asserting a number.
