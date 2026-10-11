#!/usr/bin/env bash
# test-shared-install.sh -- task-017 shared install contract.
#
# COVERS: bin/aid
# COVERS: lib/aid-install-core.sh
# COVERS: release.sh
# COVERS: tests/lib/bundle.sh
# COVERS: canonical/skills
# COVERS: canonical/aid
#
# One stage-only subject bundle is shared by fresh per-tool fixture repos (S1).
# HOME and USERPROFILE are pinned; every install target, mutated bundle and fixture
# is under mktemp. Assertions inspect fixture output in batches (S2).
# Usage: HOME=$(mktemp -d) bash tests/canonical/test-shared-install.sh [--verbose|--self-mutate]
# Exit codes: 0 all assertions pass / 1 any assertion or setup failure.
set -uo pipefail
VERBOSE=0 SELF_MUTATE=0
[[ "${1:-}" == --verbose ]] && VERBOSE=1
[[ "${1:-}" == --self-mutate ]] && SELF_MUTATE=1
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
source "${HERE}/../lib/assert.sh"
source "${HERE}/../lib/bundle.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="${TMP}/home" USERPROFILE="${TMP}/home" AID_NO_UPDATE_CHECK=1
mkdir -p "$HOME"
STAGE="${TMP}/stage"; mkdir -p "$STAGE"
if ! aid_test_stage_bundle "$STAGE" >"${TMP}/stage.log" 2>&1; then cat "${TMP}/stage.log" >&2; exit 1; fi
VERSION="$(tr -d '[:space:]' < "$REPO/VERSION")"
SHARED="$STAGE/aid-shared-v${VERSION}.tar.gz"
[[ -f "$SHARED" ]] || { echo "ERROR: missing shared payload: $SHARED" >&2; exit 1; }
sha() { sha256sum "$1" | awk '{print $1}'; }
run_aid() { local target="$1" state="$2"; shift 2; AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" "$@" --target "$target" --from-bundle "$STAGE"; }
same_tree() {
    local src="$1" dst="$2" f rel n1 n2
    while IFS= read -r -d '' f; do
        rel="${f#"$src/"}"
        [[ "$rel" =~ (^|/)\.([^/]+)(/|$) || "/$rel/" == */node_modules/* || "/$rel/" == */.git/* ]] && continue
        [[ -f "$dst/$rel" ]] && cmp -s "$f" "$dst/$rel" || return 1
    done < <(find "$src" -type f -print0)
    while IFS= read -r -d '' f; do
        rel="${f#"$dst/"}"
        [[ "$rel" =~ (^|/)\.([^/]+)(/|$) || "/$rel/" == */node_modules/* || "/$rel/" == */.git/* ]] && continue
        [[ -f "$src/$rel" ]] || return 1
    done < <(find "$dst" -type f -print0)
    return 0
}
skills_match() {
    local src="$1" dst="$2" f rel a b
    while IFS= read -r -d '' f; do rel="${f#"$src/"}"; [[ -f "$dst/$rel" ]] && cmp -s "$f" "$dst/$rel" || return 1; done < <(find "$src" -type f -print0)
    a="$(find "$src" -type f | wc -l | tr -d ' ')"; b="$(find "$dst" -type f | wc -l | tr -d ' ')"; [[ "$a" == "$b" ]]
}
count_line() { awk -v x="$2" 'index($0,x){n++} END{print n+0}' "$1"; }
root_user_content() {
    local input="$1" output="$2"
    awk '
        $0 == "<!-- AID:BEGIN -->" || $0 == "<!-- AID:END -->" ||
        $0 == "<!-- Managed by the AID CLI. Do not edit between the AID markers. -->" ||
        $0 == "@AGENTS.md" || $0 == "@.aid/runtime/rules.md" ||
        $0 == "Before acting, read and follow `.aid/runtime/rules.md` (AID rules)." { next }
        { print }
    ' "$input" > "$output"
}
no_aid_dirs() { local r="$1" d; for d in .claude .codex .cursor .github .agent; do [[ ! -d "$r/$d/aid" ]] || return 1; done; }
echo '== test-shared-install.sh =='

# AC-3 and AC-7 per tool. Exactly one add/update/remove lifecycle per fresh target.
TOOLS=(claude-code cursor codex copilot-cli antigravity)
for tool in "${TOOLS[@]}"; do
    target="$TMP/repo-$tool"; state="$TMP/state-$tool"
    mkdir -p "$target/.aid/knowledge" "$target/.aid/works/w" "$target/.aid/design" "$state"
    printf 'knowledge seed\n' > "$target/.aid/knowledge/x.md"
    printf 'state seed\n' > "$target/.aid/works/w/STATE.yml"
    printf 'design seed\n' > "$target/.aid/design/d.md"
    before="$(sha "$target/.aid/knowledge/x.md") $(sha "$target/.aid/works/w/STATE.yml") $(sha "$target/.aid/design/d.md")"
    [[ "$tool" != cursor ]] || printf 'user-attribute: preserve\n' > "$target/.gitattributes"
    out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add "$tool" --target "$target" --from-bundle "$STAGE" 2>&1)"; rc=$?
    assert_exit_zero "$rc" "AC-3 $tool fresh add succeeds"
    if [[ $rc -ne 0 ]]; then [[ $VERBOSE -eq 1 ]] && printf '%s\n' "$out"; continue; fi
    if [[ "$tool" == cursor ]]; then
        assert_file_contains "$target/.gitattributes" 'user-attribute: preserve' 'AC-7 cursor attributes preserve user line'
        assert_file_contains "$target/.gitattributes" '# >>> AID managed' 'AC-7 cursor attributes contain managed block'
        for x in '.agents/skills/aid-*/** text eol=lf' '.claude/skills/aid-*/** text eol=lf' '.aid/runtime/** text eol=lf'; do
            assert_file_contains "$target/.gitattributes" "$x" "AC-7 cursor attributes include $x"
        done
    fi
    if skills_match "$REPO/canonical/skills" "$target/.agents/skills"; then pass "AC-3 $tool installed skills equal canonical byte-for-byte"; else fail "AC-3 $tool installed skills equal canonical byte-for-byte"; fi
    expected="$(find "$REPO/canonical/skills" -type f | wc -l | tr -d ' ')"
    actual="$(find "$target/.agents/skills" -type f -path '*/aid-*' | wc -l | tr -d ' ')"
    assert_eq "$actual" "$expected" "AC-3 $tool aid-* file count equals canonical"
    if [[ "$tool" == claude-code ]]; then
        if skills_match "$REPO/canonical/skills" "$target/.claude/skills"; then pass 'AC-3 claude-code mirror equals canonical byte-for-byte'; else fail 'AC-3 claude-code mirror equals canonical byte-for-byte'; fi
    fi
    if same_tree "$REPO/canonical/aid/scripts" "$target/.aid/runtime/scripts" && same_tree "$REPO/canonical/aid/templates" "$target/.aid/runtime/templates"; then pass "AC-7 $tool runtime scripts/templates equal canonical with exclusions"; else fail "AC-7 $tool runtime scripts/templates equal canonical with exclusions"; fi
    if cmp -s "$REPO/canonical/aid/rules.md" "$target/.aid/runtime/rules.md"; then pass "AC-7 $tool rules.md equals canonical"; else fail "AC-7 $tool rules.md equals canonical"; fi
    if no_aid_dirs "$target"; then pass "AC-7 $tool has no tool-root aid/ directory"; else fail "AC-7 $tool has no tool-root aid/ directory"; fi
    after="$(sha "$target/.aid/knowledge/x.md") $(sha "$target/.aid/works/w/STATE.yml") $(sha "$target/.aid/design/d.md")"
    assert_eq "$after" "$before" "AC-7 $tool add preserves user .aid state"
    mkdir -p "$target/.aid/runtime/scripts/summarize/node_modules"
    printf dep > "$target/.aid/runtime/scripts/summarize/node_modules/x.js"
    printf stray > "$target/.aid/runtime/stray-task017"
    out="$(run_aid "$target" "$state" update 2>&1)"; rc=$?
    assert_exit_zero "$rc" "AC-7 $tool update succeeds"
    [[ ! -e "$target/.aid/runtime/stray-task017" ]] && pass "AC-7 $tool update prunes stray runtime file" || fail "AC-7 $tool update prunes stray runtime file"
    [[ -f "$target/.aid/runtime/scripts/summarize/node_modules/x.js" ]] && pass "AC-7 $tool update preserves node_modules file" || fail "AC-7 $tool update preserves node_modules file"
    if ! find "$target/.aid/.trash" -type f -path '*/node_modules/*' -print -quit 2>/dev/null | grep -q .; then pass "AC-7 $tool trashes no node_modules content"; else fail "AC-7 $tool trashes no node_modules content"; fi
    status="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" status --target "$target" 2>&1)"; rc=$?
    assert_exit_zero "$rc" "AC-7 $tool status succeeds"
    assert_output_not_contains "$status" 'extra:' "AC-7 $tool status ignores node_modules file"
    after="$(sha "$target/.aid/knowledge/x.md") $(sha "$target/.aid/works/w/STATE.yml") $(sha "$target/.aid/design/d.md")"
    assert_eq "$after" "$before" "AC-7 $tool update preserves user .aid state"
    out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" remove "$tool" --target "$target" 2>&1)"; rc=$?
    assert_exit_zero "$rc" "AC-7 $tool remove succeeds"
    after="$(sha "$target/.aid/knowledge/x.md") $(sha "$target/.aid/works/w/STATE.yml") $(sha "$target/.aid/design/d.md")"
    assert_eq "$after" "$before" "AC-7 $tool remove preserves user .aid state"
done

# Negative control: mutate an extracted staged skill, re-pack, and omit SHA256SUMS.
NEG="$TMP/negative-stage"; UNPACK="$TMP/unpacked"; mkdir -p "$NEG" "$UNPACK"
tar -xzf "$SHARED" -C "$UNPACK"
mutant="$(find "$UNPACK/skills" -type f -name SKILL.md -print -quit)"
[[ -n "$mutant" ]] || { echo 'ERROR: staged payload contains no SKILL.md' >&2; exit 1; }
printf '\nmutation byte\n' >> "$mutant"
cp "$STAGE"/aid-*-v"$VERSION".tar.gz "$NEG/"; cp "$STAGE/aid-cli-v$VERSION.tar.gz" "$NEG/"
cp "$STAGE/aid-install-core.sh" "$NEG/"; cp "$STAGE/AidInstallCore.psm1" "$NEG/"
tar -czf "$NEG/aid-shared-v$VERSION.tar.gz" -C "$UNPACK" .
target="$TMP/repo-negative"; state="$TMP/state-negative"; mkdir -p "$target" "$state"
out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add cursor --target "$target" --from-bundle "$NEG" 2>&1)"; rc=$?
assert_exit_zero "$rc" 'AC-3 mutated payload installs with SHA256SUMS absent'
if skills_match "$REPO/canonical/skills" "$target/.agents/skills"; then fail 'negative control catches a mutated staged skill byte'; else pass 'negative control catches a mutated staged skill byte'; fi

# AC-14(a): new files for Claude, no Claude file for cursor.
target="$TMP/root-a"; state="$TMP/state-a"; mkdir -p "$target" "$state"
out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add claude-code --target "$target" --from-bundle "$STAGE" 2>&1)"; rc=$?
assert_exit_zero "$rc" 'AC-14(a) Claude add succeeds without CLAUDE.md'
printf '<!-- AID:BEGIN -->\n@AGENTS.md\n<!-- AID:END -->\n' > "$TMP/import-region"
printf '<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n@.aid/runtime/rules.md\nBefore acting, read and follow `.aid/runtime/rules.md` (AID rules).\n<!-- AID:END -->\n' > "$TMP/pointer-region"
if cmp -s "$target/CLAUDE.md" "$TMP/import-region"; then pass 'AC-14(a) missing CLAUDE.md equals LF import region'; else fail 'AC-14(a) missing CLAUDE.md equals LF import region'; fi
if cmp -s "$target/AGENTS.md" "$TMP/pointer-region"; then pass 'AC-14(a) missing AGENTS.md equals five-line pointer region'; else fail 'AC-14(a) missing AGENTS.md equals five-line pointer region'; fi
target="$TMP/root-a-cursor"; state="$TMP/state-a-cursor"; mkdir -p "$target" "$state"
out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add cursor --target "$target" --from-bundle "$STAGE" 2>&1)"; rc=$?
assert_exit_zero "$rc" 'AC-14(a) cursor add succeeds'
[[ ! -e "$target/CLAUDE.md" ]] && pass 'AC-14(a) cursor creates no CLAUDE.md' || fail 'AC-14(a) cursor creates no CLAUDE.md'

