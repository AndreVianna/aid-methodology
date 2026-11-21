#!/usr/bin/env python3
"""Purpose: deny recognized direct push and merge commands in Codex PreToolUse.
Usage: codex_safeguard.py < hook-input.json
Exit codes: 0 for a decision or no match; 2 for invalid input.
Registration, trust and indirect shell or non-shell paths require separate verification.
"""
import json
import re
import shlex
import sys
from pathlib import PurePosixPath


def protected(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=';&|')
    lexer.whitespace_split = True
    words = list(lexer)
    chunks = []
    current = []
    for word in words:
        if word and all(c in ';&|' for c in word):
            chunks.append(current)
            current = []
        else:
            current.append(word)
    chunks.append(current)
    for chunk in chunks:
        while chunk and re.fullmatch(r'[A-Za-z_][A-Za-z_0-9]*=.*', chunk[0]):
            chunk = chunk[1:]
        if not chunk:
            continue
        executable = PurePosixPath(chunk[0].replace('\\', '/')).name.lower()
        if executable in ('git', 'git.exe'):
            index = 1
            while index < len(chunk) and chunk[index].startswith('-'):
                option = chunk[index]
                index += 1
                if option in ('-C', '-c', '--git-dir', '--work-tree', '--namespace'):
                    index += 1
            if index < len(chunk) and chunk[index] in ('push', 'merge'):
                return True
        if executable in ('gh', 'gh.exe') and chunk[1:3] == ['pr', 'merge']:
            return True
    return False


def main():
    try:
        event = json.load(sys.stdin)
        command = event['tool_input']['command']
        if not isinstance(command, str):
            raise ValueError('command must be text')
        if protected(command):
            print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse',
                  'permissionDecision': 'deny', 'permissionDecisionReason': 'Push and merge require the maintainer.'}}))
        return 0
    except (ValueError, KeyError, TypeError) as exc:
        print(f'codex safeguard: {exc}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
