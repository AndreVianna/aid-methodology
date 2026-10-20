#!/usr/bin/env bash
# test-design-no-work.sh - Static and fixture guard: a design-stage skill opens no work.
#
# COVERS: canonical/skills/
# COVERS: canonical/aid/scripts/execute/writeback-state.sh
#
# Before a work exists we are in the design stage: every question asked then, with its answer,
# is recorded in a design document under .aid/design/, and nothing is written under .aid/works/.
# The design-stage skills are /aid-brainstorm, /aid-design and every /aid-design-<kind>. A work is
# opened later by a build skill or /aid-orchestrate, which takes the seed into it (--create --seed).
#
#   DN-01  the design-stage roster is complete (23 skills)
#   DN-02  no design-stage skill calls the gate's --create (SKILL.md and references)
#   DN-03  no design-stage skill carries "Allocates a work-NNN" text
#   DN-04  every writer flag a design-stage skill names in a code span is a --design call; no
#          lifecycle or other work-record flag appears; no Paused/Running lifecycle value is written
#   DN-05  every design-stage skill records with --ask/--answer/--step --design
#   DN-06  every create skill that realizes a seed passes --seed on the gate's --create
#   DN-08  the hand-authored create/update skills that ask before they allocate record those questions with --ask --design
#   DN-07  fixture: the writer's --ask / --answer / --step --design leave .aid/works/ unchanged
#
# Usage:
#   bash test-design-no-work.sh [-v]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SKILLS_DIR="canonical/skills"
WRITER="${REPO_ROOT}/canonical/aid/scripts/execute/writeback-state.sh"

DESIGN_SKILLS=(aid-brainstorm aid-design)
while IFS= read -r d; do
    DESIGN_SKILLS+=("$(basename "$d")")
done < <(find "$SKILLS_DIR" -maxdepth 1 -type d -name 'aid-design-*' | sort)

# flat NAME -- every file of a skill (SKILL.md and references/), whitespace-flattened to one line.
flat() {
    local s="$1"
    find "${SKILLS_DIR}/${s}" -type f \( -name '*.md' -o -name '*.yml' \) -print0 | sort -z |
        xargs -0 cat | tr '\n' ' ' | tr -s ' '
}

echo "=== Design-stage skills open no work ==="

# DN-01
assert_eq "${#DESIGN_SKILLS[@]}" "23" "DN-01: the design-stage roster is brainstorm, bare design and the 21 design-<kind> skills"
for s in "${DESIGN_SKILLS[@]}"; do
    assert_file_exists "${SKILLS_DIR}/${s}/SKILL.md" "DN-01: ${s} has a SKILL.md"
done

for s in "${DESIGN_SKILLS[@]}"; do
    [[ -f "${SKILLS_DIR}/${s}/SKILL.md" ]] || continue
    text="$(flat "$s")"

    # DN-02
    if grep -q -E -e '--create' <<< "$text"; then
        fail "DN-02: ${s} calls or names the gate's --create"
    else
        pass "DN-02: ${s} has no gate --create call"
    fi

    # DN-03
    if grep -q -i -E 'Allocates a +work-NNN' <<< "$text"; then
        fail "DN-03: ${s} still says it allocates a work-NNN folder"
    else
        pass "DN-03: ${s} has no 'Allocates a work-NNN' text"
    fi

    # DN-04: inspect every inline code span.
    bad=""
    while IFS= read -r span; do
        span="${span#\`}"; span="${span%\`}"
        if grep -q -E -e '--(lifecycle|block|field|gate-field|append-issue|pipeline|intent|reroute|repair|handoff|handoff-return|create|check)\b' <<< "$span"; then
            bad+="[work-record flag: ${span}] "
        fi
        if grep -q -E -e '--(ask|answer|step)\b' <<< "$span" && ! grep -q -e '--design' <<< "$span"; then
            bad+="[no --design: ${span}] "
        fi
        if grep -q -E 'writeback-state\.sh +--' <<< "$span" && grep -q -E -e '--(ask|answer|step)\b' <<< "$span" && ! grep -q -e '--design' <<< "$span"; then
            bad+="[writer call without --design: ${span}] "
        fi
    done < <(grep -o '`[^`]*`' <<< "$text")
    if grep -q -E 'Paused-Awaiting-Input|`Completed`|`Blocked`|`Running`' <<< "$text"; then
        bad+="[a lifecycle value is written] "
    fi
    if [[ -n "$bad" ]]; then
        fail "DN-04: ${s} writes a work record -- ${bad}"
    else
        pass "DN-04: ${s} names only --design writes"
    fi

    # DN-05
    ok=1
    for need in '--ask --design' '--answer --design' '--step INTAKE --design' '--step PRESENT --design' '--step DONE --design'; do
        grep -q -F -e "$need" <<< "$text" || { ok=0; fail "DN-05: ${s} does not record with '${need}'"; }
    done
    [[ $ok -eq 1 ]] && pass "DN-05: ${s} records questions and steps with --design"
