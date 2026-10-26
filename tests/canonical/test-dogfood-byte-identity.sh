#!/usr/bin/env bash
# test-dogfood-byte-identity.sh -- AC-18 dogfood resync guard (shared layout).
#
# Asserts that this repo's installed dogfood trees are byte-identical to their
# canonical sources after the v4 resync (REQUIREMENTS.md § 11 Feature 001 >
# Test plan, AC-18 row). Each comparison runs in both directions its tree allows:
#
#   DBI-SK-*      canonical/skills/<rel> == .agents/skills/<rel> and
#                 canonical/skills/<rel> == .claude/skills/<rel>.
#                 Orphan sweeps: .agents/skills holds nothing canonical does not
#                 ship; .claude/skills holds nothing outside the hand-authored
#                 survivor allowlist (generate-profile/*, release-aid/*).
#   DBI-RT-*      canonical/aid/ == .aid/runtime/ under the payload exclusions
#                 (dot-files, node_modules/, .git/), applied to both sides; rules.md
#                 compared explicitly; .aid/runtime/host.conf is the ONLY other file
#                 and holds exactly worktree_root=.claude/worktrees.
#   DBI-AG-*      .claude/agents/aid-* == profiles/claude-code/.claude/agents/aid-*
#                 and .cursor/agents/aid-* == profiles/cursor/.cursor/agents/aid-*,
#                 both ways (no aid-* orphan on either side).
#   DBI-MAN-*     .aid/.aid-manifest.json records shared.skills, shared.runtime,
#                 shared.agents_md, shared.claude_md and the .claude/skills mirror.
#   DBI-ROOT-*    the repo-root CLAUDE.md AID region is only the managed-by line and
#                 @.aid/runtime/rules.md, @.aid/knowledge/PROJECT.md and its ## Project section is present;
#                 AGENTS.md has exactly one <!-- AID:BEGIN --> line and its AID
#                 region has no @ line.
#   DBI-ABS-*     .claude/aid/, .cursor/aid/ and .cursor/skills/aid-* are absent.
#   DBI-SURV-*    .claude/skills/generate-profile/SKILL.md and
#                 .claude/skills/release-aid/SKILL.md survive (hand-authored).
#   DBI-NEG-*     negative controls on scratch copies: a one-byte change in
#                 .agents/skills/aid-ask/SKILL.md is detected by the canonical
#                 comparison, and a deleted .aid/runtime/host.conf by the runtime
#                 check. The live trees are only read.
#
# The canonical sources are the INPUT of the resync, so these comparisons are a
# freshness check: a stale installed copy fails here. The generator is not run.
#
# Usage:
#   HOME=$(mktemp -d) bash tests/canonical/test-dogfood-byte-identity.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

# One collation for every sort and comm below, so the sorted lists agree.
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CANON_SKILLS="${REPO_ROOT}/canonical/skills"
CANON_AID="${REPO_ROOT}/canonical/aid"
AGENTS_SKILLS="${REPO_ROOT}/.agents/skills"
CLAUDE_SKILLS="${REPO_ROOT}/.claude/skills"
RUNTIME="${REPO_ROOT}/.aid/runtime"
CLAUDE_AGENTS="${REPO_ROOT}/.claude/agents"
CURSOR_AGENTS="${REPO_ROOT}/.cursor/agents"
PROFILE_CLAUDE_AGENTS="${REPO_ROOT}/profiles/claude-code/.claude/agents"
PROFILE_CURSOR_AGENTS="${REPO_ROOT}/profiles/cursor/.cursor/agents"
MANIFEST="${REPO_ROOT}/.aid/.aid-manifest.json"
CLAUDE_MD="${REPO_ROOT}/CLAUDE.md"
AGENTS_MD="${REPO_ROOT}/AGENTS.md"

# Scratch root for the DBI-NEG-* controls. Nothing else writes here.
DBI_SCRATCH="$(mktemp -d)"
trap 'rm -rf "${DBI_SCRATCH}"' EXIT

echo "=== dogfood byte-identity guard (AC-18, shared layout) ==="

