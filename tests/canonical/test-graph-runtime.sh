#!/usr/bin/env bash
# test-graph-runtime.sh -- the /aid-graph skill runtime: its structure, its gates, and
# the scripts that decide whether a run may start (feature-010, work-005-knowledge-graph).
#
# ONE OF THREE SUITES. The split is by SUBJECT-INVOCATION COST, not by topic:
#   test-graph-runtime.sh         this file. Structure, contracts, preflight, the write
#                                 fence, --help honesty, the ceiling carrier, the gate's
#                                 argument refusals, floor resolution, and every verdict
#                                 arm of the staleness check.
#   test-graph-runtime-digest.sh  the digest's component matrix: one mutation per input,
#                                 two per input with two arms, both negatives. Nineteen
#                                 invocations, each a different input by construction.
#   test-graph-runtime-gate.sh    the end-to-end pipeline chain, the coverage-notes
#                                 assembly, the FR-28 rubric over a page, and the ledger's
#                                 round trip.
#
# RUNTIME SHAPE, AND WHY IT IS WHAT IT IS
#   Measured on the Windows Git Bash shell this work is authored on:
#     a fork costs ~70 ms; 100 command substitutions cost 7.25 s
#     graph-stale-check.sh  8.3 s per invocation   grade-graph.sh (full)  7.4 s
#     graph-preflight.sh    2.7 s                  kb-write-fence.sh      1.6-2.1 s
#     any script --help     0.3-0.7 s              read-setting.sh        0.5 s
#   Cost is dominated by PROCESS SPAWNS, not by input size, so the suite spends its budget
#   on subject invocations and almost nothing on its own assertions:
#
#     SUBJECT INVOCATIONS: 47, and each one is a DISTINCT input the contract names --
#       5   --help, one per script (the flag set is per-script)
#       7   read-setting.sh: four resolution steps + --probe's usage error, declared,
#           and undeclared states (D4a, task-030/W5-8 -- it is no longer unsupported)
#       9   graph-preflight.sh: P1, P2, P3, P4, P6, P7, the P2-scoping fixture, the
#           external-sources non-refusal, and an unknown flag
#      12   kb-write-fence.sh: allowlist, fail-closed verify, two snapshots (idempotence),
#           clean verify, allowlisted-write verify, three violation directions, all three
#           at once, mode conflict, vacuous-fence refusal
#       5   grade-graph.sh: three argument refusals, one floor-resolution run, one --grade
#           run (the two differ by the flag under test, so they cannot share a run)
#       9   graph-stale-check.sh: absent stream, FIRST_RUN, the second run that proves
#           IDEMPOTENCE, CURRENT, --reset, missing-page STALE, --reset with no artifact,
#           and the two the view-out-of-scope arm needs (its `tool` component differs, so
#           it cannot reuse the in-scope baseline digest)
#     There is no invocation here that a second assertion could have shared: every one
#     changes the fixture, the flag, or the install.
#
#     THE SUITE'S OWN ASSERTIONS ARE FORK-FREE. Every shipped file is read ONCE with
#     `$(<file)` (a bash builtin read, no subprocess) into TXT[], and every check after
#     that is `[[ ]]`, parameter expansion, or a `read` builtin over a here-string. There
#     is no per-assertion grep, awk, sed, cut or wc anywhere in this file -- SF07 asserts
#     that mechanically, over this file's own source.
#
#     BEFORE / AFTER this restructuring, same assertions, same subjects:
#       wall clock            192 s  ->  see the run log
#       subject invocations      45  ->  45   (none was ever redundant)
#       own forks per run     ~375  ->  ~20   (the whole delta is S2)
#       mutation matrix     inline  ->  --self-mutate (CI pays one assertion pass)
#
# WHAT THIS FILE COVERS
#   graph-preflight.sh    P1-P7, the one non-refusal, and "writes nothing" asserted as an
#                         empty fixture diff rather than as a message
#   kb-write-fence.sh     the allowlist, the snapshot's completeness over the complement,
#                         all three violation directions and all three at once, and the
#                         fail-closed verify
#   grade-graph.sh        the argument refusals, the floor read through the project's one
#                         resolver, and --grade proven non-persisting byte-for-byte
#   graph-stale-check.sh  every verdict arm, and that no arm is a failure
#   the state machine     eleven states, sixteen edges, nine departures, and the two
#                         delimiter defects the Dispatch table has actually had
#   the shipped content   what the profile renderer does to it, and what it must not carry
#
# WHAT IS DELIBERATELY NOT HERE
#   * RENDER. The view has no canvas module yet (deliberately unbuilt, pending research
#     the owner commissioned), so there is no assembly to invoke. Stated as uncovered
#     rather than approximated.
#   * VISUAL-GATE, FIX and DONE as state machines. They are prompt-driven prose, which
#     this project covers by dogfooding and human review, not by a bash suite. What IS
#     asserted is every script those states drive, plus the structure of their routing.
#   * Any browser. Runtime UI verification does not belong in the required suite.
#   * Any suite count, and any ceiling figure. The first is stale in the Knowledge Base
#     and is the owner's to correct; the second is a measurement that has not landed, so
#     this suite writes its own fixture value and asserts none.
#   * Any `.aid/works/` path. Work folders are transient by project rule, so every fixture
#     is built under `mktemp -d` from the committed tree.
#
# SPEC HOOK IDS
#   SR01-SR18 appear in brackets inside a label, never as its prefix:
#   tests/canonical/test-graph-schema-loader.sh already carries an unrelated SR01-SR15
#   series for its slug rules, and two suites emitting the same bare label would make an
#   aggregated FAIL line ambiguous. The prefix is this suite's own scope; the bracketed
#   hook is what traces back to the acceptance criteria.
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
#   Each line is a reviewable claim. The five scripts are named individually because they
#   are the only ones this suite installs or reads: a sibling in the same directory cannot
#   reach it. The shared config resolver and grade.sh are named because make_install copies
#   them into every fixture install, so a change to either lands inside the subject.
# COVERS: canonical/skills/aid-graph/
# COVERS: canonical/aid/templates/graph/
# COVERS: canonical/aid/scripts/graph/graph-preflight.sh
# COVERS: canonical/aid/scripts/graph/graph-stale-check.sh
# COVERS: canonical/aid/scripts/graph/kb-write-fence.sh
# COVERS: canonical/aid/scripts/graph/grade-graph.sh
# COVERS: canonical/aid/scripts/graph/assemble-coverage-notes.sh
# COVERS: canonical/aid/scripts/config/read-setting.sh
# COVERS: canonical/aid/scripts/grade.sh
# COVERS: tests/lib/assert.sh
# COVERS: tests/canonical/test-graph-runtime.sh
#
# Usage:
#   bash test-graph-runtime.sh [-v | --verbose]
#   bash test-graph-runtime.sh --group FN[,GG...]   # one assertion group, for debugging
#   bash test-graph-runtime.sh --self-mutate        # mutation-test THIS suite
#
#   --group runs one class and the setup it needs, so a one-line fix is verified against
#   the group that covers it rather than against the whole suite. The groups are
#   SS ST RD TS NF HH CE PF FN GG VA SF (each is the label prefix its assertions carry).
#   Fixtures are built lazily, so a group that needs no install root pays for none.
#
#   --self-mutate copies the subject (scripts, skill directory or template directory)
#   into a mktemp dir, mutates the COPY by exact-string replacement, and re-runs this
#   suite against the copy requiring a non-zero exit. The committed tree is never
#   written: a sibling suite mutated canonical/ in place and a quota kill left the edit
#   behind, so the window between mutate and restore is a liability no result justifies.
#   `mutate_apply` aborts unless the anchor occurs EXACTLY once and the write changed the
#   bytes, and every mutant re-digests the committed sources afterwards.
#
# Environment (the seams --self-mutate drives; unset in a normal run):
#   GRAPH_SCRIPTS_DIR     the five scripts under test
#   AID_GRAPH_SKILL_DIR   the skill directory (SKILL.md + references/)
#   AID_GRAPH_TPL_DIR     canonical/aid/templates/graph
#
# Exit codes:
#   0 -- all assertions passed (skips are reported, and never counted as passes)
#   1 -- one or more assertions failed

set -u

VERBOSE=0
MODE="assert"
ONLY=""
while [ $# -gt 0 ]; do
    case "$1" in
        -v|--verbose)  VERBOSE=1; shift ;;
        --self-mutate) MODE="mutate"; shift ;;
        --group)       ONLY="${ONLY} ${2:?--group needs a group name}"; shift 2 ;;
        "")            shift ;;
        *) echo "test-graph-runtime.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
done
ONLY="${ONLY//,/ }"

