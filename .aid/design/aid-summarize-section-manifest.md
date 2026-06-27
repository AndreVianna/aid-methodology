# Section / IA manifest contract — `/aid-summarize` domain-driven redesign

> **Task:** task-064 (DESIGN, work-001 / delivery-011). **Type:** DESIGN — DESIGN ONLY; no
> canonical skill file is edited here. This document is the **contract** tasks 065/066/067 consume.
> **Status:** design of record for the input/IA layer of feature-015.
> **Audience reframing (§0 of feature-015 SPEC):** `kb.html` is a **different product** from the KB
> — its reader is a **non-technical newcomer with little/no prior project knowledge**; it is
> **visually rich**; the KB's no-diagrams / dual-audience / agent-frontmatter authoring rules do
> **NOT** apply to the summary. This manifest defines *what sections exist and how each is derived
> from real KB data*; tone/visual freedom is exercised within it.

This contract answers exactly one question: **given a KB produced by feature-014, what is the
summary's section set, in what order, rendered with which component, and which doc list backs the
`noscript` fallback — derived deterministically from real source fields, never from a hardcoded
software gallery.**

Every mapping below names the **real source field / file** it reads. Nothing is invented.

---

## 1. The two distinct input sources (do NOT conflate — different files)

The redesign retires profile-as-project-type. The section set is now **data-driven** from two
feature-014 outputs that live in **two different files**:

| # | Derived attribute | Source field (exact) | Source file (exact) | Shape observed today |
|---|-------------------|----------------------|---------------------|----------------------|
| I1 | **Resolved doc-set** (which docs exist → which sections exist) | `discovery.doc_set` (YAML list of `filename\|owner\|presence` entries) | `.aid/settings.yml` | 22 entries (`project-structure.md\|aid-researcher-scout\|required`, … `README.md\|skill-self\|required`) |
| I2 | **Domain** (frames labels/voice, NOT a fixed gallery) | `## Discovery Domain` → `- **Domain:**` line | `.aid/knowledge/STATE.md` | `hybrid:methodology-tooling+software-cli` |

**Critical:** the **doc-set is in `settings.yml`** and the **domain is in `knowledge/STATE.md`**.
A reader that looks for the doc-set in STATE.md (or the domain in settings.yml) is wrong. This is
the single most common conflation the old skill's PROFILE state invites and the redesign must avoid.

**Parse rules (for task-065):**
- **Doc-set entry → filename:** split each `discovery.doc_set` list item on `|`, take field 1
  (`project-structure.md`). Fields 2 (`owner`) and 3 (`presence`) are NOT used for section
  derivation in D-011 (owner is a research-provenance field; presence is `required` for all current
  entries). They are carried through only if a later delivery needs provenance badges.
- **Resolved doc-set = the doc-set filenames that actually exist on disk in `.aid/knowledge/`.**
  A doc-set entry whose file is absent produces **no section** (no phantom section, no placeholder
  for a non-existent doc). Conversely a `.aid/knowledge/*.md` doc **not** in `discovery.doc_set` is
  out of scope (the doc-set is authoritative for membership). The intersection is the **resolved
  doc-set** that drives everything below.
- **Domain string → framing:** the `Domain:` value (e.g. `hybrid:methodology-tooling+software-cli`)
  is split on `:`/`+` into facet tokens. It is used ONLY to choose newcomer-friendly **labels and
  the "what is this" framing** (a methodology+software-CLI hybrid reads differently from a pure
  data-pipeline). It does **NOT** select a section template, gate any section, or require any
  diagram. Domain is *advisory framing*, never *structural selection*.

---

## 2. One section per resolved doc / `kb-category` — the section manifest

The summary renders **exactly one section per resolved doc**. There is **no fixed section list**;
the section list IS the resolved doc-set. Each section's attributes are derived from **that doc's
own frontmatter**, read with the existing `state-generate.md` priority fallback
(`objective`+`summary` → `objective` → `intent` → first-paragraph-after-H1). Source fields:

