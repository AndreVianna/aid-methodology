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
#   AD08  the shortcut (Lite) engine writes no PLAN.md either -- AC-13 in full
#   AD09  the review path names no per-feature SPEC (a dead ARTIFACT, vs AD04 dead PATH)
#   AD10  SPEC.md is retired across canonical/ ENTIRELY -- zero, not a tolerated few
#   AD11  every KB frontmatter block parses as YAML (closes tech-debt W5-3 gate gap)
#   AD12  canonical/agents/ names no retired artifact and no retired work-state file
#   AD13  tree-wide RATCHET on the retired-artifact vocabulary (five classes)
#   AD14  every KB `sources:` citation resolves to a file that exists
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
# A line that STATES THE ABSENCE of the banned thing is never an offence -- "there is no
# per-feature SPEC.md", "writes no BLUEPRINT", "no features/ directory is created". These
# rules exist to stop agents being sent to dead artifacts, and a sentence explaining that
# an artifact is dead does the opposite.
#
# Added after the third false positive of exactly this kind (prototype.md, document.md,
# and the glossary entry defining the retirement). Twice was a coincidence; the third
# time meant the rule could not tell "use X" from "X is gone", and would keep pushing
# correct explanations into being deleted to satisfy it.
ABSENCE_RE='(there is |carries )?no( separate| longer| per-feature| such)?[ `]*(SPEC\.md|BLUEPRINT|PLAN\.md|features/)|writes? no |emits? no |never (writes|emits|creates)|is (retired|deleted|gone)|no .{0,24} is (written|created)'

