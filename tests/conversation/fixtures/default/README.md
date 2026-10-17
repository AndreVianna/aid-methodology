# notes

A small command-line tool that keeps short text notes in a local JSON file.

## Usage

```bash
python3 -m notes add "buy milk"
python3 -m notes list
```

Notes are stored in `notes.json` in the current folder. Each note has an `id`, a `text` and a
`created` timestamp (UTC, ISO 8601).

## Layout

- `src/notes/store.py`: the note store (read, append, list).
- `src/notes/cli.py`: the command-line entry point.
- `tests/test_store.py`: unit tests for the store.
