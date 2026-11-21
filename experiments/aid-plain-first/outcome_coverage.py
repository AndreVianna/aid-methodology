#!/usr/bin/env python3
"""Check coverage-record structure; this cannot verify evidence or reviewer independence.

Usage: outcome_coverage.py coverage.json
Exit: 0 all outcomes marked verified with references, 1 failed/unverified, 2 invalid.
"""
import json
import sys
from pathlib import Path


def check(data):
    if not isinstance(data, dict) or set(data) != {'outcomes', 'results'}:
        raise ValueError('expected outcomes and results')
    outcomes, results = data['outcomes'], data['results']
    if not isinstance(outcomes, list) or not outcomes or not isinstance(results, list):
        raise ValueError('outcomes must be a nonempty list and results a list')
    ids = []
    for item in outcomes:
        if (not isinstance(item, dict) or set(item) != {'id', 'description'} or
                not isinstance(item['id'], str) or not item['id'].strip() or
                not isinstance(item['description'], str) or not item['description'].strip()):
            raise ValueError('each outcome needs an id and description')
        if item['id'] in ids:
            raise ValueError('duplicate outcome id: ' + item['id'])
        ids.append(item['id'])
    records = {}
    for item in results:
        if not isinstance(item, dict) or set(item) != {'id', 'status', 'evidence'}:
            raise ValueError('each result needs id, status and evidence')
        name, status, evidence = item['id'], item['status'], item['evidence']
        if not isinstance(name, str) or name not in ids or name in records:
            raise ValueError('unknown or duplicate result id')
        if status not in ('verified', 'failed', 'unverified'):
            raise ValueError('invalid result status')
        if (not isinstance(evidence, list) or
                any(not isinstance(value, str) or not value.strip() for value in evidence)):
            raise ValueError('evidence must be a list of nonempty references')
        if not evidence:
            raise ValueError('each result needs evidence references or an unverified reason')
        records[name] = status
    complete = True
    for name in ids:
        status = records.get(name, 'unverified')
        suffix = ' (no result supplied)' if name not in records else ''
        print(f'{name}: {status}{suffix}')
        complete = complete and status == 'verified'
    print('Structural check only: this does not prove the evidence or reviewer independence.')
    return 0 if complete else 1


def main():
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    try:
        def unique_object(pairs):
            obj = {}
            for key, value in pairs:
                if key in obj:
                    raise ValueError('duplicate JSON key: ' + key)
                obj[key] = value
            return obj
        data = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'), object_pairs_hook=unique_object)
        return check(data)
    except (OSError, ValueError, TypeError) as exc:
        print('outcome coverage: ' + str(exc), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
