"""CSV export: one row per note, with the columns id, created and text."""

import csv
from pathlib import Path


def write_csv(notes: list[dict], path: Path) -> None:
    with Path(path).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["id", "created", "text"])
        for note in notes:
            writer.writerow([note["id"], note["created"], note["text"]])
