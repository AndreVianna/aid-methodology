#!/usr/bin/env bash
# COVERS: .aid/works/work-001-shared-skills-folder/REQUIREMENTS.md AC-9, AC-10, AC-14(d)
# Shared-layout reference counting, drift repair and last-user root-file cleanup.
set -uo pipefail
VERBOSE=0
[[ "${1:-}" == --verbose || "${1:-}" == -v ]] && VERBOSE=1
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
source "${HERE}/../lib/assert.sh"
source "${HERE}/../lib/bundle.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name .aid -type d 2>/dev/null | sort || true)"
export HOME="${TMP}/home" USERPROFILE="${TMP}/home" AID_NO_UPDATE_CHECK=1
mkdir -p "$HOME"
STAGE="${TMP}/stage"; mkdir -p "$STAGE"
if ! aid_test_stage_bundle "$STAGE" >"${TMP}/stage.log" 2>&1; then cat "${TMP}/stage.log" >&2; exit 1; fi
sha() { sha256sum "$1" | awk '{print $1}'; }
run_aid() {
    local target="$1" state="$2"; shift 2
    AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" "$@" --target "$target"
}
run_bundle() {
    local target="$1" state="$2"; shift 2
    AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" "$@" --target "$target" --from-bundle "$STAGE"
}
manifest_has_user() {
    python3 - "$1" "$2" "$3" <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
parts=sys.argv[2].split('.')
node=data
for part in parts: node=node[part]
sys.exit(0 if sys.argv[3] in node else 1)
PY
}
manifest_has_entry() {
    python3 - "$1" "$2" <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
sys.exit(0 if sys.argv[2] in data.get('shared', {}) else 1)
PY
}
manifest_path() { printf '%s\n' "$1/.aid/.aid-manifest.json"; }
assert_cmd() {
    local label="$1"; shift
    local output rc
    output="$("$@" 2>&1)"; rc=$?
    if [[ $rc -eq 0 ]]; then pass "$label"; else fail "$label (exit $rc)"; [[ $VERBOSE -eq 1 ]] && printf '%s\n' "$output" >&2; fi
}
assert_path_hash_same() {
    local before="$1" path="$2" label="$3"
    if [[ -f "$path" ]] && [[ "$(sha "$path")" == "$before" ]]; then pass "$label"; else fail "$label"; fi
}
echo '== test-multitool-isolation.sh =='