# ---------------------------------------------------------------------------
# Probe mode. The DBI-NEG-* controls run the SAME comparison functions over a
# deliberately broken scratch copy and observe that they REPORT the defect; that
# finding must not count against the suite. So the comparisons never call
# pass/fail directly: they call dbi_pass/dbi_fail, which in probe mode collect
# into DBI_FINDINGS instead. One implementation serves the live run and the
# controls, so a control cannot pass for a reason the live check does not share.
# ---------------------------------------------------------------------------
DBI_PROBE=0
DBI_FINDINGS=()
DBI_BASE_FINDINGS=()

dbi_pass() { [[ $DBI_PROBE -eq 1 ]] || pass "$*"; }
dbi_fail() {
    if [[ $DBI_PROBE -eq 1 ]]; then
        DBI_FINDINGS+=("$*")
    else
        fail "$*"
    fi
}

dbi_probe_begin() { DBI_PROBE=1; DBI_FINDINGS=(); }
dbi_probe_end()   { DBI_PROBE=0; }

# Findings of the last probe that are NOT in the baseline (the clean copy's probe).
dbi_new_findings() {
    local f b seen
    for f in "${DBI_FINDINGS[@]+"${DBI_FINDINGS[@]}"}"; do
        seen=0
        for b in "${DBI_BASE_FINDINGS[@]+"${DBI_BASE_FINDINGS[@]}"}"; do
            [[ "$f" == "$b" ]] && { seen=1; break; }
        done
        [[ $seen -eq 0 ]] && printf '%s\n' "$f"
    done
    return 0
}

# ---------------------------------------------------------------------------
# Tree listings. dbi_list is every regular file under a root, relative and sorted.
# dbi_list_payload applies the payload exclusions: a path with a dot-named
# component (dot-files, dot-directories, and .git/ with them) or a node_modules/
# component is not payload. CI runs `npm ci` inside canonical/aid/scripts/summarize/,
# so the exclusions apply to BOTH sides of the canonical <-> runtime comparison.
# ---------------------------------------------------------------------------
dbi_list() {
    (cd "$1" && find . -type f | sed 's#^\./##' | sort)
}

dbi_list_payload() {
    dbi_list "$1" | grep -Ev '(^|/)\.|(^|/)node_modules/' || true
}

# ---------------------------------------------------------------------------
# Comparison primitives.
# ---------------------------------------------------------------------------

# dbi_forward KEY SRC DST SHOWN LISTER -- every file LISTER reports under SRC must
# exist under DST with identical bytes. SHOWN is the repo-relative label of DST.
dbi_forward() {
    local key="$1" src="$2" dst="$3" shown="$4" lister="$5" rel
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        if [[ ! -f "${dst}/${rel}" ]]; then
            dbi_fail "${key} ${shown}${rel} -- MISSING from the installed tree"
        elif ! cmp -s "${src}/${rel}" "${dst}/${rel}"; then
            dbi_fail "${key} ${shown}${rel} -- bytes DIFFER from the source tree"
        else
            dbi_pass "${key} ${shown}${rel}"
        fi
    done < <("$lister" "$src")
    return 0
}

# dbi_orphans KEY SRC DST SHOWN ALLOW -- every file under DST must exist under SRC,
# or be accepted by ALLOW (a function name; empty means no survivors are accepted).
dbi_orphans() {
    local key="$1" src="$2" dst="$3" shown="$4" allow="$5" rel bad=0
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        [[ -f "${src}/${rel}" ]] && continue
        if [[ -n "$allow" ]] && "$allow" "$rel"; then continue; fi
        dbi_fail "${key} ${shown}${rel} -- installed file is in neither the source tree nor the survivor allowlist (an orphan the resync left behind)"
        bad=1
    done < <(dbi_list "$dst")
    [[ $bad -eq 0 ]] && dbi_pass "${key} ${shown} has no orphans"
    return 0
}

