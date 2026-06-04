---
name: add-cli-command
applies-to: new-feature
slot-count: 5
task-count: 2
summary: Add a new CLI subcommand with args and help text.
---

## spec

# Add CLI command: {{command-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-cli-command` via /aid-interview lite path
**Status:** Active

## Goal

Add a new CLI subcommand `{{command-name}}` with the defined argument signature,
help text, and output behavior.

## Context

Command signature: {{command-signature}}

Help text / description: {{help-text}}

Output behavior: {{output-behavior}}

Parent command / placement: {{parent-command}}

## Acceptance Criteria

- [ ] `{{command-name}}` is registered and appears in the parent command's help output.
- [ ] All arguments defined in the command signature are accepted and validated.
- [ ] Help text (`--help`) matches the definition above.
- [ ] Output behavior matches the specification.
- [ ] Unit tests cover argument parsing and core command logic.
- [ ] No regression in existing CLI commands.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Register and wire {{command-name}} subcommand |
| task-002 | TEST | Unit tests for {{command-name}} |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| (auto-filled) | Created from recipe `add-cli-command` | /aid-interview lite path |

## tasks

### task-001 — Register and wire {{command-name}} subcommand

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Register the `{{command-name}}` subcommand under `{{parent-command}}`.
  Implement the argument signature ({{command-signature}}), help text
  ({{help-text}}), and the command handler producing the defined output behavior
  ({{output-behavior}}).
- Acceptance Criteria:
  - [ ] `{{command-name}}` is registered and appears in `{{parent-command}} --help`.
  - [ ] All defined arguments are accepted and invalid inputs produce a helpful error.
  - [ ] Help text matches the definition.
  - [ ] Output behavior matches the specification.

### task-002 — Unit tests for {{command-name}}

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Write unit tests for `{{command-name}}` covering argument parsing, help
  output, and the main execution path including at least one error path.
- Acceptance Criteria:
  - [ ] Valid arguments produce the expected output.
  - [ ] Invalid or missing arguments produce a clear error.
  - [ ] No regression in existing CLI command tests.
