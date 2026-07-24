#!/usr/bin/env bash
# coverage-parity.sh -- executed-assertion inventory + parity-diff gate for the
# canonical bash test corpus (work-024 feature-001, keystone coverage gate).
#
# Purpose:
#   Prove mechanically that a test-suite optimization removes no real coverage.
#   `collect` enumerates the multiset of assertion IDs that actually EXECUTE
#   across the canonical suites (one row per distinct (suite,key), carrying the
#   emission count). `diff` compares an after-inventory to a baseline, excusing
#   documented re-homes and justified accepted-removals, and exits non-zero on
#   any un-excused net-removed/reduced assertion.
#
#   This tool lives at the tests/ ROOT, NOT under tests/canonical/, so it is
#   never matched by the `tests/canonical/test-*.sh` glob in run-all.sh and thus
#   never runs itself as a suite and never counts itself.
#
#   The baseline / re-home allowlist / accepted-removals inputs are passed ONLY
#   as --baseline / --allow / --accept parameters, so no permanent artifact ever
#   hard-depends on a transient work folder (CLAUDE.md transient-work-folder
#   invariant).
#
# Usage:
#   coverage-parity.sh collect --out FILE [--dir DIR] [--allow-missing-runtime]
#       Run every DIR/test-*.sh (sorted glob) under `--verbose`, parse the
#       assert.sh `PASS:`/`FAIL:` lines, and write a sorted, deterministic
#       multiset inventory (<suite>\t<key>\t<count>) to FILE plus a sibling
#       provenance sidecar (<FILE without .tsv>.meta).
#       DIR defaults to <repo>/tests/canonical.
#
#   coverage-parity.sh diff --baseline FILE (--collect [--dir DIR] | --after FILE)
#                            [--allow FILE] [--accept FILE] [--allow-missing-runtime]
#       Compare an after-inventory to the baseline. The after-inventory is
#       either collected live from the current tree (--collect) or read from a
#       pre-collected inventory file (--after). Applies the re-home allowlist
#       (--allow) and accepted-removals list (--accept), prints a report, and
#       sets the exit code.
#
#   coverage-parity.sh -h | --help
#
# Runtime preconditions:
#   `collect` (and `diff --collect`) require pwsh, node, and python3 on PATH --
#   a baseline/after captured with a runtime missing would mis-report every
#   runtime-guarded assertion as removed. Missing any of them -> exit 3. The
#   `--allow-missing-runtime` escape hatch skips this check for local
#   experimentation ONLY; it is UNSAFE for a gating run and must never be used
#   to produce a committed baseline or a gate result.
#
# Coverage-EXECUTION, not correctness:
#   A PASS line and a FAIL line both prove the assertion ran, so a pass->fail
#   regression keeps its key in both inventories and does NOT trip this gate
#   (pass/fail correctness is run-all.sh's job). An assertion skipped by a
#   crash/early-return emits no line and IS flagged as removed.
#
# Exit codes:
#   0  clean (no un-excused reduction, no re-home claimed-but-not-landed)
#   1  parity violation (un-excused reduction and/or claimed-but-not-landed)
#   2  usage / argument error
#   3  runtime precondition failed (a required runtime is absent)
#
# Strict mode: `set -uo pipefail` WITHOUT `-e` -- a canonical suite legitimately
# exits non-zero (a failing assertion still executed), and `grep` legitimately
# returns 1 on no-match; neither must abort the collector (mirrors the
# read-only-linter convention in coding-standards.md).

set -uo pipefail

# Deterministic, byte-stable sorting/formatting regardless of the caller locale.
export LC_ALL=C

PROG="coverage-parity.sh"