| Section attribute | Source frontmatter field (exact) | Fallback if absent | Notes |
|-------------------|----------------------------------|--------------------|-------|
| Section **heading / title** | derived from `objective:` (noun-phrase) + the doc's human name | doc filename de-slugified | newcomer-phrased; not the raw filename |
| Section **one-line description** | `summary:` (one-sentence scope) | `objective:` → `intent:` → first paragraph | the "what you'll learn here" line |
| Section **purpose blurb** | `objective:` (purpose noun-phrase) | `intent:` → first paragraph | feeds the newcomer "why this matters" framing |
| Section **tier / prominence** | `kb-category:` (`primary` \| `extension` \| `meta`) | absent ⇒ treat as `primary` (schema default, line 409 of frontmatter-schema.md) | drives ordering + featured-ness (§4) |
| Section **content component** | `kb-category:` (tier) **+ well-known-doc identity** | generic fallback (§3) | the category→component map (§3) |
| Section **keyword pills** | `tags:` (list) | omit (no placeholder) | rendered as friendly topic pills, not raw tag syntax |
| Section **`see_also` cross-links** | `see_also:` (list) | omit | "related" chips between sections |
| **Source citation** | the resolved doc filename | n/a (always present) | `Source: <doc>.md` link, per existing authoring rule |

**Retired:** `audience:` is **NOT** surfaced as a role-badge in the summary. The old
`state-generate.md` rendered an `[architect, developer]` badge per section; that is the KB's
**dual-audience / agent-frontmatter framing**, which feature-015 §4 (Change 4) explicitly drops
from the summary (the newcomer does not care which agent-role a doc targets). `audience:` is still
read (it is real frontmatter) but it is **not rendered** in the summary IA.

### 2a. `kb-category` is a TIER, not a content-type — read this before §3

`kb-category` ∈ `{primary, extension, meta}` is a **prominence/tier** classifier
(frontmatter-schema.md line 43; values confirmed across the live doc-set in §6). It is **not** a
content-shape ("glossary" vs "ADR" vs "table"). Therefore the content-component decision (§3) keys
on **two** signals:

1. **Tier (`kb-category`)** → ordering, featured-ness, and the **generic fallback shape**.
2. **Well-known doc identity (filename)** → the three **bespoke** components (glossary, ADR card,
   capability entry) attach to the three specific spine/decision/capability docs by name.

This two-layer keying is what lets "one section per `kb-category`" coexist with "render the glossary
as definitions and `decisions.md` as ADR cards" — the tier orders/prominences the section; the doc
identity (for the three special docs) picks the rich component; everything else falls through to the
generic fallback so **no resolved doc is ever dropped** (completeness = coverage, §0).

---

## 3. The `kb-category` → content-component map (handed to task-066)

task-066 builds the component library against this table. The rule is:
**bespoke component for the three well-known spine/decision/capability docs; generic fallback for
everything else; nothing is ever dropped.**

| Match key | Matches (real doc / field) | Content component task-066 renders | Source data the component reads |
|-----------|----------------------------|------------------------------------|----------------------------------|
| **Well-known doc:** `domain-glossary.md` | `domain-glossary.md` (`kb-category: primary`, `tags:` include `glossary`/`concept-spine`) | **Glossary / definition component** — friendly definition list / pill-cards, one per term | the term/definition rows in `domain-glossary.md` body (the Concept Spine) — **rendered as content, not linked** |
| **Well-known doc:** `decisions.md` | `decisions.md` (`kb-category: extension`, `tags:` include `adr`/`decisions`/`rationale`) | **Decision / ADR card** — one card per ADR: context → decision → rationale → consequence | each ADR entry in `decisions.md` body — **rendered as content, not linked** (the *why* behind the project) |
| **Well-known doc:** `capability-inventory.md` | `capability-inventory.md` (`kb-category: primary`, `tags:` include `capabilities`/`skills`/`workflows`) | **Capability entry** — one entry per capability (what it does · when to use it · how to invoke) | the capability rows in `capability-inventory.md` body |
| **Generic fallback — tier `primary`** | any other resolved doc with `kb-category: primary` (e.g. `architecture.md`, `module-map.md`, `process-architecture.md`, `workflow-map.md`, `technology-stack.md`, `feature-inventory.md`, `test-landscape.md`, …) | **Generic table / card / prose** — the renderer picks per-fact (table for catalogs, cards for grids, prose for narrative); a featured tier-`primary` doc may carry an infographic | the doc body: tables → tables, lists → cards/pills, narrative → newcomer prose |
| **Generic fallback — tier `extension`** | any other resolved doc with `kb-category: extension` (e.g. `quality-gates.md`) | **Generic table / card / prose**, rendered as a **secondary / lower-prominence** section (extensions are supporting, not core) | same per-fact selection as above |
| **Generic fallback — tier `meta`** | resolved docs with `kb-category: meta` (`external-sources.md`, `README.md`) | **Compact prose / reference list** (orientation, not a newcomer-concern section) — or folded into the KB Index where it is pure orientation | the doc body, summarized briefly |

