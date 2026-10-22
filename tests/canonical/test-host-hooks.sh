#!/usr/bin/env bash
# test-host-hooks.sh -- the AID Stop hook that `aid add claude-code` / `aid update` merge into the
# project's .claude/settings.json, and that `aid remove` takes out again.
#
# Purpose: prove the merge keeps every user entry, is idempotent, is recorded in the manifest
#   (tools.<tool>.hooks, format_version 3), is removed by record and by path, and that a settings
#   file AID will not edit is left alone with a warning while the install still succeeds.
# Usage:   bash tests/canonical/test-host-hooks.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.
#
# COVERS: lib/aid-install-core.sh
# COVERS: profiles/
# COVERS: bin/aid
# COVERS: .claude/skills/generate-profile/scripts/aid_profile.py
# COVERS: .claude/skills/generate-profile/scripts/render.py

set -u
VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"
source "${SCRIPT_DIR}/../lib/bundle.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
BUNDLE="${TMP}/bundle"; HOME_DIR="${TMP}/home"; AID_HOME_DIR="${TMP}/aid-home"
mkdir -p "$BUNDLE" "$HOME_DIR" "$AID_HOME_DIR"
aid_test_stage_bundle "$BUNDLE" >/dev/null 2>&1 || { echo 'ERROR: bundle staging failed' >&2; exit 1; }

COMMAND_STR='bash "${CLAUDE_PROJECT_DIR}/.aid/runtime/scripts/hooks/aid-question-form.sh"'
SETTINGS=".claude/settings.json"

run_aid() {
    HOME="$HOME_DIR" USERPROFILE="$HOME_DIR" AID_HOME="$AID_HOME_DIR" AID_NO_UPDATE_CHECK=1 TMPDIR="$TMP" \
        bash "${REPO_ROOT}/bin/aid" "$@"
}
new_target() {
    local t="${TMP}/target-$1"
    mkdir -p "$t"; git -C "$t" init -q
    printf '%s' "$t"
}
sha_of() { sha256sum "$1" | awk '{print $1}'; }
# jq-free JSON probes
py() { python3 -I -c "$@"; }
count_aid_handlers() {
    py 'import json,sys
d=json.load(open(sys.argv[1]))
n=0
for g in d.get("hooks",{}).get("Stop",[]):
    for h in g.get("hooks",[]):
        if "/.aid/runtime/scripts/hooks/aid-" in h.get("command",""): n+=1
print(n)' "$1"
}
stop_group_count() {
    py 'import json,sys
print(len(json.load(open(sys.argv[1])).get("hooks",{}).get("Stop",[])))' "$1"
}
manifest_hooks() {
    py 'import json,sys
t=json.load(open(sys.argv[1]))["tools"].get(sys.argv[2],{})
print(json.dumps(t.get("hooks"),sort_keys=True))' "$1/.aid/.aid-manifest.json" "$2"
}
manifest_format_version() {
    py 'import json,sys
print(json.load(open(sys.argv[1]))["format_version"])' "$1/.aid/.aid-manifest.json"
}

# --- HH-01 fresh target ----------------------------------------------------------------------
T="$(new_target hh01)"
OUT="$(run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-01 add claude-code succeeds"
assert_output_contains "$OUT" "Hook: aid-question-form (Stop) in .claude/settings.json" "HH-01 add prints the one hook line"
assert_file_exists "${T}/${SETTINGS}" "HH-01 settings file created"
assert_eq "$(count_aid_handlers "${T}/${SETTINGS}")" 1 "HH-01 exactly one AID handler"
assert_eq "$(stop_group_count "${T}/${SETTINGS}")" 1 "HH-01 the AID handler sits in its own group"
assert_eq "$(py 'import json,sys
d=json.load(open(sys.argv[1]))
print(list(d.keys()), d["hooks"]["Stop"][0]["hooks"][0])' "${T}/${SETTINGS}")" \
    "['hooks'] {'type': 'command', 'command': '${COMMAND_STR}', 'timeout': 30}" "HH-01 the handler is the fixed command string with timeout 30"
assert_eq "$(manifest_hooks "$T" claude-code)" \
    '[{"created": true, "event": "Stop", "name": "aid-question-form", "settings": ".claude/settings.json"}]' \
    "HH-01 the manifest records the hook with created true"
