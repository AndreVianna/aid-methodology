#!/usr/bin/env bash
# test-kb-no-work-ids.sh — the Knowledge Base names no work.
#
# The rule is in CLAUDE.md and AGENTS.md, stated imperatively, with two reasons each sufficient
# on its own: a work folder is pruned when its work ships, so a citation to one is a dangling
# pointer by design; and the KB states only the CURRENT STATE of the project's sources, whereas
# which work produced a change is history.
#
# This test exists because the rule was UNENFORCED, and an actual violation -- a note added to
# `tech-debt.md` that named a work twice -- survived three review cycles before a reviewer caught
# it by reading. A rule that binds every agent and is checked by nobody is a rule that gets
# broken quietly. Now it fails a suite instead.
#
#   KW01  no work id appears in Knowledge Base PROSE
#   KW02  no work-folder path appears in Knowledge Base prose
#   KW03  no `changelog:` frontmatter key, and no Change Log / Revision History heading --
#         the same rule's corollary: git records per-doc history at higher fidelity
#   KW04  the check itself is falsifiable (it detects a planted violation)
#
# KNOWN LIMITS, recorded so nobody reads this guard as airtight:
#   - A work id SPLIT ACROSS A LINE BREAK is not detected. Markdown wrapping breaks at spaces, so
#     `work-042` cannot be split accidentally; this is an evasion, not a mistake anybody makes.
#   - A genuine citation written inside backticks would pass, because code spans are stripped
#     (below). That is the cost of the exemption, and it is accepted: KB citations use file paths
#     and anchors, so a bare work id in code format is already anomalous enough to notice in review.
# Both are deliberate. The guard is aimed at accidental citation, which is what actually happened.
#
# WHAT IS DELIBERATELY ALLOWED: a work id inside an inline code span or a fenced block. Those are
# command SYNTAX -- `/aid-execute work-001 task-001` shows a reader how to invoke a skill -- and a
# placeholder in an example is neither a dangling pointer nor a historical citation, so it is
# outside what the rule is aimed at. Stripping code spans before searching is what draws that line
# mechanically rather than by judgement.
#
# Usage: bash test-kb-no-work-ids.sh [--verbose]

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
KB="${REPO_ROOT}/.aid/knowledge"

[[ -d "$KB" ]] || { echo "SKIP: no .aid/knowledge in this tree" >&2; exit 0; }

# Strip fenced blocks and inline code spans, then report any remaining work id with its file and
# line. Written as a function so KW04 can point it at a planted violation and prove it bites.
_scan_prose() {
    local root="$1"
    python3 - "$root" <<'PY'
import os, re, sys
root = sys.argv[1]
pat_id   = re.compile(r'work-\d{3}')
pat_path = re.compile(r'\.aid/works/')
hits = []
for dirpath, _dirs, files in os.walk(root):
    for fn in files:
        if not fn.endswith(('.md', '.yml', '.yaml')):
            continue
        path = os.path.join(dirpath, fn)
        with open(path, encoding='utf-8', errors='replace') as fh:
            lines = fh.read().split('\n')
        fenced = False
        for n, raw in enumerate(lines, 1):
            if raw.lstrip().startswith('```'):
                fenced = not fenced
                continue
            if fenced:
                continue
            # Remove inline code spans: a work id inside one is command syntax, not a citation.
            line = re.sub(r'`[^`]*`', '', raw)
            if pat_id.search(line) or pat_path.search(line):
                hits.append(f'{os.path.relpath(path, root)}:{n}: {line.strip()[:120]}')
print('\n'.join(hits))
PY
}

prose_hits="$(_scan_prose "$KB")"
id_hits="$(printf '%s' "$prose_hits" | grep -E 'work-[0-9]{3}' || true)"
path_hits="$(printf '%s' "$prose_hits" | grep -F '.aid/works/' || true)"

if [[ -z "$id_hits" ]]; then
    pass "KW01 no work id appears in Knowledge Base prose"
else
    fail "KW01 a work id appears in Knowledge Base prose:
${id_hits}"
fi

if [[ -z "$path_hits" ]]; then
    pass "KW02 no work-folder path appears in Knowledge Base prose"
else
    fail "KW02 a work-folder path appears in Knowledge Base prose:
${path_hits}"
fi

# KW03 — the corollary. A KB doc carries no changelog, because git already records per-doc history
# with author, date and diff, at higher fidelity and without drift.
changelog_hits="$(grep -rniE '^\s*changelog:|^#{1,4}\s*(change ?log|revision history)\s*$' "$KB" 2>/dev/null || true)"
if [[ -z "$changelog_hits" ]]; then
    pass "KW03 no KB doc carries a changelog key or a Change Log / Revision History heading"
else
    fail "KW03 a KB doc carries its own history:
${changelog_hits}"
fi

# KW04 — falsify the scanner. A guard nobody has seen fail is a guard nobody should trust: plant
# one violation of each kind in a scratch copy and require both to be found.
_scratch="$(mktemp -d)"
trap 'rm -rf "${_scratch}"' EXIT
mkdir -p "${_scratch}/kb"
{
    printf 'objective: a scratch doc\n\n'
    printf 'This sentence cites work-042 in prose, which the rule forbids.\n'
    printf 'This one points at .aid/works/work-042-thing/STATE.yml, also forbidden.\n\n'
    printf 'This one shows syntax and is allowed: `/aid-execute work-001 task-001`.\n'
} > "${_scratch}/kb/planted.md"
planted="$(_scan_prose "${_scratch}/kb")"
p_id="$(printf '%s' "$planted" | grep -cE 'work-042' || true)"
p_path="$(printf '%s' "$planted" | grep -cF '.aid/works/' || true)"
p_allowed="$(printf '%s' "$planted" | grep -cE 'aid-execute' || true)"
if [[ "$p_id" -ge 1 && "$p_path" -ge 1 ]]; then
    pass "KW04 the scanner detects a planted work id and a planted work-folder path"
else
    fail "KW04 the scanner missed a planted violation (id=${p_id}, path=${p_path})"
fi
assert_eq "$p_allowed" "0" "KW04 and does NOT flag a work id used as command syntax inside a code span"

test_summary
