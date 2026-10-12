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
        for x in '.agents/skills/aid-*/** text eol=lf' '.claude/skills/aid-*/** text eol=lf' '.aid/runtime/** text eol=lf' '.claude/agents/aid-* text eol=lf' '.codex/agents/aid-* text eol=lf' '.cursor/agents/aid-* text eol=lf' '.github/agents/aid-* text eol=lf' '.agent/agents/aid-* text eol=lf'; do
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

# NP: the bash CLI works end to end WITHOUT python3 (Git Bash often lacks it): add, a no-op
# update, status, remove and the v3 upgrade give the same output, tree and manifest bytes
# (installed_at masked) as the python3 run. PATH is a directory of symlinks to the needed
# tools, python3 excluded.
NOPY="$TMP/nopy-bin"; mkdir -p "$NOPY"
for c in bash sh awk gawk mawk sed grep egrep find xargs sort uniq cut tr head tail cat cp mv rm mkdir rmdir mktemp date sha256sum shasum tar gzip gunzip cmp diff od dirname basename wc ls ln chmod touch env uname stat readlink realpath tee printf true false sleep id git tput getconf expr seq; do
    src="$(command -v "$c" 2>/dev/null)" && [[ "$src" == /* ]] && ln -sf "$src" "$NOPY/$c"
done
if PATH="$NOPY" command -v python3 >/dev/null 2>&1; then fail 'NP no-python PATH really lacks python3'; else pass 'NP no-python PATH really lacks python3'; fi
np_snapshot() {  # <dir> -> "path sha" per file, installed_at masked in the manifest
    local dir="$1" f
    while IFS= read -r f; do
        if [[ "$f" == .aid/.aid-manifest.json ]]; then printf '%s manifest:%s\n' "$f" "$(sed -E 's/("installed_at": ")[^"]*"/\1<TS>"/' "$dir/$f" | sha256sum | cut -c1-64)"
        else printf '%s %s\n' "$f" "$(sha256sum < "$dir/$f" | cut -c1-64)"; fi
    done < <(cd "$dir" && find . -type f -not -path './.aid/.trash/*' -not -path './.git/*' | sed 's|^\./||' | LC_ALL=C sort)
}
np_run() {  # <label> <path-or-empty>; writes $TMP/np-<label>.{out,snap}
    local label="$1" pathv="$2" t st out snap v3
    t="$TMP/np-$label"; st="$TMP/np-$label-state"; out="$TMP/np-$label.out"; snap="$TMP/np-$label.snap"; v3="$TMP/np-$label-v3"
    mkdir -p "$t" "$st" "$v3/.cursor/aid"; : > "$out"; : > "$snap"
    step() {
        local tg="$1" fb=(--from-bundle "$STAGE"); shift
        [[ "$1" != status ]] || fb=()
        { printf '== %s\n' "$*"
          if [[ -n "$pathv" ]]; then PATH="$pathv" AID_HOME="$st" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" "$@" --target "$tg" "${fb[@]}" 2>&1
          else AID_HOME="$st" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" "$@" --target "$tg" "${fb[@]}" 2>&1; fi
          printf 'rc=%s\n' "$?"; } | sed "s|$TMP/np-$label-v3|<V3>|g; s|$TMP/np-$label|<T>|g; s|$TMP/np-[a-z]*|<T>|g" >> "$out"
        { printf '## %s\n' "$*"; np_snapshot "$tg"; } >> "$snap"
    }
    printf 'user note\n' > "$t/CLAUDE.md"
    step "$t" add cursor,claude-code
    step "$t" update
    step "$t" status
    step "$t" add codex
    step "$t" remove cursor
    step "$t" remove claude-code
    step "$t" remove codex
    # v3 upgrade: a format-2 manifest with one tool, the old tool-root layout and an old root region.
    mkdir -p "$v3/.aid" "$v3/.cursor/skills/aid-old"
    printf '{\n  "format_version": 2,\n  "aid_version": "3.0.0",\n  "installed_at": "2026-01-01T00:00:00Z",\n  "tools": {\n    "cursor": {\n      "version": "3.0.0",\n      "installed_at": "2026-01-01T00:00:00Z",\n      "paths": [\n        ".cursor/aid/x.md"\n      ]\n    }\n  }\n}\n' > "$v3/.aid/.aid-manifest.json"
    printf 'old\n' > "$v3/.cursor/aid/x.md"; printf 'skill\n' > "$v3/.cursor/skills/aid-old/SKILL.md"
    printf 'mine\n<!-- AID:BEGIN -->\nold v3 text\n<!-- AID:END -->\n' > "$v3/AGENTS.md"
    step "$v3" update
    step "$v3" update
    step "$v3" status
}
# SHA: a host with shasum but no sha256sum (macOS-like). Every region hash must use the same
# sha256 fallback as sha256_file, so the whole sequence is byte-identical to the normal run.
SHAONLY="$TMP/shaonly-bin"; mkdir -p "$SHAONLY"
for c in bash sh awk gawk mawk sed grep egrep find xargs sort uniq cut tr head tail cat cp mv rm mkdir rmdir mktemp date tar gzip gunzip cmp diff od dirname basename wc ls ln chmod touch env uname stat readlink realpath tee printf true false sleep id git tput getconf expr seq python3 pwsh; do
    src="$(command -v "$c" 2>/dev/null)" && [[ "$src" == /* ]] && ln -sf "$src" "$SHAONLY/$c"
done
REAL_SHA256SUM="$(command -v sha256sum)"
printf '#!/bin/sh\n[ "$1" = -a ] && [ "$2" = 256 ] && shift 2\nexec "%s" "$@"\n' "$REAL_SHA256SUM" > "$SHAONLY/shasum"; chmod +x "$SHAONLY/shasum"
if PATH="$SHAONLY" command -v sha256sum >/dev/null 2>&1; then fail 'SHA shasum-only PATH really lacks sha256sum'; else pass 'SHA shasum-only PATH really lacks sha256sum'; fi
np_run py ""
np_run nopy "$NOPY"
np_run sha "$SHAONLY"
assert_eq "$(cat "$TMP/np-sha.out")" "$(cat "$TMP/np-py.out")" 'SHA add/update/status/remove/v3-upgrade output identical on a shasum-only host'
assert_eq "$(cat "$TMP/np-sha.snap")" "$(cat "$TMP/np-py.snap")" 'SHA trees and manifest bytes identical on a shasum-only host after every step'
assert_eq "$(grep -c '^rc=0$' "$TMP/np-sha.out")" "$(grep -c '^== ' "$TMP/np-sha.out")" 'SHA every shasum-only step exits 0'
t="$TMP/sha-direct"; st="$TMP/sha-direct-state"; mkdir -p "$t" "$st"
out="$(PATH="$SHAONLY" AID_HOME="$st" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add claude-code --target "$t" --from-bundle "$STAGE" 2>&1)"; rc=$?
assert_exit_zero "$rc" 'SHA add claude-code on a shasum-only host succeeds'
if grep -Eq '"region_sha256": "[0-9a-f]{64}"' "$t/.aid/.aid-manifest.json" && [[ "$(grep -Ec '"region_sha256": "[0-9a-f]{64}"' "$t/.aid/.aid-manifest.json")" == 2 ]]; then pass 'SHA agents_md and claude_md region_sha256 are both recorded (64 hex)'; else fail 'SHA agents_md and claude_md region_sha256 are both recorded (64 hex)'; fi
assert_file_contains "$t/.aid/.aid-manifest.json" '"claude_md"' 'SHA shared.claude_md is recorded'
out="$(PATH="$SHAONLY" AID_HOME="$st" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" status --target "$t" 2>&1)"
assert_output_not_contains "$out" 'modified:' 'SHA status reports nothing modified right after add'
out="$(PATH="$SHAONLY" AID_HOME="$st" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" remove claude-code --target "$t" 2>&1)"
[[ ! -e "$t/CLAUDE.md" && ! -e "$t/AGENTS.md" ]] && pass 'SHA remove claude-code removes both import regions' || fail 'SHA remove claude-code removes both import regions'
assert_eq "$(cat "$TMP/np-nopy.out")" "$(cat "$TMP/np-py.out")" 'NP add/update/status/remove/v3-upgrade output identical without python3'
assert_eq "$(cat "$TMP/np-nopy.snap")" "$(cat "$TMP/np-py.snap")" 'NP trees and manifest bytes (installed_at masked) identical without python3 after every step'
assert_eq "$(grep -c '^rc=0$' "$TMP/np-nopy.out")" "$(grep -c '^== ' "$TMP/np-nopy.out")" 'NP every no-python step exits 0'
assert_output_contains "$(cat "$TMP/np-nopy.out")" 'old AID file(s) moved to .aid/.trash/' 'NP the v3 upgrade ran without python3'
assert_output_contains "$(cat "$TMP/np-nopy.snap")" '.aid/.aid-manifest.json manifest:' 'NP snapshot captured the manifest'
# The bash writer emits python3's bytes (ASCII only, \uXXXX for non-ASCII and control characters).
printf 'aid_version\t4.0.0\ninstalled_at\tT\nhost.worktree_root\t.aid/w\xc3\xb6rk "q"\\\\\ntools.cursor.version\t4.0.0\ntools.cursor.installed_at\tT\ntools.cursor.file\t.cursor/agents/aid-caf\xc3\xa9\xf0\x9f\x98\x80.md\t%s\n' "$(printf 'a%.0s' {1..64})" > "$TMP/np-model.tsv"
( source "$REPO/lib/aid-install-core.sh"; _manifest_write_v3_bash "$TMP/np-w-bash.json" "$TMP/np-model.tsv" )
if command -v python3 >/dev/null 2>&1; then
    ( source "$REPO/lib/aid-install-core.sh"; _manifest_write_v3_python "$TMP/np-w-py.json" "$TMP/np-model.tsv" )
    if cmp -s "$TMP/np-w-bash.json" "$TMP/np-w-py.json"; then pass 'NP bash and python3 writers emit identical bytes for non-ASCII and escaped values'; else fail 'NP bash and python3 writers emit identical bytes for non-ASCII and escaped values'; fi
fi
if grep -qF -e '\u00f6' "$TMP/np-w-bash.json"; then pass 'NP bash writer escapes non-ASCII as \uXXXX'; else fail 'NP bash writer escapes non-ASCII as \uXXXX'; fi
if grep -qF -e '\ud83d\ude00' "$TMP/np-w-bash.json"; then pass 'NP bash writer escapes a non-BMP character as a surrogate pair'; else fail 'NP bash writer escapes a non-BMP character as a surrogate pair'; fi
if LC_ALL=C grep -q '[^ -~]' "$TMP/np-w-bash.json"; then fail 'NP bash writer output is ASCII only'; else pass 'NP bash writer output is ASCII only'; fi

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
