#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export AID_STATUS_FIXTURE="$TMP/project"
mkdir -p "$AID_STATUS_FIXTURE/.aid" "$AID_STATUS_FIXTURE/.agents/skills/aid-one" "$AID_STATUS_FIXTURE/.claude/skills/aid-one" "$AID_STATUS_FIXTURE/.aid/runtime" "$AID_STATUS_FIXTURE/.tool/agents"
python3 - "$AID_STATUS_FIXTURE" <<'PY'
import hashlib,json,pathlib,sys
r=pathlib.Path(sys.argv[1])
def put(path,data):
    p=r/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data);return hashlib.sha256(data).hexdigest()
skill=b'skill\n'; runtime=b'host\n'; agent=b'agent\n'
agents=b'outside\n<!-- AID:BEGIN -->\nmanaged\n<!-- AID:END -->\nmore\n'
claude=b'outside\n<!-- AID:BEGIN -->\n@AGENTS.md\n<!-- AID:END -->\nmore\n'
put('.agents/skills/aid-one/SKILL.md',skill);put('.claude/skills/aid-one/SKILL.md',skill)
put('.aid/runtime/host.conf',runtime);put('.tool/agents/aid-x',agent)
put('AGENTS.md',agents);put('CLAUDE.md',claude)
def region(b):
    lines=b.splitlines(keepends=True);a=next(i for i,x in enumerate(lines) if x.rstrip(b'\n')==b'<!-- AID:BEGIN -->');z=next(i for i,x in enumerate(lines) if x.rstrip(b'\n')==b'<!-- AID:END -->');return b''.join(lines[a:z+1])
manifest={'format_version':3,'aid_version':'1.0.0','shared':{'skills':{'files':[{'path':'aid-one/SKILL.md','sha256':hashlib.sha256(skill).hexdigest()}]},'runtime':{'files':[{'path':'host.conf','sha256':hashlib.sha256(runtime).hexdigest()}]},'mirrors':{'.claude/skills':{}},'agents_md':{'region_sha256':hashlib.sha256(region(agents)).hexdigest()},'claude_md':{'region_sha256':hashlib.sha256(region(claude)).hexdigest()}},'tools':{'claude-code':{'mirrors':['.claude/skills'],'files':[{'path':'.tool/agents/aid-x','sha256':hashlib.sha256(agent).hexdigest()}]}}}
(r/'.aid/.aid-manifest.json').write_text(json.dumps(manifest))
PY
source "$ROOT/lib/aid-install-core.sh"
out="$(aid_status "$AID_STATUS_FIXTURE")"
[[ "$out" == *'Shared files: clean'* ]]
# Outside-region edits and checkout CRLF conversion do not change canonical LF region hashes.
python3 - "$AID_STATUS_FIXTURE" <<'PY'
import pathlib,sys
r=pathlib.Path(sys.argv[1])
for name in ('AGENTS.md','CLAUDE.md'):
    p=r/name;p.write_bytes(p.read_bytes().replace(b'outside',b'outside changed').replace(b'\n',b'\r\n'))
PY
out="$(aid_status "$AID_STATUS_FIXTURE")"
[[ "$out" == *'Shared files: clean'* ]]
printf x >> "$AID_STATUS_FIXTURE/.agents/skills/aid-one/SKILL.md"
printf x >> "$AID_STATUS_FIXTURE/.claude/skills/aid-one/SKILL.md"
rm "$AID_STATUS_FIXTURE/.tool/agents/aid-x"
python3 - "$AID_STATUS_FIXTURE" <<'PY'
import pathlib,sys
r=pathlib.Path(sys.argv[1])
for name in ('AGENTS.md','CLAUDE.md'):
    p=r/name;p.write_bytes(p.read_bytes().replace(b'@AGENTS.md',b'@AGENTS.md changed').replace(b'managed\r\n',b'managed changed\r\n'))
PY
mkdir -p "$AID_STATUS_FIXTURE/.agents/skills/aid-extra"
printf x > "$AID_STATUS_FIXTURE/.agents/skills/aid-extra/SKILL.md"
mkdir -p "$AID_STATUS_FIXTURE/.claude/skills/aid-extra"
printf x > "$AID_STATUS_FIXTURE/.claude/skills/aid-extra/SKILL.md"
printf x > "$AID_STATUS_FIXTURE/.aid/runtime/stray.txt"
mkdir -p "$AID_STATUS_FIXTURE/.aid/runtime/scripts/x/node_modules"
printf altered > "$AID_STATUS_FIXTURE/.aid/runtime/scripts/x/node_modules/a.js"
mkdir -p "$AID_STATUS_FIXTURE/.agents/skills/user-skill"
printf x > "$AID_STATUS_FIXTURE/.agents/skills/user-skill/SKILL.md"
out="$(aid_status "$AID_STATUS_FIXTURE")"
for expected in 'modified: .agents/skills/aid-one/SKILL.md' 'modified: .claude/skills/aid-one/SKILL.md' 'missing: .tool/agents/aid-x' 'modified: AGENTS.md' 'modified: CLAUDE.md' 'extra: .agents/skills/aid-extra/SKILL.md' 'extra: .claude/skills/aid-extra/SKILL.md' 'extra: .aid/runtime/stray.txt' 'Run: aid update'; do
    [[ "$out" == *"$expected"* ]] || { printf 'FAIL: expected %s\n' "$expected" >&2; exit 1; }
done
[[ "$out" != *'user-skill'* && "$out" != *'node_modules'* ]]
aid_status_body "$AID_STATUS_FIXTURE" > "$TMP/dashboard.out"
! rg -q 'Shared files' "$TMP/dashboard.out"
rm "$AID_STATUS_FIXTURE/CLAUDE.md"
out="$(aid_status "$AID_STATUS_FIXTURE")"
[[ "$out" == *'missing: CLAUDE.md'* ]]
printf 'restored\n' > "$AID_STATUS_FIXTURE/CLAUDE.md"
sed -i '/AID:BEGIN/d; /AID:END/d' "$AID_STATUS_FIXTURE/CLAUDE.md"
out="$(aid_status "$AID_STATUS_FIXTURE")"
[[ "$out" == *'missing: CLAUDE.md'* ]]
python3 - "$AID_STATUS_FIXTURE/.aid/.aid-manifest.json" <<'PY'
import json,pathlib,sys
p=pathlib.Path(sys.argv[1]);d=json.loads(p.read_text());d['shared'].pop('claude_md',None);d['tools'].pop('claude-code',None);p.write_text(json.dumps(d))
PY
out="$(aid_status "$AID_STATUS_FIXTURE")"
[[ "$out" != *'CLAUDE.md'* ]]
printf '{"format_version":2,"aid_version":"1.0.0","tools":{}}\n' > "$AID_STATUS_FIXTURE/.aid/.aid-manifest.json"
out="$(aid_status "$AID_STATUS_FIXTURE")"
[[ "$out" == *'Layout: format 4 (pre-shared). Run: aid update'* && "$out" != *'Shared files'* ]]
rm "$AID_STATUS_FIXTURE/.aid/.aid-manifest.json"
status=0
aid_status "$AID_STATUS_FIXTURE" >/dev/null || status=$?
[[ "$status" -eq 7 ]]
printf 'task-013 drift report fixtures passed\n'