# AC-9: shared entries remain until their last user leaves.
TARGET="$TMP/refcount"; STATE="$TMP/state-refcount"; mkdir -p "$TARGET/.agents/skills/my-skill" "$TARGET/.claude/skills/my-skill" "$STATE"
printf 'user skill\n' > "$TARGET/.agents/skills/my-skill/SKILL.md"
printf 'user mirror\n' > "$TARGET/.claude/skills/my-skill/SKILL.md"
USER_AGENT_SHA="$(sha "$TARGET/.agents/skills/my-skill/SKILL.md")"; USER_CLAUDE_SHA="$(sha "$TARGET/.claude/skills/my-skill/SKILL.md")"
assert_cmd 'AC-9 add claude-code,cursor,codex succeeds' run_bundle "$TARGET" "$STATE" add claude-code,cursor,codex
MANIFEST="$(manifest_path "$TARGET")"
if [[ -n "$MANIFEST" ]]; then pass 'AC-9 manifest is present'; else fail 'AC-9 manifest is present'; fi
shared_snapshot() {
    (cd "$TARGET" && find .agents/skills .claude/skills .aid/runtime AGENTS.md -type f 2>/dev/null | sort | while IFS= read -r f; do printf '%s %s\n' "$(sha "$TARGET/${f#./}")" "$f"; done)
}
SHARED_BEFORE="$(shared_snapshot)"
assert_cmd 'AC-9 remove cursor succeeds' run_aid "$TARGET" "$STATE" remove cursor
if [[ "$SHARED_BEFORE" == "$(shared_snapshot)" ]]; then pass 'AC-9 shared skill, runtime and AGENTS hashes stay unchanged after cursor removal'; else fail 'AC-9 shared skill, runtime and AGENTS hashes stay unchanged after cursor removal'; fi
if ! compgen -G "$TARGET/.cursor/agents/aid-*" >/dev/null; then pass 'AC-9 cursor AID agents are removed'; else fail 'AC-9 cursor AID agents are removed'; fi
if ! manifest_has_user "$MANIFEST" shared.agents_md.users cursor 2>/dev/null; then pass 'AC-9 manifest no longer names cursor'; else fail 'AC-9 manifest no longer names cursor'; fi
assert_path_hash_same "$USER_AGENT_SHA" "$TARGET/.agents/skills/my-skill/SKILL.md" 'AC-9 non-AID .agents skill hash survives cursor removal'
assert_path_hash_same "$USER_CLAUDE_SHA" "$TARGET/.claude/skills/my-skill/SKILL.md" 'AC-9 non-AID Claude skill hash survives cursor removal'
assert_cmd 'AC-9 remove codex succeeds' run_aid "$TARGET" "$STATE" remove codex
if [[ -d "$TARGET/.agents/skills" && -d "$TARGET/.claude/skills" && -d "$TARGET/.aid/runtime" ]]; then pass 'AC-9 shared entries remain after codex removal'; else fail 'AC-9 shared entries remain after codex removal'; fi
assert_path_hash_same "$USER_AGENT_SHA" "$TARGET/.agents/skills/my-skill/SKILL.md" 'AC-9 non-AID .agents skill hash survives codex removal'
assert_path_hash_same "$USER_CLAUDE_SHA" "$TARGET/.claude/skills/my-skill/SKILL.md" 'AC-9 non-AID Claude skill hash survives codex removal'
assert_cmd 'AC-9 remove claude-code succeeds' run_aid "$TARGET" "$STATE" remove claude-code
if ! compgen -G "$TARGET/.agents/skills/aid-*" >/dev/null && ! compgen -G "$TARGET/.claude/skills/aid-*" >/dev/null && [[ ! -d "$TARGET/.aid/runtime" ]]; then pass 'AC-9 shared AID payload is removed after last tool'; else fail 'AC-9 shared AID payload is removed after last tool'; [[ $VERBOSE -eq 1 ]] && find "$TARGET/.agents/skills" "$TARGET/.claude/skills" "$TARGET/.aid" -maxdepth 3 -print 2>/dev/null >&2; fi
assert_path_hash_same "$USER_AGENT_SHA" "$TARGET/.agents/skills/my-skill/SKILL.md" 'AC-9 non-AID .agents skill hash is preserved throughout'
assert_path_hash_same "$USER_CLAUDE_SHA" "$TARGET/.claude/skills/my-skill/SKILL.md" 'AC-9 non-AID Claude skill hash is preserved throughout'

# AC-10: status identifies modified, missing and extra drift; update restores bytes and trashes modified files.
DRIFT="$TMP/drift"; DSTATE="$TMP/state-drift"; mkdir -p "$DRIFT" "$DSTATE"
assert_cmd 'AC-10 add claude-code succeeds' run_bundle "$DRIFT" "$DSTATE" add claude-code
printf x >> "$DRIFT/.claude/skills/aid-ask/SKILL.md"
rm -f "$DRIFT/.claude/skills/aid-fix/SKILL.md"
printf x >> "$DRIFT/.agents/skills/aid-plan/SKILL.md"
STATUS="$(AID_HOME="$DSTATE" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" status --target "$DRIFT" 2>&1)"; STATUS_RC=$?
if [[ $STATUS_RC -eq 0 && "$STATUS" == *'.claude/skills/aid-ask/SKILL.md'* && "$STATUS" == *'.claude/skills/aid-fix/SKILL.md'* && "$STATUS" == *'.agents/skills/aid-plan/SKILL.md'* && "$STATUS" == *'aid update'* ]]; then pass 'AC-10 status names all drift paths and aid update'; else fail 'AC-10 status names all drift paths and aid update'; [[ $VERBOSE -eq 1 ]] && printf '%s\n' "$STATUS" >&2; fi
assert_cmd 'AC-10 update from same staging succeeds' run_bundle "$DRIFT" "$DSTATE" update
if cmp -s "$REPO/canonical/skills/aid-ask/SKILL.md" "$DRIFT/.claude/skills/aid-ask/SKILL.md" && cmp -s "$REPO/canonical/skills/aid-fix/SKILL.md" "$DRIFT/.claude/skills/aid-fix/SKILL.md" && cmp -s "$REPO/canonical/skills/aid-plan/SKILL.md" "$DRIFT/.agents/skills/aid-plan/SKILL.md"; then pass 'AC-10 update restores modified and missing skills to canonical bytes'; else fail 'AC-10 update restores modified and missing skills to canonical bytes'; fi
if cmp -s "$DRIFT/.aid/.trash/.claude/skills/aid-ask/SKILL.md" <(cat "$REPO/canonical/skills/aid-ask/SKILL.md"; printf x) && cmp -s "$DRIFT/.aid/.trash/.agents/skills/aid-plan/SKILL.md" <(cat "$REPO/canonical/skills/aid-plan/SKILL.md"; printf x); then pass 'AC-10 modified files are preserved byte-for-byte in trash at original paths'; else fail 'AC-10 modified files are preserved byte-for-byte in trash at original paths'; fi
STATUS2="$(AID_HOME="$DSTATE" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" status --target "$DRIFT" 2>&1)"; STATUS2_RC=$?
if [[ $STATUS2_RC -eq 0 && "$STATUS2" == *'Shared files: clean'* ]]; then pass 'AC-10 second status reports no drift'; else fail 'AC-10 second status reports no drift'; [[ $VERBOSE -eq 1 ]] && printf '%s\n' "$STATUS2" >&2; fi

