"""Command-line entry point: add a note, or list the notes."""

import argparse
import sys
from pathlib import Path

from notes.store import NoteStore

NOTES_FILE = Path("notes.json")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="notes", description="Keep short text notes.")
    sub = parser.add_subparsers(dest="command", required=True)
    add = sub.add_parser("add", help="add a note")
    add.add_argument("text", help="the note text")
    pin = sub.add_parser("pin", help="pin a note so it lists first")
    pin.add_argument("id", type=int, help="the note id")
    sub.add_parser("list", help="list every note, pinned notes first")
    args = parser.parse_args(argv)

    store = NoteStore(NOTES_FILE)
    if args.command == "add":
        note = store.add(args.text)
        print(f"added note {note['id']}")
        return 0
    if args.command == "pin":
        if not store.pin(args.id):
            print(f"no note {args.id}", file=sys.stderr)
            return 1
        print(f"pinned note {args.id}")
        return 0
    notes = store.list()
    pinned = [n for n in notes if n.get("pinned")]
    for note in pinned + notes:
        print(f"{note['id']}\t{note['created']}\t{note['text']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
