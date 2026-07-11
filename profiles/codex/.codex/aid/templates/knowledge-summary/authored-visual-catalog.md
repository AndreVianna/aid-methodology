# Authored-Visual Catalog (for `/aid-summarize`)

Inline SVG and HTML+CSS pattern templates for visuals in `kb.html`.
All visuals are **pre-rendered at build time** into inline `<svg>` or HTML+CSS
elements -- no runtime diagram engine, no CDN fetch, no external dependency.
Every visual must fit inside a `.diagram-box` wrapper (see `component-css.css`)
and be viewable in the lightbox.

Design tokens live in `design-tokens.md`. Use only the CSS custom properties
(`var(--accent)`, `var(--text)`, etc.) -- never hard-code colours -- so the
visual is automatically correct in both light and dark themes.

The section-7 quality gates validate every authored visual for:
- Readable text (legible font size, not clipped)
- Minimal / zero element overlap
- Correct basic layout (non-trivial, not collapsed or empty)

---

## When to use a visual

Choose a visual when a structural relationship, flow, or grouping communicates
more clearly than prose or a table. Each visual must have a `.caption` block
(`Figure N. <one-sentence summary>. Source: <link>`).

If no visual adds clarity, omit it -- there is no diagram floor.

---

## Pattern 1 -- Flow diagram (left-to-right)

Use for: request flows, pipeline steps, workflow sequences.

```html
<div class="diagram-box" role="button" tabindex="0"
     aria-label="Figure 1. Request flow diagram -- click or press Enter to expand">
  <svg xmlns="http://www.w3.org/2000/svg"
       viewBox="0 0 500 100" width="100%" role="img"
       aria-label="Request flow: Client to Service to Database">
    <defs>
      <marker id="arr-flow1" markerWidth="8" markerHeight="8"
              refX="6" refY="4" orient="auto">
        <path d="M0,0 L8,4 L0,8 Z" fill="var(--text-muted)"/>
      </marker>
    </defs>

    <!-- Nodes -->
    <rect x="10" y="30" width="100" height="40" rx="6"
          fill="var(--bg-elev)" stroke="var(--accent)" stroke-width="2"/>
    <text x="60" y="55" text-anchor="middle" font-size="13"
          font-family="system-ui,sans-serif" fill="var(--text)">Client</text>

    <rect x="200" y="30" width="120" height="40" rx="6"
          fill="var(--bg-elev)" stroke="var(--accent)" stroke-width="2"/>
    <text x="260" y="55" text-anchor="middle" font-size="13"
          font-family="system-ui,sans-serif" fill="var(--text)">App Service</text>

    <rect x="390" y="30" width="100" height="40" rx="6"
          fill="var(--bg-sunken)" stroke="var(--border-strong)" stroke-width="2"/>
    <text x="440" y="55" text-anchor="middle" font-size="13"
          font-family="system-ui,sans-serif" fill="var(--text)">Database</text>

    <!-- Arrows -->
    <line x1="110" y1="50" x2="198" y2="50"
          stroke="var(--text-muted)" stroke-width="1.5" marker-end="url(#arr-flow1)"/>
    <line x1="320" y1="50" x2="388" y2="50"
          stroke="var(--text-muted)" stroke-width="1.5" marker-end="url(#arr-flow1)"/>
  </svg>
  <p class="caption">Figure 1. HTTP request flows from Client through App Service to
    Database. Source: <a href="./architecture.md">architecture.md</a></p>
</div>
```

**Rules:**
- Minimum font-size 12px; preferred 13-14px for node labels.
- Use `var(--bg-elev)` / `var(--bg-sunken)` fills so nodes adapt to theme.
- Use `var(--text)` for label text; `var(--text-muted)` for arrows.
- Ensure nodes do not overlap: allow at least 30px horizontal gap between boxes.
- Each `<marker id>` must be unique within the page if you embed multiple SVGs.
  Prefix with a diagram-specific slug: `id="arr-flow1"`.

---

## Pattern 2 -- Hierarchy diagram (top-to-bottom)

Use for: organizational structure, module layers, component hierarchy.

