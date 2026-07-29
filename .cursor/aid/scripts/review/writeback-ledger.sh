#!/usr/bin/env bash
# writeback-ledger.sh -- surgical row writer for the reviewer ledger.
#
# WHY THIS EXISTS
# The prior contract had the reviewer re-emit the ENTIRE ledger table inside a `cat >` heredoc on
# every checkpoint. That is expensive (a 30-row ledger is 3.3-10 KB, so ~0.9-2.5k output tokens per
# checkpoint, plus a comparable read) and, worse, every checkpoint is an opportunity to silently
# truncate every prior finding. This helper reduces a checkpoint to one Bash call carrying one row's
# cells (~200-260 bytes) with no read at all.
#
# The honest form of the claim: this script still rewrites the file (awk to mktemp, then mv), exactly
# as execute/writeback-state.sh does for a task-state field write. What goes to zero is
# AGENT-AUTHORED whole-table re-emission -- prior rows are reproduced by the script, never retyped by
# the model, so the truncation surface is zero.
#
# THE TABLE: 8 columns, three row kinds distinguished by the `#` column.
#   | # | Severity | Status | Rule | Doc | Line | Description | Evidence |
#
#   finding  #=NNN or <NS>-NNN   Severity=[TOKEN]  Status=Pending|Fixed|Recurred|Accepted|OOS|Invalid
#   coverage #=U-NNN             Severity=--       Status=Unexamined|In Progress|Examined|Skipped
#   gap      #=G-NNN             Severity=--       Status=Open|Resolved
#
# GRADE INERTNESS is by construction, not convention: grade.sh counts a row only when cols[3] is
# exactly one of the five bracketed severity tokens AND cols[4] is exactly Pending or Recurred. A
# `--` in Severity fails that chain, so a coverage/gap row can safely carry status words that look
# grade-bearing. Verified at write time -- see --verify-grade below.
#
# USAGE
#   writeback-ledger.sh --ledger PATH --append-finding \
#       --severity '[HIGH]' [--status Pending] --rule NAR-04 \
#       --doc foo.md [--line 42] --description '...' --evidence '...' [--namespace M1]
#
#   writeback-ledger.sh --ledger PATH --append-unit \
#       --unit foo.md --rule-set KB [--status Unexamined] [--stamp ISO8601] [--namespace M1]
#
#   writeback-ledger.sh --ledger PATH --append-gap \
#       --gap-key <stable-key> --doc baz.sh --description '...' \
#       --resolution '/aid-update-kb coding-standards' [--status Open] [--namespace M2]
#
#   writeback-ledger.sh --ledger PATH --set-status --row-id U-002 --status Examined
#   writeback-ledger.sh --ledger PATH --row-id U-002 --get-status          # read-only
#
#   writeback-ledger.sh --ledger PATH --list-units [--status S] [--remaining] [--namespace NS]
#       read-only. TSV to stdout: row-id, status, doc, rule-set, stamp, art, rs
#       --remaining is sugar for "Unexamined or In Progress" -- the resume contract's "treat an
#       interrupted unit as unexamined", made mechanical in the read API instead of restated in prose
#       at every caller.
#
# EXIT CODES (aligned with execute/writeback-state.sh)
#   0 success
#   1 ledger unreadable, or parent directory absent
#   2 lock contention -- a BUG SIGNAL, not a normal path (today's writers are single-writer)
#   3 write produced empty or unverifiable output; original preserved
#   4 invalid argument -- bad severity token, status illegal for the row kind, a missing or
#     malformed Rule on a finding, raw newline, --rule against a 7-column ledger
#   5 missing required argument
#   6 malformed ledger -- no header, or a header that is neither 7 nor 8 columns
#   7 --row-id not found
set -uo pipefail

SCRIPT_NAME="writeback-ledger.sh"
# Relative, with no `canonical/` prefix, so rewrite_install_paths has nothing to rewrite and this
# resolves identically in the canonical tree and in every rendered profile.
GRADE_SH="$(dirname "$0")/../grade.sh"

LOCK_TIMEOUT="${LOCK_TIMEOUT:-20}"

HDR8='| # | Severity | Status | Rule | Doc | Line | Description | Evidence |'
SEP8='|---|---|---|---|---|---|---|---|'

die() { echo "ERROR: ${SCRIPT_NAME}: $*" >&2; exit "${2:-1}"; }

