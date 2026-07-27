# Grouped Skill Index

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-25 | Feature identified from REQUIREMENTS.md §1, §5 (FR-5), §9 (AC-8) | /aid-define |
| 2026-07-25 | Technical specification added | /aid-specify |

## Source

- REQUIREMENTS.md §1 Objective, §5 FR-5, §9 AC-8

## Description

The `/skills/` section's front door: a card index listing **every one of the 111 skills**,
grouped two levels deep — the curated four (`Support`, `Knowledge Base Maintenance`,
`Definition`, `Execution`) at the top, with `Definition` subdivided by the verb family derived
from `shortcut-catalog.yml` (the same field `gen-reference.mjs` already keys its family table
off, so the taxonomy cannot drift from the catalog).

Each card carries enough to pick a skill — name, one-line intent from frontmatter, its
group/family — and links to that skill's detail page. This feature also registers the section
in the site's sidebar contract.

**Placement rules (owner-corrected at cross-reference, Q1 — these override the grouping in
`gen-reference.mjs`'s `SKILL_GROUPS`, which is stale):**

- `aid-triage` is a **Support** skill, not a Definition skill.
- `Definition` opens with the **five full-path skills** in pipeline order, **un-subdivided**:
  `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`. None has a
  shortcut-catalog row, so no verb family is derived or invented for them.
- `aid-deploy` and `aid-monitor` are **ordinary shortcut skills** now — no longer main full path
  — and are placed under their own `deploy` and `monitor` verb families (each a family of one),
  not among the full-path skills.
- The verb-family subsections follow the five full-path skills.

Because §7 forbids modifying the existing generator, `reference/skills.md` will keep grouping
those three skills the old way until it is separately corrected. That inconsistency is accepted
and recorded, not resolved here.

It knowingly diverges from `reference/skills.md`, which stays a terse family summary; the two
surfaces coexist rather than one replacing the other.

## User Stories

- As an **AID maintainer**, I want to see every skill listed individually under a familiar
  grouping so I can find the one I am about to change without knowing its exact name.
- As a **newcomer to the repo**, I want the doorway skills grouped by verb family rather than
  dumped in one list, so the repetition is contained and the shape of the corpus is legible.
- As an **adopter reading the public docs**, I want to browse what AID can do before installing
  it.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-8 — Index shape.** Given every skill in `canonical/skills/`, when the index renders,
      then there is one card per skill, nested under the four curated groups, with the cards
      inside `Definition` subdivided by the verb family derived from the shortcut catalog; a
      skill whose card is missing, or which is filed under a group/family that disagrees with
      the catalog, fails the check.
- [ ] Given any card in the index, when it is followed, then it resolves to a page emitted by
      feature-001 (no dead cards).

---

## Technical Specification

> **Built on wave 1, which is fixed.** Feature-001's *Generator harness contract* and
> feature-003's `shapeCounts` manifest entry are adopted verbatim; nothing below redefines them.
> In particular: the generator is `site/scripts/gen-skills.mjs` with a `site/scripts/skills/`
> module cluster, `gen:skills` is chained after `gen:reference`, pages are `.md`, the index lives
> at `src/content/docs/skills/index.md` on route `/skills/`, slugs are the directory name by
> **identity**, and there is exactly one manifest (`site/scripts/.skills-manifest.json`) and one
> generator for the whole `/skills/` section.
>
> **Grounded in:** `REQUIREMENTS.md` §4, §5 (FR-5 + Placement rules), §7, §8, §9 (AC-8);
> `.aid/knowledge/` `INDEX.md`, `architecture.md`, `module-map.md`, `project-structure.md`,
> `technology-stack.md`, `authoring-conventions.md`; and direct reading of
> `site/scripts/gen-reference.mjs`, `site/scripts/__tests__/gen-reference.test.mjs`,
> `site/astro.config.mjs`, `site/src/components/overrides/Header.astro`,
> `site/src/content.config.ts`, `site/src/content/docs/reference/index.md`,
> `site/src/content/docs/reference/skills.md`, `site/package.json`,
> `canonical/aid/templates/shortcut-catalog.yml`, and `canonical/skills/*/SKILL.md`.
>
> **Note on `node_modules` citations.** This work's git worktree has no `site/node_modules`
> (feature-001's SPEC § Build-integration scope Part C records the same absence). Starlight
> internals cited below were read from the main checkout's install of the same pinned version —
> `@astrojs/starlight` **0.39.3** (`site/package.json`:24) — and every such claim is paired with an
> in-repo observable so it can be re-checked without `node_modules`.

### Data Model

**No schema changes.** No database, no persisted record type, and **no change to
`site/src/content.config.ts`**. The index page uses only Starlight's built-in `title`,
`description` and `sidebar` frontmatter plus the `generatedFrom` optional field the `docsSchema`
extension already declares (`content.config.ts`:9-18). `sidebar` is part of `docsSchema()` itself,
so the nested `sidebar.hidden` key specified below needs no `zod` addition.

> The `feature-005` / `feature-006` labels in `content.config.ts`:12-16 number a **previous**
> work's features, exactly as feature-001's SPEC warns. Nothing in this feature relates to them.

The only new persisted artifact is `site/src/content/docs/skills/index.md`, plus **one additional
row** in feature-001's existing `.skills-manifest.json` — no second manifest.

Three in-memory shapes, all internal to this feature and all built from feature-001's
`SkillRecord`:

```js
/** @typedef {{ name: string, route: string, intent: string }} SkillCard */
/** @typedef {{ verb: string, cards: SkillCard[] }} FamilySection */
/** @typedef {{ group: string, blurb: string, cards: SkillCard[], families: FamilySection[] }} GroupSection */
```

`SkillCard.name` and `SkillCard.route` are copied from `SkillRecord.dirName` / `SkillRecord.route`
rather than rebuilt, so a card's href cannot drift from the page feature-001 writes.
`FamilySection.verb` is the **raw catalog `verb` string**, never a display name — see
[Family derivation](#family-derivation).

### Feature Flow

Pure build-time transform, inside feature-001's single `gen:skills` pass. Feature-001's seven-step
order (DISCOVER → PARSE → RECORD → RENDER → WRITE → MANIFEST → GUARD) is **preserved unchanged**;
this feature adds steps between them and changes the relative order of none.

```
npm run build / npm run dev
  └─ prebuild / predev  →  sync:docs → gen:reference → gen:skills → fetch:release
       └─ gen:skills (site/scripts/gen-skills.mjs)
            1.  DISCOVER   canonical/skills/ → sorted directory names        [feature-001]
            2.  PARSE      SKILL.md frontmatter → Field[]                    [feature-001]
            3.  RECORD     SkillRecord[]                                     [feature-001]
            3a. CATALOG ←  read canonical/aid/templates/shortcut-catalog.yml [feature-002]
                           → rows[] + byName Map
            4.  RENDER     one detail page per record                        [feature-001]
            4a. ASSIGN  ←  SkillRecord[] × CURATED_GROUPS × catalog          [feature-002]
                           → GroupSection[]   (4 assignment guards, all throw)
            5.  WRITE      detail pages                                      [feature-001]
            5a. INDEX   ←  render + write src/content/docs/skills/index.md   [feature-002]
            6.  MANIFEST   entries += the index row; array re-sorted by src  [001 + 002]
            7.  GUARD      page-set drift (index.md excluded)                [feature-001]
            7a. CARDS   ←  every card target ∈ the page set just written     [feature-002]
```

`3a` is placed after `RECORD` only because nothing earlier needs it; it depends on no step and is
a pure file read. `4a` must follow `3` (it needs every record's `route` and `description`) and
precede `5a`. `7a` runs inside the same guard phase as `7`, after both writes, so it also catches
an index that references a page a later step failed to produce.

Every guard is an uncaught `throw`, so a failure exits non-zero, fails `prebuild`, fails
`npm run build`, and reds the `docs.yml` pull-request gate — the same enforcement path feature-001
specifies for AC-1.

### Layers & Components

Scripts-only, like feature-001: **no Astro component, no page route file, no style, no
client-side JavaScript.** The one exception to "scripts only" is a single additive edit to
`site/astro.config.mjs` (see [Navigation registration](#navigation-registration)).

#### Module layout

All new modules join feature-001's `site/scripts/skills/` cluster. The entrypoint stays flat.

| File | Owner | Purpose |
|------|-------|---------|
| `site/scripts/skills/catalog.mjs` | feature-002 | `loadShortcutCatalog(repoRoot) → { rows, byName }`. The **only** catalog reader in this cluster. |
| `site/scripts/skills/groups.mjs` | feature-002 | `CURATED_GROUPS` (the corrected taxonomy) + `assignGroups(records, catalog) → GroupSection[]`, carrying the four assignment guards. |
| `site/scripts/skills/summary.mjs` | feature-002 | `skillSummary(record) → string` — the one-line intent rule (first sentence, capped). |
| `site/scripts/skills/render-index.mjs` | feature-002 | Assembles `index.md`: frontmatter → marker → intro → divergence note → group/family sections. |
| `site/scripts/__tests__/gen-skills-index.test.mjs` | feature-002 | The AC-8 suite. |
| `site/scripts/gen-skills.mjs` | feature-001 (**edited**) | Gains steps 3a / 4a / 5a / 7a and the manifest row. Sanctioned by feature-001's Manifest contract: *"Feature-002 adds its index page as one more `entries` row in this same manifest, produced by this same generator run."* |
| `site/astro.config.mjs` | (**edited**) | One new top-level sidebar group. |

Conventions inherited from feature-001 and the three sibling scripts in `site/scripts/`: ESM
`.mjs`, `node:`-prefixed builtins only, kebab-case filenames, **2-space indentation** (matching the
directory, per feature-001's recorded divergence from `coding-standards.md`'s tab rule), pure
exported functions with the side effect confined to the entrypoint's
`import.meta.url === pathToFileURL(process.argv[1]).href` guard, and no new dependency.
`module-map.md`:143 records `site/ X canonical/` — the site does not consume the toolkit as code —
so this cluster follows site-local style, not the tab-indented `canonical/aid/scripts/**` house
style. `canonical/` is read, never `profiles/*` (§7).

**No `package.json` change.** `gen:skills` already exists after feature-001; the index rides the
same script. This feature's only build-wiring edit is the sidebar group.

#### Where the group and family assignment comes from

Two authorities, one each, and neither is `gen-reference.mjs`'s `SKILL_GROUPS`:

| Datum | Authority |
|-------|-----------|
| Which of the four groups a **curated** skill sits in | `CURATED_GROUPS` in `site/scripts/skills/groups.mjs` — a hand-maintained table implementing FR-5's Placement rules. |
| The **verb family** of every other skill | The `verb` field of that skill's row in `canonical/aid/templates/shortcut-catalog.yml` (field contract at `shortcut-catalog.yml`:35-39). |

Everything not named in `CURATED_GROUPS` falls into `Definition` and is filed under its catalog
`verb`. A skill in neither is a build error, not a silent omission.

##### Decision — the catalog reader is a new module, imported one-way

**Chosen: a deliberate re-implementation, isolated in `site/scripts/skills/catalog.mjs` and
imported one-way by the generator and by this feature's test.** It mirrors
`gen-reference.mjs`'s two regexes — the row opener `/^  - name:\s*(.+)$/` (`:102`) and the field
line `/^    ([a-zA-Z_]+):\s*(.*)$/` (`:111`) — plus `stripYamlScalar` (`:120-125`).

Three reasons, in order of force:

1. **Extracting a genuinely shared module is what §7 forbids.** The clean move — lift
   `parseShortcutCatalog` out of `gen-reference.mjs` and have both generators import it — edits
   `gen-reference.mjs`, which §7 freezes.
2. **Importing from `gen-reference.mjs` is not merely inelegant, it is destructive.** That file
   calls `main()` unconditionally at module scope (`gen-reference.mjs`:707), so `import { … } from
   '../gen-reference.mjs'` would regenerate all four reference pages and rewrite
   `.reference-manifest.json` as a side effect of resolving a constant. Feature-001 rejected the
   same import for the same reason.
3. **One copy inside this work, not three.** Putting the reader in a module rather than inline in
   `gen-skills.mjs` means the generator and the AC-8 suite share one implementation. Feature-001's
   corrected `gen-reference.test.mjs` keeps its own local reader (its SPEC, Part A) — that is a
   fixed wave-1 decision and is not reopened here; having that frozen generator's test import this
   feature's cluster would couple the two in the wrong direction.

*Rejected:* importing anything from `gen-reference.mjs` — it runs the other generator.
*Deferred debt:* when §7's freeze lifts, `catalog.mjs` is the natural home for the single shared
reader and `gen-reference.mjs` should import it.

**Contract of `catalog.mjs`** (narrower than `gen-reference.mjs`'s, deliberately):

```js
/** @typedef {{ name: string, verb: string, artifact: string, alias_of: string, group: string,
 *              intent: string, repurpose?: string }} CatalogRow */
loadShortcutCatalog(repoRoot) -> { rows: CatalogRow[], byName: Map<string, CatalogRow> }
```

- `rows` is in **file order** — load-bearing for family ordering below.
- Throws `[gen-skills] catalog parse` when a row has no `name`, no `verb`, or a duplicate `name`.
  `gen-reference.mjs`'s reader silently overwrites a duplicate (`:113`); a `Map` build plus this
  check cannot.
- **No `repurpose` filtering.** `gen-reference.mjs` restricts its family table to non-`repurpose`
  rows (`emittingShortcutRows`, `:132-134`) because those are the rows its build helper generates.
  This index cards **every** skill directory, and every catalog row has one, so all 94 rows
  participate. This is one of the two structural reasons the two pages' family membership differs
  — see [Divergence](#divergence-from-referenceskillsmd).

##### The corrected taxonomy — `CURATED_GROUPS`

Deliberately **not** named `SKILL_GROUPS`. The identically-named constant at
`gen-reference.mjs`:150-199 holds the stale taxonomy FR-5 overrides; a distinct name stops a future
reader assuming the two tables agree.

| Group | Members (order as rendered) | Subdivided? |
|-------|-----------------------------|-------------|
| `Support` | `aid-triage`, `aid-config`, `aid-set-connector`, `aid-unset-connector`, `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket` | no |
| `Knowledge Base Maintenance` | `aid-discover`, `aid-summarize`, `aid-housekeep`, `aid-update-kb`, `aid-query-kb`, `aid-ask` | no |
| `Definition` | **full-path block:** `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail` — then every unlisted skill, by verb family | families only |
| `Execution` | `aid-execute` | no |

Group order is fixed at Support → Knowledge Base Maintenance → Definition → Execution, matching
FR-5's own enumeration and `gen-reference.mjs`:150-199's presentation order.

What this table changes relative to `gen-reference.mjs`, and why:

- **`aid-triage` moves to `Support`**, first in the group. FR-5 Placement rules; the existing
  generator's roster entry at `gen-reference.mjs`:179 places it in `Definition`, restated in its
  own comment at `:363-365` ("the curated classic skills … already include `aid-triage` in the
  Definition group"). First in Support because it is the
  "I don't know where to start" router (`canonical/skills/aid-triage/SKILL.md`:4-11) — the answer a
  reader scanning Support most likely wants.
- **`aid-deploy` and `aid-monitor` leave the curated table entirely.** They carry catalog rows with
  `verb: deploy` / `verb: monitor` (`shortcut-catalog.yml`:840-855), so the ordinary rule files
  them under `### deploy` and `### monitor` — each a family of one — with no special case in code.
  `gen-reference.mjs`:185-186 lists them as curated Definition members.
- **`Definition` opens with exactly five skills, un-subdivided**, in pipeline order. None has a
  catalog row (verified: no `- name: aid-describe|aid-define|aid-specify|aid-plan|aid-detail` row
  exists in `shortcut-catalog.yml`), so no family can be derived and none is invented.

The member lists stay **explicit and hand-maintained**, not derived. Which skills are curated is a
curatorial choice, not a filesystem fact; deriving it would make the assignment tautological with
itself. This is the same reasoning feature-001 records for keeping `CURATED_SKILL_NAMES` explicit
(`gen-reference.test.mjs`:107-116), and it is safe here for the same reason: the clamp guard below
makes the table self-policing rather than trusted.

##### Family derivation

```
familyOf(record) = catalog.byName.get(record.dirName).verb        // for every non-curated skill
```

- **Family sections exist only for verbs actually present among Definition-assigned skills.** The
  family list is built by walking `catalog.rows` in file order, skipping any row whose name is in
  `CURATED_GROUPS`, and appending each newly-seen `verb` to an **ordered array** (not an object
  keyed by verb — feature-001's AC-6 rule 5 forbids object-key iteration over parsed data). A verb
  whose every member is curated therefore produces **no empty section**.
- **Family order = catalog first-appearance order.** *Chosen* because it is a pure function of the
  catalog file, needs no second list to maintain, and reproduces the family arrangement the
  catalog's own authors curated with their section comments. A maintainer reorders families by
  reordering the catalog — there is nowhere else to forget.
  *Rejected:* alphabetical (splits `change` from `create` and leads with `deprecate`); a
  hard-coded family-order list — that is precisely the construct that rotted in
  `gen-reference.mjs`'s `SHORTCUT_FAMILIES` (see **KI-009**). *(Renumbered by the orchestrator:
  three wave-2 agents each minted a "KI-007" concurrently. This feature's two issues are **KI-009**
  — the family table — and **KI-010** — the stale `SKILL_GROUPS`.)*
- **Card order within a family = catalog row order**, which puts canonical forms before their
  aliases. *Rejected:* alphabetical, which would print `aid-add-api` above `aid-create-api`.
- **Heading text is the raw verb in a code span** — `` ### `create` `` — so the heading *is* the
  catalog key. No display-name table exists to drift, and AC-8's parse is an exact match rather
  than a case-folding guess.

**Measured 2026-07-25 — dated diagnostic, not a contract.** Running the rule above over the live
tree assigns every directory exactly once, with no unassigned skill, no curated name lacking a
directory, and no catalog name lacking a directory. The `query` family comes out empty (both its
rows are curated into Knowledge Base Maintenance) and correctly produces no section — which is
exactly the case [OQ-1](#open-questions) is about. Every measurement quoted in this SPEC exists to
show an implementer what to expect on first run; §8 forbids any of them reaching **code, a page
template, or a test assertion**, all of which re-derive from source instead.

##### Assignment guards (all throw, all named)

Run inside `assignGroups()`, before anything is rendered:

| Guard name | Rule | Why it exists |
|------------|------|---------------|
| `unassignable skill` | Every directory under `canonical/skills/` is either in `CURATED_GROUPS` or has a catalog row. | **The clamp.** A new hand-authored skill fails the build by name instead of silently missing its card — the exact failure mode that produced KI-005. |
| `curated skill missing` | Every name in `CURATED_GROUPS` has a directory on disk. | A renamed or deleted curated skill cannot leave a phantom entry. |
| `duplicate assignment` | No name appears twice across `CURATED_GROUPS`, and no skill lands in two sections. | AC-8 says *one* card per skill. |
| `full-path catalog row` | None of the five full-path skills has a catalog row. | The un-subdivided block and the AC-8 family exemption both assume this. The day someone adds a row, the premise changes and the build says so. |

`assignGroups()` returns only after all four pass, so no downstream renderer needs a defensive
branch.

### UI Specs

*Activated: this feature's entire deliverable is a rendered page plus its place in the site's
navigation chrome. The card shape, the nesting, and the sidebar registration are the feature.*

#### Format decision — `.md` and a markdown link list

**Chosen: the index is a `.md` page, and a "card" is one markdown list item.**

```markdown
- [`aid-create-api`](/skills/aid-create-api/) — Create an API endpoint / middleware (contract, handler, validation).
```

**A real card component exists and is deliberately not used.** The site imports Starlight's
`CardGrid` / `LinkCard` on three hand-authored pages — `src/content/docs/index.mdx`:6,
`guides/pipeline.mdx`:8, `guides/maintainer.mdx`:8 — and `casulo.css`:27-28, 63 themes their
surface through `--casulo-bg-card` → `--sl-color-gray-6`. So this is a choice against an available
primitive, not an absence of one, and it needs the stronger justification given below.

Measured over all 111 `description` values, 2026-07-25 (dated diagnostics, not contracts):

| Rejected | Reason |
|----------|--------|
| `.mdx` + `<CardGrid>` / `<LinkCard>` | **(a) `LinkCard`'s `description` is plain text, and 70 of the 111 descriptions contain an authored inline code span.** Every one of those would print literal backticks, and the `<…>` placeholders inside them would lose the code-span protection that keeps markdown from swallowing them. A list item renders the author's own markdown — the same "faithful to the source" reasoning feature-001 used for the detail header. **(b) JSX-attribute escaping would become a build-breaking contract over machine-generated text:** 15 descriptions contain a `"`, 6 contain a `<` followed by a letter or `/`, and `aid-describe`'s contains `{`…`}`. Getting that escaper wrong fails the build rather than merely rendering badly. **(c)** All 12 `.mdx` files under `src/content/docs/` are hand-authored and import components; every generated page in the repo is `.md` (`gen-reference.mjs`:676-679), and feature-001 fixed the 111 detail pages as `.md`. An `.mdx` index would be the only generated `.mdx` in the repo and the odd file out in its own section. **(d)** `CardGrid` is a layout for a handful of cards, not for the whole corpus spread across every group and family on one page. |
| A markdown table per family | 3 descriptions contain a literal `|` (`aid-create-ticket`, `aid-set-connector`, `aid-update-ticket`), so a two-column table needs a second escaping layer over verbatim text — the same reason feature-001 rejected a table for the detail header, where it measured 8 such values across all frontmatter keys. A list needs no pipe escaping at all. |
| A hand-rolled `<div class="skill-card">` + CSS | `casulo.css` carries card **surface tokens** but no card **layout** class, so this means new CSS in a feature that otherwise touches no styling — to reproduce what `LinkCard` already provides, while keeping every drawback above. |

So "card" here means **a one-line list entry carrying name → route → intent**. Stated plainly
because FR-5 says "card": the requirement is *one addressable entry per skill carrying enough to
pick one*, and on a corpus this size, with descriptions this markdown-rich, the list item is the
faithful rendering and the component is the lossy one.

**Group and family live in the heading hierarchy, not on the card.** REQUIREMENTS §1 asks a card to
carry "name, one-line intent, group/family"; the two-level nesting is what carries the last of
those. Repeating `Definition · create` on 92 consecutive lines would re-introduce precisely the
repetition FR-5 asks the grouping to contain. AC-8 is checked against the nesting (see
[AC-8 test design](#ac-8-test-design)), so nothing is lost in verifiability.

#### The card's intent text

`skillSummary(record)` — the **first sentence** of the skill's frontmatter `description` (text up
to and including the first `. `), hard-cut at the last word boundary ≤ 157 characters with a
trailing `…` if longer, falling back to **feature-001's sentinel**
`AID skill <dir> — declared frontmatter contract, generated from canonical/.` when the file
carries no `description`.

> **Corrected 2026-07-27 (delivery-002 Q3).** This sentence previously read "falling back to the
> skill's own name", which contradicted feature-001 and contradicted the very next bullet's claim
> that the rule is reused **parameter-for-parameter**. Two independent things force feature-001's
> sentinel: that reuse claim, and this feature's own requirement that a card's text equal its
> page's `<meta name="description">` — unsatisfiable for a description-less skill if the two
> fallbacks differ. The fallback is unreachable in practice (all 111 skills carry a
> `description`, measured), so nothing rendered differently; the contradiction was corrected
> before task-018 was authored against it.

- **This is feature-001's page-`description` rule, deliberately reused parameter-for-parameter**,
  so a card's text and its target page's `<meta name="description">` are the same string.
  `gen-skills-index.test.mjs` asserts that equality for every skill, which pins the two together
  even though the code sits in two modules. If both are implemented in one sitting, feature-001's
  `render-page.mjs` should import `skillSummary` rather than keep a private copy — an
  implementation preference, not a contract change.
- **Escaping is the same code-span-aware rule** feature-001 specifies for
  `renderFrontmatterValue()`: `&` → `&amp;` and `<` → `&lt;` **only outside the author's own inline
  code spans**. Load-bearing on this page too, though on a narrower slice than feature-001's: it
  measured 39 *frontmatter values* carrying `<` + letter or `/`, of which **6 are `description`
  values** — the only field a card reads (`aid-create-ticket`, `aid-read-ticket`,
  `aid-set-connector`, `aid-triage`, `aid-unset-connector`, `aid-update-ticket`), and several of
  those sit inside an authored code span. Escaping blindly prints a literal `&lt;`; not escaping
  lets markdown swallow `<connector>` as a tag.
- **Source is the frontmatter, uniformly for all 111** — this feature's own Description says
  "one-line intent from frontmatter". *Rejected:* the catalog's `intent` field, which reads better
  for the doorways but exists for only 94 of 111 skills and would need a second rule and a second
  authority for card text.
- The link target is `record.route` verbatim (`/skills/<dir>/`), a root-absolute path. `base: '/'`
  (`astro.config.mjs`:25), and the site already writes links in this form
  (`reference/index.md`:8 → `/reference/overview/`).

#### Page structure

```
---
title: 'All Skills'
description: 'Every AID skill, one card each, grouped by skill group and — inside Definition — by verb family.'
generatedFrom: 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
sidebar:
  hidden: true
---

<!-- generated — do not edit; source: canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml -->

{intro paragraph — counts interpolated from the live scan}

{divergence note — see § Divergence}

## Support

{blurb}

- [`aid-triage`](/skills/aid-triage/) — …
…

## Knowledge Base Maintenance
…

## Definition

{blurb}

**The full path** — the five phases, in order:

- [`aid-describe`](/skills/aid-describe/) — …
- [`aid-define`](/skills/aid-define/) — …
- [`aid-specify`](/skills/aid-specify/) — …
- [`aid-plan`](/skills/aid-plan/) — …
- [`aid-detail`](/skills/aid-detail/) — …

### `fix`

- [`aid-fix`](/skills/aid-fix/) — …

### `create`
…

## Execution
…
```

- **Exactly two heading levels.** H2 = curated group, H3 = verb family.
  `tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 }` (`astro.config.mjs`:74) therefore
  renders the whole taxonomy — and only the taxonomy — as the page's on-page navigator. Going
  deeper would fall out of the TOC; going shallower would flatten the two levels FR-5 requires.
- **The full-path block carries no heading**, only a bold lead-in line. A `### Full path` heading
  would enter the TOC as a peer of the verb families and read as one, contradicting both
  "un-subdivided" and AC-8's "carry no family". A bold paragraph labels the block for a human
  without creating a family for a parser.
- `title: 'All Skills'` rather than `Skills`, because `reference/skills.md` already renders a page
  titled *Skills* (`gen-reference.mjs`:442); distinct titles keep the two distinguishable in the
  Pagefind results that will surface both.
- The generated marker is byte-identical to the sentence the existing pages carry
  (`gen-reference.mjs`:449, `<!-- generated — do not edit; source: … -->`, em-dash included), so
  the suites' `toContain('generated — do not edit')` idiom transfers.
- **Counts appear only by interpolation** from `records.length` and the catalog row set — no
  literal count in the generator, the page template, or a test assertion (§8). Per-shape counts are
  feature-003's `shapeCounts` manifest entry and nothing else; this page states none, needs none,
  and must not start quoting one.
- Frontmatter is serialized in the siblings' single-quoted style with `'` → `''`
  (`gen-reference.mjs`:72-80). That serializer emits flat scalar pairs only, so the nested
  `sidebar:` key is appended by `render-index.mjs` as a literal two-line block after the scalar
  pairs rather than passed through it.

#### Index grammar (the machine contract)

The renderer emits, and the AC-8 suite parses, exactly these line shapes. Nothing else in the page
may match them:

| Line | Regex | Meaning |
|------|-------|---------|
| Group | `` /^## (.+)$/ `` | Opens a group; clears the current family. |
| Family | ``/^### `([a-z][a-z-]*)`$/`` | Opens a verb family inside the current group. |
| Card | ``/^- \[`([a-z0-9-]+)`\]\((\/skills\/[a-z0-9-]+\/)\) — (.+)$/`` | One card: name, route, intent. |

A card with no family in scope belongs to the group's un-subdivided block. This grammar is what
makes AC-8 a parse rather than a substring hunt, and it is why the family heading holds a bare
code span and nothing else.

#### Navigation registration

One additive edit to `site/astro.config.mjs`, inserted **immediately after the `Reference` group**
(`astro.config.mjs`:107-120) and before `Releases`:

```js
{
  label: 'Skills',
  items: [
    { label: 'All skills', slug: 'skills' },
    { label: 'Every skill', collapsed: true, items: [{ autogenerate: { directory: 'skills' } }] },
  ],
},
```

Everything this depends on, verified:

- **A section tab appears for free.** `Header.astro` derives the header's second row from the live
  sidebar — "Tabs are derived from the live sidebar so they never drift from astro.config.mjs"
  (`Header.astro`:11) — one tab per top-level group (`:31-40`). No Header edit, and no risk of the
  tab bar drifting from the config.
- **`All skills` must be first in `items`.** The tab's destination is `links[0]?.href`
  (`Header.astro`:37) over the group's links collected in order (`:20-27, 34`), so item order is
  what makes the Skills tab land on the index rather than on whichever detail page sorts first.
  This is a load-bearing ordering, not cosmetics.
- **The autogenerated subgroup is what makes that tab work on a detail page.** `isActive` is
  `links.some((l) => l.isCurrent)` over the group's links, collected recursively
  (`Header.astro`:20-27, 38). With only the index registered, the Skills tab would never highlight
  on any of the 111 detail pages and every one of them would sit outside the site's navigation.
  This is the decisive argument for including the autogenerate.
- **`collapsed: true` is a real option on an explicit group** — `collapsed: z.boolean().default(false)`
  in Starlight's sidebar schema (`schemas/sidebar.ts`:26-27). The 111 links are present in the DOM
  but folded; Starlight expands the group containing the current page, so a detail page opens with
  its own entry highlighted.
- **The nested-`items` form is required.** `astro.config.mjs`:79-80 already records that Starlight
  ≥ 0.39.0 removed the combined `label` + `autogenerate` form; the `Get Started` group
  (`:86`) is the in-repo template for `items: [{ autogenerate: … }]`.
- **The index does not appear twice.** `sidebar.hidden: true` on `skills/index.md` removes it from
  the autogenerated tree — the filter at `navigation.ts`:243-244 is the *only* place `sidebar.hidden`
  is read, and it sits inside `treeify()`, which serves autogeneration only; explicit `slug:` items
  are unaffected. `reference/index.md`:4-5 already uses this exact idiom.
- **Detail-page order is alphabetical, for free.** Autogenerated entries sort by
  `sidebar.order ?? Number.MAX_VALUE`, ties broken by an `Intl.Collator` comparison of the route id
  (`navigation.ts`:296-313). No detail page sets `order`, so all 111 tie and sort by slug.
  **Feature-001's reserved `sidebar:` slot is therefore formally released: detail pages emit no
  `sidebar:` key at all**, and feature-001's renderer needs no change.
- **`slug: 'skills'` resolves to `skills/index.md`** — Astro's loader maps a directory index to the
  directory path, and Starlight's tree builder handles the case explicitly
  (`navigation.ts`:257-261). If it ever failed to resolve, Starlight throws at build time, which is
  the failure mode we want. *Rejected:* `link: '/skills/'` (the raw-href form used for the
  changelog at `:125`) — it always "works", including when the index was never generated.

**Two-level nesting, not one.** Putting the 111 links directly in the `Skills` group would force a
choice between an unusable 112-item list and collapsing the group, which would hide the index link
too. The subgroup keeps *All skills* always visible with the corpus folded behind one disclosure.

**Accepted cost:** ~112 extra sidebar anchors in the HTML of every page on the site. This is the
sidebar-size consequence of the all-111 decision FR-5 already took, and it scales linearly.

**Pagefind** indexes the index page like any other; no configuration
(`astro.config.mjs`:155-156).

#### Divergence from `reference/skills.md`

§7 freezes `gen-reference.mjs`, so the two surfaces will disagree and a reader must be able to see
*why* rather than conclude one is broken. Three mechanisms, in descending order of reliability:

1. **A generated note on this page**, immediately below the intro and above the first `## `
   heading, so it is not a TOC entry. It states, in one short paragraph: that
   [Reference → Skills](/reference/skills/) is a terse family **summary**, generated separately;
   that it groups `aid-triage`, `aid-deploy` and `aid-monitor` under *Definition* while this page
   files them per FR-5's Placement rules; that where the two disagree about grouping, **this page
   is authoritative**; and that the difference exists because the older generator is frozen, not
   because either page is stale-by-accident. The three names are a curatorial statement tied to
   FR-5, dated in the generator's comment — they are not derived, because deriving them would mean
   importing the frozen generator's `SKILL_GROUPS` (`gen-reference.mjs`:707 forbids it).
2. **Different sections, different framings.** The two pages sit in different sidebar groups and
   therefore different header tabs, with distinct titles (*Skills* vs *All Skills*) and distinct
   `description` frontmatter ("summarized by family" vs "one card per skill"). They read as two
   deliberate surfaces, not two attempts at the same list. Placing the `Skills` group directly
   after `Reference` makes the pairing visible in the tab bar.
3. **The asymmetry is stated, not hidden.** No reciprocal note can be added to
   `reference/skills.md` — its generator is frozen, and hand-editing its output would be
   overwritten on the next `prebuild`. So the back-reference exists in one direction only. That is
   recorded as **KI-010**, with the fix (correcting `SKILL_GROUPS`) named as follow-on work.

There is a second, larger axis of divergence a reader may notice, and the note deliberately does
**not** try to explain it in prose: the two pages disagree about *family membership* as well as
grouping, because `gen-reference.mjs`'s family table counts only non-`repurpose` rows
(`:132-134`, `:311`) whereas this index cards every catalog row. That page's family table
currently renders six rows with a count of `0`, plus detail text whose arithmetic reads `= 0` and
`-1 typed forms` (`reference/skills.md`:185-194) — a real defect in the frozen generator,
registered as **KI-009**.
Explaining someone else's broken table on this page would be worse than linking to it; the
authoritative-grouping sentence covers the reader, and the known issue covers the repo.

### Telemetry & Tracking

*Activated: feature-001 fixed an exact-line-count stdout contract for this generator, so anything
this feature adds to the console is a contract change and has to be decided rather than assumed.*

| Channel | Contract |
|---------|----------|
| stdout | **Unchanged. This feature adds no line.** Feature-001 specifies "exactly four lines per successful run"; the index is written inside that run and stays silent, so that contract holds verbatim and feature-001's suite cannot be broken by this feature. |
| stderr | Nothing on a successful run, per feature-001. |
| Counts in output | None emitted; and any count that reaches the *page* is interpolated from the live scan, never a literal (§8). |
| Failures | `throw new Error('[gen-skills] <guard>: <detail>')`, uncaught, matching feature-001's prefix and guard-name discipline. New stable guard names: `catalog parse`, `unassignable skill`, `curated skill missing`, `duplicate assignment`, `full-path catalog row`, `dead card`. Stable strings so a test can assert on them and a CI log can be grepped. |
| Exit codes | `0` / `1`, unchanged from feature-001. |
| Blast radius | A throw fails `prebuild` → `npm run build` → the `docs.yml` PR gate. |

### Migration Plan

*Activated: this feature edits a file another feature owns (`gen-skills.mjs`), edits the site's
central configuration, and must coexist with a frozen generator that publishes a competing view of
the same corpus.*

**What is touched, exhaustively.** Four things:

1. **New** — `site/scripts/skills/{catalog,groups,summary,render-index}.mjs` and
   `site/scripts/__tests__/gen-skills-index.test.mjs`.
2. **Edited** — `site/scripts/gen-skills.mjs` (feature-001's entrypoint): steps 3a/4a/5a/7a and the
   manifest row. Additive; feature-001's own steps and their order are untouched.
3. **Edited** — `site/astro.config.mjs`: one new top-level sidebar group.
4. **Generated** — `site/src/content/docs/skills/index.md`, committed like every other generated
   page in the repo.

Not touched: `gen-reference.mjs` (frozen by §7), its four generated pages, its manifest,
`src/content.config.ts`, `site/package.json`, `sync-docs.mjs`, any stylesheet, and any component.

**`astro.config.mjs` co-ownership.** This feature's edit is confined to the `sidebar` array and
does not go near the `mermaid({ … })` options at `:30-47`. Feature-003's OQ-1 asks the owner
whether to fix **KI-001** (the dropped `themeVariables`) in this work; if the answer is yes, that
fix lands in the same file. The two edits are in different literals and will not conflict
semantically, but they should be sequenced rather than made simultaneously by two agents. Noted
here rather than reopened as a question — the decision is feature-003's OQ-1, not this feature's.

**Manifest participation.** The index becomes one more `entries` row in
`site/scripts/.skills-manifest.json`, written by the same run:

```json
{ "src":  "canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml",
  "dest": "site/src/content/docs/skills/index.md" }
```

- The two-source comma-joined `src` is **byte-identical to the string
  `gen-reference.mjs`:447 already writes** for its own two-input page, including the source order,
  and identical to the index page's own `generatedFrom` value. One string, three places, no third
  spelling to drift.
- Feature-001 guarantees `entries` is "ordered by `src`, ascending". The row is **inserted into
  sorted position, not appended**. It lands first among the `canonical/skills/…` rows because `*`
  (U+002A) sorts before any lowercase letter, so the guarantee holds literally rather than
  approximately — and, being a pure string comparison, identically on every platform.
- `generatedPaths` is rebuilt from `entries` in the same order and gains
  `site/src/content/docs/skills/index.md`.
- Still **no `generatedAt`**, no wall clock, POSIX paths built by concatenation.

**Drift-guard interaction.** Feature-001's page guard already excludes `index.md` from its on-disk
comparison, so this page is invisible to it by design. This feature supplies the coverage the
exclusion leaves open, in two layers: the four assignment guards (every skill is carded exactly
once) and the `dead card` guard (every card target exists among the pages just written). Together
they close both directions of AC-8's first clause at build time, before any test runs.

**Idempotence (AC-6).** The index is a pure function of the sorted directory scan, the file order
of `shortcut-catalog.yml`, and the literal `CURATED_GROUPS` array. Concretely: the family list is
an ordered array built by first appearance (never `Object.keys`); cards within a family follow
catalog row order; curated cards follow the array's order; no clock, no `process.env`, no
randomness; pages are `'\n'`-joined and written `utf8`; every path is a POSIX string built by
concatenation. The suite asserts it as a byte comparison of run 1 against run 2, not via `git diff`
— matching feature-001's reasoning about this worktree's unresolvable `.git` pointer.

**Rollback** is: remove the sidebar group from `astro.config.mjs`, remove steps 3a/4a/5a/7a from
`gen-skills.mjs`, delete the four new modules, the test file, and
`src/content/docs/skills/index.md`, and drop the manifest row. Nothing else in the work depends on
the index — features 003–006 attach to detail pages, not to it.

**Build-cost note.** One more page, and ~112 extra sidebar anchors on every page of the site. The
page-count multiplication feature-001 flagged is unchanged by this feature.

#### AC-8 test design

`site/scripts/__tests__/gen-skills-index.test.mjs` — a **separate file** from feature-001's
`gen-skills.test.mjs`, each suite owning one artifact, mirroring feature-001's decision to keep its
suite separate from `gen-reference.test.mjs`. Run by the site's existing `npm test` → `vitest run`
(`package.json`:20), and enforced on pull requests by the CI step feature-001 adds.

Every expectation is re-derived from `canonical/skills/` and `shortcut-catalog.yml` on each run.
**No assertion compares anything to a numeric literal** — §8, and the defect class that produced
KI-005.

| # | Assertion | Derived from |
|---|-----------|--------------|
| 1 | The parsed card set equals the on-disk directory set, in **both** directions, with no name appearing twice. | `readdirSync(canonical/skills)` |
| 2 | The `## ` headings are exactly `['Support','Knowledge Base Maintenance','Definition','Execution']`, in that order. | array equality — a fixed taxonomy, no count |
| 3 | Every curated skill's parsed group equals `CURATED_GROUPS`'s, imported from `groups.mjs`. `aid-triage` → `Support` is additionally asserted by name. | `groups.mjs` |
| 4 | **Catalog agreement.** For every card that is not curated: it sits under `## Definition`, under a `### \`v\`` heading, and `v === catalog.byName.get(name).verb`. | `catalog.mjs` |
| 5 | **Full-path block.** The cards between `## Definition` and its first `### ` equal `['aid-describe','aid-define','aid-specify','aid-plan','aid-detail']` — exact array equality, so order and membership are pinned without a length literal. | explicit list (curatorial) |
| 6 | **The exemption is derived, not assumed.** None of those five has a catalog row (`byName.has(n) === false`). | `catalog.mjs` |
| 7 | `aid-deploy` sits under `### \`deploy\`` and `aid-monitor` under `### \`monitor\``, and neither appears in the full-path block. | implied by 4 + 5; asserted by name because AC-8 names them |
| 8 | **The clamp.** Every directory is curated or catalog-backed, and every curated name has a directory. | both sources |
| 9 | Family headings inside `Definition`, in document order, equal the catalog's first-appearance verb order restricted to non-curated rows. | `catalog.mjs` |
| 10 | **No dead cards.** Every card route resolves to an existing `src/content/docs/skills/<name>.md`. | filesystem |
| 11 | Each card's intent equals `skillSummary(record)`, and the unescaped summary equals the target page's `description` frontmatter. | `summary.mjs` + the rendered pages |
| 12 | No card line contains a `<` followed by a letter or `/` outside an inline code span. | the corpus |
| 13 | Marker present; the manifest carries the index row and lists it in `generatedPaths`; the manifest still has no `generatedAt`. | the manifest |
| 14 | Re-running the generator leaves `index.md` byte-identical. | byte comparison |
| 15 | The divergence note is present, sits before the first `## `, and links to `/reference/skills/`. | the rendered page |

**Why AC-8's family check can be scoped without weakening it.** AC-8 exempts the five full-path
skills from the family check and requires instead that they be present, ordered, and family-less.
Assertions 5 + 6 discharge both halves, and 6 converts the exemption from an asserted exception
into a **derived** property — if the corpus ever gains a catalog row for one of the five, the test
fails and the build's `full-path catalog row` guard fails with it, rather than the exemption
silently becoming a lie. Assertion 4 applies the catalog check to exactly the catalog-keyed cards
AC-8 scopes it to; assertion 3 covers the rest by curated-table agreement, so no card is
unchecked in either regime.

**Fixture discipline.** The suite builds its own expectations from `canonical/` and the catalog and
never reads anything under `.aid/works/`, per the transient-work-folder rule.

### Open Questions

- **OQ-1 — Do `aid-query-kb` and `aid-ask` stay in Knowledge Base Maintenance, or move to a
  `query` verb family under Definition?**

  *Why it is genuinely open.* Both carry shortcut-catalog rows with `verb: query`
  (`shortcut-catalog.yml`:866-881) **and** are curated into Knowledge Base Maintenance by the
  existing taxonomy (`gen-reference.mjs`:171-172). FR-5's Placement rules name `aid-triage`,
  the five full-path skills, and `aid-deploy`/`aid-monitor` — they do not mention these two. The
  precedent cuts both ways: `aid-deploy`/`aid-monitor` were *also* curated members with catalog
  rows, and the owner moved them out into families of their own. If that was a general principle
  rather than a specific correction, these two should follow.

  *Default implemented, so nothing is blocked:* **they stay in Knowledge Base Maintenance and carry
  no verb family**, on the reading that the owner's Q1 enumeration is exhaustive and silence means
  "unchanged". A consequence worth seeing: the `query` family then has no members left and, by the
  derivation rule, produces **no section at all** — a family that exists in the catalog but not on
  the page.

  *If the owner chooses the other reading*, the change is two names deleted from
  `CURATED_GROUPS`'s Knowledge Base Maintenance list; the `query` family then appears
  automatically, in catalog first-appearance order, with no other edit. Test assertions 3, 4 and 9
  follow the table and need no change.

- **Not a question, recorded for sequencing:** feature-003's OQ-1 (fix **KI-001**'s dropped
  `themeVariables` in this work, or file it) touches `site/astro.config.mjs`, which this feature
  also edits. Whichever way the owner answers, the two edits should be made in sequence. See
  § Migration Plan.