# --- Repository root, computed with builtins only ---------------------------
# No external command (dirname/basename) is used here, so this remains correct
# even when the runtime-precondition check below is exercised with an empty PATH.
SCRIPT_SRC="${BASH_SOURCE[0]}"
if [[ "$SCRIPT_SRC" == */* ]]; then
    SCRIPT_DIR="$(cd "${SCRIPT_SRC%/*}" && pwd)"
else
    SCRIPT_DIR="$(pwd)"
fi
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_DIR="${REPO_ROOT}/tests/canonical"

die() { echo "${PROG}: $*" >&2; exit "${2:-2}"; }

usage() {
    # Reprint the header block (Purpose/Usage/Exit codes) per coding-standards.md.
    sed -n '2,63p' "$SCRIPT_SRC" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# require_runtimes: assert pwsh, node, python3 are all on PATH (mirrors the
# test.yml "Assert test runtimes present" step). Returns 3 (not exit) so the
# caller can attach the correct subcommand context; uses only the `command`
# builtin, so it works even under an empty PATH.
# ---------------------------------------------------------------------------
require_runtimes() {
    local r missing=()
    for r in pwsh node python3; do
        command -v "$r" >/dev/null 2>&1 || missing+=("$r")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "${PROG}: missing required runtime(s): ${missing[*]}. A baseline/after captured with a runtime absent mis-reports runtime-guarded assertions as removed. Install them, or pass --allow-missing-runtime (UNSAFE for a gating run)." >&2
        return 3
    fi
    return 0
}

# ---------------------------------------------------------------------------
# normalize_key LABEL -> stable assertion identity (stdout, no trailing newline)
#   1. Strip a trailing " (exit N)" / " (exit N, not M)" suffix and any trailing
#      " [SKIPPED: ...]" shim, so the pwsh-present and pwsh-absent forms of an
#      assertion collapse to one key.
#   2. If the stripped label begins with a MULTI-letter assertion-ID token
#      (^[A-Za-z]{2,}[0-9][A-Za-z0-9._-]*) -> that token is the key. The {2,}
#      requires two-or-more letters before the first digit, so a single-letter
#      prefix such as `T07` does NOT match and falls through to step 3.
#   3. Otherwise mask the volatile substring classes (temp/scratch dirs, any
#      remaining absolute path, semver/version strings, long hex/SHA runs) to
#      placeholders and squeeze whitespace, so a free-form label is stable
#      run-to-run.
# ---------------------------------------------------------------------------
normalize_key() {
    local label="$1"

    # Step 1 -- strip volatile trailing suffixes (fork-free).
    #   " [SKIPPED: ...]" shim (the bracket is escaped so glob does not read it
    #   as a character class).
    label="${label% \[SKIPPED:*}"
    #   " (exit N)" / " (exit N, not M)" suffix appended by assert_exit_*.
    if [[ "$label" =~ ^(.*)" (exit "[0-9]+(", not "[0-9]+)?")"$ ]]; then
        label="${BASH_REMATCH[1]}"
    fi

    # Step 2 -- multi-letter assertion-ID token wins.
    if [[ "$label" =~ ^([A-Za-z][A-Za-z]+[0-9][A-Za-z0-9._-]*) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi

    # Step 3 -- mask volatile classes, then squeeze whitespace. Masking is
    # applied identically to the baseline and the after side, so any residual
    # over-masking is deterministic and cannot create a false diff.
    printf '%s' "$label" | sed -E '
        s#[A-Za-z]:[\\/][^[:space:]]*#<PATH>#g
        s#/[^[:space:]]*#<PATH>#g
        s#v?[0-9]+(\.[0-9]+)+([-+.][A-Za-z0-9]+)*#<VER>#g
        s#[0-9a-fA-F]{7,}#<HEX>#g
        s/[[:space:]]+/ /g
        s/^[[:space:]]+//
        s/[[:space:]]+$//
    '
}

# ---------------------------------------------------------------------------
# run_one_suite SUITE -> the suite's combined stdout+stderr (verbose run).
# Uses `timeout 300` when available (mirrors run-all.sh:47), tolerating any
# non-zero exit -- a failing suite still executed its assertions.
# ---------------------------------------------------------------------------
TIMEOUT_BIN="$(command -v timeout 2>/dev/null || true)"
run_one_suite() {
    local suite="$1"
    if [[ -n "$TIMEOUT_BIN" ]]; then
        "$TIMEOUT_BIN" 300 bash "$suite" --verbose 2>&1
    else
        bash "$suite" --verbose 2>&1
    fi
}

# ---------------------------------------------------------------------------
# collect_inventory OUTFILE DIR
# Core collector: chmod +x the suites (idempotent), run each DIR/test-*.sh in
# isolation under --verbose, extract the assert.sh PASS/FAIL labels, normalize,
# and write the sorted multiset <suite>\t<key>\t<count> to OUTFILE.
# Does NOT check runtimes (the caller does) and does NOT write a .meta sidecar
# (the `collect` subcommand does).
# ---------------------------------------------------------------------------
collect_inventory() {
    local outfile="$1" dir="$2"

    if [[ ! -d "$dir" ]]; then
        die "collect: suite directory not found: $dir" 2
    fi

    # Idempotent exec-bit fix (mirrors run-all.sh:27; repo authored on Windows at 100644).
    chmod +x "$dir"/test-*.sh 2>/dev/null || true

    local suites=() s
    shopt -s nullglob
    for s in "$dir"/test-*.sh; do
        suites+=("$s")
    done
    shopt -u nullglob

    local raw
    raw="$(mktemp)"

    if [[ ${#suites[@]} -gt 0 ]]; then
        # Sort the glob deterministically (byte order under LC_ALL=C).
        mapfile -t suites < <(printf '%s\n' "${suites[@]}" | sort)
        local base label
        for s in "${suites[@]}"; do
            base="${s##*/}"
            while IFS= read -r label; do
                [[ -z "$label" ]] && continue
                printf '%s\t%s\n' "$base" "$(normalize_key "$label")" >> "$raw"
            done < <(run_one_suite "$s" \
                        | grep -E '^[[:space:]]*(PASS|FAIL):[[:space:]]' \
                        | sed -E 's/^[[:space:]]*(PASS|FAIL):[[:space:]]+//')
        done
    fi

    # Counted multiset via `sort | uniq -c` (NOT `sort -u`, which would drop the
    # count that makes a within-loop iteration-count reduction visible). The awk
    # reformats each `<count> <suite>\t<key>` line to `<suite>\t<key>\t<count>`
    # WITHOUT re-splitting on the embedded tab: it reads the count from field 1,
    # strips only that leading "<pad><count><space>" prefix from $0, then appends
    # the count. A key containing spaces is preserved verbatim, and the tab
    # separators stay exact on every platform (awk interprets `\t`, unlike BSD
    # sed). The sorted order from `sort` is preserved through `uniq -c` and awk,
    # so the inventory is sorted by (suite,key) and byte-stable run-to-run.
    sort "$raw" | uniq -c \
        | awk '{ c = $1; sub(/^[[:space:]]*[0-9]+[[:space:]]/, ""); print $0 "\t" c }' \
        > "$outfile"

    rm -f "$raw"
}