# Is a class in scope for this run? With no --group, every class is.
want() { [[ -z "$ONLY" ]] || [[ " $ONLY " == *" $1 "* ]]; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Absolute: this suite cd's into its fixtures, and a relative self-path would make
# every self-check read an absent file and report an empty count.
SELF_SRC="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"

source "${SCRIPT_DIR}/../lib/assert.sh"

# A skip is NOT a pass. tests/lib/assert.sh has no notion of one (verified: no skip
# outcome in it, and its most recent commit is a pipe-safety fix), so this suite counts
# them separately, always prints them, and lists them in its own summary -- the shape
# test-graph-view.sh:82 and test-graph-gap-ledger.sh:107 already use.
SKIP=0
SKIPPED=()
skip() { SKIP=$((SKIP + 1)); SKIPPED+=("$*"); echo "  SKIP: $*"; }

GRAPH_SRC="${GRAPH_SCRIPTS_DIR:-${REPO_ROOT}/canonical/aid/scripts/graph}"
SKILL_DIR="${AID_GRAPH_SKILL_DIR:-${REPO_ROOT}/canonical/skills/aid-graph}"
TPL_GRAPH="${AID_GRAPH_TPL_DIR:-${REPO_ROOT}/canonical/aid/templates/graph}"
SKILL_MD="${SKILL_DIR}/SKILL.md"
REFS="${SKILL_DIR}/references"
CEILING_YML="${TPL_GRAPH}/scale-ceiling.yml"

MINE=(graph-preflight.sh graph-stale-check.sh kb-write-fence.sh grade-graph.sh
      assemble-coverage-notes.sh)

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Fork-free helpers.
#
# Each returns through a named global rather than stdout: a `$(...)` capture forks, and
# at ~70 ms a fork the capture costs more than everything it computes. Measured: 100
# command substitutions 7.25 s, the same work in builtins 0.16 s.
# ---------------------------------------------------------------------------

T=""        # trim
N=0         # counters
CEIL=""     # read_ceiling
CV=""       # ceiling_verdict
A1=""       # adv_first_target
DIG=""      # digest_of
VER=""      # verdict_of
CHG=""      # changed_of

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; T="${s%"${s##*[![:space:]]}"}"; }

# Occurrences of a LITERAL substring. Never `grep -c ... || echo 0`, which emits "0\n0"
# when grep also exits non-zero and then compares as neither -- a known false-PASS shape.
sub_count() {
    local hay="$1" ned="$2" n=0
    while [[ "$hay" == *"$ned"* ]]; do hay="${hay#*"$ned"}"; n=$((n + 1)); done
    N="$n"
}

# Containment, as an outcome. Same argument order as assert_output_contains, so the
# conversion from it was mechanical; the difference is that this one does not fork.
ok_contains() {
    local hay="$1" ned="$2" label="$3"
    if [[ "$hay" == *"$ned"* ]]; then
        pass "$label"
    else
        fail "$label — pattern not found: '$ned'"
        [[ "$VERBOSE" -eq 1 ]] && { echo "---HAYSTACK---"; echo "$hay"; echo "---END---"; }
    fi
}
ok_not_contains() {
    local hay="$1" ned="$2" label="$3"
    if [[ "$hay" != *"$ned"* ]]; then
        pass "$label"
    else
        fail "$label — unexpected pattern found: '$ned'"
    fi
}

# Assert a set is non-empty BEFORE any universal claim is made over it -- a universal
# over an empty set is vacuously true and is another known false-PASS shape.
assert_nonempty() {
    local n="$1" label="$2"
    if [[ "${n:-0}" -gt 0 ]]; then
        pass "$label (n=$n)"
    else
        fail "$label — the set is EMPTY, so any universal claim over it would be vacuous"
    fi
}

# Every shipped file, read once. `$(<file)` is a builtin read: no subprocess.
declare -A TXT=()
load_txt() { TXT["$1"]=$(<"$2"); }

# Scan this suite's own EXECUTABLE lines for a forbidden idiom, fork-free. Comment lines
# and the self-check class itself are skipped: an assertion whose label quotes the idiom
# it forbids is not an occurrence of it -- counting it would be the checker matching its
# own description. The pattern is an ERE, evaluated by bash's own =~.
self_code_count() {
    local pat="$1" line n=0
    while IFS= read -r line; do
        trim "$line"
        [[ "${T:0:1}" == "#" ]] && continue
        [[ "$line" == *SF[0-9][0-9]* ]] && continue
        [[ "$line" == *self_code_count* ]] && continue
        [[ "$line" =~ $pat ]] && n=$((n + 1))
    done < "$SELF_SRC"
    N="$n"
}

# The ceiling read, byte-for-byte equivalent to the sed command
# references/state-extract.md prescribes: the first node_ceiling line only, and a value
# that does not START with a digit reads as UNSET rather than as 0.
read_ceiling() {
    local line rest d i ch
    CEIL=""
    while IFS= read -r line; do
        [[ "$line" == node_ceiling:* ]] || continue
        rest="${line#node_ceiling:}"
        trim "$rest"; rest="$T"
        d=""; i=0
        while (( i < ${#rest} )); do
            ch="${rest:i:1}"
            [[ "$ch" == [0-9] ]] || break
            d+="$ch"; i=$((i + 1))
        done
        CEIL="$d"
        return 0
    done < "$1"
}

# The comparison the run makes. An absent ceiling must compare against NOTHING; it must
# never fall back to a number this suite invented.
ceiling_verdict() {
    read_ceiling "$1"
    local total="$2"
    if [[ -z "$CEIL" ]]; then
        CV="no-comparison total=${total}"
    elif [[ "$total" -gt "$CEIL" ]]; then
        CV="warn total=${total} ceiling=${CEIL}"
    else
        CV="quiet total=${total} ceiling=${CEIL}"
    fi
}

# graph-stale-check.sh's output, read without forking.
digest_of() {
    local line
    DIG=""
    while IFS= read -r line; do
        if [[ "$line" == "graph_inputs_digest: "* ]]; then
            DIG="${line#graph_inputs_digest: }"
            return 0
        fi
    done <<< "$1"
}
verdict_of() {                       # the verdict is the LAST stdout line, by contract
    local line
    VER=""
    while IFS= read -r line; do VER="$line"; done <<< "$1"
}
changed_of() {
    local line pre="[stale-check] changed components:"
    CHG=""
    while IFS= read -r line; do
        if [[ "$line" == "$pre"* ]]; then
            trim "${line#"$pre"}"; CHG="$T"
            return 0
        fi
    done <<< "$1"
}

# The first `→ TARGET` in a string, where TARGET is [A-Z][A-Z-]*. A `→ halt` is skipped
# rather than consumed, which is what awk's match() does too.
adv_first_target() {
    local s="$1" tgt ch i
    A1=""
    while [[ "$s" == *"→ "* ]]; do
        s="${s#*"→ "}"
        tgt=""; i=0
        while (( i < ${#s} )); do
            ch="${s:i:1}"
            [[ "$ch" == [A-Z] || "$ch" == "-" ]] || break
            tgt+="$ch"; i=$((i + 1))
        done
        if [[ -n "$tgt" ]]; then A1="$tgt"; return 0; fi
    done
}

# Build a self-contained fixture project. The TEMPLATE is built once (1.1 s, mostly
# `git init`) and every later fixture is a copy of it (0.24 s) -- six fresh builds cost
# 6.6 s and buy nothing, because each caller mutates the copy afterwards anyway.
PROJ_TEMPLATE="$TMP/_project-template"
build_project_template() {
    local d="$1" i
    mkdir -p "$d/.aid/knowledge" "$d/.aid/.temp/graph" "$d/src" "$d/docs/img"
    ( cd "$d" && git init -q . && git config user.email t@example.com && git config user.name t )
    printf -- '---\nkb-category: meta\nkb_status: Approved\n---\n\n# Discovery State\n\n> **User Approved:** yes\n\n## Knowledge Summary Status\n\n**User Approved:** yes (2026-01-01)\n' \
        > "$d/.aid/knowledge/STATE.md"
    {
        printf -- '---\nkb-category: primary\nsource: hand-authored\n---\n\n# Module Map\n\n## Modules\n\n'
        for i in $(seq 1 40); do echo "Line $i of real module-map content."; done
    } > "$d/.aid/knowledge/module-map.md"
    echo '# external sources'            > "$d/.aid/knowledge/external-sources.md"
    printf 'format_version: 3\nminimum_grade: B-\n' > "$d/.aid/settings.yml"
    printf '{\n  "aid_version": "9.9.9"\n}\n'       > "$d/.aid/.aid-manifest.json"
    echo 'export function main() { return 1; }'     > "$d/src/lib.js"
    printf 'PNGDATA'                                > "$d/docs/img/logo.png"
    # The enumerated streams STALE-CHECK consumes. Hand-built here so this class costs no
    # pipeline run; the gate suite drives the real enumerator over a real tree.
    printf 'int:src/lib.js\tlib.js\tscript\tnamed-unit\tsrc/lib.js\tdeclared\tsource-artifact\n' \
        > "$d/.aid/.temp/graph/nodes.tsv"
    {
        printf 'int:docs/img/logo.png\tlogo.png\timage\tdocs/img/logo.png\tdeclared\n'
        printf 'ext:example.com/spec\tspec\tweb-page\texternal-sources.md\tdeclared\n'
    } > "$d/.aid/.temp/graph/media-nodes.tsv"
}
make_project() {
    [[ -d "$PROJ_TEMPLATE" ]] || build_project_template "$PROJ_TEMPLATE"
    cp -r "$PROJ_TEMPLATE" "$1"
}

# Build a minimal install root: only what the five scripts and the digest need.
INST_TEMPLATE="$TMP/_install-template"
build_install_template() {
    local d="$1" f
    mkdir -p "$d/aid/scripts/graph" "$d/aid/templates/graph" \
             "$d/aid/templates/knowledge-graph" "$d/aid/scripts/config"
    for f in "${MINE[@]}"; do cp "${GRAPH_SRC}/${f}" "$d/aid/scripts/graph/"; done
    cp "${TPL_GRAPH}/relation-vocabulary.yml" "${TPL_GRAPH}/relationship-schema.yml" \
       "${CEILING_YML}" "$d/aid/templates/graph/"
    echo '<html></html>' > "$d/aid/templates/knowledge-graph/graph-skeleton.html"
    cp "${REPO_ROOT}/canonical/aid/scripts/config/read-setting.sh" "$d/aid/scripts/config/"
    cp "${REPO_ROOT}/canonical/aid/scripts/grade.sh" "$d/aid/scripts/"
}
make_install() {
    [[ -d "$INST_TEMPLATE" ]] || build_install_template "$INST_TEMPLATE"
    cp -r "$INST_TEMPLATE" "$1"
}

# Write the artifact frontmatter STALE-CHECK reads, carrying a given digest.
seed_artifact() {
    printf -- '---\nsource: generated\ngraph_inputs_digest: %s\ngraph_generated_at: 2026-01-01T00:00:00Z\n---\n\n# Relationships\n' \
        "$2" > "$1"
}

# A fixture listing that makes "writes nothing" an empty DIFF rather than a message. It
# records every path AND every file's byte length, so a same-size-different-name write and
# an in-place append are both visible. Fork-free: globstar expansion plus `$(<file)`.
tree_listing() {
    local root="$1" p rel body
    LISTING=""
    shopt -s nullglob dotglob globstar
    for p in "$root"/**; do
        rel="${p#"$root"/}"
        [[ "$rel" == .git || "$rel" == .git/* ]] && continue
        if [[ -f "$p" ]]; then
            body=$(<"$p")
            LISTING+="${rel} f ${#body}"$'\n'
        elif [[ -d "$p" ]]; then
            LISTING+="${rel} d"$'\n'
        fi
    done
    # All three are restored, not just globstar: leaving dotglob and nullglob set would
    # silently change the meaning of every later glob in this file.
    shopt -u globstar dotglob nullglob
}
LISTING=""

if [[ "$MODE" == "assert" ]]; then

# ===========================================================================
# === Setup, shared by every class ==========================================
# ===========================================================================
#
# Read every shipped file ONCE, here, so a --group run gets the inputs its class needs
# without the class it was filtered away from. `$(<file)` is a builtin read, so loading
# eighteen files costs no spawn at all.

shopt -s nullglob
REF_FILES=("$REFS"/*.md)
shopt -u nullglob

# The eleven states, and the eleven file basenames they map to. Both written out rather
# than derived with `tr`: eleven forks to lowercase eleven known strings is eleven forks.
DECLARED_STATES=(PREFLIGHT ENUMERATE STALE-CHECK EXTRACT EMIT GAP-REPORT RENDER
                 VALIDATE VISUAL-GATE FIX DONE)
STATE_DOCS=(state-preflight.md state-enumerate.md state-stale-check.md state-extract.md
            state-emit.md state-gap-report.md state-render.md state-validate.md
            state-visual-gate.md state-fix.md state-done.md)

load_txt "SKILL.md" "$SKILL_MD"
SHIPPED_MD=("SKILL.md")
for f in "${REF_FILES[@]}"; do
    load_txt "${f##*/}" "$f"
    SHIPPED_MD+=("${f##*/}")
done
for f in "${MINE[@]}"; do
    load_txt "$f" "${GRAPH_SRC}/${f}"
done

# The two costly fixtures, built at most once and only if a class in scope asks for one:
# make_install is 1.1 s and the project template 1.1 s, and a documentation-only group
# needs neither.
INST=""
PROJ=""
need_install() { [[ -n "$INST" ]] || { INST="$TMP/install"; make_install "$INST"; }; }
need_project() { [[ -n "$PROJ" ]] || { PROJ="$TMP/proj";   make_project "$PROJ"; }; }

# ===========================================================================
# === SS: the shipped structure -- no script is invoked in this class =======
# ===========================================================================

if want SS; then
echo ""
echo "=== SS: the skill's shipped structure ==="

assert_file_exists "$SKILL_MD" "SS01 SKILL.md ships"
if [[ -e "${SKILL_DIR}/README.md" ]]; then
    fail "SS02 no README.md ships from this skill — one exists, and no profile render carries it"
else
    pass "SS02 no README.md ships from this skill"
fi

assert_eq "${#REF_FILES[@]}" "12" "SS03 [feature-010 Layers] twelve reference files ship (eleven states + agent-pass.md)"
assert_eq "${#STATE_DOCS[@]}" "${#DECLARED_STATES[@]}" \
    "SS04a the state list and the document list are the same length (the mapping below is total)"
for i in "${!DECLARED_STATES[@]}"; do
    assert_file_exists "${REFS}/${STATE_DOCS[$i]}" \
        "SS04 a reference doc exists for state ${DECLARED_STATES[$i]}"
done
assert_file_exists "${REFS}/agent-pass.md" "SS05 agent-pass.md ships (feature-005's content)"

# --- the frontmatter's four required keys, read the way the renderer splits it ---
FM=""
fm_state=0
while IFS= read -r line; do
    if [[ "$fm_state" -eq 0 ]]; then
        trim "$line"
        [[ "$T" == "---" ]] || break
        fm_state=1
        continue
    fi
    trim "$line"
    [[ "$T" == "---" ]] && break
    FM+="$line"$'\n'
done <<< "${TXT[SKILL.md]}"

for k in name description allowed-tools argument-hint; do
    found=0
    while IFS= read -r line; do
        [[ "$line" == "${k}:"* ]] && { found=1; break; }
    done <<< "$FM"
    if [[ "$found" -eq 1 ]]; then
        pass "SS06 SKILL.md frontmatter carries the required key '${k}'"
    else
        fail "SS06 SKILL.md frontmatter is missing the required key '${k}'"
    fi
done
ok_contains "$FM" "name: aid-graph" "SS07 the skill's name is aid-graph"

# Pass 2 is dispatched by this runtime, so a dispatch tool is not optional.
TOOLS_LINE=""
while IFS= read -r line; do
    [[ "$line" == "allowed-tools:"* ]] && { TOOLS_LINE="$line"; break; }
done <<< "$FM"
assert_nonempty "${#TOOLS_LINE}" "SS08a the allowed-tools line was found, so the grant below is a real check"
if [[ "$TOOLS_LINE" == *Agent* ]]; then
    pass "SS08 [AC-S7] allowed-tools grants Agent — Pass 2 cannot be dispatched without it"
else
    fail "SS08 [AC-S7] allowed-tools does not grant Agent, so Pass 2 could never be dispatched"
fi

fi

# ===========================================================================
# === ST: the state machine as a structure =================================
# ===========================================================================

if want ST; then
echo ""
echo "=== ST: eleven states, sixteen edges, nine departures ==="

# The Dispatch table's own rows, in order: `| STATE | detail | worker | advance |`.
# A row qualifies only if its first cell is a bare all-caps state name, so neither the
# Arguments table nor the failure-modes table can contribute one.
STATE_ROWS=()
TABLE_STATES=()
declare -A ADV_CELL=()
while IFS= read -r line; do
    [[ "${line:0:2}" == "| " ]] || continue
    IFS='|' read -ra C <<< "$line"
    [[ "${#C[@]}" -ge 5 ]] || continue
    trim "${C[1]}"; st="$T"
    [[ "$st" =~ ^[A-Z][A-Z-]*$ ]] || continue
    TABLE_STATES+=("$st")
    ADV_CELL["$st"]="${C[4]}"
    STATE_ROWS+=("$st"$'\t'"${C[4]}")
done <<< "${TXT[SKILL.md]}"

assert_eq "${#TABLE_STATES[@]}" "11" "ST01 [feature-010 State Machines] the Dispatch table declares eleven states"
assert_eq "$(IFS=,; echo "${TABLE_STATES[*]}")" "$(IFS=,; echo "${DECLARED_STATES[*]}")" \
    "ST02 the eleven states appear in spine order, exactly as the SPEC's table orders them"

# TWO INDEPENDENT PARSERS of the Advance cell.
#   A splits the cell on ' / ' and takes the FIRST arrow target of each segment -- what a
#     consumer that trusts the declared separator sees.
#   B takes every arrow target anywhere in the cell -- what is actually written.
# They agree only if every target is reachable through the declared separator and no
# extra arrow hides inside a segment. That single comparison catches both delimiter
# defects this table has actually had: a comma used as a separator (which left a target
# unreachable to A) and a ' then ' inside a segment (which built an edge only B saw).
EDGES_A=()
EDGES_B=()
for row in "${STATE_ROWS[@]}"; do
    st="${row%%$'\t'*}"; adv="${row#*$'\t'}"
    rest="$adv"
    while : ; do
        if [[ "$rest" == *" / "* ]]; then
            seg="${rest%%" / "*}"; rest="${rest#*" / "}"
        else
            seg="$rest"; rest=""
        fi
        adv_first_target "$seg"
        [[ -n "$A1" ]] && EDGES_A+=("${st}"$'\t'"${A1}")
        [[ -n "$rest" ]] || break
    done
    s="$adv"
    while [[ "$s" == *"→ "* ]]; do
        s="${s#*"→ "}"
        tgt=""; i=0
        while (( i < ${#s} )); do
            ch="${s:i:1}"
            [[ "$ch" == [A-Z] || "$ch" == "-" ]] || break
            tgt+="$ch"; i=$((i + 1))
        done
        [[ -n "$tgt" ]] && EDGES_B+=("${st}"$'\t'"${tgt}")
    done
done

EDGE_N="${#EDGES_A[@]}"
assert_nonempty "$EDGE_N" "ST03 the Advance column yields edges at all"
SORTED_A=$(printf '%s\n' "${EDGES_A[@]}" | sort)
SORTED_B=$(printf '%s\n' "${EDGES_B[@]}" | sort)
if [[ "$SORTED_A" == "$SORTED_B" ]]; then
    pass "ST04 the two independent Advance parsers agree — every target is reachable through the declared ' / ' separator and no segment hides an extra arrow"
else
    fail "ST04 the two Advance parsers DISAGREE — a target is unreachable through ' / ', or a segment hides an extra arrow"
    [[ "$VERBOSE" -eq 1 ]] && { echo "--- A ---"; echo "$SORTED_A"; echo "--- B ---"; echo "$SORTED_B"; }
fi
assert_eq "$EDGE_N" "16" "ST05 the transition set is exactly sixteen edges"

# ' then ' inside an Advance cell built a spurious edge once. It must never return.
THEN_N=0
for row in "${STATE_ROWS[@]}"; do
    [[ "${row#*$'\t'}" == *" then "* ]] && THEN_N=$((THEN_N + 1))
done
assert_eq "$THEN_N" "0" "ST06 no Advance cell chains targets with ' then ' (it once built a spurious edge)"

declare -A EA=()
for e in "${EDGES_A[@]}"; do EA["$e"]=1; done

# The nine-node happy path. Every one of these edges must exist.
SPINE=(
    "PREFLIGHT	ENUMERATE" "ENUMERATE	STALE-CHECK" "STALE-CHECK	EXTRACT"
    "EXTRACT	EMIT" "EMIT	GAP-REPORT" "GAP-REPORT	RENDER"
    "RENDER	VALIDATE" "VALIDATE	VISUAL-GATE" "VISUAL-GATE	DONE"
)
SPINE_OK=1
for e in "${SPINE[@]}"; do
    if [[ -z "${EA[$e]:-}" ]]; then
        SPINE_OK=0
        fail "ST07 spine edge missing: ${e//$'\t'/ → }"
    fi
done
[[ "$SPINE_OK" -eq 1 ]] && pass "ST07 all nine spine edges are present"

# The departures. Seven are edges; two are stated in a routing cell without being one.
DEPARTURES=(
    "STALE-CHECK	DONE" "VALIDATE	FIX" "VALIDATE	DONE" "VISUAL-GATE	FIX"
    "FIX	RENDER" "FIX	EXTRACT" "FIX	VALIDATE"
)
SORTED_EXPECTED=$(printf '%s\n' "${SPINE[@]}" "${DEPARTURES[@]}" | sort)
if [[ "$SORTED_EXPECTED" == "$SORTED_A" ]]; then
    pass "ST08 the edge set is exactly the nine spine edges plus the seven declared departures — no edge more, none fewer"
else
    fail "ST08 the edge set does not match the declared spine + departures"
    [[ "$VERBOSE" -eq 1 ]] && { echo "--- expected ---"; echo "$SORTED_EXPECTED"; echo "--- actual ---"; echo "$SORTED_A"; }
fi
assert_eq "${#DEPARTURES[@]}" "7" "ST09 seven of the nine departures are edges"

# Departure 8: PREFLIGHT aborts rather than advancing.
ok_contains "${ADV_CELL[PREFLIGHT]:-}" "abort" "ST10 departure 8 of 9 — PREFLIGHT's cell states the abort route"
# Departure 9: RENDER is skipped when the view is out of scope.
ok_contains "${ADV_CELL[RENDER]:-}" "Skipped when" "ST11 departure 9 of 9 — RENDER's cell states the skip route"
# 7 edges + 2 non-edge routes = the nine departures the SPEC counts.
assert_eq "$(( ${#DEPARTURES[@]} + 2 ))" "9" "ST12 nine departures in total (seven edges + two non-edge routes)"

# The withdrawn schematic must not come back: the state table is the sole transition set.
DIAG=0
for k in "${SHIPPED_MD[@]}"; do
    for g in '─' '┌' '└' '├' '┐' '┘'; do
        if [[ "${TXT[$k]}" == *"$g"* ]]; then
            DIAG=1
            fail "ST13 a box-drawing schematic reappeared in ${k} — the state table is the only transition set"
            break
        fi
    done
done
[[ "$DIAG" -eq 0 ]] && pass "ST13 no box-drawing state schematic in SKILL.md or any reference doc"

sub_count "${TXT[SKILL.md]}" '▸ you are here'
assert_eq "$N" "1" "ST14 exactly one 'you are here' map template (not one copy per state)"

sub_count "${TXT[SKILL.md]}" '## References'
assert_eq "$N" "0" "ST15 [Open Item 6] no '## References' section — its ownership is contested and unresolved"

fi

# ===========================================================================
# === RD: the render contract for shipped content ===========================
# ===========================================================================

if want RD; then
echo ""
echo "=== RD: what the profile render does to this content ==="

PROFILE_DIRS=(.claude .cursor .windsurf .gemini .github)
PROFILE_SUBS=(aid skills agents)
CANON_OK=(canonical/aid/scripts/ canonical/aid/templates/ canonical/aid/recipes/
          canonical/skills/ canonical/agents/)

BAD_PROFILE=0
BAD_CANON=0
for k in "${SHIPPED_MD[@]}"; do
    nbad=0
    while IFS= read -r line; do
        for d in "${PROFILE_DIRS[@]}"; do
            for s in "${PROFILE_SUBS[@]}"; do
                [[ "$line" == *"${d}/${s}/"* ]] && nbad=$((nbad + 1))
            done
        done
    done <<< "${TXT[$k]}"
    [[ "$nbad" -gt 0 ]] && { BAD_PROFILE=1; fail "RD01 ${k} hardcodes a profile-specific path; the renderer rewrites 'canonical/...' per profile"; }

    # Every canonical/ reference must be one of the prefixes rewrite_install_paths knows,
    # and must not sit on a comment line -- the rewriter skips those, so such a path would
    # ship verbatim into every profile.
    nbad=0
    while IFS= read -r line; do
        [[ "$line" == *canonical/* ]] || continue
        trim "$line"
        if [[ "${T:0:1}" == "#" ]]; then nbad=$((nbad + 1)); continue; fi
        known=0
        for p in "${CANON_OK[@]}"; do
            [[ "$line" == *"$p"* ]] && { known=1; break; }
        done
        [[ "$known" -eq 0 ]] && nbad=$((nbad + 1))
    done <<< "${TXT[$k]}"
    [[ "$nbad" -gt 0 ]] && { BAD_CANON=1; fail "RD02 ${k} carries $nbad canonical/ reference(s) the renderer will not rewrite (unknown prefix, or on a comment line)"; }
done
[[ "$BAD_PROFILE" -eq 0 ]] && pass "RD01 no shipped markdown hardcodes a profile-specific path"
[[ "$BAD_CANON" -eq 0 ]] && pass "RD02 every canonical/ reference in shipped markdown is one the renderer rewrites"

# The relative link out of a skill dir must resolve in the RENDERED layout, where AID
# content nests under aid/. Fourteen sibling skills carry the ../../templates/ form,
# which resolves nowhere; this one must not join them.
declare -A LINKSET=()
for k in "${SHIPPED_MD[@]}"; do
    while IFS= read -r line; do
        s="$line"
        while [[ "$s" =~ \]\(\.\./\.\./([^\)]+)\) ]]; do
            LINKSET["${BASH_REMATCH[1]}"]=1
            s="${s#*"${BASH_REMATCH[0]}"}"
        done
    done <<< "${TXT[$k]}"
done
assert_nonempty "${#LINKSET[@]}" "RD03 the shipped content carries at least one ../../ link to check"
BAD_LINK=0
for t in "${!LINKSET[@]}"; do
    if [[ ! -e "${REPO_ROOT}/canonical/${t}" ]]; then
        BAD_LINK=1
        fail "RD04 a ../../ link resolves to nothing under the rendered layout: ](../../${t})"
    fi
done
[[ "$BAD_LINK" -eq 0 ]] && pass "RD04 every ../../ link resolves under the rendered layout"

# A CR byte survives `$(<file)` inside a line, so this needs no external grep.
CR=0
for k in "${SHIPPED_MD[@]}" "${MINE[@]}"; do
    if [[ "${TXT[$k]}" == *$'\r'* ]]; then
        CR=1
        fail "RD05 ${k} contains a CR byte; .gitattributes forces LF for *.sh and *.md"
    fi
done
[[ "$CR" -eq 0 ]] && pass "RD05 no CR byte in the five scripts or the thirteen shipped markdown files"

fi

# ===========================================================================
# === TS: the Pass-2 tool-set contract, at both ends =======================
# ===========================================================================

if want TS; then
echo ""
echo "=== TS: the empty tool set (the only mechanical check a prose contract admits) ==="

for pair in "state-extract.md:the caller" "agent-pass.md:the contract"; do
    k="${pair%%:*}"; who="${pair##*:}"
    sub_count "${TXT[$k]}" 'empty tool set'
    if [[ "$N" -ge 3 ]]; then
        pass "TS01 [SR16] ${k} states the empty tool set for both dispatch shapes and as a term (${who}, $N mentions)"
    else
        fail "TS01 [SR16] ${k} mentions the empty tool set only $N time(s) — the bound rests on this clause"
    fi
    ok_contains "${TXT[$k]}" "**discovery**" "TS02 [SR16] ${k} names the discovery dispatch shape"
    ok_contains "${TXT[$k]}" "**typing**"    "TS03 [SR16] ${k} names the typing dispatch shape"
    ok_contains "${TXT[$k]}" "inlined in the prompt" \
        "TS04 [SR16] ${k} states that a dispatch's inputs are inlined"
    ok_contains "${TXT[$k]}" "prompt-only bound is not a bound" \
        "TS05 [SR16] ${k} states WHY the tool set is a contract term and not an assumption"
done
ok_contains "${TXT[state-extract.md]}" "pass-2-unavailable" \
    "TS06 state-extract.md names the total degradation disposition"
ok_contains "${TXT[agent-pass.md]}" "pass-2-unavailable" \
    "TS07 agent-pass.md names the same degradation from the contract side"

fi

# ===========================================================================
# === NF: no fork of the sibling orchestrator ===============================
# ===========================================================================

if want NF; then
echo ""
echo "=== NF: grade-graph.sh is an orchestrator, not a fork ==="

for lit in COV KB_DIR manual-checklist.json AUTO_POOL MANUAL_POOL letter_grade MANUAL_V1 spot-check; do
    sub_count "${TXT[grade-graph.sh]}" "$lit"
    assert_eq "$N" "0" "NF01 [SR09] grade-graph.sh carries none of grade-summary.sh's '${lit}' literal"
done

# "No duplication" must not be satisfiable by doing nothing: every reused check is INVOKED.
INV=0; CHK=0; GREPHTML=0
while IFS= read -r line; do
    trim "$line"
    if [[ "$T" =~ ^(bash|node)\ \"\$(REL_VALIDATOR|HTML_VALIDATOR|CONTRAST_VALIDATOR|VISUAL_VALIDATOR)\" ]]; then
        INV=$((INV + 1))
    fi
    [[ "$T" =~ ^(check|check_count)\(\)[[:space:]]*\{ ]] && CHK=$((CHK + 1))
    [[ "$line" == *grep* && "$line" == *'"$VIEW_HTML"'* ]] && GREPHTML=$((GREPHTML + 1))
done <<< "${TXT[grade-graph.sh]}"
assert_eq "$INV" "4" "NF02 [SR09] all four reused leaf validators are invoked by name"
assert_eq "$CHK" "0" "NF03 [SR09] grade-graph.sh defines no check helper of its own"
assert_eq "$GREPHTML" "0" "NF04 [SR09] grade-graph.sh runs no assertion of its own over the page"
ok_contains "${TXT[grade-graph.sh]}" "graph-kb-gaps.md)" \
    "NF05 [AC-S6/SR15] grade-graph.sh refuses the gap ledger's path structurally"

# Configuration reaches every script through the one resolver, never by parsing the file.
BADCFG=0
for k in "${MINE[@]}"; do
    nbad=0
    while IFS= read -r line; do
        # A line is a config READ only if it both names the file AND reads it. A rendered
        # label that quotes the path (the ignore-list row) is not a read; flagging it would
        # be substring presence standing in for the thing itself.
        [[ "$line" == *settings.yml* ]] || continue
        trim "$line"
        [[ "${T:0:1}" == "#" ]] && continue
        [[ "$line" == *read-setting.sh* ]] && continue
        verb=0
        for v in awk grep sed cut cat source; do
            [[ "$line" == *"$v"* ]] && { verb=1; break; }
        done
        [[ "$verb" -eq 1 ]] && nbad=$((nbad + 1))
    done <<< "${TXT[$k]}"
    [[ "$nbad" -gt 0 ]] && { BADCFG=1; fail "NF06 ${k} appears to parse settings.yml directly (${nbad} line(s))"; }
done
[[ "$BADCFG" -eq 0 ]] && pass "NF06 no script parses settings.yml; configuration reaches them through read-setting.sh"

fi

# ===========================================================================
# === HH: the --help does not lie ==========================================
# ===========================================================================

if want HH; then
echo ""
echo "=== HH: every documented flag is parsed, every parsed flag documented ==="
echo "    (5 subject invocations: the flag set is per-script, so they cannot be shared)"

for f in "${MINE[@]}"; do
    HELP=$(bash "${GRAPH_SRC}/${f}" --help 2>&1); hrc=$?
    assert_exit_zero "$hrc" "HH01 ${f} --help"

    # Flags the header's own Flags/Modes block declares.
    declare -A DOCSET=()
    inblock=0
    while IFS= read -r line; do
        if [[ "$line" == "Flags:" || "$line" == "Modes (exactly one is required):" ]]; then
            inblock=1; continue
        fi
        if [[ "$inblock" -eq 1 && "$line" =~ ^[A-Za-z] ]]; then inblock=0; fi
        [[ "$inblock" -eq 1 ]] || continue
        [[ "$line" == "  --"* ]] || continue
        tok="${line#  }"
        tok="${tok%%[![:alnum:]-]*}"
        [[ "$tok" == --* ]] && DOCSET["$tok"]=1
    done <<< "$HELP"

    # Flags the argument parser actually accepts.
    declare -A PARSEDSET=()
    inloop=0
    while IFS= read -r line; do
        if [[ "$line" == 'while [ $# -gt 0 ]'* ]]; then inloop=1; continue; fi
        if [[ "$inloop" -eq 1 && "$line" == "done" ]]; then inloop=0; fi
        [[ "$inloop" -eq 1 ]] || continue
        trim "$line"
        [[ "$T" == -* && "$T" == *")"* ]] || continue
        pre="${T%%)*}"
        [[ "$pre" =~ ^-[-a-z\|]+$ ]] || continue
        IFS='|' read -ra TOKS <<< "$pre"
        for tok in "${TOKS[@]}"; do
            [[ "$tok" == --* ]] || continue
            [[ "$tok" == "--help" ]] && continue
            PARSEDSET["$tok"]=1
        done
    done <<< "${TXT[$f]}"

    # --help is documented on every header's Usage line rather than in its Flags block,
    # and HH01 already proves it works, so it is asserted there instead of compared.
    ok_contains "${TXT[$f]}" "-h | --help" "HH02a ${f} documents -h | --help on its Usage line"
    assert_nonempty "${#DOCSET[@]}" "HH02 ${f} --help declares at least one flag"

    MISS=""
    for tok in "${!DOCSET[@]}";    do [[ -z "${PARSEDSET[$tok]:-}" ]] && MISS+=" documented-but-not-parsed:${tok}"; done
    for tok in "${!PARSEDSET[@]}"; do [[ -z "${DOCSET[$tok]:-}"    ]] && MISS+=" parsed-but-not-documented:${tok}"; done
    if [[ -z "$MISS" ]]; then
        pass "HH03 ${f}: the documented flag set and the parsed flag set are identical (${#DOCSET[@]} flags)"
    else
        fail "HH03 ${f}: --help and the parser disagree about the flag set —${MISS}"
    fi
    unset DOCSET PARSEDSET

    # Every script must carry the three header sections the project's convention requires.
    for sec in Purpose Usage "Exit codes"; do
        ok_contains "${TXT[$f]}" "# ${sec}:" "HH04 ${f} header declares ${sec}"
    done
    # Diagnostics carry the script's own name.
    ok_contains "${TXT[$f]}" 'SELF="' "HH05 ${f} prefixes its diagnostics with its own name"
done

# read-setting.sh gains --probe (D4a, task-030/W5-8): a declared/undeclared
# availability probe, not a consumer-side degradation any more -- asserted directly
# against the real resolver, not assumed absent and not read through $STUB.
RSP="${REPO_ROOT}/canonical/aid/scripts/config/read-setting.sh"
PROBE_OUT=$(bash "$RSP" --probe 2>&1); PROBE_RC=$?
assert_exit_eq "$PROBE_RC" "2" "HH06 read-setting.sh --probe with no --path is a usage error"
ok_contains "$PROBE_OUT" "requires either" "HH07 and names what it still needs (no --path/--skill given at all)"
printf 'name: x\ngraph:\n  ignore:\n    - a/**\n' > "$TMP/hh-decl.yml"
PROBE_DECL=$(bash "$RSP" --probe --path graph.ignore --file "$TMP/hh-decl.yml")
assert_eq "$PROBE_DECL" "declared" "HH08 read-setting.sh --probe reports declared for a declared list"
printf 'name: x\n' > "$TMP/hh-undecl.yml"
PROBE_UNDECL=$(bash "$RSP" --probe --path graph.ignore --file "$TMP/hh-undecl.yml")
assert_eq "$PROBE_UNDECL" "undeclared" "HH09 read-setting.sh --probe reports undeclared for an absent section"

fi

# ===========================================================================
# === CE: the ceiling carrier, whose value is deliberately absent ==========
# ===========================================================================

if want CE; then
echo ""
echo "=== CE: scale-ceiling.yml -- absent, set, and malformed ==="

assert_file_exists "$CEILING_YML" "CE01 the ceiling carrier ships"
load_txt "scale-ceiling.yml" "$CEILING_YML"
KEYS=0
VALUED=0
while IFS= read -r line; do
    [[ "$line" =~ ^[a-z_]+: ]] && KEYS=$((KEYS + 1))
    [[ "$line" =~ ^node_ceiling:[[:space:]]*[0-9] ]] && VALUED=$((VALUED + 1))
done <<< "${TXT[scale-ceiling.yml]}"
assert_eq "$KEYS" "1" "CE02 the carrier declares exactly one key"
ok_contains "${TXT[scale-ceiling.yml]}" "node_ceiling:" "CE03 the key is node_ceiling"
# The value is absent, and this suite asserts NO figure of its own.
assert_eq "$VALUED" "0" "CE04 [AC-16a] the shipped carrier declares NO value — the measurement has not landed"
read_ceiling "$CEILING_YML"
assert_eq "$CEIL" "" "CE05 the prescribed read yields empty for the shipped carrier"

# Three arms, over fixture carriers this suite writes itself.
printf 'node_ceiling: 900\n'          > "$TMP/ceil-set.yml"
printf 'node_ceiling: not-a-number\n' > "$TMP/ceil-bad.yml"
printf 'node_ceiling:\n'              > "$TMP/ceil-empty.yml"
read_ceiling "$TMP/ceil-set.yml";   assert_eq "$CEIL" "900" "CE06 a declared value is read"
read_ceiling "$TMP/ceil-bad.yml";   assert_eq "$CEIL" ""    "CE07 a malformed value reads as UNSET, never as 0"
read_ceiling "$TMP/ceil-empty.yml"; assert_eq "$CEIL" ""    "CE08 a valueless key reads as unset"

# The comparison the run makes, over each arm. Absent must warn about NOTHING and must
# never invent a threshold; set-and-exceeded must name BOTH numbers.
ceiling_verdict "$CEILING_YML" 1234
assert_eq "$CV" "no-comparison total=1234" \
    "CE09 [SR08] an absent ceiling yields no comparison and no invented number"
ceiling_verdict "$TMP/ceil-bad.yml" 1234
assert_eq "$CV" "no-comparison total=1234" \
    "CE10 [SR08] a malformed ceiling is treated as absent, not as 0 (which would warn on every project)"
ceiling_verdict "$TMP/ceil-set.yml" 1234
assert_eq "$CV" "warn total=1234 ceiling=900" \
    "CE11 [SR08] above a declared ceiling the warning names both the total and the threshold"
ceiling_verdict "$TMP/ceil-set.yml" 42
assert_eq "$CV" "quiet total=42 ceiling=900" \
    "CE12 [SR08] below the threshold nothing is emitted"
# The exit status is unaffected in every arm -- the read is a pure function of the file.
ok_contains "${TXT[state-extract.md]}" "The exit status is unaffected" \
    "CE13 [SR08] state-extract.md states that the ceiling never changes the exit status"
ok_contains "${TXT[state-done.md]}" "Do not recompute either" \
    "CE14 DONE repeats the ceiling verdict rather than recomputing it"

fi

# ===========================================================================
# === PF: graph-preflight.sh -- P1 through P7 ==============================
# ===========================================================================

if want PF; then
echo ""
echo "=== PF: preflight refuses, names the action, and writes nothing ==="
echo "    (9 subject invocations: one per check, and each needs its own broken fixture)"

need_install; need_project
PF="${INST}/aid/scripts/graph/graph-preflight.sh"

cd "$PROJ"
OUT=$(bash "$PF" --install-root "$INST" 2>&1); RC=$?
assert_exit_zero "$RC" "PF01 [SR02] a fixture satisfying P1-P7"
ok_contains "$OUT" "Preflight checks passed" "PF02 [SR02] the pass line names the check range"

# The one non-refusal: a missing registry is zero rows, not an error.
mv "$PROJ/.aid/knowledge/external-sources.md" "$TMP/ext.bak"
OUT=$(bash "$PF" --install-root "$INST" 2>&1); RC=$?
assert_exit_zero "$RC" "PF03 [SR02/AC-19] no external-sources.md still exits 0"
ok_contains "$OUT" "external-sources.md is absent" "PF04 [SR02] and the absence is a notice on stderr"
mv "$TMP/ext.bak" "$PROJ/.aid/knowledge/external-sources.md"

# P2's scoping fix. This fixture is the one case the unscoped grep passes: the Knowledge
# Base is UNAPPROVED while a stale summary approval is recorded further down the file.
P2="$TMP/p2"; make_project "$P2"
printf -- '---\nkb-category: meta\n---\n\n# Discovery State\n\n> **User Approved:** no\n\n## Knowledge Summary Status\n\n**User Approved:** yes (2026-01-01)\n' \
    > "$P2/.aid/knowledge/STATE.md"
# The discriminating premise, checked in memory: the file carries an approval line the
# unscoped reading matches, BELOW the `##` the scoped reading stops at.
P2TXT=$(<"$P2/.aid/knowledge/STATE.md")
if [[ "$P2TXT" == *"**User Approved:** yes"* && "$P2TXT" == *"> **User Approved:** no"* ]]; then
    pass "PF05 [SR01] the fixture is the discriminating one — an approval line the unscoped reading matches sits below a refusal the scoped reading stops at"
else
    fail "PF05 [SR01] the fixture does not separate the two readings, so the scoping fix would be untested"
fi
# Snapshot the whole fixture so "writes nothing" is an empty diff, not a message.
tree_listing "$P2"; P2_BEFORE="$LISTING"
cd "$P2"
OUT=$(bash "$PF" --install-root "$INST" 2>&1); RC=$?
assert_exit_eq "$RC" "1" "PF06 [SR01] and preflight REFUSES it — the scoping fix, on the one case the unscoped grep passes"
ok_contains "$OUT" "not approved" "PF07 [SR01] the refusal names the cause"
ok_contains "$OUT" "→" "PF08 [SR01] the refusal carries an actionable line"
tree_listing "$P2"; P2_AFTER="$LISTING"
if [[ "$P2_BEFORE" == "$P2_AFTER" ]]; then
    pass "PF09 [SR01] a refusal writes NOTHING — asserted as an empty fixture diff (every path AND every file's length), not as a message"
else
    fail "PF09 [SR01] a refusal wrote to the fixture"
    [[ "$VERBOSE" -eq 1 ]] && { echo "--- before ---"; echo "$P2_BEFORE"; echo "--- after ---"; echo "$P2_AFTER"; }
fi

# P1, P3, P4, P6, P7 -- one fixture built to fail each.
p_case() {  # <label> <dir> <expect-substring> [env] [install-root]
    local label="$1" dir="$2" want="$3"
    local out rc
    out=$( cd "$dir" && eval "${4:-}" bash "$PF" --install-root "${5:-$INST}" 2>&1 ); rc=$?
    assert_exit_eq "$rc" "1" "${label} refuses"
    ok_contains "$out" "$want" "${label} names the cause"
}
P1D="$TMP/p1"; make_project "$P1D"; rm "$P1D/.aid/knowledge/STATE.md"
p_case "PF10 [SR01] P1 no STATE.md" "$P1D" "does not exist"
P3D="$TMP/p3"; make_project "$P3D"; rm "$P3D/.aid/knowledge/module-map.md"
p_case "PF11 [SR01] P3 no populated document" "$P3D" "empty, or every document is still pending"
p_case "PF12 [SR01] P4 Plan Mode" "$PROJ" "Plan Mode is active" "CLAUDE_PLAN_MODE=1"
p_case "PF13 [SR01] P6 incomplete install" "$PROJ" "installed graph area is incomplete" "" "$TMP/no-such-install"
P7D="$TMP/p7"; make_project "$P7D"; rm -rf "$P7D/.git"
p_case "PF14 [SR01] P7 not a git work tree" "$P7D" "git working tree"

# P5's floor is a runtime property of the host, so it is asserted at its source site
# rather than by breaking the host's node.
ok_contains "${TXT[graph-preflight.sh]}" "lt 20" "PF15 [SR01] P5 asserts the Node floor the project already enforces (20)"
BADFLAG=$( cd "$PROJ" && bash "$PF" --bogus 2>&1 ); BADRC=$?
assert_exit_eq "$BADRC" "2" "PF16 an unknown flag is a usage error"
ok_contains "$BADFLAG" "unknown flag" "PF17 and it names the flag"

fi

# ===========================================================================
# === FN: kb-write-fence.sh -- the checked read-only guarantee ==============
# ===========================================================================

if want FN; then
echo ""
echo "=== FN: the fence's allowlist, its snapshot, and its three violation directions ==="
echo "    (12 subject invocations: each verify runs against a different tree state)"

need_install
FN="${INST}/aid/scripts/graph/kb-write-fence.sh"
# A tree that HAS all three allowlisted paths, so "no allowlisted path is fenced" is a
# real exclusion rather than a claim about files that do not exist.
FNP="$TMP/fence"; mkdir -p "$FNP/.aid/knowledge/.cache" "$FNP/.aid/knowledge/graph-assets" "$FNP/.aid/.temp/graph"
cd "$FNP"
echo 'kb html'   > .aid/knowledge/kb.html
echo 'index'     > .aid/knowledge/INDEX.md
echo 'state'     > .aid/knowledge/STATE.md
echo 'a doc'     > .aid/knowledge/coding-standards.md
echo 'cached'    > .aid/knowledge/.cache/x.json
echo 'W1'        > .aid/knowledge/relationships.md
echo 'W2'        > .aid/knowledge/graph.html
echo 'W3'        > .aid/knowledge/graph-assets/d3.js

AL=$(bash "$FN" --list-allowlist); ALRC=$?
assert_exit_zero "$ALRC" "FN01 --list-allowlist"
ALN=0
while IFS= read -r line; do [[ -n "$line" ]] && ALN=$((ALN + 1)); done <<< "$AL"
assert_eq "$ALN" "3" "FN02 the in-KB allowlist is exactly three patterns"
for p in relationships.md graph.html 'graph-assets/**'; do
    ok_contains "$AL" "$p" "FN03 the allowlist declares ${p}"
done

SNAP=".aid/.temp/graph/kb-fence.txt"
NOSNAP=$(bash "$FN" --verify --snapshot-file "$TMP/absent-snap.txt" 2>&1); NSRC=$?
assert_exit_eq "$NSRC" "2" "FN04 [KF2/SR07] --verify FAILS CLOSED with no snapshot"
ok_contains "$NOSNAP" "fails closed" "FN05 [KF2] and says so, rather than reporting a clean run"

OUT=$(bash "$FN" --snapshot 2>&1); RC=$?
assert_exit_zero "$RC" "FN06 --snapshot"
assert_file_exists "$SNAP" "FN07 the snapshot is written"

# The snapshot, loaded ONCE into a set; every membership question below is a builtin.
declare -A SNAPSET=()
FENCED=0
while IFS=$'\t' read -r sp _; do
    [[ -n "$sp" ]] || continue
    SNAPSET["$sp"]=1
    FENCED=$((FENCED + 1))
done < "$SNAP"
assert_nonempty "$FENCED" "FN08 [KF3] the snapshot is non-empty by construction"
for p in kb.html INDEX.md STATE.md coding-standards.md .cache/x.json; do
    if [[ -n "${SNAPSET[$p]:-}" ]]; then
        pass "FN09 [KF1/SR06] the complement is fenced: ${p} is in the snapshot"
    else
        fail "FN09 [KF1/SR06] ${p} is NOT in the snapshot — the fenced set is not the complement of the allowlist"
    fi
done
for p in relationships.md graph.html graph-assets/d3.js; do
    if [[ -n "${SNAPSET[$p]:-}" ]]; then
        fail "FN10 [SR06] an allowlisted path is fenced: ${p}"
    else
        pass "FN10 [SR06] no allowlisted path is fenced: ${p} is excluded"
    fi
done

SNAP1=$(<"$SNAP")
bash "$FN" --snapshot >/dev/null 2>&1
SNAP2=$(<"$SNAP")
if [[ "$SNAP1" == "$SNAP2" ]]; then
    pass "FN11 two snapshots of an unchanged tree are byte-identical (idempotence, not merely determinism: the second run overwrote the first)"
else
    fail "FN11 the snapshot is not idempotent"
fi

OUT=$(bash "$FN" --verify 2>&1); RC=$?
assert_exit_zero "$RC" "FN12 --verify over an unchanged tree"

# Allowlisted writes are exactly what the run is permitted to do.
echo 'regenerated' > .aid/knowledge/relationships.md
echo 'regenerated' > .aid/knowledge/graph.html
echo 'new'         > .aid/knowledge/graph-assets/pixi.js
OUT=$(bash "$FN" --verify 2>&1); RC=$?
assert_exit_zero "$RC" "FN13 [AC-13] rewriting every allowlisted path does not trip the fence"

# The three directions, then all three at once.
echo 'tampered' >> .aid/knowledge/coding-standards.md
OUT=$(bash "$FN" --verify 2>&1); RC=$?
assert_exit_eq "$RC" "1" "FN14 [SR07] a CHANGED fenced document is a violation"
ok_contains "$OUT" "changed: .aid/knowledge/coding-standards.md" "FN15 [SR07] and the path is named"
echo 'a doc' > .aid/knowledge/coding-standards.md

rm .aid/knowledge/INDEX.md
OUT=$(bash "$FN" --verify 2>&1); RC=$?
assert_exit_eq "$RC" "1" "FN16 [SR07] a REMOVED fenced document is a violation"
ok_contains "$OUT" "removed: .aid/knowledge/INDEX.md" "FN17 [SR07] and the path is named"
echo 'index' > .aid/knowledge/INDEX.md

echo 'surprise' > .aid/knowledge/module-map.md
OUT=$(bash "$FN" --verify 2>&1); RC=$?
assert_exit_eq "$RC" "1" "FN18 [SR07] an ADDED file is a violation — an accidental index regeneration is exactly this shape"
ok_contains "$OUT" "added: .aid/knowledge/module-map.md" "FN19 [SR07] and the path is named"

rm .aid/knowledge/STATE.md
echo 'x' >> .aid/knowledge/kb.html
OUT=$(bash "$FN" --verify 2>&1); RC=$?
assert_exit_eq "$RC" "1" "FN20 [KF4] all three directions at once"
ok_contains "$OUT" "added: .aid/knowledge/module-map.md"   "FN21 [KF4] every offending path is named (added)"
ok_contains "$OUT" "changed: .aid/knowledge/kb.html"       "FN22 [KF4] every offending path is named (changed)"
ok_contains "$OUT" "removed: .aid/knowledge/STATE.md"      "FN23 [KF4] every offending path is named (removed)"
ok_contains "$OUT" "must not be trusted" "FN24 [KF4] the closing summary says the artifacts must not be trusted"

CONF=$(bash "$FN" --snapshot --verify 2>&1); CRC=$?
assert_exit_eq "$CRC" "2" "FN25 two modes at once is a usage error"
EMPTYD="$TMP/fence-empty"; mkdir -p "$EMPTYD/.aid/knowledge"; echo x > "$EMPTYD/.aid/knowledge/relationships.md"
EOUT=$( cd "$EMPTYD" && bash "$FN" --snapshot 2>&1 ); ERC=$?
assert_exit_eq "$ERC" "2" "FN26 a fenced set that came out empty is refused — verification would be vacuous"
ok_contains "$EOUT" "vacuous" "FN27 and it says why"

fi

# ===========================================================================
# === GG: grade-graph.sh -- the argument refusals and the floor =============
# ===========================================================================

if want GG; then
echo ""
echo "=== GG: the gate's argument refusals and its floor resolution ==="
echo "    (5 subject invocations: three refusals exit before any work; the two full runs"
echo "     differ by the flag under test, so neither can stand in for the other)"

need_install; need_project
GG="${INST}/aid/scripts/graph/grade-graph.sh"
GGD="$TMP/grade"; mkdir -p "$GGD/.aid/.temp/graph"; cd "$GGD"
printf -- '---\nkb-category: primary\n---\n\n# Relationships\n' > "$GGD/table.md"

# Argument refusals, before any work is done.
OUT=$(bash "$GG" --install-root "$INST" --table "$GGD/table.md" --grade Z 2>&1); RC=$?
assert_exit_eq "$RC" "2" "GG01 [SR17/AC-S8] --grade Z is a usage error"
ok_contains "$OUT" '^[A-F][+-]?$' "GG02 [SR17] and the message states the accepted format"
OUT=$(bash "$GG" --install-root "$INST" --table "$GGD/table.md" \
        --ledger "$GGD/.aid/.temp/review-pending/graph-kb-gaps.md" 2>&1); RC=$?
assert_exit_eq "$RC" "2" "GG03 [SR15/AC-S6] the gap ledger's path is REFUSED as a grading target"
ok_contains "$OUT" "never graded" "GG04 [AC-S6] and it says the gap ledger is never graded"
OUT=$(bash "$GG" --install-root "$INST" --table "$TMP/no-such-table.md" 2>&1); RC=$?
assert_exit_eq "$RC" "2" "GG05 a missing relationship table is a usage error"

# The floor comes from the project's single resolver, and the resolver's own order is
# what decides it. Four fixture settings files, one per resolution step.
RS="${INST}/aid/scripts/config/read-setting.sh"
printf 'minimum_grade: B-\n'                                  > "$TMP/s1.yml"
printf 'minimum_grade: B-\ngraph:\n  minimum_grade: A-\n'     > "$TMP/s2.yml"
printf 'review:\n  minimum_grade: C+\n'                       > "$TMP/s3.yml"
printf 'name: X\n'                                            > "$TMP/s4.yml"
assert_eq "$(bash "$RS" --skill graph --key minimum_grade --default A --file "$TMP/s1.yml")" "B-" \
    "GG06 [D1] the resolver reads the flat top-level minimum_grade"
assert_eq "$(bash "$RS" --skill graph --key minimum_grade --default A --file "$TMP/s2.yml")" "A-" \
    "GG07 [D1] a per-skill graph.minimum_grade override wins"
assert_eq "$(bash "$RS" --skill graph --key minimum_grade --default A --file "$TMP/s3.yml")" "C+" \
    "GG08 [D1] the legacy review.minimum_grade is the third step"
assert_eq "$(bash "$RS" --skill graph --key minimum_grade --default A --file "$TMP/s4.yml")" "A" \
    "GG09 [D1] --default is the last step"

# The floor the gate prints, and the source it names.
LED="$GGD/led.md"
OUT=$(bash "$GG" --install-root "$INST" --table "$GGD/table.md" --ledger "$LED" 2>&1); RC=$?
FLOOR_LINE=""
while IFS= read -r line; do
    [[ "$line" == "Minimum grade:"* ]] && { FLOOR_LINE="$line"; break; }
done <<< "$OUT"
assert_nonempty "${#FLOOR_LINE}" "GG10a the gate printed a floor line at all"
ok_contains "$FLOOR_LINE" "read-setting.sh --skill graph --key minimum_grade" \
    "GG10 [D1] without --grade the gate names the resolver it read the floor through"
ok_not_contains "$OUT" "grep minimum_grade" "GG11 [D1] the gate does not parse a settings file"

# --grade binds this run only, and persists nothing.
SETTINGS_BEFORE=$(<"$PROJ/.aid/settings.yml")
OUT=$(cd "$PROJ" && bash "$GG" --install-root "$INST" --table "$GGD/table.md" --ledger "$LED" --grade B 2>&1)
ok_contains "$OUT" "Minimum grade:  B   [--grade" \
    "GG12 [SR17/AC-S8] --grade B TAKES EFFECT — a run that swallowed the flag fails here"
SETTINGS_AFTER=$(<"$PROJ/.aid/settings.yml")
if [[ "$SETTINGS_BEFORE" == "$SETTINGS_AFTER" ]]; then
    pass "GG13 [SR17/AC-S8] and .aid/settings.yml is byte-identical before and after"
else
    fail "GG13 [SR17/AC-S8] --grade wrote to .aid/settings.yml"
fi

fi

# ===========================================================================
# === VA: graph-stale-check.sh -- the verdict arms ==========================
# ===========================================================================
#
# The digest's COMPONENTS are the sibling suite's class (test-graph-runtime-digest.sh);
# what this class owns is the verdict each situation yields.

if want VA; then
echo ""
echo "=== VA: every verdict arm, and the fact that none of them is a failure ==="
echo "    (9 subject invocations: eight distinct situations plus the second run that"
echo "     proves idempotence; the out-of-scope arm needs its own baseline because its"
echo "     'tool' component differs from the in-scope install's)"

need_install
SC="${INST}/aid/scripts/graph/graph-stale-check.sh"
DGP="$TMP/verdict"; make_project "$DGP"
cd "$DGP"
ART="$DGP/.aid/knowledge/relationships.md"

NOSTREAM=$(bash "$SC" --install-root "$INST" --stream-dir "$TMP/no-streams" 2>&1); NSRC2=$?
assert_exit_eq "$NSRC2" "1" "VA01 an absent enumerated stream is exit 1 — an unreadable required input, never a verdict"
ok_contains "$NOSTREAM" "ENUMERATE must run before STALE-CHECK" "VA02 and it names the ordering requirement"

OUT=$(bash "$SC" --install-root "$INST" 2>&1); RC=$?
assert_exit_zero "$RC" "VA03 [SR03] the verdict is informational — exit 0"
verdict_of "$OUT"
assert_eq "$VER" "FIRST_RUN" "VA04 no artifact yields FIRST_RUN, on the LAST stdout line"
digest_of "$OUT"; BASE_DIGEST="$DIG"
if [[ "$BASE_DIGEST" =~ ^kb=[0-9a-f]{64},src=[0-9a-f]{64},ext=[0-9a-f]{64},cfg=[0-9a-f]{64},vocab=[0-9a-f]{64},tool=[0-9a-f]{64}$ ]]; then
    pass "VA05 [FR-11] the composite is six name=<hex> pairs, comma-joined, in the inputs' own order"
else
    fail "VA05 [FR-11] the composite's shape is wrong: '$BASE_DIGEST'"
fi
OUT2=$(bash "$SC" --install-root "$INST" 2>&1)
if [[ "$OUT" == "$OUT2" ]]; then
    pass "VA06 [SR03] two runs over unchanged inputs print byte-identical output"
else
    fail "VA06 [SR03] the verdict output is not deterministic"
fi
TSN=0
while IFS= read -r line; do
    [[ "$line" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} || "$line" =~ [0-9]{2}:[0-9]{2}:[0-9]{2} ]] && TSN=$((TSN + 1))
done <<< "$OUT"
assert_eq "$TSN" "0" "VA07 no timestamp appears in the verdict output"

seed_artifact "$ART" "$BASE_DIGEST"
echo '<html>graph</html>' > "$DGP/.aid/knowledge/graph.html"
OUT=$(bash "$SC" --install-root "$INST" 2>&1)
verdict_of "$OUT"; assert_eq "$VER" "CURRENT" "VA08 [SR03] every component unchanged and every expected artifact present yields CURRENT"
changed_of "$OUT"; assert_eq "$CHG" "none" "VA09 [SR03] and no component is reported changed"

# --reset, and the two remaining STALE arms.
OUT=$(bash "$SC" --install-root "$INST" --reset 2>&1); RC=$?
assert_exit_zero "$RC" "VA10 [SR05] --reset exits 0"
verdict_of "$OUT"; assert_eq "$VER" "STALE" "VA11 [SR05/AC-S2] --reset on an unchanged fixture yields STALE"
ok_contains "$OUT" "no artifact deleted, no ledger preserved" \
    "VA12 [AC-S2] --reset discards the digest comparison and NOTHING else"
assert_file_exists "$ART" "VA13 [SR05] --reset deleted no artifact"

mv "$DGP/.aid/knowledge/graph.html" "$TMP/page.bak"
OUT=$(bash "$SC" --install-root "$INST" 2>&1)
verdict_of "$OUT"; assert_eq "$VER" "STALE" "VA14 a missing EXPECTED artifact is STALE even when every component matches"
ok_contains "$OUT" "missing expected artifact" "VA15 and the missing artifact is named"
mv "$TMP/page.bak" "$DGP/.aid/knowledge/graph.html"

mv "$ART" "$TMP/art.bak"
OUT=$(bash "$SC" --install-root "$INST" --reset 2>&1)
verdict_of "$OUT"; assert_eq "$VER" "FIRST_RUN" "VA16 --reset with no artifact is FIRST_RUN, not a false STALE"
mv "$TMP/art.bak" "$ART"

# view_expected false: the presence test must not demand a page that was never in scope.
NOVIEW="$TMP/install-noview"; make_install "$NOVIEW"
rm -f "$NOVIEW/aid/templates/knowledge-graph/graph-skeleton.html"
rm -f "$DGP/.aid/knowledge/graph.html"
OUT=$(bash "${NOVIEW}/aid/scripts/graph/graph-stale-check.sh" --install-root "$NOVIEW" 2>&1)
digest_of "$OUT"; NV_DIGEST="$DIG"
if [[ "$NV_DIGEST" == "$BASE_DIGEST" ]]; then
    fail "VA17a the out-of-scope install produced the SAME digest as the in-scope one — then removing an installed output-affecting file did not move the 'tool' component"
else
    pass "VA17a the out-of-scope install has its own digest (its 'tool' component differs), which is why this arm needs its own baseline run"
fi
seed_artifact "$ART" "$NV_DIGEST"
OUT=$(bash "${NOVIEW}/aid/scripts/graph/graph-stale-check.sh" --install-root "$NOVIEW" 2>&1)
verdict_of "$OUT"; assert_eq "$VER" "CURRENT" "VA17 [SR18/AC-S10] with the view out of scope, CURRENT does not demand a page"
ok_contains "$OUT" "the view templates are not installed" "VA18 [SR18] and the expected-artifact set says so"

fi

# ===========================================================================
# === SF: this suite's own false-PASS controls ==============================
# ===========================================================================

if want SF; then
echo ""
echo "=== SF: the known false-PASS shapes, checked against this suite's own source ==="

self_code_count 'sed -i.*(REPO_ROOT|GRAPH_SRC|SKILL_MD|CEILING_YML)'
assert_eq "$N" "0" "SF01 no in-place edit of any committed path (every mutation goes to a copy under mktemp -d)"
self_code_count 'sed .*[0-9]+s/'
assert_eq "$N" "0" "SF02 no line-numbered sed substitution — line numbers shift and the edit silently misses"
self_code_count '\|\| echo 0'
assert_eq "$N" "0" "SF03 no 'grep -c ... || echo 0' idiom, which emits '0\n0' and compares as neither"
self_code_count 'assert_nonempty'
assert_nonempty "$N" "SF04 universals are guarded by an explicit non-emptiness assertion"
self_code_count '\.aid/works/'
assert_eq "$N" "0" "SF05 no .aid/works/ path — work folders are transient, and every fixture here is self-built"
self_code_count 'tests/canonical/test-.*\.sh.*(wc -l|count)'
assert_eq "$N" "0" "SF06 this suite asserts no suite count (the Knowledge Base's figure is stale and is the owner's to correct)"
self_code_count 'assert_(file|output)_(contains|not_contains)'
assert_eq "$N" "0" "SF07 no per-assertion grep: every containment check is the fork-free ok_contains, because at ~70 ms a fork the capture costs more than the check"

# The COVERS manifest select-suites.sh reads. A WRONG entry is the only way this suite can
# silently stop being selected, so every entry must resolve on disk -- a typo fails here
# rather than quietly narrowing the change set that re-runs this file.
COVERS_N=0
BAD_COVER=0
while IFS= read -r line; do
    [[ "$line" == "# COVERS:"* ]] || continue
    trim "${line#\# COVERS:}"
    [[ -n "$T" ]] || continue
    COVERS_N=$((COVERS_N + 1))
    if [[ ! -e "${REPO_ROOT}/${T%/}" ]]; then
        BAD_COVER=1
        fail "SF08 a COVERS entry names a path that does not exist: ${T}"
    fi
done < "$SELF_SRC"
assert_nonempty "$COVERS_N" "SF08a the suite declares a COVERS manifest (a suite without one is selected for every change — fail-safe, but it runs on unrelated edits)"
[[ "$BAD_COVER" -eq 0 ]] && pass "SF08 every COVERS entry resolves on disk"

cd "$REPO_ROOT"

fi

# ===========================================================================
echo ""
echo "=== Summary ==="
echo "  Tests passed:  $PASS"
echo "  Tests failed:  $FAIL"
echo "  Tests skipped: $SKIP"
if [[ "$SKIP" -gt 0 ]]; then
    echo ""
    echo "Skipped (a skip is never a pass):"
    for s in "${SKIPPED[@]}"; do echo "  - $s"; done
fi
if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "Failed tests:"
    for e in "${ERRORS[@]}"; do echo "  - $e"; done
    exit 1
fi
echo ""
echo "All tests passed."
exit 0

# ===========================================================================
else   # MODE == mutate
# ===========================================================================

CANON_GRAPH="${REPO_ROOT}/canonical/aid/scripts/graph"
CANON_SKILL="${REPO_ROOT}/canonical/skills/aid-graph"
CANON_TPL="${REPO_ROOT}/canonical/aid/templates/graph"
SELF="${BASH_SOURCE[0]}"

digest_src() {
    sha256sum "$CANON_GRAPH"/graph-preflight.sh "$CANON_GRAPH"/kb-write-fence.sh \
              "$CANON_GRAPH"/grade-graph.sh "$CANON_SKILL"/SKILL.md \
              "$CANON_TPL"/scale-ceiling.yml | awk '{ print $1 }' | tr '\n' ' '
}
BASE_SRC_DIGEST="$(digest_src)"

# Exact-string replacement. NO numeric line addresses anywhere: a `sed 'Ns/...'` against a
# line number that shifts is a known false-PASS shape, so the anchor is the text itself.
# Aborts unless the anchor occurs EXACTLY once AND the write changed the file -- an anchor
# that has drifted must fail loudly, never mutate nothing and report a survivor.
mutate_apply() {
    local file="$1" n
    # The anchor and the replacement are passed through the ENVIRONMENT, not through
    # `awk -v`. awk processes escape sequences in a -v assignment, so an anchor containing
    # a tab, a newline or an escaped pipe -- which several of the anchors below do -- would
    # arrive at awk as the CHARACTER that escape denotes and match nothing. The mutant would
    # then ABORT rather than run, and a mutation harness that quietly stops testing is worse
    # than none. ENVIRON[] is not escape-processed.
    export MUT_FROM="$2" MUT_TO="$3"
    n="$(awk 'BEGIN { s = ENVIRON["MUT_FROM"] } index($0, s) > 0 { c++ } END { print c + 0 }' "$file")"
    if [[ "$n" -ne 1 ]]; then
        echo "    ABORT: anchor occurs $n times (need exactly 1): ${MUT_FROM:0:60}" >&2
        return 1
    fi
    awk '
        BEGIN { s = ENVIRON["MUT_FROM"]; r = ENVIRON["MUT_TO"] }
        { p = index($0, s); if (p > 0) $0 = substr($0, 1, p - 1) r substr($0, p + length(s)); print }
    ' "$file" > "$file.mut" || return 1
    if cmp -s "$file" "$file.mut"; then
        echo "    ABORT: replacement changed nothing" >&2
        rm -f "$file.mut"; return 1
    fi
    mv -f "$file.mut" "$file"
}

MUT_TOTAL=0; MUT_KILLED=0; MUT_SURVIVED=0; MUT_ABORTED=0

# run_mutant <name> <scripts|skill|tpl> <file-within> <anchor> <replacement> [group]
#
# The re-run is scoped to the GROUP the mutant targets. A mutant proves that a specific
# assertion flips, and re-running twelve classes to watch one of them flip costs 116 s to
# learn nothing extra -- seven mutants that way is thirteen minutes. Where a mutant could
# plausibly break a class other than its own, run it unscoped.
run_mutant() {
    local name="$1" kind="$2" file="$3" from="$4" to="$5" group="${6:-}"
    MUT_TOTAL=$((MUT_TOTAL + 1))
    local dir="$TMP/mut$MUT_TOTAL"
    mkdir -p "$dir"
    local -a env_pair=()
    case "$kind" in
        scripts) cp "$CANON_GRAPH"/*.sh "$dir/" 2>/dev/null
                 env_pair=(GRAPH_SCRIPTS_DIR="$dir") ;;
        skill)   cp -r "$CANON_SKILL/." "$dir/"
                 env_pair=(AID_GRAPH_SKILL_DIR="$dir") ;;
        tpl)     cp -r "$CANON_TPL/." "$dir/"
                 env_pair=(AID_GRAPH_TPL_DIR="$dir") ;;
        *) echo "    ABORT: unknown mutant kind ${kind}" >&2
           MUT_ABORTED=$((MUT_ABORTED + 1)); return ;;
    esac
    echo "=== $name"
    if ! mutate_apply "$dir/$file" "$from" "$to"; then
        echo "    RESULT: ABORTED (anchor drifted -- the mutant proves nothing; fix the anchor)"
        MUT_ABORTED=$((MUT_ABORTED + 1)); return
    fi
    local out rc=0 flipped
    out="$(env "${env_pair[@]}" bash "$SELF" 2>&1)" || rc=$?
    flipped="$(printf '%s\n' "$out" | grep -cE '^  FAIL: ' || true)"
    if [[ "$rc" -ne 0 ]]; then
        echo "    RESULT: KILLED (suite exit $rc, $flipped assertion(s) flipped)"
        printf '%s\n' "$out" | grep -E '^  FAIL: ' | head -3 | sed 's/^/      /'
        MUT_KILLED=$((MUT_KILLED + 1))
    else
        echo "    RESULT: *** SURVIVED *** -- this defect is invisible to the suite"
        MUT_SURVIVED=$((MUT_SURVIVED + 1))
    fi
    if [[ "$(digest_src)" == "$BASE_SRC_DIGEST" ]]; then
        echo "    source tree: UNTOUCHED (digests match)"
    else
        echo "    source tree: *** MODIFIED *** -- aborting everything"
        exit 1
    fi
}

echo "=========================================================================="
echo " Mutation harness -- mutating COPIES under $TMP, never the tree"
echo " baseline digests: $BASE_SRC_DIGEST"
echo "=========================================================================="

run_mutant "M1 the write fence's allowlist widened to cover a Knowledge Base document" \
    scripts kb-write-fence.sh \
    '    "graph-assets/**"' \
    '    "graph-assets/**" "coding-standards.md"' \
    FN

run_mutant "M2 a comma used as an Advance-cell target separator (defect 1 of 2)" \
    skill SKILL.md \
    '| → RENDER / → EXTRACT / → VALIDATE, by where the repaired input lives |' \
    '| → RENDER, → EXTRACT or → VALIDATE, by where the repaired input lives |' \
    ST

run_mutant "M3 a ' then ' chaining two targets inside one Advance segment (defect 2 of 2)" \
    skill SKILL.md \
    '| → EMIT |' \
    '| → EMIT then → GAP-REPORT |' \
    ST

run_mutant "M4 the ceiling carrier ships a value of 0 (which would warn on every project)" \
    tpl scale-ceiling.yml \
    'node_ceiling:' \
    'node_ceiling: 0' \
    CE

run_mutant "M5 the gate parses .aid/settings.yml directly instead of using the one resolver" \
    scripts grade-graph.sh \
    '    if [ ! -f "$RESOLVER" ]; then' \
    '    FLOOR=$(grep "^minimum_grade:" .aid/settings.yml); if [ ! -f "$RESOLVER" ]; then' \
    NF

run_mutant "M6 preflight P2 reverted to the UNSCOPED approval read (the shipped defect)" \
    scripts graph-preflight.sh \
    '    if ! printf '"'"'%s\n'"'"' "$LEGACY" | grep -qE '"'"'^(> *)?\*\*User Approved:\*\* yes'"'"'; then' \
    '    if ! grep -qE '"'"'^(> *)?\*\*User Approved:\*\* yes'"'"' "$STATE"; then' \
    PF

run_mutant "M7 --grade accepted, validated, and then silently ignored" \
    scripts grade-graph.sh \
    '    FLOOR="$FLOOR_OVERRIDE"' \
    '    FLOOR="${FLOOR:-A}"' \
    GG

echo "=========================================================================="
echo " mutants: $MUT_TOTAL   killed: $MUT_KILLED   survived: $MUT_SURVIVED   aborted: $MUT_ABORTED"
echo " source tree after every mutant: $(digest_src)"
echo "=========================================================================="
if [[ "$MUT_SURVIVED" -gt 0 || "$MUT_ABORTED" -gt 0 || "$MUT_KILLED" -ne "$MUT_TOTAL" ]]; then
    echo "MUTATION TESTING FAILED"
    exit 1
fi
echo "All mutants killed."
exit 0

fi
