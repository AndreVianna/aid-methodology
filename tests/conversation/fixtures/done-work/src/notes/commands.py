"""Command-line entry point: add a note, list the notes, or export them to CSV."""

import argparse
import sys
from pathlib import Path

from notes.export import write_csv
from notes.store import NoteStore

NOTES_FILE = Path("notes.json")
EXPORT_FILE = Path("notes.csv")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="notes", description="Keep short text notes.")
    sub = parser.add_subparsers(dest="command", required=True)
    add = sub.add_parser("add", help="add a note")
    add.add_argument("text", help="the note text")
    sub.add_parser("list", help="list every note")
    sub.add_parser("export", help="write every note to notes.csv")
    args = parser.parse_args(argv)

    store = NoteStore(NOTES_FILE)
    if args.command == "add":
        note = store.add(args.text)
        print(f"added note {note['id']}")
        return 0
    if args.command == "export":
        write_csv(store.list(), EXPORT_FILE)
        print(f"wrote {EXPORT_FILE}")
        return 0
    for note in store.list():
        print(f"{note['id']}\t{note['created']}\t{note['text']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
