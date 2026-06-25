---
kb-category: primary
notes: "Bespoke component HTML templates for the three concept-first docs (feature-015 Change 2
        / FR-46). These templates are used by GENERATE (state-generate.md §3) to render
        domain-glossary.md, decisions.md, and capability-inventory.md as first-class content,
        not as links. The component styles live in component-css.css (the three Concept-first
        content components sections). All HTML uses existing design tokens; shell/chrome is
        untouched (§5b)."
---

# Bespoke Component Templates (Concept-first — Change 2 / FR-46)

> **Purpose:** HTML authoring templates for the three well-known docs that always receive a
> bespoke component, regardless of domain or `kb-category` tier. Used during GENERATE
> (state-generate.md §3) to render these docs as content, not as links to `.md` files.
>
> **Component selection algorithm (deterministic):**
> 1. If doc filename is `domain-glossary.md` → Glossary / definition component (§1).
> 2. If doc filename is `decisions.md` → Decision / ADR card component (§2).
> 3. If doc filename is `capability-inventory.md` → Capability entry component (§3).
> 4. All other resolved docs → generic fallback (see `auto-detect.md` tier hints).
>
> **Key rule:** render as content, never as a bare link. A newcomer must never have to open a
> `.md` file to read the Concept Spine, the ADRs, or the capability catalogue.

---

## 1. Glossary / definition component — `domain-glossary.md`

**Source data:** the term/definition rows in the `domain-glossary.md` body (the Concept Spine
section). Each term entry has: term name, "Definition-as-used-here" paragraph, optional
"Aliases", "Relates-to" field, and "sources" list.

**Stable anchor:** `id="glossary"` on the `<section>`. Per-term anchors use `id="gloss-{slug}"`,
where `{slug}` is the term name lowercased with spaces replaced by hyphens.

### Section HTML template

```html
<section id="glossary" class="sec featured" aria-labelledby="glossary-heading">
  <header>
    <span class="eyebrow">Concept Spine</span>
    <h2 id="glossary-heading">Key Vocabulary</h2>
    <p class="lede">The words this project uses in a specific way — defined as used here,
      not generically. Read these first so the rest of the documentation makes sense.</p>
  </header>
  <div class="gloss-grid">

    <!-- Repeat the block below once per glossary term: -->
    <div class="gloss-card" id="gloss-{slug}">
      <div class="gloss-term">
        <a class="gloss-anchor" href="#gloss-{slug}">{Term Name}</a>
      </div>
      <p class="gloss-def">{Definition-as-used-here paragraph — plain language, newcomer-friendly.
        Omit jargon; explain what makes this definition project-specific.}</p>

      <!-- Relates-to pills (omit block if absent): -->
      <div class="gloss-meta">
        <span class="gloss-label">Relates to</span>
        <span class="gloss-pill gloss-pill-accent">{Related term A}</span>
        <span class="gloss-pill gloss-pill-accent">{Related term B}</span>
        <!-- Add one pill per related term listed in the Relates-to field. -->
      </div>

      <!-- Aliases (omit block if absent): -->
      <div class="gloss-meta">
        <span class="gloss-label">Also called</span>
        <span class="gloss-pill">{Alias}</span>
      </div>
    </div>
    <!-- End of one term block -->

  </div>
  <p class="meta" style="margin-top:1rem; font-size:0.85rem; color:var(--text-dim);">
    Source: <a href="./domain-glossary.md">domain-glossary.md</a>
    &mdash; {N} terms. Full definitions in the source document.
  </p>
</section>
```

### Authoring rules (glossary)

- **One `.gloss-card` per term** in the Concept Spine (not the Lexicon abbreviations; those
  are lower-priority and may be omitted or grouped into a compact table below the grid).
- **Definition text** must come from the doc's "Definition-as-used-here" field verbatim or
  paraphrased for friendliness — never invented.
- **Relates-to pills** come from the doc's "Relates-to" field. Link pills to `#gloss-{slug}`
  anchors when the related term appears in this same grid; otherwise render as plain pills.
- **Order:** preserve the Concept Spine order from the source document.
- **No bare links** to `domain-glossary.md` as the primary content — the rendered cards ARE
  the content. The footer "Source:" link is the only link to the source `.md`.

---

## 2. Decision / ADR card component — `decisions.md`

**Source data:** each `## D{N} — {Title}` section in `decisions.md`. Each ADR entry has:
Decision statement, Alternatives rejected list, Constraint that drove it.

**Stable anchor:** `id="decisions"` on the `<section>`. Per-ADR anchors use `id="adr-d{N}"`.

**Status mapping:** all current ADRs in `decisions.md` are `Accepted` (CONFIRMED) unless
tagged otherwise. Map "Accepted" to the `.accepted` status class; note superseded decisions
in the "Still Load-Bearing" section.

### Section HTML template