usage() { sed -n '/^# USAGE/,/^set -uo/p' "$0" | sed 's/^# \{0,1\}//; $d'; }

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
LEDGER=""; MODE=""
SEVERITY=""; STATUS=""; RULE=""; DOC=""; LINE=""; DESCRIPTION=""; EVIDENCE=""
UNIT=""; RULE_SET=""; STAMP=""; NAMESPACE=""
GAP_KEY=""; RESOLUTION=""; ROW_ID=""
VERIFY_GRADE=1; REMAINING=0

set_mode() {
    [[ -z "$MODE" ]] || die "two modes given: --$MODE and --$1" 4
    MODE="$1"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ledger)         LEDGER="${2:-}"; shift 2 ;;
        --append-finding) set_mode append-finding; shift ;;
        --append-unit)    set_mode append-unit; shift ;;
        --append-gap)     set_mode append-gap; shift ;;
        --set-status)     set_mode set-status; shift ;;
        --get-status)     set_mode get-status; shift ;;
        --list-units)     set_mode list-units; shift ;;
        --remaining)      REMAINING=1; shift ;;
        --severity)       SEVERITY="${2:-}"; shift 2 ;;
        --status)         STATUS="${2:-}"; shift 2 ;;
        --rule)           RULE="${2:-}"; shift 2 ;;
        --doc)            DOC="${2:-}"; shift 2 ;;
        --line)           LINE="${2:-}"; shift 2 ;;
        --description)    DESCRIPTION="${2:-}"; shift 2 ;;
        --evidence)       EVIDENCE="${2:-}"; shift 2 ;;
        --unit)           UNIT="${2:-}"; shift 2 ;;
        --rule-set)       RULE_SET="${2:-}"; shift 2 ;;
        --stamp)          STAMP="${2:-}"; shift 2 ;;
        --namespace)      NAMESPACE="${2:-}"; shift 2 ;;
        --gap-key)        GAP_KEY="${2:-}"; shift 2 ;;
        --resolution)     RESOLUTION="${2:-}"; shift 2 ;;
        --row-id)         ROW_ID="${2:-}"; shift 2 ;;
        --no-verify-grade) VERIFY_GRADE=0; shift ;;
        --verify-grade)   VERIFY_GRADE=1; shift ;;
        -h|--help)        usage; exit 0 ;;
        *)                die "unknown argument: $1" 4 ;;
    esac
done

[[ -n "$LEDGER" ]] || die "--ledger is required" 5
[[ -n "$MODE" ]]   || die "one of --append-finding / --append-unit / --append-gap / --set-status / --get-status is required" 5

# ---------------------------------------------------------------------------
# Validation vocabularies
# ---------------------------------------------------------------------------
SEV_RE='^\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]$'
RULE_RE='^[A-Z]{2,12}-[0-9]{2}$'

status_ok_finding()  { case "$1" in Pending|Fixed|Recurred|Accepted|OOS|Invalid) return 0 ;; *) return 1 ;; esac; }
status_ok_unit()     { case "$1" in Unexamined|"In Progress"|Examined|Skipped)   return 0 ;; *) return 1 ;; esac; }
status_ok_gap()      { case "$1" in Open|Resolved)                              return 0 ;; *) return 1 ;; esac; }

# Raw newlines would split one logical row across table lines and corrupt the file. Same guard class
# as writeback-state.sh's newline rejection.
reject_newline() {
    local name="$1" val="$2"
    [[ "$val" == *$'\n'* || "$val" == *$'\r'* ]] && die "--${name} contains a raw newline; not permitted" 4
    return 0
}

# Pipes are ESCAPED, not rejected: unlike the STATE table, the ledger schema defines `\|`. Safe for
# the grader because the closed-vocabulary columns and the path column cannot contain a pipe, so an
# escaped pipe can only ever land after cols[4].
esc_pipe() { printf '%s' "${1//|/\\|}"; }

# `--` is the null sentinel throughout (matching the Rule sentinel and the STATE templates), not the
# em-dash the schema's older Line examples used. grade.sh ignores both, so existing cells are not
# migrated; this binds new rows only.
nz() { [[ -n "$1" ]] && printf '%s' "$1" || printf '%s' '--'; }

# ---------------------------------------------------------------------------
# Lock -- inherited from writeback-state.sh. Unnecessary under today's
# single-writer invariant, present because the orchestrator becomes a second
# writer of this same file once resume lands. Exit 2 is a bug signal.
# ---------------------------------------------------------------------------
LOCK_FILE=""; LOCK_ACQUIRED=0

