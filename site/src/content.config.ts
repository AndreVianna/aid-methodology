import { defineCollection } from 'astro:content';
import { z } from 'zod';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: docsLoader(),
    schema: docsSchema({
      extend: z.object({
        // Project-specific optional frontmatter (consumed by later features):
        // feature-005: provenance link, e.g. "docs/install.md"
        sourceDoc: z.string().optional(),
        // feature-006: generated reference pages provenance
        generatedFrom: z.string().optional(),
        // feature-006: toggle per-page "Report an issue" link
        reportIssue: z.boolean().default(true),
      }),
    }),
  }),
};