assert_eq "$(manifest_format_version "$T")" 3 "HH-01 manifest format_version stays 3"
assert_eq "$(py 'import json,sys
print(list(json.load(open(sys.argv[1]))["tools"]["claude-code"].keys()))' "${T}/.aid/.aid-manifest.json")" \
    "['version', 'installed_at', 'mirrors', 'worktree_root', 'files', 'paths', 'hooks']" "HH-01 hooks is the last member of the tool entry"
assert_eq "$(tail -c1 "${T}/${SETTINGS}" | od -An -c | tr -d ' ')" '\n' "HH-01 the created file ends with a newline"
assert_eq "$(head -c3 "${T}/${SETTINGS}" | od -An -tx1 | tr -d ' ')" '7b0a20' "HH-01 LF, 2-space indent, no BOM"
assert_file_exists "${T}/.aid/runtime/scripts/hooks/aid-question-form.sh" "HH-01 the hook script ships to the runtime"

# --- HH-02 user keys and a user Stop hook are kept; re-runs change nothing ---------------------
T="$(new_target hh02)"
mkdir -p "${T}/.claude"
cat > "${T}/${SETTINGS}" <<'JSON'
{
  "permissions": {
    "allow": ["Bash(ls:*)"]
  },
  "note": "caf\u00e9 \u2603 \ud83d\ude00 \"q\" \\ \/ \u0001",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "echo pre" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "echo user-stop" }]
      }
    ]
  },
  "env": { "KEEP": "1", "NUM": 7, "NIL": null, "FLAG": true }
}
JSON
printf '\n' >> "${T}/${SETTINGS}"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1; RC=$?
assert_exit_zero "$RC" "HH-02 add into an existing settings file succeeds"
assert_eq "$(py 'import json,sys
d=json.load(open(sys.argv[1]))
print(list(d.keys()), d["permissions"], d["env"], d["hooks"]["PreToolUse"][0]["matcher"], d["hooks"]["Stop"][0]["hooks"][0]["command"], len(d["hooks"]["Stop"]))' "${T}/${SETTINGS}")" \
    "['permissions', 'note', 'hooks', 'env'] {'allow': ['Bash(ls:*)']} {'KEEP': '1', 'NUM': 7, 'NIL': None, 'FLAG': True} Bash echo user-stop 2" \
    "HH-02 user keys, order, values and the user Stop hook are kept"
assert_eq "$(py 'import json,sys
d=json.load(open(sys.argv[1]))
print(d["hooks"]["Stop"][1]["hooks"][0]["command"])' "${T}/${SETTINGS}")" "$COMMAND_STR" "HH-02 the AID group is appended after the user group"
assert_file_contains "${T}/${SETTINGS}" '"note": "café ☃ 😀 \"q\" \\ / \u0001"' "HH-02 non-ASCII stays as UTF-8 and control characters as \\u00xx"
assert_eq "$(tail -c1 "${T}/${SETTINGS}" | od -An -c | tr -d ' ')" '\n' "HH-02 the file's final newline is kept"
assert_eq "$(manifest_hooks "$T" claude-code | grep -c '"created": false')" 1 "HH-02 an existing file is recorded created false"
BEFORE="$(sha_of "${T}/${SETTINGS}")"; MBEFORE="$(sha_of "${T}/.aid/.aid-manifest.json")"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
assert_eq "$(sha_of "${T}/${SETTINGS}")" "$BEFORE" "HH-02 a second add changes no byte of the settings file"
run_aid update --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
assert_eq "$(sha_of "${T}/${SETTINGS}")" "$BEFORE" "HH-02 update changes no byte of the settings file"
assert_eq "$(count_aid_handlers "${T}/${SETTINGS}")" 1 "HH-02 still one AID handler after add and update"
assert_eq "$(manifest_hooks "$T" claude-code | grep -c '"created": false')" 1 "HH-02 update keeps the manifest record"
# A file without a final newline keeps that state, and an unchanged merge writes nothing (mtime stable).
T2="$(new_target hh02b)"; mkdir -p "${T2}/.claude"
printf '{"hooks":{"Stop":[]},"x":1}' > "${T2}/${SETTINGS}"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T2" >/dev/null 2>&1
assert_eq "$(tail -c1 "${T2}/${SETTINGS}" | od -An -c | tr -d ' ')" '}' "HH-02 a file with no final newline stays without one"
assert_eq "$(count_aid_handlers "${T2}/${SETTINGS}")" 1 "HH-02 an empty Stop list takes the AID group"
OLD_MTIME="$(stat -c %Y "${T2}/${SETTINGS}" 2>/dev/null || stat -f %m "${T2}/${SETTINGS}")"
sleep 1
run_aid update --from-bundle "$BUNDLE" --target "$T2" >/dev/null 2>&1
assert_eq "$(stat -c %Y "${T2}/${SETTINGS}" 2>/dev/null || stat -f %m "${T2}/${SETTINGS}")" "$OLD_MTIME" "HH-02 a run that changes nothing writes nothing"
# A hand-formatted file that already holds the AID group is not reformatted.
T3="$(new_target hh02c)"; mkdir -p "${T3}/.claude"
printf '{\n    "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "bash \\"${CLAUDE_PROJECT_DIR}/.aid/runtime/scripts/hooks/aid-question-form.sh\\"", "timeout": 30}]}]}\n}\n' > "${T3}/${SETTINGS}"
HAND="$(sha_of "${T3}/${SETTINGS}")"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T3" >/dev/null 2>&1
assert_eq "$(sha_of "${T3}/${SETTINGS}")" "$HAND" "HH-02 an already-merged hand-formatted file is left byte for byte"
# A user's own Stop group before and an AID group left over from an older path are both handled.
T4="$(new_target hh02d)"; mkdir -p "${T4}/.claude"
cat > "${T4}/${SETTINGS}" <<'JSON'
{"hooks": {"Stop": [
  {"hooks": [{"type": "command", "command": "bash \"/old/place/.aid/runtime/scripts/hooks/aid-old-thing.sh\""}, {"type": "command", "command": "echo mine"}]},
  {"hooks": [{"type": "command", "command": "bash \"/x/.aid/runtime/scripts/hooks/aid-question-form.sh\""}]}
]}}
JSON
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T4" >/dev/null 2>&1
assert_eq "$(py 'import json,sys
d=json.load(open(sys.argv[1]))
print([[h["command"] for h in g["hooks"]] for g in d["hooks"]["Stop"]])' "${T4}/${SETTINGS}")" \
    "[['echo mine'], ['${COMMAND_STR}']]" "HH-02 stale AID handlers are stripped, the user handler stays, an emptied group is dropped"

