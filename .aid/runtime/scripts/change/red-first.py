#!/usr/bin/env python3
"""Purpose: prove new tests fail on the old revision without changing the source checkout.
Usage: red-first.py --repo DIR --revision REV --tests DIR --junit FILE -- COMMAND [ARGS...]
Exit codes: 0 for an actual failing test, 1 for missing, passing or invalid evidence.
"""
import argparse
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for option in ('repo', 'revision', 'tests', 'junit'):
        parser.add_argument('--' + option, required=True)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    try:
        if not command:
            raise ValueError('missing test command')
        tests = Path(args.tests).resolve(strict=True)
        report = Path(args.junit)
        if not tests.is_dir() or report.is_absolute() or '..' in report.parts:
            raise ValueError('tests must be a directory and report must be relative')
        with tempfile.TemporaryDirectory(prefix='aid-red-first-') as temp:
            checkout = Path(temp) / 'repo'
            subprocess.run(['git', 'clone', '--quiet', '--no-hardlinks', '--no-checkout', str(Path(args.repo).resolve()), str(checkout)], check=True)
            subprocess.run(['git', '-C', str(checkout), 'checkout', '--quiet', '--detach', args.revision], check=True)
            target = checkout / tests.name
            if target.is_symlink():
                raise ValueError('test destination is a symbolic link')
            for source in tests.rglob('*'):
                destination = target / source.relative_to(tests)
                if source.is_symlink() or destination.is_symlink():
                    raise ValueError('symbolic links are not accepted in the test overlay')
            shutil.copytree(tests, target, dirs_exist_ok=True)
            (checkout / report).unlink(missing_ok=True)
            result = subprocess.run(command, cwd=checkout)
            root = ET.parse(checkout / report).getroot()
            cases = root.findall('.//testcase')
            if not result.returncode or not cases or any(case.find('failure') is None or case.find('error') is not None for case in cases):
                raise ValueError('each new test must fail on the old revision')
        return 0
    except (OSError, ValueError, ET.ParseError, subprocess.CalledProcessError) as exc:
        print(f'red-first: {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