# ---------------------------------------------------------------------------
# write_meta METAFILE DIR
# Provenance sidecar: master SHA, UTC timestamp, runner OS, runtime versions.
# ---------------------------------------------------------------------------
tool_version() {
    # tool_version NAME COMMAND...
    local name="$1"; shift
    if command -v "$1" >/dev/null 2>&1; then
        local v
        v="$("$@" 2>&1 | head -1)"
        printf '%s: %s\n' "$name" "$v"
    else
        printf '%s: absent\n' "$name"
    fi
}

write_meta() {
    local metafile="$1"
    {
        echo "# coverage-parity baseline provenance (auto-generated -- do not edit)"
        printf 'captured_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
        printf 'commit_sha: %s\n' "$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
        printf 'runner_os: %s\n' "$(uname -srmo 2>/dev/null || uname -s 2>/dev/null || echo unknown)"
        tool_version "pwsh_version" pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        tool_version "node_version" node --version
        tool_version "python3_version" python3 --version
    } > "$metafile"
}

# ---------------------------------------------------------------------------
# Subcommand: collect
# ---------------------------------------------------------------------------
cmd_collect() {
    local out="" dir="$DEFAULT_DIR" allow_missing=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --out)  [[ $# -lt 2 ]] && die "collect: --out requires a value"; out="$2"; shift 2 ;;
            --dir)  [[ $# -lt 2 ]] && die "collect: --dir requires a value"; dir="$2"; shift 2 ;;
            --allow-missing-runtime) allow_missing=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) die "collect: unknown argument: $1" ;;
        esac
    done

    [[ -z "$out" ]] && die "collect: --out FILE is required"

    if [[ "$allow_missing" -eq 0 ]]; then
        require_runtimes || exit 3
    fi

    collect_inventory "$out" "$dir"

    local metafile="${out%.tsv}.meta"
    write_meta "$metafile"

    echo "${PROG}: collect -> $out ($(wc -l < "$out" | tr -d ' ') rows); provenance -> $metafile" >&2
    exit 0
}