scan_tree() {
    local trees="$1" pattern="$2" fence_policy="${3:-skip-fences}"
    ( cd "$REPO" && TREES="$trees" PATTERN="$pattern" FENCE_POLICY="$fence_policy" \
      ABSENCE="$ABSENCE_RE" python3 - <<'PY'
import os, pathlib, re

pattern = re.compile(os.environ["PATTERN"])
absence = re.compile(os.environ.get("ABSENCE", r"(?!x)x"), re.I)
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
            if pattern.search(line) and not absence.search(line):
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
        'features/[*a-zA-Z0-9_-]*/SPEC\.md|per-feature `?SPEC' include-fences)"
# The character class includes `*` deliberately. The first version enumerated two
# spellings -- `features/*/SPEC.md` and `features/feature-<name>/SPEC.md` -- and missed
# the third, `features/feature-*/SPEC.md`, where the glob sits AFTER the prefix. Two
# live instructions in this repo used exactly that form and passed the gate for days.
# Found only when another branch's copy of the same sentence was reviewed, which is the
# argument for matching the SHAPE (anything between `features/` and `/SPEC.md`) rather
# than enumerating the spellings someone happened to think of.
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
# AD08: the shortcut (Lite) engine writes no PLAN.md either -- AC-13 in full.
#
# The Lite path now produces exactly REQUIREMENTS.md, STATE.yml, and
# tasks/task-NNN/DETAIL.md. A plan records a SEQUENCING decision; with one feature and
# one delivery there is none to record, and every field a PLAN.md would carry is either
# already stated (the objective is § 1, the criteria are § 9) or derivable (the task
# listing from each `**Source:**`, the graph from each `**Depends on:**`).
#
# Priced before it was built, which is why the shape exists in the meter: at Lite
# dimensions it saves ~11% of a run. Most of that is the removed gate POINT rather than
# the removed bytes -- the file is ~2.6 KB against a ~3.3 MB run -- and the saving grows
# with review cycles because a gate point is cycle-multiplied.
#
# `flattened-plan-template.md` is deleted with it: nothing seeded it but this state.
# ---------------------------------------------------------------------------
assert_eq "$([[ -e "${REPO}/canonical/aid/templates/delivery-plans/flattened-plan-template.md" ]] && echo present || echo absent)" \
    "absent" "AD08a the flattened PLAN.md template is deleted"

# AD08c: the 34 generated doorways must not ADVERTISE an artifact set the engine no
# longer produces. They each carry a one-line summary of the pipeline, and that line
# said "REQUIREMENTS -> SPEC -> PLAN -> DETAIL" for the whole time AD07 and AD08b were
# passing -- because both are scoped to the engine, and a doorway is neither the engine
# nor its scaffolding. A skill whose description promises artifacts that are never
# written misleads whoever chooses it, which is the whole job of a doorway.
#
# Found by comparing against another in-flight branch rather than by these gates, which
# is why the rule is here now: the gap was invisible from inside this work.
# The pattern targets the ARTIFACT phrasing only. SPEC and PLAN are still STATES in the
# engine's state machine (`INTAKE -> CAPTURE -> SPEC -> PLAN -> DETAIL -> GATE ->
# APPROVAL-HALT`) -- those phases still run, they just no longer write a document. A
# first draft of this rule matched the bare arrow chain and flagged all 34 state-machine
# lines, which would have pushed a correct description into being deleted.
ad08c="$(scan_tree "canonical/skills" 'authors REQUIREMENTS -> SPEC|PLAN \+ BLUEPRINT|SPEC -> PLAN -> DETAIL tasks' include-fences)"
ad08c_count="$(report_count "$ad08c")"
assert_eq "$ad08c_count" "0" "AD08c no generated doorway advertises the retired SPEC/PLAN artifact set"
[[ "$ad08c_count" != "0" ]] && report_body "$ad08c" | sed 's|^|    offender: |' >&2

# Scoped to the engine, NOT its scaffolding: the family files legitimately discuss the
# full path, where PLAN.md remains the right home for a real sequencing decision.
ad08="$(scan_tree "canonical/aid/templates/shortcut-engine.md" 'PLAN\.md' include-fences)"
ad08_count="$(report_count "$ad08")"
# One mention survives on purpose -- the table explaining what a PLAN.md WOULD have
# carried and where each field lives instead. Naming the retired artifact while
# explaining its retirement is the opposite of instructing an agent to write one, so
# the rule allows exactly that single reference and fails on a second.
if [[ "$ad08_count" -le 1 ]]; then
    pass "AD08b the shortcut engine instructs no PLAN.md write (${ad08_count} explanatory mention(s))"
else
    fail "AD08b the shortcut engine must not instruct a PLAN.md write — ${ad08_count} mentions"
    report_body "$ad08" | sed 's|^|    offender: |' >&2
fi

# ---------------------------------------------------------------------------
# AD09: the REVIEW path names no per-feature SPEC.
#
# The reviewer briefs, the dispatch template and the reviewer agent tell a review
# agent WHAT TO LOAD. They were still naming "the feature's SPEC.md" and "all feature
# SPECs" after both aid-define and aid-specify moved to REQUIREMENTS.md § 11 -- 23
# mentions across 8 files, every one of them an instruction to load a file no work
# produces any more.
#
# AD04 could not see them because it matches the PATH shape (`features/.../SPEC.md`),
# and these say "SPEC.md" or "SPECs" with no path at all. Two different mistakes need
# two different rules: one for a dead path, one for a dead artifact NAME on the
# surface that consumes it.
#
# Scoped to the review path rather than all of canonical/, because a bare "SPEC.md"
# is still legitimate elsewhere -- spec-template.md exists, and several skills discuss
# specs generically. This rule governs the files that DISPATCH a reviewer, where the
# name is an instruction rather than a description.
# ---------------------------------------------------------------------------
ad09_files=""
for f in "${REPO}"/canonical/skills/*/references/reviewer-brief.md \
         "${REPO}/canonical/skills/aid-detail/references/review.md" \
         "${REPO}/canonical/skills/aid-plan/references/review-deliverables.md" \
         "${REPO}/canonical/aid/templates/reviewer-dispatch.md" \
         "${REPO}/canonical/agents/aid-reviewer/AGENT.md"; do
    [[ -f "$f" ]] || continue
    while IFS= read -r hit; do
        [[ -n "$hit" ]] && ad09_files+="${f#${REPO}/}:${hit}"$'\n'
    done < <(grep -nE 'SPEC\.md|\bSPECs\b' "$f" 2>/dev/null || true)
done
ad09_count="$(printf '%s' "$ad09_files" | grep -c . || true)"
assert_eq "$ad09_count" "0" "AD09: no reviewer brief, dispatch template or reviewer agent names a per-feature SPEC"
[[ "$ad09_count" != "0" ]] && printf '%s' "$ad09_files" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
# AD10: SPEC.md is retired everywhere, not just on the surfaces earlier rules named.
#
# AD07 covered the shortcut engine, AD09 the review path. Both were scoped because a
# SPEC.md was still live elsewhere at the time. It is not any more: neither aid-define
# nor aid-specify writes one, the Lite engine writes one, nor does any full-path skill --
# the artifact is gone from both paths. What survived was 84 REFERENCES to it, describing
# a document no work produces.
#
# The count is asserted rather than zero because two mentions are legitimate and must
# stay: `specs/spec-template.md` describing itself, and one sentence in
# feature-decomposition.md explaining that no separate spec file is written. A rule that
# demanded zero would force deleting the explanation of the very change it enforces.
#
# docs/ and examples/ are NOT in scope. docs/ is swept; examples/ still narrates the old
# flow with a sample artifact, which needs rewriting rather than patching and is tracked
# as remaining work. Including it here would fail the gate for something nobody is about
# to fix in the same commit -- a red check that teaches people to ignore red checks.
# ---------------------------------------------------------------------------
ad10="$(scan_tree "canonical" 'SPEC\.md' include-fences)"
ad10_count="$(report_count "$ad10")"
assert_eq "$ad10_count" "0" "AD10: nothing in canonical/ names SPEC.md outside an absence statement"
[[ "$ad10_count" != "0" ]] && report_body "$ad10" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
# AD13: TREE-WIDE ratchet on the retired-artifact vocabulary.
#
# This rule exists because of how every rule above it was written. Each one scoped itself
# to the tree where the problem had just been found -- AD04 to canonical/docs/examples,
# AD12 to canonical/agents -- so each proved a point about one directory and left its
# neighbours unexamined. The result was predictable in hindsight: AD12 was written to stop
# agents being sent to a retired work-state file, and the identical defect was sitting one
# directory over in canonical/skills the whole time, un-gated, because nobody ran the same
# check there. "The last surface" kept not being the last surface.
#
# So this one takes no scope argument. It counts the whole repository and compares against
# a recorded number.
#
# It is a RATCHET, not a ban, and that distinction is the only reason it can exist at all.
# Two of these three classes have a large legitimate residue:
#
#   - `STATE.md` for a WORK is dead, but ~120 references survive in canonical/skills
#     prose from the STATE.md -> STATE.yml rename. That is tracked debt (tech-debt SY-5
#     covers the Knowledge Base slice; the skills slice is recorded by SY-6) and clearing
#     it is a coordinated prose rewrite with its own review surface -- not something to
#     smuggle into whichever work happens to notice.
#   - `BLUEPRINT.md` is retired as an AUTHORED artifact, but its presence is still the
#     documented fallback sentinel for un-migrated works, read deliberately by
#     writeback-state.sh and both dashboard readers. Banning the string would delete
#     working legacy support.
#
# A ban would therefore be un-adoptable and would get weakened until it meant nothing. A
# frozen count cannot be argued with: the number goes down freely and never up, so the
# residue is visible, bounded, and cannot quietly regrow while attention is elsewhere.
#
# Update the ceilings ONLY downward. A rise means a new reference was introduced; the
# failure names the class so the offender is findable with the same pattern.
# ---------------------------------------------------------------------------
ad13_count_class() {
    ( cd "$REPO" && PATTERN="$1" python3 - <<'PY'
import os, pathlib, re, subprocess

pattern = re.compile(os.environ["PATTERN"])
# Absence statements, retirement notes, and the deliberate legacy-fallback prose are not
# offences -- the same argument AD04/AD10 already make. A sentence explaining that an
# artifact is dead is the opposite of sending someone to it.
skip = re.compile(
    r"\bno\b|not\b|never|retire[sd]?|gone|abolished|superseded|folded|formerly|legacy|"
    r"un-migrated|fallback|presence rule|sentinel|renamed|migration|era|IMPEDIMENT|"
    r"was |rejected|deprecated",
    re.I,
)
EXCLUDE = (
    "profiles/", ".claude/", ".cursor/", ".codex/", ".agent/",   # generated renders
    ".aid/works/",                                              # transient work state
    # A rule that quotes the string it governs is not an offence against itself;
    # counting this file would make the ceiling track its own prose.
    "tests/canonical/test-artifact-discipline.sh",
)
SUFFIXES = {".md", ".mdx", ".py", ".mjs", ".sh", ".ps1", ".yml", ".yaml", ".astro", ".ts", ".js"}

# TRACKED files only. Counting the working tree made the ceiling depend on whatever build
# output a developer happened to have on disk: a local package build drops ~180 copies of
# the repo under packages/, which would trip the ratchet for reasons that have nothing to
# do with the change under test. A ceiling that a stray directory can breach is a ceiling
# people learn to raise.
listed = subprocess.run(["git", "ls-files", "-z"], capture_output=True, text=True).stdout
total = 0
for name in listed.split("\0"):
    if not name or any(x in name for x in EXCLUDE):
        continue
    path = pathlib.Path(name)
    if path.suffix not in SUFFIXES or not path.is_file():
        continue
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if pattern.search(line) and not skip.search(line):
            total += 1
print(total)
PY
    )
}

# Ceilings are the counts THIS COUNTER reports, not a number measured some other way.
# That distinction is not pedantry: the first version of this rule took its ceilings from
# a working-tree scan with a different file set, and shipped with up to 48 units of slack
# -- enough that a deliberately-introduced offender passed. A ratchet with slack is not a
# ratchet. To re-baseline, run the counter and paste what it says.
#
# Lower them when a class shrinks; never raise them.
ad13_check() {
    local label="$1" ceiling="$2" pattern="$3" got
    got="$(ad13_count_class "$pattern")"
    if [[ -z "$got" ]]; then
        fail "AD13 ${label}: counter produced no output"
    elif [[ "$got" -le "$ceiling" ]]; then
        pass "AD13 ${label}: ${got} reference(s), ceiling ${ceiling}"
    else
        fail "AD13 ${label}: ${got} references exceeds the ceiling of ${ceiling} -- a new one was introduced"
    fi
}

ad13_check "work STATE.md (retired; use STATE.yml)" 65 \
    'works?[ `]{0,4}['"'"'\`]?STATE\.md|works/\{work\}/STATE\.md'
ad13_check "BLUEPRINT.md (retired as an authored artifact)" 154 \
    'BLUEPRINT\.md'
ad13_check "bare task-NNN.md (now tasks/task-NNN/DETAIL.md)" 16 \
    '(?<!IMPEDIMENT-)(?<!execute-)\btask-NNN\.md'
ad13_check "per-feature SPEC.md (folded into REQUIREMENTS.md section 11)" 3 \
    'features/[*a-zA-Z0-9_-]*/SPEC\.md|per-feature[ `]+SPEC'

# The FIFTH class, and the one that shows why a ratchet has to be revisited rather than
# declared done. Every count above matches a FILENAME. A line can name a retired STATE.md
# section -- `## Deploy State`, `## Features State` -- without naming any file, so all
# four were blind to it. It was found by asking what a filename-shaped rule could not see,
# which is a question worth asking of any rule, not just this one.
#
# The residue here is the largest of the five and the most mixed: the dashboard readers and
# the format converter must know the old headings to READ them, and test fixtures must
# contain them to simulate legacy works. Only the live-instruction slice is a defect, and
# that slice is SY-6.
ad13_check "retired STATE.md section headings (STATE.yml has keys, not headings)" 235 \
    '## (Cross-phase Q&A|Tasks Status|Tasks State|Features State|Deploy State|Pipeline State|Delivery Gate|Seed Authoring|Interview State)'

# ---------------------------------------------------------------------------
# AD12: the AGENT definitions name no retired artifact.
#
# `canonical/agents/` is the surface every prose sweep in this work missed, because each
# one targeted `canonical/skills/` and `canonical/aid/templates/` -- the places artifacts
# are USED -- and an agent definition is neither. It is, however, where an agent is told
# what to PRODUCE, which makes a stale name there more directly harmful than the same
# name in a reference doc.
#
# What was actually found sitting there: aid-architect -- the agent that performs the
# decomposition -- instructing itself to write `task-NNN.md` plus "an execution graph in
# PLAN.md", when the task definition is `tasks/task-NNN/DETAIL.md` and the graph is
# derived and never authored; and eight references across five agents telling agents to
# write state into the work's `STATE.md`, renamed to `STATE.yml`.
#
# The STATE.md check is deliberately NOT a blanket ban: `.aid/knowledge/STATE.md` is the
# KB's own state file, still markdown, still correct, and five references to it are
# right. A rule that banned the string outright would have "fixed" those into being
# wrong, so it matches the WORK state file specifically.
# ---------------------------------------------------------------------------
ad12_state="$(scan_tree "canonical/agents" 'work.{0,4}[`'\'']?STATE\.md|work.s [`'\'']?STATE\.md' include-fences)"
ad12_state_count="$(report_count "$ad12_state")"
assert_eq "$ad12_state_count" "0" "AD12a no agent writes work state to the retired STATE.md (STATE.yml)"
[[ "$ad12_state_count" != "0" ]] && report_body "$ad12_state" | sed 's|^|    offender: |' >&2

# The KB's own STATE.md must SURVIVE -- asserted positively, so a future over-broad
# tightening of the rule above is caught here rather than shipping a wrong correction.
ad12_kb="$(cd "$REPO" && grep -rl 'knowledge/STATE\.md' canonical/agents/ 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${ad12_kb:-0}" -ge 1 ]]; then
    pass "AD12b the KB's own STATE.md is still cited by agents (${ad12_kb} file(s)) -- not over-corrected"
