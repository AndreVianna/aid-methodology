# KB Authoring — Frontmatter Schema

> YAML frontmatter specification for `.aid/knowledge/*.md` documents.
> Loaded by `aid-discover` (review classification — the `aid-reviewer`
> sub-agent validates compliance semantically), `aid-config` (scaffolding), and
> `aid-summarize` (section intent extraction).

Every KB document MUST begin with a YAML frontmatter block delimited by `---` markers.
Per [principles.md](principles.md) P6, **the entire frontmatter block is exempt from review** — it
classifies the doc and provides informational metadata, but its content does not
affect the grade.

## Canonical schema

```yaml
---
kb-category: primary
source: hand-authored
intent: |
  One paragraph (1-4 sentences) describing what this doc is FOR.
  Drives the reviewer's relevance judgment + the agent's task-routing decision.
contracts:
  - "Optional list of structural cardinality claims the doc asserts."
  - "Each entry is spot-checked against disk by the aid-reviewer in REVIEW state."
changelog:
  - 2026-05-26: Migrated to v2 format (KB Authoring overhaul)
---
```

For generated docs:

```yaml
---
kb-category: primary       # or meta, depending on the doc's role
source: generated
generator: build-kb-index.sh
intent: |
  ...
contracts: []
changelog:
  - 2026-05-26: Generated for the first time
---
```

## Field reference

### `kb-category:` (required)

Per-document classification. Determines which review rubric applies.

| Value | Meaning |
|-------|---------|
| `primary` | Load-bearing knowledge doc (architecture, schemas, coding-standards, etc., AND `INDEX.md` — see `source:` for its generation status). Full review against T1+T2 facts; T3/T4 markers banned inline. |
| `meta` | Process / state ledger (`STATE.md`, `README.md`). Exempt from full review per P7-style reasoning. Spot-check current snapshot correctness only. |
| `extension` | Project-type-specific addition outside the canonical 14 (e.g., `host-tools-matrix.md`). Reviewed but flagged as extension-scope. |

See [review-rubric.md](review-rubric.md) for per-category rubric details.

**INDEX.md is `primary` + `source: generated`** — it carries load-bearing RAG-navigation knowledge (agents depend on it) but the file is produced by `build-kb-index.sh` from each KB doc's `intent:` field. The combination routes to the "Full Primary + Build-Verify" rubric (see [review-rubric.md](review-rubric.md)) — both content correctness AND generator freshness are checked.

### `source:` (required)

Production mode.

| Value | Meaning |
|-------|---------|
| `hand-authored` | Written by humans (or AI agents acting as humans during /aid-discover GENERATE state). Full content review applies. |
| `generated` | Produced by a registered build script. The script controls content. Reviewer verifies the file was regenerated (existence + freshness) but does not grade content. **`generator:` field MUST be set.** |

### `generator:` (required iff `source: generated`)

Name of the build script (relative to `.github/scripts/` or as a
project-relative path). Listed in `.github/templates/generated-files.txt` registry.

Examples: `build-kb-index.sh`, `build-metrics.sh`, `build-project-index.sh`.

### `intent:` (required)

One paragraph (1-4 sentences) declaring what the doc is FOR. This field drives:

- The reviewer's **relevance judgment** — "does this doc contain things that match its
  intent, or has scope crept?"
- The **agent's task-routing** — `INDEX.md` (or its generator) uses `intent:` to compose
  the per-doc one-liner an agent reads when deciding which KB doc to load.
- The `aid-summarize` skill's **section descriptions** when rendering
  `kb.html`.

**Write for an agent reading 21 of these in sequence.** Be precise about scope.
Don't editorialize ("this is the most important doc"); state what's covered.

**Good:**
```yaml
intent: |
  Describes the architectural patterns of AID: phase-skill mapping, agent-tier model,
  Knowledge-Base centrality, feedback loops, and the canonical-generator workflow.
  Read this to understand HOW the methodology hangs together, not WHAT each phase does.
```

**Bad:**
```yaml
intent: |
  Architecture stuff.
```

### `contracts:` (optional, list)

Structural cardinality claims the doc asserts that downstream tooling depends on
(T2 Structure tier per [tier-model.md](tier-model.md)). Each entry is a human-readable assertion
PLUS a machine-checkable predicate.

Format: list of strings, each either:
- A plain assertion (lint will warn if no checker is registered for it), OR
- A tagged assertion the reviewer can spot-check: `"count:.aid/knowledge/*.md = 21"` —
  the reviewer reads each tagged assertion and confirms against disk during REVIEW.

**Examples:**
```yaml
contracts:
  - "Lists 16 standard KB documents"
  - "Asserts the 8-task-type catalog (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE)"
  - "Names the 4 lite-path sub-paths"
```

Pure-textual contracts (like the above) are read by the reviewer; the lint can extract
the named counts and verify against disk where the format permits.

**When in doubt, omit.** Empty list `contracts: []` is valid. A missing field is
treated as empty.

### `changelog:` (optional, list)

Per-doc historical entries. Free-form list of dated notes.

```yaml
changelog:
  - 2026-05-26: Migrated to v2 format (KB Authoring overhaul)
  - 2026-06-15: Added §X for new feature Y
```

**Exempt from review.** This is informational for human readers who don't want to
run `git log`. Drift here doesn't affect grade.

Convention: prepend new entries to the top (most recent first). Use ISO date format
(`YYYY-MM-DD`). One line per entry.

**For the migration entry specifically:** every doc gets a single seed entry at
Phase C migration time: `- YYYY-MM-DD: Migrated to v2 format (KB Authoring overhaul)`.
Future contributors append as they make substantive edits.

## Rendering compatibility

YAML frontmatter between `---` markers is the standard convention used by:
- GitHub Markdown (renders as a table at the top of the file)
- Jekyll / Hugo / mdBook
- VS Code Markdown preview
- All major static site generators

Most renderers display the frontmatter; some hide it. Either is acceptable. The
`kb.html` viewer (rendered by `aid-summarize`) explicitly extracts
`intent:` for section descriptions and skips the rest.

## Parsing rules (for tools)

- Block MUST be the first content in the file (no whitespace, no BOM, no comments before)
- Opening `---` on its own line; closing `---` on its own line
- Body MUST be valid YAML 1.2
- Missing fields are treated as default-empty
- Unknown fields are tolerated (forward-compatible with future schema additions)
- If parsing fails, the doc is treated as `kb-category: primary, source: hand-authored`
  with empty intent/contracts/changelog AND lint emits a HIGH-severity warning

## Project-specific overrides

A project may define `.aid/knowledge/.review-checklist.md` (gitignored by default)
to add project-specific lint rules beyond the canonical defaults. See
[review-rubric.md](review-rubric.md) for the format.

## See also

- [principles.md](principles.md) — P6 (frontmatter exempt from review) and P5 (mark generated files)
- [tier-model.md](tier-model.md) — T2 structural facts go in `contracts:`
- [review-rubric.md](review-rubric.md) — how the reviewer uses kb-category + source to pick a rubric
