# Agent Prompt — `/aid-summarize` GENERATE state

This is the long-form prompt the agent follows when in GENERATE state. The
SKILL.md state machine wraps this with the bookkeeping (state file updates,
preflight, etc.); this file describes the actual content generation work.

---

## Inputs

- **`.aid/knowledge/`** — the populated, approved KB.
- **`.aid/settings.yml`** — `discovery.doc_set` (the resolved doc-set: which
  docs exist, in the order feature-014 curated them).
- **`.aid/knowledge/STATE.md`** — two things:
  - `## Discovery Domain` → the domain string that frames labels and voice
    (e.g. `hybrid:methodology-tooling+software-cli`). Advisory framing only —
    it does NOT select a section template or gate any section.
  - `## Knowledge Summary Status` → chosen theme, minimum grade, and the
    approval signal (`**User Approved:** yes (YYYY-MM-DD)`).
- **Section ordering and component selection** — derived from the PROFILE
  manifest (`state-profile.md`) and documented in `state-generate.md`.
- **`references/component-css.css`** — the styles to inline (includes all
  design tokens, theme, a11y baseline, bespoke component styles).
- **`references/lightbox.js`** — the script to inline.
- **`references/html-skeleton.html`** — the page shell with placeholders.
- **`references/design-tokens.md`** — palette / typography reference.
- **`references/authored-visual-catalog.md`** — inline SVG / HTML+CSS pattern templates
  for each visual type (flow, hierarchy, relationship, timeline, stats).

## Output

`.aid/dashboard/kb.html` — single self-contained file. All CSS and JS inlined;
no CDN, no split assets, no external framework fetch.

---

## Authoring rules

1. **The KB is authoritative.** Never invent facts. Every numeric or named fact
   in the HTML must trace back to a populated KB document.
2. **Cite sources.** Every section has a footer "Source:" reference link to the
   KB document(s) that fed it (e.g., `<a href="./architecture.md">architecture.md</a>`).
3. **Code-first if KB and design docs disagree.** Same rule discovery uses.
4. **No emojis** in titles or section bodies. Status icons (✓ ✗ ⚠) are OK as
   meaningful markers; emojis as decoration are not.
5. **Newcomer tone throughout.** Write for a non-technical reader with no prior
   project knowledge. Plain language, short sentences, "what & why" before "how".
   Drop the KB's agent-framing vocabulary (frontmatter, kb-category, dual-audience,
   audience badge) from the summary prose — those are KB-internal terms, not
   newcomer vocabulary. The reader does not need to know how the KB was built;
   they need to understand the project.
6. **Concept-first rendering — no bare links to source `.md` files as primary content.**
   The three well-known docs (`domain-glossary.md`, `decisions.md`,
   `capability-inventory.md`) are rendered as first-class content components — the
   reader sees the content in the page without having to open a `.md`. Specifically:
   - `domain-glossary.md` → render each term as a `.gloss-card` in a `.gloss-grid`.
     A newcomer reads the vocabulary definitions on the page. Do NOT replace the
     glossary section with a link to `domain-glossary.md`.
   - `decisions.md` → render each ADR (D1, D2, …) as an `.adr-card` in an `.adr-list`
     showing: decision statement, alternatives rejected, and the constraint that drove it.
     A newcomer reads the "why" in the page. Do NOT replace the decisions section with a
     link to `decisions.md`.
   - `capability-inventory.md` → render each capability as a `.cap-card` in a `.cap-grid`
     showing: name, slash command, what it does, when to use it.
     A newcomer reads what the project can do in the page. Do NOT replace the capabilities
     section with a link to `capability-inventory.md`.
   The ONLY link to each source `.md` is a footer "Source:" citation line at the bottom
   of the section. All other resolved docs that lack a bespoke component still get a
   "Source:" link, but that link is supplementary — the section body renders the actual
   content from the doc.
7. **Self-contained single file.** All CSS and JS inlined; no CDN, no split assets,
   no external framework fetch.
8. **Diagram captions:** every inline SVG visual or HTML+CSS infographic has a
   `.caption` block with format `Figure N. <one-sentence summary>. Source: <link>`.
   Wrap each visual in a `<div class="diagram-box">` (see `authored-visual-catalog.md`).
9. **Best format per fact.** Choose the format that best communicates each fact to a
   newcomer: table for catalogs, cards for grids, prose for narrative, diagram for
   structure. There is no minimum or maximum diagram count; the newcomer's understanding
   is the measure, not the number of visuals.