```html
<div class="diagram-box" role="button" tabindex="0"
     aria-label="Figure 2. Layer hierarchy -- click or press Enter to expand">
  <svg xmlns="http://www.w3.org/2000/svg"
       viewBox="0 0 420 200" width="100%" role="img"
       aria-label="Three-layer architecture: UI on top, Core in middle, Data at bottom">
    <defs>
      <marker id="arr-hier2" markerWidth="8" markerHeight="8"
              refX="6" refY="4" orient="auto">
        <path d="M0,0 L8,4 L0,8 Z" fill="var(--text-muted)"/>
      </marker>
    </defs>

    <!-- Layer 1: top -->
    <rect x="110" y="10" width="200" height="40" rx="6"
          fill="var(--bg-elev)" stroke="var(--accent)" stroke-width="2"/>
    <text x="210" y="35" text-anchor="middle" font-size="13"
          font-family="system-ui,sans-serif" fill="var(--text)">UI Layer</text>

    <!-- Layer 2: middle -->
    <rect x="60" y="90" width="130" height="40" rx="6"
          fill="var(--bg-elev)" stroke="var(--accent)" stroke-width="2"/>
    <text x="125" y="115" text-anchor="middle" font-size="13"
          font-family="system-ui,sans-serif" fill="var(--text)">Core Logic</text>

    <rect x="230" y="90" width="130" height="40" rx="6"
          fill="var(--bg-elev)" stroke="var(--accent)" stroke-width="2"/>
    <text x="295" y="115" text-anchor="middle" font-size="13"
          font-family="system-ui,sans-serif" fill="var(--text)">API Gateway</text>

    <!-- Layer 3: bottom -->
    <rect x="140" y="165" width="140" height="40" rx="6"
          fill="var(--bg-sunken)" stroke="var(--border-strong)" stroke-width="2"/>
    <text x="210" y="190" text-anchor="middle" font-size="13"
          font-family="system-ui,sans-serif" fill="var(--text)">Data Store</text>

    <!-- Connecting lines -->
    <line x1="155" y1="50" x2="125" y2="88"
          stroke="var(--text-muted)" stroke-width="1.5" marker-end="url(#arr-hier2)"/>
    <line x1="265" y1="50" x2="295" y2="88"
          stroke="var(--text-muted)" stroke-width="1.5" marker-end="url(#arr-hier2)"/>
    <line x1="125" y1="130" x2="175" y2="163"
          stroke="var(--text-muted)" stroke-width="1.5" marker-end="url(#arr-hier2)"/>
    <line x1="295" y1="130" x2="245" y2="163"
          stroke="var(--text-muted)" stroke-width="1.5" marker-end="url(#arr-hier2)"/>
  </svg>
  <p class="caption">Figure 2. Three-layer architecture. Source:
    <a href="./architecture.md">architecture.md</a></p>
</div>
```

---

## Pattern 3 -- Relationship map (entity boxes with labelled edges)

Use for: data models, integration hubs, domain relationships.

```html
<div class="diagram-box" role="button" tabindex="0"
     aria-label="Figure 3. Entity relationship map -- click or press Enter to expand">
  <svg xmlns="http://www.w3.org/2000/svg"
       viewBox="0 0 480 160" width="100%" role="img"
       aria-label="Asset contains one-or-more Materials; each Material has TechnicalMetadata">
    <defs>
      <marker id="arr-rel3" markerWidth="8" markerHeight="8"
              refX="6" refY="4" orient="auto">
        <path d="M0,0 L8,4 L0,8 Z" fill="var(--text-muted)"/>
      </marker>
    </defs>

    <!-- Entity: Asset -->
    <rect x="20" y="50" width="130" height="60" rx="6"
          fill="var(--bg-elev)" stroke="var(--accent)" stroke-width="2"/>
    <text x="85" y="75" text-anchor="middle" font-size="13" font-weight="600"
          font-family="system-ui,sans-serif" fill="var(--text)">Asset</text>
    <text x="85" y="93" text-anchor="middle" font-size="11"
          font-family="system-ui,sans-serif" fill="var(--text-muted)">id, name, status</text>

    <!-- Entity: Material -->
    <rect x="185" y="50" width="130" height="60" rx="6"
          fill="var(--bg-elev)" stroke="var(--accent)" stroke-width="2"/>
    <text x="250" y="75" text-anchor="middle" font-size="13" font-weight="600"
          font-family="system-ui,sans-serif" fill="var(--text)">Material</text>
    <text x="250" y="93" text-anchor="middle" font-size="11"
          font-family="system-ui,sans-serif" fill="var(--text-muted)">id, name, assetId</text>

    <!-- Entity: TechnicalMetadata -->
    <rect x="350" y="50" width="110" height="60" rx="6"
          fill="var(--bg-sunken)" stroke="var(--border-strong)" stroke-width="2"/>
    <text x="405" y="72" text-anchor="middle" font-size="12" font-weight="600"
          font-family="system-ui,sans-serif" fill="var(--text)">Technical</text>
    <text x="405" y="88" text-anchor="middle" font-size="12" font-weight="600"
          font-family="system-ui,sans-serif" fill="var(--text)">Metadata</text>

    <!-- Edge: Asset -> Material, with label -->
    <line x1="150" y1="80" x2="183" y2="80"
          stroke="var(--text-muted)" stroke-width="1.5" marker-end="url(#arr-rel3)"/>
    <text x="166" y="74" text-anchor="middle" font-size="10"
          font-family="system-ui,sans-serif" fill="var(--text-muted)">1..*</text>

    <!-- Edge: Material -> TechnicalMetadata -->
    <line x1="315" y1="80" x2="348" y2="80"
          stroke="var(--text-muted)" stroke-width="1.5" marker-end="url(#arr-rel3)"/>
    <text x="331" y="74" text-anchor="middle" font-size="10"
          font-family="system-ui,sans-serif" fill="var(--text-muted)">1:1</text>
  </svg>
  <p class="caption">Figure 3. Core data model relationships. Source:
    <a href="./artifact-schemas.md">artifact-schemas.md</a></p>
</div>
```

---

