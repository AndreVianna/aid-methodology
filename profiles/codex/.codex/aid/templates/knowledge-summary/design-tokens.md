# Design Tokens

Single source of truth for the visual language used by `/aid-summarize`. The same
tokens appear in:

- `references/component-css.css` — as CSS custom properties on `:root` and
  `html[data-theme="dark"]`.
- `references/mermaid-init.js` — as `themeVariables` for Mermaid in both modes.

## Color palette

### Light theme

| Token | Hex | Use |
|---|---|---|
| `--bg` | `#F7F9FC` | Page background |
| `--bg-elev` | `#FFFFFF` | Cards, top bar |
| `--bg-sunken` | `#EEF2F7` | Table headers, sunken inputs |
| `--text` | `#101828` | Body text |
| `--text-muted` | `#4B5565` | Secondary text |
| `--text-dim` | `#667085` | Captions, labels |
| `--border` | `#E3E8EF` | Default borders |
| `--border-strong` | `#CDD5DF` | Emphasized borders |
| `--primary` | `#0B1F3A` | Brand primary |
| `--primary-fg` | `#FFFFFF` | On-primary text |
| `--accent` | `#00A3A1` | Brand accent (teal) |
| `--accent-fg` | `#FFFFFF` | On-accent text |
| `--ok` | `#2E7D32` | Success / shipped |
| `--ok-bg` | `#E8F5E9` | Success tint |
| `--warn` | `#B45309` | Warning |
| `--warn-bg` | `#FEF3C7` | Warning tint |
| `--err` | `#B42318` | Error / critical |
| `--err-bg` | `#FEE4E2` | Error tint |
| `--info` | `#1D4ED8` | Info |
| `--info-bg` | `#DBEAFE` | Info tint |
| `--purple` | `#6941C6` | Experimental / accent2 |
| `--purple-bg` | `#F4EBFF` | Purple tint |

### Dark theme

| Token | Hex | Use |
|---|---|---|
| `--bg` | `#0B1220` | Page background |
| `--bg-elev` | `#111A2E` | Cards, top bar |
| `--bg-sunken` | `#081021` | Table headers |
| `--text` | `#E5EAF2` | Body text |
| `--text-muted` | `#9AA5B8` | Secondary text |
| `--text-dim` | `#8A99B8` | Captions (≥4.5:1 on `--bg-elev`) |
| `--border` | `#1E293B` | Default borders |
| `--border-strong` | `#2B3A52` | Emphasized borders |
| `--primary` | `#0D2A52` | Brand primary |
| `--primary-fg` | `#E8F2FF` | On-primary text |
| `--accent` | `#2DD4D2` | Brand accent (teal, brighter) |
| `--accent-fg` | `#051514` | On-accent text |
| `--ok` | `#4ADE80` | Success |
| `--ok-bg` | `rgba(34,197,94,0.15)` | Success tint |
| `--warn` | `#FBBF24` | Warning |
| `--warn-bg` | `rgba(251,191,36,0.15)` | Warning tint |
| `--err` | `#F87171` | Error |
| `--err-bg` | `rgba(220,38,38,0.20)` | Error tint |
| `--info` | `#60A5FA` | Info |
| `--info-bg` | `rgba(37,99,235,0.18)` | Info tint |
| `--purple` | `#C084FC` | Experimental |
| `--purple-bg` | `rgba(147,51,234,0.18)` | Purple tint |

## Typography

```
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Inter, Roboto,
             "Helvetica Neue", Arial, sans-serif
```

System fonts only — no web fonts. Sizes:

| Element | Size | Weight |
|---|---|---|
| `<h1>` | 2.2rem | 600 |
| Hero `<h1>` | 2.6rem | 600 |
| `<h2>` (section) | 1.85rem | 600 |
| `<h3>` | 1.15rem | 600 |
| `<h4>` (kicker) | 1rem | 600, uppercase, letter-spacing 0.04em |
| Body | 1rem | 400 |
| Card stat | 2rem | 700 |
| Badge | 0.78rem | 500 |
| Eyebrow | 0.78rem | 700, letter-spacing 0.08em, uppercase |

Line-height: 1.55 body, 1.25 headings.

## Spacing & sizing

| Token | Value |
|---|---|
| `--radius-sm` | 6px |
| `--radius` | 10px |
| `--radius-lg` | 14px |
| `--shadow-sm` | `0 1px 3px rgba(16,24,40,0.06), 0 1px 2px rgba(16,24,40,0.04)` |
| `--shadow-md` | `0 4px 8px -2px rgba(16,24,40,0.08), 0 2px 4px -2px rgba(16,24,40,0.04)` |
| `--shadow-lg` | `0 12px 24px -4px rgba(16,24,40,0.12), 0 4px 8px -4px rgba(16,24,40,0.06)` |
| Max content width | 1200px |
| Top-bar height | ~60px (sticky, `z-index: 100`) |
| Mobile breakpoint | 768px (collapse grids to 1fr) |

## Theming overrides per project

To use a different brand palette, override the `:root` variables in a `<style>`
block before the inlined `component-css.css`:

```html
<style>
:root, html[data-theme="light"] {
    --primary: #YOUR_PRIMARY;
    --accent:  #YOUR_ACCENT;
    /* keep ok/warn/err for status — they convey meaning */
}
html[data-theme="dark"] {
    --primary: #YOUR_PRIMARY_DARK;
    --accent:  #YOUR_ACCENT_DARK;
}
</style>
```

**Constraint:** any override must still pass WCAG AA contrast in both themes
(see `accessibility-checklist.md`). The grading rubric runs `contrast-check.mjs`
against the actual computed values.
