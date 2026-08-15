#!/usr/bin/env bash
# review-cost-meter.sh -- measure what a review cycle is asked to read.
#
# WHAT IS MEASURED, AND WHY IT IS NOT "TOKENS"
#
# A review cycle is performed by a dispatched LLM sub-agent. Nothing here can
# observe how many bytes that agent truly consumed, and host-cooperating token
# accounting is deliberately out of scope. So this measures the DECLARED READ
# SURFACE instead: the set of paths a cycle's dispatch brief names under
# `ARTIFACTS UNDER REVIEW`, and their byte sizes on disk at that commit.
#
# That is the right quantity rather than a convenient one. `reviewer-dispatch.md`
# makes the ARTIFACTS list binding -- "The reviewer MUST NOT open any file not
# listed here" -- so declared is also permitted, which is the enforceable
# quantity. And the scoped-hunt change does not alter how an agent reads; it
# alters what the brief tells it to hunt in. The declared surface IS the
# mechanism under test.
#
# Stated limitation: this is what a cycle was instructed to read, not what it
# demonstrably read. Every figure this tool prints is labelled "declared read
# surface" for that reason. Never call it tokens consumed.
#
# SUBCOMMANDS
#   record   append one row for one review cycle, at dispatch time
#   report   compute cycles-to-close and the within-task re-read ratio
#
# Convention sibling: tests/coverage-parity.sh (a .tsv plus a .meta provenance
# sidecar). Its subcommands are `collect` and `diff`; this tool departs
# deliberately -- `record` because the data accrues one cycle at a time rather
# than in one sweep, and `report` because it computes rather than compares.
#
# EXIT CODES
#   0  success
#   1  refusal (run-id mismatch, unreachable split commit, missing input)
#   2  usage / argument error
#
# Bash + awk only. No node, no python -- the core path assumes neither.

set -uo pipefail

readonly PROG="${0##*/}"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

die() { printf '%s: %s\n' "$PROG" "$*" >&2; exit 2; }
refuse() { printf '%s: REFUSED -- %s\n' "$PROG" "$*" >&2; exit 1; }

