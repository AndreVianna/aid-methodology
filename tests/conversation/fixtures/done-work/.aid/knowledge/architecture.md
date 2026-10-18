---
kb-category: primary
source: hand-authored
objective: How the notes tool is structured and where its state lives.
summary: Describes the two layers (command line and store), the single JSON file that holds all state, the CSV export that reads from the store, and the tests that cover the store.
sources:
  - src/notes/commands.py
  - src/notes/store.py
  - src/notes/export.py
  - README.md
tags: [architecture, state, layers]
---

# Architecture

## Layers

- **Command line** (`src/notes/commands.py`): reads arguments, calls the store or the CSV writer, prints the output.
- **Store** (`src/notes/store.py`): the only code that touches the notes file. Each call reads the whole JSON
  file, changes it in memory, and writes it back.
- **Export** (`src/notes/export.py`): writes a list of notes to a CSV file. It reads nothing from disk.

## State

All state is one file, `notes.json`, in the folder the command runs from. It holds a JSON list of notes.
The export writes a second file, `notes.csv`, in the same folder; nothing reads it back.

## Testing

`tests/test_store.py` exercises the store against a temporary folder. The command line has no test of its own.
