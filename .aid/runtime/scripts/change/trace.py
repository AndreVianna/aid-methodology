#!/usr/bin/env python3
"""Purpose: verify links between criteria and tasks.
Usage: trace.py --file plan.json
Exit codes: 0 when linked, 1 for gaps or invalid input.
"""
import argparse
import json
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--file', required=True)
    args = parser.parse_args()
    try:
        data = json.loads(Path(args.file).read_text(encoding='utf-8'))
        criteria = data['criteria']
        tasks = data['tasks']
        if not criteria or not tasks or len(set(criteria)) != len(criteria):
            raise ValueError('criteria and tasks must be nonempty and criteria unique')
        covered, ids = set(), set()
        for task in tasks:
            if not task['id'] or task['id'] in ids or not task['criteria']:
                raise ValueError('tasks require a unique id and criterion links')
            ids.add(task['id'])
            covered.update(task['criteria'])
        if covered != set(criteria):
            raise ValueError(f'criterion mismatch: missing {set(criteria) - covered}, unknown {covered - set(criteria)}')
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f'trace: {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
