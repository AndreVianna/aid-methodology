#!/usr/bin/env bash
# test-skill-guide.sh -- Feature 001 static skill-guide suite (SG-01 to SG-06).
#
# COVERS: canonical/aid/rules.md
# COVERS: canonical/skills/
# COVERS: canonical/agents/
# COVERS: canonical/aid/templates/shortcut-catalog.yml
# COVERS: tests/lib/bundle.sh
#
# Groups (REQUIREMENTS.md section 11, Feature 001, "6. Testing"):
#   SG-01  ## Handling a request counts at most 20 lines (heading through the last non-blank line)
#   SG-02  the skill guide names exactly the skills in canonical/skills/, both ways; a <kind> line
#          expands to the catalog rows of that verb (canonical/aid/templates/shortcut-catalog.yml)
#   SG-03  every skill-guide line is at most 100 characters
#   SG-04  every non-exempt description has the what/when shape ("Use when" after a what-sentence);
#          every exempt skill still exists; with AID_RELEASE_CHECK=1 the exempt list must be empty
#   SG-05  no front-door skill (canonical/skills/aid/), no aid-orchestrator agent, and aid-developer
#          and aid-tech-writer present
#   SG-06  one bundle staged by tests/lib/bundle.sh, installed for each of the five tools: every skill
#          at the tool's own skills path (.claude/skills/ for claude-code, .agents/skills/ for the
#          others), byte-identical to canonical/, name equal to its folder, a non-empty description,
#          and no flag that blocks slash or agent invocation
#
# The skill guide is ASCII, so ${#line} counts bytes and characters alike (LC_ALL=C is pinned).
# The exempt list (SG-04) names the skills that a later feature of this work deletes or renames.
# Each feature that removes a name deletes its row here; the list empties as they go.
#
# Usage:  test-skill-guide.sh [--group SG-01[,SG-02,...]] [--verbose] [--self-mutate]
#   --group        run only the named groups (T6: re-run the failing group, not the suite)
#   --self-mutate  also run the mutation matrix (S3): each mutant works on a private copy made in a
#                  mktemp dir (S5), runs only its target group (S3), and must make that group fail.
#                  The source tree must be byte-identical afterwards.
# Environment: HOME is pinned to a mktemp dir; AID_RELEASE_CHECK=1 enables the SG-04 release check.
# Exit:   0 all passed / 1 one or more failed / 2 usage error
set -uo pipefail
export LC_ALL=C

VERBOSE=0 SELF_MUTATE=0 SG_GROUPS=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) VERBOSE=1 ;;
        --self-mutate) SELF_MUTATE=1 ;;
        --group) SG_GROUPS="${2:-}"; shift ;;
        --group=*) SG_GROUPS="${1#--group=}" ;;
        *) echo "usage: test-skill-guide.sh [--group SG-01,...] [--verbose] [--self-mutate]" >&2; exit 2 ;;
    esac
    shift