# AC-14(b): markerless user file is preserved as exact prefix; update is stable for LF/CRLF/mixed.
for ending in lf crlf mixed; do
    target="$TMP/root-b-$ending"; state="$TMP/state-b-$ending"; mkdir -p "$target" "$state"
    case "$ending" in lf) printf 'User title\n\nUser paragraph\n' > "$target/CLAUDE.md";; crlf) printf 'User title\r\n\r\nUser paragraph\r\n' > "$target/CLAUDE.md";; mixed) printf 'User title\r\n\nUser paragraph\r' > "$target/CLAUDE.md";; esac
    cp "$target/CLAUDE.md" "$TMP/b-before"
    out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add claude-code --target "$target" --from-bundle "$STAGE" 2>&1)"; rc=$?
    assert_exit_zero "$rc" "AC-14(b) $ending markerless add succeeds"
    n="$(wc -c < "$TMP/b-before")"; prefix=0; cmp -n "$n" "$TMP/b-before" "$target/CLAUDE.md" || prefix=$?
    assert_eq "$prefix" 0 "AC-14(b) $ending pre-add bytes remain exact prefix"
    h="$(sha "$target/CLAUDE.md")"; out="$(run_aid "$target" "$state" update 2>&1)"; rc=$?
    assert_exit_zero "$rc" "AC-14(b) $ending update succeeds"
    assert_eq "$(sha "$target/CLAUDE.md")" "$h" "AC-14(b) $ending update leaves bytes unchanged"
    status="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" status --target "$target" 2>&1)"
    assert_output_not_contains "$status" 'CLAUDE.md' "AC-14(b) $ending unchanged file has no false drift"