**Component-selection algorithm (deterministic, for task-066):**
1. If the doc filename is one of the three **well-known docs** → use its bespoke component.
2. Else → **generic fallback**, with the **shape chosen per fact** (table / card / pill / prose /
   infographic — best-format-per-fact, §0) and **prominence keyed by `kb-category`**
   (`primary` = full section; `extension` = supporting section; `meta` = compact/reference).
3. **No resolved doc is ever skipped.** "No bespoke component" is never "no section" — the generic
   fallback guarantees coverage. **Completeness = coverage of the resolved doc-set**, never a fixed
   section count or diagram count.

**Why filename-keyed and not a new frontmatter enum:** the three bespoke components map to the three
specific docs feature-014 introduced for exactly this content (the Concept Spine, the ADR log, the
capability catalogue). `kb-category` does not encode "this is a glossary"; introducing a new
content-type frontmatter field would change feature-014's schema — **out of scope** (the summary is
a *reader*, it does not re-spec discovery; §11 of feature-015 SPEC). Filename + tier is sufficient
and grounded in fields that exist today.

---

## 4. Section ordering rule (deterministic)

Ordering is mechanical and reproducible (no LLM judgment on order). The rule, in precedence:

1. **"At a Glance" is always first** (§5) — synthesized, not a doc section.
2. **Concept-first ordering for the three well-known docs** (Change 2 intent — concepts/decisions
   are what a newcomer needs first): `domain-glossary.md` (glossary) → `decisions.md` (ADR cards)
   → `capability-inventory.md` (capability entries) appear **early**, immediately after "At a
   Glance", regardless of doc-set list position. A newcomer learns *the vocabulary, the why, and
   what it can do* before structural detail.
3. **Then tier order:** remaining `kb-category: primary` docs, then `kb-category: extension` docs.
4. **Within a tier:** preserve the **`discovery.doc_set` list order** (the order feature-014 curated
   it — itself a sensible concern grouping). This makes ordering a pure function of the resolved
   doc-set + frontmatter → **same input, same order** (auditable, FR-50-ready).
5. **`kb-category: meta` docs** (`external-sources.md`, `README.md`) sort last / fold into the KB
   Index (orientation, not a newcomer concern — concern-model.md classes `meta` as cross-cutting,
   not a newcomer concern).