# --- HH-03 a file AID will not edit ------------------------------------------------------------
refusal_case() {
    local id="$1" contents="$2" label="$3" reason="${4:-}" t out rc before
    t="$(new_target "$id")"; mkdir -p "${t}/.claude"
    printf '%s' "$contents" > "${t}/${SETTINGS}"
    before="$(sha_of "${t}/${SETTINGS}")"
    out="$(run_aid add claude-code --from-bundle "$BUNDLE" --target "$t" 2>&1)"; rc=$?
    assert_exit_zero "$rc" "${id} ${label}: the install still succeeds"
    assert_eq "$(sha_of "${t}/${SETTINGS}")" "$before" "${id} ${label}: the file is untouched"
    assert_output_contains "$out" "WARN: aid: .claude/settings.json was left untouched" "${id} ${label}: one warning names the file"
    assert_eq "$(manifest_hooks "$t" claude-code)" "null" "${id} ${label}: nothing is recorded"
    assert_file_exists "${t}/.aid/runtime/scripts/hooks/aid-question-form.sh" "${id} ${label}: the rest of the install is in place"
    if [[ -n "$reason" ]]; then
        assert_output_contains "$out" "WARN: aid: .claude/settings.json was left untouched (${reason}). Fix the file, or remove it, then run 'aid update' to add the AID hook." "${id} ${label}: the warning gives the reason '${reason}'"
    fi
    assert_eq "$(find "${t}/.claude" -maxdepth 1 \( -name '*.tmp' -o -name '.settings.tmp.*' \) | wc -l | tr -d ' ')" 0 "${id} ${label}: no stray file is left in .claude"
}
refusal_case HH-03a '{ not json' "unparseable" "is not valid JSON"
refusal_case HH-03b '[1, 2]' "not an object" "is not a JSON object"
refusal_case HH-03c '{"hooks": []}' "hooks of the wrong type" "has a hooks entry that is not an object"
refusal_case HH-03d '{"hooks": {"Stop": {}}}' "hooks.Stop of the wrong type" "has a hooks.Stop entry that is not a list"
refusal_case HH-03e '{"timeout": 1.5}' "a non-integer number" "contains a number that is not an integer"
refusal_case HH-03f '{"Env": 1, "env": 2}' "two keys that differ only in case" "has two keys that differ only in case"
refusal_case HH-03g '' "an empty file" "is not valid JSON"
refusal_case HH-03h $'\xef\xbb\xbf{}' "a BOM" "is not valid JSON"
refusal_case HH-03i '{"a": NaN}' "a NaN constant" "is not valid JSON"
refusal_case HH-03j '{"a": "\ud800"}' "a lone surrogate" "holds text that cannot be written as UTF-8"
# Nesting: 100 levels are edited, 101 are refused, whatever else the text holds.
deep_json() { python3 -I -c 'import sys; n = int(sys.argv[1]); print("{\"a\":" * n + "1" + "}" * n, end="")' "$1"; }
refusal_case HH-03k "$(deep_json 101)" "101 levels of nesting" "is nested too deeply"
refusal_case HH-03l "$(python3 -I -c 'print("[" * 990 + "]" * 990, end="")')" "990 levels of nesting" "is nested too deeply"
T="$(new_target hh03m)"; mkdir -p "${T}/.claude"; printf '%s' "$(deep_json 100)" > "${T}/${SETTINGS}"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
assert_eq "$(count_aid_handlers "${T}/${SETTINGS}")" 1 "HH-03m 100 levels of nesting are edited"
T="$(new_target hh03-update)"; mkdir -p "${T}/.claude"; printf '{}\n' > "${T}/${SETTINGS}"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
printf '{ broken' > "${T}/${SETTINGS}"
OUT="$(run_aid update --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-03 update over a file that became unparseable succeeds"
assert_output_contains "$OUT" "was left untouched" "HH-03 update warns"
assert_eq "$(manifest_hooks "$T" claude-code | grep -c '"name": "aid-question-form"')" 1 "HH-03 update keeps the record the manifest already held"