done

# Real edits drift; CRLF marker repair restores the region and is idempotent.
target="$TMP/root-b-drift"; state="$TMP/state-b-drift"; mkdir -p "$target" "$state"
printf 'outside-before\n' > "$target/CLAUDE.md"
AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add claude-code --target "$target" --from-bundle "$STAGE" >/dev/null 2>&1
python3 - "$target/CLAUDE.md" <<'PY'
import pathlib, sys
p=pathlib.Path(sys.argv[1]); b=p.read_bytes().replace(b'@AGENTS.md\n',b'@BROKEN.md\n')
p.write_bytes(b.replace(b'<!-- AID:BEGIN -->\n',b'<!-- AID:BEGIN -->\r\n').replace(b'<!-- AID:END -->\n',b'<!-- AID:END -->\r\n'))
PY
status="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" status --target "$target" 2>&1)"
assert_output_contains "$status" 'CLAUDE.md' 'AC-14(b) edited region is reported as drift'
out="$(run_aid "$target" "$state" update 2>&1)"; rc=$?
assert_exit_zero "$rc" 'AC-14(b) CRLF edited region repair succeeds'
printf 'outside-before\n' > "$TMP/b-drift-outside"
prefix=0; cmp -n "$(wc -c < "$TMP/b-drift-outside")" "$TMP/b-drift-outside" "$target/CLAUDE.md" || prefix=$?
assert_eq "$prefix" 0 'AC-14(b) repair preserves outside bytes exactly'
h="$(sha "$target/CLAUDE.md")"; out="$(run_aid "$target" "$state" update 2>&1)"; rc=$?
assert_exit_zero "$rc" 'AC-14(b) repair retry succeeds'
assert_eq "$(sha "$target/CLAUDE.md")" "$h" 'AC-14(b) CRLF repair is idempotent'

