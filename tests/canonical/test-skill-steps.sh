#!/usr/bin/env bash
# test-skill-steps.sh - Static checks for the step rules of Feature 002 (section 8, groups
# SS-02, SS-03, SS-08, SS-11, SS-12 and SS-14).
#
# COVERS: canonical/skills/
# COVERS: canonical/aid/templates/
# COVERS: canonical/aid/scripts/
# COVERS: dashboard/
# COVERS: tests/canonical/skill-steps-exempt.tsv
#
#   SS-02  every SKILL.md with a Dispatch table or a `## State:` section cites skill-steps.md;
#          shortcut-engine.md and design-lifecycle.md, while they exist, cite it too
#   SS-03  no `**Advance:**` line uses a word other than CHAIN, ASK, WAIT, PASS, CALL, HALT
#          (a line naming only its next step is a CHAIN); no PAUSE-FOR-USER word in canonical/
#   SS-08  work-state-template.yml and project-state-template.yml parse through the dashboard
#          reader with no warning
#   SS-11  no old phase name (Describe, Define, Specify, Plan, Detail, Execute) as data or logic
#          in the tracked files named by the spec, outside the legacy-phase-map markers
#   SS-12  no hand-written `lifecycle: Completed` / `Canceled` in canonical/skills/ or
#          canonical/aid/templates/, except the exempt entries marked SS-12
#   SS-14  the gate is the only creator and the writer the only writer of the work record:
#          (a) work-initiation-gate.md section 3a runs writeback-state.sh --create with
#              --reading, --skill and --step
#          (b) no `initiator:`, copy-the-template or hand-written record-block line in a skill or
#              template, except the template files named below and the exempt entries marked SS-14
#          (c) skill-steps.md section "The work record" carries the fail-closed and recovery rules
#          (d) no continuation routed by a skill itself (only work-initiation-gate.md may)
#
# The shared exempt list tests/canonical/skill-steps-exempt.tsv (columns: entry, checks, owner)
# serves SS-03, SS-12 and SS-14. An entry is a skill folder name (exempting every file under
# canonical/skills/<name>/) or a canonical/ path. The list fails when an entry no longer exists,
# and under AID_RELEASE_CHECK=1 while it is not empty.
#
# Usage:
#   bash test-skill-steps.sh [-v] [SS-NN]     # SS-NN runs that one group only
# Exit codes: 0 all pass / 1 any fail / 2 bad usage.

set -uo pipefail

VERBOSE=0
GROUP=""
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        SS-[0-9][0-9]) GROUP="$arg" ;;
        *) echo "usage: $0 [-v] [SS-NN]" >&2; exit 2 ;;
    esac
done

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

EXEMPT_TSV="tests/canonical/skill-steps-exempt.tsv"
OLD_PHASES='Describe|Define|Specify|Plan|Detail|Execute'
GATE_DOC="canonical/aid/templates/work-initiation-gate.md"
STEPS_DOC="canonical/aid/templates/skill-steps.md"
# SS-14 (b): the templates that may carry the record keys (they are the record's own shape).
SS14_TEMPLATE_EXCEPTIONS=(
    canonical/aid/templates/work-state-template.yml
    canonical/aid/templates/project-state-template.yml
    canonical/aid/templates/delivery-state-template.yml
    canonical/aid/templates/task-state-template.yml
    canonical/aid/templates/work-initiation-gate.md
)

# wants GROUP -- true when GROUP is selected (no filter, or the filter names it).
wants() { [[ -z "$GROUP" || "$GROUP" == "$1" ]]; }

G_NAME=""; G_FAIL0=0; G_PASS0=0
group_begin() {
    G_NAME="$1"; G_FAIL0=$FAIL; G_PASS0=$PASS
    echo "=== $1 ==="
}
group_end() {
    local nf=$((FAIL - G_FAIL0)) np=$((PASS - G_PASS0))
    if [[ $nf -eq 0 ]]; then
        echo "    ${G_NAME%% *}: PASS ($np check(s))"
    else
        echo "    ${G_NAME%% *}: FAIL ($nf failure(s), $np check(s) passed)"
    fi
}

# ---------------------------------------------------------------------------
# The shared exempt list.
# ---------------------------------------------------------------------------
EX_ENTRY=(); EX_CHECKS=(); EX_OWNER=()
if [[ -f "$EXEMPT_TSV" ]]; then
    while IFS=$'\t' read -r e_entry e_checks e_owner; do
        [[ -z "$e_entry" || "$e_entry" == "entry" ]] && continue
        EX_ENTRY+=("$e_entry"); EX_CHECKS+=("$e_checks"); EX_OWNER+=("$e_owner")
    done < "$EXEMPT_TSV"
else
    fail "EXEMPT list $EXEMPT_TSV is missing"
