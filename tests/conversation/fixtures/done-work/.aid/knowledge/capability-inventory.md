---
kb-category: primary
source: hand-authored
objective: The capabilities the notes tool offers today.
summary: Lists each command, what it does, and what it stores, as the code currently implements them.
sources:
  - src/notes/commands.py
  - src/notes/store.py
  - src/notes/export.py
tags: [capability, commands, storage]
---

# Capability Inventory

## Commands

| Command | Effect | Stores |
|---|---|---|
| `add <text>` | Appends a note with the next id and a UTC timestamp. | `notes.json` in the current folder. |
| `list` | Prints every note as id, timestamp and text, in insertion order. | Nothing; read only. |
| `export` | Writes every note to a CSV file, one row per note. | `notes.csv` in the current folder. |

## Not offered

- No edit, delete or search command.
- No remote sync and no network access.
