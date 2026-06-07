# Concepts & Reference Sections

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR8, FR9), §10 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR8 Concepts, FR9 Reference)
- REQUIREMENTS.md §3 (Users — returning users, maintainers), §10 (Priority — Should/Could)

## Description

Build the understanding-oriented and information-oriented areas of the site. Concepts presents the
methodology in full — pipeline & phases, philosophy, the Knowledge Base, the agent model, feedback
loops, lite vs full, and AID vs spec-driven development (from `docs/aid-methodology.md`) — plus the
FAQ (from `docs/faq.md`). Reference presents the facts: CLI & subcommands (from `docs/install.md`),
a generated Skills / Agents / KB reference (from `canonical/`), settings keys (net-new,
generated from `.aid/settings.yml`), artifacts,
repository structure (from `docs/repository-structure.md`), and the glossary (from
`docs/glossary.md`). Concepts and Reference consume content produced by the migration feature and
add the net-new generated catalog pages. Per §10, Concepts and the core Reference pages are
Should; the generated Skills/Agents/KB reference is Could and may start as stubs and deepen later.

## User Stories

- As an evaluator, I want a full explanation of the methodology and philosophy so that I can
  understand how AID works and why before committing.
- As a returning user, I want a CLI & subcommand reference, settings keys, and artifacts so that
  I can look up exact facts quickly.
- As a returning user, I want a glossary and repository-structure reference so that I can decode
  AID's terms and layout.
- As a maintainer, I want a generated Skills / Agents / KB reference from `canonical/` so that the
  roster stays accurate to the source of truth (acceptable as stubs initially).
- As a returning user, I want an FAQ so that common questions are answered without searching the
  long methodology page.

## Priority

Should

## Acceptance Criteria

- [ ] Given the Concepts section, when navigated, then the full methodology (pipeline & phases,
  philosophy, KB, agent model, feedback loops, lite vs full, AID vs SDD) and the FAQ are present
  (FR8, AC3).
- [ ] Given the Reference section, when navigated, then CLI & subcommands, settings keys
  (generated from `.aid/settings.yml`), artifacts, repository structure, and glossary pages
  are present (FR9, AC3).
- [ ] Given `canonical/`, when the Reference is built, then a Skills / Agents / KB reference
  exists (may begin as stubs and deepen later) (FR9, AC6).
- [ ] Given the migrated methodology, FAQ, repo-structure, and glossary source, when published in
  these sections, then content appears with no loss and internal links resolve (AC5).

---

## Technical Specification

### Overview & Approach

This feature owns the **information architecture and net-new content** for the two
fact-and-explanation sections of the site: **Concepts** (FR8, Diátaxis *Explanation*) and
**Reference** (FR9, Diátaxis *Information*). It does **not** own the migration transform
(feature-005) nor the site shell/schema/sidebar plumbing (feature-001). It does three things:

1. **Arranges** the pages feature-005 already migrated (`concepts/methodology.md`,
   `concepts/faq.md`, `reference/repository-structure.md`, `reference/glossary.md`) into the
   Concepts and Reference sidebar groups, replacing feature-001's stub placeholders for those
   two groups.
2. **Hand-authors** the pages whose source is not a migrated `docs/*.md`: the two section
   overview pages, the CLI & subcommands reference (`reference/cli.mdx`, authored from
   `docs/install.md`), and an artifacts reference page.
3. **Generates** a roster reference for AID's Skills / Agents / KB-doc-types directly from
   `canonical/`, plus a settings-keys reference from `.aid/settings.yml` — committed and
   drift-checked, **reusing feature-005's exact `sync`+`git diff --exit-code` convention**
   (the same convention this repo already uses for canonical→profiles render-drift).

The boundary with feature-005 is sharp: feature-005 produces `docs/*.md`→content pages; this
feature produces a **second, parallel generator** (`site/scripts/gen-reference.mjs`) whose
sources are `canonical/` and `.aid/settings.yml` — content that has no `docs/*.md` analogue.
The two generators are independent, share no state, and write to disjoint paths.