# AC-14(e): markerless user AGENTS.md retains the complete Workflow section.
target="$TMP/root-e"; state="$TMP/state-e"; mkdir -p "$target" "$state"
printf '# Project\n\n## Workflow\n\nPreserve this paragraph exactly.\n' > "$target/AGENTS.md"; cp "$target/AGENTS.md" "$TMP/e-before"
out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add claude-code --target "$target" --from-bundle "$STAGE" 2>&1)"; rc=$?
assert_exit_zero "$rc" 'AC-14(e) add succeeds with user AGENTS.md'
n="$(wc -c < "$TMP/e-before")"; prefix=0; cmp -n "$n" "$TMP/e-before" "$target/AGENTS.md" || prefix=$?
assert_eq "$prefix" 0 'AC-14(e) pre-add AGENTS bytes remain exact prefix'
assert_file_contains "$target/AGENTS.md" '## Workflow' 'AC-14(e) Workflow heading remains'
assert_file_contains "$target/AGENTS.md" 'Preserve this paragraph exactly.' 'AC-14(e) Workflow body remains'

# AC-14(f): malformed, duplicated and lone-import content repairs preserve other lines and backup.
for kind in malformed duplicate lone-import; do
    target="$TMP/root-f-$kind"; state="$TMP/state-f-$kind"; mkdir -p "$target" "$state"
    case "$kind" in
        malformed) printf 'before\n<!-- AID:BEGIN -->\nuser-after-orphan\n' > "$target/CLAUDE.md"; file=CLAUDE.md;;
        duplicate) { cat "$TMP/pointer-region"; printf 'user-between\n'; cat "$TMP/pointer-region"; } > "$target/AGENTS.md"; file=AGENTS.md;;
        lone-import) printf 'before\n@AGENTS.md\nafter\n' > "$target/CLAUDE.md"; file=CLAUDE.md;;
    esac
    cp "$target/$file" "$TMP/f-before"
    out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add claude-code --target "$target" --from-bundle "$STAGE" 2>&1)"; rc=$?
    assert_exit_zero "$rc" "AC-14(f) $kind fixture add succeeds"
    if cmp -s "$TMP/f-before" "$target/.aid/.trash/$file"; then pass "AC-14(f) $kind full pre-add backup exists"; else fail "AC-14(f) $kind full pre-add backup exists"; fi
    if [[ "$file" == CLAUDE.md ]]; then
        assert_eq "$(count_line "$target/$file" '<!-- AID:BEGIN -->') $(count_line "$target/$file" '<!-- AID:END -->') $(count_line "$target/$file" '@AGENTS.md')" '1 1 1' "AC-14(f) $kind has exactly one import region"
    else assert_eq "$(count_line "$target/$file" '<!-- AID:BEGIN -->') $(count_line "$target/$file" '<!-- AID:END -->')" '1 1' 'AC-14(f) duplicate has exactly one pointer region'; fi
    root_user_content "$TMP/f-before" "$TMP/f-user-before"
    root_user_content "$target/$file" "$TMP/f-user-after"
    if cmp -s "$TMP/f-user-before" "$TMP/f-user-after"; then pass "AC-14(f) $kind preserves every non-region line in order"; else fail "AC-14(f) $kind preserves every non-region line in order"; fi
    assert_eq "$(count_line "$target/CLAUDE.md" '@AGENTS.md')" 1 "AC-14(f) $kind has one @AGENTS.md line"
    assert_eq "$(count_line "$target/AGENTS.md" '<!-- AID:BEGIN -->')" 1 "AC-14(f) $kind has one AGENTS begin marker"
    [[ "$kind" != malformed ]] || assert_file_contains "$target/$file" 'user-after-orphan' 'AC-14(f) malformed repair preserves trailing user line'
    [[ "$kind" != duplicate ]] || assert_file_contains "$target/$file" 'user-between' 'AC-14(f) duplicate repair preserves intervening user line'
    if [[ "$kind" == lone-import ]]; then assert_file_contains "$target/$file" 'before' 'AC-14(f) lone import keeps prior user line'; assert_file_contains "$target/$file" 'after' 'AC-14(f) lone import keeps following user line'; fi
    h="$(sha "$target/$file")"; trash="$(find "$target/.aid/.trash" -type f | wc -l | tr -d ' ')"
    out="$(run_aid "$target" "$state" update 2>&1)"; rc=$?
    assert_exit_zero "$rc" "AC-14(f) $kind update succeeds"
    assert_eq "$(sha "$target/$file")" "$h" "AC-14(f) $kind update is byte-idempotent"
    assert_eq "$(find "$target/.aid/.trash" -type f | wc -l | tr -d ' ')" "$trash" "AC-14(f) $kind adds no redundant trash"
