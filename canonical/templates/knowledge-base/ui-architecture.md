---
kb-category: primary
source: hand-authored
intent: |
  Front-end / UI architecture: component model, state management, routing, design tokens. Read this for any UI-touching change.
contracts: []
changelog:
  - 2026-05-26: KB Authoring v2 template seed
---

# UI Architecture

> **Source:** aid-discover (Phase 1)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

---

## Framework & Rendering Model

| Property | Value |
|----------|-------|
| **UI Framework** | {e.g., React 18, Vue 3, Angular 17, Svelte 5, Blazor WASM} |
| **Rendering Strategy** | {e.g., SPA, SSR, SSG, hybrid — tool/framework} |
| **Language** | {e.g., TypeScript 5.x, JavaScript ES2022} |
| **Entry Point** | {e.g., src/main.tsx, src/index.ts} |

---

## Component Hierarchy

> Top-down view of the component tree. Focus on structural/layout components; leaf components can be grouped.

```
{AppRoot}
├── {LayoutShell}        — {e.g., nav, sidebar, header}
│   ├── {PageRouter}     — {e.g., React Router, Vue Router, Next.js App Router}
│   │   ├── {PageA}      — {e.g., Dashboard}
│   │   ├── {PageB}      — {e.g., Settings}
│   │   └── {PageC}      — {e.g., Detail view}
│   └── {SharedWidget}   — {e.g., notification tray}
└── {ModalLayer}         — {e.g., portal-mounted dialogs}
```

**Component count (approx.):** {n total — n pages, n shared/ui, n feature-specific}
**Component location:** {e.g., src/components/, src/features/*/components/}

---

## State Management

| Layer | Tool / Pattern | Scope | Location |
|-------|---------------|-------|----------|
| {Global app state} | {e.g., Redux Toolkit, Zustand, Pinia, NgRx} | {app-wide} | {path/to/store/} |
| {Server/async state} | {e.g., TanStack Query, SWR, Apollo Client} | {per-feature} | {path/to/hooks/} |
| {Local component state} | {e.g., useState, useReducer, ref()} | {component} | {inline} |
| {Form state} | {e.g., React Hook Form, Formik, VeeValidate} | {form} | {path/to/forms/} |
| {URL state} | {e.g., query params, router state} | {page} | {router config} |

**Key state slices / stores:**

| Store / Slice | Purpose | Persisted? |
|---------------|---------|-----------|
| {e.g., auth} | {current user, token, permissions} | {Yes — localStorage / No} |
| {e.g., ui} | {theme, sidebar open, active modal} | {No} |
| {e.g., featureX} | {domain data for feature X} | {No} |

---

## Design System & Styling

| Property | Value |
|----------|-------|
| **Design System** | {e.g., custom, Material UI, Ant Design, Shadcn/ui, Fluent UI, Chakra UI — or "none"} |
| **Styling Approach** | {e.g., CSS Modules, Tailwind CSS, styled-components, Emotion, plain CSS, SCSS} |
| **Theme / Tokens** | {e.g., CSS custom properties in tokens.css, theme.ts, design-tokens.json} |
| **Icon Library** | {e.g., Lucide React, Heroicons, Material Icons, custom SVGs} |
| **Dark Mode** | {Yes — CSS class toggle / media query / No} |

**Global style files:** {e.g., src/styles/global.css, src/theme/index.ts}

---

## Routing & Navigation

| Property | Value |
|----------|-------|
| **Router** | {e.g., React Router v6, Vue Router v4, Next.js App Router, Angular Router} |
| **Route Config Location** | {e.g., src/router/index.ts, app/layout.tsx} |
| **Auth Guard** | {e.g., PrivateRoute wrapper, route meta + navigation guard, middleware.ts} |
| **Lazy Loading** | {Yes — React.lazy / import() / No} |

**Top-level routes:**

| Path | Component / Page | Auth Required |
|------|-----------------|--------------|
| {/} | {e.g., HomePage} | {No} |
| {/dashboard} | {e.g., DashboardPage} | {Yes} |
| {/settings/*} | {e.g., SettingsLayout} | {Yes} |
| {/login} | {e.g., LoginPage} | {No} |

---

## Accessibility

| Property | Value |
|----------|-------|
| **WCAG Target** | {e.g., AA, AAA, not defined} |
| **Screen Reader Testing** | {e.g., NVDA, VoiceOver, not tested} |
| **Focus Management** | {e.g., focus-visible enforced, custom skip-nav, not addressed} |
| **ARIA Usage** | {e.g., landmarks + live regions on dynamic content / minimal / none} |
| **Color Contrast** | {e.g., verified via tooling / not verified} |
| **Keyboard Navigation** | {e.g., full keyboard support / partial / not tested} |

**Known accessibility gaps:**

| Area | Gap | Risk |
|------|-----|------|
| {e.g., modals} | {e.g., focus not trapped on open} | {High / Medium / Low} |

---

## Build & Assets

| Property | Value |
|----------|-------|
| **Bundler** | {e.g., Vite, Webpack 5, Turbopack, esbuild, Rollup} |
| **Build Output** | {e.g., dist/, .next/, build/} |
| **Code Splitting** | {e.g., route-level, manual chunks, none} |
| **Image Optimization** | {e.g., next/image, vite-plugin-imagemin, manual} |
| **Environment Config** | {e.g., .env.* files, VITE_/NEXT_PUBLIC_ prefix convention} |

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial UI architecture analysis |
