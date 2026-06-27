---
spine-dimension: D
owner: aid-researcher-analyst
---
# Decisions

## Use JSON for content-type schema definitions

**Decision:** Content type schemas are defined in `content-types.json` (not in code).
**Rationale:** A JSON schema is readable by non-developers (content editors, QA) and
can be validated at build time without running the application. It also allows tooling
(validators, form generators) to consume the schema without coupling to application code.
**Rejected alternative:** TypeScript-only schema (Zod/Yup) -- rejected because non-dev
stakeholders cannot read or validate TypeScript source directly.

## Immutable slugs after publication

**Decision:** Slugs cannot be changed after a content item reaches `published` state.
**Rationale:** Slugs form the canonical URL; changing them breaks inbound links, SEO
rankings, and cross-references from other content items.
**Rejected alternative:** Redirect-on-change -- rejected because it adds infrastructure
complexity and does not help cross-references within the CMS itself.