init_lock_file() { LOCK_FILE="$(dirname "$1")/.writeback-ledger.lock"; }

acquire_lock() {
    local parent; parent="$(dirname "$LOCK_FILE")"
    [[ -d "$parent" ]] || die "lock directory does not exist: $parent" 1
    local attempts=0
    while true; do
        if ( set -o noclobber; echo $$ > "$LOCK_FILE" ) 2>/dev/null; then
            LOCK_ACQUIRED=1; return 0
        fi
        attempts=$((attempts + 1))
        if [[ "$attempts" -ge "$LOCK_TIMEOUT" ]]; then
            die "lock contention: $LOCK_FILE held after ${attempts} retries (~$((attempts / 2))s). Another process is writing this ledger. This is a bug signal, not a normal path." 2
        fi
        sleep 0.5
    done
}

release_lock() { [[ "$LOCK_ACQUIRED" -eq 1 ]] && { rm -f "$LOCK_FILE"; LOCK_ACQUIRED=0; }; return 0; }
trap 'release_lock' EXIT

# ---------------------------------------------------------------------------
# Digests -- sha256 with the sha256sum/shasum fallback already used in the tree
# (kb-dual-intent-probes.sh, lib/aid-install-core.sh). Truncated: these are
# change detectors, not cryptographic commitments.
# ---------------------------------------------------------------------------
sha_of_file() {
    local f="$1"
    [[ -f "$f" ]] || { printf 'absent'; return 0; }
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$f" | cut -c1-12
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$f" | cut -c1-12
    else
        printf 'nodigest'
    fi
}

# The rule-set digest covers the catalog file PLUS every distinct path appearing in its Criterion
# cells, so a rule set whose declaring documents changed reads as changed even when the catalog file
# itself did not.
sha_of_rule_set() {
    local rs="$1" cat_dir base f
    # This script lives at aid/scripts/review/, the catalog at aid/templates/review-rubrics/ -- two
    # levels up, not one. Relative with no `canonical/` prefix, so it resolves identically in the
    # canonical tree and in every rendered profile.
    cat_dir="$(dirname "$0")/../../templates/review-rubrics"
    base=""
    for cand in "$cat_dir/$(printf '%s' "$rs" | tr 'A-Z' 'a-z').md" "$cat_dir/INDEX.md"; do
        [[ -f "$cand" ]] && { base="$cand"; break; }
    done
    [[ -n "$base" ]] || { printf 'absent'; return 0; }
    {
        cat "$base"
        # every backticked doc name in a Criterion cell, resolved where possible
        awk -F'|' '/^\|/ { print $4 }' "$base" 2>/dev/null \
          | grep -oE '`[^`]+`' | tr -d '`' | sed 's/ *§.*//' | sort -u \
          | while IFS= read -r dep; do
                [[ -z "$dep" ]] && continue
                for root in ".aid/knowledge" "$cat_dir/.." "."; do
                    [[ -f "$root/$dep" ]] && { cat "$root/$dep"; break; }
                done
            done
    } 2>/dev/null | if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -c1-12
                    elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | cut -c1-12
                    else printf 'nodigest'; fi
}

# ---------------------------------------------------------------------------
# Ledger inspection
# ---------------------------------------------------------------------------
ensure_parent() {
    local parent; parent="$(dirname "$LEDGER")"
    [[ -d "$parent" ]] || die "parent directory does not exist: $parent" 1
}

# Header width: 8 (current) or 7 (pre-migration, still readable per NFR-5).
header_width() {
    local h
    h="$(grep -m1 '^|' "$LEDGER" 2>/dev/null || true)"
    [[ -n "$h" ]] || { printf '0'; return 0; }
    local n; n="$(printf '%s' "$h" | awk -F'|' '{print NF-2}')"
    printf '%s' "$n"
}

create_if_absent() {
    if [[ ! -f "$LEDGER" ]]; then
        ensure_parent
        printf '%s\n%s\n' "$HDR8" "$SEP8" > "$LEDGER"
    fi
}

is_sep_row() { [[ "$1" =~ ^\|[[:space:]:|-]+\|$ ]]; }

