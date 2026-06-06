# task-011: Home splash + Get Started section pages

**Type:** IMPLEMENT

**Source:** feature-003-home-and-get-started → delivery-002

**Depends on:** task-010

**Scope:**
- Replace feature-001's `src/content/docs/index.mdx` hero stub with the full Home splash (D1): `hero` (tagline + Get Started/GitHub CTAs); body = value proposition, a `mermaid` pipeline-flow fence (reusing the methodology flowchart with hardcoded `classDef` colors dropped, A3), the install one-liner via `<InstallCommand channel="curl" />` + `<VersionBadge href="/releases/changelog/" />`, and a `<CardGrid>`/`<LinkCard>` section launcher.
- Replace `get-started/overview.md` placeholder (thin orientation, `.md`, `sidebar.label: Overview`, `order: 1`).
- Add `get-started/install.md` — channel chooser linking into `/guides/installation/` (no commands, `.md`, `order: 2`).
- Add `get-started/first-work.mdx` — net-new guided walkthrough using `<Steps>` (AC6, `order: 3`).
- Add `get-started/lite-path.mdx` — net-new lite quickstart using `<Steps>` (AC6, `order: 4`).
- Use correct relative import depths (`index.mdx` → `../../components/…`; `get-started/*` → `../../../components/…`). No `astro.config.mjs` edit (Get Started is autogenerate).

**Acceptance Criteria:**
- [ ] Home shows value prop, the pipeline Mermaid diagram, the `<InstallCommand>` one-liner + `<VersionBadge>`, and Get Started/GitHub CTAs (AC3-Home, AC13-partial).
- [ ] Get Started renders Overview → Install → Your first work → Lite path in order via autogenerate `sidebar.order` (AC3-nav, AC6).
- [ ] `first-work.mdx` and `lite-path.mdx` are net-new content (not migrated).
- [ ] Home install one-liner shows the build-time version (no hard-coded version anywhere in these pages).
- [ ] Home pipeline diagram renders as SVG (AC5).
- [ ] Build passes; all existing tests still pass.
- [ ] All §6 quality gates pass.
