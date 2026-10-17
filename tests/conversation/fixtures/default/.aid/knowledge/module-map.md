---
kb-category: primary
source: hand-authored
objective: Which source file owns which responsibility.
summary: Maps each module under src/notes/ and tests/ to its one responsibility and its main dependency.
sources:
  - src/notes/
  - tests/test_store.py
tags: [modules, layout]
---

# Module Map

| Path | Responsibility | Depends on |
|---|---|---|
| `src/notes/__init__.py` | Package marker and one-line description. | none |
| `src/notes/__main__.py` | Runs the command-line entry point for `python3 -m notes`. | `notes.commands` |
| `src/notes/commands.py` | Parses the `add` and `list` commands and prints results. | `notes.store` |
| `src/notes/store.py` | Reads and writes the JSON note file. | the standard library only |
| `tests/test_store.py` | Unit tests for `NoteStore`, using a temporary folder. | `notes.store` |
