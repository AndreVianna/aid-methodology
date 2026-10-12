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
recorded_dep=b'original package\n'; missing_dep=b'original missing package\n'
agents=b'outside\n<!-- AID:BEGIN -->\nmanaged\n<!-- AID:END -->\nmore\n'
claude=b'outside\n<!-- AID:BEGIN -->\nmanaged\n@.aid/runtime/rules.md\n<!-- AID:END -->\nmore\n'
put('.agents/skills/aid-one/SKILL.md',skill);put('.claude/skills/aid-one/SKILL.md',skill)
put('.aid/runtime/host.conf',runtime);put('.tool/agents/aid-x',agent)
recorded_dep_sha=put('.aid/runtime/pkg/node_modules/recorded.js',recorded_dep)
missing_dep_sha=put('.aid/runtime/pkg/node_modules/missing.js',missing_dep)
put('AGENTS.md',agents);put('CLAUDE.md',claude)
def region(b):
    lines=b.splitlines(keepends=True);a=next(i for i,x in enumerate(lines) if x.rstrip(b'\n')==b'<!-- AID:BEGIN -->');z=next(i for i,x in enumerate(lines) if x.rstrip(b'\n')==b'<!-- AID:END -->');return b''.join(lines[a:z+1])
manifest={'format_version':3,'aid_version':'1.0.0','shared':{'skills':{'files':[{'path':'aid-one/SKILL.md','sha256':hashlib.sha256(skill).hexdigest()}]},'runtime':{'files':[{'path':'host.conf','sha256':hashlib.sha256(runtime).hexdigest()},{'path':'pkg/node_modules/recorded.js','sha256':recorded_dep_sha},{'path':'pkg/node_modules/missing.js','sha256':missing_dep_sha}]},'mirrors':{'.claude/skills':{}},'agents_md':{'region_sha256':hashlib.sha256(region(agents)).hexdigest()},'claude_md':{'region_sha256':hashlib.sha256(region(claude)).hexdigest()}},'tools':{'claude-code':{'mirrors':['.claude/skills'],'files':[{'path':'.tool/agents/aid-x','sha256':hashlib.sha256(agent).hexdigest()}]}}}
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
printf changed > "$AID_STATUS_FIXTURE/.aid/runtime/pkg/node_modules/recorded.js"
rm "$AID_STATUS_FIXTURE/.aid/runtime/pkg/node_modules/missing.js"
python3 - "$AID_STATUS_FIXTURE" <<'PY'
import pathlib,sys
r=pathlib.Path(sys.argv[1])
for name in ('AGENTS.md','CLAUDE.md'):
    p=r/name;p.write_bytes(p.read_bytes().replace(b'managed\r\n',b'managed changed\r\n'))
PY
mkdir -p "$AID_STATUS_FIXTURE/.agents/skills/aid-extra"
printf x > "$AID_STATUS_FIXTURE/.agents/skills/aid-extra/SKILL.md"
mkdir -p "$AID_STATUS_FIXTURE/.claude/skills/aid-extra"
printf x > "$AID_STATUS_FIXTURE/.claude/skills/aid-extra/SKILL.md"
printf loose > "$AID_STATUS_FIXTURE/.agents/skills/aid-loose"
printf loose > "$AID_STATUS_FIXTURE/.claude/skills/aid-mirror-loose"
printf x > "$AID_STATUS_FIXTURE/.aid/runtime/stray.txt"
mkdir -p "$AID_STATUS_FIXTURE/.aid/runtime/scripts/x/node_modules"
printf altered > "$AID_STATUS_FIXTURE/.aid/runtime/scripts/x/node_modules/a.js"
mkdir -p "$AID_STATUS_FIXTURE/.agents/skills/user-skill"
printf x > "$AID_STATUS_FIXTURE/.agents/skills/user-skill/SKILL.md"
out="$(aid_status "$AID_STATUS_FIXTURE")"
for expected in 'modified: .agents/skills/aid-one/SKILL.md' 'modified: .claude/skills/aid-one/SKILL.md' 'missing: .tool/agents/aid-x' 'modified: AGENTS.md' 'modified: CLAUDE.md' 'extra: .agents/skills/aid-extra/SKILL.md' 'extra: .claude/skills/aid-extra/SKILL.md' 'extra: .agents/skills/aid-loose' 'extra: .claude/skills/aid-mirror-loose' 'extra: .aid/runtime/stray.txt' 'Run: aid update'; do
    [[ "$out" == *"$expected"* ]] || { printf 'FAIL: expected %s\n' "$expected" >&2; exit 1; }
done
[[ "$out" == *$'\nShared files\nmodified:'* ]]
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
