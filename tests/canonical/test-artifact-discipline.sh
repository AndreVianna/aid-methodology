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
#   AD04  nothing points an agent at the retired per-feature SPEC.md layout
#   AD05  no tree diagram lists a `features/` directory (the multi-line form AD04 misses)
#   AD06  BLUEPRINT.md is retired: no template, and no skill/engine writes one
#   AD07  the shortcut (Lite) engine writes no SPEC.md (folded into REQUIREMENTS § 11)
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

# scan_tree: report `<path>:<line>` for every line matching the regex in $2, across the
# trees named in $1 (space-separated, repo-relative). $3 selects the fence policy:
#   skip-fences    ignore lines inside ``` blocks
#   include-fences scan every line
# Prints a count on the first line, then one offender per line.
#
# The policy differs BY RULE, and both directions were learned by getting it wrong:
#
#   skip-fences suits AD01/AD02, where a fenced block may legitimately EXHIBIT the
#   banned shape -- the kb-authoring templates show `changelog:` inside fences,
#   labelled superseded. Those are specimens, and flagging them is a false positive.
#
#   include-fences suits AD04, where the pattern is a path that no longer exists.
#   There is no legitimate way to exhibit it: an agent reading a tree diagram inside
#   a fence is being pointed at a dead path just as surely as one reading prose. This
#   was not hypothetical -- aid-plan/SKILL.md's directory diagram carried both a
#   BLUEPRINT.md line and a `features/ feature-NNN/ SPEC.md` block, and AD04 skipped
#   the whole thing because it sat in a fence.
scan_tree() {
    local trees="$1" pattern="$2" fence_policy="${3:-skip-fences}"
    ( cd "$REPO" && TREES="$trees" PATTERN="$pattern" FENCE_POLICY="$fence_policy" python3 - <<'PY'
import os, pathlib, re

pattern = re.compile(os.environ["PATTERN"])
skip_fences = os.environ["FENCE_POLICY"] == "skip-fences"
hits = []
for tree in os.environ["TREES"].split():
    root = pathlib.Path(tree)
    # A tree may be named as a single FILE, so a rule can scope itself to one document
    # without pulling in its siblings (AD07 targets the engine, not every template
    # beside it).
    if root.is_file():
        candidates = [root]
    elif root.is_dir():
        candidates = sorted(root.rglob("*.md"))
    else:
        continue
    for path in candidates:
        in_fence = False
        for number, line in enumerate(
            path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1
        ):
            if line.lstrip().startswith("```"):
                in_fence = not in_fence
                continue
            if skip_fences and in_fence:
                continue
            if pattern.search(line):
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
ad01="$(scan_tree "canonical docs examples" '^## (Change Log|Revision History)\s*$' skip-fences)"
ad01_count="$(report_count "$ad01")"
assert_eq "$ad01_count" "0" "AD01: no '## Change Log' / '## Revision History' in canonical/, docs/, examples/"
[[ "$ad01_count" != "0" ]] && report_body "$ad01" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
# AD02: the Knowledge Base carries no change-log apparatus in either form.
#
# Absolute here per CLAUDE.md: which work produced a change is history, and git
# holds it. The KB states only the current state of the project's sources.
# ---------------------------------------------------------------------------
ad02="$(scan_tree ".aid/knowledge" '^(## (Change Log|Revision History)\s*$|changelog:)' skip-fences)"
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
# the dashboard readers (reader.py / reader.mjs, PF-8) and is not what this rule
# governs. It also catches the prose spelling 'per-feature SPEC', which is the
# same instruction written without a path.
#
# docs/ and examples/ are in scope with canonical/: a reader who follows the
# published methodology description to a layout that no longer exists is misled
# just as effectively as an agent following a skill file.
# ---------------------------------------------------------------------------
ad04="$(scan_tree "canonical docs examples" \
        'features/\*/SPEC\.md|features/feature-[0-9A-Za-z-]*/SPEC\.md|per-feature `?SPEC' include-fences)"
ad04_count="$(report_count "$ad04")"
assert_eq "$ad04_count" "0" "AD04: nothing cites the retired per-feature 'features/*/SPEC.md' layout"
[[ "$ad04_count" != "0" ]] && report_body "$ad04" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
# AD05: no tree diagram lists a `features/` directory.
#
# AD04 is per-line, so it cannot see the abolished layout when a directory tree
# splits it across lines -- `features/`, then `feature-NNN/`, then `SPEC.md`, each
# on its own. That is not a corner case: it is how every skill file draws the work
# layout, and three such diagrams survived AD04 for exactly this reason.
#
# Matching a lone `features/` directory entry closes it without needing a
# multi-line parser. The signal is clean because the folder does not exist any
# more, so there is no correct context in which to draw it -- a reference is wrong
# whether it appears in a diagram or in prose.
# ---------------------------------------------------------------------------
# Pattern is PYTHON re, not POSIX ERE -- scan_tree compiles it with re.compile, which
# does not understand [[:space:]] and silently treats it as an ordinary character class.
# The first draft of this line used POSIX classes and matched 2299 lines.
ad05="$(scan_tree "canonical docs examples" \
        '^[\s|`+\-]*features/\s*(#.*)?$' include-fences)"
ad05_count="$(report_count "$ad05")"
assert_eq "$ad05_count" "0" "AD05: no tree diagram lists a 'features/' directory"
[[ "$ad05_count" != "0" ]] && report_body "$ad05" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
# AD06: BLUEPRINT.md is retired -- no template for it, and no skill or engine
# template instructs an agent to write one.
#
# The delivery definition (objective, scope, gate criteria) now lives in the
# delivery's own stanza in PLAN.md. A separate file for it meant the same delivery
# was described in two places that could disagree, and made an ordinary artifact
# load-bearing: BLUEPRINT.md's PRESENCE was the flat-layout signal in three
# implementations, so it could not be retired or moved without silently changing
# how a work was classified. That signal is now the declared `pipeline.path`.
#
# TWO EXCLUSIONS, both deliberate, neither an oversight:
#
#   canonical/aid/scripts/execute/writeback-state.sh keeps naming BLUEPRINT.md in
#   is_flat_layout's PRESENCE FALLBACK. That path exists precisely for works
#   created before the declared field, which do have the file on disk. Removing it
#   would misclassify every un-migrated work.
#
#   canonical/aid/scripts/migrate/migrate-work-hierarchy.{sh,ps1} still WRITE one.
#   They are not yet converted, and this gate does not pretend otherwise. They are
#   bash+PowerShell twins that must stay in lockstep, and pwsh cannot run in this
#   container -- converting them blind is the exact setup that produced three
#   silent divergences in the layout readers earlier in this work. Tracked as
#   remaining rather than waved through.
# ---------------------------------------------------------------------------
assert_eq "$([[ -e "${REPO}/canonical/aid/templates/delivery-blueprint-template.md" ]] && echo present || echo absent)" \
    "absent" "AD06: canonical/aid/templates/delivery-blueprint-template.md does not exist"

ad06="$(scan_tree "canonical/skills canonical/aid/templates" 'BLUEPRINT' include-fences)"
ad06_count="$(report_count "$ad06")"
assert_eq "$ad06_count" "0" "AD06: no skill or engine template mentions BLUEPRINT"
[[ "$ad06_count" != "0" ]] && report_body "$ad06" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
# AD07: the shortcut (Lite) engine writes no SPEC.md.
#
# The Lite SPEC.md restated REQUIREMENTS.md: its Description, User Stories, Priority
# and Acceptance Criteria were, in the engine's own words, "synthesized from
# REQUIREMENTS.md ... not re-elicited". That is the same content in two places inside
# one work, which is the exact failure this work was opened to remove -- and the one
# that already produced two CRITICAL findings elsewhere when sibling specs asserted
# different values for one shared fact.
#
# What Specify actually decides -- the technical specification -- now lives in the
# `#### Technical Specification` subsection of the feature's `### Feature NNN` section
# in REQUIREMENTS.md § 11. The criteria are CITED there by `AC-N` id rather than
# copied, so § 9 stays their single home and no second wording can drift from it.
#
# Scope is the engine and its scaffolding only. `spec-template.md` and the full path's
# own SPEC handling are NOT covered here: the full path still has a Specify phase with
# its own artifact, and AC-13 governs the Lite path.
# ---------------------------------------------------------------------------
ad07="$(scan_tree "canonical/aid/templates/shortcut-engine.md canonical/aid/templates/shortcut-scaffolding" \
        'SPEC\.md' include-fences)"
ad07_count="$(report_count "$ad07")"
assert_eq "$ad07_count" "0" "AD07: the shortcut engine and its scaffolding write no SPEC.md"
[[ "$ad07_count" != "0" ]] && report_body "$ad07" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