6. **Knowledge Base Index is always last** — the full table of resolved docs with one-line
   descriptions (from each doc's `summary:`) — the only "links to the .md" affordance retained.

**Featured-ness:** a section is "featured" (`★`, accent treatment) if its `kb-category` is `primary`
AND it is one of the concept-first trio or a domain-salient core doc — featured-ness is a
presentation accent, **not** a structural gate; it never drops or adds a section.

**Domain's role in ordering/labels:** the `Domain:` facets (I2) only adjust **labels and framing**
(e.g. for `hybrid:methodology-tooling+software-cli`, the "what is this" framing names both the
methodology and the shipped CLI/tool). Domain **never reorders, adds, or removes** a section — the
section set is the resolved doc-set, full stop.

---

## 5. "At a Glance" — newcomer-framed inputs (retires the software-metric lead)

"At a Glance" is the **first** section and is **synthesized** (not a doc section). It is rebuilt to
lead with **what the project is / what it does**, in plain language — NOT a software-metric card grid.

| "At a Glance" input | Source (exact) | Newcomer framing |
|---------------------|----------------|------------------|
| **What this is** (lead) | project name (`.aid/knowledge/STATE.md` / build file) + the `Domain:` framing (I2) + `domain-glossary.md` / `capability-inventory.md` `objective:` | one plain-language paragraph: "This is a {methodology + CLI tool} that …" |
| **What it does** | `capability-inventory.md` `objective:`/`summary:` + top capability rows | a short friendly list of what the project lets you do |
| **Key vocabulary teaser** | first few `domain-glossary.md` terms | a taste of the project's language, linking down to the glossary section |
| **Key decisions teaser** | first `decisions.md` ADR title(s) | "the big calls", linking down to the ADR cards |

**Retired:** the old "At a Glance" 4×2 **software-metric** card grid (module count / entity count /
endpoint count / test count). Counts MAY appear as a small secondary detail, but they **do not
lead** and are not the section's purpose (Change 4 / FR-48). A newcomer needs *what & why*, not LOC.

---

## 6. Derived `noscript` doc list (retires the hardcoded list)

The `noscript` fallback links a newcomer to the source `.md` files when JS is off. Today this list
is **hardcoded** in `html-skeleton.html` (lines 76–93): a stale fixed set of `INDEX.md`,
`architecture.md`, `module-map.md`, `schemas.md`, `pipeline-contracts.md`, `integration-map.md` —
a software-seed list that does **not** reflect the resolved doc-set (it omits all 7 custom docs,
the glossary, decisions, capabilities, etc.).

**Redesign rule (for task-065):** the `noscript` list is **derived from the resolved doc-set at
generation time**:
- One `<li><a href="./{doc}.md">{doc}.md</a> — {one-line}</li>` per **resolved doc-set** entry
  (the same I1 set that drove the sections), with the one-line text taken from each doc's
  `summary:` frontmatter.
- Always lead with `INDEX.md` (the generated KB map) for orientation.
- **No hardcoded doc list survives** in `html-skeleton.html` or any section template — the list is
  a function of `discovery.doc_set` ∩ disk, identical to the section manifest membership.
- The `noscript` copy drops the **"uses Mermaid to render diagrams"** sentence's dependence on
  Mermaid being present (D-012 removes the engine; D-011 may keep the wording until then) — the
  *doc-list derivation* itself is a D-011 / FR-45 change and does not wait on D-012.

The live resolved doc-set this rule produces today (22 entries, from §1 I1, all `required` and
present): `project-structure.md, external-sources.md, architecture.md, process-architecture.md,
technology-stack.md, module-map.md, pipeline-contracts.md, integration-map.md, workflow-map.md,
coding-standards.md, authoring-conventions.md, domain-glossary.md, schemas.md, artifact-schemas.md,
test-landscape.md, quality-gates.md, tech-debt.md, infrastructure.md, feature-inventory.md,
capability-inventory.md, decisions.md, README.md` — none of which the hardcoded list covers.

---

## 7. Live doc-set → section/component resolution (worked example, this repo)

Applying §§2–6 to the **real** `discovery.doc_set` + frontmatter read for this manifest. This is the
auditable output the contract produces for AID's own KB (proves grounding; task-065/066 reproduce it
deterministically):

