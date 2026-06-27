---
spine-dimension: C2
owner: aid-researcher-analyst
---
# Content Map

## Conventions

To add a new content section to the site:
1. Register the section in `src/sections-registry.ts` with a unique section slug.
2. Create the section route in `src/routes/<section-slug>/index.ts`.
3. Map the section to its allowed content types in `content-map.json`.
4. Document the section and its allowed content types in this file.

## Contracts

| Section | Allowed content types | URL pattern |
|---------|-----------------------|-------------|
| /learn | Article, Tutorial | /learn/<content-type>/<slug> |
| /blog | Article | /blog/<slug> |
| /reference | Article | /reference/<slug> |

## Invariants

- Every content type must be mapped to at least one section before it can be published.
- Section slugs are stable; renaming a section requires a redirect rule in `nginx.conf`.
- The URL pattern is constructed from the section path + content type + content slug.
