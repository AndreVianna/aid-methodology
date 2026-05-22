# Agent Prompt — `/aid-summarize` GENERATE state

This is the long-form prompt the agent follows when in GENERATE state. The
SKILL.md state machine wraps this with the bookkeeping (state file updates,
preflight, etc.); this file describes the actual content generation work.

---

## Inputs

- **`.aid/knowledge/`** — the populated, approved KB.
- **`SUMMARY-STATE.md`** — has the chosen profile, theme, minimum grade.
- **`DISCOVERY-STATE.md`** — has the project's overall grade, project type,
  external doc paths, Review History.
- **`references/section-templates/{profile}.md`** — the section list to render.
- **`references/component-css.css`** — the styles to inline.
- **`references/lightbox.js`** — the script to inline.
- **`references/mermaid-init.js`** — Mermaid theme variables (already inside
  `lightbox.js`; mentioned for completeness).
- **`references/html-skeleton.html`** — the document shell with placeholders.
- **`references/mermaid-examples.md`** — diagram syntax patterns and pitfall
  table.
- **`references/design-tokens.md`** — palette / typography reference.
- **`.aid/knowledge/.cache/mermaid.min.js`** — the inlined library.

## Output

`.aid/knowledge/knowledge-summary.html` — single-file deliverable.

---

## Authoring rules

1. **The KB is authoritative.** Never invent facts. Every numeric or named fact
   in the HTML must trace back to a populated KB document.
2. **Cite sources.** Every section header has a "Source:" reference link to the
   KB document(s) that fed it (e.g., `<a href="./architecture.md">architecture.md</a>`).
3. **Code-first if KB and design docs disagree.** Same rule discovery uses.
4. **No emojis** in titles or section bodies. Status icons (✓ ✗ ⚠) are OK as
   meaningful markers; emojis as decoration are not.
5. **Diagram labels:** never use `<word>` HTML-tag-like tokens. Use `{word}` or
   `[word]`. Only `<b>`, `<i>`, and `<br/>` are safe HTML in Mermaid labels.
6. **Captions:** every diagram has a `.caption` block with format
   `Figure N. <one-sentence summary>. Source: <link>`.

---

## Step-by-step

### Step 1 — Read the active section template

Open `references/section-templates/{profile}.md`. It tells you:
- Which numbered sections to produce
- Which KB documents feed each section
- Which diagrams belong to which section
- Whether each section is "featured" (gets ★ marker)

If a KB document referenced by the template does NOT exist in
`.aid/knowledge/`, drop the section that depends on it. Never invent content
to fill gaps.

### Step 2 — Read the KB

Read every KB document. Extract the most "summary-worthy" content per doc:
- For tables: pick the most informative rows; drop verbose ones.
- For prose: pick the lede paragraph + any callout-style bullets.
- For lists: pick the top 5–7 entries; drop the long tail.
- For ASCII diagrams: convert to Mermaid (see Step 4).

Maintain a running list of "facts" — each fact is a `(claim, source-doc, source-line)`
triple. You'll cite these in the HTML.

### Step 3 — Read the project's identity

Open `DISCOVERY-STATE.md` for project name, type, version, Review History.
If the project root has a `pom.xml`, `package.json`, `Cargo.toml`, etc., read
the version + name from there. Cross-check against KB.

### Step 4 — Plan the diagrams

For each diagram listed in the active section template:
1. Decide the diagram TYPE (flowchart TB / LR, graph TD, erDiagram,
   sequenceDiagram, etc.).
2. Sketch the nodes and edges from the relevant KB document.
3. Apply the standard `classDef` palette from `mermaid-examples.md`.
4. Check against the "Common failure patterns" table — eliminate `<word>`
   tokens, ensure `-. text .->` has spaces, use explicit edge sources, no
   unclosed quotes.

If a KB document already contains a Mermaid block, prefer to reuse it
verbatim if it follows our conventions; otherwise re-author.

### Step 5 — Write `part1.html`

Start from `references/html-skeleton.html`. Replace placeholders:
- `{{LANG}}` — `en` (or read from CLAUDE.md if specified).
- `{{PROJECT_NAME}}` — from DISCOVERY-STATE.md or build files.
- `{{INLINE_CSS}}` — full content of `references/component-css.css`.
- `{{BODY_CONTENT}}` — the section content you've written (Step 6 below).
- `{{GENERATION_DATE}}` — today's date in `YYYY-MM-DD`.
- `{{MERMAID_VERSION}}` — fetched version from SUMMARY-STATE.md.
- `{{INLINE_LIGHTBOX_JS}}` — full content of `references/lightbox.js`.
- `{{MERMAID_VERSION_COMMENT}}` — `Mermaid v{ver} bundled inline below`.