| Order | Resolved doc | `kb-category` (source field) | Component (§3) | Why |
|-------|--------------|------------------------------|----------------|-----|
| 1 | *(At a Glance — synthesized)* | n/a | newcomer "what is / does" (§5) | always first |
| 2 | `domain-glossary.md` | primary | **Glossary / definition** | well-known doc (concept spine) |
| 3 | `decisions.md` | extension | **Decision / ADR card** | well-known doc (the *why*) |
| 4 | `capability-inventory.md` | primary | **Capability entry** | well-known doc |
| 5 | `architecture.md` | primary | generic (infographic + cards) | featured core, tier primary |
| 6 | `process-architecture.md` | primary | generic (prose + table) | tier primary |
| 7 | `module-map.md` | primary | generic (cards/table) | tier primary |
| 8 | `pipeline-contracts.md` | primary | generic (table) | tier primary |
| 9 | `integration-map.md` | primary | generic (table/infographic) | tier primary |
| 10 | `workflow-map.md` | primary | generic (prose/table) | tier primary |
| 11 | `technology-stack.md` | primary | generic (table/pills) | tier primary |
| 12 | `coding-standards.md` | primary | generic (prose) | tier primary |
| 13 | `authoring-conventions.md` | primary | generic (prose) | tier primary |
| 14 | `schemas.md` | primary | generic (table) | tier primary |
| 15 | `artifact-schemas.md` | primary | generic (table) | tier primary |
| 16 | `test-landscape.md` | primary | generic (table/cards) | tier primary |
| 17 | `tech-debt.md` | primary | generic (severity cards) | tier primary |
| 18 | `infrastructure.md` | primary | generic (table/cards) | tier primary |
| 19 | `feature-inventory.md` | primary | generic (cards/table) | tier primary |
| 20 | `project-structure.md` | primary | generic (tree/prose) | tier primary |
| 21 | `quality-gates.md` | extension | generic (table), supporting | tier extension |
| 22 | `external-sources.md` | meta | compact reference / fold to Index | tier meta |
| 23 | `README.md` | meta | compact reference / fold to Index | tier meta |
| last | *(Knowledge Base Index)* | n/a | full resolved-doc table (§4.6) | always last |

(Within-tier order in rows 5–20 follows the `discovery.doc_set` list order per §4.4; the trio
2–4 is promoted per §4.2. Featured `★` on `domain-glossary`, `decisions`, `architecture`.)
**Coverage = 22/22 resolved docs represented. Zero dropped. Zero phantom.**

---

## 8. Enumerated retirements (exhaustive change list for task-065)

task-065 deletes/replaces each of the following. The file + anchor each lives in **today** is named
so the change list is exhaustive (DBI safety: edit the **`canonical/`** source, not the rendered
`.claude/` copy — resolve each shorthand to its `canonical/` anchor per feature-015 SPEC's path
anchor note; the `.claude/` paths below are where each artifact is *observed*).