fi

# exempt_for CHECK PATH -- 0 when PATH belongs to an entry marked CHECK on the shared list.
exempt_for() {
    local check="$1" path="$2" i entry
    for i in "${!EX_ENTRY[@]}"; do
        [[ ",${EX_CHECKS[$i]}," == *",$check,"* ]] || continue
        entry="${EX_ENTRY[$i]}"
        if [[ "$entry" == */* ]]; then
            [[ "$path" == "$entry" ]] && return 0
        else
            [[ "$path" == "canonical/skills/$entry/"* ]] && return 0
        fi
    done
    return 1
}

exempt_list_check() {
    group_begin "EXEMPT shared exempt list ($EXEMPT_TSV)"
    local i entry checks token n=${#EX_ENTRY[@]}
    for i in "${!EX_ENTRY[@]}"; do
        entry="${EX_ENTRY[$i]}"; checks="${EX_CHECKS[$i]}"
        if [[ "$entry" == */* ]]; then
            if [[ -f "$entry" ]]; then
                pass "EXEMPT $entry exists"
            else
                fail "EXEMPT entry $entry names a missing file -- its feature has landed; remove the row"
            fi
        else
            if [[ -d "canonical/skills/$entry" ]]; then
                pass "EXEMPT $entry exists"
            else
                fail "EXEMPT entry $entry names a missing folder (canonical/skills/$entry) -- its feature has landed; remove the row"
            fi
        fi
        for token in ${checks//,/ }; do
            case "$token" in
                SS-03|SS-12|SS-14) ;;
                *) fail "EXEMPT entry $entry has an unknown check '$token' (SS-03, SS-12 or SS-14)" ;;
            esac
        done
        [[ -n "${EX_OWNER[$i]}" ]] || fail "EXEMPT entry $entry has no owner"
    done
    if [[ "${AID_RELEASE_CHECK:-0}" == "1" && $n -gt 0 ]]; then
        fail "EXEMPT list has $n row(s) under AID_RELEASE_CHECK=1; it must be empty for a release"
    fi
    pass "EXEMPT list read: $n row(s)"
    group_end
}

# ---------------------------------------------------------------------------
# SS-02: Dispatch-table and State-section skills cite skill-steps.md.
# ---------------------------------------------------------------------------
run_ss02() {
    group_begin "SS-02 skills with a Dispatch table or ## State: cite skill-steps.md"
    local f n=0 bad=0
    while IFS= read -r f; do
        if grep -q -E '^#{1,6} .*Dispatch|^## State:' "$f"; then
            n=$((n + 1))
            if grep -q 'skill-steps\.md' "$f"; then
                :
            else
                fail "SS-02 $f has a Dispatch table or a ## State: section and cites no skill-steps.md"
                bad=$((bad + 1))
            fi
        fi
    done < <(git ls-files -- ':(glob)canonical/skills/*/SKILL.md')
    [[ $bad -eq 0 ]] && pass "SS-02 $n SKILL.md file(s) with a Dispatch table or ## State: cite skill-steps.md"
    local legacy
    for legacy in canonical/aid/templates/shortcut-engine.md canonical/aid/templates/design-lifecycle.md; do
        [[ -f "$legacy" ]] || continue
        if grep -q 'skill-steps\.md' "$legacy"; then
            pass "SS-02 $legacy (while it exists) cites skill-steps.md"
        else
            fail "SS-02 $legacy exists and cites no skill-steps.md"
        fi
    done
    group_end
}

