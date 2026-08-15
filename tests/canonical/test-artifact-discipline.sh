#!/usr/bin/env bash
# test-artifact-discipline.sh -- standing tree-wide gates for the artifact-discipline
# rules, as opposed to one-time greps run by whoever made the change.
#
# Every rule below was, at some point, "verified" by running a grep once by hand and
# recording the count. That is not a gate: it holds only until the next edit, and it
# holds only for the trees the person happened to type. Two of these rules had already
# drifted by the time they were reviewed. A rule the project intends to keep belongs in
# a suite that re-runs it.
#
# Tests:
#   AD01  no '## Change Log' / '## Revision History' under canonical/, docs/, examples/
#   AD02  no change-log apparatus at all in .aid/knowledge/ (section OR frontmatter field)
#   AD03  every '../'-relative markdown link under canonical/ resolves to a real file
#   AD04  no canonical file points an agent at the retired per-feature SPEC.md layout
#
# Two scope decisions, both load-bearing, both found by writing the naive version first
# and reading what it flagged:
#
# tests/ is EXCLUDED from AD01. The rule governs AID artifacts. A fixture that
# simulates a legacy document must be free to contain the section it simulates, or
# legacy input becomes untestable -- there are such fixtures and they are correct.
#
# FENCED BLOCKS are excluded everywhere. `changelog:` appears inside fenced examples in
# the kb-authoring templates, explicitly labelled "(superseded) ... coexistence window":
# documentation OF the retired shape, which is the opposite of carrying it. A checker
# that cannot tell a specimen from an instance produces confident false positives, so
# this one tracks fences. The frontmatter half is therefore asserted against
# .aid/knowledge/, where CLAUDE.md makes it absolute and no illustrative frontmatter
# lives; the canonical KB seed templates keep their own per-template check (AS03b in
# test-kb-template-authoring-standard.sh).
#
# Usage: bash tests/canonical/test-artifact-discipline.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-artifact-discipline.sh =="

# scan_outside_fences: report `<path>:<line>` for every line matching the regex in $2
# that is NOT inside a ``` fenced block, across the trees named in $1 (space-separated,
# repo-relative). Prints a count on the first line, then one offender per line.
scan_outside_fences() {
    local trees="$1" pattern="$2"
    ( cd "$REPO" && TREES="$trees" PATTERN="$pattern" python3 - <<'PY'
import os, pathlib, re

pattern = re.compile(os.environ["PATTERN"])
hits = []
for tree in os.environ["TREES"].split():
    root = pathlib.Path(tree)
    if not root.is_dir():
        continue
    for path in sorted(root.rglob("*.md")):
        in_fence = False
        for number, line in enumerate(
            path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1
        ):
            if line.lstrip().startswith("```"):
                in_fence = not in_fence
                continue
            if not in_fence and pattern.search(line):
                hits.append(f"{path}:{number}: {line.strip()}")

print(len(hits))
for hit in hits:
    print(hit)
PY
    )
}

report_count() { printf '%s\n' "$1" | head -1; }
report_body()  { printf '%s\n' "$1" | tail -n +2; }

# ---------------------------------------------------------------------------
# AD01: no hand-maintained change-log section in any AID artifact.
#
# Git records per-doc history with author, date and diff, at higher fidelity and
# without drift, so a table inside the artifact is a second source that can only
# disagree with the first.
# ---------------------------------------------------------------------------
ad01="$(scan_outside_fences "canonical docs examples" '^## (Change Log|Revision History)\s*$')"
ad01_count="$(report_count "$ad01")"
assert_eq "$ad01_count" "0" "AD01: no '## Change Log' / '## Revision History' in canonical/, docs/, examples/"
[[ "$ad01_count" != "0" ]] && report_body "$ad01" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
# AD02: the Knowledge Base carries no change-log apparatus in either form.
#
# Absolute here per CLAUDE.md: which work produced a change is history, and git
# holds it. The KB states only the current state of the project's sources.
# ---------------------------------------------------------------------------
ad02="$(scan_outside_fences ".aid/knowledge" '^(## (Change Log|Revision History)\s*$|changelog:)')"
ad02_count="$(report_count "$ad02")"
assert_eq "$ad02_count" "0" "AD02: .aid/knowledge/ carries no change-log section and no 'changelog:' field"
[[ "$ad02_count" != "0" ]] && report_body "$ad02" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
# AD03: every '../'-relative markdown link under canonical/ resolves.
#
# These are agent instructions. A dead relative path does not raise an error at
# runtime -- the agent simply reads nothing and proceeds with missing context,
# which is the quietest way for this methodology to fail. 14 of these were live
# in canonical/ when the rule was first claimed satisfied, 13 of them the same
# missing path segment repeated.
# ---------------------------------------------------------------------------
ad03_report="$(
    cd "$REPO" && python3 - <<'PY'
import pathlib, re, sys

broken = []
for path in sorted(pathlib.Path("canonical").rglob("*.md")):
    text = path.read_text(encoding="utf-8", errors="replace")
    # ](../...) -- strip any #anchor before resolving; a bare #anchor is AD-scope
    # for the anchor checker, not this one.
    for match in re.finditer(r"\]\((\.\.[^)#\s]*)", text):
        target = match.group(1).strip()
        if not (path.parent / target).exists():
            line = text[: match.start()].count("\n") + 1
            broken.append(f"{path}:{line} -> {target}")

print(len(broken))
for entry in broken:
    print(entry)
PY
)"
ad03_count="$(printf '%s\n' "$ad03_report" | head -1)"
assert_eq "$ad03_count" "0" "AD03: every '../'-relative link under canonical/ resolves to an existing file"
[[ "$ad03_count" != "0" ]] && printf '%s\n' "$ad03_report" | tail -n +2 | sed 's|^|    broken: |' >&2

# ---------------------------------------------------------------------------
# AD04: nothing points an agent at the retired per-feature SPEC.md layout.
#
# Features are '### Feature NNN' subsections of REQUIREMENTS.md § 11. They were
# once per-feature folders holding a SPEC.md. An instruction to read
# 'features/*/SPEC.md' now globs to nothing, silently, and the reading agent
# continues without the context it was told to load.
#
# The pattern is deliberately narrow -- the abolished SHAPE, not the string
# 'SPEC.md' -- because a work-root SPEC.md is still a live identity fallback in
# the dashboard readers and is not what this rule governs.
# ---------------------------------------------------------------------------
ad04_hits=""
while IFS= read -r line; do
    [[ -n "$line" ]] && ad04_hits+="${line}"$'\n'
done < <(grep -rnE 'features/\*/SPEC\.md|features/feature-[0-9A-Za-z-]*/SPEC\.md' \
             "${REPO}/canonical" --include='*.md' 2>/dev/null || true)
ad04_count="$(printf '%s' "$ad04_hits" | grep -c . || true)"
assert_eq "$ad04_count" "0" "AD04: no canonical file cites the retired per-feature 'features/*/SPEC.md' path"
[[ "$ad04_count" != "0" ]] && printf '%s' "$ad04_hits" | sed "s|^${REPO}/||; s|^|    offender: |" >&2

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
