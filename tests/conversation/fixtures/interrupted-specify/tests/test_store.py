import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from notes.store import NoteStore  # noqa: E402


class NoteStoreTest(unittest.TestCase):
    def test_add_then_list_keeps_order(self):
        with tempfile.TemporaryDirectory() as folder:
            store = NoteStore(Path(folder) / "notes.json")
            first = store.add("buy milk")
            second = store.add("call home")
            self.assertEqual(first["id"], 1)
            self.assertEqual(second["id"], 2)
            self.assertEqual([n["text"] for n in store.list()], ["buy milk", "call home"])

    def test_empty_store_lists_nothing(self):
        with tempfile.TemporaryDirectory() as folder:
            self.assertEqual(NoteStore(Path(folder) / "missing.json").list(), [])


if __name__ == "__main__":
    unittest.main()