else
    fail "AD12b agents no longer cite .aid/knowledge/STATE.md -- AD12a was applied too broadly"
fi

ad12_art="$(scan_tree "canonical/agents" 'task-NNN\.md|execution graph in PLAN|SPEC\.md|BLUEPRINT' include-fences)"
ad12_art_count="$(report_count "$ad12_art")"
assert_eq "$ad12_art_count" "0" "AD12c no agent is told to produce a retired artifact"
[[ "$ad12_art_count" != "0" ]] && report_body "$ad12_art" | sed 's|^|    offender: |' >&2

# ---------------------------------------------------------------------------
# AD11: every KB doc's frontmatter is well-formed YAML.
#
# This closes tech-debt W5-3's second half -- the half that row itself called "the more
# useful" one. Six of 21 KB docs once had frontmatter that would not parse, and nothing
# noticed: `lint-frontmatter.sh` validates field PRESENCE and list-versus-scalar SHAPE
# textually, never well-formedness, and its FL19 class soft-skips AID's own KB docs
# entirely. The one gate named after frontmatter was structurally blind to frontmatter
# that will not parse.
#
# The original defect is gone -- its root cause was `changelog:` entries whose prose
# contained `": "`, and the change-log apparatus was removed repo-wide. But a defect
# disappearing because something unrelated removed its cause is not the same as a defect
# being prevented: nothing stopped it recurring. This is what stops it.
#
# Asserted with a real parser rather than a regex, because the failure mode is precisely
# "looks fine to a textual check, rejected by a parser". Python is used directly: it is
# already a hard dependency of the test corpus, and the alternative is another
# hand-rolled YAML reader, which this work has spent enough time on.
# ---------------------------------------------------------------------------
ad11="$( cd "$REPO" && python3 - <<'PY'
import pathlib, re
try:
    import yaml
