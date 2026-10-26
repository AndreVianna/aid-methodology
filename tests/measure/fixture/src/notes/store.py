"""Local JSON-file note store."""

import json
from datetime import datetime, timezone
from pathlib import Path


class NoteStore:
    """Keeps notes in one JSON file; each note is a dict with id, text and created."""

    def __init__(self, path: Path):
        self.path = Path(path)

    def _read(self) -> list[dict]:
        if not self.path.exists():
            return []
        return json.loads(self.path.read_text(encoding="utf-8"))

    def _write(self, notes: list[dict]) -> None:
        self.path.write_text(json.dumps(notes, indent=2) + "\n", encoding="utf-8")

    def add(self, text: str) -> dict:
        """Append a note with the next free id and return it."""
        notes = self._read()
        next_id = max((n["id"] for n in notes), default=0) + 1
        note = {
            "id": next_id,
            "text": text,
            "created": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        }
        notes.append(note)
        self._write(notes)
        return note

    def pin(self, note_id: int) -> bool:
        """Mark a note as pinned; return False when no note has that id."""
        notes = self._read()
        for note in notes:
            if note["id"] == note_id:
                note["pinned"] = True
                self._write(notes)
                return True
        return False

    def list(self) -> list[dict]:
        """Return every note in insertion order."""
        return self._read()
