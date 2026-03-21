# AID for Cursor

Use the `setup.sh` (or `setup.ps1` on Windows) script at the repo root to install AID into your project, or copy manually:

## Setup

```bash
# Automated (recommended)
path/to/aid-methodology/setup.sh /path/to/your/project

# Manual
cp -r path/to/aid-methodology/cursor/.cursor  .cursor/
cp path/to/aid-methodology/cursor/AGENTS.md   AGENTS.md
```

This gives you:
- `.cursor/rules/aid-methodology.mdc` — Always-on rule: KB integration and phase workflow
- `.cursor/rules/aid-review.mdc` — Code review standards (applied to source files)
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Rules

### `aid-methodology.mdc` (always applied)

Tells Cursor to:
- Read `knowledge/INDEX.md` before making changes
- Treat the Knowledge Base as the single source of truth
- Follow AID phases and produce artifacts at each gate

### `aid-review.mdc` (applied to source files)

When Cursor reviews code it will:
- Check against task acceptance criteria
- Verify against `knowledge/coding-standards.md` and `knowledge/architecture.md`
- Grade A+ to F and tag issues by category

## Usage

1. Run `setup.sh` to install into your project.
2. Edit `AGENTS.md` with your project description, build commands, and conventions.
3. Run the Discovery phase (use the AID methodology docs as reference) to generate `knowledge/INDEX.md`.
4. Cursor will automatically apply the rules on every edit.

## Notes

- Cursor uses `.mdc` files in `.cursor/rules/` — these are Markdown with YAML frontmatter
- `alwaysApply: true` rules are injected into every conversation
- `globs:` rules are injected when matching files are open
- Human-readable phase documentation lives in the repo's `skills/` directory
- Templates for all artifacts live in `templates/`
