#!/usr/bin/env python3
# render_lib.py -- small helpers shared by the profile renderer
#
# Purpose:
#   Provide UTF-8 file I/O for canonical content. Profile emission manifests and
#   content rewriting were retired when profiles became agents-only outputs.
#
# Usage:
#   python render_lib.py --self-test
#
# Requirements: Python 3.11+; standard library only.
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def read_canonical_file(path: str | Path) -> str:
    """Read a UTF-8 canonical source file."""
    return Path(path).read_text(encoding="utf-8")


def write_output_file(path: str | Path, content: str) -> bytes:
    """Write UTF-8 text with LF line endings and return the emitted bytes."""
    dest = Path(path)
    dest.parent.mkdir(parents=True, exist_ok=True)
    encoded = content.encode("utf-8")
    dest.write_bytes(encoded)
    return encoded


def main() -> int:
    """Run focused helper self-tests when requested."""
    parser = argparse.ArgumentParser(prog="render_lib.py")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if not args.self_test:
        parser.print_help()
        return 0

    failures: list[str] = []
    import tempfile

    with tempfile.TemporaryDirectory() as temp:
        target = Path(temp) / "nested" / "out.txt"
        expected = "line one\nline two\n"
        actual = write_output_file(target, expected)
        if actual != expected.encode("utf-8") or target.read_bytes() != actual:
            failures.append("write_output_file did not preserve UTF-8/LF bytes")
        if read_canonical_file(target) != expected:
            failures.append("read_canonical_file did not return written text")

    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        return 1
    print("OK: render_lib self-tests passed (2 checks)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
