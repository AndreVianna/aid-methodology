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
printf 'user edit to shared file\n' >> "$TARGET/.agents/skills/aid-define/SKILL.md"
OUT="$(run_aid remove claude-code --target "$TARGET" 2>&1)" || { echo "$OUT" >&2; exit 1; }
assert_file_absent "$TARGET/.agents/skills/aid-define/SKILL.md" 'Last shared user removes canonical skill'
assert_file_exists "$TARGET/.aid/.trash/.agents/skills/aid-define/SKILL.md" 'Changed shared skill is preserved in trash'
assert_file_absent "$TARGET/.aid/runtime/rules.md" 'Last shared user removes runtime payload'
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
printf 'user edit after install\n' >> "$THIRD/AGENTS.md"
OUT="$(run_aid remove claude-code --target "$THIRD" 2>&1)" || { echo "$OUT" >&2; exit 1; }
assert_output_contains "$OUT" 'Left in place (modified or not AID-owned): AGENTS.md' 'Edited AGENTS.md prints the exact preservation notice'
assert_file_exists "$THIRD/AGENTS.md" 'Edited AGENTS.md stays in place'
if head -c "$(wc -c < "$TMP/attributes.before")" "$THIRD/.gitattributes" | cmp -s - "$TMP/attributes.before"; then pass 'Removing managed gitattributes bytes preserves the original user line bytes'; else fail 'Removing managed gitattributes bytes preserves the original user line bytes'; fi
assert_output_contains "$(cat "$THIRD/AGENTS.md")" 'user edit after install' 'Edited AGENTS.md user bytes remain'

# A pre-existing markerless CLAUDE.md survives the last Claude import user.
SECOND="${TMP}/claude-region"; mkdir -p "$SECOND"
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

# A remaining tool whose rules_inline flag is false restores the pointer region
# when the inline tool leaves.
FOURTH="${TMP}/inline-transition"; mkdir -p "$FOURTH"
run_aid add claude-code,cursor --from-bundle "$BUNDLE" --target "$FOURTH" >/dev/null 2>&1 || exit 1
python3 - "$FOURTH" <<'PY'
import hashlib,json,pathlib,sys
root=pathlib.Path(sys.argv[1]); manifest=root/'.aid/.aid-manifest.json'; data=json.loads(manifest.read_text())
data['tools']['cursor']['rules_inline']=True
path=root/'AGENTS.md'; text=path.read_text(encoding='utf-8')
start=text.index('<!-- AID:BEGIN -->'); end=text.index('<!-- AID:END -->')+len('<!-- AID:END -->\n')
rules=(root/'.aid/runtime/rules.md').read_text(encoding='utf-8')
region='<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n'+rules+'<!-- AID:END -->\n'
path.write_text(text[:start]+region+text[end:],encoding='utf-8')
data['shared']['agents_md']['file_sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
manifest.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
PY
run_aid remove cursor --target "$FOURTH" >/dev/null 2>&1 || exit 1
assert_file_contains "$FOURTH/AGENTS.md" '@.aid/runtime/rules.md' 'Removing the last inline-rules tool restores the pointer region'
assert_file_not_contains "$FOURTH/AGENTS.md" 'The AID rules' 'Pointer rewrite removes the previous inline body'

test_summary