### Architectural Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| **D1 — Two sidebar groups, explicit (hand-authored) item order** | Replace feature-001's stub Concepts and Reference sidebar entries with the full explicit item lists below. Keep `autogenerate` **off** (feature-001 D8) so group order/labels are deterministic. | Feature-001 stubbed one item per group (`concepts/methodology`, `reference/overview`); this feature owns the real IA. Explicit ordering lets us lead each group with an *overview* page (Diátaxis entry point) and sequence reference pages by lookup frequency, which `autogenerate` (alphabetical) cannot do. |
| **D2 — Each section opens with a thin hand-authored overview page** | Add `concepts/overview.md` and `reference/overview.md`. **Confirmed cross-feature decision:** feature-006 owns the Reference section, so `reference/overview` belongs here; feature-001's sidebar now uses `autogenerate: { directory: 'reference' }` and its ownership comment has been corrected from "feature-007" to feature-006 (the original "feature-007" attribution was a scaffold-era mislabel). feature-007 owns only the two Pipeline & Maintainer **Guides** pages (`guides/pipeline`, `guides/maintainer`) and no Reference page. Each overview is a short orientation page that frames the section and links to its children. | AC3 requires the sections be "navigable"; a bare list of leaf pages with no landing page reads as unfinished. The methodology page is long (1430 lines) — a Concepts overview gives evaluators a 30-second map before they commit to it. These are net-new, not migrated; they carry **no** `sourceDoc` frontmatter and are never touched by either generator. |
| **D3 — CLI reference is hand-authored `.mdx`, sourced from `docs/install.md` (not migrated)** | `reference/cli.mdx` is authored by hand from `docs/install.md`, **not** run through feature-005's sync. It is a *restructured* command reference (subcommand-by-subcommand: `aid` / `add` / `status` / `update` / `remove` / `version` / `self`, then flags, exit codes, env vars, tool ids), not a faithful copy of the install guide. | `docs/install.md` is already migrated **whole** by feature-005 to `guides/installation.md` (a how-to). FR9's Reference CLI page is a *different genre* — a lookup table of the command surface — so it must be a distinct, re-organized page, not a second copy of the same source (which would drift and duplicate). It is `.mdx` so it can use Starlight `<Tabs>` for the PowerShell/Bash flag-form split and Aside callouts. Because it is hand-derived (not generated), it carries no drift-check; it links into `guides/installation` anchors for the long-form prose to minimize duplication. |
| **D4 — Skills/Agents/KB roster is GENERATED from `canonical/`, committed + drift-checked** | A new generator `site/scripts/gen-reference.mjs` reads `canonical/skills/*/SKILL.md`, `canonical/agents/*/AGENT.md`, and `canonical/templates/knowledge-base/*.md` and emits `reference/skills.md`, `reference/agents.md`, `reference/kb.md`. Output is committed; CI runs the generator then `git diff --exit-code` over the generated paths. | FR9/AC6 + the maintainer user story require the roster stay accurate to the source of truth (`canonical/` is the source; `profiles/` are its render output per `docs/install.md`). Generating means the page can never list a removed skill or miss a new one. Mirroring feature-005's committed-derived + drift-check pattern (and the repo's render-drift convention from MEMORY) gives a clean-checkout build with no pre-step and a CI guard against drift, with **zero** new infrastructure concepts. |
| **D5 — Settings-keys reference is GENERATED from `.aid/settings.yml`** | The same `gen-reference.mjs` emits `reference/settings.md` from `.aid/settings.yml`, enumerating each key, its path (`review.minimum_grade`, `execution.max_parallel_tasks`, …), default/current value, and the inline `#` comment as the description. | FR9 + AC3 call settings keys "net-new, generated from `.aid/settings.yml`." The YAML's own comments are already authoritative human descriptions, so the generator harvests them rather than re-authoring — keeping the page correct as `/aid-config` evolves the file. |
| **D6 — Roster reference ships at FULL depth, not stubs (§10 Should-tier scope)** | The generated `skills.md`/`agents.md`/`kb.md` render a complete table (name + one-line description from frontmatter, count, and source path) on first delivery — not placeholder stubs. | §10 marks the generated roster *Could* ("may start as stubs and deepen later"), but the frontmatter already contains a clean `name` + `description` for all 11 skills and 9 agents, and the 14 KB doc-types each have a template README/intro — so a *full table* costs the same as a stub generator and removes a follow-up. Per-item deep pages (full SKILL.md body rendered) remain the explicit deepen-later step the §10 *Could* note reserves; the table is the floor we ship. (Assumption flagged below — if scope must be minimized, the generator can emit table rows only for the count and source path and defer descriptions; called out in Assumptions.) |
| **D7 — One generator, manifest-driven, deterministic** | `gen-reference.mjs` is a single Node-stdlib ESM script driven by an explicit source→output table (the *Generation Mapping* below) and emits a `site/scripts/.reference-manifest.json` (outside the collection root, like feature-005's `.synced-manifest.json`) listing the paths it owns. | Matches feature-005's mechanism exactly so the two generators are operationally identical (same wiring, same drift-check shape, same "manifest outside collection root so docsLoader's glob ignores it"). One script for all generated reference output keeps the build wiring to a single `gen:reference` prebuild step. |

### Page Inventory (Concepts FR8 + Reference FR9)

Provenance legend: **M** = migrated by feature-005 (this feature only arranges it);
**A** = hand-authored by this feature; **G** = generated by this feature's `gen-reference.mjs`.

| Page (`site/src/content/docs/`) | Prov. | Source | Notes |
|---|---|---|---|
| `concepts/overview.md` | A | — (net-new) | Thin Explanation entry point; frames the section, links to methodology + faq. |
| `concepts/methodology.md` | M | `docs/aid-methodology.md` (feature-005) | The full methodology: pipeline & phases, philosophy, KB, agent model, feedback loops, lite vs full, AID-vs-SDD, 7 Mermaid diagrams. Arranged as the Concepts centerpiece. |
| `concepts/faq.md` | M | `docs/faq.md` (feature-005) | FAQ. |
| `reference/overview.md` | A | — (net-new) | Thin Information entry point; orients the reference set. feature-006 owns `reference/overview` (confirmed; feature-001's comment corrected to feature-006). |
| `reference/cli.mdx` | A | `docs/install.md` | Hand-authored command reference (subcommands, flags, exit codes, env vars, tool ids, auto-detect); `<Tabs>` for flag forms; links to `guides/installation` for prose. |
| `reference/skills.md` | G | `canonical/skills/*/SKILL.md` | 11 skills; table of name + description (frontmatter) + source path. |
| `reference/agents.md` | G | `canonical/agents/*/AGENT.md` | 9 agents; table of name + description (frontmatter) + source path. |
| `reference/kb.md` | G | `canonical/templates/knowledge-base/*.md` | 14 KB doc-types; the Knowledge Base taxonomy (architecture, coding-standards, … test-landscape). |
| `reference/settings.md` | G | `.aid/settings.yml` | Settings keys: path, default/current value, description harvested from inline comments. |
| `reference/artifacts.md` | A | — (net-new) | The AID artifact set (REQUIREMENTS.md, SPEC.md, PLAN.md, task-NNN.md, STATE.md, the KB docs, manifest files) — what each is and where it lives; cross-links `reference/repository-structure`. |
| `reference/repository-structure.md` | M | `docs/repository-structure.md` (feature-005) | Repo layout. |
| `reference/glossary.md` | M | `docs/glossary.md` (feature-005) | Glossary. |

### Sidebar Configuration (replaces feature-001's Concepts + Reference stubs)

Edited in `site/astro.config.mjs` (feature-001 owns the file; this feature replaces only the
two affected group objects — the other three groups are untouched):

```js
{ label: 'Concepts', items: [
    { label: 'Overview',          slug: 'concepts/overview' },          // A
    { label: 'The methodology',   slug: 'concepts/methodology' },       // M (005)
    { label: 'FAQ',               slug: 'concepts/faq' } ] },           // M (005)
{ label: 'Reference', items: [
    { label: 'Overview',              slug: 'reference/overview' },              // A
    { label: 'CLI & subcommands',     slug: 'reference/cli' },                   // A
    { label: 'Skills',                slug: 'reference/skills' },                // G
    { label: 'Agents',                slug: 'reference/agents' },                // G
    { label: 'Knowledge Base',        slug: 'reference/kb' },                    // G
    { label: 'Settings keys',         slug: 'reference/settings' },             // G
    { label: 'Artifacts',             slug: 'reference/artifacts' },             // A
    { label: 'Repository structure',  slug: 'reference/repository-structure' }, // M (005)
    { label: 'Glossary',              slug: 'reference/glossary' } ] },          // M (005)
```

### Reference Generator (`site/scripts/gen-reference.mjs`) — D4, D5, D7

**Mechanism.** A Node-stdlib ESM script (no runtime deps; reads source files, transforms text,
writes content pages), driven by the explicit *Generation Mapping* below. For each generated
page it: (1) reads its source(s); (2) parses the needed fields (YAML frontmatter `name` +
`description` for skills/agents; the leading H1/intro for KB doc-types; key path + value +
inline `#` comment for settings); (3) prepends injected page frontmatter
(`title`, `description`, and a `generatedFrom` provenance marker analogous to feature-005's
`sourceDoc`); (4) renders a deterministic Markdown table; (5) writes the page under
`site/src/content/docs/reference/`. It emits `site/scripts/.reference-manifest.json` (outside
the collection root) listing the four paths it owns.

**Generation Mapping (source → output).**

| Output (`reference/`) | Source glob / file | Extracted per item | Row count today |
|---|---|---|---|
| `skills.md` | `canonical/skills/*/SKILL.md` | frontmatter `name`, `description`; dir name as source path | 11 |
| `agents.md` | `canonical/agents/*/AGENT.md` | frontmatter `name`, `description`, `tier`, `tools`; dir name as source path | 9 |
| `kb.md` | `canonical/templates/knowledge-base/*.md` (excl. `README.md`) | filename (doc-type), leading H1/first line as one-liner | 14 |
| `settings.md` | `.aid/settings.yml` | key path, value, inline `#`-comment description | (current keys: `project.*`, `tools.installed`, `review.minimum_grade`, `execution.max_parallel_tasks`, `traceability.heartbeat_interval`, per-skill overrides) |

**Wiring (package.json — added to feature-001's `package.json`, alongside feature-005's
`sync:docs`):**

```json
{
  "scripts": {
    "gen:reference": "node scripts/gen-reference.mjs",
    "predev":   "npm run sync:docs && npm run gen:reference",
    "prebuild": "npm run sync:docs && npm run gen:reference"
  }
}
```

(Feature-005 also defines `predev`/`prebuild` for `sync:docs`; the two are merged into a single
chained pre-step — coordination point noted in Feature Boundaries.) CI runs both generators
before `astro build`.

**Drift-check (CI — mirrors feature-005's D2).** After `npm run gen:reference`:

```sh
git diff --exit-code -- site/src/content/docs/reference/skills.md \
  site/src/content/docs/reference/agents.md \
  site/src/content/docs/reference/kb.md \
  site/src/content/docs/reference/settings.md \
  site/scripts/.reference-manifest.json
```

A non-empty diff means `canonical/` or `.aid/settings.yml` changed without re-running the
generator, or the script is non-deterministic — either fails the build. This is the AC6 guard
that keeps the roster accurate to the source of truth. The four generated pages carry
`generatedFrom` frontmatter as a secondary "derived — do not hand-edit" marker.

### File / Directory Tree (added/edited by this feature)

```
site/
├── astro.config.mjs                       # edit: replace Concepts + Reference sidebar groups (D1)
├── package.json                           # edit: + gen:reference; chain into predev/prebuild
├── scripts/
│   ├── gen-reference.mjs                  # NEW: the roster + settings generator (A)
│   └── .reference-manifest.json           # generated; committed; OUTSIDE the collection root
└── src/content/docs/
    ├── concepts/
    │   ├── overview.md                    # NEW hand-authored (A)
    │   ├── methodology.md                 # arranged (M, feature-005 owns content)
    │   └── faq.md                         # arranged (M, feature-005 owns content)
    └── reference/
        ├── overview.md                    # NEW hand-authored (A) — replaces 001 stub
        ├── cli.mdx                        # NEW hand-authored (A) from docs/install.md
        ├── skills.md                      # generated (G)
        ├── agents.md                      # generated (G)
        ├── kb.md                          # generated (G)
        ├── settings.md                    # generated (G)
        ├── artifacts.md                   # NEW hand-authored (A)
        ├── repository-structure.md        # arranged (M, feature-005 owns content)
        └── glossary.md                    # arranged (M, feature-005 owns content)
```

### Feature Boundaries

| Concern | Owner | This feature does |
|---|---|---|
| Content collection, `docsSchema()` (`sourceDoc`, `reportIssue`), the five sections, `astro-mermaid`, sidebar config file | feature-001 | Inherits; edits only the Concepts + Reference sidebar groups |
| Migration of `docs/*.md` (methodology, faq, repo-structure, glossary) | feature-005 | Arranges those four pages; never re-migrates them |
| `guides/installation.md` (full install how-to from `docs/install.md`) | feature-005/004 | Links to its anchors from `reference/cli.mdx`; does not duplicate it |
| `predev`/`prebuild` script keys in `package.json` | feature-001 base, feature-005 adds `sync:docs` | Adds `gen:reference` and chains both pre-steps — coordinate the merged script line |
| CI workflow (runs generators + link check before build) | feature-002 | Specifies the `gen:reference` step + the drift-check rule the CI must enforce |
| Per-page "Report an issue" (`reportIssue` schema field) | feature-010/006 | Reference pages keep the schema default; no extra work here |
| FR15 version injection | feature-008 | Out of scope |

### AC Coverage

| AC | Satisfied by |
|---|---|
| AC3 (Concepts: full methodology + FAQ present) | `concepts/overview` + arranged `methodology` (all 8 themes) + `faq` in the sidebar group (D1, D2). |
| AC3 (Reference: CLI, settings keys, artifacts, repo structure, glossary present) | `reference/cli` (A), `reference/settings` (G), `reference/artifacts` (A), arranged `repository-structure` + `glossary` (M). |
| AC6 (Skills/Agents/KB reference exists, may deepen later) | Generated `skills.md`/`agents.md`/`kb.md` shipped at full-table depth (D4, D6); deep per-item pages reserved as the §10 deepen-later step. |
| AC5 (migrated content faithful, links resolve) | Owned by feature-005; this feature only arranges, adding no transform; feature-002's internal-link check validates the new authored/generated pages' links resolve. |

### Assumptions to Spot-Check

- **A2 (KB-reference semantics).** "KB" in FR9 is read as the AID **Knowledge Base doc-type
  taxonomy** (the 14 templates in `canonical/templates/knowledge-base/`), not a specific
  project's populated `.aid/knowledge/`. Confirm this is the intended roster.
- **A3 (roster depth).** D6 ships full tables now (not stubs) since frontmatter makes it free;
  confirm this is acceptable scope vs. the §10 *Could* "start as stubs" note (the only deepen-later
  item left is per-item full-body pages).
- **A4 (single `predev`/`prebuild` line).** feature-005 and this feature both define the
  pre-steps; confirm they are merged into one chained script (`sync:docs && gen:reference`) rather
  than two conflicting definitions of the same key.