```html
<section id="decisions" class="sec" aria-labelledby="decisions-heading">
  <header>
    <span class="eyebrow">Architecture &amp; Design Rationale</span>
    <h2 id="decisions-heading">Key Decisions</h2>
    <p class="lede">The significant choices that shaped this project — what was decided,
      what was rejected, and why. These are the "whys" a newcomer cannot recover from
      the code alone.</p>
  </header>
  <div class="adr-list">

    <!-- Repeat the block below once per ADR: -->
    <div class="adr-card" id="adr-d{N}">
      <div class="adr-header">
        <span class="adr-id">D{N}</span>
        <span class="adr-title">{Decision title (from ## D{N} — {Title})}</span>
        <span class="adr-status accepted">Accepted</span>
        <!-- Status classes: accepted | deprecated | superseded | proposed -->
      </div>
      <div class="adr-body">
        <div class="adr-row">
          <span class="adr-row-label">Decision</span>
          <span class="adr-row-content">{The Decision paragraph — the choice that was made,
            one or two sentences, newcomer-friendly.}</span>
        </div>
        <div class="adr-row">
          <span class="adr-row-label">Rejected</span>
          <div class="adr-row-content adr-alts">
            <div class="adr-alt-item">{Alternative A — why it was rejected (brief).}</div>
            <div class="adr-alt-item">{Alternative B — why it was rejected (brief).}</div>
            <!-- One .adr-alt-item per alternative in the "Alternatives rejected" list. -->
          </div>
        </div>
        <div class="adr-row">
          <span class="adr-row-label">Why</span>
          <span class="adr-row-content">{The constraint or rationale that drove the decision —
            from the "Constraint that drove it" field.}</span>
        </div>
        <!-- Optional: consequence (omit if not in source): -->
        <div class="adr-row">
          <span class="adr-row-label">Consequence</span>
          <span class="adr-row-content">{Notable implication or gotcha for a newcomer, if any.}</span>
        </div>
      </div>
    </div>
    <!-- End of one ADR block -->

  </div>
  <p class="meta" style="margin-top:1rem; font-size:0.85rem; color:var(--text-dim);">
    Source: <a href="./decisions.md">decisions.md</a>
    &mdash; {N} decisions. Full rationale in the source document.
  </p>
</section>
```

### Authoring rules (ADR cards)

- **One `.adr-card` per `## D{N}` entry** in the source document.
- **Decision text** paraphrased for a newcomer — must not invent rationale. Use the
  "Decision:" paragraph as the source.
- **Alternatives rejected** — one `.adr-alt-item` per bullet in the "Alternatives rejected"
  list. Keep brief (one phrase + reason).
- **Why / constraint** — from the "Constraint that drove it" field or closing evidence sentence.
- **Consequence** — optional row; include only if the source notes a notable gotcha or implication
  (e.g., "GOTCHA: shipped scripts must stay ASCII-only and 5.1-compatible").
- **Status** — use `accepted` for CONFIRMED entries. Use `deprecated` or `superseded` only if
  the source explicitly marks the decision as overridden.
- **No bare links** to `decisions.md` as the primary content. The footer "Source:" link is
  the only link to the source `.md`.

---

## 3. Capability entry component — `capability-inventory.md`

**Source data:** the capability rows/tables in `capability-inventory.md`. Each capability has:
Capability name, Skill (invoke), What it accomplishes, When to use.

**Stable anchor:** `id="capabilities"` on the `<section>`. Per-capability anchors use
`id="cap-{slug}"`, where `{slug}` is the capability name lowercased with spaces replaced by
hyphens.

### Section HTML template

```html
<section id="capabilities" class="sec featured" aria-labelledby="capabilities-heading">
  <header>
    <span class="eyebrow">What AID Does For You</span>
    <h2 id="capabilities-heading">Capabilities</h2>
    <p class="lede">Everything this project can do for its users — each capability explained
      in plain language: what it does, when to reach for it, and how to invoke it.</p>
  </header>

  <!-- Optional: group cards by section (pipeline / on-demand) with a sub-heading: -->
  <h3 style="margin: 0 0 0.75rem; color:var(--text-muted); font-size:0.9rem;
             text-transform:uppercase; letter-spacing:0.06em;">
    Pipeline capabilities (lifecycle order)
  </h3>
  <div class="cap-grid">

    <!-- Repeat the block below once per capability: -->
    <div class="cap-card" id="cap-{slug}">
      <div class="cap-kicker">{Section label, e.g. "Pipeline" or "On-demand"}</div>
      <div class="cap-name">{Capability name, e.g. "Discover"}</div>
      <!-- Invoke pill (omit if no slash command): -->
      <code class="cap-invoke">{/aid-command}</code>
      <dl class="cap-dl">
        <dt>What</dt>
        <dd>{What it accomplishes — one to two sentences, newcomer-friendly.}</dd>
        <dt>When</dt>
        <dd>{When to use it — the trigger or situation that calls for this capability.}</dd>
      </dl>
    </div>
    <!-- End of one capability card -->

  </div>

  <!-- Repeat .cap-grid with a new sub-heading for each capability group: -->
  <h3 style="margin: 1.25rem 0 0.75rem; color:var(--text-muted); font-size:0.9rem;
             text-transform:uppercase; letter-spacing:0.06em;">
    On-demand capabilities
  </h3>
  <div class="cap-grid">
    <!-- ... additional cap-cards for on-demand capabilities ... -->
  </div>

  <p class="meta" style="margin-top:1rem; font-size:0.85rem; color:var(--text-dim);">
    Source: <a href="./capability-inventory.md">capability-inventory.md</a>
    &mdash; {N} capabilities. Full details in the source document.
  </p>
</section>
```

### Authoring rules (capability entries)

- **One `.cap-card` per capability row** in the source table(s).
- **What** — from the "What it accomplishes" column. Paraphrase for newcomer friendliness;
  never invent a purpose not stated in the source.
- **When** — from the "When to use" column. Keep brief (one sentence or phrase).
- **Invoke pill** — from the "Skill (invoke)" column. Render as `<code class="cap-invoke">`.
  Omit if the capability has no user-facing slash command (e.g., maintainer-only tools).
- **Grouping** — follow the source document's section grouping (pipeline capabilities /
  on-demand / maintainer-only). Use subordinate `<h3>` headings to separate groups.
  Omit the maintainer-only group or render it as a compact note rather than full cards.
- **No bare links** to `capability-inventory.md` as the primary content. The footer
  "Source:" link is the only link to the source `.md`.
