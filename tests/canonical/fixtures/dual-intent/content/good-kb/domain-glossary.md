---
spine-dimension: C4
owner: aid-researcher-analyst
---
# Domain Glossary

## Article

A long-form written content item managed by the CMS. Has required fields: title,
slug, body, publishedAt. Can be published in the /blog or /learn sections.

## Tutorial

A step-by-step instructional content item with a difficulty rating (beginner,
intermediate, or advanced). Supports prerequisite chaining via Tutorial slugs.

## Slug

A URL-safe, human-readable identifier for a content item. Pattern:
`^[a-z0-9]+(?:-[a-z0-9]+)*$`. Slugs are immutable after first publication.

## Publishing state

The lifecycle state of a content item. Valid states in order: draft, review,
published, archived. State transitions are enforced; states cannot be skipped.

## Content type

A named category of content (Article, Tutorial) with its own field schema,
validators, and section mappings.

## Invariants

- All terms correspond to concepts enforced in the content-types.json schema and validators.
- No abbreviations used as primary term entries.