done

# DN-06
for k in architecture backlog cicd mvp roadmap stack testing-strategy document; do
    f="${SKILLS_DIR}/aid-create-${k}/SKILL.md"
    [[ -f "$f" ]] || { fail "DN-06: ${f} is missing"; continue; }
    text="$(tr '\n' ' ' < "$f" | tr -s ' ')"
    if grep -q -F -e "--seed .aid/design/${k}.md" <<< "$text" && grep -q -F -e '--create' <<< "$text"; then
        pass "DN-06: aid-create-${k} passes --seed .aid/design/${k}.md to the gate's --create"
    else
        fail "DN-06: aid-create-${k} does not pass --seed .aid/design/${k}.md to the gate's --create"
    fi
done

# DN-06 (continued): the shortcut engine, /aid-orchestrate and the seed-reading update skills pass --seed too.
for f in canonical/aid/templates/shortcut-engine.md canonical/skills/aid-orchestrate/SKILL.md canonical/skills/aid-orchestrate/references/start-or-resume.md; do
    [[ -f "$f" ]] || { fail "DN-06: ${f} is missing"; continue; }
    text="$(tr '\n' ' ' < "$f" | tr -s ' ')"
    if grep -q -F -e '--seed' <<< "$text" && grep -q -F -e '--create' <<< "$text"; then
        pass "DN-06: ${f##*/} passes --seed to --create"
    else
        fail "DN-06: ${f} does not pass --seed to --create"
    fi
done
for k in architecture backlog cicd mvp roadmap stack testing-strategy; do
    f="${SKILLS_DIR}/aid-update-${k}/SKILL.md"
    [[ -f "$f" ]] || { fail "DN-06: ${f} is missing"; continue; }
    text="$(tr '\n' ' ' < "$f" | tr -s ' ')"
    if grep -q -F -e "--seed .aid/design/${k}.md" <<< "$text"; then
        pass "DN-06: aid-update-${k} passes --seed .aid/design/${k}.md to the gate's --create"
    else
        fail "DN-06: aid-update-${k} does not pass --seed .aid/design/${k}.md to the gate's --create"
    fi
done

# DN-06 (continued): starters that ask before they allocate record their questions in a design document.
for f in canonical/aid/templates/shortcut-engine.md canonical/aid/templates/work-initiation-gate.md canonical/skills/aid-orchestrate/SKILL.md \
         canonical/skills/aid-research/SKILL.md canonical/skills/aid-report/SKILL.md; do
    text="$(tr '\n' ' ' < "$f" | tr -s ' ')"
    if grep -q -F -e '--ask --design' <<< "$text" && grep -q -F -e '--rename-design' <<< "$text"; then
        pass "DN-06: ${f##*/} records its pre-work questions with --ask --design and --rename-design"
    else
        fail "DN-06: ${f} does not record its pre-work questions with --ask --design / --rename-design"
    fi
done