# ---------------------------------------------------------------------------
# SS-03: advance words; no PAUSE-FOR-USER word in canonical/.
# A `**Advance:**` line names one word: CHAIN, ASK, WAIT, PASS, CALL or HALT. A plain
# step name (an upper-case identifier, or an arrow to the next State) is a CHAIN.
# ---------------------------------------------------------------------------
run_ss03() {
    group_begin "SS-03 advance words and PAUSE-FOR-USER"
    local files=() f hits
    while IFS= read -r f; do
        exempt_for SS-03 "$f" && continue
        files+=("$f")
    done < <(git ls-files -- canonical)
    if [[ ${#files[@]} -eq 0 ]]; then
        fail "SS-03 no tracked canonical/ files to scan"
    else
        hits=$(python3 -c '
import re, sys
SIX = ("CHAIN", "ASK", "WAIT", "PASS", "CALL", "HALT")
ADV = re.compile(r"(?<![`])\*\*Advance:\*\*[ \t]+(.*)$")
TOK = re.compile(r"[A-Za-z][A-Za-z0-9-]*")
for path in sys.argv[1:]:
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    for num, line in enumerate(lines, 1):
        if "PAUSE-FOR-USER" in line:
            print(f"{path}:{num}: PAUSE-FOR-USER on the line")
        m = ADV.search(line)
        if not m:
            continue
        rest = m.group(1).lstrip("*` \t")
        if not rest or rest.startswith(chr(0x2192)):
            continue
        t = TOK.match(rest)
        if not t:
            print(f"{path}:{num}: **Advance:** names no advance word")
            continue
        word = t.group(0)
        if word in SIX:
            continue
        print(f"{path}:{num}: **Advance:** word {word} is not CHAIN, ASK, WAIT, PASS, CALL or HALT")
' "${files[@]}" 2>&1) || true
        if [[ -z "$hits" ]]; then
            pass "SS-03 every **Advance:** line in canonical/ names an allowed word; no PAUSE-FOR-USER"
        else
            while IFS= read -r f; do [[ -n "$f" ]] && fail "SS-03 $f"; done <<< "$hits"
        fi
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-08: the two state templates parse through the dashboard reader with no warning.
# ---------------------------------------------------------------------------
run_ss08() {
    group_begin "SS-08 state templates parse through the reader"
    local out rc
    out=$(PYTHONDONTWRITEBYTECODE=1 python3 -c '
import sys
from pathlib import Path
sys.path.insert(0, "dashboard")
from reader.parsers import parse_state_md
from reader.state_schema import parse_state_document
work = Path("canonical/aid/templates/work-state-template.yml").read_text(encoding="utf-8")
proj = Path("canonical/aid/templates/project-state-template.yml").read_text(encoding="utf-8")
checks = (
    ("work-state-template.yml", parse_state_md(work, "work-000", None).parse_warnings),
    ("project-state-template.yml", parse_state_document(proj, file_label="project-state-template.yml")[1]),
)
for name, warns in checks:
    print("OK " + name if not warns else "")
    for w in warns:
        print("WARN " + name + ": " + w)
' 2>&1)
    rc=$?
    if [[ $rc -ne 0 ]]; then
        fail "SS-08 the dashboard reader could not run (exit $rc): $out"
    else
        local line
        while IFS= read -r line; do
            case "$line" in
                OK\ *) pass "SS-08 ${line#OK } parses with no warning" ;;
                WARN\ *) fail "SS-08 ${line#WARN }" ;;
            esac
        done <<< "$out"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-11: no old phase name as data or logic.
# ---------------------------------------------------------------------------
ss11_lines() {
    awk -v F="$1" '
        /legacy-phase-map: begin/ { s = 1; next }
        /legacy-phase-map: end/   { s = 0; next }
        !s { print F ":" FNR ":" $0 }' "$1"
}

run_ss11() {
    group_begin "SS-11 no old phase name"
    local files=() f hits="" out
    local P_PHASE="phase: *(${OLD_PHASES})\\b"
    local P_FIELD="--field Phase --value (${OLD_PHASES})\\b"
    local P_QUOTED="[\"'](${OLD_PHASES})[\"']"
    local P_ENUM_AFTER="(${OLD_PHASES}) [\\\\]?\\| (${OLD_PHASES})\\b"
    local P_PHASEDOT="Phase\\.(${OLD_PHASES})\\b"
    local P_BACKTICK="\`(${OLD_PHASES})\`"
    while IFS= read -r f; do
        case "$f" in
            canonical/aid/scripts/summarize/*) continue ;;
            */tests/*|*/__tests__/*) continue ;;
            dashboard/reader/*/*|dashboard/server/*/*) continue ;;
        esac
        files+=("$f")
    done < <(git ls-files -- canonical/skills canonical/aid/templates canonical/aid/scripts \
        dashboard/home.html dashboard/scripts/writeback-state.sh dashboard/reader dashboard/server)
    if [[ ${#files[@]} -eq 0 ]]; then
        fail "SS-11 no tracked files in the phase-name scope"
    else
        for f in "${files[@]}"; do
            out=$(ss11_lines "$f" | grep -E -e "$P_PHASE" -e "$P_FIELD" -e "$P_QUOTED" \
                -e "$P_ENUM_AFTER" -e "$P_PHASEDOT" || true)
            [[ -n "$out" ]] && hits+="$out"$'\n'
            out=$(ss11_lines "$f" | grep -E -e "$P_BACKTICK" | grep -i -e 'phase' || true)
            [[ -n "$out" ]] && hits+="$out"$'\n'
        done
        local line
        while IFS= read -r line; do
            [[ -n "$line" ]] && fail "SS-11 old phase name: $line"
        done <<< "$hits"
        [[ -z "$hits" ]] && pass "SS-11 ${#files[@]} tracked file(s) in scope name no old phase"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-12: no hand-written finish.
# ---------------------------------------------------------------------------
run_ss12() {
    group_begin "SS-12 no hand-written finish"
    local files=() f hits
    while IFS= read -r f; do
        exempt_for SS-12 "$f" && continue
        files+=("$f")
    done < <(git ls-files -- canonical/skills canonical/aid/templates)
    if [[ ${#files[@]} -eq 0 ]]; then
        fail "SS-12 no tracked files in the finish scope"
    else
        hits=$(grep -I -H -n -E 'lifecycle: ["'"'"']?(Completed|Canceled)' -- "${files[@]}" || true)
        if [[ -z "$hits" ]]; then
            pass "SS-12 no hand-written lifecycle: Completed or Canceled outside the exempt list"
        else
            while IFS= read -r f; do [[ -n "$f" ]] && fail "SS-12 hand-written finish: $f"; done <<< "$hits"
        fi
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-14: the record's creator and writer.
# ---------------------------------------------------------------------------
run_ss14() {
    group_begin "SS-14 the gate creates and the writer writes the record"
    local files=() f hits is_exc t

    # (a) the gate's section 3a runs --create with --reading, --skill and --step.
    local sec3a
    sec3a=$(awk '/^### 3a\./{on=1; next} /^### 3b\./{on=0} on' "$GATE_DOC" 2>/dev/null)
    if [[ -z "$sec3a" ]]; then
        fail "SS-14(a) $GATE_DOC has no section 3a"
    else
        local opt missing=""
        for opt in 'writeback-state.sh --create' '--reading' '--skill' '--step'; do
            grep -q -F -e "$opt" <<< "$sec3a" || missing+=" $opt"
        done
        if [[ -z "$missing" ]]; then
            pass "SS-14(a) section 3a runs writeback-state.sh --create with --reading, --skill and --step"
        else
            fail "SS-14(a) section 3a lacks:$missing"
        fi
    fi

    # (b) no record key, template copy or hand-written record block outside the exceptions.
    while IFS= read -r f; do
        exempt_for SS-14 "$f" && continue
        is_exc=0
        for t in "${SS14_TEMPLATE_EXCEPTIONS[@]}"; do [[ "$f" == "$t" ]] && is_exc=1; done
        [[ $is_exc -eq 1 ]] && continue
        files+=("$f")
    done < <(git ls-files -- canonical/skills canonical/aid/templates)
    if [[ ${#files[@]} -eq 0 ]]; then
        fail "SS-14(b) no tracked files in the record scope"
    else
        hits=$(grep -I -H -n -E -e 'initiator:' -e '[Cc]opy.*work-state-template\.yml' \
            -e 'work-state-template\.yml` to\b' -e '^(active_skill|step|step_detail|phase):' \
            -- "${files[@]}" || true)
        if [[ -z "$hits" ]]; then
            pass "SS-14(b) no record key, template copy or hand-written record block outside the exceptions"
        else
            while IFS= read -r f; do [[ -n "$f" ]] && fail "SS-14(b) $f"; done <<< "$hits"
        fi
    fi

    # (c) skill-steps.md section "The work record" carries the fail-closed and recovery rules.
    local rec
    rec=$(awk '/^## The work record/{on=1; next} /^## /{on=0} on' "$STEPS_DOC" 2>/dev/null)
    if [[ -n "$rec" ]] && grep -q -E '^### Fail-closed' <<< "$rec" && grep -q -E '^### Recovery' <<< "$rec"; then
        pass "SS-14(c) skill-steps.md section The work record has the fail-closed and recovery rules"
    else
        fail "SS-14(c) skill-steps.md section The work record lacks the fail-closed or recovery rule"
    fi

    # (d) no continuation routed by a skill itself.
    files=()
    while IFS= read -r f; do
        [[ "$f" == "$GATE_DOC" ]] && continue
        files+=("$f")
    done < <(git ls-files -- canonical/skills canonical/aid/templates)
    hits=$(grep -I -H -n -E -e 'resume door' -e '`?phase`?-matched' \
        -e '[A-Z][a-z]+-phase work' -e 'route per the chosen work' -- "${files[@]}" || true)
    if [[ -z "$hits" ]]; then
        pass "SS-14(d) no skill routes a continuation itself"
    else
        while IFS= read -r f; do [[ -n "$f" ]] && fail "SS-14(d) continuation routed by a skill: $f"; done <<< "$hits"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------
echo "=== Skill step rules (Feature 002 section 8) ==="

if [[ -z "$GROUP" || "$GROUP" == SS-03 || "$GROUP" == SS-12 || "$GROUP" == SS-14 ]]; then
    exempt_list_check
fi
wants SS-02 && run_ss02
wants SS-03 && run_ss03
wants SS-08 && run_ss08
wants SS-11 && run_ss11
wants SS-12 && run_ss12
wants SS-14 && run_ss14

test_summary
exit $?
