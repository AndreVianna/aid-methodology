#!/usr/bin/env bash
# test-skill-steps.sh - Static checks for the step rules of Feature 002 (section 8, groups
# SS-01 to SS-14; SS-04 to SS-07, SS-09, SS-10 and SS-13 are the conversation and agent rules).
#
# COVERS: canonical/skills/
# COVERS: canonical/agents/
# COVERS: canonical/aid/templates/
# COVERS: canonical/aid/scripts/
# COVERS: chat-node/
# COVERS: dashboard/
# COVERS: docs/
# COVERS: examples/
# COVERS: site/scripts/
# COVERS: site/src/content/
# COVERS: tests/canonical/skill-steps-exempt.tsv
# COVERS: tests/conversation/deferred.tsv
# COVERS: tests/conversation/samples/
#
#   SS-01  no banner line (`[State: X]`, `you are here`, `Advancing to [State`, `[State N] Dispatching`,
#          `[Resolved:`, `Re-run /aid-`) under canonical/skills/ or canonical/aid/templates/; a line that is
#          an advance line (`**Advance:**`, or an advance word followed by an arrow) may name a target
#   SS-02  every SKILL.md with a Dispatch table or a `## State:` section cites skill-steps.md;
#          shortcut-engine.md and design-lifecycle.md, while they exist, cite it too; the chaining
#          file is absent and cited nowhere in canonical/, tests/canonical/, site/scripts/, docs/,
#          examples/ or dashboard/
#   SS-03  no `**Advance:**` line uses a word other than CHAIN, ASK, WAIT, PASS, CALL, HALT
#          (a line naming only its next step is a CHAIN, written with the word and the arrow:
#          `**Advance:** CHAIN → NAME`; a bare arrow with no word, and a bare name with no arrow, are
#          flagged; only the plain note "line is at the end of this file" is not an advance line);
#          no PAUSE-FOR-USER word in canonical/
#   SS-04  every hand-authored SKILL.md (and, while shortcut-engine.md exists, the generated doorways
#          through it) cites question-protocol.md, except the never-asks list (aid-chat and
#          aid-unset-connector, each of which must exist); no AskUserQuestion in any allowed-tools
#   SS-05  no canonical/agents/aid-interviewer/; the word interviewer, in any case, appears nowhere in
#          canonical/agents/, canonical/skills/, canonical/aid/templates/, docs/, examples/ or
#          site/src/content/
#   SS-06  no file under canonical/skills/ names `## Cross-phase Q&A`, and no line sends a question to a
#          delivery-level qa
#   SS-07  nothing under chat-node/ names `.aid/works` or `STATE.yml`
#   SS-08  work-state-template.yml and project-state-template.yml parse through the dashboard
#          reader with no warning
#   SS-09  every asking skill (each SKILL.md citing the protocol, and the generated doorways through
#          shortcut-engine.md) has a sample under tests/conversation/samples/ whose frontmatter skills:
#          names it and whose covers holds AC-28, or a skill: row of tests/conversation/deferred.tsv
#          that matches it
#   SS-10  canonical/aid/templates/agent-boilerplate.md has the `## Talking with the user` section; every
#          canonical/agents/*/AGENT.md includes {{include:agent-boilerplate}}; no AGENT.md tells its
#          agent to ask the user
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
#   SS-13  each of canonical/agents/aid-reviewer/AGENT.md, canonical/aid/templates/reviewer-dispatch.md
#          and every canonical/skills/*/references/reviewer-brief.md has a `### What to report` heading
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
    local f n=0 bad=0 chain_hits
    # The chaining file is retired: absent, and cited nowhere in the scope the spec names. This
    # suite names the file in its own rules, so it is the one file the scan skips.
    if [[ -e canonical/aid/templates/state-machine-chaining.md ]]; then
        fail "SS-02 canonical/aid/templates/state-machine-chaining.md still exists; skill-steps.md replaces it"
    else
        pass "SS-02 state-machine-chaining.md is absent"
    fi
    chain_hits=$(git grep -l -F 'state-machine-chaining' -- canonical tests/canonical site/scripts docs \
        examples dashboard ':!tests/canonical/test-skill-steps.sh' || true)
    if [[ -z "$chain_hits" ]]; then
        pass "SS-02 no file in the chaining scope cites state-machine-chaining"
    else
        while IFS= read -r f; do [[ -n "$f" ]] && fail "SS-02 $f cites state-machine-chaining"; done <<< "$chain_hits"
    fi
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
# A `**Advance:**` line names one word: CHAIN, ASK, WAIT, PASS, CALL or HALT (`ASK then HALT` starts with
# ASK). A bare `**Advance:**` takes its word from the next non-blank line; one with no word at all fails.
# A line that names only its next step is a CHAIN written with the word (skill-steps.md, The step table:
# `CHAIN → NAME`); a line that starts with the arrow and no word fails. The one other skip is the exact
# prose note "this step's one **Advance:** line is at the end of this file", which points at the line.
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
ADV = re.compile(r"(?<![`])\*\*Advance:\*\*[ \t]*(.*)$")
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
        if not rest:  # the word wraps to the next line: read the next non-blank line
            nxt = num
            while nxt < len(lines) and not lines[nxt].strip():
                nxt += 1
            rest = lines[nxt].strip().lstrip("*` \t") if nxt < len(lines) else ""
            if not rest:
                print(f"{path}:{num}: **Advance:** names no advance word")
                continue
        if rest.startswith(chr(0x2192)):
            print(f"{path}:{num}: **Advance:** is a bare arrow with no advance word (write CHAIN → NAME)")
            continue
        if rest.startswith("line is at the end of this file"):  # the plain note that points at the advance line
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
# SS-01: no banner form under canonical/skills/ or canonical/aid/templates/.
# A line that is an advance line keeps its `[State: X]` target (skill-steps.md, The step table):
# a line that carries `**Advance:**`, or an advance word followed by an arrow, is not a banner.
# ---------------------------------------------------------------------------
run_ss01() {
    group_begin "SS-01 no banner form (Steps and hand-offs)"
    local hits
    hits=$(git grep -n -I -E -e '\[State: ' -e 'you are here' -e 'Advancing to \[State' \
        -e '\[State [0-9]+\] Dispatching' -e '\[Resolved:' -e 'Re-run `/aid-' \
        -- canonical/skills canonical/aid/templates \
        | grep -v -E 'Advance|(CHAIN|ASK|WAIT|PASS|CALL|HALT)\*{0,2} →' || true)
    if [[ -z "$hits" ]]; then
        pass "SS-01 no banner line under canonical/skills/ or canonical/aid/templates/"
    else
        local h
        while IFS= read -r h; do [[ -n "$h" ]] && fail "SS-01 banner form: $h"; done <<< "$hits"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-04: every asking skill cites question-protocol.md; no AskUserQuestion in allowed-tools.
# ---------------------------------------------------------------------------
SS04_NEVER_ASKS=(aid-chat aid-unset-connector)
ENGINE_DOC="canonical/aid/templates/shortcut-engine.md"

# first_heading FILE -- the first `# ` heading of FILE ("# Shortcut..." marks a generated doorway).
first_heading() { grep -m1 '^# ' "$1" 2>/dev/null || true; }

run_ss04() {
    group_begin "SS-04 asking skills cite question-protocol.md; no AskUserQuestion"
    local f name x is_never hand=0 gen=0 bad=0 hits engine_cites=0
    if [[ -f "$ENGINE_DOC" ]] && grep -q 'question-protocol\.md' "$ENGINE_DOC"; then engine_cites=1; fi
    for x in "${SS04_NEVER_ASKS[@]}"; do
        if [[ -f "canonical/skills/$x/SKILL.md" ]]; then
            pass "SS-04 never-asks skill $x exists"
        else
            fail "SS-04 never-asks skill $x does not exist; remove it from the never-asks list"
        fi
    done
    while IFS= read -r f; do
        name=$(basename "$(dirname "$f")")
        is_never=0
        for x in "${SS04_NEVER_ASKS[@]}"; do [[ "$name" == "$x" ]] && is_never=1; done
        [[ $is_never -eq 1 ]] && continue
        if [[ "$(first_heading "$f")" == "# Shortcut"* ]]; then
            gen=$((gen + 1))
            if [[ $engine_cites -ne 1 ]]; then
                fail "SS-04 generated doorway $f asks through $ENGINE_DOC, which cites no question-protocol.md"
                bad=$((bad + 1))
            fi
        elif grep -q 'question-protocol\.md' "$f"; then
            hand=$((hand + 1))
        else
            fail "SS-04 $f is hand-authored, is not a never-asks skill, and cites no question-protocol.md"
            bad=$((bad + 1))
        fi
    done < <(git ls-files -- ':(glob)canonical/skills/*/SKILL.md')
    [[ $bad -eq 0 ]] && pass "SS-04 $hand hand-authored and $gen generated asking SKILL.md file(s) cite the protocol"

    hits=$(git grep -n -I -E '^allowed-tools:.*AskUserQuestion' -- canonical || true)
    if [[ -z "$hits" ]]; then
        pass "SS-04 no AskUserQuestion in any allowed-tools"
    else
        while IFS= read -r f; do [[ -n "$f" ]] && fail "SS-04 AskUserQuestion in allowed-tools: $f"; done <<< "$hits"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-05: no aid-interviewer agent; the word interviewer nowhere in the scoped paths.
# ---------------------------------------------------------------------------
run_ss05() {
    group_begin "SS-05 no aid-interviewer agent; the word interviewer nowhere"
    if [[ -e canonical/agents/aid-interviewer || -n "$(git ls-files -- canonical/agents/aid-interviewer)" ]]; then
        fail "SS-05 canonical/agents/aid-interviewer exists"
    else
        pass "SS-05 canonical/agents/aid-interviewer is absent"
    fi
    local hits
    hits=$(git grep -n -I -i -F 'interviewer' -- canonical/agents canonical/skills canonical/aid/templates \
        docs examples site/src/content || true)
    if [[ -z "$hits" ]]; then
        pass "SS-05 the word interviewer appears in none of the scoped paths"
    else
        local h
        while IFS= read -r h; do [[ -n "$h" ]] && fail "SS-05 interviewer: $h"; done <<< "$hits"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-06: no Cross-phase Q&A section under canonical/skills/; no question sent to a delivery-level qa.
# ---------------------------------------------------------------------------
run_ss06() {
    group_begin "SS-06 no Cross-phase Q&A section; no question to a delivery-level qa"
    local hits h
    hits=$(git grep -n -I -F -e '## Cross-phase Q&A' -- canonical/skills || true)
    if [[ -z "$hits" ]]; then
        pass "SS-06 no ## Cross-phase Q&A section under canonical/skills/"
    else
        while IFS= read -r h; do [[ -n "$h" ]] && fail "SS-06 Cross-phase Q&A section: $h"; done <<< "$hits"
    fi
    hits=$(git grep -n -I -i -E 'delivery[^.]{0,40}\bqa\b' -- canonical/skills \
        | grep -i -E -e '--ask' -e 'question' -e 'record' -e 'asked' || true)
    if [[ -z "$hits" ]]; then
        pass "SS-06 no line under canonical/skills/ sends a question to a delivery-level qa"
    else
        while IFS= read -r h; do [[ -n "$h" ]] && fail "SS-06 question sent to a delivery-level qa: $h"; done <<< "$hits"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-07: nothing under chat-node/ names .aid/works or STATE.yml.
# ---------------------------------------------------------------------------
run_ss07() {
    group_begin "SS-07 chat-node names no .aid/works or STATE.yml"
    local hits h
    hits=$(git grep -n -I -E -e '\.aid/works' -e 'STATE\.yml' -- chat-node || true)
    if [[ -z "$hits" ]]; then
        pass "SS-07 nothing under chat-node/ names .aid/works or STATE.yml"
    else
        while IFS= read -r h; do [[ -n "$h" ]] && fail "SS-07 $h"; done <<< "$hits"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-09: every asking skill has an AC-28 sample naming it, or a skill: row of the deferred list.
# ---------------------------------------------------------------------------
read -r -d '' SS09_PY <<'PY' || true
import fnmatch, glob, pathlib, re, subprocess

NEVER = {"aid-chat", "aid-unset-connector"}

def read(path):
    return pathlib.Path(path).read_text(encoding="utf-8", errors="replace")

def tracked(pattern):
    out = subprocess.run(["git", "ls-files", "-z", "--", pattern], capture_output=True, text=True).stdout
    return [p for p in out.split("\0") if p]

def frontmatter(path):
    lines = read(path).split("\n")
    fields = {}
    if not lines or lines[0].strip() != "---":
        return fields
    for line in lines[1:]:
        if line.strip() == "---":
            break
        m = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if m:
            fields[m.group(1)] = m.group(2).strip()
    return fields

# AC-28 samples: the skills each one names, when it covers AC-28.
ac28 = set()
for sample in sorted(glob.glob("tests/conversation/samples/**/*.md", recursive=True)):
    fields = frontmatter(sample)
    covers = [c.strip() for c in fields.get("covers", "").split(",")]
    if "AC-28" in covers:
        ac28.update(n for n in re.split(r"[,\s]+", fields.get("skills", "")) if n)

# skill: rows of the deferred list (the glob after the prefix).
rows = []
for line in read("tests/conversation/deferred.tsv").replace("\r", "").split("\n")[1:]:
    cols = line.split("\t")
    if cols and cols[0].startswith("skill:"):
        rows.append(cols[0][len("skill:"):])

# The asking set: each SKILL.md that cites the protocol, and the generated doorways when the
# engine that asks for them cites it.
engine_cites = pathlib.Path("canonical/aid/templates/shortcut-engine.md").is_file() and \
    "question-protocol.md" in read("canonical/aid/templates/shortcut-engine.md")
asking = []
for path in tracked(":(glob)canonical/skills/*/SKILL.md"):
    name = pathlib.Path(path).parent.name
    if name in NEVER:
        continue
    text = read(path)
    first = next((l for l in text.split("\n") if l.startswith("# ")), "")
    if first.startswith("# Shortcut"):
        if engine_cites:
            asking.append(name)
    elif "question-protocol.md" in text:
        asking.append(name)

bad = 0
for name in asking:
    if name in ac28 or any(fnmatch.fnmatchcase(name, pat) for pat in rows):
        continue
    bad += 1
    print("FAIL SS-09 asking skill " + name + " has neither an AC-28 sample naming it nor a skill: row")
if not bad:
    print("PASS SS-09 " + str(len(asking)) + " asking skill(s): each has an AC-28 sample or a skill: row")
PY

run_ss09() {
    group_begin "SS-09 every asking skill has an AC-28 sample or a skill: row"
    local out line
    out=$(python3 -c "$SS09_PY" 2>&1) || true
    if [[ -z "$out" ]]; then
        fail "SS-09 the coverage check printed nothing (it could not run)"
    else
        while IFS= read -r line; do
            case "$line" in
                PASS\ *) pass "${line#PASS }" ;;
                FAIL\ *) fail "${line#FAIL }" ;;
                *) fail "SS-09 $line" ;;
            esac
        done <<< "$out"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-10: the agent boilerplate section, the include in every AGENT.md, no ask-the-user line.
# ---------------------------------------------------------------------------
run_ss10() {
    group_begin "SS-10 agents: boilerplate section, include, no ask-the-user"
    local f n=0 bad=0 hits h
    if grep -q -E '^## Talking with the user[[:space:]]*$' canonical/aid/templates/agent-boilerplate.md 2>/dev/null; then
        pass "SS-10 agent-boilerplate.md has the ## Talking with the user section"
    else
        fail "SS-10 canonical/aid/templates/agent-boilerplate.md has no ## Talking with the user section"
    fi
    while IFS= read -r f; do
        n=$((n + 1))
        if ! grep -q -F '{{include:agent-boilerplate}}' "$f"; then
            fail "SS-10 $f does not include {{include:agent-boilerplate}}"
            bad=$((bad + 1))
        fi
    done < <(git ls-files -- ':(glob)canonical/agents/*/AGENT.md')
    [[ $bad -eq 0 ]] && pass "SS-10 $n AGENT.md file(s) include {{include:agent-boilerplate}}"
    hits=$(git grep -n -I -i -E -e 'AskUserQuestion' -e 'ask the user' -- ':(glob)canonical/agents/*/AGENT.md' || true)
    if [[ -z "$hits" ]]; then
        pass "SS-10 no AGENT.md tells its agent to ask the user"
    else
        while IFS= read -r h; do [[ -n "$h" ]] && fail "SS-10 AGENT.md asks the user: $h"; done <<< "$hits"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# SS-13: each reviewer definition, dispatch template and reviewer brief has a ### What to report heading.
# ---------------------------------------------------------------------------
run_ss13() {
    group_begin "SS-13 reviewer definition, dispatch template and briefs have ### What to report"
    local f n=0 bad=0
    local files=(canonical/agents/aid-reviewer/AGENT.md canonical/aid/templates/reviewer-dispatch.md)
    while IFS= read -r f; do files+=("$f"); done < <(git ls-files -- ':(glob)canonical/skills/*/references/reviewer-brief.md')
    for f in "${files[@]}"; do
        n=$((n + 1))
        if [[ -f "$f" ]] && grep -q -E '^### What to report[[:space:]]*$' "$f"; then
            :
        else
            fail "SS-13 $f has no ### What to report heading (FR-21)"
            bad=$((bad + 1))
        fi
    done
    [[ $bad -eq 0 ]] && pass "SS-13 $n file(s) have a ### What to report heading"
    group_end
}

# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------
echo "=== Skill step rules (Feature 002 section 8) ==="

if [[ -z "$GROUP" || "$GROUP" == SS-03 || "$GROUP" == SS-12 || "$GROUP" == SS-14 ]]; then
    exempt_list_check
fi
wants SS-01 && run_ss01
wants SS-02 && run_ss02
wants SS-03 && run_ss03
wants SS-04 && run_ss04
wants SS-05 && run_ss05
wants SS-06 && run_ss06
wants SS-07 && run_ss07
wants SS-08 && run_ss08
wants SS-09 && run_ss09
wants SS-10 && run_ss10
wants SS-11 && run_ss11
wants SS-12 && run_ss12
wants SS-13 && run_ss13
wants SS-14 && run_ss14

test_summary
exit $?