# ---------------------------------------------------------------------------
# read_inventory FILE ARRAYNAME
# Load an inventory (<suite>\t<key>\t<count>) into the named associative array,
# keyed by "<suite>\t<key>" -> count. Comment (#) and blank lines are ignored.
# ---------------------------------------------------------------------------
read_inventory() {
    local file="$1" arrname="$2"
    local -n arr="$arrname"
    local suite key count
    while IFS=$'\t' read -r suite key count; do
        [[ -z "$suite" || "$suite" == \#* ]] && continue
        [[ -z "$count" ]] && continue
        arr["${suite}"$'\t'"${key}"]="$count"
    done < "$file"
}

# ---------------------------------------------------------------------------
# Subcommand: diff
# ---------------------------------------------------------------------------
cmd_diff() {
    local baseline="" allow="" accept="" after="" do_collect=0 dir="$DEFAULT_DIR" allow_missing=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --baseline) [[ $# -lt 2 ]] && die "diff: --baseline requires a value"; baseline="$2"; shift 2 ;;
            --allow)    [[ $# -lt 2 ]] && die "diff: --allow requires a value"; allow="$2"; shift 2 ;;
            --accept)   [[ $# -lt 2 ]] && die "diff: --accept requires a value"; accept="$2"; shift 2 ;;
            --after)    [[ $# -lt 2 ]] && die "diff: --after requires a value"; after="$2"; shift 2 ;;
            --collect)  do_collect=1; shift ;;
            --dir)      [[ $# -lt 2 ]] && die "diff: --dir requires a value"; dir="$2"; shift 2 ;;
            --allow-missing-runtime) allow_missing=1; shift ;;
            -h|--help)  usage; exit 0 ;;
            *) die "diff: unknown argument: $1" ;;
        esac
    done

    [[ -z "$baseline" ]] && die "diff: --baseline FILE is required"
    [[ ! -f "$baseline" ]] && die "diff: baseline not found: $baseline"

    if [[ "$do_collect" -eq 1 && -n "$after" ]]; then
        die "diff: --collect and --after are mutually exclusive"
    fi
    if [[ "$do_collect" -eq 0 && -z "$after" ]]; then
        die "diff: an after-inventory is required -- pass --collect (collect live) or --after FILE"
    fi

    # Resolve the after-inventory.
    local after_file
    local collected_tmp=""
    if [[ "$do_collect" -eq 1 ]]; then
        if [[ "$allow_missing" -eq 0 ]]; then
            require_runtimes || exit 3
        fi
        collected_tmp="$(mktemp)"
        collect_inventory "$collected_tmp" "$dir"
        after_file="$collected_tmp"
    else
        [[ ! -f "$after" ]] && die "diff: after-inventory not found: $after"
        after_file="$after"
    fi

    # Load inventories.
    declare -A BASE AFTER
    read_inventory "$baseline" BASE
    read_inventory "$after_file" AFTER

    # ---- Provenance / stale-baseline warning (best-effort) ----
    local metafile="${baseline%.tsv}.meta"
    if [[ -f "$metafile" ]]; then
        local recorded_sha head_sha
        recorded_sha="$(sed -n 's/^commit_sha: //p' "$metafile" | head -1)"
        head_sha="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
        echo "baseline provenance: $metafile (commit ${recorded_sha:-unknown})"
        if [[ -n "$recorded_sha" && "$recorded_sha" != "unknown" && "$head_sha" != "unknown" && "$recorded_sha" != "$head_sha" ]]; then
            echo "WARN: current HEAD ($head_sha) differs from the baseline commit ($recorded_sha); the diff may be comparing against a stale baseline." >&2
        fi
    fi

    # ---- Load re-home allowlist rules ----
    # Parallel arrays: RH_OLD["<suite>\t<key>"] -> "<new_suite>\t<new_key>"
    declare -A RH_OLD
    local rh_targets=()   # list of "<new_suite>\t<new_key>" for claimed-not-landed scan
    local rh_lines=()     # human-readable "old -> new" for the report
    if [[ -n "$allow" ]]; then
        [[ ! -f "$allow" ]] && die "diff: allowlist not found: $allow"
        local os ok ns nk rationale
        while IFS=$'\t' read -r os ok ns nk rationale; do
            [[ -z "$os" || "$os" == \#* ]] && continue
            [[ -z "$ns" || -z "$nk" ]] && continue
            RH_OLD["${os}"$'\t'"${ok}"]="${ns}"$'\t'"${nk}"
            rh_targets+=("${ns}"$'\t'"${nk}")
            rh_lines+=("${os} / ${ok}  ->  ${ns} / ${nk}")
        done < "$allow"
    fi

    # ---- Load accepted-removals ----
    declare -A ACCEPT
    if [[ -n "$accept" ]]; then
        [[ ! -f "$accept" ]] && die "diff: accepted-removals not found: $accept"
        local a_suite a_key a_delivery a_just
        while IFS=$'\t' read -r a_suite a_key a_delivery a_just; do
            [[ -z "$a_suite" || "$a_suite" == \#* ]] && continue
            [[ -z "$a_just" ]] && continue   # a removal is excused only WITH a justification
            ACCEPT["${a_suite}"$'\t'"${a_key}"]="$a_just"
        done < "$accept"
    fi

    # ---- Compute reductions ----
    local violations=() excused_rehome=() excused_accept=() added=() claimed_not_landed=()
    local pk suite key b a reduced

    for pk in "${!BASE[@]}"; do
        b="${BASE[$pk]}"
        a="${AFTER[$pk]:-0}"
        if [[ "$a" -lt "$b" ]]; then
            reduced=$(( b - a ))
            suite="${pk%%$'\t'*}"
            key="${pk#*$'\t'}"
            if [[ -n "${RH_OLD[$pk]:-}" ]]; then
                local tgt="${RH_OLD[$pk]}"
                local tgt_count="${AFTER[$tgt]:-0}"
                if [[ "$tgt_count" -gt 0 ]]; then
                    local tsuite="${tgt%%$'\t'*}" tkey="${tgt#*$'\t'}"
                    excused_rehome+=("${suite}"$'\t'"${key}"$'\t'"re-homed to ${tsuite} / ${tkey}")
                    continue
                fi
                # target absent -> falls through to violation (also flagged below as claimed-not-landed)
            fi
            if [[ -n "${ACCEPT[$pk]:-}" ]]; then
                excused_accept+=("${suite}"$'\t'"${key}"$'\t'"${ACCEPT[$pk]}")
                continue
            fi
            violations+=("${suite}"$'\t'"${key}"$'\t'"baseline=${b} after=${a} (reduced ${reduced})")
        fi
    done

    # ---- Net-adds (INFO) ----
    for pk in "${!AFTER[@]}"; do
        a="${AFTER[$pk]}"
        b="${BASE[$pk]:-0}"
        if [[ "$a" -gt "$b" ]]; then
            suite="${pk%%$'\t'*}"
            key="${pk#*$'\t'}"
            added+=("${suite}"$'\t'"${key}"$'\t'"+$(( a - b ))")
        fi
    done

    # ---- Claimed-but-not-landed: any re-home rule whose target is absent from after ----
    local i tgt
    for i in "${!rh_targets[@]}"; do
        tgt="${rh_targets[$i]}"
        if [[ "${AFTER[$tgt]:-0}" -eq 0 ]]; then
            claimed_not_landed+=("${rh_lines[$i]}")
        fi
    done

    [[ -n "$collected_tmp" ]] && rm -f "$collected_tmp"

    # ---- Report ----
    echo "=== coverage-parity diff ==="
    echo "baseline: $baseline"
    if [[ "$do_collect" -eq 1 ]]; then
        echo "after:    <collected from ${dir}>"
    else
        echo "after:    $after_file"
    fi
    echo

    if [[ ${#violations[@]} -gt 0 ]]; then
        echo "-- REMOVED / REDUCED (un-excused) (${#violations[@]}) --"
        local line
        while IFS= read -r line; do printf '   [REMOVED] %s\n' "$line"; done \
            < <(printf '%s\n' "${violations[@]}" | sort)
    fi
    if [[ ${#claimed_not_landed[@]} -gt 0 ]]; then
        echo "-- re-home claimed but not landed (target absent from after) (${#claimed_not_landed[@]}) --"
        local line
        while IFS= read -r line; do printf '   [CLAIMED-NOT-LANDED] %s\n' "$line"; done \
            < <(printf '%s\n' "${claimed_not_landed[@]}" | sort)
    fi
    if [[ ${#excused_rehome[@]} -gt 0 ]]; then
        echo "-- excused: re-homed (${#excused_rehome[@]}) --"
        local line
        while IFS= read -r line; do printf '   [RE-HOME] %s\n' "$line"; done \
            < <(printf '%s\n' "${excused_rehome[@]}" | sort)
    fi
    if [[ ${#excused_accept[@]} -gt 0 ]]; then
        echo "-- excused: accepted-removal (${#excused_accept[@]}) --"
        local line
        while IFS= read -r line; do printf '   [ACCEPTED] %s\n' "$line"; done \
            < <(printf '%s\n' "${excused_accept[@]}" | sort)
    fi
    if [[ ${#added[@]} -gt 0 ]]; then
        echo "-- added (net-new, INFO) (${#added[@]}) --"
        local line
        while IFS= read -r line; do printf '   [INFO added] %s\n' "$line"; done \
            < <(printf '%s\n' "${added[@]}" | sort)
    fi
    echo

    if [[ ${#violations[@]} -eq 0 && ${#claimed_not_landed[@]} -eq 0 ]]; then
        echo "RESULT: PASS -- no net-removed coverage (excused re-homes: ${#excused_rehome[@]}, accepted-removals: ${#excused_accept[@]}, net-adds: ${#added[@]})"
        exit 0
    fi
    echo "RESULT: FAIL -- ${#violations[@]} un-excused reduction(s), ${#claimed_not_landed[@]} claimed-but-not-landed re-home(s)"
    exit 1
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
main() {
    local sub="${1:-}"
    case "$sub" in
        collect) shift; cmd_collect "$@" ;;
        diff)    shift; cmd_diff "$@" ;;
        -h|--help|help) usage; exit 0 ;;
        "") die "no subcommand -- use 'collect' or 'diff' (see --help)" ;;
        *) die "unknown subcommand: $sub (use 'collect' or 'diff')" ;;
    esac
}

main "$@"
