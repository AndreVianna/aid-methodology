---
kb-category: primary
source: hand-authored
objective: Describe the notes benchmark project, its checks, and its source layout.
summary: The notes CLI stores local notes in a JSON file and is tested with unittest.
sources: [README.md, src/notes/store.py, src/notes/commands.py, tests/test_store.py]
---

# Notes Project Card

## What it is

A small command-line notes tool. It stores notes in `notes.json` in the current
directory and lists pinned notes first.

## Stack

Python and the standard library; no external runtime dependencies.

## Commands

From the project root, run the existing tests with
`PYTHONPATH=src python3 -m unittest discover -s tests -v`. Run the tool with
`PYTHONPATH=src python3 -m notes` followed by a command. There is no configured
build or lint command in this fixture.

## Where things live

`src/notes/store.py` handles storage; `src/notes/commands.py` implements the
CLI. `tests/test_store.py` contains the existing tests; `README.md` describes
usage.

## Detail

Use `.aid/knowledge/INDEX.md` to find the relevant architecture, capability,
and module documents.