# Next free ID for a kind. Findings: next integer. Coverage/gap: next NNN within kind+namespace.
next_id() {
    local kind="$1" ns="$2" prefix="" max=0 id num
    case "$kind" in
        finding) prefix="" ;;
        unit)    prefix="U-" ;;
        gap)     prefix="G-" ;;
    esac
    local want="^${prefix}"
    [[ -n "$ns" ]] && want="${want}${ns}-"
    want="${want}[0-9]+$"

    while IFS= read -r line; do
        [[ "$line" == \|* ]] || continue
        is_sep_row "$line" && continue
        id="$(printf '%s' "$line" | awk -F'|' '{gsub(/[ `]/,"",$2); print $2}')"
        [[ "$id" == "#" ]] && continue
        [[ "$id" =~ $want ]] || continue
        num="${id##*-}"
        num="${num#0}"; num="${num#0}"          # tolerate zero padding
        [[ -z "$num" ]] && num=0
        [[ "$num" -gt "$max" ]] && max="$num"
    done < "$LEDGER"

    local nxt=$((max + 1))
    if [[ "$kind" == "finding" ]]; then
        [[ -n "$ns" ]] && printf '%s-%s' "$ns" "$nxt" || printf '%s' "$nxt"
    else
        [[ -n "$ns" ]] && printf '%s%s-%03d' "$prefix" "$ns" "$nxt" \
                       || printf '%s%03d' "$prefix" "$nxt"
    fi
}

# Find a row by its `#` value; prints the whole line, or nothing.
find_row() {
    local target="$1" line id
    while IFS= read -r line; do
        [[ "$line" == \|* ]] || continue
        is_sep_row "$line" && continue
        id="$(printf '%s' "$line" | awk -F'|' '{gsub(/[ `]/,"",$2); print $2}')"
        [[ "$id" == "$target" ]] && { printf '%s' "$line"; return 0; }
    done < "$LEDGER"
    return 1
}

row_kind_of() {
    case "$1" in
        U-*) printf 'unit' ;;
        G-*) printf 'gap' ;;
        *)   printf 'finding' ;;
    esac
}

data_row_count() {
    local n=0 line
    while IFS= read -r line; do
        [[ "$line" == \|* ]] || continue
        is_sep_row "$line" && continue
        [[ "$(printf '%s' "$line" | awk -F'|' '{gsub(/[ `]/,"",$2); print $2}')" == "#" ]] && continue
        n=$((n + 1))
    done < "$LEDGER"
    printf '%s' "$n"
}

grade_of() {
    [[ -f "$GRADE_SH" ]] || { printf 'nograder'; return 0; }
    bash "$GRADE_SH" "$1" 2>/dev/null || printf 'error'
}

# ---------------------------------------------------------------------------
# CRLF / trailing-newline invariance, inherited wholesale from
# wb_set_frontmatter's guards. Ledgers get written on Windows too; without this
# the byte-invariance property fails on the first Windows checkpoint.
# ---------------------------------------------------------------------------
HAS_CRLF=0; HAD_TRAILING_NL=1

detect_eol() {
    HAS_CRLF=0; HAD_TRAILING_NL=1
    [[ -s "$LEDGER" ]] || return 0
    local first=""
    IFS= read -r first < "$LEDGER" 2>/dev/null || true
    [[ "$first" == *$'\r' ]] && HAS_CRLF=1
    [[ "$(tail -c1 "$LEDGER" | wc -l)" -eq 0 ]] && HAD_TRAILING_NL=0
    return 0
}

# emit_transformed <awk-program> [awk -v args...]
# Runs the awk program over the ledger with CRLF stripped, restores CRLF per line, and drops the
# spurious terminator only when the source genuinely lacked one.
emit_transformed() {
    local prog="$1"; shift
    local out
    if [[ "$HAS_CRLF" -eq 1 ]]; then
        out="$(sed 's/\r$//' "$LEDGER" | awk "$@" "$prog" | sed 's/$/\r/'; printf 'X')"
    else
        out="$(awk "$@" "$prog" "$LEDGER"; printf 'X')"
    fi
    out="${out%X}"
    if [[ "$HAD_TRAILING_NL" -eq 0 ]]; then
        if [[ "$HAS_CRLF" -eq 1 ]]; then out="${out%$'\r\n'}"; else out="${out%$'\n'}"; fi
    fi
    printf '%s' "$out"
}

