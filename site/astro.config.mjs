// astro.config.mjs — AID docs site configuration
//
// Integration order matters: astro-mermaid MUST precede starlight() so it
// transforms fenced ```mermaid blocks before Starlight processes the content.
//
// Sidebar contract (D8 / reconciled across all features):
//   - Get Started / Concepts / Reference: autogenerate (siblings add pages via
//     sidebar.order + sidebar.label in each page's frontmatter).
//   - Guides: explicit slug items (small curated set; labels controlled here).
//   - Releases: link: to src/pages/releases/changelog.astro (not a docs page).
//
// components: map is OWNED HERE. It already holds four keys (Header, PageTitle,
// Banner, Footer) — do not rewrite the map, only add. No slot is reserved for a
// feature of this work.

import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import sitemap from '@astrojs/sitemap';
import mermaid from 'astro-mermaid';

export default defineConfig({
  // feature-002 owns these — set here per task-005
  site: 'https://aid.casuloailabs.com',
  base: '/',

  integrations: [
    // astro-mermaid BEFORE starlight (transforms ```mermaid fences)
    mermaid({
      // Fallback only. `autoTheme` (on by default) re-initializes mermaid on every
      // `data-theme` change, mapping light -> 'default' and dark -> 'dark', so this
      // value is used only before a theme is resolved.
      theme: 'dark',

      // A previous version of this block set `themeVariables` HERE, one level too high.
      // The integration builds its config as `{ theme, ...mermaidConfig }` and reads
      // nothing else, so those thirteen colours were silently dropped and every diagram
      // on the site has always rendered with mermaid's stock palette. They are not
      // reinstated under `mermaidConfig`: a fixed palette would override BOTH of the
      // themes `autoTheme` switches between, so the dark colours would be pinned into
      // light mode. Per-theme colour belongs in CSS, where `[data-theme]` can select —
      // see the mermaid block in src/styles/casulo.css.
      mermaidConfig: {
        // Layout, which is theme-independent and therefore safe to fix here.
        //
        // This lived in a per-diagram YAML `config:` block emitted by
        // render-mermaid.mjs. That had a side effect worth recording: a per-diagram
        // `config:` makes mermaid re-init for that diagram, which discarded the site
        // config entirely. Node fills survived because our charts set them through
        // explicit `classDef` statements, so the loss showed up only in edge strokes and
        // edge-label backgrounds — visible as near-invisible lines in dark mode.
        // Declaring it once here keeps a single authority and lets `autoTheme` work.
        layout: 'elk',
        flowchart: {
          // Mermaid's defaults are tuned for small hand-drawn diagrams. These charts are
          // derived, so nodes carry two lines of real text and grow well past the
          // spacing dagre assumes — shapes nearly touched and edges took long detours.
          nodeSpacing: 55,
          rankSpacing: 65,
          padding: 12,
          useMaxWidth: true,
        },
      },

      // KI-012: astro-mermaid defaults enableLog to true, which logs
      // "[astro-mermaid] ..." to every visitor's console on every page.
      enableLog: false,
    }),

    starlight({
      title: 'AID — AI Integrated Development',

      // Persistent social links in header/footer chrome (AC3)
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/AndreVianna/aid-methodology',
        },
        {
          icon: 'external',
          label: 'Casulo AI Labs',
          href: 'https://casuloailabs.com',
        },
      ],

      // Self-hosted Inter + casulo brand token overrides (task-002)
      customCss: [
        './src/styles/casulo.css',
        './src/styles/shell.css',
      ],

      favicon: '/favicon.svg',

      tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 },

      defaultLocale: 'en',

      // Reconciled sidebar contract (D8) — DO NOT restructure; siblings add pages.
      // Note: Starlight v0.39.0+ requires autogenerate groups to be nested inside
      // an items array (the combined label+autogenerate form was removed).
      sidebar: [
        // Root doc page — Overview is the top item of the sidebar (points to /)
        { label: 'Overview', slug: '' },
        {
          label: 'Get Started',
          items: [{ autogenerate: { directory: 'get-started' } }],
        },
        {
          label: 'Guides',
          items: [
            { label: 'Installation', slug: 'guides/installation' },
            { label: 'Working the pipeline', slug: 'guides/pipeline' },
            { label: 'Web dashboard', slug: 'guides/dashboard' },
            { label: 'Maintainer', slug: 'guides/maintainer' },
          ],
        },
        // feature-006 owns the Concepts + Reference groups (explicit item order per SPEC D1)
        // feature-010 adds feedback.md last in the Concepts group (sidebar.order: 99)
        {
          label: 'Concepts',
          items: [
            { label: 'Overview',          slug: 'concepts/overview' },
            { label: 'The methodology',   slug: 'concepts/methodology' },
            { label: 'FAQ',               slug: 'concepts/faq' },
          ],
        },
        {
          label: 'Reference',
          items: [
            { label: 'Overview',              slug: 'reference/overview' },
            { label: 'CLI & subcommands',     slug: 'reference/cli' },
            { label: 'Skills',                slug: 'reference/skills' },
            { label: 'Agents',                slug: 'reference/agents' },
            { label: 'Knowledge Base',        slug: 'reference/kb' },
            { label: 'Settings keys',         slug: 'reference/settings' },
            { label: 'Artifacts',             slug: 'reference/artifacts' },
            { label: 'Repository structure',  slug: 'reference/repository-structure' },
            { label: 'Glossary',              slug: 'reference/glossary' },
          ],
        },
        // feature-002 owns the Skills group (task-016): explicit index item first
        // (Header.astro derives the tab's href from items[0]), then an autogenerated
        // collapsed subgroup so the tab highlights on any of the 111 detail pages.
        {
          label: 'Skills',
          items: [
            { label: 'All skills', slug: 'skills' },
            {
              label: 'Every skill',
              collapsed: true,
              items: [{ autogenerate: { directory: 'skills' } }],
            },
          ],
        },
        {
          label: 'Releases',
          items: [
            // link: (not slug:) because this is a src/pages route, not a docs page
            { label: 'Changelog', link: '/releases/changelog' },
          ],
        },
        {
          label: 'Contact Us',
          items: [
            { label: 'Site Issue',          slug: 'contact/site-issue' },
            { label: 'Methodology Bug',     slug: 'contact/methodology-bug' },
            { label: 'Question or Feedback', slug: 'contact/feedback' },
            { label: 'Contact Request',     slug: 'contact/contact-request' },
          ],
        },
      ],

      // Component override map — OWNED HERE. Already holds four keys below;
      // do not rewrite this map, only add. No slot is reserved for a feature
      // of this work.
      components: {
        // prototype-01 shell: two-row header (brand + section tabs) and
        // breadcrumb/eyebrow/title. See src/components/overrides/.
        Header: './src/components/overrides/Header.astro',
        PageTitle: './src/components/overrides/PageTitle.astro',
        Banner: './src/components/Banner.astro',
        Footer: './src/components/Footer.astro',
      },

      // Pagefind (built-in) powers the search box; no extra config needed.
      // It builds a static index at astro build time — no external SaaS request (AC8).
    }),

    // @astrojs/sitemap emits sitemap-index.xml + sitemap-0.xml into dist/
    sitemap(),
  ],
});