except ImportError:
    print("SKIP")
    raise SystemExit(0)

bad = []
for path in sorted(pathlib.Path(".aid/knowledge").glob("*.md")):
    text = path.read_text(encoding="utf-8", errors="replace")
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        continue                      # a doc with no frontmatter block is AD02's business
    try:
        yaml.safe_load(m.group(1))
    except Exception as exc:          # noqa: BLE001
        first = str(exc).splitlines()[0]
        bad.append(f"{path}: {first}")

print(len(bad))
for entry in bad:
    print(entry)
PY
)"
if [[ "$(printf '%s\n' "$ad11" | head -1)" == "SKIP" ]]; then
    pass "AD11 SKIPPED: PyYAML not installed"
else
    ad11_count="$(report_count "$ad11")"
    assert_eq "$ad11_count" "0" "AD11: every .aid/knowledge/ frontmatter block parses as YAML"
    [[ "$ad11_count" != "0" ]] && report_body "$ad11" | sed 's|^|    invalid: |' >&2
fi

# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# AD14: every KB `sources:` citation resolves to a file that exists.
#
# The KB's whole claim is that a reader can VERIFY it: each doc lists the sources it was
# derived from so a fact can be traced back. A citation to a file that no longer exists
# breaks exactly that, and it breaks silently -- the doc still reads as authoritative.
#
# Nothing checked it. `kb-citation-lint.sh` is the gate whose name suggests it would, but
# it flags VOLATILE line-number anchors (`file.md:39`), a different problem entirely; it
# never opens the cited path. So retiring a template left three KB docs citing deleted
# files -- feature.md and delivery-blueprint-template.md -- and no suite noticed.
#
# Two path forms are both legitimate and both resolved here: `canonical/...` (this repo's
# source of truth) and `.claude/aid/...` (the rendered install tree a KB doc may cite
# because that is where an adopter sees the file). A `path:anchor` suffix is stripped
# before resolution -- the anchor is kb-citation-lint's business, not this rule's.
# ---------------------------------------------------------------------------
ad14_report="$( cd "$REPO" && python3 - <<'AD14PY'
import pathlib, re
try:
    import yaml
