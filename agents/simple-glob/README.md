# Simple Glob

**Utility Agent — invoked by other agents, not at the skill layer**

The Simple Glob enumerates files matching one or more patterns and returns a structured markdown table with path, size, and modification time. It is the dedicated file-discovery sub-agent for any agent that needs a sorted, filterable inventory before deciding where to read.

## What It Does

Given pattern(s) and optional filters, the Simple Glob:

- Expands glob patterns against the project root
- Collects file metadata (path, size in lines or bytes, last-modified time)
- Applies filters (size threshold, date range, sub-directory restrictions)
- Returns a sorted markdown table

It is invoked by other agents (Researcher, discovery-*, Operator) when those agents need an authoritative file list to drive subsequent decisions.

## What It Doesn't Do

- Read file contents (that's Simple Extractor)
- Interpret what the files contain
- Decide which files matter (the caller filters by reading the table)
- Modify or delete files

## Inputs

- **Patterns** — one or more glob patterns (e.g., `**/*.tsx`, `src/services/**/*.py`)
- **Optional: exclude patterns** — globs to subtract from the result
- **Optional: filters** — `min_size`, `max_size`, `modified_after`, `modified_before`
- **Optional: sort key** — `path` (default), `size`, or `mtime`

## Output

Markdown table:

```markdown
| Path | Lines | Modified |
|------|-------|----------|
| src/api/UserController.java | 247 | 2026-04-14 |
| src/api/AuthController.java | 189 | 2026-04-12 |
| src/api/HealthController.java | 42 | 2026-03-28 |
```

(Lines or bytes is caller-configurable; mtime in ISO date.)

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **simple-extractor** | Extractor reads file *contents*. Glob lists files without reading them. |
| **Researcher** | Researcher synthesizes findings. Glob only enumerates. |

## Tools

- **Glob** — primary
- **Bash** — read-only commands: `find`, `wc -l`, `stat`, `du`

No Read, no Grep — Glob never opens file contents.

## Tier

**Small tier** — file enumeration with metadata is mechanical. The model exists only to interpret the request, dispatch the right glob/find command, and shape the output table. Larger models add no value.

## Caller Contract

The calling agent **must**:

1. Provide concrete patterns. "Find code files" is too vague; "Find `**/*.java` and `**/*.kt`" is correct.
2. Specify the sort order if it matters for downstream logic.
3. Validate the output — at minimum, sanity-check the count against expectations.

The Glob **will**:

1. Refuse vague patterns. Returns an empty table with a note rather than guessing.
2. Always include path, even when caller asked only for size or mtime.
3. Cap results at a reasonable limit (default 200 rows) and note truncation.

## Examples

- *"List all `**/*.tsx` and `**/*.ts` files in `src/components/`, sorted by lines, top 50"* → markdown table
- *"Find Python files modified in the last 30 days"* → table with mtime sorted descending
- *"Enumerate all `Dockerfile` and `*.dockerfile` files anywhere in the repo"* → small table, no truncation

## Constraints

- Patterns are glob, not regex.
- Paths are relative to project root.
- Mtime is ISO format (YYYY-MM-DD or full ISO 8601 if hour-precision matters).
- Sort is stable and deterministic — same inputs produce same output.
