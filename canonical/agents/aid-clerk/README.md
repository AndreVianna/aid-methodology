> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# aid-clerk

**Internal Utility — dispatched by large-tier agents, not directly by skills**

The Clerk performs one mechanical, schema-bounded operation per dispatch: file extraction, template placeholder-fill, or glob enumeration. It offloads deterministic mechanical work from reasoning agents so those agents can focus on analysis.

## What It Does

The Clerk is a parameterized utility. The caller specifies an `operation` (extract, format, or glob) and the Clerk executes exactly that operation:

- **extract** — reads files and extracts items matching a caller-specified schema, returning a markdown table with path + line evidence
- **format** — reads a template and substitutes caller-provided placeholder values, returning populated markdown
- **glob** — expands a glob pattern, collects path/size/mtime, applies caller-specified filters, returns a sorted markdown table

The Clerk consolidates three former small-tier utility agents (one per mechanical operation type: extraction, template-fill, and glob enumeration). All three shared the same two dispatch sites (aid-discover GENERATE and aid-execute) and the same narrow pattern — mechanical, schema-bounded, deterministic output. The operation type is a dispatch parameter, not a reason for separate agents.

## When It's Invoked

| Caller | Operation | Use case |
|--------|-----------|----------|
| aid-discover GENERATE agents | extract / glob | Pre-extract file inventories, structured item lists before KB doc authoring |
| aid-execute agents | extract / format / glob | Extract structured items, fill report templates, enumerate files during task execution |

Never invoked directly by a skill. Always delegated by a large-tier agent that needs mechanical work done.

## What It Produces

- **extract**: markdown table or list with path + line number for every extracted item
- **format**: populated markdown file matching the template's structure
- **glob**: sorted markdown table with path, size, and mtime for every matched file

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **aid-researcher** | Researcher *analyzes and interprets* code. Clerk *mechanically extracts* from it. |
| **aid-tech-writer** | Tech Writer authors docs with judgment. Clerk fills templates without interpretation. |

## Tools

- **Read, Glob, Grep** — reading source files and templates
- **Write, Edit** — producing the output file (format operation)
- **Bash** — read-only file enumeration and metadata (`find`, `wc`, `stat`)

## Tier

**Small tier** — purely mechanical: no reasoning, no interpretation, no judgment. The Clerk's value is speed, reliability, and schema fidelity.

## Examples

- *"Extract all exported function names from `src/api/*.ts`."* → Clerk returns markdown table with function names, file paths, line numbers
- *"Fill the task-template.md template with: title=Add auth middleware, type=IMPLEMENT, ..."* → Clerk returns populated markdown
- *"Glob `canonical/agents/**/*.md`, filter by mtime > 2026-05-01."* → Clerk returns sorted table of matching files

## Key Behaviors

- **Schema-bound.** Matches the requested schema exactly. No bonus fields, no commentary.
- **Cite everything.** Every row carries path + line number.
- **Empty result > fabrication.** "0 matches in 47 files searched" is the correct answer when nothing matches.
- **One operation per dispatch.** Never attempts to chain or combine operations in a single call.

## Caller Contract

The caller must specify:
- `operation`: `extract` | `format` | `glob`
- For extract: target files/glob, schema description, item type to match
- For format: template path or name, placeholder-to-value mapping
- For glob: glob pattern, optional filters (mtime, size, extension)