Cut the file at the empty `<script>` tag that will host the Mermaid library
(the second `<script>` block in the skeleton). That cut point is `part1.html`.

### Step 6 — Write the body content

Section by section, drawing from KB:

#### §1 — At a Glance

Use `.grid.g4` for a card grid of key numerics. Each card:
```html
<div class="card">
    <div class="kicker">{Label}</div>
    <div class="stat">{Number}</div>
    <div class="stat-sub">{One-line context}</div>
</div>
```

Pick 6–8 numerics that orient a stranger:
- Module/package count
- Persistent entity count
- Public API surface count (endpoints / exported symbols / subcommands)
- Backend test count
- Component / container / DI element count
- Major external integration count
- Downstream consumer (if any) — use `.card-primary` for emphasis

End with a single `.callout` card explaining "what this is" in one paragraph.

#### §2 — Architecture

3 diagrams + a `.grid.g2` of intent-vs-reality cards. Diagrams:
1. Stack layers
2. Module dependency DAG
3. Request/data flow

Cards: documented intent · implementation reality · technology choices ·
DI/wiring style.

#### §3 — Modules / Plugins / Components

Card per module using `.card.plugin`. Each card:
```html
<div class="card plugin">
    <div class="kicker">{Layer/Role}</div>
    <div class="plugin-name">com.example.foo</div>
    <h3>{Display name}</h3>
    <div class="plugin-body">{One-paragraph purpose}</div>
    <dl>
        <dt>Public API</dt><dd>...</dd>
        <dt>Entities</dt><dd>...</dd>
        <dt>Tests</dt><dd>...</dd>
    </dl>
    <div class="plugin-stats">
        <span class="badge">N Java</span>
        <span class="badge badge-ok">N tests</span>
    </div>
</div>
```

#### §4 — Data Model

ER diagram + the entity catalog table from data-model.md:
```html
<div class="tbl-wrap">
<table class="tbl">
    <thead>...</thead>
    <tbody>...</tbody>
</table>
</div>
```

Plus 3–4 callouts for known data-model gotchas (no version on aggregate, etc.).

#### §5 — API Surface (or equivalent for profile)

Namespace / endpoint / symbol table. For web-app, this is REST routes; for
library, exported symbols; for CLI, subcommands.

#### §6 — Integrations

Integration hub diagram + workflow + event-flow + a summary table.

#### §7+ — Per profile-specific sections

Follow the active template.

#### Last section — Knowledge Base Index

Table of every KB doc with a 1-line description. Mirrors `INDEX.md`.

### Step 7 — Add diagrams

Insert each diagram inside a `.mermaid-box`:
```html
<div class="mermaid-box">
    <pre class="mermaid">
flowchart LR
    classDef ...
    A --> B
    </pre>
    <div class="caption">Figure N. Summary. Source: <a href="./xxx.md">xxx.md</a></div>
</div>
```

The lightbox JS automatically wires up click-to-expand on every `.mermaid-box`.

### Step 8 — Write `part2.html`

The remainder of the skeleton after the Mermaid library script tag:
- Closing `</script>` for the Mermaid script
- The `<script>` containing `{{INLINE_LIGHTBOX_JS}}` (already replaced)
- `</body></html>`

### Step 9 — Concatenate

Use the platform-appropriate concat script:
- POSIX: `scripts/concatenate.sh part1.html mermaid.min.js part2.html OUTPUT`
- Windows: `scripts/concatenate.ps1 -Part1 ... -Mermaid ... -Part2 ... -Output ...`

Output: `.aid/knowledge/knowledge-summary.html`.

Remove temp `part1.html` and `part2.html`.

### Step 10 — Update SUMMARY-STATE.md

Set `**Output Size:**` to actual file size, `**Last Run:**` to now.

Transition to VALIDATE.

---

## Pitfalls (must avoid)

- **`<word>` tokens in diagrams.** Use `{word}` instead.
- **Re-using innerHTML for diagram source.** Always `el.textContent = el.dataset.source`
  on re-render. (This is in `lightbox.js` already — don't deviate.)
- **Continuation arrows without explicit source.** Each edge gets `A --> B`.
- **Lightbox SVG bg/padding on the SVG itself.** Put chrome on `.lb-inner`.
- **Forgetting to escape special chars.** When inserting KB content as text,
  HTML-encode `<`, `>`, `&`. When inserting as code (inside `<code>`), the
  encoding is the same.
- **Inventing facts.** Every number traces back to KB.
- **Skipping the Mermaid validator.** D1 = automatic F. Validate before claiming done.
