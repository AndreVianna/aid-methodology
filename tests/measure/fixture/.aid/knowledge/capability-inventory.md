---
kb-category: primary
source: hand-authored
objective: The capabilities the notes tool offers today.
summary: Lists each command, what it does, and what it stores, as the code currently implements them.
sources:
  - src/notes/commands.py
  - src/notes/store.py
tags: [capability, commands, storage]
---

# Capability Inventory

## Commands

| Command | Effect | Stores |
|---|---|---|
| `add <text>` | Appends a note with the next id and a UTC timestamp. | `notes.json` in the current folder. |
| `pin <id>` | Marks the note as pinned. | `"pinned": true` on that note in `notes.json`. |
| `list` | Prints every note once as id, timestamp and text: pinned notes first, then the others, each group in insertion order. | Nothing; read only. |

## Not offered

- No edit, delete or search command.
- No remote sync and no network access.