---

## Step-by-step

### Step 1 — Read the section manifest from PROFILE

The PROFILE state (`references/state-profile.md`) has already produced an ordered
section manifest: one entry per resolved doc, in concept-first ordering (domain-glossary
→ decisions → capability-inventory → then primary docs in doc-set order → extension
docs → meta docs). "At a Glance" is always first; Knowledge Base Index is always last.

Read each manifest entry:
- **doc filename** (the resolved KB doc)
- **section heading** (derived from `objective:` frontmatter or doc filename de-slugified)
- **one-line description** (from `summary:` → `objective:` → `intent:` → first paragraph)
- **purpose blurb** (from `objective:` → `intent:` → first paragraph)
- **tier** (`kb-category:` — `primary` | `extension` | `meta`)
- **keyword pills** (from `tags:`)
- **see-also links** (from `see_also:`)
- **component type** (bespoke for the three well-known docs; generic fallback otherwise)

Do NOT use project-TYPE profiles (web-app/cli/library/microservices/data-pipeline/
agentic-pipeline). The section set is the resolved doc-set, not a fixed template.

### Step 2 — Read all resolved KB documents

For each doc in the manifest, read `.aid/knowledge/{doc}.md` and extract:
- **Key facts** — numbers, names, version pins from the doc body. Extract the most
  summary-worthy content: for tables, pick informative rows; for prose, pick the
  lede paragraph + any callout-style bullets; for lists, pick the top 5–7 entries.
- **Concept Spine content** — for `domain-glossary.md`: extract each term's
  Definition-as-used-here, Relates-to, and Aliases fields.
- **ADR content** — for `decisions.md`: extract each D{N} entry's Decision,
  Alternatives rejected, and Constraint-that-drove-it.
- **Capability content** — for `capability-inventory.md`: extract each capability's
  name, invoke command, What-it-accomplishes, When-to-use.
- **Generated-doc flag** — if frontmatter has `source: generated`, render with a small
  "(auto-generated by `{generator}`)" attribution line.

**Do NOT render `audience:` as a role-badge.** The KB's dual-audience / agent-frontmatter
framing does not apply to the summary. The newcomer does not care which agent-role a doc
targets; audience leaks the KB's machine-oriented framing into a newcomer-facing product.

The KB is **authoritative**. Do not re-grade it, re-validate it, or contradict it.
If the KB says X, the HTML says X.

### Step 3 — Read the project's identity

Open `.aid/knowledge/STATE.md` `## Discovery Domain` for the domain string.
If the project root has a `pom.xml`, `package.json`, `Cargo.toml`, or other build
file, read the version + name from there. Cross-check against KB.

Read `## Discovery Domain` → `- **Domain:**` for the domain framing
(e.g. `hybrid:methodology-tooling+software-cli`).

### Step 4 — Build the "At a Glance" section (always first)

"At a Glance" is synthesized — not a doc section. Write it as a
**newcomer-friendly plain-language section** that answers: "What IS this project?
What does it DO for me?"

**Structure:**

```html
<section id="at-a-glance" class="sec featured" aria-labelledby="aag-heading">
  <header>
    <span class="eyebrow">{Domain framing, e.g. "Methodology + CLI tool"}</span>
    <h2 id="aag-heading">{{PROJECT_NAME}}</h2>
    <p class="lede">{One plain-language paragraph: "This is a {domain framing}
      that {what it does for users}." Friendly, no jargon.}</p>
  </header>

  <!-- What it does — friendly list from capability-inventory.md (if present) -->
  <div class="callout ok" style="margin-bottom:1.5rem">
    <h4>What it does for you</h4>
    <ul style="margin:0; padding-left:1.4em">
      <li>{Key capability 1 — one line, newcomer-friendly}</li>
      <li>{Key capability 2}</li>
      <!-- 3–5 top capabilities; no more -->
    </ul>
  </div>

  <!-- Key vocabulary teaser (if domain-glossary.md is in resolved doc-set) -->
  <p style="font-size:0.92rem; color:var(--text-muted);">
    <strong>Key vocabulary:</strong>
    <a href="#gloss-{slug}">{Term 1}</a>,
    <a href="#gloss-{slug}">{Term 2}</a>,
    <a href="#gloss-{slug}">{Term 3}</a>
    — <a href="#glossary">see all terms &rarr;</a>
  </p>

  <!-- Key decisions teaser (if decisions.md is in resolved doc-set) -->
  <p style="font-size:0.92rem; color:var(--text-muted);">
    <strong>Big decisions:</strong>
    <a href="#adr-d1">{ADR 1 short title}</a>,
    <a href="#adr-d2">{ADR 2 short title}</a>
    — <a href="#decisions">see all &rarr;</a>
  </p>
</section>
```

