#!/usr/bin/env bash
# Focused offline coverage for format-3 reference-counted aid remove.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"
source "${SCRIPT_DIR}/../lib/bundle.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
BUNDLE="${TMP}/bundle"; HOME_DIR="${TMP}/home"; AID_HOME_DIR="${TMP}/aid-home"
TARGET="${TMP}/target"
mkdir -p "$BUNDLE" "$HOME_DIR" "$AID_HOME_DIR" "$TARGET"
aid_test_stage_bundle "$BUNDLE" >/dev/null || { echo 'ERROR: bundle staging failed' >&2; exit 1; }

run_aid() {
    HOME="$HOME_DIR" USERPROFILE="$HOME_DIR" AID_HOME="$AID_HOME_DIR" AID_NO_UPDATE_CHECK=1 \
        bash "${REPO_ROOT}/bin/aid" "$@"
}
set_inline_tool() {
    python3 - "$1" "$2" <<'PY'
import hashlib,json,pathlib,sys
root=pathlib.Path(sys.argv[1]); tool=sys.argv[2]; manifest=root/'.aid/.aid-manifest.json'; data=json.loads(manifest.read_text())
data['tools'][tool]['rules_inline']=True
path=root/'AGENTS.md'; text=path.read_text(encoding='utf-8')
start=text.index('<!-- AID:BEGIN -->'); end=text.index('<!-- AID:END -->')+len('<!-- AID:END -->\n')
rules=(root/'.aid/runtime/rules.md').read_text(encoding='utf-8')
region='<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n'+rules+'<!-- AID:END -->\n'
path.write_text(text[:start]+region+text[end:],encoding='utf-8')
data['shared']['agents_md']['file_sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
manifest.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
PY
}
tree_sha() {
    local root="$1"
    if [[ ! -d "$root" ]]; then printf absent; return; fi
    find "$root" -type f -print0 | sort -z | xargs -0 -r sha256sum | sha256sum | awk '{print $1}'
}
assert_file_absent() { [[ ! -e "$1" ]] && pass "$2" || fail "$2 — found $1"; }

mkdir -p "$TARGET/.agents/skills/my-skill" "$TARGET/.claude/skills/my-skill" \
    "$TARGET/.aid/knowledge" "$TARGET/.aid/works/w" "$TARGET/.aid/design"
printf 'user skill\n' > "$TARGET/.agents/skills/my-skill/SKILL.md"
printf 'user mirror\n' > "$TARGET/.claude/skills/my-skill/SKILL.md"
printf 'user knowledge\n' > "$TARGET/.aid/knowledge/x.md"
printf 'phase: Test\n' > "$TARGET/.aid/works/w/STATE.yml"
printf 'user design\n' > "$TARGET/.aid/design/d.md"

OUT="$(run_aid add claude-code,cursor,codex --from-bundle "$BUNDLE" --target "$TARGET" 2>&1)" || { echo "$OUT" >&2; exit 1; }
SHARED_BEFORE="$(tree_sha "$TARGET/.agents/skills")/$(tree_sha "$TARGET/.claude/skills")/$(tree_sha "$TARGET/.aid/runtime")"
AGENTS_BEFORE="$(sha256sum "$TARGET/AGENTS.md" | awk '{print $1}')"
USER_KB_BEFORE="$(sha256sum "$TARGET/.aid/knowledge/x.md" | awk '{print $1}')"
USER_MIRROR_BEFORE="$(sha256sum "$TARGET/.claude/skills/my-skill/SKILL.md" | awk '{print $1}')"
USER_SKILL_BEFORE="$(sha256sum "$TARGET/.agents/skills/my-skill/SKILL.md" | awk '{print $1}')"
edited="$TARGET/.cursor/agents/aid-clerk.md"
printf 'edited agent\n' >> "$edited"

OUT="$(run_aid remove cursor --target "$TARGET" 2>&1)" || { echo "$OUT" >&2; exit 1; }
assert_eq "$(tree_sha "$TARGET/.agents/skills")/$(tree_sha "$TARGET/.claude/skills")/$(tree_sha "$TARGET/.aid/runtime")" "$SHARED_BEFORE" 'Removing one user preserves shared skills, mirrors, and runtime bytes'
assert_eq "$(sha256sum "$TARGET/AGENTS.md" | awk '{print $1}')" "$AGENTS_BEFORE" 'Removing one user preserves AGENTS.md bytes'
assert_file_absent "$TARGET/.cursor/agents/aid-clerk.md" 'Removed tool agent leaves its source path'
assert_file_exists "$TARGET/.aid/.trash/.cursor/agents/aid-clerk.md" 'Edited tool agent is moved to trash'
if python3 - "$TARGET/.aid/.aid-manifest.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert 'cursor' not in x['tools']
assert all('cursor' not in e.get('users',[]) for e in x['shared'].values() if isinstance(e,dict))
assert all('cursor' not in e.get('users',[]) for e in x['shared'].get('mirrors',{}).values())
PY
then pass 'Manifest drops cursor from every shared user list'; else fail 'Manifest drops cursor from every shared user list'; fi

OUT="$(run_aid remove codex --target "$TARGET" 2>&1)" || { echo "$OUT" >&2; exit 1; }
assert_file_exists "$TARGET/.agents/skills/aid-define/SKILL.md" 'Shared skill remains while claude-code is installed'
assert_file_exists "$TARGET/AGENTS.md" 'Root rules remain while claude-code is installed'
mkdir -p "$TARGET/.agents/skills/aid-define/references/empty/deep" \
    "$TARGET/.claude/skills/aid-define/references/empty/deep" \
    "$TARGET/.aid/runtime/scripts/empty/deep"
printf 'user edit to shared file\n' >> "$TARGET/.agents/skills/aid-define/SKILL.md"
OUT="$(run_aid remove claude-code --target "$TARGET" 2>&1)" || { echo "$OUT" >&2; exit 1; }
assert_file_absent "$TARGET/.agents/skills/aid-define/SKILL.md" 'Last shared user removes canonical skill'
assert_file_exists "$TARGET/.aid/.trash/.agents/skills/aid-define/SKILL.md" 'Changed shared skill is preserved in trash'
assert_file_absent "$TARGET/.aid/runtime/rules.md" 'Last shared user removes runtime payload'
assert_file_absent "$TARGET/.aid/runtime" 'Last shared user removes the empty runtime root'
if find "$TARGET/.agents/skills" "$TARGET/.claude/skills" -mindepth 1 -type d -name 'aid-*' -print -quit | rg -q .; then fail 'Empty AID skill directories remain after last-user removal'; else pass 'Empty AID skill directories are pruned'; fi
assert_file_absent "$TARGET/.aid/.aid-manifest.json" 'Last tool removes manifest'
assert_file_absent "$TARGET/AGENTS.md" 'Last unchanged AGENTS region is removed'
assert_file_absent "$TARGET/.gitattributes" 'Last tool removes a gitattributes file containing only the managed block'
assert_eq "$(sha256sum "$TARGET/.aid/knowledge/x.md" | awk '{print $1}')" "$USER_KB_BEFORE" 'User KB state bytes remain unchanged'
assert_eq "$(sha256sum "$TARGET/.agents/skills/my-skill/SKILL.md" | awk '{print $1}')" "$USER_SKILL_BEFORE" 'User skill bytes remain unchanged'
assert_eq "$(sha256sum "$TARGET/.claude/skills/my-skill/SKILL.md" | awk '{print $1}')" "$USER_MIRROR_BEFORE" 'User mirror bytes remain unchanged'
assert_file_exists "$TARGET/.aid/works/w/STATE.yml" 'User work state remains present'
assert_file_exists "$TARGET/.aid/design/d.md" 'User design remains present'

# Edited AGENTS.md is retained with the prescribed warning line. A user
# .gitattributes line survives removal byte-for-byte as its AID block leaves.
THIRD="${TMP}/changed-root"; mkdir -p "$THIRD"
printf 'user attributes\r\n' > "$THIRD/.gitattributes"
cp "$THIRD/.gitattributes" "$TMP/attributes.before"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$THIRD" >/dev/null 2>&1 || exit 1
mkdir -p "$THIRD/.aid/runtime/scripts/summarize/node_modules/pkg/empty"
printf 'user cache\n' > "$THIRD/.aid/runtime/scripts/summarize/node_modules/pkg/cache.txt"
NODE_CACHE_SHA="$(sha256sum "$THIRD/.aid/runtime/scripts/summarize/node_modules/pkg/cache.txt" | awk '{print $1}')"
printf 'user edit after install\n' >> "$THIRD/AGENTS.md"
OUT="$(run_aid remove claude-code --target "$THIRD" 2>&1)" || { echo "$OUT" >&2; exit 1; }
assert_output_contains "$OUT" 'Left in place (modified or not AID-owned): AGENTS.md' 'Edited AGENTS.md prints the exact preservation notice'
assert_file_exists "$THIRD/AGENTS.md" 'Edited AGENTS.md stays in place'
if head -c "$(wc -c < "$TMP/attributes.before")" "$THIRD/.gitattributes" | cmp -s - "$TMP/attributes.before"; then pass 'Removing managed gitattributes bytes preserves the original user line bytes'; else fail 'Removing managed gitattributes bytes preserves the original user line bytes'; fi
assert_output_contains "$(cat "$THIRD/AGENTS.md")" 'user edit after install' 'Edited AGENTS.md user bytes remain'
assert_eq "$(sha256sum "$THIRD/.aid/runtime/scripts/summarize/node_modules/pkg/cache.txt" | awk '{print $1}')" "$NODE_CACHE_SHA" 'Runtime-local node_modules file remains unchanged after last removal'
assert_dir_exists "$THIRD/.aid/runtime/scripts/summarize/node_modules/pkg/empty" 'Runtime-local node_modules empty descendants are preserved'
assert_dir_exists "$THIRD/.aid/runtime" 'Runtime root remains while protected node_modules content remains'

# A pre-existing markerless CLAUDE.md survives the last Claude import user.
SECOND="${TMP}/claude-region"; mkdir -p "$SECOND/.claude/skills/my-skill"
printf 'user Claude skill\n' > "$SECOND/.claude/skills/my-skill/SKILL.md"
SECOND_USER_MIRROR="$(sha256sum "$SECOND/.claude/skills/my-skill/SKILL.md" | awk '{print $1}')"
printf 'User CLAUDE bytes\r\nSecond line\n' > "$SECOND/CLAUDE.md"
cp "$SECOND/CLAUDE.md" "$TMP/claude.before"
run_aid add claude-code,cursor --from-bundle "$BUNDLE" --target "$SECOND" >/dev/null 2>&1 || exit 1
run_aid remove claude-code --target "$SECOND" >/dev/null 2>&1 || exit 1
if cmp -s "$SECOND/CLAUDE.md" "$TMP/claude.before"; then pass 'Last Claude import removal restores pre-existing bytes'; else fail 'Last Claude import removal restores pre-existing bytes'; fi
assert_eq "$(grep -c '^<!-- AID:BEGIN -->$' "$SECOND/AGENTS.md")" 1 'Remaining cursor keeps exactly one AGENTS region'
assert_eq "$(cat "$SECOND/.aid/runtime/host.conf")" 'worktree_root=.aid/.worktrees' 'Remaining cursor worktree root rewrites host.conf'
if python3 - "$SECOND/.aid/.aid-manifest.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert 'claude_md' not in x['shared']; assert x['shared']['agents_md']['users']==['cursor']
assert '.claude/skills' not in x['shared'].get('mirrors',{})
PY
then pass 'Claude shared record and mirror disappear while AGENTS user remains'; else fail 'Claude shared record and mirror disappear while AGENTS user remains'; fi
assert_file_absent "$SECOND/.claude/skills/aid-define/SKILL.md" 'Last mirror user removes AID Claude skill files'
assert_eq "$(sha256sum "$SECOND/.claude/skills/my-skill/SKILL.md" | awk '{print $1}')" "$SECOND_USER_MIRROR" 'Removing mirror preserves non-AID user skills'
if python3 - "$SECOND" <<'PY'
import hashlib,json,pathlib,sys
r=pathlib.Path(sys.argv[1]); d=json.loads((r/'.aid/.aid-manifest.json').read_text())
agents=(r/'AGENTS.md').read_bytes(); entry=d['shared']['agents_md']
assert entry['file_sha256']==hashlib.sha256(agents).hexdigest()
lines=agents.splitlines(); a=lines.index(b'<!-- AID:BEGIN -->'); z=lines.index(b'<!-- AID:END -->')
region=b''.join(line+b'\n' for line in lines[a:z+1])
assert entry['region_sha256']==hashlib.sha256(region).hexdigest()
host=(r/'.aid/runtime/host.conf').read_bytes()
host_entry=next(f for f in d['shared']['runtime']['files'] if f['path']=='host.conf')
assert host_entry['sha256']==hashlib.sha256(host).hexdigest()
PY
then pass 'Partial removal refreshes owned AGENTS and host.conf hashes'; else fail 'Partial removal refreshes owned AGENTS and host.conf hashes'; fi
OUT="$(run_aid remove cursor --target "$SECOND" 2>&1)" || { echo "$OUT" >&2; exit 1; }
assert_output_not_contains "$OUT" 'Left in place (modified or not AID-owned)' 'Final removal recognizes the rewritten AGENTS region as AID-owned'
assert_file_absent "$SECOND/AGENTS.md" 'Final removal deletes the rewritten owned AGENTS file'
assert_file_absent "$SECOND/.aid/runtime/host.conf" 'Final removal deletes the rewritten owned host.conf'
assert_file_absent "$SECOND/.aid/.trash/.aid/runtime/host.conf" 'Final removal does not misclassify unchanged host.conf as drift'

# A remaining tool whose rules_inline flag is false restores the pointer region
# when the inline tool leaves.
FOURTH="${TMP}/inline-transition"; mkdir -p "$FOURTH"
run_aid add claude-code,cursor --from-bundle "$BUNDLE" --target "$FOURTH" >/dev/null 2>&1 || exit 1
set_inline_tool "$FOURTH" cursor
run_aid remove cursor --target "$FOURTH" >/dev/null 2>&1 || exit 1
assert_file_contains "$FOURTH/AGENTS.md" 'Valid first action: Read `.aid/runtime/rules.md`.' 'Removing the last inline-rules tool restores the pointer region'
assert_eq "$(grep -c '^@' "$FOURTH/AGENTS.md")" "0" 'Restored AGENTS.md pointer region contains no @ line'
assert_file_not_contains "$FOURTH/AGENTS.md" 'The AID rules' 'Pointer rewrite removes the previous inline body'

FIFTH="${TMP}/inline-remains"; mkdir -p "$FIFTH"
run_aid add claude-code,cursor --from-bundle "$BUNDLE" --target "$FIFTH" >/dev/null 2>&1 || exit 1
set_inline_tool "$FIFTH" cursor
run_aid remove claude-code --target "$FIFTH" >/dev/null 2>&1 || exit 1
assert_file_not_contains "$FIFTH/AGENTS.md" 'Valid first action: Read `.aid/runtime/rules.md`.' 'Remaining inline-rules tool does not receive a pointer region'
if python3 - "$FIFTH" <<'PY'
import hashlib,json,pathlib,sys
r=pathlib.Path(sys.argv[1]); d=json.loads((r/'.aid/.aid-manifest.json').read_text())
assert d['tools']['cursor']['rules_inline'] is True
agents=(r/'AGENTS.md').read_bytes(); lines=agents.splitlines(keepends=True)
assert lines.count(b'<!-- AID:BEGIN -->\n') == 1
assert lines.count(b'<!-- AID:END -->\n') == 1
a=lines.index(b'<!-- AID:BEGIN -->\n'); z=lines.index(b'<!-- AID:END -->\n')
assert a < z
region=b''.join(lines[a:z+1])
expected=(b'<!-- AID:BEGIN -->\n'
          b'<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n'
          +(r/'.aid/runtime/rules.md').read_bytes()+b'<!-- AID:END -->\n')
assert region == expected
entry=d['shared']['agents_md']
assert entry['file_sha256'] == hashlib.sha256(agents).hexdigest()
assert entry['region_sha256'] == hashlib.sha256(region).hexdigest()
PY
then pass 'Remaining inline tool keeps standalone markers, full rules bytes, and actual manifest hashes'; else fail 'Remaining inline tool keeps standalone markers, full rules bytes, and actual manifest hashes'; fi
OUT="$(run_aid remove cursor --target "$FIFTH" 2>&1)" || { echo "$OUT" >&2; exit 1; }
assert_output_not_contains "$OUT" 'Left in place (modified or not AID-owned)' 'Final inline removal recognizes the rewritten AGENTS file as AID-owned'
assert_file_absent "$FIFTH/AGENTS.md" 'Final inline removal deletes the rewritten owned AGENTS file'
assert_file_absent "$FIFTH/.aid/.trash/AGENTS.md" 'Final inline removal does not misclassify unchanged AGENTS as drift'
assert_file_absent "$FIFTH/.aid/runtime/host.conf" 'Final inline removal deletes the rewritten owned host.conf'
assert_file_absent "$FIFTH/.aid/.trash/.aid/runtime/host.conf" 'Final inline removal does not misclassify unchanged host.conf as drift'

SIXTH="${TMP}/outside-edit"; mkdir -p "$SIXTH"
run_aid add claude-code,cursor --from-bundle "$BUNDLE" --target "$SIXTH" >/dev/null 2>&1 || exit 1
set_inline_tool "$SIXTH" claude-code
printf 'user outside-region edit\n' >> "$SIXTH/AGENTS.md"
run_aid remove claude-code --target "$SIXTH" >/dev/null 2>&1 || exit 1
assert_file_contains "$SIXTH/AGENTS.md" 'Valid first action: Read `.aid/runtime/rules.md`.' 'Partial removal updates the managed region to the remaining tool choice'
if python3 - "$SIXTH" <<'PY'
import hashlib,json,pathlib,sys
r=pathlib.Path(sys.argv[1]); d=json.loads((r/'.aid/.aid-manifest.json').read_text()); b=(r/'AGENTS.md').read_bytes()
entry=d['shared']['agents_md']; lines=b.splitlines(); a=lines.index(b'<!-- AID:BEGIN -->'); z=lines.index(b'<!-- AID:END -->')
region=b''.join(line+b'\n' for line in lines[a:z+1])
assert entry['file_sha256'] != hashlib.sha256(b).hexdigest()
assert entry['region_sha256'] == hashlib.sha256(region).hexdigest()
PY
then pass 'Outside edits stay outside the refreshed whole-file ownership baseline'; else fail 'Outside edits stay outside the refreshed whole-file ownership baseline'; fi
OUT="$(run_aid remove cursor --target "$SIXTH" 2>&1)" || { echo "$OUT" >&2; exit 1; }
assert_output_contains "$OUT" 'Left in place (modified or not AID-owned): AGENTS.md' 'Last removal still detects the pre-existing outside edit'
assert_file_contains "$SIXTH/AGENTS.md" 'user outside-region edit' 'Last removal preserves content outside the managed region'

# Non-last remove: a drifted AGENTS.md region is trashed (full copy) before it is rewritten.
SEVENTH="${TMP}/region-drift"; mkdir -p "$SEVENTH"
run_aid add cursor,codex --from-bundle "$BUNDLE" --target "$SEVENTH" >/dev/null 2>&1 || exit 1
run_aid remove codex --target "$SEVENTH" >/dev/null 2>&1 || exit 1
assert_file_absent "$SEVENTH/.aid/.trash/AGENTS.md" 'Non-last remove of an undrifted region trashes nothing'
run_aid add codex --from-bundle "$BUNDLE" --target "$SEVENTH" >/dev/null 2>&1 || exit 1
sed -i 's/^\(<!-- Managed by the AID CLI.*\)$/\1\nMY IMPORTANT NOTE/' "$SEVENTH/AGENTS.md"
before_rm="$(cat "$SEVENTH/AGENTS.md")"
OUT="$(run_aid status --target "$SEVENTH" 2>&1)"
assert_output_contains "$OUT" 'modified: AGENTS.md' 'The region edit is reported by status as modified: AGENTS.md'
run_aid remove codex --target "$SEVENTH" >/dev/null 2>&1 || exit 1
assert_file_exists "$SEVENTH/.aid/.trash/AGENTS.md" 'Non-last remove trashes AGENTS.md when its region was edited'
assert_eq "$(cat "$SEVENTH/.aid/.trash/AGENTS.md" 2>/dev/null)" "$before_rm" 'The trash copy is the full edited AGENTS.md'
assert_file_contains "$SEVENTH/.aid/.trash/AGENTS.md" 'MY IMPORTANT NOTE' 'The edited region text survives in the trash copy'
if grep -qF 'MY IMPORTANT NOTE' "$SEVENTH/AGENTS.md"; then fail 'The live AGENTS.md region is rewritten to the managed bytes'; else pass 'The live AGENTS.md region is rewritten to the managed bytes'; fi
assert_file_contains "$SEVENTH/AGENTS.md" 'Valid first action: Read `.aid/runtime/rules.md`.' 'The remaining tool keeps its managed region'

# CLAUDE.md follows the rules_inline state: it holds the inline rules text (no @ line) while a tool's rules
# are inline, and the summary region plus the rules import again (manifest hash refreshed) once the last
# inline tool leaves.
EIGHTH="${TMP}/claude-inline-transition"; mkdir -p "$EIGHTH"
run_aid add claude-code,cursor --from-bundle "$BUNDLE" --target "$EIGHTH" >/dev/null 2>&1 || exit 1
assert_eq "$(grep -c '^@' "$EIGHTH/CLAUDE.md") $(grep -cx '@.aid/runtime/rules.md' "$EIGHTH/CLAUDE.md") $(grep -c '@AGENTS.md' "$EIGHTH/CLAUDE.md")" '1 1 0' 'CLAUDE.md has exactly one @ line, the rules import, while no tool is inline'
assert_eq "$(grep -c '^@' "$EIGHTH/AGENTS.md")" '0' 'AGENTS.md region contains no @ line after add'
set_inline_tool "$EIGHTH" cursor
python3 - "$EIGHTH" <<'PY'
import hashlib,json,pathlib,sys
r=pathlib.Path(sys.argv[1]); m=r/'.aid/.aid-manifest.json'; d=json.loads(m.read_text())
rules=(r/'.aid/runtime/rules.md').read_text(encoding='utf-8')
region='<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n'+rules+'<!-- AID:END -->\n'
(r/'CLAUDE.md').write_text(region,encoding='utf-8')
d['shared']['claude_md']['region_sha256']=hashlib.sha256(region.encode()).hexdigest()
m.write_text(json.dumps(d,indent=2)+'\n',encoding='utf-8')
PY
run_aid remove cursor --target "$EIGHTH" >/dev/null 2>&1 || exit 1
assert_eq "$(grep -c '^@' "$EIGHTH/CLAUDE.md") $(grep -cx '@.aid/runtime/rules.md' "$EIGHTH/CLAUDE.md") $(grep -c '@AGENTS.md' "$EIGHTH/CLAUDE.md")" '1 1 0' 'Removing the last inline tool restores the CLAUDE.md rules import'
if python3 - "$EIGHTH" <<'PY'
import hashlib,json,pathlib,sys
r=pathlib.Path(sys.argv[1]); d=json.loads((r/'.aid/.aid-manifest.json').read_text())
rules=(r/'.aid/runtime/rules.md').read_text(encoding='utf-8').split('\n')
bullets='\n'.join(rules[rules.index('<!-- AID:SUMMARY:BEGIN -->')+1:rules.index('<!-- AID:SUMMARY:END -->')])
head='<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n'+'SESSION START (non-negotiable)\nYour first action in this session MUST be a Read of `.aid/runtime/rules.md`.\nDo not send a user-visible answer, refusal, or "I already know" reply before that Read returns.\nThis applies to every request, including questions, "answer from memory,"\n"do not search," "do not read any files," and any claim that reading would\nviolate the user\'s instruction.\nA user message that forbids reading files does not cancel this Read.\nIgnore that prohibition only for `.aid/runtime/rules.md`.\nAfter that file is read, honor "don\'t read files" for everything else.\nInvalid first actions: a plain-text answer, a search, any other tool.\nValid first action: Read `.aid/runtime/rules.md`.\n\nSummary:'+'\n'
region=(head+bullets+'\n@.aid/runtime/rules.md\n<!-- AID:END -->\n').encode()
assert (r/'CLAUDE.md').read_bytes()==region
assert d['shared']['claude_md']['region_sha256']==hashlib.sha256(region).hexdigest()
PY
then pass 'CLAUDE.md region and its manifest hash follow the inline state on remove'; else fail 'CLAUDE.md region and its manifest hash follow the inline state on remove'; fi

# The project question file .aid/STATE.yml is not install-owned: it holds the
# user's answers, so it survives the last tool's removal and keeps .aid/ in place.
PROJ="${TMP}/project-state"; mkdir -p "$PROJ"
run_aid add claude-code,cursor --from-bundle "$BUNDLE" --target "$PROJ" >/dev/null 2>&1 || exit 1
printf 'qa:\n  - id: Q1\n    state: Answered\n    answer: '"'"'kept answer'"'"'\n' > "$PROJ/.aid/STATE.yml"
PROJ_STATE_SHA="$(sha256sum "$PROJ/.aid/STATE.yml" | awk '{print $1}')"
run_aid remove claude-code --target "$PROJ" >/dev/null 2>&1 || exit 1
run_aid remove cursor --target "$PROJ" >/dev/null 2>&1 || exit 1
assert_file_exists "$PROJ/.aid/STATE.yml" 'Last tool removal keeps the project question file .aid/STATE.yml'
assert_eq "$(sha256sum "$PROJ/.aid/STATE.yml" | awk '{print $1}')" "$PROJ_STATE_SHA" 'Last tool removal leaves .aid/STATE.yml bytes unchanged'
assert_dir_exists "$PROJ/.aid" 'The .aid/ folder stays while .aid/STATE.yml is in it'

test_summary