# ---------------------------------------------------------------------------
# Post-write verification. The original is preserved on any failure.
#   - output non-empty
#   - header row byte-identical to the input's
#   - data-row count is exactly as expected (+1 append, +0 set-status)
#   - the target row is present
#   - for non-finding appends: grade.sh on pre-image and post-image AGREE (AC-9
#     enforced at write time, default-on, not merely in a fixture)
# ---------------------------------------------------------------------------
commit_or_die() {
    local tmp="$1" expect_rows="$2" expect_row_id="$3" check_grade="$4" pre_grade="$5"

    [[ -s "$tmp" ]] || { rm -f "$tmp"; die "write produced empty output; original preserved" 3; }

    local hdr_in hdr_out
    hdr_in="$(grep -m1 '^|' "$LEDGER" 2>/dev/null || true)"
    hdr_out="$(grep -m1 '^|' "$tmp" 2>/dev/null || true)"
    if [[ -n "$hdr_in" && "$hdr_in" != "$hdr_out" ]]; then
        rm -f "$tmp"; die "write altered the header row; original preserved" 3
    fi

    local n=0 line
    while IFS= read -r line; do
        [[ "$line" == \|* ]] || continue
        is_sep_row "$line" && continue
        [[ "$(printf '%s' "$line" | awk -F'|' '{gsub(/[ `]/,"",$2); print $2}')" == "#" ]] && continue
        n=$((n + 1))
    done < "$tmp"
    if [[ "$n" -ne "$expect_rows" ]]; then
        rm -f "$tmp"; die "write produced $n data rows, expected $expect_rows; original preserved" 3
    fi

    if [[ -n "$expect_row_id" ]] && ! grep -qF "| $expect_row_id |" "$tmp"; then
        rm -f "$tmp"; die "target row '$expect_row_id' absent from output; original preserved" 3
    fi

    if [[ "$check_grade" -eq 1 ]]; then
        local post_grade; post_grade="$(grade_of "$tmp")"
        if [[ "$pre_grade" != "$post_grade" ]]; then
            rm -f "$tmp"
            die "grade changed from '$pre_grade' to '$post_grade' -- a non-finding row must be grade-inert (AC-9); original preserved" 3
        fi
    fi

    mv "$tmp" "$LEDGER" || { rm -f "$tmp"; die "could not replace ledger" 3; }
}

append_row() {                    # $1 = the complete row text, $2 = row id, $3 = verify grade?
    local row="$1" rid="$2" check="$3"
    local pre_rows pre_grade tmp
    pre_rows="$(data_row_count)"
    pre_grade=""
    [[ "$check" -eq 1 ]] && pre_grade="$(grade_of "$LEDGER")"

    detect_eol
    tmp="$(mktemp)"
    # Append after the last table line, so trailing prose (if any) stays put.
    ROW_TEXT="$row" emit_transformed '
      /^\|/ { last = NR }
      { lines[NR] = $0 }
      END {
        for (i = 1; i <= NR; i++) {
          print lines[i]
          if (i == last) print ENVIRON["ROW_TEXT"]
        }
        if (last == 0) print ENVIRON["ROW_TEXT"]
      }
    ' > "$tmp"

    commit_or_die "$tmp" "$((pre_rows + 1))" "$rid" "$check" "$pre_grade"
}

# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------
mode_append_finding() {
    [[ -n "$SEVERITY" ]]    || die "--severity is required for --append-finding" 5
    [[ -n "$DOC" ]]         || die "--doc is required for --append-finding" 5
    [[ -n "$DESCRIPTION" ]] || die "--description is required for --append-finding" 5
    [[ -n "$EVIDENCE" ]]    || die "--evidence is required for --append-finding" 5
    [[ -z "$STATUS" ]] && STATUS="Pending"

    [[ "$SEVERITY" =~ $SEV_RE ]] || die "invalid --severity '$SEVERITY'; expected one of [CRITICAL] [HIGH] [MEDIUM] [LOW] [MINOR]" 4
    status_ok_finding "$STATUS"  || die "invalid --status '$STATUS' for a finding row" 4
    for f in description evidence doc line rule; do
        case "$f" in
            description) reject_newline description "$DESCRIPTION" ;;
            evidence)    reject_newline evidence "$EVIDENCE" ;;
            doc)         reject_newline doc "$DOC" ;;
            line)        reject_newline line "$LINE" ;;
            rule)        reject_newline rule "$RULE" ;;
        esac
    done

    # AC-3, mechanically. This is the ONLY place it can be enforced: grade.sh cannot do it under
    # NFR-1, and this helper is the only writer of rows.
    #
    # NO EXEMPTION. An earlier revision let a `Status: OOS` row carry `--` in Rule, as an interim
    # carrier for "no rule set covers this artifact class". That carrier is retired: the gap protocol
    # gives that outcome its own row kind, so an unmatched class is a `[GAP:CRITERIA]` gap row rather
    # than a finding nobody can trace to a rule.
    #
    # An ungrounded finding is therefore unwritable AT EVERY STATUS, which is the point -- it is what
    # stops "I could not find a rule" from quietly becoming "here is a finding anyway".
    [[ -n "$RULE" ]] || die "--rule is required on every finding row, at every status (AC-3). If no rule set covers this artifact, record a gap instead: --append-gap with a '[GAP:CRITERIA]' description." 4
    [[ "$RULE" == "--" ]] && die "'--' is not a rule. An unmatched artifact class is a [GAP:CRITERIA] gap row, not a finding -- see aid/templates/criteria-gap-protocol.md" 4
    [[ "$RULE" =~ $RULE_RE ]] || die "invalid --rule '$RULE'; expected <CLASS>-<NN> matching ${RULE_RE}" 4

    create_if_absent
    local w; w="$(header_width)"
    [[ "$w" == "7" || "$w" == "8" ]] || die "malformed ledger: header has $w columns, expected 7 or 8" 6
    if [[ "$w" == "7" && "$RULE" != "--" ]]; then
        die "--rule given but the ledger header is 7 columns; a ledger keeps the shape of its own header. Start a new 8-column ledger, or omit --rule." 4
    fi

    local rid; rid="$(next_id finding "$NAMESPACE")"
    local row
    if [[ "$w" == "8" ]]; then
        row="| $rid | $SEVERITY | $STATUS | $RULE | $DOC | $(nz "$LINE") | $(esc_pipe "$DESCRIPTION") | $(esc_pipe "$EVIDENCE") |"
    else
        row="| $rid | $SEVERITY | $STATUS | $DOC | $(nz "$LINE") | $(esc_pipe "$DESCRIPTION") | $(esc_pipe "$EVIDENCE") |"
    fi

    # A finding legitimately changes the grade, so grade verification is not applied here.
    append_row "$row" "$rid" 0
    echo "OK: ${LEDGER} -- appended finding ${rid} (${SEVERITY} ${STATUS}, rule ${RULE})"
}

mode_append_unit() {
    [[ -n "$UNIT" ]]     || die "--unit is required for --append-unit" 5
    [[ -n "$RULE_SET" ]] || die "--rule-set is required for --append-unit" 5
    [[ -z "$STATUS" ]] && STATUS="Unexamined"
    status_ok_unit "$STATUS" || die "invalid --status '$STATUS' for a coverage row; expected Unexamined | In Progress | Examined | Skipped" 4
    reject_newline unit "$UNIT"
    reject_newline rule-set "$RULE_SET"

    create_if_absent
    local w; w="$(header_width)"
    [[ "$w" == "7" || "$w" == "8" ]] || die "malformed ledger: header has $w columns, expected 7 or 8" 6

    # The helper generates the stamp, not the agent -- the same shell-generated-timestamp discipline
    # the heartbeat protocol imposes.
    [[ -z "$STAMP" ]] && STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    local art rs desc
    art="$(sha_of_file "$UNIT")"
    rs="$(sha_of_rule_set "$RULE_SET")"
    desc="rule-set: $RULE_SET"
    [[ "$STATUS" == "Skipped" && -n "$DESCRIPTION" ]] && desc="$desc; $(esc_pipe "$DESCRIPTION")"

    local rid; rid="$(next_id unit "$NAMESPACE")"
    local ev="${STAMP}; art=${art}; rs=${RULE_SET}@${rs}"
    local row
    if [[ "$w" == "8" ]]; then
        row="| $rid | -- | $STATUS | -- | $UNIT | -- | $desc | $ev |"
    else
        row="| $rid | -- | $STATUS | $UNIT | -- | $desc | $ev |"
    fi

    append_row "$row" "$rid" "$VERIFY_GRADE"
    echo "OK: ${LEDGER} -- appended coverage ${rid} (${STATUS}, ${UNIT})"
}