except ImportError:
    print("SKIP")
    raise SystemExit(0)

def resolves(raw):
    s = raw.strip().strip("`")
    if not s or s.startswith(("http://", "https://", "(")) or s in {"none", "N/A", "-"}:
        return True                       # URLs and placeholders are out of scope
    if s.startswith(".aid/generated/"):
        return True                       # build output; absent in a clean checkout
    s = s.split(":", 1)[0]                # drop a durable anchor suffix
    if pathlib.Path(s).exists():
        return True
    # A KB doc may cite the RENDERED install tree; map it back to canonical/.
    for prefix, repl in ((".claude/aid/", "canonical/aid/"), (".claude/", "canonical/"),
                         (".cursor/aid/", "canonical/aid/"), (".cursor/", "canonical/")):
        if s.startswith(prefix) and pathlib.Path(repl + s[len(prefix):]).exists():
            return True
    return False

bad = []
for path in sorted(pathlib.Path(".aid/knowledge").glob("*.md")):
    m = re.match(r"^---\n(.*?)\n---", path.read_text(encoding="utf-8", errors="replace"), re.S)
    if not m:
        continue
    try:
        fm = yaml.safe_load(m.group(1)) or {}
    except Exception:
        continue                          # AD11 owns unparseable frontmatter
    for src in (fm.get("sources") or []):
        if not resolves(str(src)):
            bad.append(f"{path}: {src}")

print(len(bad))
for entry in bad:
    print(entry)
AD14PY
)"
if [[ "$(printf '%s\n' "$ad14_report" | head -1)" == "SKIP" ]]; then
    pass "AD14 SKIPPED: PyYAML not installed"
else
    ad14_count="$(report_count "$ad14_report")"
    assert_eq "$ad14_count" "0" "AD14: every .aid/knowledge/ sources: citation resolves to an existing file"
    [[ "$ad14_count" != "0" ]] && report_body "$ad14_report" | sed 's|^|    dangling: |' >&2
fi

echo ""
test_summary
exit $?
