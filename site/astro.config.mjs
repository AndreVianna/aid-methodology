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
// components: map is EMPTY here — this config OWNS it.
//   Reserved slots (later deliveries add ONE key each; do not rewrite the map):
//     Banner:     feature-009 (announcement banner)
//     Footer:     feature-010 (feedback/casuloailabs.com back-link)
//     Hero:       feature-008 (version badge on home hero)

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
      theme: 'dark',
      themeVariables: {
        // casulo dark palette applied to Mermaid diagrams
        background: '#0a0e1a',
        mainBkg: '#1a2035',
        nodeBorder: '#d4a853',
        clusterBkg: '#111827',
        titleColor: '#f1f5f9',
        edgeLabelBackground: '#1a2035',
        primaryColor: '#1a2035',
        primaryTextColor: '#f1f5f9',
        primaryBorderColor: '#d4a853',
        lineColor: '#94a3b8',
        secondaryColor: '#111827',
        tertiaryColor: '#212b45',
      },
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
            { label: 'Feedback',          slug: 'concepts/feedback' },
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
        {
          label: 'Releases',
          items: [
            // link: (not slug:) because this is a src/pages route, not a docs page
            { label: 'Changelog', link: '/releases/changelog' },
          ],
        },
      ],

      // Component override map — OWNED HERE, intentionally empty.
      // Later deliveries add ONE key each (do not rewrite this map, only add):
      //   Banner:  feature-009 (announcement banner, delivery-003)
      //   Footer:  feature-010 (feedback + casuloailabs.com back-link, delivery-003)
      //   Hero:    feature-008 (version badge on splash hero, delivery-002)
      components: {
        // prototype-01 shell: two-row header (brand + section tabs) and
        // breadcrumb/eyebrow/title. See src/components/overrides/.
        Header: './src/components/overrides/Header.astro',
        PageTitle: './src/components/overrides/PageTitle.astro',
        // Reserved slots — feature-009 (Banner) + feature-010 (Footer):
        Banner: './src/components/Banner.astro',
        Footer: './src/components/Footer.astro',
        // Hero:   './src/components/Hero.astro',  (feature-008, delivery-002)
      },

      // Pagefind (built-in) powers the search box; no extra config needed.
      // It builds a static index at astro build time — no external SaaS request (AC8).
    }),

    // @astrojs/sitemap emits sitemap-index.xml + sitemap-0.xml into dist/
    sitemap(),
  ],
});