usage() {
    cat <<'USAGE'
Usage:
  review-cost-meter.sh record --task <task-NNN> --cycle <N> --brief <path>
                              [--data <dir>]
  review-cost-meter.sh report [--split-at-task <task-NNN> | --split-at <commit>]
                              [--data <dir>]

record   Sum the on-disk sizes of the paths named under the brief's
         `ARTIFACTS UNDER REVIEW` heading and append one row.
         Creates the .tsv/.meta pair on first call; refuses to append when
         the pair's run ids disagree.

report   Per task: cycles-to-close, and the within-task re-read ratio
         (mean cycle-2+ declared surface / that task's own cycle-1 surface).
         With a split, prints both metrics for the before and after sides.
         --split-at-task is PREFERRED: a task id survives rebase and squash.
         --split-at <commit> is offered as a secondary form and fails loudly
         when a recorded commit is no longer reachable.

Both subcommands print the row count behind every figure. A task with no rows
is reported as missing, never as zero.
USAGE
}

# Data location. Defaults to the work folder this meter was built for; the
# override exists so the test suite never touches live data.
DATA_DIR=""
resolve_data_dir() {
    if [[ -n "$DATA_DIR" ]]; then printf '%s' "$DATA_DIR"; return; fi
    local d
    for d in .aid/works/*/; do
        [[ -d "$d" ]] || continue
        printf '%s' "${d%/}"
        return
    done
    die "no .aid/works/<work>/ found and --data not given"
}

TSV=""; META=""
set_paths() {
    local dir; dir="$(resolve_data_dir)" || exit $?
    TSV="${dir}/review-cost.tsv"
    META="${dir}/review-cost.meta"
}

# The run id ties the pair together. W5-19 records that coverage-parity.sh's
# .tsv and .meta can be committed out of step with nothing detecting it -- and
# that the committed pair WAS out of step, which made its staleness warning
# untrustworthy in both directions. Its recommended fix is one run id in both
# files, checked by the reader. This tool goes one step further and checks at
# WRITE time too, because coverage-parity.sh writes both files in a single
# invocation while this one appends across many: the pair is exposed for the
# whole life of a work, so a mismatch is caught at the append that would widen
# it rather than discovered later by a reader trying to trust it.
read_run_id_tsv() {
    [[ -f "$TSV" ]] || return 1
    local first; first="$(head -n1 "$TSV")"
    [[ "$first" == '#run'* ]] || return 1
    printf '%s' "${first#\#run	}"
}
read_run_id_meta() {
    [[ -f "$META" ]] || return 1
    awk -F'\t' '$1=="run"{print $2; found=1} END{exit !found}' "$META"
}

verify_pair() {
    local t m
    t="$(read_run_id_tsv)" || refuse "$TSV is missing or has no '#run' header line"
    m="$(read_run_id_meta)" || refuse "$META is missing or has no 'run' entry"
    [[ "$t" == "$m" ]] || refuse "run id mismatch -- $TSV has '$t', $META has '$m'. One file was regenerated, restored or hand-edited without the other; the pair is not trustworthy and this tool will not add to it."
}

# ---------------------------------------------------------------------------
# record
# ---------------------------------------------------------------------------

# Extract the paths a brief names under ARTIFACTS UNDER REVIEW. The section
# ends at the next all-caps heading -- the 5-section shape reviewer-dispatch.md
# mandates: CONTEXT:, RUBRIC:, OUT OF SCOPE (do not grade against):,
# OUT-OF-SCOPE FINDINGS POLICY:, DELIVERABLES:.
#
# The block ends at the next UNINDENTED line, which is the structural rule of
# the brief format: every section heading sits at column 0 and every artifact
# entry is indented. Matching the heading TEXT was tried twice and failed
# twice -- first a class of [A-Z -] and then one adding digits and brackets --
# because "OUT OF SCOPE (do not grade against):" carries lowercase inside its
# parenthetical, so that whole section leaked its path-like entries into the
# surface total. Indentation is what actually distinguishes a heading from an
# entry, so match on that rather than on a guess about heading spelling.
brief_artifacts() {
    awk '
        /^[[:space:]]*ARTIFACTS UNDER REVIEW:/ { inblk=1; next }
        inblk && /^[^[:space:]]/ { inblk=0 }
        inblk {
            line=$0
            sub(/^[[:space:]]*-[[:space:]]*/, "", line)
            sub(/[[:space:]]*$/, "", line)
            sub(/[[:space:]]+\(.*$/, "", line)      # drop a trailing "(note)"
            gsub(/`/, "", line)
            if (line ~ /^[^[:space:]]+$/ && line != "") print line
        }
    ' "$1"
}

# Takes the brief PATH and does its own extraction. An earlier version took the
# path as $1 but read the list from stdin, so the caller had to supply both --
# and dropping the process substitution silently produced a surface of 0 rather
# than an error. A measurement tool must not have a call form that quietly
# measures nothing.
surface_bytes() {
    local brief="$1" total=0 p sz any=0
    while IFS= read -r p; do
        any=1
        [[ -n "$p" ]] || continue
        if [[ -f "$p" ]]; then
            sz=$(wc -c <"$p"); total=$(( total + sz ))
        else
            # A glob in the ARTIFACTS list expands here; a path that matches
            # nothing contributes 0 and is reported, not silently dropped.
            local matched=0 g
            for g in $p; do
                [[ -f "$g" ]] || continue
                sz=$(wc -c <"$g"); total=$(( total + sz )); matched=1
            done
            (( matched )) || printf '%s: note -- ARTIFACTS entry matched no file on disk: %s\n' "$PROG" "$p" >&2
        fi
    done < <(brief_artifacts "$brief")
    if (( ! any )); then
        printf '%s: WARNING -- %s names no paths under ARTIFACTS UNDER REVIEW; recording a surface of 0. A zero here means the brief could not be parsed, not that the cycle read nothing.\n' "$PROG" "$brief" >&2
    fi
    printf '%s' "$total"
}

cmd_record() {
    local task="" cycle="" brief=""
    while (( $# )); do
        case "$1" in
            --task)  task="${2:-}";  shift 2 ;;
            --cycle) cycle="${2:-}"; shift 2 ;;
            --brief) brief="${2:-}"; shift 2 ;;
            --data)  DATA_DIR="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) die "unknown argument: $1" ;;
        esac
    done
    [[ -n "$task"  ]] || die "record: --task is required"
    [[ -n "$cycle" ]] || die "record: --cycle is required"
    [[ -n "$brief" ]] || die "record: --brief is required"
    [[ "$cycle" =~ ^[0-9]+$ ]] || die "record: --cycle must be a positive integer, got '$cycle'"
    [[ -f "$brief" ]] || die "record: brief not found: $brief"
    set_paths

    if [[ ! -f "$TSV" && ! -f "$META" ]]; then
        # First call: both files are created together, sharing one run id.
        # Neither can exist without the other.
        local run_id
        run_id="$(basename "$(resolve_data_dir)")-$(date -u +%Y%m%dT%H%M%SZ)"
        printf '#run\t%s\n' "$run_id" >"$TSV"
        printf 'task\tcycle\tcommit\tsurface_bytes\n' >>"$TSV"
        {
            printf 'run\t%s\n' "$run_id"
            printf 'created\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            printf 'tool\t%s\n' "$PROG"
        } >"$META"
        printf '%s: created %s and %s (run %s)\n' "$PROG" "$TSV" "$META" "$run_id"
    fi
    verify_pair

    local commit; commit="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
    local bytes;  bytes="$(surface_bytes "$brief")"
    # The append is CHECKED. This tool exists partly to make W5-5's class of
    # silent state-write failure visible, so it must not commit that failure
    # itself: without `set -e` a failed redirect is swallowed and the success
    # message prints over a row that was never written.
    if ! printf '%s\t%s\t%s\t%s\n' "$task" "$cycle" "$commit" "$bytes" >>"$TSV"; then
        refuse "could not append to $TSV -- the row was NOT recorded. A measurement that failed to write must never report success."
    fi
    printf '%s: recorded %s cycle %s -- declared read surface %s bytes\n' \
        "$PROG" "$task" "$cycle" "$bytes"
}

# ---------------------------------------------------------------------------
# report
# ---------------------------------------------------------------------------

cmd_report() {
    local split_task="" split_commit=""
    while (( $# )); do
        case "$1" in
            --split-at-task) split_task="${2:-}";   shift 2 ;;
            --split-at)      split_commit="${2:-}"; shift 2 ;;
            --data)          DATA_DIR="${2:-}";     shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) die "unknown argument: $1" ;;
        esac
    done
    [[ -z "$split_task" || -z "$split_commit" ]] || die "report: give --split-at-task or --split-at, not both"
    set_paths
    [[ -f "$TSV" ]] || refuse "no data at $TSV -- nothing has been recorded"
    verify_pair

    # The commit form is fragile by nature: a rebase or squash-merge orphans a
    # recorded sha, at which point merge-base either errors or misclassifies.
    # Fail loudly and name the rows rather than report a split we cannot justify.
    if [[ -n "$split_commit" ]]; then
        git rev-parse --verify --quiet "$split_commit^{commit}" >/dev/null \
            || refuse "--split-at commit '$split_commit' is not reachable"
        local unreachable
        unreachable="$(awk -F'\t' 'NR>2 && $3!="unknown"{print $3}' "$TSV" | sort -u | while read -r c; do
            git rev-parse --verify --quiet "$c^{commit}" >/dev/null || printf '%s ' "$c"
        done)"
        [[ -z "$unreachable" ]] || refuse "recorded commits are no longer reachable (rebase or squash): ${unreachable}-- a task id survives those, so use --split-at-task instead"
    fi

    awk -F'\t' -v split_task="$split_task" -v split_commit="$split_commit" '
        NR<=2 { next }
        {
            task=$1; cyc=$2+0; bytes=$4+0
            rows[task]++
            if (cyc==1) { c1[task]=bytes; has1[task]=1 }
            else        { later[task]+=bytes; nlater[task]++ }
            if (!(task in seen)) { seen[task]=1; order[++n]=task }
        }
        END {
            if (n==0) { print "no rows recorded"; exit 0 }
            for (i=1;i<=n;i++) {
                t=order[i]
                side = "all"
                if (split_task != "") side = (t < split_task) ? "before" : "after"
                # Every task on a side counts toward the task and row totals for
                # that side, whether or not its ratio is usable. Only the ratio
                # mean is restricted to usable tasks -- otherwise a task with
                # one cycle silently disappears from the summary and the reader
                # sees a smaller sample than the data actually contains.
                if (side=="before") { btasks++; brows+=rows[t]; bcyc+=rows[t] }
                else if (side=="after") { atasks++; arows+=rows[t]; acyc+=rows[t] }
                printf "%-10s  side=%-6s  cycles=%d  rows=%d  ", t, side, rows[t], rows[t]
                if (!has1[t])            { print "ratio=MISSING (no cycle-1 row -- cannot normalise)"; continue }
                if (nlater[t]==0)        { print "ratio=n/a (only one cycle recorded)"; continue }
                r = (later[t]/nlater[t]) / c1[t]
                printf "ratio=%.3f\n", r
                if (side=="before") { bn++; bsum+=r }
                else if (side=="after") { an++; asum+=r }
            }
            if (split_task != "") {
                print ""
                print "declared read surface -- before/after split at " split_task
                if (btasks>0) {
                    printf "  before: tasks=%d (%d with a usable ratio)  rows=%d  mean cycles=%.2f  ", btasks, bn, brows, bcyc/btasks
                    if (bn>0) printf "mean re-read ratio=%.3f\n", bsum/bn; else print "mean re-read ratio=MISSING (no task has 2+ cycles)"
                } else print "  before: NO ROWS AT ALL -- missing, not zero"
                if (atasks>0) {
                    printf "  after : tasks=%d (%d with a usable ratio)  rows=%d  mean cycles=%.2f  ", atasks, an, arows, acyc/atasks
                    if (an>0) printf "mean re-read ratio=%.3f\n", asum/an; else print "mean re-read ratio=MISSING (no task has 2+ cycles)"
                } else print "  after : NO ROWS AT ALL -- missing, not zero"
                print ""
                print "  A raw cross-task byte comparison is NOT produced: a smaller later task"
                print "  reads fewer bytes whether or not the remedy works. The ratio is"
                print "  within-task, so each task is its own control."
            }
        }
    ' "$TSV"
}

# ---------------------------------------------------------------------------

main() {
    local sub="${1:-}"
    case "$sub" in
        record) shift; cmd_record "$@" ;;
        report) shift; cmd_report "$@" ;;
        -h|--help|help) usage; exit 0 ;;
        "") die "no subcommand -- use 'record' or 'report' (see --help)" ;;
        *) die "unknown subcommand: $sub (use 'record' or 'report')" ;;
    esac
}

main "$@"
