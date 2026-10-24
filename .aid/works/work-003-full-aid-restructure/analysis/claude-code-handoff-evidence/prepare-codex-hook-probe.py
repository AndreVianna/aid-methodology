"""Purpose: build a private native-hook capability fixture, not product code.
Usage: /usr/bin/python3 prepare-codex-hook-probe.py
Exit: 0 ready; nonzero setup error. Does not invoke a model or trust a hook.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import uuid

source = Path('/mnt/c/Projects/AID')
evidence = source / '.aid/.temp/runner-codex-checks'
base = Path('/home/andre/projects/aid/.aid/.temp') / ('native-hooks-' + uuid.uuid4().hex)
base.mkdir(mode=0o700)
repo, home = base / 'repo', base / 'home'
repo.mkdir(mode=0o700)
home.mkdir(mode=0o700)
codex_home = home / '.codex'
codex_home.mkdir(mode=0o700)
auth = Path('/home/andre/.codex/auth.json')
assert auth.is_file()
shutil.copyfile(auth, codex_home / 'auth.json')
(codex_home / 'auth.json').chmod(0o600)
(codex_home / 'config.toml').write_text('web_search = "disabled"\n[features]\napps = false\n')
env = dict(os.environ, HOME=str(home), CODEX_HOME=str(codex_home),
           PATH='/home/andre/.local/bin:/usr/local/bin:/usr/bin:/bin',
           GIT_CEILING_DIRECTORIES=str(base), PYTHONDONTWRITEBYTECODE='1')
subprocess.run(['git', 'init', '-q'], cwd=repo, env=env, check=True)
handler = repo / '.aid/runtime/scripts/hooks/aid-native-probe.py'
handler.parent.mkdir(parents=True)
handler.write_text('''"""Private diagnostic hook; logs events and controlled toy outcomes only."""
import json
from pathlib import Path
import sys
import time

base = Path(__file__).resolve().parents[5]
payload = json.load(sys.stdin)
with (base / 'events.jsonl').open('a') as stream:
    stream.write(json.dumps(payload, ensure_ascii=False) + '\\n')
mode = (base / 'mode.txt').read_text().strip()
event = payload.get('hook_event_name')
command = str((payload.get('tool_input') or {}).get('command', ''))
if event == 'PreToolUse' and 'DENIED_SENTINEL' in command:
    if mode == 'malformed-pre':
        print('{invalid')
    elif mode == 'timeout-pre':
        time.sleep(4)
    else:
        print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse',
              'permissionDecision': 'deny', 'permissionDecisionReason':
              'Native capability probe: this sentinel write is denied. Do not retry.'}}))
elif event == 'Stop' and mode == 'stop-once':
    flag = base / 'stop-issued'
    if not flag.exists():
        flag.write_text('issued')
        print(json.dumps({'decision': 'block', 'reason':
              'Native continuation capability probe: reply CONTINUED without tools.'}))
''')
(base / 'mode.txt').write_text('observe\n')
config = {'description': 'Private AID capability probe; no product installation.', 'hooks': {}}
for event in ('SessionStart', 'PreToolUse', 'PostToolUse', 'Stop'):
    config['hooks'][event] = [{'hooks': [{'type': 'command',
        'command': f'/usr/bin/python3 "{handler}"', 'timeout': 2}]}]
hooks_path = repo / '.codex/hooks.json'
hooks_path.parent.mkdir()
hooks_path.write_text(json.dumps(config, indent=2) + '\n')
proof = {'purpose': 'Q190 isolated feasibility; not acceptance evidence',
         'base': str(base), 'repo': str(repo), 'home': str(home),
         'codex_home': str(codex_home), 'handler': str(handler),
         'handler_sha256': hashlib.sha256(handler.read_bytes()).hexdigest(),
         'definition_sha256': hashlib.sha256(hooks_path.read_bytes()).hexdigest(),
         'hook_trust_not_preseeded_or_bypassed': True,
         'existing_auth_copied_privately_no_contents_recorded': True,
         'environment': {k: env[k] for k in ('HOME', 'CODEX_HOME', 'PATH',
                                             'GIT_CEILING_DIRECTORIES', 'PYTHONDONTWRITEBYTECODE')}}
(evidence / 'delivery-003-native-hook-probe.json').write_text(json.dumps(proof, indent=2) + '\n')
print(json.dumps(proof, indent=2))