mode_append_gap() {
    [[ -n "$GAP_KEY" ]]     || die "--gap-key is required for --append-gap" 5
    [[ -n "$DOC" ]]         || die "--doc is required for --append-gap" 5
    [[ -n "$DESCRIPTION" ]] || die "--description is required for --append-gap" 5
    [[ -n "$RESOLUTION" ]]  || die "--resolution is required for --append-gap" 5
    [[ -z "$STATUS" ]] && STATUS="Open"
    status_ok_gap "$STATUS" || die "invalid --status '$STATUS' for a gap row; expected Open | Resolved" 4
    reject_newline gap-key "$GAP_KEY"
    reject_newline description "$DESCRIPTION"
    reject_newline resolution "$RESOLUTION"

    create_if_absent
    local w; w="$(header_width)"
    [[ "$w" == "7" || "$w" == "8" ]] || die "malformed ledger: header has $w columns, expected 7 or 8" 6

    # Idempotent on --gap-key, following --append-issue's precedent: a repeated key appends NO row and
    # instead increments resume=N on the existing row. That gives a mechanical recurrence signal
    # without this script deciding any halt policy.
    local existing="" line id
    while IFS= read -r line; do
        [[ "$line" == \|* ]] || continue
        is_sep_row "$line" && continue
        id="$(printf '%s' "$line" | awk -F'|' '{gsub(/[ `]/,"",$2); print $2}')"
        [[ "$id" == G-* ]] || continue
        if [[ "$line" == *"gap-key=${GAP_KEY};"* || "$line" == *"gap-key=${GAP_KEY} "* || "$line" == *"gap-key=${GAP_KEY}|"* ]]; then
            existing="$id"; break
        fi
    done < "$LEDGER"

    if [[ -n "$existing" ]]; then
        local cur nxt pre_rows tmp
        cur="$(find_row "$existing" | grep -oE 'resume=[0-9]+' | head -1 | cut -d= -f2)"
        [[ -z "$cur" ]] && cur=1
        nxt=$((cur + 1))
        pre_rows="$(data_row_count)"
        detect_eol
        tmp="$(mktemp)"
        TARGET="$existing" OLD="resume=${cur}" NEW="resume=${nxt}" emit_transformed '
          {
            line = $0
            if (line ~ /^\|/) {
              n = split(line, c, "|")
              id = c[2]; gsub(/[ `]/, "", id)
              if (id == ENVIRON["TARGET"]) {
                sub(ENVIRON["OLD"], ENVIRON["NEW"], line)
              }
            }
            print line
          }
        ' > "$tmp"
        commit_or_die "$tmp" "$pre_rows" "$existing" "$VERIFY_GRADE" "$(grade_of "$LEDGER")"
        echo "OK: ${LEDGER} -- duplicate gap key ${existing} (recurrence, resume=${nxt})"
        return 0
    fi

    local rid; rid="$(next_id gap "$NAMESPACE")"
    local ev="$(esc_pipe "$RESOLUTION"); gap-key=${GAP_KEY}; resume=1"
    local row
    if [[ "$w" == "8" ]]; then
        row="| $rid | -- | $STATUS | -- | $DOC | -- | $(esc_pipe "$DESCRIPTION") | $ev |"
    else
        row="| $rid | -- | $STATUS | $DOC | -- | $(esc_pipe "$DESCRIPTION") | $ev |"
    fi

    append_row "$row" "$rid" "$VERIFY_GRADE"
    echo "OK: ${LEDGER} -- appended gap ${rid} (${STATUS}, key ${GAP_KEY})"
}

mode_set_status() {
    [[ -n "$ROW_ID" ]] || die "--row-id is required for --set-status" 5
    [[ -n "$STATUS" ]] || die "--status is required for --set-status" 5
    [[ -f "$LEDGER" ]] || die "ledger does not exist: $LEDGER" 1

    local row; row="$(find_row "$ROW_ID")" || die "--row-id '$ROW_ID' not found in $LEDGER" 7

    # Status is validated against THE TARGET ROW'S KIND, so `--row-id U-002 --status Recurred` is
    # rejected rather than silently producing a nonsense coverage row.
    local kind; kind="$(row_kind_of "$ROW_ID")"
    case "$kind" in
        finding) status_ok_finding "$STATUS" || die "status '$STATUS' is not legal for finding row $ROW_ID" 4 ;;
        unit)    status_ok_unit    "$STATUS" || die "status '$STATUS' is not legal for coverage row $ROW_ID" 4 ;;
        gap)     status_ok_gap     "$STATUS" || die "status '$STATUS' is not legal for gap row $ROW_ID" 4 ;;
    esac

    local pre_rows pre_grade tmp
    pre_rows="$(data_row_count)"
    pre_grade="$(grade_of "$LEDGER")"
    detect_eol
    tmp="$(mktemp)"

    # Rewrites EXACTLY ONE CELL. Every other cell of the target row is reproduced verbatim and every
    # other row is copied byte-for-byte -- the property the whole design rests on.
    TARGET="$ROW_ID" NEWSTATUS="$STATUS" emit_transformed '
      function is_sep(s) { return s ~ /^\|[ \t:|-]+\|$/ }
      {
        line = $0
        if (line ~ /^\|/ && !is_sep(line)) {
          n = split(line, c, "|")
          id = c[2]; gsub(/[ `]/, "", id)
          if (id == ENVIRON["TARGET"]) {
            # Exactly one cell changes. Single-space padding matches the shape this script writes,
            # so a row it wrote stays byte-identical apart from the status token itself.
            c[4] = " " ENVIRON["NEWSTATUS"] " "
            # The loop already emits a leading "|" on its first pass, so `out` is the complete row.
            # Prefixing another one produced "|| U-001 | ..." and made the row unfindable afterwards.
            out = ""
            for (i = 2; i <= n; i++) out = out "|" c[i]
            line = out
          }
        }
        print line
      }
    ' > "$tmp"

    # A status change on a FINDING row legitimately moves the grade; on a coverage or gap row it must
    # not, so verification applies only to the non-finding kinds.
    local check=0
    [[ "$kind" != "finding" && "$VERIFY_GRADE" -eq 1 ]] && check=1
    commit_or_die "$tmp" "$pre_rows" "$ROW_ID" "$check" "$pre_grade"
    echo "OK: ${LEDGER} -- ${ROW_ID} status set to '${STATUS}'"
}