**Rules for "At a Glance":**
- **Lead with what & why, not metrics.** Module count, test count, and lines of code
  do NOT lead this section. A newcomer needs the mission, not the measurements.
  Metrics MAY appear as a small secondary callout later in the page (not here).
- The lede paragraph uses the domain framing from `## Discovery Domain` + the
  `objective:` from `domain-glossary.md` or `capability-inventory.md` as source.
- Omit the vocabulary teaser if `domain-glossary.md` is absent from the resolved doc-set.
- Omit the decisions teaser if `decisions.md` is absent from the resolved doc-set.

### Step 5 — Assemble the sections (concept-first trio → primary → extension → meta)

For each doc in the PROFILE manifest (after "At a Glance"), author one `<section>` using
the component assigned by the manifest:

#### Bespoke components (the three well-known docs)

Follow the templates in
`.codex/aid/templates/knowledge-summary/section-templates/bespoke-components.md`:
- `domain-glossary.md` → `§1` Glossary / definition component (`.gloss-grid`)
- `decisions.md` → `§2` Decision / ADR card component (`.adr-list`)
- `capability-inventory.md` → `§3` Capability entry component (`.cap-grid`)

Each bespoke component renders the doc's content directly — a newcomer reads the
definitions / decisions / capabilities on the page without opening any `.md` file.

#### Generic fallback (all other resolved docs)

For each non-bespoke doc, produce a `<section class="sec [featured]">` using this
structure:

```html
<section id="{doc-slug}" class="sec{featured}" aria-labelledby="{doc-slug}-heading">
  <header>
    <span class="eyebrow">{Tier label, e.g. "Project Structure" or "How we work"}</span>
    <h2 id="{doc-slug}-heading">{Section heading — newcomer-phrased}</h2>
    <p class="lede">{One-line description — "what you'll learn in this section."}</p>
  </header>

  {Section body — choose the best format per fact:}
  <!-- For catalogs → .tbl-wrap + table.tbl -->
  <!-- For grids → .grid.g2/.g3 + .card items -->
  <!-- For narrative → <p> paragraphs with the newcomer "what & why" -->
  <!-- For structure → inline SVG or HTML+CSS visual in .diagram-box (see authored-visual-catalog.md) -->
  <!-- Keyword pills (if tags: present): -->
  <div style="display:flex; flex-wrap:wrap; gap:0.4rem; margin: 0.75rem 0;">
    <span class="badge">{tag 1}</span>
    <span class="badge">{tag 2}</span>
  </div>

  <!-- See-also links (if see_also: present): -->
  <p class="meta" style="font-size:0.85rem; color:var(--text-dim);">
    Related: <a href="#{related-slug}">{Related section}</a>
  </p>

  <p class="meta" style="font-size:0.85rem; color:var(--text-dim);">
    Source: <a href="./{doc}.md">{doc}.md</a>
  </p>
</section>
```

Rules:
- `{featured}` → add class `featured` (→ ★ marker) for `kb-category: primary` docs that
  are domain-salient core docs (the concept-first trio always gets `featured`; for other
  primaries, apply featured to docs that are the clearest newcomer entry points).
- **`kb-category: meta`** docs (`external-sources.md`, `README.md`) → compact prose /
  reference list, rendered without `featured`; may be folded into the KB Index.
- **No section is ever skipped.** Every resolved doc gets a section, even if the content
  is thin. The generic fallback guarantees coverage (completeness = coverage of the
  resolved doc-set).

#### Tone for section content

Across ALL sections, maintain newcomer tone:
- Short sentences. Active voice. Explain the "why" not just the "what."
- Never use KB-internal terms (frontmatter, kb-category, dual-audience, tier, agent-role)
  as if the reader knows them.
- Treat each section as introducing the topic from scratch to someone with no prior
  project context.
- Numbers and code names (e.g. module names, command names) are fine as facts;
  explain their significance in plain English alongside them.

### Step 6 — Knowledge Base Index (always last)

The last section is a full table of every resolved doc with a one-line description:

