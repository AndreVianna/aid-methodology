import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import sitemap from '@astrojs/sitemap';
import skills from './src/data/skills.json' with { type: 'json' };
import { GROUPS } from './src/data/groups.mjs';

const REPO = 'https://github.com/AndreVianna/aid-methodology';

// One collapsed sidebar group per skill group; the pages themselves are written by
// scripts/generate.mjs, which runs before every build.
const skillGroups = GROUPS.map((g) => ({
  label: g.title,
  collapsed: true,
  items: Object.entries(skills)
    .filter(([, s]) => s.group === g.id)
    .sort(([, a], [, b]) => a.order - b.order)
    .map(([name]) => ({ label: name, slug: `reference/skills/${name}` })),
})).filter((g) => g.items.length);

export default defineConfig({
  site: 'https://aid.casuloailabs.com',
  integrations: [
    starlight({
      title: 'AID',
      description: 'AID (AI Integrated Development): a way to build software with AI coding agents, with you approving every step.',
      logo: { src: './src/logo.svg', alt: '' },
      favicon: '/favicon.svg',
      social: [{ icon: 'github', label: 'AID on GitHub', href: REPO }],
      editLink: { baseUrl: `${REPO}/edit/master/site/` },
      customCss: ['./src/styles/custom.css'],
      components: { Footer: './src/components/Footer.astro' },
      tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 },
      sidebar: [
        {
          label: 'Get started',
          items: ['get-started/what-is-aid', 'get-started/install', 'get-started/first-change', 'get-started/first-project'],
        },
        {
          label: 'Guides',
          items: [
            'guides/choose-your-entry',
            'guides/knowledge-base',
            'guides/review-and-grades',
            'guides/connectors-and-tickets',
            'guides/dashboard',
            'guides/agent-chat',
          ],
        },
        {
          label: 'Concepts',
          items: ['concepts/how-it-works', 'concepts/methodology', 'concepts/faq'],
        },
        {
          label: 'Reference',
          items: [
            'reference/cli',
            'reference/settings',
            'reference/work-files',
            'reference/kb-documents',
            { label: 'Skills', collapsed: true, items: [{ label: 'All skills', slug: 'reference/skills' }, ...skillGroups] },
            'reference/agents',
            'reference/repository-structure',
            'reference/glossary',
          ],
        },
        { label: 'Project', items: ['releases', 'contact'] },
      ],
    }),
    sitemap(),
  ],
});