# --- HH-04 remove ---------------------------------------------------------------------------------
T="$(new_target hh04-user)"; mkdir -p "${T}/.claude"
printf '{\n  "permissions": {"allow": ["Bash(ls:*)"]},\n  "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "echo mine"}]}]}\n}\n' > "${T}/${SETTINGS}"
run_aid add claude-code,cursor --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
OUT="$(run_aid remove claude-code --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-04 remove claude-code succeeds"
assert_file_exists "${T}/${SETTINGS}" "HH-04 a file with user entries stays"
assert_eq "$(count_aid_handlers "${T}/${SETTINGS}")" 0 "HH-04 the AID handler is gone"
assert_eq "$(py 'import json,sys
d=json.load(open(sys.argv[1]))
print(d["permissions"], [h["command"] for g in d["hooks"]["Stop"] for h in g["hooks"]])' "${T}/${SETTINGS}")" \
    "{'allow': ['Bash(ls:*)']} ['echo mine']" "HH-04 the user hook and keys stay"
assert_eq "$(manifest_hooks "$T" cursor)" "null" "HH-04 the other tool's manifest entry is untouched"
T="$(new_target hh04-created)"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
run_aid update --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
run_aid remove claude-code --target "$T" >/dev/null 2>&1; RC=$?
assert_exit_zero "$RC" "HH-04 remove of a hook-only install succeeds"
[[ ! -e "${T}/${SETTINGS}" ]] && pass "HH-04 a file AID created, left as {}, is deleted" || fail "HH-04 a file AID created, left as {}, is deleted"
[[ ! -e "${T}/.claude" ]] && pass "HH-04 the emptied .claude directory goes too" || fail "HH-04 the emptied .claude directory goes too"
# AID created the file, the user added a key later: only the handler leaves.
T="$(new_target hh04-grown)"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
py 'import json,sys
p=sys.argv[1]; d=json.load(open(p)); d["model"]="opus"; open(p,"w").write(json.dumps(d,indent=2)+"\n")' "${T}/${SETTINGS}"
run_aid remove claude-code --target "$T" >/dev/null 2>&1
assert_eq "$(py 'import json,sys
print(json.load(open(sys.argv[1])))' "${T}/${SETTINGS}")" "{'model': 'opus'}" "HH-04 a created file that grew keeps the user's key; empty hooks keys are dropped"

