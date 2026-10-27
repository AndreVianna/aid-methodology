#!/usr/bin/env python3
"""Purpose: request permission for direct pushes and deny direct merges in Claude shell calls.
Usage: safeguard.py < hook-input.json
Exit codes: 0 for a decision or no match; 2 for invalid input.
This does not claim to detect aliases, indirection or calls outside the registered host tools.
"""
import json
import re
import sys


def main():
    try:
        event = json.load(sys.stdin)
        command = event['tool_input']['command']
        if not isinstance(command, str):
            raise ValueError('command must be text')
        git = r'(?<![\w.-])git(?:\.exe)?\b(?:(?![;&|\n]).)*?\b'
        if re.search(git + r'merge\b|(?<![\w.-])gh(?:\.exe)?\s+pr\s+merge\b', command, re.I):
            decision, reason = 'deny', 'The maintainer performs merges.'
        elif re.search(git + r'push\b', command, re.I):
            decision, reason = 'ask', 'Ask the user before pushing.'
        else:
            return 0
        print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse',
              'permissionDecision': decision, 'permissionDecisionReason': reason}}))
        return 0
    except (ValueError, KeyError, TypeError) as exc:
        print(f'safeguard: {exc}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
