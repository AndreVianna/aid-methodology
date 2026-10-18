---
kb-category: primary
source: hand-authored
objective: How the notes tool is structured and where its state lives.
summary: Describes the two layers (command line and store), the single JSON file that holds all state, and the tests that cover the store.
sources:
  - src/notes/commands.py
  - src/notes/store.py
  - README.md
tags: [architecture, state, layers]
---

# Architecture

## Layers

- **Command line** (`src/notes/commands.py`): reads arguments, calls the store, prints the output.
- **Store** (`src/notes/store.py`): the only code that reads or writes `notes.json`. Each call reads the whole JSON
  file, changes it in memory, and writes it back. A file the user asks for, such as an export, is written by the command that produces it (see State).

## State

All state is one file, `notes.json`, in the folder the command runs from. It holds a JSON list of notes.
Nothing else is persisted. An export file the user asks for (for example `notes.csv`) is output, not state: no
command reads it back, and it does not change `notes.json`.

## Testing

`tests/test_store.py` exercises the store against a temporary folder. The command line has no test of its own.