# Read-only. Emits the coverage manifest as TSV so a planner can consume it without re-parsing
# markdown. The `art=` and `rs=` tokens are split out of Evidence here rather than at every caller,
# because they are what make invalidation-on-resume decidable and every caller needs them.
mode_list_units() {
    [[ -f "$LEDGER" ]] || die "ledger does not exist: $LEDGER" 1
    local want="${STATUS:-}"
    awk -v want="$want" -v remaining="$REMAINING" -v ns="$NAMESPACE" '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      function is_sep(s) { return s ~ /^\|[ \t:|-]+\|$/ }
      /^\|/ {
        if (is_sep($0)) next
        n = split($0, c, "|")
        id = trim(c[2]); gsub(/`/, "", id)
        if (id !~ /^U-/) next

        if (ns != "") { if (id !~ ("^U-" ns "-")) next }

        status = trim(c[4])
        doc    = trim(c[6])
        desc   = trim(c[8])
        ev     = trim(c[9])

        # --remaining means Unexamined OR In Progress: an interrupted unit is treated as unexamined,
        # which is the resume contract rather than a convenience.
        if (remaining == 1) {
          if (status != "Unexamined" && status != "In Progress") next
        } else if (want != "" && status != want) next

        rs_name = desc; sub(/^rule-set:[ \t]*/, "", rs_name); sub(/;.*$/, "", rs_name)
        rs_name = trim(rs_name)

        stamp = ev; sub(/;.*$/, "", stamp); stamp = trim(stamp)

        art = ""
        if (match(ev, /art=[^;|]+/)) art = trim(substr(ev, RSTART + 4, RLENGTH - 4))
        rsd = ""
        if (match(ev, /rs=[^;|]+/))  rsd = trim(substr(ev, RSTART + 3, RLENGTH - 3))

        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", id, status, doc, rs_name, stamp, art, rsd
      }
    ' "$LEDGER"
}

mode_get_status() {
    [[ -n "$ROW_ID" ]] || die "--row-id is required for --get-status" 5
    [[ -f "$LEDGER" ]] || die "ledger does not exist: $LEDGER" 1
    local row; row="$(find_row "$ROW_ID")" || die "--row-id '$ROW_ID' not found in $LEDGER" 7
    printf '%s\n' "$(printf '%s' "$row" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$4); print $4}')"
}

case "$MODE" in
    append-finding) init_lock_file "$LEDGER"; [[ -d "$(dirname "$LEDGER")" ]] && acquire_lock; mode_append_finding ;;
    append-unit)    init_lock_file "$LEDGER"; [[ -d "$(dirname "$LEDGER")" ]] && acquire_lock; mode_append_unit ;;
    append-gap)     init_lock_file "$LEDGER"; [[ -d "$(dirname "$LEDGER")" ]] && acquire_lock; mode_append_gap ;;
    set-status)     init_lock_file "$LEDGER"; acquire_lock; mode_set_status ;;
    get-status)     mode_get_status ;;                       # read-only, no lock
    list-units)     mode_list_units ;;                       # read-only, no lock
    *)              die "unhandled mode: $MODE" 4 ;;
esac