done
ALL_GROUPS="SG-01 SG-02 SG-03 SG-04 SG-05 SG-06"
if [[ -n "$SG_GROUPS" ]]; then
    for g in ${SG_GROUPS//,/ }; do
        [[ " $ALL_GROUPS " == *" $g "* ]] || { echo "unknown group: $g" >&2; exit 2; }
    done
fi
want() { [[ -z "$SG_GROUPS" || ",$SG_GROUPS," == *",$1,"* ]]; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
source "${HERE}/../lib/assert.sh"
source "${HERE}/../lib/bundle.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="${TMP}/home" USERPROFILE="${TMP}/home" AID_NO_UPDATE_CHECK=1
mkdir -p "$HOME"
SG_ROOT="$REPO"

# SG-04 exempt list: the S9 rows of the delivery-001 site search. Every name is a skill folder today.
SG_EXEMPT=(
    'aid-ask' 'aid-config' 'aid-create-api' 'aid-create-architecture' 'aid-create-backlog' 'aid-create-cicd'
    'aid-create-cli' 'aid-create-config' 'aid-create-dashboard' 'aid-create-data-model' 'aid-create-data-pipeline' 'aid-create-diagram'
    'aid-create-document' 'aid-create-infra' 'aid-create-integration' 'aid-create-job' 'aid-create-messaging' 'aid-create-mvp'
    'aid-create-roadmap' 'aid-create-stack' 'aid-create-test' 'aid-create-testing-strategy' 'aid-create-theme' 'aid-create-ticket'
    'aid-create-ui' 'aid-define' 'aid-deprecate' 'aid-describe' 'aid-design' 'aid-design-api'
    'aid-design-architecture' 'aid-design-backlog' 'aid-design-cicd' 'aid-design-cli' 'aid-design-config' 'aid-design-dashboard'
    'aid-design-data-model' 'aid-design-data-pipeline' 'aid-design-document' 'aid-design-infra' 'aid-design-integration' 'aid-design-job'
    'aid-design-messaging' 'aid-design-mvp' 'aid-design-roadmap' 'aid-design-stack' 'aid-design-test' 'aid-design-testing-strategy'
    'aid-design-theme' 'aid-design-ui' 'aid-detail' 'aid-discover' 'aid-document-architecture' 'aid-document-changelog'
    'aid-document-decision' 'aid-document-guideline' 'aid-document-runbook' 'aid-document-standard' 'aid-document-tutorial' 'aid-experiment'
    'aid-housekeep' 'aid-migrate' 'aid-prototype-ui' 'aid-remove' 'aid-summarize' 'aid-test-data-quality'
    'aid-test-performance' 'aid-test-security' 'aid-update-api' 'aid-update-architecture' 'aid-update-backlog' 'aid-update-cicd'
    'aid-update-cli' 'aid-update-config' 'aid-update-dashboard' 'aid-update-data-model' 'aid-update-data-pipeline' 'aid-update-document'
    'aid-update-infra' 'aid-update-integration' 'aid-update-job' 'aid-update-kb' 'aid-update-messaging' 'aid-update-mvp'
    'aid-update-roadmap' 'aid-update-stack' 'aid-update-test' 'aid-update-testing-strategy' 'aid-update-theme' 'aid-update-ticket'
    'aid-update-ui'
)

# ---------------------------------------------------------------------------
# Helpers (one awk or sed pass per file; no per-assertion spawns beyond that)
# ---------------------------------------------------------------------------
fm_block() { awk 'NR == 1 && $0 == "---" { f = 1; next } f && $0 == "---" { exit } f { print }' "$1"; }

fm_name() { fm_block "$1" | awk '/^name:/ { sub(/^name:[ \t]*/, ""); print; exit }'; }

# Folded or inline description, whitespace collapsed to single spaces.
fm_description() {
    fm_block "$1" | awk '
        /^description:/ { on = 1; sub(/^description:[ \t]*>?[ \t]*/, ""); buf = $0; next }
        /^[A-Za-z0-9_-]+:/ { on = 0 }
        on && /^[ \t]+/ { sub(/^[ \t]+/, ""); buf = buf (buf == "" ? "" : " ") $0 }
        END { gsub(/[ \t]+/, " ", buf); sub(/^ /, "", buf); sub(/ $/, "", buf); print buf }'
}

# Flags that block invocation: disable-model-invocation: true (agent) or user-invocable: false (slash).
blocking_flags() {
    fm_block "$1" | awk '/^disable-model-invocation:[ \t]*"?true/ || /^user-invocable:[ \t]*"?false/ { print }'
}

# Lines from "## Handling a request" through the last non-blank line before the next "## " heading.
handling_count() {
    awk '
        $0 == "## Handling a request" { on = 1; start = NR; last = NR; next }
        on && /^## / { exit }
        on && NF > 0 { last = NR }
        END { if (start) print last - start + 1; else print 0 }' "$1"
}

# The lines of "## Skill guide", up to the next "## " heading.
guide_section() { awk '$0 == "## Skill guide" { on = 1; next } on && /^## / { exit } on { print }' "$1"; }

# The skill name each guide bullet gives, as written (a <kind> name is not yet expanded).
guide_names() { guide_section "$1" | sed -n 's/^- `\/\(aid-[^`]*\)`.*/\1/p'; }

# Catalog rows as "name verb artifact" (artifact may be empty).
catalog_rows() {
    awk '
        /^  - name: / { name = $3; verb = ""; art = "" }
        /^    verb: /  { verb = $2 }
        /^    artifact: / { art = $2; gsub(/"/, "", art); print name, verb, art }' "$1"
}

# Every name the guide gives: a literal name as written, or an <kind> name expanded to the catalog
# rows of its verb that carry an artifact (aid-create-<kind> -> every create row with an artifact).
expand_guide() {
    local name stem verb
    guide_names "$1" | while IFS= read -r name; do
        if [[ "$name" == *"<kind>"* ]]; then
            stem="${name%%-<kind>*}"
            verb="${stem#aid-}"
            catalog_rows "$2" | awk -v v="$verb" '$2 == v && $3 != "" { print $1 }'
        else
            printf '%s\n' "$name"
        fi
    done | sort -u
}

# Skill folder names of a directory, sorted.
skill_dirs() {
    local d
    for d in "$1"/*/; do [[ -d "$d" ]] && basename "$d"; done | sort
}

is_exempt() {
    local e
    for e in "${SG_EXEMPT[@]}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
}

# Digest of every file under canonical/ (S5: proves the source tree was left byte-identical).
tree_digest() { find "$REPO/canonical" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum; }

# ---------------------------------------------------------------------------
# SG-01 .. SG-05: static checks against SG_ROOT (the repository, or a mutant copy)
# ---------------------------------------------------------------------------
group_sg01() {
    local n
    n="$(handling_count "$SG_ROOT/canonical/aid/rules.md")"
    if [[ "$n" -ge 1 && "$n" -le 20 ]]; then
        pass "SG-01 ## Handling a request counts $n lines (at most 20)"
    else
        fail "SG-01 ## Handling a request counts $n lines: at most 20"
    fi
}

group_sg02() {
    local rules="$SG_ROOT/canonical/aid/rules.md"
    local catalog="$SG_ROOT/canonical/aid/templates/shortcut-catalog.yml"
    local named disk missing extra
    named="$(expand_guide "$rules" "$catalog" | grep -v '^$')"
    disk="$(skill_dirs "$SG_ROOT/canonical/skills")"
    missing="$(comm -23 <(printf '%s\n' "$named") <(printf '%s\n' "$disk") | grep -v '^$' | tr '\n' ' ')"
    extra="$(comm -13 <(printf '%s\n' "$named") <(printf '%s\n' "$disk") | grep -v '^$' | tr '\n' ' ')"
    if [[ -z "$missing" ]]; then
        pass "SG-02 every skill the guide names has a folder in canonical/skills/"
    else
        fail "SG-02 the guide names skills with no folder in canonical/skills/: $missing"
    fi
    if [[ -z "$extra" ]]; then
        pass "SG-02 every folder in canonical/skills/ is named by the guide"
    else
        fail "SG-02 folders in canonical/skills/ the guide does not name: $extra"
    fi
}

group_sg03() {
    local line n=0 long=0
    while IFS= read -r line; do
        n=$((n + 1))
        if [[ ${#line} -gt 100 ]]; then
            long=$((long + 1))
            fail "SG-03 guide line is ${#line} characters, at most 100: ${line:0:60}..."
        fi
    done < <(guide_section "$SG_ROOT/canonical/aid/rules.md")
    if [[ $long -eq 0 ]]; then pass "SG-03 all $n skill-guide lines are at most 100 characters"; fi
}

group_sg04() {
    local name desc before checked=0 bad=0 missing=0
    for name in "${SG_EXEMPT[@]}"; do
        if [[ ! -d "$SG_ROOT/canonical/skills/$name" ]]; then
            missing=$((missing + 1))
            fail "SG-04 exempt row names a skill that no longer exists: $name"
        fi
    done
    if [[ $missing -eq 0 ]]; then pass "SG-04 all ${#SG_EXEMPT[@]} exempt skills still exist"; fi
    while IFS= read -r name; do
        if is_exempt "$name"; then continue; fi
        checked=$((checked + 1))
        desc="$(fm_description "$SG_ROOT/canonical/skills/$name/SKILL.md")"
        before="${desc%%Use when*}"
        if [[ "$desc" == *"Use when"* && -n "${before//[[:space:]]/}" ]]; then
            :
        else
            bad=$((bad + 1))
            fail "SG-04 $name: description lacks the what/when shape (a what-sentence, then 'Use when')"
        fi
    done < <(skill_dirs "$SG_ROOT/canonical/skills")
    if [[ $bad -eq 0 ]]; then pass "SG-04 all $checked non-exempt descriptions have the what/when shape"; fi
    if [[ "${AID_RELEASE_CHECK:-0}" == 1 ]]; then
        if [[ ${#SG_EXEMPT[@]} -eq 0 ]]; then
            pass "SG-04 release check: the exempt list is empty"
        else
            fail "SG-04 release check: ${#SG_EXEMPT[@]} skills are still exempt"
        fi
    fi
}

group_sg05() {
    local c="$SG_ROOT/canonical" a
    if [[ -e "$c/skills/aid" ]]; then
        fail "SG-05 front-door skill still present: canonical/skills/aid/"
    else
        pass "SG-05 no front-door skill: canonical/skills/aid/ is absent"
    fi
    if [[ -e "$c/agents/aid-orchestrator" ]]; then
        fail "SG-05 orchestrator agent still present: canonical/agents/aid-orchestrator/"
    else
        pass "SG-05 no aid-orchestrator agent"
    fi
    for a in aid-developer aid-tech-writer; do
        if [[ -d "$c/agents/$a" ]]; then
            pass "SG-05 agent $a is present"
        else
            fail "SG-05 agent $a is missing from canonical/agents/"
        fi
    done
}

# ---------------------------------------------------------------------------
# SG-06: one bundle, installed for each of the five tools, then checked at each tool's skills path
# ---------------------------------------------------------------------------
SG06_TOOLS="claude-code cursor codex copilot-cli antigravity"
declare -A SG06_DIR=()
SG06_INSTALLED=0

sg06_skills_path() {
    if [[ "$1" == claude-code ]]; then echo ".claude/skills"; else echo ".agents/skills"; fi
}

sg06_install_all() {
    [[ $SG06_INSTALLED -eq 1 ]] && return 0
    SG06_INSTALLED=1
    local stage="${TMP}/bundle" tool target state out rc
    mkdir -p "$stage"
    if ! aid_test_stage_bundle "$stage" >"${TMP}/stage.log" 2>&1; then
        fail "SG-06 staging one bundle through tests/lib/bundle.sh failed: $(tail -n 1 "${TMP}/stage.log")"
        return 1
    fi
    pass "SG-06 one bundle staged through tests/lib/bundle.sh"
    for tool in $SG06_TOOLS; do
        target="${TMP}/project-${tool}"; state="${TMP}/state-${tool}"
        mkdir -p "$target" "$state"
        out="$(AID_HOME="$state" AID_NO_UPDATE_CHECK=1 bash "$REPO/bin/aid" add "$tool" --target "$target" --from-bundle "$stage" 2>&1)"; rc=$?
        if [[ $rc -ne 0 ]]; then
            fail "SG-06 $tool: aid add exited $rc: $(tail -n 1 <<< "$out")"
            continue
        fi
        SG06_DIR[$tool]="${target}/$(sg06_skills_path "$tool")"
    done
    return 0
}

sg06_check_all() {
    local tool dir name sk desc flags n bad
    for tool in $SG06_TOOLS; do
        dir="${SG06_DIR[$tool]:-}"
        if [[ -z "$dir" || ! -d "$dir" ]]; then
            fail "SG-06 $tool: no installed skills folder at $(sg06_skills_path "$tool")"
            continue
        fi
        n=0; bad=0
        while IFS= read -r name; do
            n=$((n + 1))
            sk="$dir/$name"
            if [[ ! -d "$sk" ]]; then
                bad=$((bad + 1)); fail "SG-06 $tool: skill $name is not installed at $(sg06_skills_path "$tool")"
                continue
            fi
            if ! diff -rq -- "$SG_ROOT/canonical/skills/$name" "$sk" >/dev/null 2>&1; then
                bad=$((bad + 1)); fail "SG-06 $tool: $name is not byte-identical to canonical/skills/$name"
                continue
            fi
            if [[ "$(fm_name "$sk/SKILL.md")" != "$name" ]]; then
                bad=$((bad + 1)); fail "SG-06 $tool: $name has a name: field that is not its folder name"
                continue
            fi
            desc="$(fm_description "$sk/SKILL.md")"
            if [[ -z "$desc" ]]; then
                bad=$((bad + 1)); fail "SG-06 $tool: $name has an empty description"
                continue
            fi
            flags="$(blocking_flags "$sk/SKILL.md")"
            if [[ -n "$flags" ]]; then
                bad=$((bad + 1)); fail "SG-06 $tool: $name carries a flag that blocks invocation: $flags"
                continue
            fi
        done < <(skill_dirs "$SG_ROOT/canonical/skills")
        if [[ $bad -eq 0 ]]; then
            pass "SG-06 $tool: all $n skills at $(sg06_skills_path "$tool") are byte-identical, named, described and unflagged"
        fi
    done
}

group_sg06() {
    sg06_install_all
    sg06_check_all
}

# ---------------------------------------------------------------------------
# Self-mutate matrix (S3, S5): each mutant runs in a subshell over a private copy and is judged by
# the FAIL lines of its own target group only.
# ---------------------------------------------------------------------------
mut_root() {  # <label>: a private copy of canonical/, made the mutant's SG_ROOT
    local m="${TMP}/mutant-$1"
    rm -rf "$m"; mkdir -p "$m"
    cp -R "$REPO/canonical" "$m/canonical"
    SG_ROOT="$m"
}

m_sg01_21st_line() {
    mut_root sg01
    awk '{ print } $0 == "## Handling a request" { print "- filler line one"; print "- filler line two"; print "- filler line three" }' \
        "$REPO/canonical/aid/rules.md" > "$SG_ROOT/canonical/aid/rules.md"
    group_sg01
}

m_sg02_guide_line_removed() {
    mut_root sg02a
    sed -i '/^- `\/aid-ask` --/d' "$SG_ROOT/canonical/aid/rules.md"
    group_sg02
}

m_sg02_stray_folder() {
    mut_root sg02b
    mkdir -p "$SG_ROOT/canonical/skills/aid-stray-skill"
    printf -- '---\nname: aid-stray-skill\ndescription: >\n  A stray skill. Use when a test adds one.\n---\n' \
        > "$SG_ROOT/canonical/skills/aid-stray-skill/SKILL.md"
    group_sg02
}

m_sg03_101_char_line() {
    mut_root sg03
    local base="- \`/aid-ask\` -- " pad fill line
    pad=$((101 - ${#base}))
    fill="$(printf 'x%.0s' $(seq 1 "$pad"))"
    line="${base}${fill}"
    awk -v line="$line" '{ if ($0 == "## Review criteria (before you write)") { print line; print "" } print }' \
        "$REPO/canonical/aid/rules.md" > "$SG_ROOT/canonical/aid/rules.md"
    group_sg03
}

m_sg04_no_use_when() {
    mut_root sg04a
    sed -i 's/Use when a plain request/Use if a plain request/' "$SG_ROOT/canonical/skills/aid-orchestrate/SKILL.md"
    group_sg04
}

m_sg04_exempt_row_missing() {
    mut_root sg04b
    SG_EXEMPT+=(aid-ghost-skill)
    group_sg04
}

m_sg04_release_check() {
    mut_root sg04c
    AID_RELEASE_CHECK=1
    group_sg04
}

m_sg05_front_door() {
    mut_root sg05a
    mkdir -p "$SG_ROOT/canonical/skills/aid"
    printf -- '---\nname: aid\ndescription: >\n  Front door. Use when a test adds one.\n---\n' > "$SG_ROOT/canonical/skills/aid/SKILL.md"
    group_sg05
}

m_sg05_orchestrator_agent() {
    mut_root sg05b
    mkdir -p "$SG_ROOT/canonical/agents/aid-orchestrator"
    group_sg05
}

m_sg05_developer_removed() {
    mut_root sg05c
    rm -rf "$SG_ROOT/canonical/agents/aid-developer"
    group_sg05
}

m_sg06_installed_byte() {
    local m="${TMP}/mutant-sg06-byte"
    rm -rf "$m"; cp -R "${SG06_DIR[claude-code]}" "$m"
    printf ' ' >> "$m/aid-ask/SKILL.md"
    SG06_DIR[claude-code]="$m"
    sg06_check_all
}

m_sg06_disable_model_invocation() {
    local m="${TMP}/mutant-sg06-flag"
    rm -rf "$m"; cp -R "${SG06_DIR[claude-code]}" "$m"
    sed -i '1a disable-model-invocation: true' "$m/aid-ask/SKILL.md"
    SG06_DIR[claude-code]="$m"
    sg06_check_all
}

run_mutant() {  # <group> <label> <function>
    local group="$1" label="$2" fn="$3" log="${TMP}/mutant-${2}.log"
    want "$group" || return 0
    ( "$fn" ) >"$log" 2>&1
    if grep -q '^  FAIL: ' "$log"; then
        pass "mutant $label fails $group"
    else
        fail "mutant $label did not fail $group"
    fi
}

# ---------------------------------------------------------------------------
echo '== test-skill-guide.sh =='
if want SG-01; then group_sg01; fi
if want SG-02; then group_sg02; fi
if want SG-03; then group_sg03; fi
if want SG-04; then group_sg04; fi
if want SG-05; then group_sg05; fi
if want SG-06; then group_sg06; fi

if [[ $SELF_MUTATE -eq 1 ]]; then
    digest_before="$(tree_digest)"
    if want SG-06; then sg06_install_all; fi
    run_mutant SG-01 sg01-21st-line m_sg01_21st_line
    run_mutant SG-02 sg02-guide-line-removed m_sg02_guide_line_removed
    run_mutant SG-02 sg02-stray-folder m_sg02_stray_folder
    run_mutant SG-03 sg03-101-char-line m_sg03_101_char_line
    run_mutant SG-04 sg04-no-use-when m_sg04_no_use_when
    run_mutant SG-04 sg04-exempt-row-missing m_sg04_exempt_row_missing
    run_mutant SG-04 sg04-release-check-nonempty m_sg04_release_check
    run_mutant SG-05 sg05-front-door m_sg05_front_door
    run_mutant SG-05 sg05-orchestrator-agent m_sg05_orchestrator_agent
    run_mutant SG-05 sg05-developer-removed m_sg05_developer_removed
    run_mutant SG-06 sg06-installed-byte m_sg06_installed_byte
    run_mutant SG-06 sg06-disable-model-invocation m_sg06_disable_model_invocation
    digest_after="$(tree_digest)"
    if [[ "$digest_before" == "$digest_after" ]]; then
        pass "mutation matrix left canonical/ byte-identical"
    else
        fail "mutation matrix changed canonical/"
    fi
fi

test_summary
exit $?
