#!/usr/bin/env python3
"""Purpose: verify Windows checkout line endings do not change runtime manifest bytes.
Usage: python tests/canonical/test_lf_manifest_policy.py
Exit codes: 0 when parity holds, nonzero on failure.
"""
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TEMPLATES = ('delivery-state-template.yml', 'shortcut-catalog.yml',
             'task-state-template.yml', 'work-state-template.yml')


class ManifestCheckoutParity(unittest.TestCase):
    def test_windows_autocrlf_runtime_and_manifest_match_git_blobs(self):
        scratch = ROOT / '.aid/.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='lf-manifest-', dir=scratch) as tmp:
            base = Path(tmp)
            origin, checkout = base / 'origin', base / 'checkout'
            origin.mkdir()
            def git(cwd, *args):
                return subprocess.run(['git', '-C', str(cwd), *args], check=True,
                                      capture_output=True).stdout
            git(origin, 'init', '-q')
            git(origin, 'config', 'user.name', 'Test')
            git(origin, 'config', 'user.email', 'test@example.invalid')
            git(origin, 'config', 'core.autocrlf', 'false')
            attributes = Path(os.environ.get('AID_TEST_GITATTRIBUTES', ROOT / '.gitattributes'))
            (origin / '.gitattributes').write_bytes(attributes.read_bytes())
            folder = origin / 'canonical/aid/templates'
            folder.mkdir(parents=True)
            blobs = {}
            for name in TEMPLATES:
                rel = 'canonical/aid/templates/' + name
                blob = subprocess.run(['git', '-C', str(ROOT), 'show', 'HEAD:' + rel],
                                      check=True, capture_output=True).stdout
                self.assertNotIn(b'\r\n', blob, rel)
                blobs[name] = blob
                (folder / name).write_bytes(blob)
            binary = b'\x00\x01\r\n\xff'
            (folder / 'binary-control.bin').write_bytes(binary)
            git(origin, 'add', '--all')
            git(origin, 'commit', '-qm', 'fixture')
            subprocess.run(['git', '-c', 'core.autocrlf=true', 'clone', '--no-hardlinks',
                            '--quiet', str(origin), str(checkout)], check=True, capture_output=True)

            runtime = base / 'installed/.aid/runtime/templates'
            runtime.mkdir(parents=True)
            manifest = {'shared': {'runtime': {'files': []}}}
            for name in TEMPLATES:
                source = checkout / 'canonical/aid/templates' / name
                installed = runtime / name
                shutil.copyfile(source, installed)
                digest = hashlib.sha256(installed.read_bytes()).hexdigest()
                manifest['shared']['runtime']['files'].append({'path': 'templates/' + name, 'sha256': digest})
                with self.subTest(template=name):
                    self.assertEqual(source.read_bytes(), blobs[name], 'autocrlf changed the payload')
                    self.assertEqual(installed.read_bytes(), blobs[name], 'installed bytes differ from Git')
                    self.assertEqual(digest, hashlib.sha256(blobs[name]).hexdigest(), 'manifest hash drift')
            self.assertEqual((checkout / 'canonical/aid/templates/binary-control.bin').read_bytes(), binary)
            self.assertEqual(len(json.loads(json.dumps(manifest))['shared']['runtime']['files']), 4)


if __name__ == '__main__':
    unittest.main()
