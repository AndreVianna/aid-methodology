---
spine-dimension: C3
owner: aid-researcher-analyst
---
# Authoring Conventions

## Conventions

- **Slug naming:** all slugs are lowercase, hyphen-separated, no underscores or special characters.
  Pattern: `^[a-z0-9]+(?:-[a-z0-9]+)*$`. Example: `getting-started-with-cms` (correct);
  `Getting_Started` (wrong -- uppercase and underscore).
- **Title casing:** sentence case (capitalize first word and proper nouns only).
  Example: `Getting started with the CMS` (correct); `Getting Started With The CMS` (wrong).
- **Body format:** all body content is authored in Markdown (GitHub-flavored).
  Code blocks must specify a language fence (` ```bash `, ` ```json `).
- **Tagging:** tags are lowercase, hyphen-separated, singular nouns.
  Example: `tutorial`, `api-reference` (correct); `Tutorials`, `API References` (wrong).
- **Publishing workflow:** new content enters `draft`, must pass `review`, then is set to
  `published` by an authorized reviewer. Skipping states is prohibited.
- **Field ordering in JSON:** required fields before optional fields, alphabetical within each group.

## Invariants

- All slugs must pass the pattern validator before submission to review.
- Content in `published` state must not be edited in place; create a new revision.
- Author field must reference a known author slug from the author registry.