# DN-08: the hand-authored skills that ask before they allocate record each pre-allocation question in a design document.
for s in aid-update-architecture aid-update-backlog aid-update-cicd aid-update-mvp aid-update-roadmap aid-update-stack aid-update-testing-strategy \
         aid-create-backlog aid-create-mvp aid-create-roadmap; do
    f="${SKILLS_DIR}/${s}/SKILL.md"
    [[ -f "$f" ]] || { fail "DN-08: ${f} is missing"; continue; }
    text="$(tr '\n' ' ' < "$f" | tr -s ' ')"
    if grep -q -F -e '--ask --design' <<< "$text" && grep -q -F -e '--answer --design' <<< "$text" && grep -q -F -e 'untitled-<YYYYMMDD-HHMMSS>.md' <<< "$text"; then
        pass "DN-08: ${s} records its pre-allocation questions with --ask --design / --answer --design"
    else
        fail "DN-08: ${s} does not record its pre-allocation questions with --ask --design / --answer --design"
    fi
done

# DN-07 fixture: the writer's design modes never touch .aid/works/.
# Needs the writer's --design / --seed modes; without them the writer exits 5 and these fail.
snapshot() { (cd "$1" && { find .aid/works -print 2>/dev/null | sort; find .aid/works -type f -exec cksum {} + 2>/dev/null | sort; }); }

run_fixture() {
    local label="$1" with_works="$2" proj="${TMP}/proj-${1}"
    mkdir -p "${proj}/.aid/design"
    if [[ "$with_works" == yes ]]; then
        mkdir -p "${proj}/.aid/works/work-001-existing"
        printf 'name: existing\nlifecycle: Running\n' > "${proj}/.aid/works/work-001-existing/STATE.yml"
    fi
    local before after out code seed=".aid/design/api.md"
    before="$(snapshot "$proj")"

    out="$(cd "$proj" && bash "$WRITER" --ask --design "$seed" --category Scope --impact High \
        --context 'which resources' --suggested 'orders' --asked-by aid-design-api 2>&1)"; code=$?
    assert_exit_zero "$code" "DN-07(${label}): --ask --design exits 0 -- ${out}"
    assert_output_contains "$out" "D1" "DN-07(${label}): --ask --design prints the new id D1"
    assert_file_exists "${proj}/${seed}" "DN-07(${label}): --ask --design opens the seed document"
    assert_file_contains "${proj}/${seed}" "## Questions" "DN-07(${label}): the seed carries a ## Questions table"

    out="$(cd "$proj" && bash "$WRITER" --answer --design "$seed" --id D1 --state Answered --value 'orders' 2>&1)"; code=$?
    assert_exit_zero "$code" "DN-07(${label}): --answer --design exits 0 -- ${out}"

    out="$(cd "$proj" && bash "$WRITER" --step PRESENT --design "$seed" --detail 'presented' 2>&1)"; code=$?
    assert_exit_zero "$code" "DN-07(${label}): --step --design exits 0 -- ${out}"
    assert_file_contains "${proj}/${seed}" "step: PRESENT" "DN-07(${label}): --step --design writes step into the seed frontmatter"

    after="$(snapshot "$proj")"
    assert_eq "$after" "$before" "DN-07(${label}): .aid/works/ is unchanged by the design writes"
    if [[ "$with_works" == no ]]; then
        if [[ -e "${proj}/.aid/works" ]]; then
            fail "DN-07(${label}): .aid/works/ was created by a design write"
        else
            pass "DN-07(${label}): no .aid/works/ was created"
        fi
    fi
}
run_fixture existing-works yes
run_fixture no-works no

# A --design path outside .aid/design/ is refused (exit 5), so a design write cannot reach a work.
proj="${TMP}/proj-reject"
mkdir -p "${proj}/.aid/works/work-001-x"
(cd "$proj" && bash "$WRITER" --ask --design .aid/works/work-001-x/STATE.yml --category Scope --impact High \
    --context c --suggested s --asked-by aid-design >/dev/null 2>&1); code=$?
assert_exit_eq "$code" 5 "DN-07: --design outside .aid/design/ is refused (exit 5)"

test_summary
exit $?
