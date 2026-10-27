#!/usr/bin/env python3
"""Purpose: write a compact work state atomically.
Usage: state.py --file state.json --data '{"goal":"..."}'
Exit codes: 0 on success, 1 for invalid data or write failure.
"""
import argparse
import json
import os
import sys
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--file', required=True)
    parser.add_argument('--data', required=True)
    args = parser.parse_args()
    temp = None
    try:
        data = json.loads(args.data)
        if not isinstance(data, dict):
            raise ValueError('state must be an object')
        path = Path(args.file)
        with tempfile.NamedTemporaryFile('w', encoding='utf-8', dir=path.parent, delete=False) as out:
            temp = out.name
            json.dump(data, out, ensure_ascii=False, indent=2)
            out.write('\n')
        os.replace(temp, path)
        return 0
    except (OSError, ValueError) as exc:
        print(f'state: {exc}', file=sys.stderr)
        return 1
    finally:
        if temp and os.path.exists(temp):
            os.unlink(temp)


if __name__ == '__main__':
    sys.exit(main())
