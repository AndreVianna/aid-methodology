# notes

A small command-line tool that keeps short text notes in a local JSON file.

## Usage

```bash
PYTHONPATH=src python3 -m notes add "buy milk"
PYTHONPATH=src python3 -m notes pin 1
PYTHONPATH=src python3 -m notes list
```

`list` shows pinned notes first, then the others, each note once.

Notes are stored in `notes.json` in the current folder. Each note has an `id`, a `text` and a
`created` timestamp (UTC, ISO 8601); a pinned note also has `"pinned": true`.

## Layout

- `src/notes/store.py`: the note store (read, append, pin, list).
- `src/notes/commands.py`: the command-line entry point.
- `tests/test_store.py`: unit tests for the store.