# --- HH-05 record missing, marker present ----------------------------------------------------------
T="$(new_target hh05)"
run_aid add claude-code,codex --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
py 'import json,sys
p=sys.argv[1]; d=json.load(open(p)); d["tools"]["claude-code"].pop("hooks"); open(p,"w").write(json.dumps(d,indent=2)+"\n")' "${T}/.aid/.aid-manifest.json"
assert_eq "$(manifest_hooks "$T" claude-code)" "null" "HH-05 fixture: the manifest has no hook record"
run_aid remove claude-code --target "$T" >/dev/null 2>&1; RC=$?
assert_exit_zero "$RC" "HH-05 remove without a record succeeds"
assert_eq "$(count_aid_handlers "${T}/${SETTINGS}")" 0 "HH-05 the AID handler is stripped by its path marker"
assert_eq "$(py 'import json,sys
print(json.load(open(sys.argv[1])))' "${T}/${SETTINGS}")" "{}" "HH-05 with no record the emptied file is kept as {} (created is unknown)"
# A settings file with no AID handler is never parsed or refused on remove.
T="$(new_target hh05b)"; run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
printf '{ not json but no marker' > "${T}/${SETTINGS}"
OUT="$(run_aid remove claude-code --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-05 remove leaves a settings file without the marker alone"
assert_output_not_contains "$OUT" "WARN" "HH-05 and does not warn about it"
assert_eq "$(cat "${T}/${SETTINGS}")" "{ not json but no marker" "HH-05 the unrelated file is byte for byte"
# A marker-bearing file that cannot be edited on remove: warn, keep, remove still completes.
T="$(new_target hh05c)"; run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
printf '{ broken /.aid/runtime/scripts/hooks/aid-x' > "${T}/${SETTINGS}"
OUT="$(run_aid remove claude-code --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-05 remove with an uneditable settings file succeeds"
assert_output_contains "$OUT" "was left untouched" "HH-05 and warns"
assert_eq "$(cat "${T}/${SETTINGS}")" "{ broken /.aid/runtime/scripts/hooks/aid-x" "HH-05 and leaves the file"

# --- HH-06 tools that declare no hook ------------------------------------------------------------
T="$(new_target hh06)"
OUT="$(run_aid add cursor,codex --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-06 add cursor,codex succeeds"
assert_output_not_contains "$OUT" "Hook:" "HH-06 no hook line"
[[ ! -e "${T}/.claude/settings.json" && ! -e "${T}/.cursor/settings.json" && ! -e "${T}/.codex/settings.json" ]] \
    && pass "HH-06 no settings file for cursor or codex" || fail "HH-06 no settings file for cursor or codex"
assert_eq "$(manifest_hooks "$T" cursor)/$(manifest_hooks "$T" codex)" "null/null" "HH-06 no hook records"
assert_eq "$(grep -c '"hooks"' "${T}/.aid/.aid-manifest.json")" 0 "HH-06 the manifest has no hooks member at all"

# --- HH-07 update on an install that lacks the hook ----------------------------------------------
T="$(new_target hh07)"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
rm -f "${T}/${SETTINGS}"
py 'import json,sys
p=sys.argv[1]; d=json.load(open(p)); d["tools"]["claude-code"].pop("hooks"); open(p,"w").write(json.dumps(d,indent=2)+"\n")' "${T}/.aid/.aid-manifest.json"
OUT="$(run_aid update --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-07 update succeeds"
assert_output_contains "$OUT" "Hook: aid-question-form (Stop) in .claude/settings.json" "HH-07 update reports the hook"
assert_eq "$(count_aid_handlers "${T}/${SETTINGS}")" 1 "HH-07 update adds the hook to an install without it"
assert_eq "$(manifest_hooks "$T" claude-code | grep -c '"created": true')" 1 "HH-07 and records it (the file was absent, so created true)"
# A project added with another tool first gets the hook when claude-code joins it.
T="$(new_target hh07b)"
run_aid add cursor --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
assert_eq "$(count_aid_handlers "${T}/${SETTINGS}")" 1 "HH-07 adding claude-code to a cursor project places the hook"
assert_eq "$(manifest_hooks "$T" cursor)" "null" "HH-07 and cursor's entry stays hook-free"
run_aid add codex --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
assert_eq "$(manifest_hooks "$T" claude-code | grep -c '"name": "aid-question-form"')" 1 "HH-07 adding another tool keeps claude-code's record"