```html
<section id="kb-index" class="sec" aria-labelledby="kb-index-heading">
  <header>
    <h2 id="kb-index-heading">Knowledge Base Index</h2>
    <p class="lede">All source documents in this project's Knowledge Base —
      click any document name to jump to its section on this page.</p>
  </header>
  <div class="tbl-wrap">
  <table class="tbl">
    <thead>
      <tr><th>Document</th><th>What it covers</th></tr>
    </thead>
    <tbody>
      <!-- One row per resolved doc, in manifest order: -->
      <tr>
        <td><a class="doc-link" href="#{section-id}"><code>{doc}.md</code></a></td>
        <td>{summary: value, or doc name de-slugified}</td>
      </tr>
    </tbody>
  </table>
  </div>
  <p class="meta" style="margin-top:1rem; font-size:0.85rem; color:var(--text-dim);">
    Source: <a href="./INDEX.md">INDEX.md</a> — generated KB map.
  </p>
</section>
```

**Link rule (mandatory).** Each document name MUST link to that document's **section on this
page** via the in-page anchor `#{section-id}`, where `{section-id}` is the exact `id` you
assigned to that doc's `<section>` (the filename stem, lowercased — e.g. `architecture.md` →
`#architecture`, `README.md` → `#readme`). Do **NOT** link to the raw `./{doc}.md` file:
in-page anchors keep kb.html self-contained (they work offline and when the file is shared
standalone) and open the *rendered* section, not unformatted markdown. Because these are
in-page section anchors — not links to source `.md` files — they comply with rule #6. The
`.doc-link` class (in `component-css.css`) re-asserts the `--accent` link color on the
code-styled filename so it reads as a link in both themes.

### Step 7 — Start from the skeleton

Open `references/html-skeleton.html`. Replace placeholders:
- `{{LANG}}` — `en` (or read from `AGENTS.md` if specified).
- `{{PROJECT_NAME}}` — from `.aid/knowledge/STATE.md` or build files.
- `{{INLINE_CSS}}` — full content of `references/component-css.css`.
- `{{BODY_CONTENT}}` — all sections from Steps 4–6, in order.
- `{{GENERATION_DATE}}` — today's date in `YYYY-MM-DD`.
- `{{INLINE_LIGHTBOX_JS}}` — full content of `references/lightbox.js`.
- `{{NOSCRIPT_DOC_LIST}}` — one `<li>` per resolved doc (in manifest order)
  derived from the doc-set, not hardcoded. Format:
  `<li><a href="./{doc}.md">{doc}.md</a> — {summary: value}</li>`.

### Step 8 — Produce the multi-source layout

Structure sources under `.aid/knowledge/summary-src/` as documented in
`references/state-generate.md §5`. The skeleton becomes `skeleton-head.html`;
each section becomes `sections/NN-{slug}.html`; closing shell becomes
`skeleton-foot.html`.

### Step 9 — Assemble via `assemble.sh`

```bash
mkdir -p .aid/dashboard
bash .codex/aid/scripts/summarize/assemble.sh --output .aid/dashboard/kb.html
```

The assembled `kb.html` is the single self-contained deliverable (all CSS/JS inlined).

### Step 10 — Update `.aid/knowledge/STATE.md`

Set `**Output Size:**` to actual file size, `**Last Run:**` to now (per `state-generate.md §8`).
Transition to VALIDATE.

---

## Pitfalls (must avoid)

- **Leading "At a Glance" with metrics.** Module counts, test counts, and LOC
  DO NOT lead the section. Put what & why first; metrics are a secondary detail.
- **Importing KB authoring rules.** The KB is dual-audience and diagram-free by design;
  the summary is neither. Never tell the reader "this doc is for architects and developers"
  or "this uses no diagrams" — those are KB-internal decisions, invisible to a newcomer.
- **Rendering `audience:` as a role-badge.** The `audience:` frontmatter field is
  machine-facing metadata; drop it entirely from the summary HTML.
- **Skipping a resolved doc.** Every doc in the manifest gets a section. No phantom
  sections for docs that do not exist; no dropped sections for docs that do.
- **Skipping the lightbox JS.** The focus-trapped lightbox must be inlined.
- **Inventing facts.** Every number and claim traces back to KB.
- **Hard-coding hex colours in SVG.** Use CSS custom properties (`var(--text)`,
  `var(--accent)`, etc.) so visuals adapt to light and dark themes.
- **CDN / split assets / runtime engine.** Everything inlined. No external fetches.
  No Mermaid engine or any other diagram runtime. Visuals are pre-rendered inline SVG
  or HTML+CSS (see `authored-visual-catalog.md` for patterns).
