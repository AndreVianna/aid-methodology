# casuloailabs.com — Brand & Design Reference

Extracted from the live site repo `AndreVianna/casuloailabs.com` (cloned at
`~/projects/casuloailabs`) on 2026-06-06. The AID docs site must inherit this visual
identity so it reads as **product documentation within the casuloailabs.com family**.

## Stack of the parent site

- Hand-authored **static HTML/CSS/JS** (no generator). Files: `index.html`, `styles.css`,
  `script.js`, plus `blog/` (hand-written per-post `index.html` + `blog.css`).
- Published via **GitHub Pages**; apex custom domain via `CNAME`; DNS managed at **GoDaddy**.
- The existing AID blog post lives at `blog/aid-methodology/index.html` (+ `images/1-pipeline.png`,
  `2-comparison.png`, `3-ironman.png`, `4-feedback-loops.png`).

## Design tokens (from `styles.css :root`)

| Token | Value | Role |
|-------|-------|------|
| `--bg-primary` | `#0a0e1a` | page background (dark) |
| `--bg-secondary` | `#111827` | section background |
| `--bg-card` | `#1a2035` | cards / panels |
| `--bg-card-hover` | `#212b45` | card hover |
| `--text-primary` | `#f1f5f9` | body text |
| `--text-secondary` | `#94a3b8` | secondary text |
| `--text-muted` | `#64748b` | muted/captions |
| `--accent` | `#d4a853` | **signature gold** — links, CTAs, highlights |
| `--accent-hover` | `#e6bc6a` | accent hover |
| `--accent-glow` | `rgba(212,168,83,0.15)` | glow/aura |
| `--border` | `rgba(148,163,184,0.1)` | hairline borders |
| `--border-accent` | `rgba(212,168,83,0.3)` | accent borders |
| `--radius` / `--radius-sm` | `12px` / `8px` | corner radius |
| `--max-width` | `1200px` | content max width |
| `--nav-height` | `72px` | sticky nav height |

- **Typography:** `Inter` (Google Fonts), weights 400/500/600/700/800; system-font fallback.
- **Theme:** dark-first, warm gold accent on deep navy; translucent sticky nav
  (`rgba(10,14,26,0.85)` + blur); card-based layout; SVG line icons (stroke 2);
  subtle `fade-in` scroll animations.

## Parent-site nav model (for cross-linking)

Top nav brand: **"Casulo AI Labs"**. Links: Problem · Solution · Services · Promise ·
Why Us · Proof · **Blog** · *Get Assessment* (CTA). Footer: Ottawa, Canada · "Built by
engineers, for engineers." · © 2026 Casulo AI Labs.

→ The AID docs site should expose a back-link to `casuloailabs.com` (and ideally the parent
site adds an "AID" / "Docs" entry pointing to `aid.casuloailabs.com`).

## Implication for tooling

Whatever generator is chosen must allow overriding theme colors with these exact tokens
(dark `#0a0e1a` base, gold `#d4a853` accent) and the Inter font. CSS-custom-property-based
theming (e.g. Astro Starlight) maps these 1:1; palette-based theming (e.g. MkDocs Material)
reaches the same result with a custom stylesheet.