# --- HH-08 no python3 ---------------------------------------------------------------------------
NOPY="${TMP}/nopy-bin"; mkdir -p "$NOPY"
for c in bash sh awk gawk mawk sed grep egrep find xargs sort uniq cut tr head tail cat cp mv rm mkdir rmdir mktemp date sha256sum shasum tar gzip gunzip cmp diff od dirname basename wc ls ln chmod touch env uname stat readlink realpath tee printf true false sleep id git tput getconf expr seq; do
    src="$(command -v "$c" 2>/dev/null)" && [[ "$src" == /* ]] && ln -sf "$src" "$NOPY/$c"
done
if PATH="$NOPY" command -v python3 >/dev/null 2>&1; then fail "HH-08 fixture: PATH lacks python3"; else pass "HH-08 fixture: PATH lacks python3"; fi
T="$(new_target hh08)"
OUT="$(PATH="$NOPY" HOME="$HOME_DIR" AID_HOME="$AID_HOME_DIR" AID_NO_UPDATE_CHECK=1 TMPDIR="$TMP" bash "${REPO_ROOT}/bin/aid" add claude-code --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-08 add without python3 succeeds"
assert_output_contains "$OUT" "WARN: aid: python3 not found; .claude/settings.json was not changed" "HH-08 one warning"
[[ ! -e "${T}/${SETTINGS}" ]] && pass "HH-08 nothing is written" || fail "HH-08 nothing is written"
assert_eq "$(grep -c '"hooks"' "${T}/.aid/.aid-manifest.json")" 0 "HH-08 nothing is recorded"
# remove without python3 keeps the file and warns; the removal completes.
T="$(new_target hh08b)"
run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" >/dev/null 2>&1
OUT="$(PATH="$NOPY" HOME="$HOME_DIR" AID_HOME="$AID_HOME_DIR" AID_NO_UPDATE_CHECK=1 TMPDIR="$TMP" bash "${REPO_ROOT}/bin/aid" remove claude-code --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-08 remove without python3 succeeds"
assert_output_contains "$OUT" "python3 not found; .claude/settings.json was not changed" "HH-08 remove warns that the settings file stays"
assert_eq "$(count_aid_handlers "${T}/${SETTINGS}")" 1 "HH-08 the settings file is left as it was"

# --- HH-09 malformed descriptors are refused (see also test-release-staging-descriptors.sh) ---
refuse_descriptor() {
    local id="$1" contents="$2" needle="$3" extract member list artifact digest t out rc
    extract="${TMP}/ex-${id}"; rm -rf "$extract"; mkdir -p "$extract" "${TMP}/b-${id}"
    cp -a "${BUNDLE}/." "${TMP}/b-${id}/"
    artifact="$(ls "${TMP}/b-${id}"/aid-claude-code-v*.tar.gz)"
    tar -xzf "$artifact" -C "$extract"
    printf '%s' "$contents" > "${extract}/aid-tool.conf"
    tar -tzf "$artifact" > "${TMP}/list-${id}"
    tar --hard-dereference -czf "${artifact}.new" -C "$extract" -T "${TMP}/list-${id}" && mv "${artifact}.new" "$artifact"
    digest="$(sha_of "$artifact")"
    awk -v name="$(basename "$artifact")" -v hash="$digest" '$2 == name {$1 = hash} {print}' "${TMP}/b-${id}/SHA256SUMS" > "${TMP}/b-${id}/SHA256SUMS.new"
    mv "${TMP}/b-${id}/SHA256SUMS.new" "${TMP}/b-${id}/SHA256SUMS"
    t="$(new_target "$id")"
    out="$(run_aid add claude-code --from-bundle "${TMP}/b-${id}" --target "$t" 2>&1)"; rc=$?
    assert_exit_eq "$rc" 1 "${id} refused"
    assert_output_contains "$out" "$needle" "${id} diagnostic"
    [[ ! -e "${t}/.aid" ]] && pass "${id} nothing installed" || fail "${id} nothing installed"
}
refuse_descriptor HH-09a $'tool=claude-code\nhook_settings=.claude/other.json\nhook=Stop:aid-question-form\n' "invalid hook_settings"
refuse_descriptor HH-09b $'tool=claude-code\nhook_settings=.claude/settings.json\nhook=Stop:question-form\n' "invalid hook 'Stop:question-form'"
refuse_descriptor HH-09c $'tool=claude-code\nhook_settings=.claude/settings.json\nhook=Pre:aid-question-form\n' "invalid hook 'Pre:aid-question-form'"
refuse_descriptor HH-09d $'tool=claude-code\nhook=Stop:aid-question-form\n' "hook needs hook_settings"
refuse_descriptor HH-09f $'tool=claude-code\nhook_settings=.claude/settings.json\nhook=Stop:aid-x-\n' "invalid hook 'Stop:aid-x-'"
refuse_descriptor HH-09g $'tool=claude-code\nhook_settings=.claude/settings.json\nhook=Stop:aid--x\n' "invalid hook 'Stop:aid--x'"
refuse_descriptor HH-09e $'tool=claude-code\nhook_settings=.claude/settings.json\nhook_settings=.claude/settings.json\nhook=Stop:aid-question-form\n' "hook_settings may appear only once"

# --- HH-11 a symbolic link at the settings path is never replaced or deleted -----------------------
T="$(new_target hh11)"; mkdir -p "${T}/.claude" "${T}/shared"
LINK_BODY='{"permissions": {"allow": ["Bash(ls:*)"]}, "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "bash \"x/.aid/runtime/scripts/hooks/aid-old.sh\""}]}]}}'
printf '%s' "$LINK_BODY" > "${T}/shared/s.json"
ln -s ../shared/s.json "${T}/${SETTINGS}"
LINK_SHA="$(sha_of "${T}/shared/s.json")"
OUT="$(run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-11 add over a symbolic link succeeds"
assert_output_contains "$OUT" "WARN: aid: .claude/settings.json was left untouched (is a symbolic link)." "HH-11 add warns with the reason"
assert_output_not_contains "$OUT" "Hook:" "HH-11 add prints no Hook line"
[[ -L "${T}/${SETTINGS}" && "$(readlink "${T}/${SETTINGS}")" == "../shared/s.json" ]] && pass "HH-11 the link is still a link to the same file" || fail "HH-11 the link is still a link to the same file"
assert_eq "$(sha_of "${T}/shared/s.json")" "$LINK_SHA" "HH-11 the file it points to is unchanged"
assert_eq "$(manifest_hooks "$T" claude-code)" "null" "HH-11 nothing is recorded"
assert_eq "$(find "${T}/.claude" "${T}/shared" -maxdepth 1 \( -name '*.tmp' -o -name '.settings.tmp.*' \) | wc -l | tr -d ' ')" 0 "HH-11 no temp file is left next to the link or its target"
OUT="$(run_aid update --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-11 update over a symbolic link succeeds"
assert_output_contains "$OUT" "(is a symbolic link)" "HH-11 update warns too"
[[ -L "${T}/${SETTINGS}" ]] && pass "HH-11 update leaves the link" || fail "HH-11 update leaves the link"
OUT="$(run_aid remove claude-code --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-11 remove over a symbolic link succeeds"
assert_output_contains "$OUT" "WARN: aid: .claude/settings.json was left untouched (is a symbolic link). Remove its entries whose command holds /.aid/runtime/scripts/hooks/aid- by hand." "HH-11 remove warns with the reason"
[[ -L "${T}/${SETTINGS}" && "$(readlink "${T}/${SETTINGS}")" == "../shared/s.json" ]] && pass "HH-11 remove neither replaces nor deletes the link" || fail "HH-11 remove neither replaces nor deletes the link"
assert_eq "$(sha_of "${T}/shared/s.json")" "$LINK_SHA" "HH-11 and the file it points to is unchanged"
# A dangling link is a link too.
T="$(new_target hh11b)"; mkdir -p "${T}/.claude"; ln -s ../nowhere.json "${T}/${SETTINGS}"
OUT="$(run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-11 add over a dangling link succeeds"
assert_output_contains "$OUT" "(is a symbolic link)" "HH-11 a dangling link is refused as a link"
[[ -L "${T}/${SETTINGS}" && ! -e "${T}/nowhere.json" ]] && pass "HH-11 a dangling link is not followed or replaced" || fail "HH-11 a dangling link is not followed or replaced"

# --- HH-12 a directory (or any non-regular file) at the settings path -------------------------------
T="$(new_target hh12)"; mkdir -p "${T}/${SETTINGS}"
OUT="$(run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-12 add over a directory succeeds"
assert_output_contains "$OUT" "WARN: aid: .claude/settings.json was left untouched (is not a regular file)." "HH-12 add warns with the reason"
assert_output_not_contains "$OUT" "Hook:" "HH-12 add prints no Hook line"
assert_eq "$(manifest_hooks "$T" claude-code)" "null" "HH-12 nothing is recorded"
assert_eq "$(find "${T}/${SETTINGS}" -mindepth 1 | wc -l | tr -d ' ')" 0 "HH-12 nothing goes into the directory"
assert_eq "$(find "${T}/.claude" -maxdepth 1 \( -name '*.tmp' -o -name '.settings.tmp.*' \) | wc -l | tr -d ' ')" 0 "HH-12 no temp file is left next to it"
OUT="$(run_aid update --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-12 update over a directory succeeds"
OUT="$(run_aid remove claude-code --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-12 remove over a directory succeeds"
[[ -d "${T}/${SETTINGS}" ]] && pass "HH-12 remove leaves the directory" || fail "HH-12 remove leaves the directory"

# --- HH-13 a write that fails leaves the original file exactly as it was ----------------------------
# Read-only directory: the temp file cannot be created. (root ignores the mode, so the case is skipped as root.)
if [[ "$(id -u)" != 0 ]]; then
    T="$(new_target hh13)"; mkdir -p "${T}/.claude"; printf '{"x": 1}\n' > "${T}/${SETTINGS}"
    BEFORE="$(sha_of "${T}/${SETTINGS}")"; chmod a-w "${T}/.claude"
    OUT="$(run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
    chmod u+w "${T}/.claude"
    assert_exit_zero "$RC" "HH-13 add into a read-only .claude succeeds"
    assert_output_contains "$OUT" "(cannot be written)." "HH-13 add warns with the reason"
    assert_output_not_contains "$OUT" "Hook:" "HH-13 and prints no Hook line"
    assert_eq "$(sha_of "${T}/${SETTINGS}")" "$BEFORE" "HH-13 the original file is byte for byte"
    assert_eq "$(manifest_hooks "$T" claude-code)" "null" "HH-13 nothing is recorded"
else
    pass "HH-13 (skipped as root: a read-only directory does not stop root)"
fi
# A failing replace: the merge's python3 is wrapped so os.replace raises, the case the temp file must not survive.
T="$(new_target hh13b)"; mkdir -p "${T}/.claude"; printf '{"x": 1}\n' > "${T}/${SETTINGS}"
BEFORE="$(sha_of "${T}/${SETTINGS}")"
FAILPY="${TMP}/failpy-bin"; mkdir -p "$FAILPY"
cat > "${FAILPY}/failreplace.py" <<'PYWRAP'
import os, sys
sys.argv = sys.argv[1:]
src = sys.stdin.read()
if "scripts/hooks/aid-" in src:  # only the settings-hook merge fails; every other python3 call is untouched
    def _fail(*args, **kwargs):
        raise OSError("replace refused")
    os.replace = _fail
exec(compile(src, "<stdin>", "exec"))
PYWRAP
REALPY="$(command -v python3)"
printf '#!/usr/bin/env bash\nif [[ "$1" == - ]]; then exec "%s" "%s" "$@"; fi\nexec "%s" "$@"\n' "$REALPY" "${FAILPY}/failreplace.py" "$REALPY" > "${FAILPY}/python3"
chmod +x "${FAILPY}/python3"
OUT="$(PATH="${FAILPY}:$PATH" run_aid add claude-code --from-bundle "$BUNDLE" --target "$T" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-13 add with a failing replace succeeds"
assert_output_contains "$OUT" "(cannot be written)." "HH-13 a failing replace warns with the reason"
assert_output_not_contains "$OUT" "Hook:" "HH-13 and prints no Hook line"
assert_eq "$(sha_of "${T}/${SETTINGS}")" "$BEFORE" "HH-13 a failing replace leaves the original byte for byte"
assert_eq "$(find "${T}/.claude" -maxdepth 1 \( -name '*.tmp' -o -name '.settings.tmp.*' \) | wc -l | tr -d ' ')" 0 "HH-13 and removes its temp file"
assert_eq "$(manifest_hooks "$T" claude-code)" "null" "HH-13 and records nothing"

# --- HH-10 the generator and the shipped descriptor agree ---------------------------------------
assert_file_contains "${REPO_ROOT}/profiles/claude-code/aid-tool.conf" "hook_settings=.claude/settings.json" "HH-10 the shipped descriptor names the settings file"
assert_file_contains "${REPO_ROOT}/profiles/claude-code/aid-tool.conf" "hook=Stop:aid-question-form" "HH-10 the shipped descriptor names the hook"
for other in codex cursor copilot-cli antigravity; do
    assert_file_not_contains "${REPO_ROOT}/profiles/${other}/aid-tool.conf" "hook" "HH-10 ${other} declares no hook"
done
GEN="${REPO_ROOT}/.claude/skills/generate-profile/scripts"
OUT="$(python3 "${GEN}/aid_profile.py" --self-test 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-10 aid_profile self-test passes"
OUT="$(python3 "${GEN}/render.py" --self-test --canonical-root "$REPO_ROOT" 2>&1)"; RC=$?
assert_exit_zero "$RC" "HH-10 render self-test passes"

test_summary
