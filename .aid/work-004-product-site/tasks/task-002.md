# task-002: Casulo brand theme CSS (token overrides + font)

**Type:** CONFIGURE

**Source:** feature-001-site-foundation → delivery-001

**Depends on:** task-001

**Scope:**
- Author `site/src/styles/casulo.css` as the single-source brand layer (D3): declare the casulo brand tokens, then map them onto Starlight's CSS custom properties for the dark default scope and the `:root[data-theme='light']` scope.
- Map dark mode to gold `#d4a853` accents on dark `#0a0e1a`; map light mode text-weight accents to the darkened gold `#8a6418` (AA on white) per the SPEC contrast contract (A2).
- Import Inter via `@fontsource/inter` (weights 400/500/600/700/800), self-hosted (D9); set corner radius + heading scale.
- Ensure wide Mermaid diagram wrappers and `pre` are horizontally scrollable (`overflow-x: auto`) per the responsive NFR.
- Do NOT register the CSS in config here (task-003 wires `customCss`).

**Acceptance Criteria:**
- [ ] `casulo.css` defines casulo brand tokens once and maps them to `--sl-color-*` for both `[data-theme]` scopes.
- [ ] Dark mode uses `#d4a853`; light-mode text-weight accents use the AA-passing darkened gold (`#8a6418` or a verified equivalent).
- [ ] Inter is imported self-hosted (no Google Fonts `<link>`, no third-party request).
- [ ] Mermaid/diagram wrappers and `pre` blocks have `overflow-x: auto`.
- [ ] No new color tokens beyond the documented casulo palette are introduced.
- [ ] Configuration is idempotent; no plaintext secrets.
- [ ] All §6 quality gates pass.