| # | Retired thing | What it is today | File + anchor (observed in `.claude/`; edit the `canonical/` twin) |
|---|---------------|------------------|--------------------------------------------------------------------|
| R1 | **Profile-as-project-type selection** | PROFILE state auto-detects web-app/cli/library/microservices/data-pipeline/agentic-pipeline from KB greps and stores a `**Profile:**` | `references/state-profile.md` (whole-file; the `architecture.md`/`pipeline-contracts.md`/`module-map.md`/`infrastructure.md`/`integration-map.md` grep block, lines ~10–17, and the `**Profile:**` persistence, lines ~29–35) → replaced by the I1/I2 doc-set+domain read |
| R2 | **Project-type scoring rules** | the `web-app … agentic-pipeline` scoring tables (max 15 pts, confidence levels) | `templates/knowledge-summary/section-templates/auto-detect.md` (whole file) → retired as a selector; the "Concept Spine applies to all profiles" note (lines 130–141) is **superseded** by §3's glossary component |
| R3 | **The 6 project-type section templates** | fixed software section lists keyed by project-TYPE | `templates/knowledge-summary/section-templates/{web-app,cli,library,microservices,data-pipeline,agentic-pipeline}.md` → retired as project-type profiles; any kept content recast as **`kb-category`-keyed rendering hints** (§3), never as type selectors |
| R4 | **Phantom `repo-presentation.md` reference** | a doc that does not exist, cited as a KB source | `templates/knowledge-summary/section-templates/agentic-pipeline.md` lines **18, 24, 27** (the §2 "The Pipeline", §8 "Distribution / Install", §11 "Documentation Surface" rows) → removed wherever it appears (these template rows + any prose) |
| R5 | **Hardcoded `noscript` doc list** | a fixed `INDEX.md / architecture.md / module-map.md / schemas.md / pipeline-contracts.md / integration-map.md` list | `templates/knowledge-summary/html-skeleton.html` lines **76–93** (the `<noscript><ul>…</ul></noscript>` block) → replaced by the §6 derived list |
| R6 | **Hardcoded seed-doc grep / fixed 15-doc software seed** | the section manifest assumed a fixed software doc set | `references/state-profile.md` (the doc-name greps) + `references/state-generate.md` step 3's reliance on a profile template's fixed `{profile-section}` list (lines ~64–93) → both replaced by "one section per resolved doc-set entry" (§2) |
| R7 | **`audience:` role-badge in the summary** | per-section `[architect, developer]` badge (KB agent-framing leaking into the summary) | `references/state-generate.md` lines ~46–49 (the `audience:` → role-badge rule) → dropped per Change 4 / FR-48 (§2's "Retired" note) |
| R8 | **Software-metric "At a Glance" lead** | the 4×2 numeric card grid (modules/entities/endpoints/tests) as the lead | `templates/knowledge-summary/section-templates/web-app.md §1` (lines 46–50) + `prompt.md` "§1 — At a Glance" (lines 116–137) → replaced by the §5 newcomer-framed inputs |

**Not retired (kept, per §5b + keep-list):** the outer page shell in `html-skeleton.html` (top bar,
side panel, search, nav chrome — kept consistent with `home.html`/`index.html`), the design-token
system, light/dark theming (shared `aid-dashboard-theme`), the focus-trapped lightbox, the a11y
baseline (skip-link, landmarks, `:focus-visible`, `prefers-reduced-motion`, `forced-colors`, and the
`noscript` *element itself* — only its hardcoded *list* is derived now), responsive layout,
single-file self-containment. This manifest touches **only the inner content model** (which sections,
in what order, with which component, from which field).

---

## 9. Guardrail conformance (§5 / §5b of the design seed — C1/C2/C3/C5/C6 + §5b)

This contract requires **no** new output path, split asset, CDN, framework fetch, or shell change.
It is purely a re-derivation of *which sections exist and how each is rendered* from existing fields:

| Guardrail | How this contract honours it |
|-----------|------------------------------|
| **C1** output path `<repo>/.aid/dashboard/kb.html` | unchanged — this manifest never touches the output path; sections are assembled into the same single file |
| **C2/C3** single self-contained file, no CDN / split assets / framework fetch | unchanged — the derived `noscript` list (§6) and the bespoke/generic components (§3) are inlined HTML/CSS, no sub-resource; the server's `home.html`/`kb.html` allowlist is unaffected |
| **C5** approval signal `## Knowledge Summary Status` → `**User Approved:** yes (YYYY-MM-DD)` in `.aid/knowledge/STATE.md` | unchanged — this manifest reads `## Discovery Domain` from STATE.md but writes nothing to the approval block; the approval contract is untouched |
| **C6** `README.md ## Completeness` rows + `.aid/settings.yml kb_baseline:` shape | unchanged — this manifest reads `discovery.doc_set` from settings.yml; it does not alter `kb_baseline:` or the completeness rows the reader derives `doc_count`/outdated from |
| **§5b** outer shell consistent with `home.html` + CLI `index.html` | the shell is on the **keep-list** (§8 "Not retired"); only the **inner content area** is re-derived. No chrome is reinvented |

Consistent with the **§0 two-audience reframing**: this manifest drops `audience:` badges (R7) and
the software-metric lead (R8), promotes concepts/decisions/capabilities to first-class rendered
content (§3) ahead of structure (§4), and frames "At a Glance" for a non-technical newcomer (§5) —
without importing the KB's no-diagrams / agent-frontmatter rules into the summary.

---

## 10. What tasks 065/066/067 consume from this contract

| Downstream task | Consumes |
|-----------------|----------|
| **task-065** (input rewire) | §1 (the two-source read), §2 (one-section-per-resolved-doc + frontmatter field mapping), §4 (ordering rule), §6 (derived `noscript`), §5 ("At a Glance" inputs), **§8 (the exhaustive retirement change list)** |
| **task-066** (content components) | §3 (the `kb-category`→component map + the 3 bespoke components + generic fallback + the deterministic selection algorithm) |
| **task-067** (whatever consumes the assembled manifest, e.g. prompt/grading wording) | §2a (tier≠content-type), §3 (completeness = coverage), §4 (concept-first ordering), §5 (newcomer framing) |
