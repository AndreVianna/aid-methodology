> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`SKILL.md`](SKILL.md) in this folder.

# aid-init — Phase 0: Setup

Initialize a project for the AID methodology. Bootstrapping step; not a development phase.

## What It Does

Conversational. Asks a small set of questions and scaffolds the AID workspace:

1. **Classify the project** — greenfield (new) or brownfield (existing code).
2. **Collect metadata** — project name, one-line description, external doc paths, minimum acceptable KB grade.
3. **Scaffold the Knowledge Base** — `.aid/knowledge/` with all 16 KB document templates pre-populated for the project type.
4. **Generate meta-documents** — `INDEX.md`, `README.md`, `DISCOVERY-STATE.md` with the project's metadata baked in.
5. **Set up the project context file** — `CLAUDE.md` (Claude Code) or `AGENTS.md` (Codex/Cursor) with AID placeholders.
6. **Update `.gitignore`** — based on whether the user wants `.aid/` versioned.

## When to Use

- Once at the start of a new project, before any other AID phase.
- Re-running is idempotent: keeps filled documents, resets only those still at `❌ Pending`.
- `--reset` is the nuclear option: deletes `.aid/` and re-initializes from scratch.

## Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| `.aid/knowledge/` | project root | All 16 KB documents + `INDEX.md` + `README.md` + `DISCOVERY-STATE.md` |
| `{project_context_file}` | project root | `CLAUDE.md` or `AGENTS.md` (per host tool) with AID placeholders for `aid-discover` to fill in |

## Next Step

| Project type | Next skill |
|---|---|
| Brownfield (existing code) | `/aid-discover` — analyze the codebase and fill in the KB |
| Greenfield (new project) | `/aid-interview` — gather requirements from scratch |