# AC-14(d): remove Claude's import while Cursor keeps the single AGENTS region.
for kind in absent markerless; do
    TARGET="$TMP/claude-$kind"; STATE="$TMP/claude-state-$kind"; mkdir -p "$TARGET" "$STATE"
    if [[ "$kind" == markerless ]]; then printf 'User CLAUDE notes\n' > "$TARGET/CLAUDE.md"; cp "$TARGET/CLAUDE.md" "$TMP/claude-before-$kind"; fi
    assert_cmd "AC-14(d) add claude-code,cursor ($kind CLAUDE) succeeds" run_bundle "$TARGET" "$STATE" add claude-code,cursor
    assert_cmd "AC-14(d) remove claude-code ($kind CLAUDE) succeeds" run_aid "$TARGET" "$STATE" remove claude-code
    if [[ "$kind" == absent ]]; then
        [[ ! -e "$TARGET/CLAUDE.md" ]] && pass 'AC-14(d) CLI-created CLAUDE.md is removed' || fail 'AC-14(d) CLI-created CLAUDE.md is removed'
    else
        cmp -s "$TMP/claude-before-$kind" "$TARGET/CLAUDE.md" && pass 'AC-14(d) markerless user CLAUDE.md is restored byte-for-byte' || fail 'AC-14(d) markerless user CLAUDE.md is restored byte-for-byte'
    fi
    BEGIN_COUNT="$(awk '$0 == "<!-- AID:BEGIN -->" { n++ } END { print n+0 }' "$TARGET/AGENTS.md")"
    [[ "$BEGIN_COUNT" == 1 ]] && pass "AC-14(d) AGENTS.md retains exactly one AID region ($kind)" || fail "AC-14(d) AGENTS.md retains exactly one AID region ($kind)"
    MANIFEST="$(manifest_path "$TARGET")"
    if manifest_has_user "$MANIFEST" shared.agents_md.users cursor 2>/dev/null; then pass "AC-14(d) agents_md users contains cursor ($kind)"; else fail "AC-14(d) agents_md users contains cursor ($kind)"; fi
    if ! manifest_has_entry "$MANIFEST" claude_md 2>/dev/null; then pass "AC-14(d) manifest has no shared.claude_md ($kind)"; else fail "AC-14(d) manifest has no shared.claude_md ($kind)"; fi
done

# AC-9 last-user AGENTS.md cleanup variants.
for kind in user markerless-created edited; do
    TARGET="$TMP/agents-$kind"; STATE="$TMP/agents-state-$kind"; mkdir -p "$TARGET" "$STATE"
    if [[ "$kind" == user ]]; then printf '## User workflow\nKeep this text.\n' > "$TARGET/AGENTS.md"; cp "$TARGET/AGENTS.md" "$TMP/agents-before-$kind"; fi
    assert_cmd "AC-9 add claude-code ($kind AGENTS) succeeds" run_bundle "$TARGET" "$STATE" add claude-code
    if [[ "$kind" == user ]]; then
        assert_cmd 'AC-9 remove claude-code with markerless user AGENTS succeeds' run_aid "$TARGET" "$STATE" remove claude-code
        cmp -s "$TMP/agents-before-$kind" "$TARGET/AGENTS.md" && pass 'AC-9 markerless user AGENTS outside bytes are preserved when full-file hash matches' || fail 'AC-9 markerless user AGENTS outside bytes are preserved when full-file hash matches'
    elif [[ "$kind" == markerless-created ]]; then
        assert_cmd 'AC-9 remove claude-code with AID-created AGENTS succeeds' run_aid "$TARGET" "$STATE" remove claude-code
        [[ ! -e "$TARGET/AGENTS.md" ]] && pass 'AC-9 AID-created region-only AGENTS.md is deleted' || fail 'AC-9 AID-created region-only AGENTS.md is deleted'
    else
        assert_cmd 'AC-9 edit installed AGENTS then remove claude-code succeeds' bash -c 'printf "user edit\\n" >> "$1/AGENTS.md"; AID_HOME="$2" AID_NO_UPDATE_CHECK=1 bash "$3/bin/aid" remove claude-code --target "$1"' _ "$TARGET" "$STATE" "$REPO"
        [[ -f "$TARGET/AGENTS.md" ]] && grep -q 'user edit' "$TARGET/AGENTS.md" && pass 'AC-9 post-install edited AGENTS.md remains in place' || fail 'AC-9 post-install edited AGENTS.md remains in place'
    fi
done

# Existing isolation guarantees retained from the prior suite.
_CANARY_AFTER="$(find "$REAL_HOME" -maxdepth 6 -name .aid -type d 2>/dev/null | sort || true)"
[[ "$_CANARY_BEFORE" == "$_CANARY_AFTER" ]] && pass 'T27 escape canary: no new .aid/ dirs appeared in real HOME (<PATH>)' || fail 'T27 escape canary: no new .aid/ dirs appeared in real HOME (<PATH>)'
[[ "$HOME" != "$REAL_HOME" ]] && pass 'T29 HOME pin: fakehome (<PATH> is distinct from real HOME (<PATH>' || fail 'T29 HOME pin: fakehome (<PATH> is distinct from real HOME (<PATH>'
[[ ! -e "$HOME/.aid/.update-check" ]] && pass 'T30 no .update-check in fakehome (AID_NO_UPDATE_CHECK=1 honoured)' || fail 'T30 no .update-check in fakehome (AID_NO_UPDATE_CHECK=1 honoured)'
test_summary
