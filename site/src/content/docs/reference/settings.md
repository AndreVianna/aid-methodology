---
title: Settings and manifest
description: Every key in .aid/settings.yml, what /aid-config changes, and what the install manifest .aid/.aid-manifest.json records.
sidebar:
  order: 2
---

Each AID project has two small files in its `.aid/` folder:

- `.aid/settings.yml` holds your project's settings. You and `/aid-config` edit it.
- `.aid/.aid-manifest.json` is the install record. The `aid` command writes it. Do not edit it.

## The settings file

`.aid/settings.yml` is plain YAML. AID skills read it each time they run. `aid add` creates it from a template if it is missing, and `aid projects add` creates it for a project with no tools.

```yaml
format_version: 5
name: my-project
description: A short description of the project
type: brownfield
source_control: git
minimum_grade: A
heartbeat_interval: 1

knowledge:
  source: main
```

### Keys you can change

| Key | Allowed values | Default |
|---|---|---|
| `name` | Any text without spaces. | The folder name, or `<project-name>` until you set it. |
| `description` | One line of text. No line breaks. | Empty, or `<project-description>` until you set it. |
| `type` | `brownfield` (an existing codebase) or `greenfield` (a new one). | `brownfield` |
| `source_control` | `none`, `git`, `svn` or `mercurial`. | `git` |
| `minimum_grade` | A letter `A` to `F`, with an optional `+` or `-`, such as `A`, `A+` or `B+`. | `A` |
| `heartbeat_interval` | A whole number of minutes. `0` turns heartbeats off. | `1` |

What each key does:

- **`name` and `description`** identify the project. The description lives only here, not in `CLAUDE.md` or `AGENTS.md`.
- **`type`** tells AID whether it is documenting code that exists or planning code that does not.
- **`source_control`** tells AID which version-control system the project uses.
- **`minimum_grade`** is the quality bar. Every skill that reviews its own output keeps going until the grade is at least this high. See [Review and grades](/guides/review-and-grades/). If the key is missing, each skill uses its own built-in default, which is `A`.
- **`heartbeat_interval`** is how often, in minutes, a long-running sub-agent reports that it is still working. With `0`, no heartbeats are written.

### Keys AID writes for you

| Key | What it holds |
|---|---|
| `format_version` | A number that says which layout `.aid/` uses. The current value is `5`. The `aid` command reads it to decide whether the project needs `aid update`. Do not edit it. |
| `knowledge.source` | The branch the Knowledge Base is compared against to decide whether it is out of date. Set it to your main branch. |
| `knowledge.last_update` | The date and time of the last Knowledge Base build. Written by `/aid-discover` and `/aid-housekeep`. |
| `knowledge.doc_set` | The list of Knowledge Base documents and which agent writes each one. Written by `/aid-discover`, and extended by `/aid-create` when it adds a document. |
| `knowledge.term_exclusions` | Words that `/aid-discover` should not treat as domain terms. |

`/aid-config` does not touch the `knowledge` block. If you run `/aid-config knowledge`, it answers `Unknown key`. That is expected. See the [Knowledge base guide](/guides/knowledge-base/).

### Optional keys

These are not in the template. They only take effect when you add them by hand.

| Key | What it does |
|---|---|
| `<skill>.minimum_grade` | Overrides `minimum_grade` for one skill. For example, a `discover:` section with `minimum_grade: A+` raises the bar for `/aid-discover` only. |
| `execution.max_parallel_tasks` | The most tasks `/aid-execute` runs at once. The default is `5`. |

Use a nested layout for both, with the section name on its own line and the key indented under it.

### Old key names

Older projects nested the keys under `project:`, `review:`, `traceability:` and `discovery:`. Skills still read those names, but only as aliases for the flat keys above. For example, `traceability.heartbeat_interval` is read as `heartbeat_interval`, and `discovery.doc_set` as `knowledge.doc_set`. Write the flat names in new files. `aid update` migrates an older file.

## Changing settings with /aid-config

`/aid-config` is the skill that views and edits the file. It has two modes.

| You type | What happens |
|---|---|
| `/aid-config` | Shows every user-editable key in a table. If `settings.yml` does not exist yet, it first copies the template into place. A value that is still a placeholder, such as `<project-name>`, is marked unset, and the skill prints the command to set it. |
| `/aid-config <key>` | Shows the current value, offers choices plus a free-text option, checks your answer against the table above, and saves it. It prints `key: old -> new`. |

The accepted keys are `name`, `description`, `type`, `source_control`, `minimum_grade` and `heartbeat_interval`. The skill changes only the line you asked about. It keeps every other line and comment. It stops if your tool is in plan mode, because it writes a file.

See the [`/aid-config` reference](/reference/skills/aid-config/) for the skill itself.

## The install manifest

`.aid/.aid-manifest.json` is a record of what `aid add` and `aid update` installed. `aid status`, `aid update` and `aid remove` all depend on it. If you delete it, `aid` treats the project as having nothing installed (exit 6). A project with no tools keeps a manifest with an empty `tools` object.

The manifest records:

| Field | What it holds |
|---|---|
| `format_version` | The version of the manifest layout. It is `3`. This is a different number from the one in `settings.yml`. |
| `aid_version` | The AID release installed in this project. |
| `installed_at` | When the manifest was first written. |
| `host.worktree_root` | The folder where AID creates git worktrees. The default is `.aid/.worktrees`. |
| `shared` | The files all tools share, each with a SHA-256 hash: the skills, the runtime scripts, the AID block in `AGENTS.md`, and the AID block in `CLAUDE.md`. Each entry lists which tools use it. |
| `tools.<name>` | For each installed tool: its version, when it was installed, the skill folders it mirrors, and its own agent files with hashes. |

The hashes are how `aid status` knows a file changed and how `aid remove` knows which files are yours. A shortened example:

```json
{
  "format_version": 3,
  "aid_version": "3.1.3",
  "installed_at": "2026-10-26T17:45:59Z",
  "host": { "worktree_root": ".aid/.worktrees" },
  "shared": {
    "skills":    { "root": ".agents/skills", "version": "3.1.3", "users": ["claude-code"], "files": [] },
    "runtime":   { "root": ".aid/runtime", "version": "3.1.3", "users": ["claude-code"], "files": [] },
    "agents_md": { "path": "AGENTS.md", "version": "3.1.3", "users": ["claude-code"] },
    "claude_md": { "path": "CLAUDE.md", "version": "3.1.3", "users": ["claude-code"] }
  },
  "tools": {
    "claude-code": { "version": "3.1.3", "installed_at": "2026-10-26T17:45:59Z", "files": [] }
  }
}
```

Each `files` list holds entries like `{ "path": "...", "sha256": "..." }`. They are empty here to keep the example short.

The `aid` command compares the two format numbers with the version it supports. If the project is older, it prints `Run: aid update`. If the project is newer than your CLI, it refuses to change anything and tells you to run `aid update self`.

For the command side, see [The aid command](/reference/cli/).