## Pattern 4 -- Timeline / phases (horizontal)

Use for: project phases, delivery sequence, lifecycle stages.

```html
<div class="diagram-box" style="overflow-x:auto">
  <div style="min-width:420px; padding:1rem 0">
    <div style="display:flex; align-items:center; gap:0; position:relative">
      <!-- Phase pill -->
      <div style="text-align:center; flex:1">
        <div style="background:var(--accent); color:var(--accent-fg);
                    border-radius:999px; padding:0.35rem 0.75rem;
                    font-size:0.82rem; font-weight:600; white-space:nowrap">
          Discover
        </div>
        <p style="margin:0.25rem 0 0; font-size:0.78rem; color:var(--text-muted)">KB produced</p>
      </div>
      <!-- Connector -->
      <div style="flex:0 0 2rem; height:2px; background:var(--border-strong)"></div>
      <div style="text-align:center; flex:1">
        <div style="background:var(--accent); color:var(--accent-fg);
                    border-radius:999px; padding:0.35rem 0.75rem;
                    font-size:0.82rem; font-weight:600; white-space:nowrap">
          Specify
        </div>
        <p style="margin:0.25rem 0 0; font-size:0.78rem; color:var(--text-muted)">SPEC.md done</p>
      </div>
      <div style="flex:0 0 2rem; height:2px; background:var(--border-strong)"></div>
      <div style="text-align:center; flex:1">
        <div style="background:var(--accent); color:var(--accent-fg);
                    border-radius:999px; padding:0.35rem 0.75rem;
                    font-size:0.82rem; font-weight:600; white-space:nowrap">
          Implement
        </div>
        <p style="margin:0.25rem 0 0; font-size:0.78rem; color:var(--text-muted)">Code shipped</p>
      </div>
    </div>
  </div>
  <p class="caption">Figure 4. Delivery phases. Source:
    <a href="./process-architecture.md">process-architecture.md</a></p>
</div>
```

---

## Pattern 5 -- Stat / metric card grid

Use for: key metrics, capability counts, version badges. Does NOT require SVG.

```html
<div style="display:grid; grid-template-columns:repeat(auto-fill,minmax(140px,1fr)); gap:1rem; margin:1rem 0">
  <div style="background:var(--bg-elev); border:1px solid var(--border);
              border-radius:8px; padding:1rem; text-align:center">
    <span style="display:block; font-size:2rem; font-weight:700;
                 color:var(--accent); line-height:1">42</span>
    <span style="font-size:0.82rem; color:var(--text-muted)">Skills</span>
  </div>
  <div style="background:var(--bg-elev); border:1px solid var(--border);
              border-radius:8px; padding:1rem; text-align:center">
    <span style="display:block; font-size:2rem; font-weight:700;
                 color:var(--accent); line-height:1">v1.1</span>
    <span style="font-size:0.82rem; color:var(--text-muted)">Version</span>
  </div>
</div>
<!-- No caption needed for metric grids; they are supplementary details -->
```

---

## Common failure patterns (for the §7 visual-fidelity gate)

When a visual inspection flags a problem, look up the symptom here.

| Symptom | Cause | Fix |
|---------|-------|-----|
| Text clipped at SVG edge | `viewBox` too narrow for label width | Widen `viewBox` or shorten label text |
| Two nodes overlap | Insufficient gap between x-coordinates | Increase x spacing by at least 30px |
| Text invisible in dark theme | Used a hard-coded light colour instead of `var(--text)` | Replace every hard-coded colour with a CSS token |
| SVG collapses to zero height | Missing `height` or `viewBox` attribute | Add `viewBox="0 0 W H"` and `width="100%"` |
| Lightbox shows empty box | `<svg>` has no child elements | Check SVG authoring; ensure at least one `<rect>` or `<path>` is present |
| Arrow invisible | `id` collision between two SVGs' `<marker>` elements | Prefix marker IDs with a unique diagram slug |
| Content cut off on narrow screen | Fixed `width` in px on `<svg>` | Use `width="100%"` and `viewBox` for intrinsic aspect ratio |
| Long label overflows rect | Underestimated text width | Split label to two `<text>` lines or widen the `<rect>` |

## Hard rules for every authored visual

1. **Use CSS tokens, never hard-coded colours.** `fill="var(--text)"`, not
   `fill="#101828"` -- so the visual works in both light and dark themes.
2. **Minimum font-size 12px.** Smaller text is unreadable at normal zoom.
3. **Unique `<marker id>` per SVG.** Prefix with a diagram slug
   (e.g. `id="arr-arch-flow"`) to avoid id collisions across multiple inline SVGs
   on the same page.
4. **`viewBox` + `width="100%"` on every `<svg>`.** Never rely on a fixed pixel
   width; the lightbox and narrow viewports will clip it.
5. **No node/label overlap.** Place boxes so their bounding rects do not intersect.
   Minimum 30px horizontal gap; minimum 20px vertical gap.
6. **Caption every diagram.** Format: `Figure N. <one-sentence summary>. Source: <link>`.
7. **`aria-label` on the `<svg>` element.** One sentence describing what the SVG
   shows, for screen-reader users.