done

# Existing primitive suite has bounded tests for frozen stamp collisions and preoccupied .N suffixes.
if [[ "$SELF_MUTATE" -eq 1 ]]; then
    if HOME="$TMP/primitive-home" bash "$REPO/tests/canonical/test-install-core-primitives.sh" --verbose >"$TMP/primitives.log" 2>&1; then
        pass 'frozen-clock backup collision and preoccupied suffix byte-preservation primitives pass'
    else cat "$TMP/primitives.log" >&2; fail 'frozen-clock backup collision and preoccupied suffix byte-preservation primitives pass'; fi
    # Live control of the comparison assertion: an unmutated scratch install must
    # satisfy equality, therefore the negative assertion (! equality) must fail.
    target="$TMP/repo-negative-live"; state="$TMP/state-negative-live"; mkdir -p "$target" "$state"
    out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add cursor --target "$target" --from-bundle "$STAGE" 2>&1)"; rc=$?
    assert_exit_zero "$rc" 'negative-control liveness scratch install succeeds'
    if skills_match "$REPO/canonical/skills" "$target/.agents/skills"; then
        if ( ! skills_match "$REPO/canonical/skills" "$target/.agents/skills" ); then fail 'negative assertion fails when mutation is bypassed'; else pass 'negative assertion fails when mutation is bypassed'; fi
    else fail 'negative assertion liveness scratch is canonical'; fi
fi
test_summary