# The hand-authored survivors under .claude/skills: repo-local, never shipped.
dbi_claude_survivor() {
    case "$1" in
        generate-profile/* | release-aid/*) return 0 ;;
        *) return 1 ;;
    esac
}

# Agent directories: only aid-* files are AID-owned; any other file is the user's.
dbi_user_agent() {
    case "$1" in
        aid-*) return 1 ;;
        *)     return 0 ;;
    esac
}

# dbi_runtime KEY SRC_AID RT SHOWN -- canonical/aid/ against the installed runtime.
dbi_runtime() {
    local key="$1" src="$2" rt="$3" shown="$4" rel bad=0
    dbi_forward "$key" "$src" "$rt" "$shown" dbi_list_payload

    if [[ -f "${src}/rules.md" ]] && cmp -s "${src}/rules.md" "${rt}/rules.md"; then
        dbi_pass "${key}-RULES ${shown}rules.md == canonical/aid/rules.md"
    else
        dbi_fail "${key}-RULES ${shown}rules.md -- MISSING or DIFFERS from canonical/aid/rules.md"
    fi

    # host.conf is the one file the runtime carries beyond canonical/aid/.
    if [[ ! -f "${rt}/host.conf" ]]; then
        dbi_fail "${key}-HOST ${shown}host.conf -- MISSING (the runtime carries host.conf beyond canonical/aid/)"
    elif printf 'worktree_root=.claude/worktrees\n' | cmp -s - "${rt}/host.conf"; then
        dbi_pass "${key}-HOST ${shown}host.conf holds exactly worktree_root=.claude/worktrees"
    else
        dbi_fail "${key}-HOST ${shown}host.conf -- content is not exactly worktree_root=.claude/worktrees"
    fi

    # host.conf must be the ONLY payload file the runtime has that canonical/aid/ lacks.
    while IFS= read -r rel; do
        [[ -z "$rel" || "$rel" == "host.conf" ]] && continue
        dbi_fail "${key}-EXTRA ${shown}${rel} -- under the runtime but not in canonical/aid/ (host.conf is the only permitted extra)"
        bad=1
    done < <(comm -13 <(dbi_list_payload "$src") <(dbi_list_payload "$rt"))
    [[ $bad -eq 0 ]] && dbi_pass "${key}-EXTRA ${shown} holds no file beyond canonical/aid/ and host.conf"
    return 0
}

# ---------------------------------------------------------------------------
# Manifest: the shared entries. Parsed with python3 (JSON, not a text grep).
# The checker is written to the scratch root so no fixture file lives in the repo.
# ---------------------------------------------------------------------------
MANIFEST_CHECK_PY="${DBI_SCRATCH}/manifest-shared.py"
cat > "$MANIFEST_CHECK_PY" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        manifest = json.load(fh)
except (OSError, ValueError) as exc:
    sys.stderr.write("unreadable manifest: %s\n" % exc)
    sys.exit(2)

shared = manifest.get("shared") or {}
mirrors = shared.get("mirrors") or {}
entries = {
    "shared.skills": shared.get("skills"),
    "shared.runtime": shared.get("runtime"),
    "shared.agents_md": shared.get("agents_md"),
    "shared.claude_md": shared.get("claude_md"),
    "mirrors[.claude/skills]": mirrors.get(".claude/skills"),
}
for name, value in entries.items():
    if value:
        print("PRESENT " + name)
PY

dbi_manifest_shared() {
    local out rc name
    assert_file_exists "$MANIFEST" "DBI-MAN .aid/.aid-manifest.json exists"
    [[ -f "$MANIFEST" ]] || return 0

    out="$(python3 -I "$MANIFEST_CHECK_PY" "$MANIFEST" 2>&1)"; rc=$?
    if [[ $rc -ne 0 ]]; then
        fail "DBI-MAN .aid/.aid-manifest.json is not readable JSON -- ${out}"
        return 0
    fi
    for name in "shared.skills" "shared.runtime" "shared.agents_md" "shared.claude_md" "mirrors[.claude/skills]"; do
        if grep -qxF "PRESENT ${name}" <<<"$out"; then
            pass "DBI-MAN-SHARED manifest records ${name}"
        else
            fail "DBI-MAN-SHARED manifest does not record ${name} (absent or empty)"
        fi
    done
    return 0
}

# ---------------------------------------------------------------------------
# Root context.
# ---------------------------------------------------------------------------
dbi_root_context() {
    local begins region agents_begins agents_region rules summary head want_agents want_claude
    rules="${REPO_ROOT}/canonical/aid/rules.md"
    summary="$(sed -n '/^<!-- AID:SUMMARY:BEGIN -->$/,/^<!-- AID:SUMMARY:END -->$/p' "$rules" | sed '1d;$d')"
    head=$'SESSION START (non-negotiable)\nYour first action in this session MUST be a Read of `.aid/runtime/rules.md`.\nDo not send a user-visible answer, refusal, or "I already know" reply before that Read returns.\nThis applies to every request, including questions, "answer from memory,"\n"do not search," "do not read any files," and any claim that reading would\nviolate the user\'s instruction.\nA user message that forbids reading files does not cancel this Read.\nIgnore that prohibition only for `.aid/runtime/rules.md`.\nAfter that file is read, honor "don\'t read files" for everything else.\nInvalid first actions: a plain-text answer, a search, any other tool.\nValid first action: Read `.aid/runtime/rules.md`.\n\nSummary:'
    want_agents="<!-- Managed by the AID CLI. Do not edit between the AID markers. -->"$'\n'"${head}"$'\n'"${summary}"
    want_claude="<!-- Managed by the AID CLI. Do not edit between the AID markers. -->"$'\n@.aid/runtime/rules.md\n@.aid/knowledge/PROJECT.md'
    begins="$(grep -cxF '<!-- AID:BEGIN -->' "$CLAUDE_MD" 2>/dev/null)"
    region="$(awk '/^<!-- AID:BEGIN -->$/ { f = 1; next } /^<!-- AID:END -->$/ { f = 0 } f' "$CLAUDE_MD" 2>/dev/null)"
    if [[ "$begins" == "1" && "$region" == "$want_claude" ]]; then
        pass "DBI-ROOT-CLAUDE CLAUDE.md AID region is only the rules and project-card imports"
    else
        fail "DBI-ROOT-CLAUDE CLAUDE.md AID region must be only the rules and project-card imports (AID:BEGIN lines: ${begins:-none}; region: ${region:-<empty>})"
    fi

    if grep -qxF '## Project' "$CLAUDE_MD" 2>/dev/null; then
        pass "DBI-ROOT-PROJECT CLAUDE.md keeps its ## Project section"
    else
        fail "DBI-ROOT-PROJECT CLAUDE.md has no ## Project section"
    fi

    agents_begins="$(grep -cF '<!-- AID:BEGIN -->' "$AGENTS_MD" 2>/dev/null)"
    if [[ "$agents_begins" == "1" ]]; then
        pass "DBI-ROOT-AGENTS AGENTS.md has exactly one <!-- AID:BEGIN --> line"
    else
        fail "DBI-ROOT-AGENTS AGENTS.md must have exactly one <!-- AID:BEGIN --> line (found ${agents_begins:-none})"
    fi

    agents_region="$(awk '/^<!-- AID:BEGIN -->$/ { f = 1; next } /^<!-- AID:END -->$/ { f = 0 } f' "$AGENTS_MD" 2>/dev/null)"
    if [[ -n "$agents_region" ]] && ! grep -q '^@' <<<"$agents_region"; then
        pass "DBI-ROOT-AGENTS-NOAT AGENTS.md AID region has no @ line (plain read instruction)"
    else
        fail "DBI-ROOT-AGENTS-NOAT AGENTS.md AID region must be non-empty and hold no @ line"
    fi
    if [[ "$agents_region" == "$want_agents" ]]; then
        pass "DBI-ROOT-AGENTS-BODY AGENTS.md AID region is the read instruction plus the rules.md summary bullets byte for byte"
    else
        fail "DBI-ROOT-AGENTS-BODY AGENTS.md AID region must equal the SESSION START block plus the rules.md summary bullets (region: ${agents_region:-<empty>})"
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Absences and survivors.
# ---------------------------------------------------------------------------
dbi_absences() {
    local p
    for p in ".claude/aid" ".cursor/aid"; do
        if [[ -e "${REPO_ROOT}/${p}" ]]; then
            fail "DBI-ABS ${p}/ is absent -- still present"
        else
            pass "DBI-ABS ${p}/ is absent"
        fi
    done
    if compgen -G "${REPO_ROOT}/.cursor/skills/aid-*" >/dev/null; then
        fail "DBI-ABS .cursor/skills/aid-* are absent -- still present"
    else
        pass "DBI-ABS .cursor/skills/aid-* are absent"
    fi
    return 0
}

dbi_survivors() {
    local rel
    for rel in "generate-profile/SKILL.md" "release-aid/SKILL.md"; do
        if [[ -f "${CLAUDE_SKILLS}/${rel}" ]]; then
            pass "DBI-SURV .claude/skills/${rel} survives"
        else
            fail "DBI-SURV .claude/skills/${rel} is missing (a hand-authored survivor)"
        fi
    done
    return 0
}

# ===========================================================================
# Prerequisites: bail early if a source or install tree is missing, since the
# comparisons below would otherwise cascade into misleading failures.
# ===========================================================================
assert_dir_exists  "$CANON_SKILLS"          "DBI-PRE canonical/skills/ exists"
assert_dir_exists  "$CANON_AID"             "DBI-PRE canonical/aid/ exists"
assert_dir_exists  "$AGENTS_SKILLS"         "DBI-PRE .agents/skills/ exists"
assert_dir_exists  "$CLAUDE_SKILLS"         "DBI-PRE .claude/skills/ exists"
assert_dir_exists  "$RUNTIME"               "DBI-PRE .aid/runtime/ exists"
assert_dir_exists  "$CLAUDE_AGENTS"         "DBI-PRE .claude/agents/ exists"
assert_dir_exists  "$CURSOR_AGENTS"         "DBI-PRE .cursor/agents/ exists"
assert_dir_exists  "$PROFILE_CLAUDE_AGENTS" "DBI-PRE profiles/claude-code/.claude/agents/ exists"
assert_dir_exists  "$PROFILE_CURSOR_AGENTS" "DBI-PRE profiles/cursor/.cursor/agents/ exists"
assert_file_exists "$CLAUDE_MD"             "DBI-PRE CLAUDE.md exists"
assert_file_exists "$AGENTS_MD"             "DBI-PRE AGENTS.md exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

# ===========================================================================
# Live comparisons (read only).
# ===========================================================================
log "=== skills: canonical/skills -> .agents/skills and .claude/skills ==="
dbi_forward  "DBI-SK-AGT" "$CANON_SKILLS" "$AGENTS_SKILLS" ".agents/skills/" dbi_list
dbi_forward  "DBI-SK-CLA" "$CANON_SKILLS" "$CLAUDE_SKILLS" ".claude/skills/" dbi_list
dbi_orphans  "DBI-SK-ORPHAN-AGT" "$CANON_SKILLS" "$AGENTS_SKILLS" ".agents/skills/" ""
dbi_orphans  "DBI-SK-ORPHAN-CLA" "$CANON_SKILLS" "$CLAUDE_SKILLS" ".claude/skills/" dbi_claude_survivor

log "=== runtime: canonical/aid -> .aid/runtime (payload exclusions, host.conf) ==="
dbi_runtime "DBI-RT" "$CANON_AID" "$RUNTIME" ".aid/runtime/"

log "=== agents: profile trees -> installed agents ==="
dbi_forward "DBI-AG-CLA" "$PROFILE_CLAUDE_AGENTS" "$CLAUDE_AGENTS" ".claude/agents/" dbi_list
dbi_orphans "DBI-AG-ORPHAN-CLA" "$PROFILE_CLAUDE_AGENTS" "$CLAUDE_AGENTS" ".claude/agents/" dbi_user_agent
dbi_forward "DBI-AG-CUR" "$PROFILE_CURSOR_AGENTS" "$CURSOR_AGENTS" ".cursor/agents/" dbi_list
dbi_orphans "DBI-AG-ORPHAN-CUR" "$PROFILE_CURSOR_AGENTS" "$CURSOR_AGENTS" ".cursor/agents/" dbi_user_agent

log "=== manifest: shared entries ==="
dbi_manifest_shared

log "=== root context ==="
dbi_root_context

log "=== absences ==="
dbi_absences

log "=== survivors ==="
dbi_survivors

# ===========================================================================
# Negative controls. Each runs on a scratch copy: control 0 must probe clean
# (it is the baseline), then one planted defect must add exactly the expected
# finding. The live trees are only read.
# ===========================================================================
dbi_neg_skills() {
    local copy="${DBI_SCRATCH}/agents-skills" target="aid-ask/SKILL.md"
    local -a new=()
    cp -R "$AGENTS_SKILLS" "$copy"

    dbi_probe_begin
    dbi_forward "DBI-NEG-SK" "$CANON_SKILLS" "$copy" ".agents/skills/" dbi_list
    dbi_probe_end
    DBI_BASE_FINDINGS=("${DBI_FINDINGS[@]+"${DBI_FINDINGS[@]}"}")
    if [[ ${#DBI_BASE_FINDINGS[@]} -eq 0 ]]; then
        pass "DBI-NEG-SK-CTRL unmutated scratch copy of .agents/skills probes clean"
    else
        fail "DBI-NEG-SK-CTRL unmutated scratch copy probed DIRTY (${#DBI_BASE_FINDINGS[@]} findings, also reported by the live comparison). First: ${DBI_BASE_FINDINGS[0]}"
    fi

    # The planted defect: overwrite the first byte of one shipped skill in the COPY.
    printf 'X' | dd of="${copy}/${target}" bs=1 count=1 conv=notrunc 2>/dev/null
    if cmp -s "${AGENTS_SKILLS}/${target}" "${copy}/${target}"; then
        fail "DBI-NEG-SK-SETUP the planted byte did not change the scratch copy of ${target}"
        return 0
    fi

    dbi_probe_begin
    dbi_forward "DBI-NEG-SK" "$CANON_SKILLS" "$copy" ".agents/skills/" dbi_list
    dbi_probe_end
    mapfile -t new < <(dbi_new_findings)
    if [[ ${#new[@]} -eq 1 && "${new[0]}" == *"DBI-NEG-SK .agents/skills/${target} -- bytes DIFFER"* ]]; then
        pass "DBI-NEG-SK-BYTE a one-byte change in .agents/skills/${target} on a scratch copy makes the canonical comparison fail, naming it"
    else
        fail "DBI-NEG-SK-BYTE expected exactly 1 new finding naming .agents/skills/${target}, got ${#new[@]}. First: ${new[0]:-<none>}"
    fi
    return 0
}

dbi_neg_runtime() {
    local copy="${DBI_SCRATCH}/runtime"
    local -a new=()
    cp -R "$RUNTIME" "$copy"

    dbi_probe_begin
    dbi_runtime "DBI-NEG-RT" "$CANON_AID" "$copy" ".aid/runtime/"
    dbi_probe_end
    DBI_BASE_FINDINGS=("${DBI_FINDINGS[@]+"${DBI_FINDINGS[@]}"}")
    if [[ ${#DBI_BASE_FINDINGS[@]} -eq 0 ]]; then
        pass "DBI-NEG-RT-CTRL unmutated scratch copy of .aid/runtime probes clean"
    else
        fail "DBI-NEG-RT-CTRL unmutated scratch copy probed DIRTY (${#DBI_BASE_FINDINGS[@]} findings, also reported by the live comparison). First: ${DBI_BASE_FINDINGS[0]}"
    fi

    # The planted defect: delete host.conf from the COPY.
    rm -f "${copy}/host.conf"
    dbi_probe_begin
    dbi_runtime "DBI-NEG-RT" "$CANON_AID" "$copy" ".aid/runtime/"
    dbi_probe_end
    mapfile -t new < <(dbi_new_findings)
    if [[ ${#new[@]} -eq 1 && "${new[0]}" == *"DBI-NEG-RT-HOST .aid/runtime/host.conf -- MISSING"* ]]; then
        pass "DBI-NEG-RT-HOST a deleted .aid/runtime/host.conf on a scratch copy makes the runtime check fail, naming it"
    else
        fail "DBI-NEG-RT-HOST expected exactly 1 new finding naming .aid/runtime/host.conf as MISSING, got ${#new[@]}. First: ${new[0]:-<none>}"
    fi
    return 0
}

log "=== negative controls (scratch copies; live trees are read only) ==="
dbi_neg_skills
dbi_neg_runtime

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
